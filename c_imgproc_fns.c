// C implementations of image processing functions

#include <stdlib.h>
#include <assert.h>
#include <stdio.h>
#include <stdint.h>
#include <sys/types.h>
#include <sys/ucontext.h>
#include "imgproc.h"

//checks if any of the tiles would be empty based on the tiling factor
int all_tiles_nonempty( int width, int height, int n ) {
  return !(n < 1 || (height / n) < 1 || (width / n) < 1);
}

//determines the specific width of a tile in a certain column. Takes into account any extra width if the image width isn't divisible by n
int determine_tile_w( int width, int n, int tile_col ) {
  int remainder = width % n;//if it's not completly divisible (excess is distributed eveling across the earlier tiles)
  if (remainder > tile_col) {
    return (width / n) + 1;
  }
  return width / n;
}

//determines how far the next tile should start in the x direction
int determine_tile_x_offset( int width, int n, int tile_col ) {
  int offset = 0;
  for (int i = 0; i < tile_col; i++) {
    offset += determine_tile_w(width, n, i);
  }
  return offset;
}

//determines the specific height of a tile in a certain row. Takes into account any extra height if the image height isn't divisible by n
int determine_tile_h( int height, int n, int tile_row ) {
  int remainder = height % n;//if it's not completly divisible (excess is distributed eveling across the earlier tiles)
  if (remainder > tile_row) {
    return (height / n) + 1;
  }
  return height / n;
}

//determines how far the next tile should start in the y direction
int determine_tile_y_offset( int height, int n, int tile_row ) {
  int offset = 0;
  for (int i = 0; i < tile_row; i++) {
    offset += determine_tile_h(height, n, i);
  }
  return offset;
}

//creates a single tile in the image
void copy_tile( struct Image *out_img, struct Image *img, int tile_row, int tile_col, int n ) {
  int tile_w = determine_tile_w(img->width, n, tile_col);
  int tile_h = determine_tile_h(img->height, n, tile_row);
  int x_offset = determine_tile_x_offset(img->width, n, tile_col);
  int y_offset = determine_tile_y_offset(img->height, n, tile_row);

  for (int r = 0; r < tile_h; r++){
    for (int c = 0; c < tile_w; c++) {
      int img_c = c * n; //taking every nth pixel
      int img_r = r * n;

      if (img_c < img->width && img_r < img->height) { //valid pixel to take
        uint32_t pixel = img->data[img_r * img->width + img_c];
        int out_c = x_offset + c;
        int out_r = y_offset + r;
        out_img->data[out_r * out_img->width + out_c] = pixel;
      }
    }
  }
}

//returns the red component of the pixel
uint32_t get_r( uint32_t pixel ) {
  return (pixel >> 24) & 0xFF;
}

//returns the green component of a pixel
uint32_t get_g( uint32_t pixel ) {
  return (pixel >> 16) & 0xFF;
}

//returns the blue component of a pixel
uint32_t get_b( uint32_t pixel ) {
  return (pixel >> 8) & 0xFF;
}

//returns the alpha value of a pixel
uint32_t get_a( uint32_t pixel ) {
  return pixel & 0xFF;
}

//based on red, green, blue, and alpha values, it creates a new pixel with those values
uint32_t make_pixel( uint32_t r, uint32_t g, uint32_t b, uint32_t a ) {
  uint32_t pixel = (r << 24) | (g << 16) | (b << 8) | a;
  return pixel;
}

//calculates the greyscale color value and returns a new greyscale pixel
uint32_t to_grayscale( uint32_t pixel ) {
  uint8_t y = (79 * get_r(pixel) + 128 * get_g(pixel) + 49 * get_b(pixel)) / 256;
  return make_pixel(y, y, y, get_a(pixel));
}

//performs the blendign calculation on a single color
uint32_t blend_components( uint32_t fg, uint32_t bg, uint32_t alpha ) {
  return (alpha * fg + (255 - alpha) * bg) / 255;
}

//blends all three color components and returns a new pixel with those values
uint32_t blend_colors( uint32_t fg, uint32_t bg ) { // fg = foreground, bg = background
  uint32_t a = get_a(fg); // get foreground's opacity for overlay
  uint8_t blend_r = blend_components(get_r(fg), get_r(bg), a);
  uint8_t blend_g = blend_components(get_g(fg), get_g(bg), a);
  uint8_t blend_b = blend_components(get_b(fg), get_b(bg), a);
  return make_pixel(blend_r, blend_g, blend_b, 255);
}

// Mirror input image horizontally.
// This transformation always succeeds.
//
// Parameters:
//   input_img  - pointer to the input Image
//   output_img - pointer to the output Image (in which the transformed
//                pixels should be stored)
void imgproc_mirror_h( struct Image *input_img, struct Image *output_img ) {
  for (int r = 0; r < input_img->height; r++){
    for (int c = 0; c < input_img->width; c++) {
      uint32_t pixel = input_img->data[(r * input_img->width) + c];
      int index = (r * input_img->width) + (input_img->width - 1 - c);
      output_img->data[index] = pixel;
    }
  }
}

// Mirror input image vertically.
// This transformation always succeeds.
//
// Parameters:
//   input_img  - pointer to the input Image
//   output_img - pointer to the output Image (in which the transformed
//                pixels should be stored)
void imgproc_mirror_v( struct Image *input_img, struct Image *output_img ) {
  for (int r = 0; r < input_img->height; r++){
    for (int c = 0; c < input_img->width; c++) {
      uint32_t pixel = input_img->data[(r * input_img->width) + c];
      int index = ((input_img->height - 1 - r) * input_img->width) + c;
      output_img->data[index] = pixel;
    }
  }
}

// Transform image by generating a grid of n x n smaller tiles created by
// sampling every n'th pixel from the original image.
//
// Parameters:
//   input_img  - pointer to original struct Image
//   n          - tiling factor (how many rows and columns of tiles to generate)
//   output_img - pointer to the output Image (in which the transformed
//                pixels should be stored)
// Returns:
//   1 if successful, or 0 if either
//     - n is less than 1, or
//     - the output can't be generated because at least one tile would
//       be empty (i.e., have 0 width or height)
int imgproc_tile( struct Image *input_img, int n, struct Image *output_img ) {
  if (!all_tiles_nonempty(output_img->width, output_img->height, n)) {
    return 0;
  }

  for (int r = 0; r < n; r++) {
    for (int c = 0; c < n; c++) {
      copy_tile(output_img, input_img, r, c, n);
    }
  }

  return 1;
}

// Convert input pixels to grayscale.
// This transformation always succeeds.
//
// Parameters:
//   input_img  - pointer to the input Image
//   output_img - pointer to the output Image (in which the transformed
//                pixels should be stored)
void imgproc_grayscale( struct Image *input_img, struct Image *output_img ) {
  for (int r = 0; r < input_img->height; r++){
    for (int c = 0; c < input_img->width; c++) {
      int index = (r * input_img->width) + c;
      uint32_t pixel = input_img->data[index];
      output_img->data[index] = to_grayscale(pixel);
    }
  }
}

// Overlay a foreground image on a background image, using each foreground
// pixel's alpha value to determine its degree of opacity in order to blend
// it with the corresponding background pixel.
//
// Parameters:
//   base_img - pointer to base (background) image
//   overlay_img - pointer to overlaid (foreground) image
//   output_img - pointer to output Image
//
// Returns:
//   1 if successful, or 0 if the transformation fails because the base
//   and overlay image do not have the same dimensions
int imgproc_composite( struct Image *base_img, struct Image *overlay_img, struct Image *output_img ) {
  if (base_img->height != overlay_img->height || base_img->width != overlay_img->width) {
    return 0;
  }

  for (int r = 0; r < base_img->height; r++){
    for (int c = 0; c < base_img->width; c++) {
      int index = (r * base_img->width) + c;
      uint32_t pixel_bg = base_img->data[index];
      uint32_t pixel_fg = overlay_img->data[index];
      output_img->data[index] = blend_colors(pixel_fg, pixel_bg);
    }
  }
  return 1;
}
