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

	pushq %r12
	pushq %r13
	pushq %r14
	pushq %r15
	pushq %rbx

	call get_r
	movl %eax, %ebx

	call get_g
	movl %eax, %r12d

	call get_b
	movl %eax, %r13d

	call get_a
	movl %eax, %r14d

	/* doing the greyscale calculation */
	imull $79, %ebx
	imull $128, %r12d
	addl %ebx, %r12d
	imull $49, %r13d
  	addl %r12d, %r13d
	
	movl %r13d, %eax
	movl $256, %r15d
	movl $0, %edx /* high 32 bits, need to manually push 0 in there */
	divl %r15d
	
	/*calling the make_pixel function*/
	movl %eax, %edi
	movl %eax, %esi
	movl %eax, %edx
	movl %r14d, %ecx
	call make_pixel

	popq %rbx
	popq %r15
	popq %r14
	popq %r13
	popq %r12

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
	/* for puproses rn, assume %r12 holds input_img->height, %r13 hold input_img->width */
	/* can put caller saved registers since not calling any fucntions */
	/* r12 and above are callee saved */
	
	/* ABI complient stackframe, meaningful stack trace in gdb */
	pushq %rbp
	movq %rsp, %rbp
	subq $8, %rsp

	pushq %r12
	pushq %r13
	pushq %r14
	
	movl IMAGE_WIDTH_OFFSET(%rdi), %r10d /* move source image width to %r10d */
	movl IMAGE_HEIGHT_OFFSET(%rdi), %r11d /* move source image height to %r11d */
	movq IMAGE_DATA_OFFSET(%rdi), %rdx /* move pointer to source data array to %rdx */
	movq IMAGE_DATA_OFFSET(%rsi), %r14 /* move pointer to output source data array to %14 */

	movl $0, %ecx /* initializing my outer loop counter to 0  (r)*/

	.LrowLoopH:
		cmpl %r11d, %ecx
		jge .LrowLoopHEnd

		movl $0, %r8d /* initializing my inner loop counter to 0 (c) */

	.LcolLoopH:
		cmpl %r10d, %r8d
		jge .LcolLoopHEnd
		
		/* Calculate index in input image array (r * width) + c */
		movl %ecx, %r9d
		imull %r10d, %r9d
		addl %r8d, %r9d
		
		/* Load pixel value from input_img->data[(r * input_img->width) + c] */
		movl (%rdx, %r9, 4), %r12d /* %rdx + (%r9d * 4) */

		/* Calculate index for output image array (r * width) + (width - 1 - c) */
		/* movl %ecx, %r13d
		imull %r10d, %r13d
		addl %r10d, %r13d
		subl %r8d, %r13d
		decl %r13d */

		movl %r10d, %r13d
		imull %ecx, %r13d
		addl %r10d, %r13d
		subl %r8d, %r13d
		decl %r13d

		/* Store pixel in output_img->data[index] */
		movl %r12d, (%r14d, %r13d, 4)

		incl %r8d
		jmp .LcolLoopH

	.LcolLoopHEnd:
		incl %ecx
		jmp .LrowLoopH
	
	.LrowLoopHEnd:
		popq %r14
		popq %r13
		popq %r12

		addq $8, %rsp
		popq %rbp
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
	/* ABI complient stackframe, meaningful stack trace in gdb */
	pushq %rbp
	movq %rsp, %rbp
	subq $8, %rsp

	pushq %r12
	pushq %r13
	pushq %r14
	
	movl IMAGE_WIDTH_OFFSET(%rdi), %r10d /* move source image width to %r10d */
	movl IMAGE_HEIGHT_OFFSET(%rdi), %r11d /* move source image height to %r11d */
	movq IMAGE_DATA_OFFSET(%rdi), %rdx /* move pointer to source data array to %rdx */
	movq IMAGE_DATA_OFFSET(%rsi), %r14 /* move pointer to output source data array to %14 */

	movl $0, %ecx /* initializing my outer loop counter to 0  (r)*/

	.LrowLoopV:
		cmpl %r11d, %ecx
		jge .LrowLoopVEnd

		movl $0, %r8d /* initializing my inner loop counter to 0 (c) */

	.LcolLoopV:
		cmpl %r10d, %r8d
		jge .LcolLoopVEnd
		
		/* Calculate index in input image array (r * width) + c */
		movl %ecx, %r9d
		imull %r10d, %r9d
		addl %r8d, %r9d
		
		/* Load pixel value from input_img->data[(r * input_img->width) + c] */
		movl (%rdx, %r9, 4), %r12d /* %rdx + (%r9d * 4) */

		/* Calculate index for output image array ((input_img->height - 1 - r) * input_img->width) + c */
		movl %r11d, %r13d
		decl %r13d
		subl %ecx, %r13d
		imull %r10d, %r13d
		addl %r8d, %r13d

		/* Store pixel in output_img->data[index] */
		movl %r12d, (%r14d, %r13d, 4)

		incl %r8d
		jmp .LcolLoopV

	.LcolLoopVEnd:
		incl %ecx
		jmp .LrowLoopV
	
	.LrowLoopVEnd:
		popq %r14
		popq %r13
		popq %r12

		addq $8, %rsp
		popq %rbp
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

 /*
 for (int r = 0; r < input_img->height; r++){
    for (int c = 0; c < input_img->width; c++) {
      int index = (r * input_img->width) + c;
      uint32_t pixel = input_img->data[index];
      output_img->data[index] = to_grayscale(pixel);
    }
  }
 */
	.globl imgproc_grayscale
imgproc_grayscale:
	/* ABI complient stackframe, meaningful stack trace in gdb */
	pushq %rbp
	movq %rsp, %rbp
	subq $8, %rsp

	pushq %rbx
	pushq %rbp
	pushq %r12
	pushq %r13
	pushq %r14
	pushq %r15
	
	movq IMAGE_DATA_OFFSET(%rdi), %rbx /* move pointer to source data array to %rdx */
	movq IMAGE_DATA_OFFSET(%rsi), %rbp /* move pointer to output source data array to %14 */

	/* calculating loop upperbound */
	movl IMAGE_WIDTH_OFFSET(%rdi), %r12d /* move source image width to %r10d */
	imull IMAGE_HEIGHT_OFFSET(%rdi), %r12d /* multiply source image height by width to get total number of pixels */

	movl $0, %r13d /* initializing my loop counter to 0 --> this is also my index value */

	.LpixelLoop:
		cmpl %r12d, %r13d /* r13 >= r12d */
		jge .LpixelLoopEnd
		
		/* Load pixel value from input_img->data[index] */
		movl (%rbx, %r13, 4), %r14d /* %rbx + (%r13 * 4) */

		/* Calculate greyscale pixel */
		movl %r14d, %edi /* passing pixel value into function parameter */
		call to_grayscale /* computing the grayscale value of said pixel */

		/* Store pixel in output_img->data[index] */
		movl %eax, %r14d /* moving the greyscale pixel value into %r12 (original color pixel is lost) */
		movl %r14d, (%rbp, %r13, 4)

		incl %r13d
		jmp .LpixelLoop
	
	.LpixelLoopEnd:
		popq %r15
		popq %r14
		popq %r13
		popq %r12
		popq %rbp
		popq %rbx

		addq $8, %rsp
		popq %rbp
	
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