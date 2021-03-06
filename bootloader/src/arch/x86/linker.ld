ENTRY(_boot_entry)

SECTIONS {
    . = 0x7c00;

    /*
     * Remove garbage .eh_frame section - we don't need it
     * and it offsets the address calculation for the entire binary
     * so that when we use objcopy to grab only the .text section,
     * the addresses (e.g. the far jump into protected mode) are shifted
     * causing problems.
     */
    /DISCARD/ : {
        *(.eh_frame*)
        *(.gcc_*)
    }

    .bootloader :
    {
        __start = .;

        *(.stage0_text)

        __text_end = .;
        __text_size = __text_end - __start;

        /* Magic number
         * We could have put this in the actual stage0.s, but TBH this
         * is a better place since we don't have to deal with
         * janky assembly address math
         */
        . = . + (0x200 - 0x2 - __text_size);
        SHORT(0xAA55);

        ASSERT(__text_size < 512, "Text Segment too big for MBR");

        __stage2_entry = .;

        /**
         * @improvement:
         * We put Rust text after the magic number (effectively starting at the
         * second sector) because Rust code is gonna grow pretty big, later on
         * we might be able to cut the Rust code into chunks to reduce the file
         * size, but that's for later.
         */
        __rust_text_start = .;
        *(.rust_text)
        __rust_text_end   = .;

        __text_end = .;
    }

    /** Just in case rodata is placed defautly before our .text */
    .rodata      : ALIGN(16)    { *(.rodata.*) }
    .data_rel_ro : ALIGN(4)     { *(.data_rel_ro) }
    .got         : ALIGN(4)     { *(.got) }
    .got_plt     : ALIGN(4)     { *(.got_plt) }

    __end = .;

    /** Calculate how many sectors the entire program needs */
    __all_sector_count =  (__end - __stage2_entry) / 512 + 1;
}
