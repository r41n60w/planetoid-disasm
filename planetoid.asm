; vi: syntax=asmM6502 ts=4 sw=4

; Acornsoft Planetoid, BBC Micro
; Written by Neil Raine, 1982

; 6502 disassembly by rainbow
; 2020.02.08
; <djrainbow50@gmail.com>
; https://github.com/r41n60w/planetoid-disasm

; object code in file: PLANET2
; 8960 bytes, ~35 pages

; this is a work in progress!

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

FALSE		=	0
TRUE		=	1
LEFT		=	0	;_xwinedge[2]
RIGHT		=	1	; "
NULL		=	0
KEYDOWN		=	-1	;$ff

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

SHIP		=	0
HITCH		=	1
ID_MIN		=	2
ID_MAX		=	31
ID_BULLET1	=	32
ID_BULLET2	=	33
ID_ALT1		=	34
ID_ALT2		=	35
ID_ALT3		=	36

EMPTY		=	-1	; $ff, bit 6 set
UPDATE		=	$80
BLIT		=	$00
U_SHIP		=	0
LANDER		=	1
MUTANT		=	2
BAITER		=	3
BOMBER		=	4
SWARMER		=	5
HUMAN		=	6
POD			=	7
KUGEL		=	8  ; bullet or mine
S250		=	9
S500		=	10

; Zero page vars (_zpvar)
_level		=	$16
_humanbonus =	$17
_score_lsb	=	$30	; all BCD
_score_100	=	$31 ; mmh,hll points
_score_msb	=	$32
_lives		=	$37
_bombs		=	$38
_high_rank	=	$43	; hiscores #1 to #8

_framec_l	=	$10	
_framec_h	=	$11	
_flpalc		=	$35
_flpalframes=	$36
_rotpalc	=	$3d
_count		=	$12
_enemyc		=	$13	; not baiters/humans
_humanc		=	$15
_hikerc		=	$2d ;hitchhikers(rescuees)

_squaddelay	=	$14
_baitdelay_l=	$18
_baitdelay_h=	$19
_spawn_spr	=	$27

_id_alt		=	$22
_batchc		=	$25
_batch		=	$26

_no_planet	=	$1a		; booleans 0/1
_dead		=	$24
_bomb_pass2	=	$3b
_is_spawning=	$40

_Laser		=	$46		;[4] $47,$48,$49
_Tail		=	$4a		;[4] LASERPX[x]
_Head		=	$4e		;[4] "
_BeamX		=	$52		;[4]
_BeamY		=	$56 	;[4]
_pTail_l	=	$5a		;[4] laser @vram
_pTail_h	=	$5e		;[4]
_pHead_l	=	$62		;[4]
_pHead_h	=	$66		;[4]
_laserc		=	$87

_inkey_tab	= 	$0e
_inkey_space= 	$23
_inkey_enter= 	$2b
_leading0	=	$33	; 0: leading blanks
_strlen		=	$44

_gameover_sp=	$39
_nextlvl_sp	=	$3f
_savedirq	=	$8c
_savedvbks	=	$1b
_savedx		=	$41
_savedy		=	$42
_xreg		=	$85
_yreg		=	$86
_id			=	$89

_bgpal		=	$0f	; logical colour 0
_shippal	=	$3c		; " 7
_surfpal	=	$3e		; " 6
_flashc		=	$34

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

_dest_crow	=	$74  ; vram cell row 0-7
_imglen		=	$75
_heightmask	=	$84
_paintmask	=	$8a
_collision	=	$8b

_min_xscr	=	$28
_max_xscr	=	$29
_ship_xscr	=	$2c
_anim_xscr	=	$7a
_beam_yscr	=	$7c
_xscrc		= 	$7e

_xwin		=	$0a
_xwinedge	=	$0c		; [2]
_xwinleft	=	$0c		; " + LEFT
_xwinright	=	$0d		; " + RIGHT
_dxwin		=	$2a
_dxwinc		=	$78
_dxedge		=	$88	; laser L=-_dxwin,R

_ddx_l		=	$1c
_ddx_h		=	$1d
_dxrel_l	=	$1e
_dxrel_h	=	$1f
_xrel_l		=	$20
_xrel_h		=	$21

_rand_h		=	$80
_rand_m		=	$81
_rand_l		=	$82

_ptr76		=	$76
_temp76		=	$76
_word76		=	$76
_temp		=	$76
_temp_l		=	$76
_temp_h		=	$77
_temp2		=	$77
_offset_l	=	$76
_offset_h	=	$77

; TABLES @pages 4-7)
X_l			=	$400	;[37]
X_h			=	$425
Y_l			=	$44a	;[37]
Y_h			=	$46f 
dX_l		=	$494
dX_h		=	$4b9
dY_l		=	$4de
dY_h		=	$503 
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

;Tables etc. within code
YSURFACE	=	$e00	;whole page
DIGITS		=	$f00	;[10][16]
SPR_SHIPR	=	$fc0	;[6][8]
SPR_SHIPL	=	$ff0	;[6][8]
SURFTILES	=	$1020	;[3][4]
SURFQUAD	=	$2bc0	;[64]4x2bit packed
XBLAST		=	$2c60	;[8]
YBLAST		=	$2c68	;[8]
FLASHPAL	=	$2c70	;[8] $4<c>
HYPERKEYS	=	$2c78	;hypersp kcodes[7]
paramblock	=	$2c80	;OSWORD,max 8bytes
SPRITELEN	=	$2d00
SPRITEV_L	=	$2d0b
SPRITEV_H	=	$2d16
MAP_DOT		=	$2d21	; [2][2][11]
SPR_HEIGHT	=	$2d4d
U_SCORES1	=	$2d58
U_SCORES100	=	$2d63
ANIMATESPW	=	$2d6e	; bool[11]
vblankc		=	$2e00
rotatec		=	$2e01
ROT_CLRS	=	$2e02	; [3]
AIVECTOR	=	$2e05	; 11 addrs/22B
; " hi			 2e06

SPAWNC		=	$2e1d	; type[8]
XMIN_INIT	=	$2e25
YMIN_INIT	=	$2e35
DXMIN_INIT	=	$2e45
DYMIN_INIT	=	$2e55
XRANGE_INIT	=	$2e2d
YRANGE_INIT	=	$2e3d
DXRANGE_INIT=	$2e4d
DYRANGE_INIT=	$2e5d
PSTRS_L		=	$2e65	; both 6 bytes
PSTRS_H		=	$2e79
DEFAULTHI	=	$3040

;fc0
img0_shipr:
.byte	$15,$3f,$15,$11,$11,$11,$33,$11
.byte	0,$2a,$3f,$3f,$37,$33,$33,$33
.byte	0,0,0,$2a,$3f,$3f,$3f,$37
.byte	0,0,0,0,0,$3f,$3f,$3f
.byte	0,0,0,0,0,7,7,$3f
.byte	0,0,0,0,0,8,$1d,$3f

; @PLANET1
; *L. PLANET2:CALL &1100
entrypoint:	jmp		boot		;1100 3000

; IRQ1V vectors here
irq1v_hook:	lda		#2	 ;1103  system VIA
			bit		SYS6522+13 ;IRQ status
			beq		+		   ;bit 1 set?
			inc		vblankc    ; -> vsync
+			jmp		(!_savedirq) ;go back

;void		wait_vblank(u8, u8 *last);
; busy wait until vblank
wait_vblank:lda		vblankc		  ;1110
			cmp		_vblankc_last ;vsync?
			beq		wait_vblank   ;no,loop
			sta		_vblankc_last 
			rts

;bool		is_vblank(u8, u8);
is_vblank:	lda		vblankc		;111a
			cmp		_vblankc_last
			rts
; 
; map _p_hysical colour to _l_ogical 
set_palette:pha					;1120	 
			eor		#%111		;llllpppp 
			sta		SHEILA +$21 ;video ULA
			pla			   ;reg "Palette"
			rts

out6845:	stx		SHEILA		;reg# 1128
			sta		SHEILA + 1	;byte out
			rts

; T1: 1-shot mode, disable latch/shift reg
; load low-order latch, high-order counter
; autostarts timer @1MHz(2?)
start_timer:lda		#%10000000	;aux 112f
			sta		USR6522 +11	;ctrl reg
			stx		USR6522 +4	;T1C-L
			sty		USR6522 +5	;T1C-H
			rts		

; test input reg B
timerstate:	bit		USR6522 +0	;113b
			rts  	;return PB7 -> N

ai_batch:	ldx		#SHIP
			jsr		get_xscr		;useless?
			sta		_ship_xscr	;2c
			lda		#0
			sta		_min_xscr
			lda		#77
			sta		_max_xscr

			lda		_scrolloff_l
			bpl		+			;if(_"<0)
			clc
			adc		#77
			sta		_max_xscr
			bne		++			;else
+				sta	_min_xscr	;1159
++			lda		_batchc	;115b
			sta		_batch ;starts at 5

			ldx		_id	;89 " " 2
--			jsr		ai_unit	;1161

			ldx		_id
-			inx					;1166
			cpx		#HITCH	;1
			beq		-		;skip slot #1
			cpx		#ID_MAX +1	;32
			bne		+		;last slot?
			ldx		#ID_MIN		;2
			lda		Anim
			beq		+		;		;
			ldx		#SHIP	;0
+			stx		_id		;1178

			jsr		is_vblank	;useless?!
			dec		_batch
			bne		--
			rts		

ai_alt:		ldx		_id_alt		;1182
			jsr		ai_unit

			inx					;[34,36]
			cpx		#ID_ALT3 +1	;37
			bne		+
			ldx		#ID_ALT1	;34
+			stx		_id_alt		;118e
			rts		

ai_unit:	lda		Unit,x	
			bpl		ai_ret	;no ai?
			asl		
			tay		
			bmi		ai_ret	;ff?
			lsr					;clr hibit
			sta		Unit,x

			lda		Anim,x
			beq		++			;exists?
			bmi		+			;xploding?
			jsr		anim_frame
			jmp		wtimer_map
			;rts 			 unit spawning
+			jmp		anim_frame	;11ab
			;rts

++			lda		AIVECTOR,y	;11ae
			sta		_destptr_l
			lda		AIVECTOR+1,y
			sta		_destptr_h
			jmp		(!_destptr) ;do jump
ai_ret:		rts					;11bb

;2e05
;AIVECTOR:	.word	$11bc, $11da
;			.word	$1361, $13f8
;			.word	$142d, $1436
;			.word	$14b1, $1568
;			.word	$11bf, $11bf, $11bf
;AIVECTOR:	.word	ai_ship
;			.word	ai_kugel,ai_250,ai_500

;11bc
; first vector @jump table 
ai_ship:	jmp		move_enemy
			;rts
; addr:		11bf
; ai_s
ai_kugel:						;#8
ai_250:							;#9
ai_500:							;#10
ai_sprite:	ldy		Param,x		
			iny					;age++
			tya		
			sta		Param,x		; 
			cpy		#160
			bne		+			;too old?
			jmp		erase_id
			;rts

+			jsr		move_enemy	;11ce
			lda		pNext_h,x	;null ptr/
			bne		+		 	;offscrn?
			jmp		erase_id  
+			rts					;11d9

ai_lander:	lda		_humanc		;11da
			bne		+		; no planet?
			jsr		erase_id  ;lander
			lda		#MUTANT	;2
			sta		Unit,x
			jmp		ai_mutant ;make mutant
+			lda		#10			;11e9
			jsr		shootchance	;1:25

			lda		Param,x
			pha		
			and		#%111111
			tay		
			pla		
			bne		+
			jmp		j1v_e		;12d2
+			bmi		j1v_c		;11fb

			lda		Y_h,x
			cmp		#190
			bcc		toj7v_0		;1227

			lda		#HUMAN		;6
			jsr		is_linked
			bne		j1v_b

			tya					;mutant	
			tax		
			jsr		kill_unit
			ldx		_id
			jsr		erase_id
			lda		#MUTANT
			sta		Unit,x
			jmp		ai_mutant

j1v_a:		ldy		#LANDER		;121d 1
			jsr		init_dxy

-			lda		#0			;1222
			sta		Param,x
toj7v_0:	jmp		movewaitmap	;1227

j1v_b:		jsr		erase_id	;122a
			lda		#LANDER
			sta		Unit,x
			jmp		init_unit
			;rts

j1v_c:		lda		Param,x		;1235
			asl		
			bmi		j1v_d		;1266

			lda		#HUMAN
			jsr		is_unlinked
			bne		-

			lda		X_h,x
			cmp		X_h,y
			beq		+
			jmp		j1v_f
+			lda		#$fc		;-4 124d
			sta		dY_h,x
			lda		dX_l,y
			sta		dX_l,x
			lda		dX_h,y
			sta		dX_h,x

			lda		Param,x		;set b6
			ora		#%0100 0000
			sta		Param,x

j1v_d:		lda		Unit,y		;1266
			and		#%0111 1111	;sprite #
			cmp		#HUMAN
			bne		j1v_a
			lda		Param,y
			and		#%1100 0000
			bne		j1v_a		;b6 || b7?

			lda		Param,y
			beq		+
			lda		#0
			sta		dY_l,x
			sta		dY_h,x
			jmp		movewaitmap

+			lda		Y_h,x		;1286
			sec		
			sbc		#10
			cmp		Y_h,y
			bcs		toj7v_1
			sta		Y_h,y

			lda		DXMIN_INIT + LANDER
			lsr					;2e46
			lsr					; / 4
			sec		
			sbc		#1			;dy--
			sta		dY_h,x
			sta		dY_h,y
			lda		#0
			sta		dY_l,x
			sta		dY_l,y
			sta		dX_l,x
			sta		dX_h,x
			sta		dX_l,y
			sta		dX_h,y

			clc		
			lda		X_l,x
			adc		#$80		;+2px
			sta		X_l,y
			lda		X_h,x
			adc		#0
			sta		X_h,y

			tya		
			sta		Param,x
			txa		
			sta		Param,y
toj7v_1:	jmp		movewaitmap	;12cf

j1v_e:		jsr		random		;12d2
			and		#%11111		;[0,31]
;			cmp		#32
;			bcs		j1v_e		;impossbl?
			cmp		#ID_MIN		;2
			bcc		j1v_e	
			tay					;[2,31]

			lda		#HUMAN
			jsr		is_unlinked
			bne		j1v_f
			sec		
			lda		X_h,y
			sbc		X_h,x		;horz disq
			sta		_temp		;Xy - Xx
			lda		dX_h,x
			asl					;dirctn->C
			lda		_temp		;A: +dispX
			bcc		+			;going R?
			lda		#0
			sbc		_temp		;A: -dispX
+			cmp		#50			;12fc
			bcs		j1v_f		;>= 50?

			tya		
			ora		#%10000000
			sta		Param,x

j1v_f:		lda		dX_l,x		;1306
			sta		_temp_l
			asl		_temp_l
			rol		
			asl		_temp_l
			rol		
			asl		_temp_l		; *= 8
			rol		
			sta		_temp_h

			jsr		get_ysurf
			sta		_temp_l
			sec		
			lda		Y_h,x
			sbc		_temp_l
			cmp		#20
			bcc		moveup		
			cmp		#30
			bcs		movedown
			jmp		movewaitmap

moveup:		bit		_temp_h		;132f
			bpl		yadd
			bmi		ysub

movedown:	bit		_temp_h		;1335
			bmi		yadd
			;bpl	..
ysub:		sec					;1339
			lda		Y_l,x
			sbc		_temp_l
			sta		Y_l,x
			lda		Y_h,x
			sbc		_temp_h
			sta		Y_h,x
			jmp		movewaitmap

yadd:		clc					;134d
			lda		Y_l,x
			adc		_temp_l
			sta		Y_l,x
			lda		Y_h,x
			adc		_temp_h
			sta		Y_h,x
			jmp		movewaitmap

ai_mutant:	lda		#25			;1361
			jsr		shootchance	;1:10

			lda		pSprite_h,x
			beq		+			;null ptr?
			jsr		random
			cmp		#20
			bcs		+			;1:13 odds
			lda		#16
			jsr		playsound
+			jsr		get_xdisph	;1377
			cmp		#10
			bpl		j13b3
			cmp		#$ec 		;-20
			bmi		j13ca 		;near shp?

j1382:		jsr		abs_ydisp	;1382
j1385:		ldy		#6    		;1385below
			lda		#0			;(go up)
			bcs		+			;above?
			ldy		#$fa		;-6 
;			lda		#0			;(go down)
+			sta		dY_l,x		;138f
			tya					;set vert
			sta		dY_h,x		;velocity

j1396:		sec					;1396
			lda		X_h + SHIP
			sbc		X_h,x
			php		; save N	
			lda		#80
			plp		
			bpl		+
			ldy		#$fd		;-3
			lda		#$b0		;-80
+			sta		dX_l,x		;13a9
			tya		
			sta		dX_h,x	; -592
			jmp		movewaitmap

j13b3:		cmp		#50			;13b3
			bpl		j13ca
			jsr		abs_ydisp
			cmp		#40
			bcs		j1382
			jsr		abs_ydisp 	;ret C
			php		
			pla					;get flags
			eor		#1			;~carry
			pha					;write
			plp		
			jmp		j1385
;status: 7 NV_BDIZC 0

j13ca:		jsr		random		;13ca
			and		#1
			pha		
			plp  				;random C
			jmp		j1385

get_xdisph:	ldy		X_h + SHIP	;13d4
			lda		_ddx_h
			asl					;facing R:
			lda		X_h,x		;(xid-xme)

			bcc		+			;facing L?
			tya					;-> negate
			ldy		X_h,x		;(xme-xid)

+			sty		_temp		;13e3
			sec					;+ in frnt
			sbc		_temp		;- behind
			rts					;horz disp

abs_ydisp:	sec					;13e9
			lda		Y_h,x
			sbc		Y_h + SHIP

			pha					;vert disp
			asl					;above: !C
			pla					;below: C
			bpl		+			;-ve?
			eor		#$ff		;absolute
+			rts					;13f7 retC

ai_baiter:	lda		#40			;13f8
			jsr		shootchance	;1:6 odds
			lda		Param,x
			beq		+
			dec		Param,x
			jmp		movewaitmap

+			jsr		random		;1408
			and		#%111
			clc		
			adc		#10
			sta		Param,x		;[10,17]

			txa		
			tay		
			jsr		target_ship
			asl		dY_l,x
			rol		dY_h,x
			asl		dX_l,x
			rol		dX_h,x
			asl		dX_l,x
			rol		dX_h,x
			jmp		movewaitmap
				;rts

ai_bomber:	jsr		minechance	;142d
			jsr		dy_sine
			jmp		movewaitmap
			;rts

ai_swarmer:	jsr		dy_sine		;1436
			sec		
			lda		X_h,x
			sbc		X_h + SHIP
			sta		_temp
			eor		dX_h,x
			bmi		++
			lda		_temp
			bpl		+
			eor		#$ff
+			cmp		#20		;144d
			bcs		+
			jmp		movewaitmap
+			jmp		j1396	;1454

++			lda		pSprite_h,x	;1457
			beq		+	;null ptr?
			jsr		random
			cmp		#15
			bcs		+		;1:17
			lda		#19
			jsr		playsound
+			lda		#30		;1468
			jsr		shootchance	;1:8
			jmp		movewaitmap

dy_sine:	lda		#0		;1470
			sta		_temp
			lda		Y_h,x
			sec		
			sbc		#98
			bcs		uppersine ;10 <= Y <= 96?
; screen's lower half, A between -88 -> -2
lowersine:	eor		#$ff	;147c
			clc				;-A
			adc		#1		;2's complement 
; 2 (top) >= A >= 88 (bottom)
			asl		
			rol		_temp	; *= 4
			asl		
			rol		_temp	;HI BYTE!

			clc				;add to velocity	
			adc		dY_l,x
			sta		dY_l,x
			lda		_temp
			adc		dY_h,x
			sta		dY_h,x
			rts		

uppersine:	asl				;1497
			rol		_temp
			asl		
			rol		_temp	;HI BYTE!
			sta		_temp2	;LO BYTE!

			sec		;subtract from velocity	
			lda		dY_l,x
			sbc		_temp2
			sta		dY_l,x
			lda		dY_h,x
			sbc		_temp
			sta		dY_h,x
			rts		

ai_human:	lda		Param,x		;14b1
			bne		+			;special?
			jmp		normalhuman	;153e
			;rts

+			bmi		+			;14b9
			tay					;id #
			lda		#LANDER		;1
			jsr		is_linked
			bne		startfall	;14fc
			jmp		movewaitmap

+			asl					;14c6
			bmi		falling		;1509
			stx		_xreg
			ldx		#HITCH
			jsr		get_ysurf
			ldx		_xreg
			cmp		Y_h + HITCH	;470
			bcs		rescued	;on planet? 
			rts		

rescued:	dec		_hikerc		;14d8
			lda		X_h + HITCH	;426
			sta		X_h,x
			lda		Y_h + HITCH
			sta		Y_h,x
			lda		#0
			sta		dY_h,x
			sta		dY_l,x
			sta		Param,x

			lda		#15
			jsr		playsound
			jsr		score500	;25bc
			jmp		movewaitmap
	
startfall:	lda		#$ff		;14fc
			sta		Param,x
			lda		#0
			sta		dY_l,x
			sta		dY_h,x
falling:	sec					;1509
			lda		dY_l,x
			sbc		#64			;gravity
			sta		dY_l,x		;accel
			lda		dY_h,x
			sbc		#0
			sta		dY_h,x

			jsr		get_ysurf
			cmp		Y_h,x		;man hit
			bcc		movewaitmap	;ground?

			lda		dY_h,x		;fall velc
			cmp		#$fb		;> -5?
			bcs		+
			jmp		kill_unit	;splat
			;rts

; safely fell
landsafe:	lda		#0			;152c
			sta		Param,x
			ldy		#HUMAN		;walking 
			jsr		init_dxy 	;speed

			lda		#15
			jsr		playsound
			jmp		score250 ;flash '250'
			;rts

normalhuman:lda		dX_l,x		;153e
			sta		_temp_l
			lda		dX_h,x
			asl		_temp_l
			rol		
			asl		_temp_l
			rol		
			asl		_temp_l
			rol		
			sta		_temp_h	;signed

			jsr		get_ysurf
			sec		
			sbc		Y_h,x
			cmp		#4
			bmi		++
			cmp		#8
			bpl		+
			bmi		movewaitmap

+			jmp		moveup		;1562
++			jmp		movedown	;1565

movewaitmap:
ai_pod:		ldx		_id			;1568
			jsr		move_enemy
			ldx		_id
			jmp		wtimer_map
			;rts

playsound:	sta		_temp		;1572
			txa
			pha
			tya
			pha
			ldx		_temp ;arg passed in A
			lda		$2c88,x
			sta		_temp
plsndloop:	lda		$2c88,x			;157f
			sta		paramblock +1
			lda		$2c9c,x
			sta		paramblock

			ldy		#2
			lda		$2cb0,x
			jsr		ins_param
			lda		$2cc4,x
			jsr		ins_param
			lda		$2cd8,x
			jsr		ins_param

			txa		; = SOUND(chan,
			pha		
			ldx		#<paramblock ; =2c80
			ldy		#>paramblock
			lda		#7
			jsr		OSWORD	;fff1

			pla
			tax
			inx
			dec		_temp
			bpl		plsndloop

			pla
			tay
			pla
			tax
			rts
;15b6
ins_param:	sta		paramblock,y ; lobyte
			iny		
			asl	
			lda		#0
			bcc		+	; -ve param?
			lda		#$ff
			; insert param hibyte
+			sta		paramblock,y	;15c1
			iny	; word added 2 param block
			rts		

repaint_map:lda		_min_xscr	;15c6
			pha		
			lda		_max_xscr ;not needed?
			pha		
			lda		#0
			sta		_min_xscr
			lda		#80
			sta		_max_xscr

			ldx		#31
rpmaploop:	stx		_xreg		;15d6
			lda		Unit,x
			bpl		rpmapnext ; b7 clear?
			asl		
			bmi		rpmapnext ; b6 set?
			
			ldy		pDot_l,x
			sty		_destptr_l
			ldy		pDot_h,x
			beq		rpmapnext
			sty		_destptr_h

			lda		Dot,x
			tax		
			stx		_yreg
			jsr		dot_map  ; erase old

			ldx		_xreg  ; current slot
			clc		
			lda		_destptr_l
			adc		_scrolloff_l ; scroll
			sta		_destptr_l
			sta		pDot_l,x
			lda		_destptr_h
			adc		_scrolloff_h

			bpl		+	; wrap screen ram
			sec		
			sbc		#$50
+			cmp		#$30		 ;160a
			bcs		+
			adc		#$50

+			sta		_destptr_h	 ;1610
			sta		pDot_h,x

			ldx		_yreg   ; 2x sprite #
			jsr		dot_map ; paint new

rpmapnext:	ldx		_xreg		 ; 161a
			dex  ; loop over slots #0-#31
			bpl		rpmaploop 

			pla		
			sta		_max_xscr ;not needed?
			pla		
			sta		_min_xscr
			rts		


dot_map:	lda		_destptr_h	;1626
			bne		upperdot
			rts		; null ptr	

upperdot:	ldy		#0			;162b
			lda		(_destptr),y
			eor		MAP_DOT,x
			sta		(_destptr),y  ; paint
			lda		_destptr_h ; preserve
			sta		_srcptr_h
			lda		_destptr_l
			sta		_srcptr_l

			and		#%111
			cmp		#7	  ; @ cell bottom?
			bne		lowerdot
dot640:		clc		; to cell below  1645
			lda		_srcptr_l
			adc		#120	; + 640 - 8
			sta		_srcptr_l
			lda		_srcptr_h
			adc		#2
			bpl		+	; wrap vram
			sec		
			sbc		#$50
+			sta		_srcptr_h		;1652

lowerdot:	iny		; 1px down	1654
			lda		(_srcptr),y
			eor		MAP_DOT+1,x
			sta		(_srcptr),y	;paint
			rts		

;165d
wtimer_map:	jsr		timerstate
			bpl		wtimer_map

			cpx		#32
			bcc		+		
			rts		; arg X/id >= 32 

+			lda		_min_xscr	;1667
			pha		
			lda		_max_xscr
			pha		
			txa		
			pha		; id	
			lda		#0
			sta		_min_xscr
			lda		#80
			sta		_max_xscr

			lda		pDot_l,x
			sta		_destptr_l
			lda		pDot_h,x
			sta		_destptr_h
			lda		Dot,x
			tax		
			jsr		dot_map

			pla		
			pha		
			tax		
			lda		Y_h,x
			lsr		
			lsr		; /= 4	
			clc		
			adc		#196
			tay		

			sec		
			lda		X_l,x
			sbc		_xrel_l
			lda		X_h,x
			sbc		_xrel_h
			jsr		px_add110		;2ff0

			lsr		
			lsr		
			php		; store carry = bit 1
			clc		
			adc		#8
			tax		
			jsr		setptr_xy

			plp		
			pla		
			tax		; arg X preserved	
			php		
			lda		_destptr_l
			sta		pDot_l,x
			lda		_destptr_h
			sta		pDot_h,x

			lda		Unit,x
			asl		
			plp		
			bcc		+
			adc		#21
+			sta		Dot,x	;16c3
			tax		
			jsr		dot_map

			pla		
			sta		_max_xscr
			pla		
			sta		_min_xscr
			rts		

;16d1
key_return:	ldx		#$b6 ; RETURN keycode
			jsr		scan_inkey
			beq		+
			eor		_inkey_enter
+			stx		_inkey_enter ;16da
			beq		+		; key down?
; fire laser, if theres an empty slot
			ldx		#3
-			lda		_Laser,x	;16e0 46
			beq		fire_laser	;free beam
			;rts
			dex		
			bpl		-			;[4]
+			rts					;16e7

;16e8
fire_laser:	stx		_xreg		;beam[0,3]
			lda		Y_h + SHIP
			sec		
			sbc		#6			;from nose
			tay		

			ldx		#SHIP
			jsr		get_xscr
			tax		
fireleft:	dex					;L side
			lda		#$81		;shoot L
			bit		_ddx_h
			bmi		+			;facing R?
fireright:		txa
			clc				;R side
			adc		#7			;width+1
			tax
			lda		#$01		;shoot R 
+			pha					;1705
			txa		
			pha		; store coords		
			tya		
			pha		
			jsr		setptr_xy	;_destptr

			ldx		_xreg		;beam slot
			lda		_destptr_l
			sta		_pTail_l,x
			sta		_pHead_l,x
			lda		_destptr_h
			sta		_pTail_h,x
			sta		_pHead_h,x

			pla					;Y coord
			sta		_BeamY,x
			pla					;X "
			sta		_BeamX,x
			pla					;01/81
			sta		_Laser,x ;beam taken
			lda		#0
			sta		_Tail,x
			sta		_Head,x

			lda		#4
			jmp		playsound	;laser snd
			;rts

do_laser:	ldx		#3			;172f beam
beamloop:
lzright:		lda	#8			;1731
			sta		_offset_l
			lda		#0
			sta		_offset_h	;+8
			lda		_dxwin		;+_dxwin
			ldy		_Laser,x
			bpl		lzedge		;left?
lzleft:			lda	#$f8		
			sta		_offset_l
			lda		#$ff
			sta		_offset_h	;-8
			sec		
			lda		#0
			sbc		_dxwin		;-_dxwin
lzedge:		sta		_dxedge		;174c
			sec		
			lda		_BeamX,x	;adjust
			sbc		_dxwin
			sta		_BeamX,x

			lda		_Laser,x
			bne		+
			jmp		lasernext	;free beam

+			lda		_pHead_l,x ;175c
			sta		_destptr_l
			lda		_pHead_h,x
			sta		_destptr_h

			clc		
			lda		#4
			adc		_dxedge
			sta		_laserc		;loop idx
lzloop:		lda		_BeamX,x	;176b

			ldy		_Laser,x
			bmi		llpleft		;left?
llpright:		cmp	_max_xscr
			bpl		erase_laser
			inc		_BeamX,x
			bne		llppaint
llpleft:		cmp	_min_xscr	;1779
			bmi		erase_laser
			dec		_BeamX,x

llppaint:	ldy		_Head,x		;177f
			jsr		blit_laser
			sta		_Head,x		;++
			jsr		next_ptr

llphit:		ldy		#0
			lda		(_destptr),y
			and		#%11000000	
			beq		lznext		;b6/7 set?
			jsr		laser_hit	;hit unit
			bcs		lznext
			rts				;fail
lznext:		dec		_laserc		;1797
			bne		lzloop		;[~4,0]

newhead:	lda		_destptr_l
			sta		_pHead_l,x
			lda		_destptr_h
			sta		_pHead_h,x
			bne		lzscroll	;always

;2bff [80] black, bF, Fb, FF
;LASERPX:
;.byte	$95,  0,  0,$30,  0,$20,$30,$10
;.byte	$30,  0,$30,$30,$20,$30,$30,  0
;.byte	$30,$30,$30,$30,$30,$30,$30,$30
;.byte	$30,$30,$30,$30,$30,$30,$30,$30
;.byte	$30,$30,$30,$30,$30,$30,$30,$30
;.byte	$30,$30,$30,$30,$30,$30,$30,$30
;.byte	$30,$30,$30,$30,$30,$30,$30,$30
;.byte	$30,$30,$30,$30,$30,$30,$30,$30
;.byte	$30,$30,$30,$30,$30,$30,$30,$30
;.byte	$30,$30,$30,$30,$30,$30,$30,$30

erase_laser:lda		_destptr_l	;17a5
			sta		_srcptr_l
			lda		_destptr_h
			sta		_srcptr_h	;= pHead
			lda		_pTail_l,x
			sta		_destptr_l
			lda		_pTail_h,x
			sta		_destptr_h

			lda		#NULL		;0
			sta		_Laser,x	;clr beam

			lda		_Tail,x		;spr idx
			tax		
			ldy		#0
elzloop:	inx					;17be	
			lda		LASERPX,x	;2bff
			eor		(_destptr),y
			sta		(_destptr),y ;erase
			cpx		#80
			bne		elznext		;[1,79]
			ldx		#79

elznext:	jsr		next_ptr	;17cc
			lda		_destptr_l
			cmp		_srcptr_l	;while
			bne		elzloop
			lda		_destptr_h	;(src !=
			cmp		_srcptr_h	; dest)
			bne		elzloop
			rts					;ps equal

lzscroll:	lda		_pTail_l,x ;17dc
			sta		_destptr_l
			lda		_pTail_h,x
			sta		_destptr_h
			
			clc		
			lda		#1
			adc		_dxedge
			sta		_laserc
			beq		lasernext	;no scroll
			bmi		lasernext	;"
tailloop:		ldy		_Tail,x	;17ef
			jsr		blit_laser
			sta		_Tail,x
			jsr		next_ptr
			dec		_laserc	;[1-79,0]
			bne		tailloop
newtail:	lda		_destptr_l
			sta		_pTail_l,x
			lda		_destptr_h
			sta		_pTail_h,x

lasernext:	dex					;1805	
			bmi		+
			jmp		beamloop	;1731[3,0]
+			rts					;180b

laser_hit:	lda		_destptr_l	;180c
			pha		
			lda		_destptr_h
			pha		
			lda		_offset_l
			pha		
			lda		_offset_h
			pha		

			lda		_BeamX,x
			jsr		lz_collide

			pla		
			sta		_offset_h
			pla		
			sta		_offset_l
			pla		
			sta		_destptr_h
			pla		
			sta		_destptr_l

			bcs		lzhit_ret
			txa		
			pha		
			jsr		erase_laser
			pla		
			tax		
			clc		
lzhit_ret:	rts					;1833

blit_laser:	iny					;++Y  1834
			tya		
			pha					;store arg

			lda		LASERPX,y	;pixel
			ldy		#0
			eor		(_destptr),y
			sta		(_destptr),y ;blit

			pla		
			cmp		#80			;max?
			bne		+			;[1,79]
			lda		#79		
+			rts				;ret A  1847

next_ptr:	clc					;1848
			lda		_destptr_l
			adc		_offset_l
			sta		_destptr_l	;dest
			lda		_destptr_h	; +=
			adc		_offset_h	;offset

			bpl		+
			lda		#$30		;wrap vram
+			cmp		#$30		;1857
			bcs		+
			adc		#$50
+			sta		_destptr_h	;185d
			rts		

; arg A: _BeamX,x
lz_collide:	cmp		#80			;1860
			bcc		lzcdinit	;offscrn?
			rts
lzcdinit:	stx		_xreg		;1865 beam
			sta		_anim_xscr ;7a unused?
			lda		_BeamY,x	;yscr
			sta		_beam_yscr	;7c

			ldx		#ID_MIN		;2
lzcdloop:	lda		pSprite_h,x	;186f
			beq		lzcdnext	;0ptr?
			lda		Y_h,x		;unit Y
			sec		
			sbc		_beam_yscr	;Y displc
			cmp		#8
			bcs		lzcdnext	;within?

			lda		pSprite_l,x
			and		#%11111000
			sta		_temp
			sec		
			lda		_destptr_l
			and		#%11111000
			sbc		_temp
			sta		_offset_l

			lda		_destptr_h
			sbc		pSprite_h,x
			bpl		+			;-ve?
			clc
			adc		#80
+			lsr					;1898
			ror		_offset_l
			lsr		
			ror		_offset_l	; /= 8
			lsr		
			ror		_offset_l
			sta		_offset_h

			sec		
-			lda		_offset_l		;18a4
			sbc		#80
			sta		_offset_l
			lda		_offset_h
			sbc		#0
			sta		_offset_h
			bcs		-

			lda		_offset_l
			adc		#80
			cmp		#4
			bcs		lzcdnext

			lda		Anim,x
			bne		lzcdnext	;exists?
			lda		Unit,x
			asl		
			bmi		lzcdnext	;freeslot?
			lsr					;sprite #
			cmp		#HUMAN		;6
			bne		hitfound
hithuman:	lda		Param,x
			cmp		#$80
			beq		lzcdnext	;fake man?
hitfound:	lda		#3			;18d1
			jsr		playsound
			jsr		score_unit
			jsr		kill_unit	;zzzzz
			ldx		_xreg
			clc				;success
			rts

lzcdnext:	inx					;18e0
			cpx		#32			;[2,31]
			bne		lzcdloop	;186f
			ldx		_xreg
			sec				;fail
			rts

kill_unit:	lda		Unit,x		;18e9
			and		#%01111111
			cmp		#8
			bcs		erase_id	 ;rts
			cmp		#3
			beq		kill_u2	 ;rts

			pha		
			jsr		kill_u2		;1910
			pla		
			bcs		killu_ret

			cmp		#6
			beq		+
			dec		_enemyc	; enemy
killu_ret:	rts					;1903

+			lda		#10		;human	1904
			jsr		playsound

			dec		_humanc
			bne		killu_ret
			jmp		rm_surface
			;rts	

kill_u2:	lda		Unit,x		;1910
			pha		
			jsr		erase_id
			pla		
			bcs		killu_ret
			sta		Unit,x

			lda		#$ff
			sta		Anim,x
			lda		#8
			sta		Param,x
			rts		

;1928
erase_id:	txa				  
			pha			   	  	;save id #
			lda		Unit,x
			asl				  	;b6/ff?
			bmi		erasefail	;slotempty

			cpx		#ID_BULLET1 
			bcs		skipdot		;>= #32?
			ldy		pDot_l,x	;on mmap
			sty		_destptr_l
			ldy		pDot_h,x
			sty		_destptr_h
			beq		skipdot		;null ptr?
			lda		#0			;make 0ptr
			sta		pDot_h,x
			lda		Dot,x
			tax					;[0,43]
			jsr		dot_map		;erase dot

skipdot:	pla					;194c
			pha					;X/id #
			tax		
			lda		Anim,x
			bne		nosprite	;drawn?
erasespr:	lda		pSprite_l,x	;1954
			sta		_destptr_l	;vram
			lda		pSprite_h,x
			sta		_destptr_h
			lda		Unit,x
			and		#%01111111
			tax					;sprite #
			jsr		paint_spr	;erase

nosprite:	pla					;1967
			tax		
			jsr		clear_data	;An,P,ptrs
			lda		Unit,x
			and		#%01111111
			cmp		#POD
			bne		erasesucc	;swarmers?
swarmcloud:	lda		X_h,x		;2e2a 1975
			sta		XMIN_INIT + SWARMER
			lda		Y_h,x
			sec		
			sbc		#8			;2e3a
			sta		YMIN_INIT + SWARMER
			jsr		random
			and		#%111		;spawn x#
			clc					;[5,12]
			adc		#5
			sta		SPAWNC + SWARMER
			txa					;save pod#
			pha					;85
			lda		#(SWARMER|$80) 
			jsr		mspawn		;spw cloud
			pla					;pod id
			tax		

erasesucc:	lda		#$ff		;1998
			sta		Unit,x		;clear slot
			clc		
			rts				;successful
erasefail:	pla					;199f
			tax		
			sec		
			rts				;failed

;2e1d
;SPAWNC:	.byte	0,5,0,0,4,0,0,0

mspawn:		sta		_spawn_spr	;27 19a3
			and		#%01111111	;sprite #
			tay		
			lda		SPAWNC,y	;2e1d
			beq		mspw_ret	; none?
			sta		_count		;12
			cpy		#LANDER
			bne		mspwinit
			lda		_humanc		;no planet?
			bne		mspwinit
			ldy		#MUTANT	;->all muts

mspwinit:	jsr		mspw_frame	;19b9

			ldx		#ID_MIN	 	;start here
mspwloop:	lda		Unit,x		;19be
			asl
			bpl		mspwnext	;b6 clear?
			tya					;free slot
			ora		#%10000000	;set hibit
			sta		Unit,x
			jsr		init_unit	;create u

			cpy		#BAITER	;not in
			beq		+			
			cpy		#HUMAN	;_enemyc
			beq		+
			inc		_enemyc		;curr #
+			dec		_count		;19d7
			beq		mspw_ret	;all done

mspwnext:	txa		; find next slot 19db
			clc		
			adc		#5			;#2,#7..
			tax		
			cpx		#ID_MAX + 1	;32	
			bcc		mspwloop
			sec		
			sbc		#29		; -> #3,#8..
			tax		
			cpx		#7 ; #4.. #5.. #6..#31
			bne		mspwloop

			bit		_spawn_spr	;no slots
			bpl		mspwinit	;try again?
mspw_ret:	rts					;19f0

mspw_frame:	lda		_spawn_spr	;19f1
			bmi		+			;hibit set?
			pha		
			lda		_count
			pha		
			tya		
			pha		

			jsr		frame

			pla		
			tay		
			pla		
			sta		_count
			pla		
			sta		_spawn_spr
+			rts					;1a06

;
spw_baiter:	dec		_baitdelay_l ;18 1a07
			bne		+
			dec		_baitdelay_h ;19
			bne		+
; respawn interval has passed
			lda		#1	 		 ;2e20
			sta		SPAWNC + BAITER
			lda		X_h + SHIP
			sta		XMIN_INIT + BAITER
			lda		#($80|BAITER)  
			jsr		mspawn		 ;spawn 1
; respawn every $200/512 frames
			lda		#2
			sta		_baitdelay_h
+			rts					;1a23

;2d6e 
;ANIMATESPW:.byte	0,1,1,1,1,0,0,1,0,0,0

init_unit:	lda		Unit,x		;1a24
			asl
			php		
			lsr					;sprite #
			tay		

			jsr		clear_data	;ret A = 0
			sta		pDot_h,x	;NULL
			plp		
			bpl		+			;free slot?
			rts
; slot taken, Y = sprite #  1a35
+			lda		ANIMATESPW,y  ;2d6e
			beq		+
			lda		#1			;warp in
			sta		Anim,x		;over
			lda		#8			;8 frames
			sta		Param,x

+			jsr		random		;1a44
			and		XRANGE_INIT,y ;2e2d
			clc		
			adc		XMIN_INIT,y ;2e25
			sta		X_h,x

			jsr		random
			and		YRANGE_INIT,y ;2e3d
			clc		
			adc		YMIN_INIT,y ;etc
			cmp		#192
			bcc		+
			sbc		#192
+			sta		Y_h,x		;1a61

init_dxy:	jsr		random		;1a64
			and		DXRANGE_INIT,y ;2e4d
			clc		
			adc		DXMIN_INIT,y
			jsr		to_velocity 
			sta		dX_l,x ;ret A = _temp_l
			lda		_temp_h
			sta		dX_h,x

			jsr		random
			and		DYRANGE_INIT,y ;2e5d
			clc		
			adc		DYMIN_INIT,y
			jsr		to_velocity
			sta		dY_l,x
			lda		_temp_h
			sta		dY_h,x
			rts		

to_velocity:sta		_temp_l		;1a8f
			lda		#0
			sta		_temp_h

			jsr		random
			bpl		+
			sec		
			lda		#0
			sbc		_temp_l		;negate val
			sta		_temp_l
			bcs		+
			dec		_temp_h		;ff

+			lda		_temp_l		;1aa5
			asl
			rol		_temp_h
			asl	
			rol		_temp_h
			asl
			rol		_temp_h
			rts		

mspawn_all:	ldx		#LANDER		;1 1ab1
-			txa					;1ab3
			pha		
			jsr		mspawn

			pla		
			tax		
			inx		
			cpx		#POD + 1	;8
			bne		-
			rts		

;1ac0
smartbomb:	lda		_bombs
			bne		+			
			rts				;no bombs
+			sed					;1ac5
			sec		
			lda		_bombs		;bcd_t
			sbc		#1			;bombs--
			sta		_bombs 
			cld		
			ldx		#0 			;no score,
			ldy		#0			;update #
			jsr		add_score	;of bombs

			lda		#FALSE
			jsr		detonate ;runs into
			lda		#TRUE
			;jmp	detonate
			;rts

;void		detonate(bool pass2);
detonate:		sta	_bomb_pass2	;1adc
			lda		#(PAL_BG | WHITE)
			sta		_bgpal		;07
			ldx		#2
			jsr		do_nframes	;flash W
			jsr		bombscreen	;2 passes
			lda		#(PAL_BG | BLACK)
			sta		_bgpal		;00
			ldx		#2
			jsr		do_nframes	;back to B
			rts

bombscreen:	ldx		#ID_MIN		;1af4
bombloop:	lda		Unit,x		;1af6
			asl					;ff/
			bmi		bombnext	;freeslot?

			lsr					;sprite #
			cmp		#HUMAN		;humans
			beq		bombnext	;spared!
			lda		Anim,x		;drawn?
			bne		bombnext
			lda		pSprite_h,x	;onscreen?
			bne		blowup		;BOOM!
;0ptr -> unit offscreen
;EXCEPT new swarmers @pass2
			lda		_bomb_pass2	;3b
			beq		bombnext	;2nd pass?
			lda		Unit,x
			and		#%0111 1111	;sprite
			cmp		#SWARMER	;#5
			bne		bombnext	;swarmer?
			jsr		get_xscr
			cmp		#80
			bcs		bombnext	;offscrn?
			lda		X_h,x
			eor		#%10000000
			sta		X_h,x
			bne		bombnext

blowup:		jsr		score_unit		;1b29
			jsr		kill_unit

bombnext:	inx						;1b2f
			cpx		#32
			bne		bombloop	; [2,31]
			rts		
;2c78
;HYPERKEYS:	.byte	$ac,$bb,$ca,$ba
;			.byte	$aa,$9b,$ab

; addr:		$1b35:+57 bytes

;void		keys_hyper(void);
keys_hyper:	ldx		#6			;traverse
khyploop:	stx		_xreg		;table
			lda		HYPERKEYS,x	;[7]
			tax					;key code
			jsr		scan_inkey	;keydown?
			bne		hyperspace	;found key

			ldx		_xreg		;table idx
			dex					;try keys
			bpl		khyploop	;[6,0]
khyp_ret:	rts					;-> fail
hyperspace:	bit		Anim		;(& HAL)
			bvs		khyp_ret	;b6?
			lda		Param		;warping,
			cmp		#5			;before
			bcs		khyp_ret	;frame #4?
jump2c:		jsr		random		;->_xrel_h
			jsr		new_screen

			jsr		random
			ldx		#WARP		;      01
			cmp		#40			;~16%
			bcs		hypvars		;chance?
			ldx		#(WARP|HAL)	;die!  41
hypvars:	stx		Anim
			lda		#8
			sta		Param
			rts		

;1b6e
frame_nochk:lda		_no_planet	
			ora		_humanc	
; already destroyed planet
; and/or humam(s) remain
			bne		to_frameall
; planet intact + no humans .. DESTROY!!
			lda		#TRUE
			sta		_no_planet
flbgloop:	iny					;1b78
			tya		
			and		#%111		;[0,7]
			pha		
			tay					;table idx
flashbg:	lda		FLASHPAL,y	;2c70
			and		#(PAL_BG|%1111)	;strip
			sta		_bgpal		;colour
			ldx		#3
			jsr		do_nframes

			lda		#(PAL_BG|BLACK)
			sta		_bgpal		;00
			ldx		#4
			jsr		do_nframes
flbgnext:	pla		
			tay		
			bne		flbgloop	;repeat x8

to_frameall:jmp		frame_all

;1b9a
shootchance:sta		_temp	; chance 76
			lda		_dead
			beq		+
			rts		; must be alive	

+			jsr		random			;1ba1
			cmp		_temp	; shoot? 
			bcs		shtch_ret

			sec		; horiz displacement
			lda		X_h + SHIP
			sbc		X_h,x	; unit firing

			bpl		+		; get absolute
			sta		_temp
			sec		
			lda		#0
			sbc		_temp	; negate A

+			cmp		#40			;1bb8
			bcs		shtch_ret ; too far?

			jsr		shoot		;1c84	
			bcc		+		; shoot succ?
shtch_ret:	rts					;1bc1
; actually shoot
+			lda		#8			;1bc2
			jsr		playsound

target_ship:sec					;1bc7
			lda		X_h + SHIP
			sbc		X_h,x
			jsr		dist_div64 ; ret _t_h
			sta		_srcptr_h
			clc		
			lda		_temp_l
			sta		_srcptr_l ;absolute
			adc		dX_l + SHIP
			sta		dX_l,y ; rel to ship
			lda		_temp_h
			adc		dX_h + SHIP
			sta		dX_h,y

			sec		
			lda		Y_h + SHIP
			sbc		Y_h,x
			jsr		dist_div64
			sta		_destptr_h
			sta		dY_h,y
			lda		_temp_l
			sta		_destptr_l
			sta		dY_l,y

targetloop:	lda		dY_h,y		;1bfc
			cmp		#3
			bcc		+			;< 3?	
			cmp		#$fe		;-2
			bcc		target_ret	;|dy| >=3?
+			lda		dX_h,y		;1c07
			beq		+
			cmp		#$ff
			bne		target_ret	;|dx| >1?
			sec		
			lda		#0
			sbc		dX_l,y		;-dx
			jmp		++
+			lda		_srcptr_l	;1c19
			ora		_srcptr_h
			beq		target_ret
			lda		dX_l,y	3	;+dx
++			cmp		_shootspeed	;1c22 3a
			bcs		target_ret

			clc
			lda		dX_l,y
			adc		_srcptr_l
			sta		dX_l,y
			lda		dX_h,y
			adc		_srcptr_h
			sta		dX_h,y
			clc
			lda		dY_l,y
			adc		_destptr_l
			sta		dY_l,y
			lda		dY_h,y
			adc		_destptr_h
			sta		dY_h,y
			jmp		targetloop
target_ret:	rts					;1c4b

;1c4c no refs??
			lda		#8
			jmp		playsound

minechance:	lda		pNext_h,x	;1c51
			beq		+ 	; onscreen?
			jsr		random
			cmp		#60  ; 1 chance in 4
			bcs		+

			jsr		spawn_misc ; lay mine
			bcs		+	       ; ok?
			lda		#0		; stationery
			sta		dY_l,y
			sta		dY_h,y
			sta		dX_l,y
			sta		dX_h,y
+			rts					;1c70

dist_div64:	sta		_temp_l		;1c71
			php		; save N	
			lda		#0
			plp		
			bpl		+
			lda		#$ff ; sign extend

+			asl		_temp_l		;1c7b
			rol		
			asl		_temp_l
			rol		; *= 4
			sta		_temp_h
			rts		

shoot:		ldy		#32			;1c84
			bne		shootloop ; always
spawn_misc:	ldy		#34			;1c88
shootloop:	jsr		shoot_id	;1c8a
			bcc		+	; found slot?

			iny		; next slot	
			cpy		#ID_ALT3 + 1
			bne		shootloop
+			rts					;1c94

;spawn bullet/mine
shoot_id:	lda		Unit,y		;1c95
			eor		#%1100 0000
			asl		
			asl					;b6 set?
			bcs		shtid_ret	;taken?	
			lda		#($80|KUGEL)
			sta		Unit,y		;spawn 88

			lda		X_l,x
			sta		X_l,y
			clc		
			lda		X_h,x		;4px right
			adc		#1			;of unit
			sta		X_h,y		;->@middle

			lda		Y_l,x
			sta		Y_l,y
			sec		
			lda		Y_h,x	
			sbc		#4			;4px below
			sta		Y_h,y		;u -> @mid

			lda		#0
			sta		Param,y
			sta		Anim,y
			clc					;=success
shtid_ret:	rts					;1cca
			;ret C set =fail

;1ccb
frame:		ldx		#$9f		;TAB
			jsr		scan_inkey
			beq		+
			eor		_inkey_tab
+			stx		_inkey_tab	;1cd4
			beq		+		 	;tab down?
			jsr		smartbomb	;fire@hole

+			jsr		keys_hyper	;1cdb
			jsr		frame_nochk
			lda		_dead
			bne		do_death
			rts		

;1ce6
do_death:	lda		#(PAL_BG|WHITE)
			sta		_bgpal		;07
			jsr		frame_all	;flash wht
			lda		#(PAL_BG|BLACK)
			sta		_bgpal		;00

			ldx		#50			;ship
			jsr		do_nframes	;red/white
			ldx		#FALSE		;prevent
			stx		_dead		;re-entry!
			;ldx	#SHIP
			jsr		erase_id  	;erase shp
			lda		#12
			jsr		playsound

; explode into shrapnel
			ldx		#ID_MAX		;31
-			jsr		clear_sptrs	;1d04
			lda		Unit,x
			sta		Param,x		;backup
			lda		Anim,x
			sta		pDot_l,x	; "

			lda		#(U_SHIP|$80)
			sta		Unit,x ; all slots
			lda		#0
			sta		Anim,x
			sta		pDot_h,x

			lda		X_h + SHIP
			clc		
			adc		#2
			sta		X_h,x
			lda		X_l + SHIP
			sta		X_l,x

			lda		Y_h + SHIP
			sta		Y_h,x
			lda		Y_l + SHIP
			sta		Y_l,x

			ldy		#U_SHIP
			jsr		init_dxy
			dex		
			bpl		-

			lda		#$ba
			sta		SPRITEV_L + U_SHIP
			lda		#$10
			sta		SPRITEV_H + U_SHIP
			lda		#4
			sta		SPRITELEN + U_SHIP

			lda		_batchc
			pha		
			lda		#30			;process
			sta		_batchc		;all slots

			ldx		#60			;frames
-			txa					;1d5b
			pha		

			jsr		ai_batch	;all x30
			jsr		next_frame
			jsr		repaint_all

			pla					;frame ctr
			tax		
			cpx		#18
			bne		+			;#42/60?
			lda		#(PALX_METAL|RED) ;f1
			jsr		set_palette	;red shrap
+			dex					;1d71
			bne		-

			ldx		#ID_MAX	;restore all
-			lda		Param,x		;1d76
			sta		Unit,x
			lda		pDot_l,x
			sta		Anim,x
			dex		
			bpl		-

			pla		
			sta		_batchc		;5(+)
			ldx		#100
			jsr		delay

			sed					;bcd_t
			sec		
			lda		_lives
			sbc		#1			;lose life
			sta		_lives
			cld		

			lda		_is_spawning	
			ora		_enemyc
			beq		+			;lvl done?
			lda		_lives
			bne		++			;continue?

			ldx		_gameover_sp
			txs					;game over
			rts		

+			ldx		_nextlvl_sp	;1da4
			txs		
			rts		

++			jsr		cont_level	;2452 1da8
			ldx		#50
			jsr		delay
			rts		
;1db1
game:		tsx
			stx		_nextlvl_sp		;3f
			lda		#TRUE
			sta		_is_spawning	;40

			lda		#HUMAN
			jsr		mspawn
			lda		#0
			sta		SPAWNC + HUMAN
			ldx		#20
			jsr		do_nframes
			jsr		mspawn_all
			jsr		spawn_squad
			jsr		spawn_squad
			lda		_level
			cmp		#6
			bcc		+			;level 6+?
			jsr		spawn_squad

+			lda		#FALSE		;1dd9
			sta		_is_spawning
-			jsr		frame		;1ddd
			lda		_enemyc
			bne		-
			rts		

;1de5
spawn_squad:lda		#0
			sta		_framec_l	;reset
			sta		_framec_h	;frame ctr
squadwait:	jsr		frame
			lda		_enemyc		;old squad
			beq		newsquad	;all dead?
			lda		_humanc		;or
			beq		newsquad	;no men?

			inc		_framec_l
			bne		+			;count++
			inc		_framec_h
+			lda		_framec_h	;1dfc
			cmp		_squaddelay	;$200 frs?
			bne		squadwait	;delay

newsquad:	lda		#LANDER		;#1
			jsr		mspawn		;spawn 'em
			rts		

;1e08
rm_surface:	txa					;preserve
			pha
			lda		#(PAL_SURF|BLACK)
			sta		_surfpal	;60
			jsr		set_palette	;no surf
			pla		
			tax		
			rts		

;addr:		1e14:+9 bytes
;arg X: 	keycode (-ve) 
;ret A,Z:	-1 if down, 0 not

;int		scan_inkey(int keycode);
scan_inkey:	ldy		#$ff		;scan keyb
			lda		#$81		;INKEY
			jsr		OSBYTE		;key down?
			txa					;-> 00/ff
			rts					;-> Z

;addr:		1e1d:+20 bytes

;void		wait_spaceb(void);
wait_spaceb:lda		#$0f
			ldx		#1			;input buf
			jsr		OSBYTE		;flush it
spcloop:	lda		#$7e
			jsr		OSBYTE		;clear ESC
			jsr		OSRDCH		;getchar()
			cmp		#' '		;space?
			bne		spcloop		;loop til
			rts					;pressed

;addr:		1e31:
;arg XY:	screen X coord, screen Y coord
;ret (succ)	_destptr -> @screen ram
;(fail)					null ptr

;void	   *setptr_xy(	unsigned xscr,
;						unsigned yscr);	
setptr_xy:	lda		#NULL		;ret 0ptr
			sta		_destptr_h	;on fail
			cpx		_min_xscr
			bcc		spxy_ret	;off scrn?
			cpx		_max_xscr
			bcs		spxy_ret

yscrin:		tya					;Yscr
			eor		#$ff		;~
			pha					;b0-2 cell
			lsr		
			lsr		
			lsr		
			tay		

			lsr					;b3
			sta		_temp
			lda		#0
			ror
			adc		_originp_l	;C clear
			php		; save C	
			sta		_destptr_l

setcell:	tya					;~Yscr >>3
			asl		
			adc		_temp		;b4-7
			plp		; C
			adc		_originp_h
			sta		_destptr_h
			
			lda		#0
			sta		_temp
xscrin:		txa					;Xscr
			asl		
			rol		_temp
			asl		
			rol		_temp
			asl		
			rol		_temp		;*= 8
			adc		_destptr_l
			sta		_destptr_l	;cell

			lda		_temp
			adc		_destptr_h
			bpl		setrow
			sec		
			sbc		#$50		;wrap vram
setrow:		sta		_destptr_h

			pla					;~Yscr	
			and		#%111		;cell row
			ora		_destptr_l	;combine
			sta		_destptr_l
spxy_ret:	rts					;_destptr

xorpaint:	lda		_destptr_h		;1e7e
			bne		+		; null ptr?
			rts				; no dest

+			lda		#0				;1e83
			sta		_paintmask ;collision

			lda		_imglen
			pha		
			ldy		#0
xorpinit:	lda		_destptr_h		;1e8c
			pha		
			lda		_destptr_l
			pha		

			lda		_destptr_l
			and		#%00000111 ;cell row
			sta		_dest_row
			lda		_destptr_l
			and		#%11111000 ;whole cell
			sta		_destptr_l
xorploop:	lda		(_srcptr),y		;1e9e
			php		
			iny		
			sty		_temp  ; src cell row
			
			ldy		_dest_row
			eor		(_destptr),y  ; paint
			sta		(_destptr),y
			iny		; detect collision
			plp		;(colours w/hibit set)
			beq		+ ; src pixel nonzero?
			ora		_paintmask
			sta		_paintmask	

+			cpy		#8			;1eb2
			beq		cellbelow
xorpnext:	sty		_dest_row	;1eb6
			ldy		_temp
			tya		
			and		_heightmask
			beq		cellright
			dec		_imglen
			bne		xorploop

			pla		
			pla		
			pla		
			sta		_imglen
			rts		

cellbelow:	ldy		#0			;1ec9
			clc		
			lda		_destptr_l
			adc		#$80
			sta		_destptr_l	; +640
			lda		_destptr_h
			adc		#2
			bpl		+		
			sec		
			sbc		#$50		;wrap vram
+			sta		_destptr_h	;1edb
			bne		xorpnext	;always

cellright:	clc					;1edf
			pla		
			adc		#8  ; -> next cell
			sta		_destptr_l
			pla		
			adc		#0 ;(right of current)
			bpl		+
			sec		
			sbc		#$50  		;wrap vram
+			sta		_destptr_h	;1eed

			dec		_imglen
			bne		xorpinit
			pla		
			sta		_imglen
			rts		


screenstart:lda		_originp_l	;1ef7
			sta		_temp

			lda		_originp_h
			lsr		
			ror		_temp
			lsr	
			ror		_temp
			lsr		
			ror		_temp

			ldx		#12
			jsr		out6845		;screen
			ldx		#13			;start adr
			lda		_temp		;>> 3
			jmp		out6845
			;rts

;1f12
;void		next_frame(void);
next_frame:	jsr		screenstart
			jsr		wait_vblank	;middle of
			ldy		#$14  		;count hi
			ldx		#$80  ; 	;      lo
			jsr		start_timer ;5248 cyc
palette1:	lda		_bgpal
			jsr		set_palette
			lda		_humanc
			bne		palette2 	;no men?
			lda		_bgpal
			ora		#PAL_SURF	;$60
			jsr		set_palette
palette2:	dec		_flpalc		;every
			bne		palette3	;6th frame
flashpal:	lda		_flpalframes
			sta		_flpalc		;=6
			inc		_flashc		
			lda		_flashc		;loop over
			and		#%111		;[0,7] 
			sta		_flashc
			tax		
			lda		FLASHPAL,x	;2c70
			jsr		set_palette ;PAL_FLASH
palette3:	inc		_rotpalc	;every
			lda		_rotpalc	;4th frame
			and		#%11 		;(% 4)
			bne		nxtfr_ret
rotatepal:	ldx		rotatec		;[3] index
			lda		#PAL_ROT1	;$10
rotloop:	sta		_temp		
			stx		rotatec		;2e01
			lda		ROT_CLRS,x	;2e02
			ora		_temp		;PAL_ROTx
			jsr		set_palette
rotnext:	inx					;colour
			cpx		#3			;[0,2]
			bne		+
			ldx		#0
+			lda		_temp
			clc					;PAL_	
			adc		#$10
			cmp		#$40 		;rotate x3
			bne		rotloop
nxtfr_ret:	rts

;2e02
;ROT_CLRS:	.byte	RED,YELLOW,BLUE
;				$01,$03,$04
;2c70
;FLASHPAL:	.byte	$45,$42,$46,$43
;			.byte	$47,$43,$46,$42

psurf_right:pha					;1f71
			sta		_dxwinc
			sty		_xscrc

			ldy		_xwinedge,x
-			jsr		paint_surf	;1f78
			inc		_xscrc
			iny
			dec		_dxwinc
			bne		-

			tya
			sta		_xwinedge,x
			pla
			rts

psurf_left:	pha		; (-ve) _dxwin  1f87
			sta		_dxwinc	
			sty		_xscrc ; starting pt

			; _xwinleft / _xwinright
			ldy		_xwinedge,x ; [2]
-			dec		_xscrc		; arg 1f8e
			dey					; arg	
			jsr		paint_surf	;1f9d
			inc		_dxwinc
			bne		-	; loop till 0

			tya		
			sta		_xwinedge,x
			pla		; A preserved	
			rts		

;1f9d
paint_surf:	stx		_xreg		;LEFT/RIGH
			sty		_yreg		;_xwin[x]
			tya		
			and		#%11		; % 4
			tax					;[0,3]

			tya		
			lsr
			lsr					; / 4
			tay	

			lda		SURFQUAD,y  ; 2bc0[64]
-			dex		;[0-3,0]
			bmi		+
			lsr
			lsr
			bne		-			;unpack	

+			and		#%11		;1fb3
			asl
			asl
			adc		#<SURFTILES	;1020
			sta		_srcptr_l
			lda		#>SURFTILES	;[3][4]
			sta		_srcptr_h


			ldx		_xscrc  ; arg passed
			ldy		_yreg ;arg Y _xwin[lr]
			lda		YSURFACE,y		;e00
			tay		
			jsr		setptr_xy ;get vramptr

			lda		#4
			sta		_imglen
			lda		#7
			sta		_heightmask
			jsr		xorpaint ;paint/erase

			ldx		_xscrc
			ldy		#196
			jsr		setptr_xy

			ldy		#0		; paint/erase
			lda		#$f0	; blue line
			eor		(_destptr),y
			sta		(_destptr),y
			iny		
			lda		#$f0	; blue,blue
			eor		(_destptr),y
			sta		(_destptr),y ; px 2

			ldx		_xreg
			ldy		_yreg
			rts		

;1ff0
flash_ship:	lda		Anim + SHIP
			beq		+			;drawn?
			jmp		scroll_scrn	;22cf
			;rts
+			lda		_dead		;1ff8
; scan keys, ship motion etc
			beq		to_p_esc	;2016

			lda		_shippal	;dead
			eor		#$80 		;flash shp
			sta		_shippal	;2000
			bmi		+
; every 2nd call 
			eor		#%110		;red/wht
			sta		_shippal	;$71/$77
			jsr		set_palette

+			lda		#0			;200b
			sta		dX_l + SHIP	;stop ship
			sta		dX_h + SHIP	
			jmp		j2124
			; scroll_scrn
			; move_ship(SHIP)
			; wtimer_map(SHIP)

;2016
to_p_esc:	jmp		key_p_esc		;2f90
			;rts
;2019	A/up
keys_nav:	ldx		#$be		;'A' key
			jsr		scan_inkey
			beq		+

			clc					;A pressed
			lda		Y_h + SHIP
			adc		#2
			cmp		#195		;ship@top?
			bcs		+
			sta		Y_h + SHIP	;move up
;202d	Z/down
+			ldx		#$9e		;'Z' key
			jsr		scan_inkey
			beq		+			;pressed?
			sec					;Y coords
			lda		Y_h + SHIP	;origin @
			sbc		#2			;scrn btm
			cmp		#9			;< height
			bcc		key_space	;@bottom?
			sta		Y_h + SHIP	;move down

;2041	SPACE/reverse
key_space:	ldx		#$9d		;SPACE bar
			jsr		scan_inkey
			beq		+
			; ~_kst_space -> Z
			eor		_inkey_space ;~(0/-1)
+			stx		_inkey_space ;204a
			beq		+
; space key down
			lda		pSprite_l + SHIP
			sta		_destptr_l
			lda		pSprite_h + SHIP
			sta		_destptr_h
; erase ship
			ldx		#U_SHIP
			jsr		paint_spr
; toggle sprite vector
			lda		SPRITEV_L + U_SHIP ;bw
			eor		#%0011 0000 ;0f{cf}0
			sta		SPRITEV_L + U_SHIP
			lda		#NULL		;0
			sta		pSprite_h + SHIP
; negate accel. vector
			sec		
			lda		#0
			sbc		_ddx_l
			sta		_ddx_l
			lda		#0
			sbc		_ddx_h
			sta		_ddx_h

;2077	SHIFT/accelerate
+			ldx		#$ff  		;SHIFT key
			jsr		scan_inkey
			beq		decelerate
; SHIFT pressed
accelerate:	clc		; velocity += accel.
			lda		dX_l + SHIP
			adc		_ddx_l	  
			sta		dX_l + SHIP

			lda		dX_h + SHIP
			adc		_ddx_h	  
			sta		dX_h + SHIP

; compute ship velocity etc.
decelerate:	lda		dX_h + SHIP	;208f
			ora		dX_l + SHIP
			beq		decel_done	; vel. 0?
; ship in motion
			lda		dX_h + SHIP
			bpl		+  ; +ve velocity?
; decelerate until stationery (going left)
			clc		
			lda		dX_l + SHIP
			adc		#3
			sta		dX_l + SHIP

			lda		dX_h + SHIP
			adc		#0
			sta		dX_h + SHIP
; velocity may not cross zero
			bcs		df_stopped ;stationery

			lda		dX_h + SHIP
			cmp		#$ff
			bpl		decel_done
; velocity < -256?
			lda		#$ff
			sta		dX_h + SHIP
			lda		#0		; max velocity
			sta		dX_l + SHIP
			beq		decel_done	; always

; decelerate (going right)
+			sec					;20c2
			lda		dX_l + SHIP
			sbc		#3
			sta		dX_l + SHIP

			lda		dX_h + SHIP
			sbc		#0
			sta		dX_h + SHIP
			bcc		df_stopped ;crossed 0?

			lda		dX_h + SHIP
			cmp		#1
			bmi		decel_done	; > $100?
			; max velocity
			lda		#0
			sta		dX_l + SHIP
			beq		decel_done	;always

df_stopped:	lda		#0			;20e3
			sta		dX_l + SHIP
			sta		dX_h + SHIP

decel_done:	ldx		#0			;20eb
			jsr		get_xscr
			tax		
			ldy		#15	;facing right
			lda		_ddx_h
			bpl		+			
			ldy		#59	;" left
+			sty		_temp	;20f9

			lda		#0
			ldy		#0	;xpos ok
			cpx		_temp	;rel move 
			beq		+
			lda		#$80 ;->wind right
			;ldy	#0
			bcs		+	
			lda		#$80 ;-> " left
			ldy		#$ff
;210 calc relative velocity
+			clc		; onscreen movement	
			adc		dX_l + SHIP
			sta		_dxrel_l		;1e
			tya		; + scrolling
			adc		dX_h + SHIP
			sta		_dxrel_h		;1f

			clc		;move edge of screen
			lda		_dxrel_l
			adc		_xrel_l
			sta		_xrel_l
			lda		_dxrel_h
			adc		_xrel_h
			sta		_xrel_h

j2124:		jsr		scroll_scrn	;2124
			ldx		#SHIP
			jsr		move_ship	;dX only
			ldx		#SHIP
			jsr		wtimer_map
			rts		

; spawn/erase hitchhiker
spawn_hiker:lda		_hikerc	 ;2132
			beq		erase_hh

			lda		#HUMAN
			sta		Unit + HITCH
			lda		X_l + SHIP
			clc				; superfluous
			adc		#0		; "
			sta		X_l + HITCH
			lda		#1
			adc		X_h + SHIP
			sta		X_h + HITCH

			lda		Y_h + SHIP
			sec		
			sbc		#10
			sta		Y_h + HITCH

			ldx		#HITCH	; @start?
			jsr		next_vidp	;21b0
			jmp		wtimer_map	;165d
			;rts
erase_hh:	ldx		#HITCH	;215d
			jmp		erase_id
			;rts

;2162
move_enemy:	lda		Unit,x
			and		#%0111 0111	;sprite #
			tay					; % 8	

			clc		
			lda		dY_l,x
			adc		Y_l,x
			sta		Y_l,x

			lda		dY_h,x
			adc		Y_h,x
			cmp		#$c3
			bcc		+
			cpy		#(U_SHIP & KUGEL) ;0/8
			beq		moveskip	;21d1

			lda		#9
+			cmp		#9			;2182
			bcs		++
			cpy		#U_SHIP
			bne		+

			cmp		#4
			bcs		++
			bcc		moveskip

+			cpy		#6			;2190
			php		
			lda		#194
			plp		
			bne		++

			lda		#9
++			sta		Y_h,x		;219a

			clc		
move_ship:	lda		dX_l,x		;219d
			adc		X_l,x
			sta		X_l,x

			lda		dX_h,x
			adc		X_h,x
			sta		X_h,x
next_vidp:	ldy		Y_h,x		;21b0
			txa		
			pha		
			jsr		get_xscr
			tax		
			jsr		setptr_xy
			pla		
			tax		

movedone:	lda		_destptr_l	;21be
			sta		pNext_l,x
			lda		_destptr_h
			sta		pNext_h,x
			lda		Unit,x
			and		#%01111111	;BLIT
			sta		Unit,x
			rts		

moveskip:	lda		#NULL		;21d1
			sta		_destptr_h	;null ptr
			beq		movedone
			; always
;21d7
get_xscr:	sec	
			lda		X_l,x	; *
			sbc		_xrel_l
			sta		_offset_l
			lda		X_h,x	; *
			sbc		_xrel_h
			sta		_offset_h

			asl		_offset_l
			rol		
			sta		_temp

			eor		_offset_h
			bmi		+
			lda		_temp
			rts					;ret A
+			lda		#$80		;21f2
			rts		

repaint_all:ldx		#SHIP		;21f5 0
rpaloop:	txa					;21f7
			pha					;save id #
			lda		Unit,x
			bmi		rpanext		;repaint?
			ora		#UPDATE		;$80
			sta		Unit,x

			lda		Anim,x
			bne		rpanext 	;drawn?
			lda		pSprite_l,x
			cmp		pNext_l,x
			bne		rpaerase
			lda		pSprite_h,x
			cmp		pNext_h,x
			bne		rpaerase
			cpx		#SHIP 		;u. still?
			bne		rpanext	 	;norepaint
rpaerase:	lda		pSprite_l,x	;221c
			sta		_destptr_l
			lda		pSprite_h,x
			sta		_destptr_h
			lda		Unit,x
			and		#%01111111
			tax					;sprite #
			jsr		paint_spr	;erase old

			pla					;id #
			tax		
			lda		pNext_l,x
			sta		pSprite_l,x
			sta		_destptr_l
			lda		pNext_h,x
			sta		pSprite_h,x
			sta		_destptr_h	;update
			txa		
			pha		
			jsr		xorpaint
rpanext:	pla					;2246
			tax					;id #
			inx		
			cpx		#ID_ALT3 + 1
			bne		rpaloop		;21f7
			rts		

;2d4d
;SPR_HEIGHT:.byte	07,07,07,03
;					07,03,$0f,07
;					03,07,07

paint_spr:	lda		SPR_HEIGHT,x ;224e
			sta		_heightmask
			lda		SPRITELEN,x
			sta		_imglen
			lda		SPRITEV_L,x
			sta		_srcptr_l
			lda		SPRITEV_H,x
			sta		_srcptr_h

			jsr		xorpaint 	;same X
			cpx		#U_SHIP
			bne		+  			;erased?
			lda		_paintmask
			sta		_collision
+			rts					;226d

scroll_surf:lda		#0			;226e
			sta		_min_xscr
			lda		#80
			sta		_max_xscr
			lda		_originp_l
			pha		
			lda		_originp_h
			pha		
			lda		_oldorgp_l
			sta		_originp_l
			lda		_oldorgp_h
			sta		_originp_h

			lda		_dxwin
			beq		ssurfstill	;stopped?
			bpl		ssurfright	;+ve?
ssurfleft:	ldx		#1			;228a
			ldy		#80			;-ve A
			jsr		psurf_left
			sta		_temp		;xwinright
			pla					;restore
			sta		_originp_h	;curr ptr
			pla		
			sta		_originp_l

			sec			
			lda		#0
			sbc		_temp		;-_dxwin
			tay					;(+ve)	
			ldx		#0
			lda		_temp
			jsr		psurf_left
			jmp		ssurf_ret


ssurfright:	ldx		#0			;22a9
			ldy		#0			;A: +dxwin
			jsr		psurf_right
			sta		_temp
			pla		
			sta		_originp_h
			pla		
			sta		_originp_l

			sec		
			lda		#80
			sbc		_temp		;80-dxwin
			tay		
			ldx		#1
			lda		_temp
			jsr		psurf_right
			jmp		ssurf_ret

ssurfstill:	pla					;22c8
			sta		_originp_h
			pla		
			sta		_originp_l
ssurf_ret:	rts					;22ce

;22cf
scroll_scrn:lda		_originp_l
			sta		_oldorgp_l
			lda		_originp_h
			sta		_oldorgp_h

			lda		_xrel_l
			asl					;-> cells
			lda		_xrel_h
			rol		
			pha					;-> xwin
			sec		
			sbc		_xwin
			sta		_dxwin		;(x 2px)
			asl		
			asl					; *= 8	
			asl					;screen
			ldy		#0			;bytes
			bcc		+
			ldy		#$ff		;(signed)

+			sta		_scrolloff_l ;22ec
			clc		
			adc		_originp_l
			sta		_originp_l
			tya					;00/ff
			sta		_scrolloff_h
			adc		_originp_h
			bpl		+
			sec		
			sbc		#$50		;wrap vram
+			cmp		#$30		;22fd
			bcs		+
			adc		#$50
+			sta		_originp_h	;2303
			pla		
			sta		_xwin
			jmp		screenstart
			;rts

collision:	lda		_collision				;230b
			and		#%11000000	; enemy + ship overlap?
			beq		no_collide	
			lda		_dead
			beq		collide		; alive?
no_collide:	rts					;2315

; ship has collided, find unit
collide:	ldx		#SHIP		;2316
			jsr		get_xscr
			sta		_ship_xscr

			ldx		#ID_ALT3	;[36,2]
colldloop:	lda		Unit,x		;231f
			asl		
			bmi		colldnext	;b6/empty?
			cmp		#%10010		;(9 <<1)
			bcs		colldnext	;S250/500?
			lda		Anim,x
			bne		colldnext	;exists?

cllydisp:	lda		Y_h,x
			sec		
			sbc		Y_h + SHIP	;Ydispl
			cmp		#8
			bpl		colldnext	; > 7?
			cmp		#$f9	
			bmi		colldnext	; < -7?
; -7 >= ydisp >= 7
;(ship/enemy height 8px) 
cllxdisp:	jsr		get_xscr
			cmp		#80
			bcs		colldnext	;offscrn?
			sec		
			sbc		_ship_xscr	; Xdispl
			cmp		#6
			bpl		colldnext	; > 5?
			cmp		#$fd
			bmi		colldnext	; < -3 ?
;-3 <= Xdisp <= 5
;(ship width 6px, enemy 4px)
			lda		Unit,x
			and		#%01111111	;sprite #
			cmp		#HUMAN
			beq		cllman		;man?
cllsmash:	jsr		score_unit	;collision
			jsr		kill_unit	;w/enemy
			lda		#TRUE
			sta		_dead		;die
			lda		#(PAL_SHIP|WHITE)
			sta		_shippal
cllman:		lda		Param,x
			bpl		colldnext
			cmp		#$80
			beq		colldnext

cllhitch:	jsr		erase_id	;man
			lda		#$80		; ->
			sta		Param,x		;hiker
			lda		#(UPDATE|HUMAN)	;86
			sta		Unit,x
			inc		_hikerc 	;rescued!
			lda		#14
			jsr		playsound
			jsr		score500
colldnext:	dex
			cpx		#ID_MIN		;2
			bcs		colldloop	;[36,2]
			rts		

;238c
random:		txa					;save X
			pha		
			ldx		#8			;count
rndgen:		lda		_rand_h		
			and		#%0100 1000	;pseudornd
			adc		#%0011 1000
			asl					;b6 << gen
			asl					;(3 byte)
			rol		_rand_l
			rol		_rand_m
			rol		_rand_h
			dex					
			bne		rndgen		;repeat x8

			pla					;restore X
			tax		
			lda		_rand_h		;rnd[0,ff]
			rts					; -> ret

;23a6
next_level:	sed					;bcd_t
			lda		_level
			clc		
			adc		#1			;level++
			sta		_level
			cmp		#5			;lvl #1-4?
			bcc		+			;bonus x00
			lda		#5			;max 500
+			sta		_humanbonus	;23b4

			lda		_level		;bcd_t
			sec					;normal
			ldx		#(PAL_SURF|RED)	;surfc
-			sbc		#5			;23bb
			bcs		- 			;(level
			cmp		#$95		;mod 5)==0
			bne		+			;multiple?
; every 5th level, bonus
			lda		#10
			sta		_humanc		;renew men
			lda		#FALSE
			sta		_no_planet	;new,green
			ldx		#(PAL_SURF|GREEN);surf
; process 6(,7,8..) units at a time
			inc		_batchc		;orig =5

+			cld					;23cf
			lda		_humanc
			bne		+			;no men?
			ldx		#(PAL_SURF|BLACK) ;no
+			stx		_surfpal	;23d6 surf

			clc		
			lda		_shootspeed
			adc		#8
			sta		_shootspeed	; +8
			lda		#10	
			sta		_baitdelay_h
			lda		#0
			sta		SPAWNC + BAITER
			lda		_humanc		;survivors
			sta		SPAWNC + HUMAN

			ldx		#ID_LAST
			lda		#$ff
-			sta		Unit,x		;23f1
			dex		
			bpl		-

			lda		#0
			sta		_hikerc
			lda		#ID_ALT1	;34
			sta		_id_alt
			lda		#0
			sta		rotatec		;2e01
			sta		_flashc		;34
			lda		#6
			sta		_flpalframes ;36
			sta		_flpalc		;35
			lda		#0
			sta		_enemyc		;13
			lda		#2
			sta		_squaddelay	;14
			lda		#0			;2e22
			sta		SPAWNC + SWARMER

			ldx		#0			;level #1:
			lda		_level		;no bombrs
			cmp		#1
			beq		+
			ldx		#4			;#2,#3: x4
			cmp		#4
			bcc		+			;#4 on: x7
			ldx		#7
+			stx		SPAWNC + BOMBER	

			ldx		#4			;pods x4:
			cmp		#4			;lvl #4 on
			bcs		+
			dex					;#3: x3
			cmp		#3
			beq		+
			dex		
			dex					;#2: x1
			cmp		#2
			beq		+
			dex					;#1: none
+			stx		SPAWNC + POD

			lda		DXMIN_INIT + LANDER
			clc
			adc		#2			;max xvelc
			cmp		#24 		;(22 << 3)
			bcs		+
			sta		DXMIN_INIT + LANDER

+			lda		#(PAL_BG|BLACK)
			sta		_bgpal		;00

;called after life lost
cont_level:	lda		#$80		;2452
			sta		XMIN_INIT + SWARMER

			ldx		#ID_LAST+1	;#32
contloop:	lda		Unit,x		;2459
			and		#%01111111	;sprite #
			cmp		#BAITER	
			bne		+			;baiter?
			lda		#EMPTY		;free slot
			sta		Unit,x		;elseaaàq
+			jsr		reset_unit
			jsr		init_unit
			dex		
			bpl		contloop	;[32,0]

			lda		#ID_MIN		;#2
			sta		_id
			lda		#0			;no hiker
			sta		_hikerc

			lda		#KEYDOWN	;no late
			sta		_inkey_space ;key
			sta		_inkey_enter ;presses
			sta		_inkey_tab

; either $ff or passed in A
new_screen:	sta		_xrel_h		;2480
			asl
			sta		_xwin		;xrel <<1
			lda		#0
			sta		_xrel_l
			lda		#$80
			sta		X_l + SHIP
			clc
			lda		_xrel_h
			adc		#7
			sta		X_h + SHIP	;Xscr = 15

			lda		#0		 	;initial Y
			sta		Y_l + SHIP	;@centre
			lda		#100
			sta		Y_h + SHIP
			lda		#7			;+ve ->
			sta		_ddx_l		;facing R
			lda		#0
			sta		_ddx_h

			lda		#0			;clr beams
			ldx		#3
-			sta		_Laser,x	;24ac
			dex
			bpl		-			;[3,0]
; clear hitchhiker slot
			lda		#$ff
			sta		Unit + HITCH
; clear alternate slots #32 -> #36
			ldx		#ID_ALT3	;#36
-			lda		#$ff		;24b8
			sta		Unit,x
			jsr		clear_data
			dex
			cpx		#ID_BULLET1	;[36,32]
			bpl		-
; clear unit slots #0 -> #31
-			jsr		reset_unit	;24c5
			dex
			bpl		-			;[31,0]

			lda		#$80
			sta		Param + HITCH

			lda		#0
			sta		Unit + SHIP
			sta		dX_l + SHIP
			sta		dX_h + SHIP
			sta		Anim + SHIP
			;lda	#FALSE
			sta		_dead
			sta		_collision

; ship facing right, by default
			lda		#<SPR_SHIPR	;fc0
			sta		SPRITEV_L + U_SHIP	
			lda		#>SPR_SHIPR
			sta		SPRITEV_H + U_SHIP	
			lda		#(8*6)		;48
			sta		SPRITELEN + U_SHIP

			lda		#0
			sta		_dxwin
			sta		_scrolloff_l
			sta		_scrolloff_h
;			lda		#0		; superfluous
			sta		_originp_l
			sta		_oldorgp_l

			lda		#$30
			sta		_originp_h
			sta		_oldorgp_h
			sta		_digitp_h
			lda		#$d0
			sta		_digitp_l

			jsr		wait_vblank ;ready
			lda		#(PAL_BG|BLACK) ;00
-			jsr		set_palette	;2510
			clc
			adc		#$10		;palette
			bne		-			;all BLACK

			lda		#0				;msg #
			jsr		print_n

			lda		#(PALX_ENEMYB|BLACK)
-			jsr		set_palette	;80 251f
			clc
			adc		#$11		;[91,a2
			bcc		-			; ,e6,f7]

			lda		#(PAL_FLASH|WHITE)
			jsr		set_palette	;47
			lda		_surfpal	;6[012]
			jsr		set_palette

			lda		#0
			sta		_min_xscr
			lda		#80
			sta		_max_xscr
			lda		_xwin		;from xrel
			sta		_xwinleft  	;_xwinedge
			sta		_xwinright	;[2]
			ldx		#RIGHT		;1
			lda		#80			;draw
			ldy		#0			;surface
			jsr		psurf_right	;of planet

			ldx		#0		;paint digits
			ldy		#0
			jmp		add_score 
			;rts

reset_unit:	lda		Anim,x		;254f
			beq		++			;drawn?
			bpl		+			;spawning?
			lda		#$ff		;exploded
			sta		Unit,x		;->free
			bne		++	  		;always

+			lda		#8			;255d
			sta		Param,x		;re warp
++			jsr		clear_sptrs	;2562
			;lda	#NULL
			sta		pDot_h,x
			rts

clear_data:	lda		#0			;2569
			sta		Anim,x
			sta		Param,x
clear_sptrs:lda		#NULL		;2571
			sta		pNext_h,x
			sta		pSprite_h,x
			rts

print_n:	stx		_savedx  ;41 257a
			sty		_savedy  ;42
; look up ptr to string
			tax					;string #
			lda		PSTRS_L,x	;char *[7]
			sta		_destptr_l
			lda		PSTRS_H,x
			sta		_destptr_h
			ldy		#0		 	 ;1st char
			lda		(_destptr),y ;->length
			sta		_strlen

-			iny					;258f
			lda		(_destptr),y
			jsr		OSWRCH		;print it
			cpy		_strlen
			bne		-

			ldx		_savedx		;restore
			ldy		_savedy
			rts

score_unit:	txa		;X = enemy id 259e
			pha		
			tya		;Y preserved	
			pha		
			lda		Unit,x
			cmp		#EMPTY		;-1
			beq		+			;empty?

			and		#%0111 1111	;slot full
			tax					;->type
			lda		U_SCORES100,x ;2d63
			tay		
			lda		U_SCORES1,x	;2d58
			tax		
			jsr		add_score
+			pla					;25b7
			tay		
			pla		
			tax		
			rts		

score500:	tya					;25bc
			pha		
			txa		
			pha		
			ldy		#5
			ldx		#0
			jsr		add_score
			pla		
			tax		
			jsr		spawn_misc	;1c88
			bcs		sc500_ret	;found?
; spawn flashing '500'
			lda		#($80|S500)
			sta		Unit,y		;8a
; spawn_misc() above has preset coords
; as for a bullet, ie @ unit(=ship) centre
spawn_score:clc					;25d3
			lda		Y_h,y
			adc		#12
			sta		Y_h,y		;above shp

			lda		dX_h + SHIP
			asl					;arith >>
			lda		dX_h + SHIP
			ror					;(Vship/2)
			sta		dX_h,y 		;-> Vhorz
			lda		dX_l + SHIP
			ror					;contn >>
			sta		dX_l,y
			lda		#0			;no vert
			sta		dY_h,y		;movement
			sta		dY_l,y

			sec		
			lda		X_h,y
			sbc		#1			;centre 
			sta		X_h,y		;of ship
sc500_ret:	pla					;25ff
			tay					;restore Y
			rts		

score250:	tya		;cf score500() 2602
			pha		
			txa		
			pha		
			ldy		#2
			ldx		#$50
			jsr		add_score

			pla		
			tax		
			jsr		spawn_misc	;1c88
			bcs		sc500_ret	;25ff
; spawn flashing '250'
			lda		#(S250|$80)
			sta		Unit,y		;89
			bne		spawn_score	;25d3
			; as for score500() above

add_score:	sed		; BCD vars	 261b
			clc
			txa		; passed X,Y
			adc		_score_lsb
			sta		_score_lsb ; += X
			tya
			adc		_score_100	; +carry
			sta		_score_100	; += Y x00
			; carry .. ##
			php
			lda		#0
			adc		_score_msb	; += carry
			sta		_score_msb
			plp		; C preserved
			cld
; every 10,000 points
			bcc		+		;score MSB?
			jsr		reward	;+1 life,bomb

; repaint score
+			lda		_digitp_l	;2e 2635
			sta		_destptr_l
			lda		_digitp_h	;2f
			sta		_destptr_h
			lda		#FALSE
			sta		_leading0
; blank til first significant digit
			ldx		#2
-			lda		_score_lsb,x ;2643
			jsr		paint_bcd
			dex
			bpl		-
			jsr		paint_digit	;extra 0

			ldx		#0
			lda		_lives
			jsr		paint_bcd ;paint lives

			lda		#FALSE
			sta		_leading0	;erase
			jsr		paint_digit	; spacer
; args for paint_bcd
			ldx		#0
			lda		_bombs   	;paint bombs
			;jsr	paint_bcd	;runs thru
			;rts
paint_bcd:	pha		; hhhhllll  2664
			and		#%11110000
			jsr		paint_digit
;use high nibble -> 16 byte intervals
			cpx		#0
			bne		+
; make sure paint_digit doesnt erase
			lda		#TRUE		;copy
			sta		_leading0
;2672
+			pla			;restore arg
			asl
			asl
			asl			;use low nibble
			asl
;2677
paint_digit:stx		_temp	;preserve X
			tax
			ora		_leading0 ;digits yet?
			sta		_leading0

			ldy		#0
pdigloop:	lda		_leading0	;2680
			beq		+			;blank?
			lda		DIGITS,x ;src =f00
+			sta		(_destptr),y ;dst 2687
			iny
			inx				;next byte
			tya
			and		#%111
			tay				;Y %= 8
			bne		plnext	;while(Y)

			clc					
			lda		_destptr_l	;next cell
			adc		#8			;ptr += 8
			sta		_destptr_l
			bcc		plnext		;boundary?
			inc		_destptr_h	;next page
			bpl		plnext		;> v.top?
			lda		_destptr_h
			sec
			sbc		#$50		;wrap vram
			sta		_destptr_h

plnext:		txa					;26a5
			and		#%1111 		;X % 16?
			bne		pdigloop	;while()
			
			ldx		_temp		;restore
			rts


repaint_dig:ldy		#0			;26ad
			lda		_scrolloff_l
			bpl		+
			ldy		#$ff
+			sty		_temp		;26b5

			clc		
			lda		_digitp_l
			sta		_srcptr_l
			adc		_scrolloff_l
			sta		_destptr_l
			sta		_digitp_l
			lda		_digitp_h
			sta		_srcptr_h
			adc		_temp
			bpl		+
			sec		
			sbc		#$50		;wrap vram
+			cmp		#$30		;26cd
			bcs		+
			adc		#$50
+			sta		_destptr_h	;26d3
			sta		_digitp_h

			lda		#$ff
			eor		_temp
			sta		_temp_h
			lda		#8
			sta		_temp_l

			sec		
			lda		#24
			sbc		_dxwin
			bit		_dxwin
			bmi		rpdig0		;271b

			clc		
			lda		_destptr_l
			adc		#184
			sta		_destptr_l
			bcc		+
			inc		_destptr_h
			bpl		+
			sec		
			lda		_destptr_h
			sbc		#$50
			sta		_destptr_h

+			clc					;26fe
			lda		_srcptr_l
			adc		#184
			sta		_srcptr_l
			bcc		+
			inc		_srcptr_h
			bpl		+
			sec		
			lda		_srcptr_h
			sbc		#$50
			sta		_srcptr_h

+			lda		#248		;2712
			sta		_temp_l

			clc		
			lda		#24
			adc		_dxwin
rpdig0:		tax					;271b
rpdigloop:	ldy		#7			;271c
-			lda		(_srcptr),y	;271e
			sta		(_destptr),y
			dey		
			bpl		-

			clc		
			lda		_srcptr_l
			adc		_temp_l
			sta		_srcptr_l
			lda		_temp_h
			adc		_srcptr_h
			bpl		+
			sec		
			sbc		#$50		;wrap vram
+			cmp		#$30		;2735
			bcs		+
			adc		#$50
+			sta		_srcptr_h	;273b

			clc		
			lda		_destptr_l
			adc		_temp_l
			sta		_destptr_l
			lda		_temp_h
			adc		_destptr_h
			bpl		+
			sec		
			sbc		#$50		;wrap vram
+			cmp		#$30		;274d
			bcs		+
			adc		#80
+			sta		_destptr_h	;2753

			dex		
			bne		rpdigloop
			rts		

init_zp:	lda		#10			;2759
			sta		_humanc
			lda		#8			;2e46
			sta		DXMIN_INIT + LANDER
			lda		#0
			sta		_shootspeed
			lda		#5
			sta		_batchc
			lda		#3
			sta		_lives
			sta		_bombs
			lda		#0
			sta		_score_lsb
			sta		_score_100
			sta		_score_msb
			sta		_level
			;lda	#FALSE
			sta		_no_planet
			rts

reward:		sed					;277d
			clc
			lda		_lives		;bcd_t
			adc		#1			;1up
			sta		_lives
			clc
			lda		_bombs
			adc		#1 			;1 extra
			sta		_bombs 		;smartbomb
			cld

			lda		#18
			jmp		playsound
			;rts

do_nframes:	txa					;2792
			pha		
			jsr		frame_nochk	;1b6e
			pla		
			tax		
			dex		
			bne		do_nframes
			rts		

; addr:		$279d:+57 bytes
; main routine
; ret X:	-1 if ESCAPE condition clred
;			0  otherwise

;int 		frame_all(void);
frame_all:	jsr		do_laser	;172f
			jsr		flash_ship	;1ff0
			jsr		spawn_hiker	;2132
			jsr		repaint_dig	;26ad
			jsr		repaint_map	;15c6

			ldx		#ID_BULLET1	;32
			jsr		ai_unit		;1191
			ldx		#ID_BULLET2	;33
			jsr		ai_unit
			jsr		ai_alt		;34
			jsr		ai_alt		;35
			jsr		ai_alt 		;36
			jsr		ai_batch	;113f 5x

			jsr		next_frame	;1f12
;wait_vblank()
;start_timer()
			jsr		scroll_surf	;226e
			jsr		repaint_all	;21f5
			jsr		collision	;230b
			jsr		spawn_bait	;1a07
;at intervals
			lda		#$7e  		;ack ESC
			jmp		OSBYTE		;condition
			;rts

;27d6
cursor_on:	lda		#4  ;enable 27d6
			ldx		#0  ;cursor editing
			jsr		OSBYTE
			ldx		#10
			lda		#%0111 0010
			jmp		out6845
				;rts

cursor_off:	lda		#4	;disable 27e4
			ldx		#1	;cursor editing
			jsr		OSBYTE	
			ldx		#10	;reg 10 -> cursor
			lda		#%0010 0000	
			jmp		out6845 ;disable blink
				;rts
;also blink freq 1/32
;cursor start line 0

;27f2 no refs?
debugscore:	lda		#FALSE
			sta		_leading0
			ldx		#2
			ldy		#0
			jsr		cursor_xy

			ldx		#2
-			lda		_score_lsb,x  ;27ff
			jsr		print_bcd
			dex		
			bpl		-	
			rts		

print_bcd:	pha					;2808
			lsr		
			lsr		
			lsr		
			lsr		
			jsr		print_digit
			pla		
			and		#%1111		;lo nibble
			;jsr	print_digit
			;rts
print_digit:stx		_xreg		;save 2813

			tax					;arg 0-9
			ora		_leading0
			sta		_leading0	;0 until
			bne		+			;sig fig?
			ldx		#(' '-'0')	;0 -> $f0

+			txa					;281e
			clc					;+$30 ->
			adc		#'0'		;/[0-9 ]/
			ldx		_xreg		;restore
			jmp		OSWRCH		;char out
			;rts

rjust_bcd:	pha					;2827
			lda		#FALSE
			sta		_leading0	;leading
			pla					;blanks
			jmp		print_bcd
			;rts

cursor_xy:	lda		#31	; move cursor 2830
			jsr		OSWRCH
			txa			; VDU 31,rowX,colY
			jsr		OSWRCH
			tya				
			jmp		OSWRCH
			;rts

hiscore:	lda		#$7e		;283d
			jsr		OSBYTE 		;ack ESC

			ldx		#0		  	;top score
highloop:	lda		HiScore,x	;2844
			cmp		_score_lsb ; > C clear
			lda		HiScore+1,x
			sbc		_score_100 ; > clear
			lda		HiScore+2,x
			sbc		_score_msb ; [-1]
			bcc		newhigh	   ; > hi[x]?

			txa		
			clc		
			adc		#24	; next score @tbl
			tax		
			cpx		#(24 * 7 + 1) ; =169
			bcc		highloop  ; 8x scores
			bcs		print_highs	; too low?

			; found place @tbl
newhigh:	stx		_temp		;2860
			cpx		#(24 * 7)	;=168
			beq		+	; lowest place?

			ldx		#168
-			dex					;2868
			lda		HiScore,x ; 2nd last
			sta		HiScore+24,x  ; last
			cpx		_temp
			bne		-  ; shift scores down

+			lda		#'\r'		;2873 0d
			sta		HiScore+3,x ; blank
			lda		_score_lsb
			sta		HiScore,x
			lda		_score_100
			sta		HiScore+1,x
			lda		_score_msb   ;enter in
			sta		HiScore+2,x ;score

			jsr		print_highs
			jsr		input_name

print_highs:lda		#3			;288d
			jsr		print_n
			jsr		cursor_off

			ldx		#0
			stx		_high_rank
			ldy		#6		; text row
prhiloop:	txa					;289b
			pha		
			pha		

			sed
			clc		
			lda		_high_rank ; #1 to #8
			adc		#1
			sta		_high_rank
			cld		

			ldx		#3
			jsr		cursor_xy
			lda		_high_rank
			jsr		rjust_bcd	; print
			lda		#'.'		;2e
			jsr		OSWRCH
			ldx		#7
			jsr		cursor_xy

			pla		; tbl offset
			tax		
			lda		HiScore+2,x
			jsr		rjust_bcd
			lda		HiScore+1,x
			jsr		print_bcd
			lda		HiScore,x
			jsr		print_bcd

			cpx		_temp
			bne		+
			sty		_temp2	; entry row
+			lda		#5			;28d5
			jsr		print_n

			inx		
			inx		
			inx		
-			lda		HiScore,x	;28dd
			jsr		OSWRCH
			inx		
			cmp		#'\r'
			bne		-

			iny		
			iny		; next row of text	
			pla		
			clc		
			adc		#24
			tax		
			cpx		#(24 * 8)	; =192
			bne		prhiloop

			rts		

input_name:	lda		#4			;28f4
			jsr		print_n
			jsr		cursor_on	;27d6

			lda		#$0f
			ldx		#1
			jsr		OSBYTE
			ldx		#18
			ldy		_temp2	; entry row
			jsr		cursor_xy

			clc		
			lda		_temp
			adc		#3
			sta		paramblock	;2c80
			lda		#0
			adc		#>HiScore	;7
			sta		paramblock +1
			lda		#20		; max length
			sta		paramblock +2
			lda		#$20
			sta		paramblock +3
			lda		#$7e
			sta		paramblock +4
			ldx		#<paramblock
			ldy		#>paramblock
			lda		#0
			jsr		OSWORD

			bcc		+	
			ldx		_temp
			lda		#'\r'
			sta		HiScore+3,x
+			jmp		cursor_off	;293a
			;rts

init_video:	lda		#22			;293d
			jsr		OSWRCH		;ffee
			lda		#2
			jsr		OSWRCH		;MODE 2
; no video/cursor blanking delay
			ldx		#8	;reg 8
			lda		#0	;non-interlcd sync
			jsr		out6845
; disable cursor editing + blink
			jmp		cursor_off
			;rts
;2951
done_level:	lda		_xrel_h
			jsr		new_screen
			lda		#1
			jsr		print_n

			ldx		#40
			ldy		#159
			jsr		setptr_xy
			lda		#0
			sta		_leading0
			lda		_level
			jsr		paint_bcd
			
			ldx		#42
			ldy		#135
			jsr		setptr_xy
			lda		#0
			sta		_leading0
			lda		_humanbonus		;17
			jsr		paint_bcd
			lda		#0
			jsr		paint_bcd

			lda		_humanc
			beq		lvldone

			sta		_count ; bonus counter
			ldx		#25		; += 3 ..
bonusloop:	ldy		#119			;2988
			txa		
			pha		
			jsr		setptr_xy
			ldx		#HUMAN			;6
			jsr		paint_spr

			ldy		_humanbonus	; x100
			ldx		#00			; per human
			jsr		add_score

			ldx		#4
			jsr		delay

			pla		
			clc		
			adc		#3			; spacing
			tax		

			dec		_count
			bne		bonusloop
;29a9
lvldone:	ldx		#70
			jsr		delay
			rts	
;29af
delay:		txa
			pha		
			jsr		next_frame	;1f12
			pla		
			tax		
			dex		
			bne		delay
			rts		
;29ba
main:		jsr		init_video
					; play game 
			jsr		planetoid
; _gameover_sp returns here / game over
			lda		_xrel_h ;start @same Xpos
			jsr		new_screen
			lda		#2
			jsr		print_n
			ldx		#100
			jsr		delay
main_hisc:	jsr		hiscore			;29cf

			lda		#6
			jsr		print_n
			jsr		waitspc_in
			; infinite loop
			jmp		main
;29dd
planetoid:	tsx
			stx		_gameover_sp
; sp returns as if from this fn
			lda		#0
			jsr		playsound

			jsr		init_zp
planetloop:	jsr		next_level		; 29e8
			jsr		game		;1db1
; _savedsp3f returns here / level complete
			jsr		done_level	;2951
; make sure lives remain
			lda		_lives		
			bne		planetloop	; level++

			rts		; game over

anim_frame:	lda		Param,x		;29f6
			cmp		#8	;1st frame?
			beq		+	;nothing to erase

			lda		_originp_l
			pha		
			lda		_originp_h
			pha		
			lda		_xrel_l
			pha		
			lda		_xrel_h
			pha		
			lda		pNext_l,x
			sta		_originp_l
			lda		pNext_h,x
			sta		_originp_h
			lda		pSprite_l,x
			sta		_xrel_l
			lda		pSprite_h,x
			sta		_xrel_h

			jsr		xoranimate ;erase old

			pla		
			sta		_xrel_h
			pla		
			sta		_xrel_l
			pla		
			sta		_originp_h
			pla		
			sta		_originp_l

+			ldy		Param,x		;2a2c
			dey		
			tya		
			sta		Param,x
			beq		+

			lda		_originp_l
			sta		pNext_l,x
			lda		_originp_h
			sta		pNext_h,x
			lda		_xrel_l
			sta		pSprite_l,x
			lda		_xrel_h
			sta		pSprite_h,x
			
			jmp		xoranimate ; paint new
			;rts

+			lda		Anim,x		;2a4d
			bmi		++
			cpx		#0
			bne		+
			asl		
			bpl		+
			lda		#1
			sta		_dead
+			lda		#0			;2a5d
			sta		Anim,x
			sta		pSprite_h,x
			sta		pNext_h,x
			rts		

++			lda		#$ff		;2a69
			sta		Unit,x
			jmp		init_unit
			;rts

;2a71
xoranimate:	lda		_min_xscr
			pha		
			lda		_max_xscr
			pha		
			lda		#0
			sta		_min_xscr
			lda		#80
			sta		_max_xscr

			jsr		get_xscr		;X pos
			cmp		#100
			bpl		xanim_ret
			cmp		#ec			;< -20 ?
			bmi		xanim_ret
			sta		_anim_xscr
			lda		Anim,x
			bmi		anim_blast

; default anim: spawning (warp in)
anim_warp:	lda		Param,x		;2a91
			cmp		#7
			bne		+			;@start?
			lda		#6
			jsr		playsound

+			ldy		#7			;2a9d
warploop:	sty		_yreg		;2a9f loopc
			ldx		_anim_xscr
			lda		$2c50,y
			jsr		warp_coord	;2b3a
			pha		
			ldx		_id
			lda		Y_h,x
			tax		
			lda		$2c58,y
			jsr		warp_coord

			tay		
			pla		
			tax		
			jsr		setptr_xy
			lda		_destptr_h	;offscreen?
			beq		warpnext	;null ptr?
warpdot:	ldy		#0			;2abf
			ldx		_id
			lda		Unit,x		;sprite #
			asl		
			tax		
			lda		MAP_DOT,x	;map colour
			eor		(_destptr),y
			sta		(_destptr),y ;plot/wipe

warpnext:	ldy		_yreg		;2ad0 loopc
			dey		
			bpl		warploop	;8x dots

			ldx		_id
xanim_ret:	pla					;2ad7
			sta		_max_xscr
			pla		
			sta		_min_xscr
			rts		

;2c60 [8]
;XBLAST:	.byte	2,4,0,-4,-2,-4,0,4
;2c68 [8]
;YBLAST:	.byte	0,12,6,12,0,-12,-6,-12

anim_blast:	ldy		#7			;2ade
blastloop:	lda		_anim_xscr	;2ae0
			ldx		XBLAST,y	;2c60
			jsr		blast_coord	;Xscr
			pha		
			lda		Y_h,x
			ldx		YBLAST,y	;2c68
			jsr		blast_coord	;Yscr
blastptr:	tay					;2af2
			pla		
			tax		
			cpy		#192
			bcs		blastnext	;too high?
			jsr		setptr_xy

			lda		_destptr_h
			beq		blastnext	;offscrn?
blastdot:	ldy		#0			;2b05
			ldx		_id
			lda		Unit,x		;sprite #
			asl					; * 2
			tax		
			lda		MAP_DOT,x	;colour
			eor		(_destptr),y
			sta		(_destptr),y ;XOR blit
;			jmp		blastnext	;"?
;			pla					;unused?
blastnext:	ldx		_id			;2b14
			ldy		_yreg
			dey		
			bpl		blastloop

			jmp		xanim_ret
			;rts

blast_coord:sty		_yreg		;2b1e
			stx		_temp
			ldx		_id

			pha		
			sec		
			lda		#8
			sbc		Param,x
			tay		
			pla		

-			clc					;2b2d
			adc		_temp
			dey		
			bne		-			;[1,7] -> 0

			php		
			ldy		_yreg
			ldx		_id
			plp		
			rts		

warp_coord:	stx		_xreg		;2b3a
			sec		
			sbc		_xreg     	;carry
			sta		_offset_l 	;=(A - X)
			lda		#0
			sbc		#0		 	;sign xtnd
			sta		_offset_h	;0 | ff

			lda		#0
			sta		_srcptr_l
			sta		_srcptr_h
			ldx		_id
			lda		Param,x
			tax		
-			clc					;2b53
			lda		_srcptr_l
			adc		_offset_l
			sta		_srcptr_l
			lda		_srcptr_h
			adc		_offset_h
			sta		_srcptr_h
			dex		
			bne		-			;[7,1] ->0

			lda		_srcptr_l
			lsr		_srcptr_h	; /= 8
			ror		
			lsr		_srcptr_h
			ror		
			lsr		_srcptr_h
			ror		
			clc		
			adc		_xreg
			rts					;->coord A
;			rts					;unused

get_ysurf:	lda		X_l,x		;2b73
			asl		
			lda		X_h,x
			rol		
			tay		
			lda		YSURFACE,y
			rts		

;addr:		$2b80:+12 bytes
; arg A:	linked sprite # (LANDER|HUMAN)
; arg Y:	linked id #
; ret:		Z set if drawn,NOT linked
;Wrapper fn -> is_linked(), X preserved
;
;bool		is_unlinked(sprite_t	spr,
;						unit_t		link)
;{ return is_linked(spr, NULL, link); }
is_unlinked:stx		_temp_h
			ldx		#NULL		;NOT ship
			jsr		is_linked
			php					;save Z	

			ldx		_temp_h
			plp					;restore
			rts					;ret Z	

; addr:		2b8c:+20 bytes
; arg A:	linked sprite #	(LANDER|HUMAN)
; arg X:	current id #	(ai_xxxx -> X)
; arg Y:	linked id #		(= Param,X)
; ret:		Z flag set if linked + drawn

;bool		is_linked(	sprite_t	spr,
;						unit_t		ai,	
;						unit_t		link);
is_linked:	eor		Unit,y		;link.spr
			and		#%0111 1111	;mask flag
			bne		linkerr		;== spr?

			stx		_temp_l		;ai
			lda		Param,y		;link.ptr
			cmp		_temp_l		;linked
			bne		linkerr		;back?

			lda		Anim,y		;drawn ->Z
linkerr:	rts					;ret Z

;3000
;actual ENTRY POINT
boot:		lda		#$00		;3000
			ldx		#1			;get MOS
			jsr		OSBYTE 		;version
; returned in X, but unused?
			ldx		#$ff
			txs					;init stck

			sei					;hook irq
			lda		IRQ1V		;204
			sta		_savedirq
			lda		IRQ1V +1
			sta		_savedirq + 1
			lda		#<irq1v_hook ;1103
			sta		IRQ1V
			lda		#>irq1v_hook
			sta		IRQ1V + 1
			cli					;re-enable

			ldx		#0			;hiscores
yreset:		ldy		#0			;3022
mkhiloop:	lda		DEFAULTHI,y	;3024 [24]
			sta		HiScore,x
			inx					;Acornsoft
			iny					;1000 pts
			cpy		#24	
			bcc		mkhiloop
			cpx		#(24*7 + 1)	;169
			bcc		yreset

			lda		#(PAL_SHIP | WHITE)
			sta		_ship_cl	;77
			jmp		main		;startgame

;303b
;			.byte	0,0,0,0,0	
;3040	
;DEFAULTHI:	.byte	0,$10,0		
;			.text	"Acornsoft",13
;			.byte	0,0,0,0,0,0,0,0
;			.byte	0,0,0
;3058 
;	(zeros til 30ff)
;			.resb	($3100 - $)
