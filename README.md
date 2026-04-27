This is a simple bootloader written in NASM assembly.
To run it yourself, you need to make sure that the kernel code is placed at LBA 
sector 1 on the disk image, as the bootloader will read 100 sectors starting from 
there and load them into memory at address 0x10000, then jump to it.
