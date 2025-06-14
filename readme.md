Made for `zig 0.15.0-dev.79`, seems some higher versions break some bit shifts which result in failed tests.

# References
[Pandocs - Memory Map](https://gbdev.io/pandocs/Memory_Map.html)  
[GBDev - SM83 instruction set](https://gbdev.io/gb-opcodes/optables/)  
[RGBDS - opcode reference](https://rgbds.gbdev.io/docs/v0.9.2/gbz80.7)  
[Gekkio - Game Boy: Complete Technical Reference](https://gekkio.fi/files/gb-docs/gbctr.pdf)  
[wheremyfoodat - Gameboy logs](https://github.com/wheremyfoodat/Gameboy-logs)  
[Blargg - test roms](https://github.com/L-P/blargg-test-roms/)

# Status
## Misc
| Test         | Status |
| ------------ | ------ |
| dmg_boot.bin |        |
## Blargg
### cpu_instrs
| Test                     | Status |
| ------------------------ | ------ |
| 01-special.gb            | ✅ pass |
| 02-interrupts.gb         | fail ❎ |
| 03-op sp,hl.gb           | ✅ pass |
| 04-op r,imm.gb           | ✅ pass |
| 05-op rp.gb              | ✅ pass |
| 06-ld r,r.gb             | ✅ pass |
| 07-jr,jp,call,ret,rst.gb | ✅ pass |
| 08-misc instrs.gb        | ✅ pass |
| 09-op r,r.gb             | fail ❎ |
| 10-bit ops.gb            | ✅ pass |
| 11-op a,(hl).gb          | fail ❎ |