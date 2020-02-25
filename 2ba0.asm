; vi: syntax=asmM6502 ts=4 sw=4

; Acornsoft Planetoid, BBC Micro
; Written by Neil Raine, 1982
; 6502 disassembly by rainbow
; 2020.02.08
; <djrainbow50@gmail.com>
; https://github.com/r41n60w/planetoid-disasm

;$2ba0 -> $2fef:
;	global vars x2 (vsync, rotatec)
;	all tables	
;$3040 -> $3057:
;	default high score

			org		$2ba0

;$2ba0	32 unused bytes
.byte	0,8,0,8,0,8,0,0,0,0,4,4,4,8,8,4
.byte	4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4

;$2bc0 [64]
;Packed 2-bit surface tiles (256) 4/byte
;Corresponds to YSurface[256]
SurfQuad:
.byte	$2a,$00,$55,$55,$65,$66,$9a,$a9
.byte	$00,$01,$44,$55,$55,$55,$a5,$2a
.byte	$80,$2a,$08,$42,$55,$55,$55,$66
.byte	$66,$a6,$a6,$09,$82,$50,$10,$11
.byte	$41,$54,$55,$55,$55,$55,$55,$2a
.byte	$88,$08,$50,$69,$55,$55,$55,$55
.byte	$55,$55,$55,$55,$99,$a9,$99,$99
.byte	$19,$50,$40,$14,$54,$55,$55
;.byte	$95 (1st byte of imgLaser[] below)

;$2bff	vram_t[81]
;Laser beam sprite data (Tail to Head)
;[0] never used, Tail starts at [1]
;colours: $00 bb, $10 bF, $20 Fb, $30 FF
imgLaser:	.byte	$95			;unused
.byte	$00,$00,$30,$00,$20,$30,$10,$30
.byte	$00,$30,$30,$20,$30,$30,$00,$30
.byte	$30,$30,$30,$30,$30,$30,$30,$30
.byte	$30,$30,$30,$30,$30,$30,$30,$30
.byte	$30,$30,$30,$30,$30,$30,$30,$30
.byte	$30,$30,$30,$30,$30,$30,$30,$30
.byte	$30,$30,$30,$30,$30,$30,$30,$30
.byte	$30,$30,$30,$30,$30,$30,$30,$30
.byte	$30,$30,$30,$30,$30,$30,$30,$30
.byte	$30,$30,$30,$30,$30,$30,$30,$30

;$2c50	xoffset_t[8]
;Warp animation point Xscr coord offsets
WarpX:		
.byte	 80, 80, 40,  0,  0,  0, 40, 80

;$2c58	yoffset_t[8]
;Warp animation point Y coord offsets
WarpY:	
.byte	 96,-64,-64,-64, 96,  0,  0,  0

;$2c60	xoffset_t[8]
;Blast animation point Xscr coord offsets
BlastX:		
.byte	  2,  4,  0, -4, -2, -4,  0,  4

;$2c68	yoffset_t[8]
;Blast animation point Y coord offsets
BlastY:		
.byte	  0, 12,  6, 12,  0,-12, -6,-12

;$2c70	palette_t[8]
;PAL_FLASH (flashing) colour palettes
FlashPal:
.byte	$45,$42,$46,$43,$47,$43,$46,$42

;$2c78	inkey_t[7]
;Hyperspace keycode (-ve INKEY) table
HyperKeys:
.byte	 -84, -69, -54, -70, -86,-101, -85

;$2c7f	1 unused byte (see match below)
			.byte	$28

;$2c80	int16_t[4] -> 8 bytes
;OSWORD parameter block, 4 signed words
;NB: This matches 9 bytes at YSurface[$7f]
ParamBlk:
.byte	$25,$24,$20,$1d,$1c,$19,$19,$19

;SOUND parameters (5x) below:

;MSB of Channel/HSFC (first SOUND param)
;  Hold always off
;LSB of Channel/HSFC (first SOUND param)
;  Flush always on
;LSB of Amplitude (second SOUND param)
;  [0,-15] amplitude / [1-4] envelope #
;LSB of Pitch (third SOUND param)
;LSB of Duration (fourth SOUND param)

;$2c88	uint8_t[20] # synced voices
HoldSync:
.byte	$02,  2,  2,$00,$01,  1,$01,  1
.byte	$01,  1,$01,  1,$01,  1,$00,$00
.byte	$01,  1,$00,$00

;$2c9c	uint8_t[20] sound channel #
FlushChan:
.byte	$11,$12,$13,$10,$11,$10,$11,$10
.byte	$11,$10,$11,$10,$11,$10,$12,$12
.byte	$11,$10,$13,$12

;$2cb0	int8_t[20] (-ve)amplitude/envelope
AmplEnvel:
.byte	-10,-10,-10,  0,  1,-12,  2,-10
.byte	  1,-10,  1,-15,  1,-15,  3,  3
.byte	  1,-15,  4,  3

;$2cc4	uint8_t[20] sound frequency [0,ff]
Pitch:
.byte	  0,  0,  0,  0,230,  7,100,  7
.byte	255,  7,180,  7,130,  7, 50, 20
.byte	255,  3,  0,170

;$2cd8	uint8_t[20] note length [0,ff]
Duration:
.byte	 50, 50, 50,  0,255, 30,255, 12
.byte	255,  2,255, 17,255, 40,  8,  8
.byte	255, 60, 35,  8

;$2cec	20 unused bytes
;NB: This matches bytes at YSurface[$ec]
.byte	$28,$25,$25,$24,$20,$1d,$1d,$1d
.byte	$1d,$1d,$1d,$1d,$1d,$1d,$1d,$1d
.byte	$1d,$1d,$1d,$1e

;$2d00	size_t[11]
;Sprite data lengths [#SHIP -> #S500]
SpriteLen:
;		SHIP LAND  MUT BAIT BOMB SWAR
.byte	  48,  32,  32,  20,  24,  12
.byte	   8,  24,   2,  40,  40
;		 MAN  POD KUGL S250 S500

;$2d0b	(uint8_t) vram_t * [11]
;LSB of vectors to sprite data
SpriteV_l:
.byte	<imgShipR,  <imgLander,<imgMutant
.byte	<imgBaiter, <imgBomber,<imgSwarmer
.byte	<imgMan,    <imgPod,   <imgKugel
.byte	<img250,    <img500

;$2d16	(uint8_t) vram_t *[11] vector MSBs
SpriteV_h:
.byte	>imgShipR,  >imgLander,>imgMutant
.byte	>imgBaiter, >imgBomber,>imgSwarmer
.byte	>imgMan,    >imgPod,   >imgKugel
.byte	>img250,    >img500

;$2d21	vram_t[11][2]
;Minimap dots (2x2px) for each sprite #
;		SHIP     LAND     MUT      BAIT
imgDot:    ;BOMB     SWAR     MAN      POD
.byte	$ff,$ff, $8a,$88, $a2,$88, $88,$88
.byte	$a2,$a2, $82,$8a, $a8,$a8, $20,$88
.byte	$00,$d8, $00,$00, $00,$ff
;		KUGL     S250     S500

;$2d37	vram_t[11][2]
;imgDot[] dots, >> 1 pixel to the right
imgDotR:
.byte	$ff,$ff, $45,$44, $51,$44, $44,$44
.byte	$51,$51, $41,$45, $54,$54, $10,$10
.byte	$00,$6c, $00,$00, $00,$7f

;$2d4d	size_t[11]
;Sprite height bitmask (-> _heightmask)
SpriteMaxY:
;		SHIP LAND  MUT BAIT BOMB SWAR
.byte	   7,   7,   7,   3,   7,   3
.byte	  15,   7,   3,   7,   7
;		 MAN  POD KUGL S250 S500

;$2d58	bcd_t[11] unit point scores (x1)
Points_l:
;		SHIP LAND  MUT BAIT BOMB SWAR
.byte	 $00, $50, $50, $50, $00, $50
.byte	 $00, $00, $25, $00, $00
;		 MAN  POD KUGL S250 S500

;$2d63	bcd_t[11] unit point scores (x100)
Points_h:
.byte	 $00, $01, $01, $01, $02, $02
.byte	 $00, $10, $00, $00, $00

;$2d6e	bool[11] unit 'warp in' animation 
DoWarp:
;		SHIP LAND  MUT BAIT BOMB SWAR
.byte	   0,   1,   1,   1,   1,   0
.byte	   0,   1,   0,   0,   0
;		 MAN  POD KUGL S250 S500

;$2d79	135 unused bytes
.byte	$bb,$ca,$ba,$aa,$9b,$ab,$60
.byte	$10,$01,$f1,$ff,$07,$00,$28,$00
.byte	$02,$02,$02,$00,$01,$01,$01,$01
.byte	$01,$01,$01,$01,$01,$01,$00,$00
.byte	$01,$01,$00,$00,$11,$12,$13,$10
.byte	$11,$10,$11,$10,$11,$10,$11,$10
.byte	$11,$10,$12,$12,$11,$10,$13,$12
.byte	$f6,$f6,$f6,$00,$01,$f4,$02,$f6
.byte	$01,$f6,$01,$f1,$01,$f1,$03,$03
		;$2dc0
.byte	$01,$f1,$04,$03,$00,$00,$00,$00
.byte	$e6,$07,$64,$07,$ff,$07,$b4,$07
.byte	$82,$07,$32,$14,$ff,$03,$00,$0a
.byte	$32,$32,$32,$00,$ff,$1e,$ff,$0c
.byte	$ff,$02,$ff,$11,$ff,$28,$08,$08
.byte	$ff,$3c,$23,$08,$20,$38,$30,$30
.byte	$30,$0d,$35,$31,$30,$20,$21,$2c
.byte	$4d,$31,$39,$47,$3f,$58,$57,$80

;$2e00	uint8_t vsync count -> irq_hook()
vsync:		.byte		$30

;$2e01	uint8_t  index into RotColour[3]
rotatec:	.byte		0

;$2e02	colour_t[3]  PAL_ROTx colours
RotColour:	.byte		RED, YELLOW, BLUE
;						$01,    $03,  $04

;$2e05	void (*)(int)[11]
;Vector table to all unit AI routines
AiVector:
.word	ai_ship,	ai_lander,	ai_mutant
.word	ai_baiter,	ai_bomber,	ai_swarmer
.word	ai_human,	ai_pod
.word	ai_object,	ai_object,	ai_object

;$2e1b  2 unused bytes
			.word		0

;$2e1d  uint8_t[8]  Unit spawn counts
Spawnc:	
.byte	  0,  5,  0,  0,  4,  0,  0,  0
;		SHP LAN MUT BAI BOM SWM MAN POD

;$2e25	xpos_t[8]  Initial unit minimum X
XMinInit:
.byte	  7,  0, 64,  0, 64,  0,  0,  0

;$2e2d	uint8_t[8]  Initial unit X range
XRangeInit:
.byte	  0,255,127, 15,  7,  0,255, 63

;$2e35	ypos_t[8]  Initial unit minimum Y
YMinInit:
.byte	100,180,  0,  0,  0,  0, 10,  0
;		SHP LND MUT BAI BOM SWM MAN POD

;$2e3d	uint8_t[8]  Initial unit Y range
YRangeInit:
.byte	  0,  0,255,255,255, 31,  0,255

;$2e45	xoffset_t[8] Init minimum dX (abs)
dXMinInit:
.byte	  2, 24,  0, 10, 24, 50,  4,  8

;$2e4d	uint8_t[8]  Initial unit dX range
dXRangeInit:
.byte	  7, 15,  0,  7, 15,  7,  0,  7
;		SHP LND MUT BAI BOM SWM MAN POD

;$2e55	yoffset_t[8] Init minimum dY (abs)
dYMinInit:
.byte	 10,  0,  0, 10,  0, 24,  0,  8

;$2e5d	uint8_t[8]  Initial unit dY range
dYRangeInit:
.byte	 63,  0,  0,  7, 15,  7,  0,  7

;typedef struct	{
;	uint8_t		len;
;	char		str[];
;} string_t;

;$2e65	(uint8_t) string_t * [7]
;LSB of string pointers
StringV_l:
.byte	<string0,	<string1,	<string2,
.byte	<string3,	<string4,	<string5,
.byte	<string6

;$2e6c	13 unused bytes
.byte	$9c,$c4,$c4,$c8,$3c,$ac,$a4,$8c
.byte	$78,$cc,$90,$8c,$a0

;$2e79	(uint8_t) string_t * [7]
;MSB of string pointers
StringV_h:
.byte	>string0,	>string1,	>string2,
.byte	>string3,	>string4,	>string5,
.byte	>string6

;$2e80	13 unused bytes
.byte	$00,$00,$03,$00,$00,$00,$00,$00
.byte	$00,$fc,$00,$00,$03

;$2e8d	string_t[3]  Message string #0
string0:	.byte	  2	;length
.byte		 12		;clear text
.byte		 20		;restore def palette

;$2e90	string_t[25]  Message string #1
string1:	.byte	 24	;len
.byte	 17,  4			;txt clr PAL_FLASH
.byte	 31,  4, 12		;cursor (4,12)
.byte	224,225,226,227,228,229,' '
.byte	230,231,232,233,234
.byte	 31,  7, 15		;cursor (7,15)
.byte	235,236,237,238

;$2ea9	string_t[12]  Message string #2
string2:	.byte	11	;len
.byte	 31,  7, 15		;cursor (7,15)
.byte	 17,  4			;text colour #4
.byte	239,240,' ',' '
.byte	241,242

;$2eb5	string_t[64]  Message string #3
string3:	.byte	63	;len
.byte	 22,  7			;MODE 7
.byte	$81,$9d,$83,$8d
.byte	 31,  9,  0		;cursor (9,0)
.byte	"Planetoid Hall of Fame" ;row 1
.byte	 31,  0,  1		;cursor (0,1)
.byte	$81,$9d,$83,$8d	;double height
.byte	 31,  9,  1		;cursor (9,1)
.byte	"Planetoid Hall of Fame" ;row 2


;$2ef5	string_t[68]  Message string #4
string4:	.byte	67	;len
.byte	 31, 11,  3		;cursor (11,3)
.byte	$86,$8d			;double height
.byte	"Congratulations"	;row 1
.byte	 31, 11,  4		;cursor (11,4)
.byte	$86,$8d
.byte	"Congratulations"	;row 2
.byte	 31,  8, 23		;cursor (8,23)
.byte	$86,$88
.byte	"Please enter your name"

;$2f39	string_t[6]  Message string #5
string5:	.byte	5
.byte	" ... "

;$2f3f	string_t[81]  Message string #6
string6:	.byte	80
.byte	 31, 10,  3		;cursor (10,3)
.byte	$8d,$86			;double height
.byte	"Today's Greatest" ;row 1
.byte	 31, 10,  4		;(10,4)
.byte	$8d,$86
.byte	"Today's Greatest" ;row 2
.byte	 31,  2, 17		;(2,17)
.byte	$86,$88
.byte	"Press the SPACE BAR "
.byte	"to play again"

;$3040	hiscore_t[24]  Default high score
DefHigh:	.byte	  0,$10,$00	;1000pts
			.byte	"Acornsoft\r"	
			.word	  0,  0,  0,  0,  0
			.byte	  0
