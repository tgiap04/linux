savedcmd_covert.o := ld -EL  -maarch64elf -z noexecstack --no-warn-rwx-segments   -r -o covert.o @covert.mod 
