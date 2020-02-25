
; vi: syntax=asmM6502 ts=4 sw=4

; Acornsoft Planetoid, BBC Micro
; Written by Neil Raine, 1982
; 6502 disassembly by rainbow
; 2020.02.08
; <djrainbow50@gmail.com>
; https://github.com/r41n60w/planetoid-disasm

;$e00 -> $eff:  
;	planet surface Y coords
;$f00 -> $10ff:
;  all sprite data 

.org	$e00

;$e00	ypos_t[256]
;Planet surface Y coords, for each Xwin
SurfaceY:
.byte	 34, 38, 42, 44, 40, 36, 32, 28
.byte	 25, 25, 25, 25, 25, 25, 25, 25
.byte	 25, 25, 26, 29, 30, 33, 34, 37
.byte	 38, 42, 45, 46, 49, 50, 54, 58
.byte	 60, 56, 52, 48, 45, 44, 40, 36
.byte	 32, 29, 28, 25, 25, 25, 25, 25
.byte	 25, 25, 25, 25, 25, 25, 25, 25
.byte	 25, 25, 26, 30, 34, 38, 42, 44
		;$e40
.byte	 40, 36, 32, 30, 34, 38, 42, 44
.byte	 40, 38, 40, 36, 34, 36, 32, 29
.byte	 29, 29, 29, 29, 29, 29, 29, 29
.byte	 29, 29, 29, 29, 30, 33, 34, 37
.byte	 38, 41, 42, 45, 46, 49, 50, 54
.byte	 58, 61, 62, 66, 69, 70, 72, 68
.byte	 66, 68, 64, 62, 64, 61, 57, 57
.byte	 56, 52, 49, 48, 45, 44, 41, 40
		;$e80
.byte	 37, 36, 32, 29, 28, 25, 25, 25
.byte	 25, 25, 25, 25, 25, 25, 25, 25
.byte	 25, 25, 25, 25, 25, 25, 25, 25
.byte	 25, 25, 25, 25, 26, 30, 34, 36
.byte	 32, 30, 32, 30, 32, 30, 32, 28
.byte	 24, 20, 17, 17, 17, 18, 22, 25
.byte	 25, 25, 25, 25, 25, 25, 25, 25
.byte	 25, 25, 25, 25, 25, 25, 25, 25
		;$ec0
.byte	 25, 25, 25, 25, 25, 25, 25, 25
.byte	 25, 25, 25, 25, 25, 25, 25, 25
.byte	 25, 26, 29, 30, 33, 34, 38, 42
.byte	 45, 46, 49, 50, 53, 54, 57, 58
.byte	 61, 62, 65, 64, 60, 56, 53, 53
.byte	 52, 48, 44, 41, 40, 37, 37, 36
.byte	 32, 29, 29, 29, 29, 29, 29, 29
.byte	 29, 29, 29, 29, 29, 29, 29, 30

;$f00	vram_t[10][16]
;Digits 0-9 sprite data (each 4x8px)
imgDigit:
.byte	$30,$20,$20,$20,$20,$20,$30,$00 ;0
.byte	$20,$20,$20,$20,$20,$20,$20,$00
.byte	$10,$30,$10,$10,$10,$10,$30,$00 ;1
.byte	$00,$00,$00,$00,$00,$00,$20,$00
.byte	$30,$00,$00,$30,$20,$20,$30,$00 ;2
.byte	$20,$20,$20,$20,$00,$00,$20,$00
.byte	$30,$00,$00,$30,$00,$00,$30,$00 ;3
.byte	$20,$20,$20,$20,$20,$20,$20,$00
.byte	$20,$20,$20,$30,$00,$00,$00,$00 ;4
.byte	$20,$20,$20,$20,$20,$20,$20,$00

.byte	$30,$20,$20,$30,$00,$00,$30,$00 ;5
.byte	$20,$00,$00,$20,$20,$20,$20,$00
.byte	$30,$20,$20,$30,$20,$20,$30,$00 ;6
.byte	$20,$00,$00,$20,$20,$20,$20,$00
.byte	$30,$00,$00,$00,$00,$00,$00,$00 ;7
.byte	$20,$20,$20,$20,$20,$20,$20,$00
.byte	$30,$20,$20,$30,$20,$20,$30,$00 ;8
.byte	$20,$20,$20,$20,$20,$20,$20,$00
.byte	$30,$20,$20,$30,$00,$00,$30,$00 ;9
.byte	$20,$20,$20,$20,$20,$20,$20,$00

;$fa0	vram_t[8]
;Humanoid sprite data (#6, 2x8px)
imgMan:	
.byte	$cc,$cd,$cd,$cc,$f3,$51,$51,$51

;$fa8	vram_t[24]
;Pod sprite data (#7, 6x8px)
imgPod:
.byte	$00,$10,$10,$c3,$c3,$10,$10,$00
.byte	$82,$92,$92,$c3,$c3,$92,$92,$82
.byte	$00,$00,$00,$82,$82,$00,$00,$00

;$fc0	vram_t[48]
;Ship (right) sprite data (#0r, 12x8px)
imgShipR:
.byte	$15,$3f,$15,$11,$11,$11,$33,$11
.byte	$00,$2a,$3f,$3f,$37,$33,$33,$33
.byte	$00,$00,$00,$2a,$3f,$3f,$3f,$37
.byte	$00,$00,$00,$00,$00,$3f,$3f,$3f
.byte	$00,$00,$00,$00,$00,$07,$07,$3f
.byte	$00,$00,$00,$00,$00,$08,$1d,$3f
;$ff0	vram_t[48]
;Ship (left) sprite data (#0l, 12x8px)
imgShipL:
.byte	$00,$00,$00,$00,$00,$04,$2e,$3f
.byte	$00,$00,$00,$00,$00,$0b,$0b,$3f
.byte	$00,$00,$00,$00,$00,$3f,$3f,$3f
.byte	$00,$00,$00,$15,$3f,$3f,$3f,$3b
.byte	$00,$15,$3f,$3f,$3b,$33,$33,$33
.byte	$2a,$3f,$2a,$22,$22,$22,$37,$22

;$1020	vram_t[3][4]
;Planet surface tiles sprite data (2x4px)
imgSurface:
.byte	$28,$28,$14,$14 ; \  down slope
.byte	$00,$28,$3c,$14 ; ~  flat
.byte	$14,$14,$28,$28 ; /  up slope

;$102c	vram_t[32]
;Lander sprite data (#1, 8x8px)
imgLander:
.byte	$00,$45,$cc,$cc,$44,$00,$44,$88
.byte	$cf,$cf,$44,$44,$cc,$ce,$44,$44
.byte	$8a,$cf,$44,$44,$cc,$8a,$44,$00
.byte	$00,$00,$88,$88,$00,$00,$00,$88

;$104c	vram_t[32]
;Mutant sprite data (#2, 8x8px)
imgMutant:
.byte	$00,$51,$cc,$cc,$44,$00,$44,$88
.byte	$0c,$0c,$51,$51,$f3,$d9,$51,$51
.byte	$88,$f6,$44,$44,$e6,$88,$44,$00
.byte	$00,$00,$88,$88,$00,$00,$00,$88

;$106c	vram_t[20]
;Baiter sprite data (#3, 10x4px)
imgBaiter:	.byte	$00,$44,$cd,$44
			.byte	$cc,$c0,$ca,$cc
			.byte	$cc,$c0,$cf,$cc
			.byte	$cc,$c0,$c5,$cc
			.byte	$00,$88,$ce,$88

;$1080  5 unused bytes
			.byte	$00,$00,$00,$00,$00
;$1085	15 byte code fragment
; -> This matches scroll_surf():$22bb
			.byte	$50			;lda #80
			sbc		_temp
			tay
			ldx		#RIGHT		;1
			lda		_temp		;old:
			jsr		$1d73	;psurf_right()
			jmp		$20fb	;ssurf_ret
			pla

;$1094	vram_t[24]
;Bomber sprite data (#4, 6x8px)
imgBomber:
.byte	$51,$03,$06,$06,$06,$06,$03,$03
.byte	$f3,$03,$0c,$0e,$0e,$0c,$03,$03
.byte	$f3,$53,$53,$53,$53,$53,$02,$02

;$10ac	vram_t[12]
;Swarmer sprite data (#5, 6x4px)
imgSwarmer:	.byte	$00,$41,$c7,$41
			.byte	$82,$c3,$c7,$c3
			.byte	$00,$00,$82,$00

;$10b8	vram_t[2]
;Bullet/mine sprite data (#8, 2x2px)
imgKugel:	.byte	$aa,$aa

;$10ba	vram_t[4]
;Shrapnel sprite data (2x4px)
imgShrapnel:.byte	$ff,$ff,$ff,$ff

;$10be	vram_t[40]
;Score '250' sprite data (#9, 10x8px)
img250:
.byte	$00,$00,$05,$00,$05,$05,$05,$00
.byte	$00,$00,$0f,$05,$0f,$00,$0f,$00
;$10ce	vram_t[40]
;Score '500' sprite data (#10, 10x8px)
img500:
.byte	$00,$00,$0c,$08,$0c,$00,$0c,$00
.byte	$00,$00,$09,$01,$09,$09,$09,$00
.byte	$00,$00,$03,$01,$01,$01,$03,$00
;img250[40] end
.byte	$00,$00,$0f,$0a,$0a,$0a,$0f,$00
.byte	$00,$00,$0a,$0a,$0a,$0a,$0a,$00

;$10f6	10 unused bytes
			.byte		$00	
			.word		2440	;BASIC
			.word		2450	;line #s??
			.word		2460
			.word		2470
;$10ff
			.byte		$09
