;
;==================================================================================================
;   ROMWBW DEFAULT BUILD SETTINGS FOR DYNO
;==================================================================================================
;
; THIS FILE DEFINES THE DEFAULT CONFIGURATION SETTINGS FOR THE PLATFORM
; INDICATED ABOVE.  THESE SETTINGS DEFINE THE OFFICIAL BUILD FOR THIS
; PLATFORM AS DISTRIBUTED IN ROMWBW RELEASES.
;
; ROMWBW USES CASCADING CONFIGURATION FILES AS INDICATED BELOW:
;
; cfg_master.asm			- MASTER CONFIGURATION FILE DEFINES ALL POSSIBLE ROMWBW SETTINGS
; |
; +-> cfg_<platform>.asm		- PLATFORM SPECIFIC DEFAULT CONFIGURATION SETTINGS
;     |
;     +-> Config/<plt>_std.asm		- DEFAULT BUILD SETTINGS FOR PLATFORM
;         |
;         +-> Config/<plt>_<cust>.asm	- OPTIONAL CUSTOM USER SETTINGS
;
; THE TOP (MASTER CONFIGURATION) FILE DEFINES ALL POSSIBLE ROMWBW
; CONFIGURATION SETTINGS. EACH FILE BELOW THE MASTER CONFIGURATION FILE
; INHERITS THE CUMULATIVE SETTINGS OF THE FILES ABOVE IT AND MAY
; OVERRIDE THESE SETTINGS AS DESIRED.
;
; OTHER THAN THE TOP MASTER FILE, EACH FILE MUST "#INCLUDE" ITS PARENT
; FILE (SEE #INCLUDE STATEMENT BELOW).  THE TOP TWO FILES SHOULD NOT BE
; MODIFIED.
;
; TO CUSTOMIZE YOUR BUILD SETTINGS YOU SHOULD MODIFY THIS FILE, THE
; DEFAULT BUILD SETTINGS (Config/<platform>_std.asm) OR PREFERABLY
; CREATE AN OPTIONAL CUSTOM USER SETTINGS FILE THAT INCLUDES THE DEFAULT
; BUILD SETTINGS FILE (SEE EXAMPLE Config/SBC_user.asm).
;
; BY CREATING A CUSTOM USER SETTINGS FILE, YOU ARE LESS LIKELY TO BE
; IMPACTED BY FUTURE CHANGES BECAUSE YOU WILL ONLY BE INHERITING MOST
; OF YOUR SETTINGS WHICH WILL BE UPDATED BY AUTHORS AS ROMWBW EVOLVES.
;
; PLEASE REFER TO THE CUSTOM BUILD INSTRUCTIONS (README.TXT) IN THE
; SOURCE DIRECTORY (TWO DIRECTORIES ABOVE THIS ONE).
;
; *** WARNING: ASIDE FROM THE MASTER CONFIGURATION FILE, YOU MUST USE
; ".SET" TO OVERRIDE SETTINGS.  THE ASSEMBLER WILL ERROR IF YOU ATTEMPT
; TO USE ".EQU" BECAUSE IT WON'T LET YOU REDEFINE A SETTING WITH ".EQU".
;
#DEFINE	BOOT_DEFAULT	"H"		; DEFAULT BOOT LOADER CMD ON <CR> OR AUTO BOOT
;
#include "cfg_dyno.asm"
;
CPUOSC		.SET	18432000	; CPU OSC FREQ IN MHZ
CRTACT		.SET	FALSE		; ACTIVATE CRT (VDU,CVDU,PROPIO,ETC) AT STARTUP
;
Z180_CLKDIV	.SET	1		; Z180: CHK DIV: 0=OSC/2, 1=OSC, 2=OSC*2
Z180_MEMWAIT	.SET	0		; Z180: MEMORY WAIT STATES (0-3)
Z180_IOWAIT	.SET	1		; Z180: I/O WAIT STATES TO ADD ABOVE 1 W/S BUILT-IN (0-3)
;
ASCIENABLE	.SET	TRUE		; ASCI: ENABLE Z180 ASCI SERIAL DRIVER (ASCI.ASM)
;
FDENABLE	.SET	TRUE		; FD: ENABLE FLOPPY DISK DRIVER (FD.ASM)
;
PPIDEENABLE	.SET	TRUE		; PPIDE: ENABLE PARALLEL PORT IDE DISK DRIVER (PPIDE.ASM)
