; vi: syntax=asmM6502 ts=4 sw=4

; Acornsoft Planetoid, BBC Micro
; Written by Neil Raine, 1982
; 6502 disassembly by rainbow
; 2020.02.08
; <djrainbow50@gmail.com>
; https://github.com/r41n60w/planetoid-disasm

; Constants/equates

NULL		=	0
FALSE		=	0
TRUE		=	1
LEFT		=	0	;_xwinedge[2]
RIGHT		=	1	; "

KEYUP		=	0		;$00
KEYDOWN		=	-1		;$ff
;typedef	int	inkey_t;
KEY_SHIFT	=	-1		;$ff
KEY_P		=	-56		;$c8
KEY_A		=	-66		;$be
KEY_AT		=	-72		;$b8
KEY_RETURN	=	-74		;$b6
KEY_TAB		=	-97		;$9f
KEY_Z		=	-98		;$9e
KEY_SPACE	=	-99		;$9d
KEY_ESCAPE	=	-113	;$8f

;typedef unsigned	colour_t;
;typedef struct	{
;	colour_t	logical		: 4;
;	colour_t	physical	: 4;
;} palette_t;
;enum palettes	{
PAL_BG		=	$00 ; bomb -> flash white
PAL_ROT1	=	$10 ; [ x3
PAL_ROT2	=	$20 ; [ rotate b/w
PAL_ROT3	=	$30 ; [ red, yellow, blue
PAL_FLASH	=	$40 ; mutant, pod, digits
PAL_SHIP2	=	$50 ; magenta
PAL_SURF	=	$60 ; red, green lvl x5
PAL_SHIP	=	$70 ; ship hit ->flash red
PALX_CLEAR	=	$80 ; centre of baiter
PALX_UNITR	=	$90 ; pod, swarmer
PALX_UNITG	=	$a0 ;[ land/mut,bait,human
PALX_UNITY	=	$b0 ;[ above x4 + swarmer
PALX_UNITB	=	$c0 ; bomber?
PALX_UNITM	=	$d0
PALX_UNITC	=	$e0
PALX_METAL	=	$f0 ;bullet/mine,ship hull
;};

;enum colours	{
BLACK		=	0
RED			=	1
GREEN		=	2
YELLOW		=	3
BLUE		=	4
MAGENTA		=	5
CYAN		=	6
WHITE		=	7
;};

;typedef int8_t id_t;
;enum ids	{
SHIP		=	0	;ship slot	
HITCH		=	1	;hitch hiker(s) slot
ID_MIN		=	2	;U0  first unit slot
ID_MAX		=	31	;Uf  last  unit slot
ID_BULLET1	=	32	;O
ID_BULLET2	=	33
ID_ALT1		=	34
ID_ALT2		=	35
ID_ALT3		=	36
;};

;typedef int	sprite_t;
;typedef struct {
;	unsigned	state	: 1;
;	sprite_t	sprite	: 7:
;} unit_t;
;extern unit_t	Unit[37];
BLIT		=	$00			;bit 7 clear
UPDATE		=	$80			;bit 7 set
;enum sprites	{
EMPTY		=	-1			;$ff,bit 6 set
U_SHIP		=	0
LANDER		=	1	;+ man -> mutant
MUTANT		=	2
BAITER		=	3
BOMBER		=	4
SWARMER		=	5	;spawned on Pod death
MAN			=	6	
POD			=	7
KUGEL		=	8	;bullet or mine
S250		=	9	;flashing '250' points
S500		=	10	;         '500'
;};

;extern	int8_t	Anim[37];
;enum anims	{
WARP		=	1			;$01 +hyperspc
HAL			=	(1 << 6)	;$40 hyper die
BLAST		=	-1			;$ff
;};

;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

;Address equates
SHEILA		=	$fe00
ULAPALETTE	=	$fe21
SYS6522		=	$fe40
USR6522		=	$fe60
OSRDCH		=	$ffe0
OSWRCH		=	$ffee
OSWORD		=	$fff1
OSBYTE		=	$fff4
IRQ1V		=	$204
VRAM		=	$3000

;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

; Zero page variables (prefix _zp)

;BCD vars
_level		=	$16
_humanbonus =	$17
_score_lsb	=	$30
_score_100	=	$31 ; mmh,hll points
_score_msb	=	$32
_lives		=	$37
_bombs		=	$38
_high_rank	=	$43	; hiscores #1 to #8

;Counters
_framec_l	=	$10	
_framec_h	=	$11	
_count		=	$12
_enemyc		=	$13	; not baiters/humans
_squaddelay	=	$14
_humanc		=	$15
_baitdelay_l=	$18
_baitdelay_h=	$19
_hikerc		=	$2d ;hitchhikers(rescuees)
_flpalc		=	$35
_flpalframes=	$36
_rotpalc	=	$3d

;Sprite/id
_id_alt		=	$22
_batch		=	$25
_batchc		=	$26
_spawn_spr	=	$27
_id			=	$89

;Palette
_bgpal		=	$0f	; logical colour 0
_shippal	=	$3c		; " 7
_surfpal	=	$3e		; " 6
_flashc		=	$34

;Blit/Print
_leading0	=	$33	; 0: leading blanks
_strlen		=	$44
_dest_crow	=	$74  ; vram cell row 0-7
_imglen		=	$75
_heightmask	=	$84
_paintmask	=	$8a
_collision	=	$8b

;Keycode
_inkey_tab	= 	$0e
_inkey_space= 	$23
_inkey_enter= 	$2b

;Pointers + ptr offsets
_scrolloff_l=	$02
_scrolloff_h=	$03
_oldorgp	=	$00
_oldorgp_l	=	$00
_oldorgp_h	=	$01
_originp	=	$08
_originp_l	=	$08	
_originp_h	=	$09	
_digitp		=	$2e	; start of digit row
_digitp_l	=	$2e ; in vram
_digitp_h	=	$2f
_destptr	=	$70
_destptr_l	=	$70
_destptr_h	=	$71
_srcptr		=	$72
_srcptr_l	=	$72
_srcptr_h	=	$73

;Screen coords
_min_xscr	=	$28
_max_xscr	=	$29
_ship_xscr	=	$2c
_anim_xscr	=	$7a
_beam_yscr	=	$7c
_xscrc		= 	$7e
;Scaled coords
_xwin		=	$0a
_xwinedge	=	$0c		; [2]
_xwinleft	=	$0c		; " + LEFT
_xwinright	=	$0d		; " + RIGHT
_dxwin		=	$2a
_dxwinc		=	$78
_dxedge		=	$88	; laser L=-_dxwin,R
; Raw coords
_ddx_l		=	$1c
_ddx_h		=	$1d
_dxrel_l	=	$1e
_dxrel_h	=	$1f
_xrel_l		=	$20
_xrel_h		=	$21

;Booleans
_no_planet	=	$1a		;0/1
_dead		=	$24		;FALSE/TRUE
_bomb_pass2	=	$3b
_is_spawning=	$40

;Laser tables
_Laser		=	$46		;[4] $47,$48,$49
_Tail		=	$4a		;[4] imgLaser[x]
_Head		=	$4e		;[4] "
_BeamX		=	$52		;[4]
_BeamY		=	$56 	;[4]
_pTail_l	=	$5a		;[4] laser @vram
_pTail_h	=	$5e		;[4]
_pHead_l	=	$62		;[4]
_pHead_h	=	$66		;[4]
_laserc		=	$87

;Misc
_gameover_sp=	$39		;
_nextlvl_sp	=	$3f
_irq1v		=	$8c		;*(IRQ1V)
_vsync0		=	$1b		;last vsync ctr
_savedx		=	$41
_savedy		=	$42
_xreg		=	$85
_yreg		=	$86
_rand_h		=	$80		;random buffer
_rand_m		=	$81
_rand_l		=	$82

;Temp
_temp		=	$76
_temp_l		=	$76
_temp_h		=	$77
_temp2		=	$77
_offset_l	=	$76
_offset_h	=	$77

;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

; Tables (pages 4-7)
X_l			=	$400	;[37]
X_h			=	$425	;[37]
Y_l			=	$44a	;[37]
Y_h			=	$46f 	;[37]
dX_l		=	$494	;[37]
dX_h		=	$4b9	;[37]
dY_l		=	$4de	;[37]
dY_h		=	$503 	;[37]
pSprite_l	=	$528	;(void *)[37]
pSprite_h	=	$54d	;sprite ptr @vram
pNext_l		=	$572	;(void *)[37]
pNext_h		=	$597	;next spr pos@vram
Unit		=	$5bc	;sprite_t[37]
Param		=	$5e1	;count[37], flags
pDot_l		=	$606	;[32]
pDot_h		=	$626	;[32]
Anim		=	$646	;flags[37]
Dot			=	$66b	;idx[37] spr#x2
HiScore		=	$700	;hiscore_t[7] =168
