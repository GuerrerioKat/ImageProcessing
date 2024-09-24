/*
 * x86-64 assembly language implementations of functions
 */

	.section .text

/* Offsets of struct Image fields */
#define IMAGE_WIDTH_OFFSET   0
#define IMAGE_HEIGHT_OFFSET  4
#define IMAGE_DATA_OFFSET    8

/*
 * TODO: define your helper functions here.
 * Don't forget to use the .globl directive to make
 * them visible to the test code.
 */

	.globl all_tiles_nonempty
all_tiles_nonempty:
	ret

	.globl determine_tile_w
determine_tile_w:
	ret

 	.globl determine_tile_x_offset
determine_tile_x_offset:
	ret

 	.globl determine_tile_h
determine_tile_h:
	ret

 	.globl determine_tile_y_offset
 determine_tile_y_offset:
	ret

 	.globl copy_tile
 copy_tile:
	ret

 /*
 * uint32_t get_r( uint32_t pixel );
 *
 * Returns the red component of a pixel.
 * This transformation always succeeds.
 *
 * Parameters:
 *   %edi - pointer to the pixel
 */
	.globl get_r
get_r:
	movl %edi, %eax
	shrl $24, %eax
	and $0xFF, %eax
	ret

	.globl get_g
get_g:
	movl %edi, %eax
	shrl $16, %eax
	and $0xFF, %eax
	ret

	.globl get_b
get_b:
	movl %edi, %eax
	shrl $8, %eax
	and $0xFF, %eax
	ret

	.globl get_a
get_a:
	movl %edi, %eax
	and $0xFF, %eax
	ret

/*
 * uint32_t make_pixel( uint32_t r, uint32_t g, uint32_t b, uint32_t a );
 *
 * Returns the a new pixel based on the 4 components.
 * This transformation always succeeds.
 *
 * Parameters:
 *   %edi - red pixel value
 *   %esi - green pixel value
 *   %edx - blue pixel value
 *   %ecx - alpha pixel value
 */
	.globl make_pixel
make_pixel:
	shll $24, %edi
	shll $16, %esi
	shll $8, %edx
	or %edi, %esi
	or %esi, %edx
	or %edx, %ecx // bitwise or for each rgba
	movl %ecx, %eax
	ret

/*
 * uint32_t to_grayscale( uint32_t pixel );
 *
 * Returns the a new pixel based on the 4 components.
 * This transformation always succeeds.
 *
 * Parameters:
 *   %edi - pixel value
 */
	.globl to_grayscale
to_grayscale:
	// getting the pixel values
	call get_r
	movl %eax, %r10d

	call get_g
	movl %eax, %r11d

	call get_b
	movl %eax, %r12d

	call get_a
	movl %eax, %r13d

	//doing the greyscale calculation
	imull $79, %r10d
	imull $128, %r11d
	addl %r10d, %r11d
	imull $49, %r12d
  	addl %r11d, %r12d
	
	movl %r12d, %eax
	movl $256, %r14d //256 is too big for a 32 bit value 
	divl %r14d
	
	//calling the make_pixel function
	movl %r12d, %edi
	movl %r12d, %esi
	movl %r12d, %edx
	movl %r13d, %ecx
	call make_pixel

	ret

/*
 * uint32_t blend_components( uint32_t fg, uint32_t bg, uint32_t alpha );
 *
 * Returns the a new pixel based on the 4 components.
 * This transformation always succeeds.
 *
 * Parameters:
 *   %edi - red pixel value
 *   %esi - green pixel value
 *   %edx - blue pixel value
 *   %ecx - alpha pixel value
 */
	.globl blend_components
blend_components:
  	/*return (alpha * fg + (255 - alpha) * bg) / 255;*/
	ret

/*
 * uint32_t blend_colors( uint32_t fg, uint32_t bg );
 *
 * Returns the a new pixel based on the 4 components.
 * This transformation always succeeds.
 *
 * Parameters:
 *   %edi - fg value
 *   %esi - bg value
 */
	.globl blend_colors
blend_colors:
	/* uint32_t a = get_a(fg); // get foreground's opacity for overlay
	uint8_t blend_r = blend_components(get_r(fg), get_r(bg), a);
	uint8_t blend_g = blend_components(get_g(fg), get_g(bg), a);
	uint8_t blend_b = blend_components(get_b(fg), get_b(bg), a);
	return make_pixel(blend_r, blend_g, blend_b, 255); */
	ret

/*
 * Implementations of API functions
 */

/*
 * void imgproc_mirror_h( struct Image *input_img, struct Image *output_img );
 *
 * Transform image by mirroring its pixels horizontally.
 * This transformation always succeeds.
 *
 * Parameters:
 *   %rdi - pointer to original struct Image
 *   %rsi - pointer to output struct Image
 */
	.globl imgproc_mirror_h
imgproc_mirror_h:
	/* TODO: implement */
	ret

/*
 * void imgproc_mirror_v( struct Image *input_img, struct Image *output_img );
 *
 * Transform image by mirroring its pixels vertically.
 * This transformation always succeeds.
 *
 * Parameters:
 *   %rdi - pointer to original struct Image
 *   %rsi - pointer to output struct Image
 */
	.globl imgproc_mirror_v
imgproc_mirror_v:
	/* TODO: implement */
	ret

/*
 * int imgproc_tile( struct Image *input_img, int n, struct Image *output_img );
 *
 * Transform image by generating a grid of n x n smaller tiles created by
 * sampling every n'th pixel from the original image.
 *
 * Parameters:
 *   %rdi - pointer to original struct Image
 *   %esi - tiling factor (how many rows and columns of tiles to generate)
 *   %rdx - pointer to the output Image (in which the transformed
 *          pixels should be stored)
 *
 * Returns (in %eax):
 *   1 if successful, or 0 if either
 *     - n is less than 1, or
 *     - the output can't be generated because at least one tile would
 *       be empty (i.e., have 0 width or height)
 */
	.globl imgproc_tile
imgproc_tile:
	/* TODO: implement (this stub implementation just returns 0) */
	xorl %eax, %eax
	ret

/*
 * void imgproc_grayscale( struct Image *input_img, struct Image *output_img );
 *
 * Transform image by converting each pixel to grayscale.
 * This transformation always succeeds.
 *
 * Parameters:
 *   %rdi - pointer to original struct Image
 *   %rsi - pointer to output struct Image
 */
	.globl imgproc_grayscale
imgproc_grayscale:
	/* TODO: implement */
	ret

/*
 * int imgproc_composite( struct Image *base_img, struct Image *overlay_img );
 *
 * Overlay a foreground image on a background image, using each foreground
 * pixel's alpha value to determine its degree of opacity in order to blend
 * it with the corresponding background pixel.
 *
 * Parameters:
 *   %rdi - pointer to base (background) image
 *   %rsi - pointer to overlaid (foreground) image
 *   %rdx - pointer to output Image
 *
 * Returns:
 *   1 if successful, or 0 if the transformation fails because the base
 *   and overlay image do not have the same dimensions
 */
	.globl imgproc_composite
imgproc_composite:
	/* TODO: implement (this stub implementation just returns 0) */
	xorl %eax, %eax
	ret

/*
vim:ft=gas:
*/