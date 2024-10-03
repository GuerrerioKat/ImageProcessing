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

 /*
 * uint32_t all_tiles_nonempty( uint32_t width, uint32_t height, int32_t n );
 *
 * Checks if any of the tiles would be empty based on the tiling factor.
 * Returns 1 if true, 0 if false.
 *
 * Parameters:
 *   %edi - width value
 *   %esi - height value
 *   %edx - n value
 */
	.globl all_tiles_nonempty
all_tiles_nonempty:
	pushq %rbp
	movq %rsp, %rbp

	movl %edx, %r10d
	
	cmpl $1, %r10d /* n < 1 */
	jl .LendF
	
	movl %esi, %eax
	movl $0, %edx
	divl %r10d
	cmpl $1, %eax /* (height/n) < 1 */
	jl .LendF

	movl %edi, %eax
	movl $0, %edx
	divl %r10d
	cmpl $1, %eax /* (width/n) < 1 */
	jl .LendF

	.LendT:
		movl $1, %eax
		popq %rbp
		ret

	.LendF:
		movl $0, %eax
		popq %rbp
		ret

	.globl determine_tile_w

 /*
 * uint32_t get_r( uint32_t pixel );
 *
 * Returns the red component of a pixel.
 *
 * Parameters:
 *   %edi - pointer to the pixel
 */
determine_tile_w:
	/* ABI complient stack frame */
	pushq %rbp
	movq %rsp, %rbp
	subq $0, %rsp

	movl %edi, %eax /* move the width into numerator */
	movl %esi, %r10d /* moving n into %r10 */
	movl %edx, %r11d /* moving tile_col into %r11 */
	movl $0, %edx /* high 32 bits, need to manually push 0 in there */
	divl %r10d /* divide by n and put into %eax */
	
	.LcheckRemainderw:
		cmp %r11d, %edx /* remainder > tile_col */
		jg .LextraOffsetw
		jmp .LreturnOffsetw

	.LextraOffsetw:
		incl %eax
	
	.LreturnOffsetw:
		addq $0, %rsp
		popq %rbp
		ret

 /*
 * uint32_t get_r( uint32_t pixel );
 *
 * Returns the red component of a pixel.
 *
 * Parameters:
 *   %edi - pointer to the pixel
 */
 	.globl determine_tile_x_offset
determine_tile_x_offset:
	pushq %rbp
	movq %rsp, %rbp
	subq $8, %rsp

	pushq %r12
	pushq %r13
	pushq %r14
	pushq %r15
	pushq %rbx
	
	movl $0, %r14d /* make %r14d the offset tracker */
	movl $0, %r15d /* make %r15d the i (counter) tracker */
	
	movl %edi, %r12d /* width */
	movl %esi, %r13d /* n */
	movl %edx, %ebx /* tile_col */

	.Lloopx:
		cmpl %ebx, %r15d /* i >= tile_col */
		jge .LendLoopx
		
		movl %r12d, %edi
		movl %r13d, %esi
		movl %r15d, %edx
		call determine_tile_w
		addl %eax, %r14d
		
		incl %r15d
		jmp .Lloopx

	.LendLoopx:
		movl %r14d, %eax

		popq %rbx
		popq %r15
		popq %r14
		popq %r13
		popq %r12

		addq $8, %rsp
		popq %rbp
	ret

 /*
 * uint32_t get_r( uint32_t pixel );
 *
 * Returns the red component of a pixel.
 *
 * Parameters:
 *   %edi - pointer to the pixel
 */
 	.globl determine_tile_h
determine_tile_h:
	/* ABI complient stack frame */
	pushq %rbp
	movq %rsp, %rbp
	subq $0, %rsp

	movl %edi, %eax /* move the height into numerator */
	movl %esi, %r10d /* moving n into %r10 */
	movl %edx, %r11d /* moving tile_col into %r11 */
	movl $0, %edx /* high 32 bits, need to manually push 0 in there */
	divl %r10d /* divide by n and put into %eax */
	
	.LcheckRemainderh:
		cmp %r11d, %edx /* remainder > tile_row */
		jg .LextraOffseth
		jmp .LreturnOffseth

	.LextraOffseth:
		incl %eax
	
	.LreturnOffseth:
		addq $0, %rsp
		popq %rbp
		ret

 /*
 * uint32_t get_r( uint32_t pixel );
 *
 * Returns the red component of a pixel.
 *
 * Parameters:
 *   %edi - pointer to the pixel
 */
 	.globl determine_tile_y_offset
 determine_tile_y_offset:
	pushq %rbp
	movq %rsp, %rbp
	subq $8, %rsp

	pushq %r12
	pushq %r13
	pushq %r14
	pushq %r15
	pushq %rbx
	
	movl $0, %r14d /* make %r14d the offset tracker */
	movl $0, %r15d /* make %r15d the i (counter) tracker */
	
	movl %edi, %r12d /* height */
	movl %esi, %r13d /* n */
	movl %edx, %ebx /* tile_row */

	.Lloopy:
		cmpl %ebx, %r15d /* i >= tile_row */
		jge .LendLoopx
		
		movl %r12d, %edi
		movl %r13d, %esi
		movl %r15d, %edx
		call determine_tile_w
		addl %eax, %r14d
		
		incl %r15d
		jmp .Lloopx

	.LendLoopy:
		movl %r14d, %eax

		popq %rbx
		popq %r15
		popq %r14
		popq %r13
		popq %r12

		addq $8, %rsp
		popq %rbp
	ret

 /*
 * uint32_t get_r( uint32_t pixel );
 *
 * Returns the red component of a pixel.
 *
 * Parameters:
 *   %edi - pointer to the pixel
 */
 	.globl copy_tile
 copy_tile:
	pushq %rbp
    movq %rsp, %rbp
    subq $40, %rsp

    pushq %rbx
    pushq %r12
    pushq %r13
    pushq %r14
    pushq %r15

    movl %edx, %r12d  //tile_row
    movl %ecx, %r13d  //tile_col
    movl %r8d, %r14d  //n

    movq IMAGE_DATA_OFFSET(%rdi), %r15 /* move pointer to output image data array to %r15 */
    movq IMAGE_DATA_OFFSET(%rsi), %rbx /* move pointer to source image data array to %rbx */

    movl IMAGE_WIDTH_OFFSET(%rsi), %r8d
    movl %r8d, -4(%rbp) /* move source image width to %r11d */
    movl IMAGE_HEIGHT_OFFSET(%rsi), %r8d
    movl %r8d, -8(%rbp) /* move source image height to %r11d */

    movl IMAGE_WIDTH_OFFSET(%rdi), %r8d
    movl %r8d, -40(%rbp) /* move output image width to %r11d */
    movl IMAGE_HEIGHT_OFFSET(%rdi), %r8d
    movl %r8d, -44(%rbp) /* move output image height to %r11d */

    //GETTING TILE_W
    movl -4(%rbp), %edi /* move source image width to %edi */
    movl %r14d, %esi
    movl %r13d, %edx
    call determine_tile_w
    movl %eax, -12(%rbp) /* storign tile width */

    //GETTING TILE_H
    movl -8(%rbp), %edi /* move source image width to %edi */
    movl %r14d, %esi
    movl %r12d, %edx
    call determine_tile_h
    movl %eax, -16(%rbp) /* storign tile height */

    //GETTING X_OFFSET
    movl -4(%rbp), %edi /* move source image width to %edi */
    movl %r14d, %esi
    movl %r13d, %edx
    call determine_tile_x_offset
    movl %eax, -20(%rbp) /* storign tile x offset */

    //GETTING Y_OFFSET
    movl -8(%rbp), %edi /* move source image width to %edi */
    movl %r14d, %esi
    movl %r12d, %edx
    call determine_tile_y_offset
    movl %eax, -24(%rbp) /* storign tile y offset */

    movl $0, %r8d
    .LrowLoopTileCP:
        cmpl -16(%rbp), %r8d /* r >= tile height */
        jge .LrowLoopTileCPEnd /* if true, end row loop */

        movl $0, %r9d /* initializing my inner loop counter to 0 (c) */

    .LcolLoopTileCP:
        cmpl -12(%rbp), %r9d /* c >= tile width */
        jge .LcolLoopTileCPEnd /* if true, end column loop */
        
        /* Get column and row for every nth pixel */
        movl %r14d, %edi
        imull %r9d, %edi /* holds img_c */

        movl %r14d, %esi
        imull %r8d, %esi /* holds img_r */

        /* Getting pixel index */
        movl -4(%rbp), %edx
        imull %esi, %edx
        addl %edi, %edx

        /* Getting pixel value */
        movl (%rbx, %rdx, 4), %eax
        movl %eax, -28(%rbp)

        /* Getting output c and r */
        movl -20(%rbp), %eax
        movl %eax, -32(%rbp)
        addl %r9d, -32(%rbp) //int out_c = x_offset + c;

        movl -24(%rbp), %eax
        movl %eax, -36(%rbp)
        addl %r8d, -36(%rbp) // int out_r = y_offset + r;

        /* getting output index and storing it in -32(%rbp) */
        movl -40(%rbp), %eax
        imull -36(%rbp), %eax
        addl %eax, -32(%rbp)

        /* Store pixel in output_img->data[index] */
		movl -32(%rbp), %eax
		movl -28(%rbp), %esi
        movl %esi, (%r15, %rax, 4)

        incl %r9d /* c++ in for loop */
        jmp .LcolLoopTileCP

    .LcolLoopTileCPEnd:
        incl %r8d /* r++ in for loop */
        jmp .LrowLoopTileCP
    
    .LrowLoopTileCPEnd:
        popq %r15 /* pop registers from stack */
        popq %r14
        popq %r13
        popq %r12
		popq %rbx

        addq $40, %rsp
        popq %rbp


	ret

 /*
 * uint32_t get_r( uint32_t pixel );
 *
 * Returns the red component of a pixel.
 *
 * Parameters:
 *   %edi - pointer to the pixel
 */
	.globl get_r
get_r:
	/* ABI complient stack frame */
	pushq %rbp
	movq %rsp, %rbp
	subq $0, %rsp

	movl %edi, %eax /* move parameter into return value */
	shrl $24, %eax /* shift right by 24 */
	and $0xFF, %eax /* bitwise and with 0xFF */

	/* ABI complient stack frame */
	addq $0, %rsp
	popq %rbp

	ret

/*
 * uint32_t get_g( uint32_t pixel );
 *
 * Returns the green component of a pixel value
 *
 * Parameters:
 *   %edi - pixel value
 */
	.globl get_g
get_g:
	/* ABI complient stack frame */
	pushq %rbp
	movq %rsp, %rbp
	subq $0, %rsp

	movl %edi, %eax /* move parameter into return value */
	shrl $16, %eax /* shift right by 16 */
	and $0xFF, %eax /* bitwise and with 0xFF */

	/* ABI complient stack frame */
	addq $0, %rsp
	popq %rbp

	ret

	.globl get_b

/*
 * uint32_t get_b( uint32_t pixel );
 *
 * Returns the blue component of a pixel value
 *
 * Parameters:
 *   %edi - pixel value
 */
get_b:
	/* ABI complient stack frame */
	pushq %rbp
	movq %rsp, %rbp
	subq $0, %rsp

	movl %edi, %eax /* move parameter into return value */
	shrl $8, %eax /* shift right by 8 */
	and $0xFF, %eax /* bitwise and with 0xFF */

	/* ABI complient stack frame */
	addq $0, %rsp
	popq %rbp

	ret

/*
 * uint32_t get_a( uint32_t pixel );
 *
 * Returns the alpha component of a pixel value
 *
 * Parameters:
 *   %edi - pixel value
 */
	.globl get_a
get_a:
	/* ABI complient stack frame */
	pushq %rbp
	movq %rsp, %rbp
	subq $0, %rsp

	movl %edi, %eax /* move parameter into return value */
	and $0xFF, %eax /* bitwise and with 0xFF */

	/* ABI complient stack frame */
	addq $0, %rsp
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
	subq $0, %rsp

	shll $24, %edi /* shift red left by 24 */
	shll $16, %esi /* shift green left by 16 */
	shll $8, %edx /* shift blue left by 8 */
	/* no need to shift a left */
	or %edi, %esi /* bitwise or for each rgba */
	or %esi, %edx
	or %edx, %ecx
	movl %ecx, %eax /* move that final result to the return value */

	/* ABI complient stack frame */
	addq $0, %rsp
	popq %rbp

	ret

/*
 * uint32_t to_grayscale( uint32_t pixel );
 *
 * Returns the a new pixel based on the 4 components.
 * This transformation always succeeds.
 *
 * Register use:
 *	%ebx - pixel red value
 *	%r12 - pixel green value
 *	%r13 - pixel blue value
 *	%r14 - pixel alpha value
 *	%r15 - greyscale color pixel value calculation result
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
	divl %r15d /* divide by 256 and put into %eax */
	
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
 *   %edi - forground pixel value
 *   %esi - background pixel value
 *   %edx - alpha pixel value
 */
	.globl blend_components
blend_components:
	/* ABI complient stack frame */
	pushq %rbp
	movq %rsp, %rbp
	subq $0, %rsp

	imull %edx, %edi
	movl $255, %r11d
	subl %edx, %r11d
	imull %r11d, %esi
	addl %edi, %esi /* esi now holds the numerator */
	
	movl %esi, %eax /* move the numerator calculated above into return value */
	movl $255, %r10d
	movl $0, %edx /* high 32 bits, need to manually push 0 in there */
	divl %r10d /* divide by 255 */

	popq %rbp

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
	/* ABI complient stack frame */
	pushq %rbp
	movq %rsp, %rbp
	subq $24, %rsp

	pushq %r12 /* push these registers to stack */
	pushq %r13
	pushq %r14

	movl %edi, %r12d /* holds fg pixel value */
	movl %esi, %r13d /* holds bg pixel value */

	call get_a
	movl %eax, %r14d /* holds alpha value */

	//BLENDING RED COMPONENT VALUES
	movl %r12d, %edi
	call get_r
	movl %eax, -4(%rbp) /* holds fg red value */

	movl %r13d, %edi
	call get_r
	movl %eax, -8(%rbp) /* holds bg red value */

	movl -4(%rbp), %edi
	movl -8(%rbp), %esi
	movl %r14d, %edx
	call blend_components
	movl %eax, -12(%rbp) /* storing local variables of the red component */

	//BLENDING GREEN COMPONENT VALUES
	movl %r12d, %edi
	call get_g
	movl %eax, -4(%rbp) /* holds fg green value */

	movl %r13d, %edi
	call get_g
	movl %eax, -8(%rbp) /* holds bg green value */

	movl -4(%rbp), %edi
	movl -8(%rbp), %esi
	movl %r14d, %edx
	call blend_components
	movl %eax, -16(%rbp) /* storing blended green component */

	//BLENDING BLUE COMPONENT VALUES
	movl %r12d, %edi
	call get_b
	movl %eax, -4(%rbp) /* holds fg green value */

	movl %r13d, %edi
	call get_b
	movl %eax, -8(%rbp) /* holds bg green value */

	movl -4(%rbp), %edi
	movl -8(%rbp), %esi
	movl %r14d, %edx
	call blend_components
	movl %eax, -20(%rbp) /* storing blended blue component */

	movl -12(%rbp), %edi
	movl -16(%rbp), %esi
	movl -20(%rbp), %edx
	movl $255, %ecx
	call make_pixel
	
	popq %r14
	popq %r13
	popq %r12
	
	addq $24, %rsp
	popq %rbp
	
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
 * Register use:
 *	%rbx - pointer to source data array
 *	%r8 - row loop counter (r)
 *	%r9 - column loop counter (c)
 *	%r10 - input image width
 *	%r11 - input image height
 *	%r12 - input image pixel index
 *	%r13 - output image pixel index
 *	%r14 - pixel value
 *	%r15 - pointer to output data array
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
 * Register use:
 *	%rbx - pointer to source data array
 *	%r8 - row loop counter (r)
 *	%r9 - column loop counter (c)
 *	%r10 - input image width
 *	%r11 - input image height
 *	%r12 - input image pixel index
 *	%r13 - output image pixel index
 *	%r14 - pixel value
 *	%r15 - pointer to output data array
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
	movq IMAGE_DATA_OFFSET(%rsi), %r15 /* move pointer to output source data array to %r15 */

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
	pushq %rbp
	movq %rsp, %rbp
	subq $8, %rsp

	pushq %rbx /* push registers into stack */
	pushq %r12
	pushq %r13
	pushq %r14
	pushq %r15

	movl %esi, %ebx /* holding our value for n */
	movq %rdi, %r12 /* holding input image pointer */
	movq %rdx, %r13 /* holding output image pointer */

	movl IMAGE_WIDTH_OFFSET(%r13), %edi
	movl IMAGE_HEIGHT_OFFSET(%r13), %esi
	movl %ebx, %edx
	call all_tiles_nonempty
	
	cmpl $1, %eax
	jne .LrowLoopTileFailEnd

	movl $0, %r14d /* initializing my outer loop counter to 0 (r)*/

	.LrowLoopTile:
		cmpl %ebx, %r14d /* r >= input height */
		jge .LrowLoopTileEnd /* if true, end row loop */

		movl $0, %r15d /* initializing my inner loop counter to 0 (c) */

	.LcolLoopTile:
		cmpl %ebx, %r15d /* c >= input width */
		jge .LcolLoopTileEnd /* if true, end column loop */

		movq %r13, %rdi
		movq %r12, %rsi
		movl %r14d, %edx
		movl %r15d, %ecx
		movl %ebx, %r8d

		call copy_tile
		
		incl %r15d /* c++ in for loop */
		jmp .LcolLoopTile

	.LcolLoopTileEnd:
		incl %r14d /* r++ in for loop */
		jmp .LrowLoopTile
	
	.LrowLoopTileFailEnd:
		movl $0, %eax
		jmp .LreturnTile

	.LrowLoopTileEnd:
		movl $1, %eax
	
	.LreturnTile:
		popq %r15 /* pop registers from stack */
		popq %r14
		popq %r13
		popq %r12
		popq %rbx

		addq $8, %rsp
		popq %rbp
	ret

/*
 * void imgproc_grayscale( struct Image *input_img, struct Image *output_img );
 *
 * Transform image by converting each pixel to grayscale.
 * This transformation always succeeds.
 *
 * Register use:
 *	%rbx - pointer to source data array
 *	%r12 - pixel loop uper bound
 *	%r13 - loop counter (ie. current pixel index)
 *	%r14 - pixel value
 *	%r15 - pointer to output data array
 *
 * Parameters:
 *   %rdi - pointer to original struct Image
 *   %rsi - pointer to output struct Image
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
	
	movq IMAGE_DATA_OFFSET(%rdi), %rbx /* move pointer to source data array to %rbx */
	movq IMAGE_DATA_OFFSET(%rsi), %r15 /* move pointer to output source data array to %r15 */

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
 * imgproc_composite( struct Image *base_img, struct Image *overlay_img, struct Image *output_img )
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
	/* ABI complient stackframe, meaningful stack trace in gdb */
	pushq %rbp
	movq %rsp, %rbp
	subq $8, %rsp

	pushq %rbx /* push registers into stack */
	pushq %r12
	pushq %r13
	pushq %r14
	pushq %r15

	movl IMAGE_HEIGHT_OFFSET(%rsi), %r10d
	movl IMAGE_WIDTH_OFFSET(%rsi), %r11d

	cmpl IMAGE_HEIGHT_OFFSET(%rdi), %r10d
	jne .LcompositeFails

	cmpl IMAGE_WIDTH_OFFSET(%rdi), %r11d
	jne .LcompositeFails
	
	movq IMAGE_DATA_OFFSET(%rsi), %rbx /* move pointer to forground data array to %rbx */
	movq IMAGE_DATA_OFFSET(%rdi), %r14 /* move pointer to background data array to %r14 */
	movq IMAGE_DATA_OFFSET(%rdx), %r15 /* move pointer to output source data array to %r15 */

	/* calculating loop upperbound */
	movl IMAGE_WIDTH_OFFSET(%rdi), %r12d /* move source image width to %r10d */
	imull IMAGE_HEIGHT_OFFSET(%rdi), %r12d /* multiply source image height by width to get total number of pixels */

	movl $0, %r13d /* initializing my loop counter to 0 --> this is also my index value */

	.LcompositeLoop:
		cmpl %r12d, %r13d /* r13 >= r12d */
		jge .LcompositeLoopEnd /* if true, end pixel loop */
		
		/* Load pixel values */
		movl (%rbx, %r13, 4), %edi /* forground pixel value */
		movl (%r14, %r13, 4), %esi /* background pixel value */

		/* blending the pixel values together */
		call blend_colors

		/* Store pixel in output_img->data[index] */
		movl %eax, (%r15, %r13, 4)

		incl %r13d /* counter for loop iterations; counter++ here */
		jmp .LcompositeLoop
	
	.LcompositeLoopEnd:
		movl $1, %eax
		jmp .LreturnCode

	.LcompositeFails:
		movl $0, %eax

	.LreturnCode:
		popq %r15 /* pop registers from stack */
		popq %r14
		popq %r13
		popq %r12
		popq %rbx

		addq $8, %rsp
		popq %rbp
	
	ret

/*
vim:ft=gas:
*/