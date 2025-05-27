cd xgm
..\vasmm68k_mot -Fbin -nosym -o plugin_xgm.bin plugin_xgm.asm
cd ..\amiga_boot_sector
..\vasmm68k_mot -Fbin -nosym -o bootsector.bin bootsector.asm
pause

