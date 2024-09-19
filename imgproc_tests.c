#include <assert.h>
#include <stdlib.h>
#include <stdbool.h>
#include "tctest.h"
#include "imgproc.h"

// An expected color identified by a (non-zero) character code.
// Used in the "Picture" data type.
typedef struct {
  char c;
  uint32_t color;
} ExpectedColor;

// Type representing a "picture" of an expected image.
// Useful for creating a very simple Image to be accessed
// by test functions.
typedef struct {
  ExpectedColor colors[20];
  int width, height;
  const char *data;
} Picture;

// Some "basic" colors to use in test Pictures
#define TEST_COLORS \
    { \
      { ' ', 0x000000FF }, \
      { 'r', 0xFF0000FF }, \
      { 'g', 0x00FF00FF }, \
      { 'b', 0x0000FFFF }, \
      { 'c', 0x00FFFFFF }, \
      { 'm', 0xFF00FFFF }, \
    }

// Expected "basic" colors after grayscale transformation
#define TEST_COLORS_GRAYSCALE \
    { \
      { ' ', 0x000000FF }, \
      { 'r', 0x4E4E4EFF }, \
      { 'g', 0x7F7F7FFF }, \
      { 'b', 0x303030FF }, \
      { 'c', 0xB0B0B0FF }, \
      { 'm', 0x7F7F7FFF }, \
    }

// Colors for test overlay image (for testing the composite
// transformation). Has some fully-opaque colors,
// some partially-transparent colors, and a complete
// transparent color.
#define OVERLAY_COLORS \
  { \
    { 'r', 0xFF0000FF }, \
    { 'R', 0xFF000080 }, \
    { 'g', 0x00FF00FF }, \
    { 'G', 0x00FF0080 }, \
    { 'b', 0x0000FFFF }, \
    { 'B', 0x0000FF80 }, \
    { ' ', 0x00000000 }, \
  }

// Data type for the test fixture object.
// This contains data (including Image objects) that
// can be accessed by test functions. This is useful
// because multiple test functions can access the same
// data (so you don't need to create/initialize that
// data multiple times in different test functions.)
typedef struct {
  // smiley-face picture
  Picture smiley_pic;

  // original smiley-face Image object
  struct Image *smiley;

  // empty Image object to use for output of
  // transformation on smiley-face image
  struct Image *smiley_out;

  // Picture for overlay image (for basic imgproc_composite test)
  Picture overlay_pic;

  // overlay image object
  struct Image *overlay;
} TestObjs;

// Functions to create and clean up a test fixture object
TestObjs *setup( void );
void cleanup( TestObjs *objs );

// Helper functions used by the test code
struct Image *picture_to_img( const Picture *pic );
uint32_t lookup_color(char c, const ExpectedColor *colors);
bool images_equal( struct Image *a, struct Image *b );
void destroy_img( struct Image *img );

// Test functions
void test_mirror_h_basic( TestObjs *objs );
void test_mirror_v_basic( TestObjs *objs );
void test_tile_basic( TestObjs *objs );
void test_grayscale_basic( TestObjs *objs );
void test_composite_basic( TestObjs *objs );
// TODO: add prototypes for additional test functions
void test_all_tiles_nonempty(TestObjs *objs);
void test_determine_tile_w(TestObjs *objs);
void test_determine_tile_x_offset(TestObjs *objs);
void test_determine_tile_h(TestObjs *objs);
void test_determine_tile_y_offset(TestObjs *objs);
void test_copy_tile(TestObjs *objs);
void test_get_r(TestObjs *objs);
void test_get_g(TestObjs *objs);
void test_get_b(TestObjs *objs);
void test_get_a(TestObjs *objs);
void test_make_pixel(TestObjs *objs);
void test_to_grayscale(TestObjs *objs);
void test_blend_components(TestObjs *objs);
void test_blend_colors(TestObjs *objs);

int main( int argc, char **argv ) {
  // allow the specific test to execute to be specified as the
  // first command line argument
  if ( argc > 1 )
    tctest_testname_to_execute = argv[1];

  TEST_INIT();

  // Run tests.
  // Make sure you add additional TEST() macro invocations
  // for any additional test functions you add.
  TEST ( test_all_tiles_nonempty );
  TEST( test_determine_tile_w );
  TEST( test_determine_tile_x_offset );
  TEST( test_determine_tile_h );
  TEST( test_determine_tile_y_offset );
  TEST( test_copy_tile );
  TEST( test_get_r );
  TEST( test_get_g );
  TEST( test_get_b );
  TEST( test_get_a );
  TEST( test_make_pixel );
  TEST( test_to_grayscale );
  TEST( test_blend_components );
  TEST( test_blend_colors );

  TEST( test_mirror_h_basic );
  TEST( test_mirror_v_basic );
  TEST( test_tile_basic );
  TEST( test_grayscale_basic );
  TEST( test_composite_basic );

  TEST_FINI();
}

////////////////////////////////////////////////////////////////////////
// Test fixture setup/cleanup functions
////////////////////////////////////////////////////////////////////////

TestObjs *setup( void ) {
  TestObjs *objs = (TestObjs *) malloc( sizeof(TestObjs) );

  Picture smiley_pic = {
    TEST_COLORS,
    16, // width
    10, // height
    "    mrrrggbc    "
    "   c        b   "
    "  r   r  b   c  "
    " b            b "
    " b            r "
    " g   b    c   r "
    "  c   ggrb   b  "
    "   m        c   "
    "    gggrrbmc    "
    "                "
  };
  objs->smiley_pic = smiley_pic;
  objs->smiley = picture_to_img( &smiley_pic );

  objs->smiley_out = (struct Image *) malloc( sizeof( struct Image ) );
  img_init( objs->smiley_out, objs->smiley->width, objs->smiley->height );

  Picture overlay_pic = {
    OVERLAY_COLORS,
    16, 10,
   "                "
   "                "
   "                "
   "                "
   "                "
   "  rRgGbB        "
   "                "
   "                "
   "                "
   "                "
  };
  objs->overlay_pic = overlay_pic;
  objs->overlay = picture_to_img( &overlay_pic );

  return objs;
}

void cleanup( TestObjs *objs ) {
  destroy_img( objs->smiley );
  destroy_img( objs->smiley_out );
  destroy_img( objs->overlay );

  free( objs );
}

////////////////////////////////////////////////////////////////////////
// Test code helper functions
////////////////////////////////////////////////////////////////////////

struct Image *picture_to_img( const Picture *pic ) {
  struct Image *img;

  img = (struct Image *) malloc( sizeof(struct Image) );
  img_init( img, pic->width, pic->height );

  for ( int i = 0; i < pic->height; ++i ) {
    for ( int j = 0; j < pic->width; ++j ) {
      int index = i * img->width + j;
      uint32_t color = lookup_color( pic->data[index], pic->colors );
      img->data[index] = color;
    }
  }

  return img;
}

uint32_t lookup_color(char c, const ExpectedColor *colors) {
  for (int i = 0; ; i++) {
    assert(colors[i].c != 0);
    if (colors[i].c == c) {
      return colors[i].color;
    }
  }
}

// Returns true IFF both Image objects are identical
bool images_equal( struct Image *a, struct Image *b ) {
  if ( a->width != b->width || a->height != b->height )
    return false;

  int num_pixels = a->width * a->height;
  for ( int i = 0; i < num_pixels; ++i ) {
    if ( a->data[i] != b->data[i] )
      return false;
  }

  return true;
}

void destroy_img( struct Image *img ) {
  if ( img != NULL )
    img_cleanup( img );
  free( img );
}

////////////////////////////////////////////////////////////////////////
// Test functions
////////////////////////////////////////////////////////////////////////
void test_all_tiles_nonempty(TestObjs *objs) {
  // tbh I do not know how to test this one
  ASSERT(all_tiles_nonempty(1, 1, 1) == 1);
  ASSERT(all_tiles_nonempty(1, 0, 1) == 0);
  ASSERT(all_tiles_nonempty(0, 1, 1) == 0);
  ASSERT(all_tiles_nonempty(1, 1, 0) == 0);
}

void test_determine_tile_w(TestObjs *objs) {
  ASSERT(determine_tile_w(100, 10, 9) == 10);
  ASSERT(determine_tile_w(101, 10, 0) == 11);
  ASSERT(determine_tile_w(101, 10, 9) == 10);
  ASSERT(determine_tile_w(5, 10, 0) == 1);
  ASSERT(determine_tile_w(1, 1, 0) == 1);
}

void test_determine_tile_x_offset(TestObjs *objs) {
  ASSERT(determine_tile_x_offset(100, 10, 0) == 0);
  ASSERT(determine_tile_x_offset(100, 10, 1) == 10);
  ASSERT(determine_tile_x_offset(101, 10, 1) == 11);
  ASSERT(determine_tile_x_offset(5, 10, 0) == 0);
  ASSERT(determine_tile_x_offset(10, 10, 1) == 1);
}

void test_determine_tile_h(TestObjs *objs) { // tile_w and tile_h do the same things so test the same
  ASSERT(determine_tile_h(100, 10, 9) == 10);
  ASSERT(determine_tile_h(101, 10, 0) == 11);
  ASSERT(determine_tile_h(101, 10, 9) == 10);
  ASSERT(determine_tile_h(5, 10, 0) == 1);
  ASSERT(determine_tile_h(1, 1, 0) == 1);
}

void test_determine_tile_y_offset(TestObjs *objs) { // x_offset and y_offset are the same so test the same 
  ASSERT(determine_tile_y_offset(100, 10, 0) == 0);
  ASSERT(determine_tile_y_offset(100, 10, 1) == 10);
  ASSERT(determine_tile_y_offset(101, 10, 1) == 11);
  ASSERT(determine_tile_y_offset(5, 10, 0) == 0);
  ASSERT(determine_tile_y_offset(10, 10, 1) == 1);
}

void test_copy_tile(TestObjs *objs) {
  Picture smiley_mirror_h_pic = {
    TEST_COLORS,
    16, 10,
    "    cbggrrrm    "
    "   b        c   "
    "  c   b  r   r  "
    " b            b "
    " r            b "
    " r   c    b   g "
    "  b   brgg   c  "
    "   c        m   "
    "    cmbrrggg    "
    "                "
  };
  // struct Image *smiley_mirror_h_expected = picture_to_img( &smiley_mirror_h_pic );
  // struct Image *copy = malloc(sizeof(struct Image));
  // copy->width = 16;
  // copy->height = 10;
  // copy->data = calloc(16 * 10, sizeof(uint32_t));
  // copy_tile(copy, smiley_mirror_h_expected, 1, 2, 2);
  // ASSERT(images_equal(smiley_mirror_h_expected, copy));
  // destroy_img( smiley_mirror_h_expected );
  // destroy_img( copy );
}

void test_get_r(TestObjs *objs) {
  uint32_t pixel = 0x80C0E0F0; // 10000000110000001110000011110000
  print_binary(get_r(pixel)); // 00000000000000000000000010000000
  ASSERT(get_r(pixel) == 0x80);
  // can't really compare strings so had to look up decimal form of these
}

void test_get_g(TestObjs *objs) {
  uint32_t pixel = 0x80C0E0F0;
  print_binary(get_g(pixel)); // 00000000000000000000000011000000
  ASSERT(get_g(pixel) == 0xC0);
}

void test_get_b(TestObjs *objs) {
  uint32_t pixel = 0x80C0E0F0;
  print_binary(get_b(pixel)); // 00000000000000000000000011100000
  ASSERT(get_b(pixel) == 0xE0);
}

void test_get_a(TestObjs *objs) {
  uint32_t pixel = 0x80C0E0F0;
  print_binary(get_a(pixel)); // 00000000000000000000000011110000
  ASSERT(get_a(pixel) == 0xF0);
}

void test_make_pixel(TestObjs *objs) {
  uint32_t pixel = 0x80C0E0F0;
  uint32_t madePixel = make_pixel(get_r(pixel), get_g(pixel), get_b(pixel), get_a(pixel));
  ASSERT(madePixel == pixel);
  madePixel = make_pixel(0x80, 0xC0, 0xE0, 0xF0);
  ASSERT(madePixel == pixel);
}

void test_to_grayscale(TestObjs *objs) {
  // r
  uint32_t pixel = make_pixel(255, 0, 0, 255);
  uint32_t expected = make_pixel(78, 78, 78, 255);
  uint32_t result = to_grayscale(pixel);
  ASSERT(result == expected);
  
  // g
  pixel = make_pixel(0, 255, 0, 255); // green
  expected = make_pixel(127, 127, 127, 255);
  result = to_grayscale(pixel);
  ASSERT(result == expected);
  
  // b
  pixel = make_pixel(0, 0, 255, 255); // blue
  expected = make_pixel(48, 48, 48, 255);
  result = to_grayscale(pixel);
  ASSERT(result == expected);

  // white
  pixel = make_pixel(255, 255, 255, 255); // white
  expected = make_pixel(255, 255, 255, 255);
  result = to_grayscale(pixel);
  ASSERT(result == expected);
  
  // black
  pixel = make_pixel(0, 0, 0, 255); // black
  expected = make_pixel(0, 0, 0, 255);
  result = to_grayscale(pixel);
  ASSERT(result == expected);
}

void test_blend_components(TestObjs *objs) {
  uint32_t fg = 100;
  uint32_t bg = 200;
  uint32_t alpha = 50;
  uint32_t expected = (50 * 100 + (255 - 50) * 200) / 255;
  uint32_t result = blend_components(fg, bg, alpha);
  ASSERT(result == expected);

  fg = 255;
  bg = 0;
  alpha = 0;
  expected = (0 * 255 + (255 - 0) * 0) / 255;
  result = blend_components(fg, bg, alpha);
  ASSERT(result == expected);
}

void test_blend_colors(TestObjs *objs) {
  uint32_t fg = make_pixel(255, 0, 0, 128); // half opacity
  uint32_t bg = make_pixel(0, 255, 0, 255);
  uint32_t expected = make_pixel(
    (128 * 255 + (255 - 128) * 0) / 255,
    (128 * 0 + (255 - 128) * 255) / 255,
    (128 * 0 + (255 - 128) * 0) / 255,
    255
  );
  uint32_t result = blend_colors(fg, bg);
  ASSERT(result == expected);

  fg = make_pixel(255, 0, 0, 0); // not visible
  bg = make_pixel(0, 255, 0, 255);
  expected = make_pixel(0, 255, 0, 255); // bg should be returned
  result = blend_colors(fg, bg);
  ASSERT(result == expected);

  fg = make_pixel(255, 0, 0, 255);
  bg = make_pixel(0, 255, 0, 0);
  expected = make_pixel(255, 0, 0, 255); // fg should be returned
  result = blend_colors(fg, bg);
  ASSERT(result == expected);
}

void test_mirror_h_basic( TestObjs *objs ) {
  Picture smiley_mirror_h_pic = {
    TEST_COLORS,
    16, 10,
    "    cbggrrrm    "
    "   b        c   "
    "  c   b  r   r  "
    " b            b "
    " r            b "
    " r   c    b   g "
    "  b   brgg   c  "
    "   c        m   "
    "    cmbrrggg    "
    "                "
  };
  struct Image *smiley_mirror_h_expected = picture_to_img( &smiley_mirror_h_pic );

  imgproc_mirror_h( objs->smiley, objs->smiley_out );

  ASSERT( images_equal( smiley_mirror_h_expected, objs->smiley_out ) );

  destroy_img( smiley_mirror_h_expected );
}

void test_mirror_v_basic( TestObjs *objs ) {
  Picture smiley_mirror_v_pic = {
    TEST_COLORS,
    16, 10,
    "                "
    "    gggrrbmc    "
    "   m        c   "
    "  c   ggrb   b  "
    " g   b    c   r "
    " b            r "
    " b            b "
    "  r   r  b   c  "
    "   c        b   "
    "    mrrrggbc    "
  };
  struct Image *smiley_mirror_v_expected = picture_to_img( &smiley_mirror_v_pic );

  imgproc_mirror_v( objs->smiley, objs->smiley_out );

  ASSERT( images_equal( smiley_mirror_v_expected, objs->smiley_out ) );

  destroy_img( smiley_mirror_v_expected );
}

void test_tile_basic( TestObjs *objs ) {
  Picture smiley_tile_3_pic = {
    TEST_COLORS,
    16, 10,
    "  rg    rg   rg "
    "                "
    "  gb    gb   gb "
    "                "
    "  rg    rg   rg "
    "                "
    "  gb    gb   gb "
    "  rg    rg   rg "
    "                "
    "  gb    gb   gb "
  };
  struct Image *smiley_tile_3_expected = picture_to_img( &smiley_tile_3_pic );

  int success = imgproc_tile( objs->smiley, 3, objs->smiley_out );
  ASSERT( success );
  ASSERT( images_equal( smiley_tile_3_expected, objs->smiley_out ) );

  destroy_img( smiley_tile_3_expected );
}

void test_grayscale_basic( TestObjs *objs ) {
  Picture smiley_grayscale_pic = {
    TEST_COLORS_GRAYSCALE,
    16, // width
    10, // height
    "    mrrrggbc    "
    "   c        b   "
    "  r   r  b   c  "
    " b            b "
    " b            r "
    " g   b    c   r "
    "  c   ggrb   b  "
    "   m        c   "
    "    gggrrbmc    "
    "                "
  };

  struct Image *smiley_grayscale_expected = picture_to_img( &smiley_grayscale_pic );

  imgproc_grayscale( objs->smiley, objs->smiley_out );

  ASSERT( images_equal( smiley_grayscale_expected, objs->smiley_out ) );

  destroy_img( smiley_grayscale_expected );
}

void test_composite_basic( TestObjs *objs ) {
  imgproc_composite( objs->smiley, objs->overlay, objs->smiley_out );

  // for all of the fully-transparent pixels in the overlay image,
  // the result image should have a pixel identical to the corresponding
  // pixel in the base image
  for ( int i = 0; i < 160; ++i ) {
    if ( objs->overlay->data[i] == 0x00000000 )
      ASSERT( objs->smiley->data[i] == objs->smiley_out->data[i] );
  }

  // check the computed colors for the partially transparent or
  // fully opaque colors in the overlay image
  ASSERT( 0xFF0000FF == objs->smiley_out->data[82] );
  ASSERT( 0x800000FF == objs->smiley_out->data[83] );
  ASSERT( 0x00FF00FF == objs->smiley_out->data[84] );
  ASSERT( 0x00807FFF == objs->smiley_out->data[85] );
  ASSERT( 0x0000FFFF == objs->smiley_out->data[86] );
  ASSERT( 0x000080FF == objs->smiley_out->data[87] );
}

