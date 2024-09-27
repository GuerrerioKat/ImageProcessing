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
	/* ABI complient stack frame */
	pushq %rbp
	movq %rsp, %rbp
	subq $8, %rsp

	movl %edi, %eax /* move parameter into return value */
	shrl $24, %eax /* shift right by 24 */
	and $0xFF, %eax /* bitwise and with 0xFF */

	/* ABI complient stack frame */
	addq $8, %rsp
	popq %rbp

	ret

	.globl get_g
get_g:
	/* ABI complient stack frame */
	pushq %rbp
	movq %rsp, %rbp
	subq $8, %rsp

	movl %edi, %eax /* move parameter into return value */
	shrl $16, %eax /* shift right by 16 */
	and $0xFF, %eax /* bitwise and with 0xFF */

	/* ABI complient stack frame */
	addq $8, %rsp
	popq %rbp

	ret

	.globl get_b
get_b:
	/* ABI complient stack frame */
	pushq %rbp
	movq %rsp, %rbp
	subq $8, %rsp

	movl %edi, %eax /* move parameter into return value */
	shrl $8, %eax /* shift right by 8 */
	and $0xFF, %eax /* bitwise and with 0xFF */

	/* ABI complient stack frame */
	addq $8, %rsp
	popq %rbp

	ret

	.globl get_a
get_a:
	/* ABI complient stack frame */
	pushq %rbp
	movq %rsp, %rbp
	subq $8, %rsp

	movl %edi, %eax /* move parameter into return value */
	and $0xFF, %eax /* bitwise and with 0xFF */

	/* ABI complient stack frame */
	addq $8, %rsp
	popq %rbp

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
	/* ABI complient stack frame */
	pushq %rbp
	movq %rsp, %rbp
	subq $8, %rsp

	shll $24, %edi /* shift red left by 24 */
	shll $16, %esi /* shift green left by 16 */
	shll $8, %edx /* shift blue left by 8 */
	/* no need to shift a left */
	or %edi, %esi /* bitwise or for each rgba */
	or %esi, %edx
	or %edx, %ecx
	movl %ecx, %eax /* move that final result to the return value */

	/* ABI complient stack frame */
	addq $8, %rsp
	popq %rbp

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
	/* ABI complient stack frame */
	pushq %rbp
	movq %rsp, %rbp
	subq $8, %rsp

	pushq %r12 /* push these registers to stack */
	pushq %r13
	pushq %r14
	pushq %r15
	pushq %rbx
	/* effectivly subtracts 40 from %rsp */

	call get_r /* call each get rgba function for calculations */
	movl %eax, %ebx /* move value from call onto registers */

	call get_g
	movl %eax, %r12d

	call get_b
	movl %eax, %r13d

	call get_a
	movl %eax, %r14d

	/* doing the greyscale calculation */
	imull $79, %ebx /* multiply 79 by the r value */
	imull $128, %r12d /* multiply 128 by the g value */
	addl %ebx, %r12d /* add the two together */
	imull $49, %r13d /* multiply 49 by the b value */
  	addl %r12d, %r13d /* adds all rgb (+ coefficient) values together */
	
	movl %r13d, %eax /* move the sum calculated above into return value */
	movl $256, %r15d /* will be dividing total sum by 256, represented by %r15d */
	movl $0, %edx /* high 32 bits, need to manually push 0 in there */
	divl %r15d /* divide by 256 and put into %r15d --> notice it's callee-saved */
	
	/*calling the make_pixel function*/
	movl %eax, %edi /* create the parameters for make_pixel function */
	movl %eax, %esi /* first three parameters of function are all the same */
	movl %eax, %edx
	movl %r14d, %ecx /* last parameter is a value */
	call make_pixel

	popq %rbx /* pop registers from stack */
	popq %r15
	popq %r14
	popq %r13
	popq %r12

	/* ABI complient stack frame */
	addq $8, %rsp
	popq %rbp

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
  	/* return (alpha * fg + (255 - alpha) * bg) / 255; */
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
	/* ABI complient stackframe, meaningful stack trace in gdb */
	pushq %rbp /* rbp must point to location just below return address */
	movq %rsp, %rbp /* creates area in stackframe for local variable storage, only if you're accessing memory in the stack frame */
	subq $8, %rsp /* creating block of 8 bits that rbp points to direclty above (ie. pointer to what is just beyond the end of an arry -> indexing is backwards) */

	pushq %r12 /* push registers into stack */
	pushq %r13
	pushq %r14
	pushq %rbx
	pushq %r15
	
	
	movl IMAGE_WIDTH_OFFSET(%rdi), %r10d /* move source image width to %r10d */
	movl IMAGE_HEIGHT_OFFSET(%rdi), %r11d /* move source image height to %r11d */
	movq IMAGE_DATA_OFFSET(%rdi), %rbx /* move pointer to source data array to %rbx */
	movq IMAGE_DATA_OFFSET(%rsi), %r15 /* move pointer to output source data array to %14 */

	movl $0, %r8d /* initializing my outer loop counter to 0 (r)*/

	.LrowLoopH:
		cmpl %r11d, %r8d /* r8d >= r10 -> r >= input height */
		jge .LrowLoopHEnd /* if true, end row loop */

		movl $0, %r9d /* initializing my inner loop counter to 0 (c) */

	.LcolLoopH:
		cmpl %r10d, %r9d /* r9 >= r11 -> c >= input width */
		jge .LcolLoopHEnd /* if true, end column loop */
		
		/* Calculate index in input image array (r * width) + c */
		movl %r8d, %r12d /* moving r into final index registrar */
		imull %r10d, %r12d /* width * r */
		addl %r9d, %r12d /* (r * width) + c */
		
		/* Load pixel value from input_img->data[(r * input_img->width) + c] */
		movl (%rbx, %r12, 4), %r14d /* %rbx + (%r12d * 4) */

		/* Calculate index for output image array (r * width) + (width - 1 - c) */
		movl %r8d, %r13d /* moving r into mirrored index for output image */
		imull %r10d, %r13d /* r * width */
		addl %r10d, %r13d /* (r * width) + width */
		subl %r9d, %r13d /* (r * width) + width - c */
		decl %r13d /* (r * width) + width - c - 1 */

		/* Store pixel in output_img->data[index] */
		movl %r14d, (%r15, %r13, 4)

		incl %r9d /* c++ in for loop */
		jmp .LcolLoopH

	.LcolLoopHEnd:
		incl %r8d /* r++ in for loop */
		jmp .LrowLoopH
	
	.LrowLoopHEnd:
		popq %r15 /* pop registers from stack */
		popq %rbx
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

	pushq %r12 /* push registers into stack */
	pushq %r13
	pushq %r14
	pushq %rbx
	pushq %r15
	
	movl IMAGE_WIDTH_OFFSET(%rdi), %r10d /* move source image width to %r10d */
	movl IMAGE_HEIGHT_OFFSET(%rdi), %r11d /* move source image height to %r11d */
	movq IMAGE_DATA_OFFSET(%rdi), %rbx /* move pointer to source data array to %rbx */
	movq IMAGE_DATA_OFFSET(%rsi), %r15 /* move pointer to output source data array to %14 */

	movl $0, %r8d /* initializing my outer loop counter to 0 (r)*/

	.LrowLoopV:
		cmpl %r11d, %r8d /* r8d >= r10 -> r >= input height */
		jge .LrowLoopVEnd /* if true, end row loop */

		movl $0, %r9d /* initializing my inner loop counter to 0 (c) */

	.LcolLoopV:
		cmpl %r10d, %r9d /* r9 >= r11 -> c >= input width */
		jge .LcolLoopVEnd /* if true, end column loop */
		
		/* Calculate index in input image array (r * width) + c */
		movl %r8d, %r12d /* moving r into final index registrar */
		imull %r10d, %r12d /* width * r */
		addl %r9d, %r12d /* (r * width) + c */
		
		/* Load pixel value from input_img->data[(r * input_img->width) + c] */
		movl (%rbx, %r12, 4), %r14d /* %rbx + (%r12d * 4) */

		/* Calculate index for output image array (input_img->height - 1 - r) * input_img->width) + c */
		movl %r11d, %r13d /* moving the height into mirrored index for output image */
		decl %r13d /* height - 1 */
		subl %r8d, %r13d /* height - 1 - r */
		imull %r10d, %r13d /* ((height - 1 - r) * width) */
		addl %r9d, %r13d /* ((height - 1 - r) * width) + c */

		/* Store pixel in output_img->data[index] */
		movl %r14d, (%r15, %r13, 4)

		incl %r9d /* c++ in for loop */
		jmp .LcolLoopV

	.LcolLoopVEnd:
		incl %r8d /* r++ in for loop */
		jmp .LrowLoopV
	
	.LrowLoopVEnd:
		popq %r15 /* pop registers from stack */
		popq %rbx
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

	pushq %rbx /* push registers into stack */
	pushq %r12
	pushq %r13
	pushq %r14
	pushq %r15
	
	movq IMAGE_DATA_OFFSET(%rdi), %rbx /* move pointer to source data array to %rdx */
	movq IMAGE_DATA_OFFSET(%rsi), %r15 /* move pointer to output source data array to %14 */

	/* calculating loop upperbound */
	movl IMAGE_WIDTH_OFFSET(%rdi), %r12d /* move source image width to %r10d */
	imull IMAGE_HEIGHT_OFFSET(%rdi), %r12d /* multiply source image height by width to get total number of pixels */

	movl $0, %r13d /* initializing my loop counter to 0 --> this is also my index value */

	.LpixelLoop:
		cmpl %r12d, %r13d /* r13 >= r12d */
		jge .LpixelLoopEnd /* if true, end pixel loop */
		
		/* Load pixel value from input_img->data[index] */
		movl (%rbx, %r13, 4), %r14d /* %rbx + (%r13 * 4) */

		/* Calculate greyscale pixel */
		movl %r14d, %edi /* passing pixel value into function parameter */
		call to_grayscale /* computing the grayscale value of said pixel */

		/* Store pixel in output_img->data[index] */
		movl %eax, %r14d /* moving the greyscale pixel value into %r12 (original color pixel is lost) */
		movl %r14d, (%r15, %r13, 4)

		incl %r13d /* counter for loop iterations; counter++ here */
		jmp .LpixelLoop
	
	.LpixelLoopEnd:
		popq %r15 /* pop registers from stack */
		popq %r14
		popq %r13
		popq %r12
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