; vi: syntax=asmM6502 ts=4 sw=4

; Acornsoft Planetoid, BBC Micro
; Written by Neil Raine, 1982
; 6502 disassembly by rainbow
; 2020.02.08
; <djrainbow50@gmail.com>
; https://github.com/r41n60w/planetoid-disasm

; file: PLANET2
; 8960 bytes, ~35 pages

; all assembly code

			org		$1100

;$1100,+3	1loc
;Entry point (NOT PLANET2's exec addr!)
;@$.PLANET1 (BASIC program):
;	*L. PLANET2:CALL &1100
entrypoint:	jmp		boot

;$1103,+13	5 loc
;Interrupt hook, IRQ1V vectors here
;interrupt void irq_hook(void);
irq_hook:	lda		#%00000010	;bit 1/Vs?
			bit		SYS6522 +13	;SyVIA R13
			beq		+		   	;IRQstatus
			inc		vsync    	;vsync++
+			jmp		(!_irq1v)	;emter IRQ

; addr:		$1110:+10 bytes,, 5 loc
;Busy wait until vsync
;void		wait_vsync(void);
wait_vsync:	lda		vsync		;vsync ->
			cmp		_vsync0		;++c > c0?
			beq		wait_vsync	;no,loop
; vsync -> now within vblank
			sta		_vsync0		;equalize
			rts					;again
;@@@ Timing:
;wait_vsync() is entered at any time before the next frame/vblank, depending on the frame's AI load, # to repaint etc.
;   Returning from it however, will be at a specific, constant time (relative to each frame's 20ms period).
;  The vertical sync pulse just fired, so the timing here about halfway through the monitor's vertical blanking interval.
;  The BBC micro's vblank lasts ~ 4ms, so after wait_vsync() there's:

; ~2ms vblank -> draw + change palette
; ~16ms raster scanning, top to bottom
; another ~2ms of next vblank

; ... then the next frames wait_vsync().

;    Useless of course with full screen sprite handling, BUT no problem with Planetoid thanks to the divided screen (minimap at top, playfield bottom) ..
;    This accurate timing cycle is used to exploit the top-to-bottom raster scan, namely to paint/erase the main game while rasters near the top @minimap, and vice versa! =)

;$111a,+6	3loc
;Test if vsync
;bool		is_vsync(void);
is_vsync:	lda		vsync
			cmp		_vsync0
			rts
;Like wait_vsync(), but returns test (presumably in Z) instead of blocking.
;Called once from ai_batch() but return is discarded (?)

;$1120,+8	5loc
;Map _p_hysical to _l_ogical colour
;void		set_palette(palette_t logical,
;						colour_t physical)
set_palette:pha					
			eor		#%111		;llllpppp 
			sta		ULAPALETTE	;video ULA
			pla			   		;"Palette"
			rts					;reg $fe21

;$1128,+7	3loc
;Write a byte of data to a 6845 CRTC reg
;	arg X:	register #	-> $fe00
;	arg Y:	data byte	-> $fe01
;void		out6845(uint8_t		reg,
;					uint8_t		data);
out6845:	stx		SHEILA		;reg #0-17
			sta		SHEILA + 1	;byte out
			rts

;$112f,+12	5loc
;Init + start hardware timer 1 (@user VIA)
;Loading T1C-H auto starts timer
;timer T1 flags @aux ctrl reg:
;	one-shot mode, disable latch/shift reg
;	arg X:	counter lo byte
;	arg Y:	" hi byte (cycles @1MHz)
;void		start_timer(uint16_t count);
start_timer:lda		#%10000000	;setup T1
			sta		USR6522 +11	;ACR
			stx		USR6522 +4	;T1C-L
			sty		USR6522 +5	;T1C-H
			rts		

;$113b,+4	2loc
; Test timer state (input reg B -> PB7)
;	ret N:	set if timer has run out	
;bool		timerstate(void);
timerstate:	bit		USR6522 +0	;IRB.PB7?
			rts					;ret -> N

;$113f,+67	33loc
;Process batch of unit AIs
;void		ai_batch(	size_t	batch,
;						id_t	id);
ai_batch:
;			ldx		#SHIP
;			jsr		get_xscr	;useless?
;			sta		_ship_xscr
xrange:		lda		#0
			sta		_min_xscr
			lda		#77
			sta		_max_xscr
			lda		_scrolloff_l
			bpl		rrange		;if(>0)
lrange:		clc
			adc		#77			;(77-8*dx)
			sta		_max_xscr
			bne		batchinit	;else
rrange:		sta		_min_xscr	;(8*dx)

batchinit:	lda		_batch		;init.ly 5
			sta		_batchc		;loop idx
			ldx		_id			;curr id #
batchloop:	jsr		ai_unit

			ldx		_id			;[0,]2-31
nextid:		inx					;id++
			cpx		#HITCH
			beq		nextid		;skip #1
			cpx		#ID_MAX + 1	;#32
			bne		batchid		;@last sl?
			ldx		#ID_MIN		;#2
			lda		Anim + SHIP	;ship	
			beq		batchid		;normal?
			ldx		#SHIP		;#0(hyper)
batchid:	stx		_id
;			jsr		is_vsync	;useless?
batchnext:	dec		_batchc		;while(--)
			bne		batchloop	;[5+,1]
			rts		

;$1182,+15	8loc
;Process one of ID_ALT<123>
;void		ai_alt(void);
ai_alt:		ldx		_id_alt		;1182
			jsr		ai_unit

			inx					;[34,36]
			cpx		#ID_ALT3 + 1 
			bne		altid		;#37?
			ldx		#ID_ALT1	;-> #34
altid:		stx		_id_alt
			rts		
;static id_t		_id_alt =
;			ID_ALT1, ID_ALT2, ID_ALT3;

;$1191,+43	19loc
;Process unit AI
;	arg X:	unit id #
;void		ai_unit(id_t id);
ai_unit:	lda		Unit,x
			bpl		noai		;BLIT?
			;-> if(unit & UPDATE)
aivec:		asl					;spr# <<1
			tay					;AI vector
			bmi		noai		;EMPTY?
			lsr					;clr hibit
setblit:	sta		Unit,x		;-> BLIT
			lda		Anim,x
			beq		aijump		;present?
			bmi		aiexplode
aiwarp:		jsr		anim_frame	;warp in
			jmp		mm_update
			;rts
aiexplode:	jmp		anim_frame	;explode
			;rts
aijump:		lda		AiVector,y
			sta		_destptr_l
			lda		AiVector + 1,y
			sta		_destptr_h	;jump
			jmp		(!_destptr) ;to vector
			;...rts
noai:		rts					;fail,exit

;$11bc,+3	1loc
;AI vector for U_SHIP
;	arg X:	unit id #
;void		ai_ship(id_t id);
ai_ship:	jmp		move_unit
			;rts
;Only execd when ship exploding,
; ie all slots become U_SHIP

;$11bf,+27	12loc
;AI vector for KUGEL,S250,S500
;	arg X:	unit id #
;void		ai_object(id_t id);
ai_kugel:						;#8
ai_250:							;#9
ai_500:							;#10
ai_object:	ldy		Param,x		
			iny					;age++
			tya		
			sta		Param,x
			cpy		#160		;> frames
			bne		+			;too old?
			jmp		erase_unit
			;rts
aisprmove:	jsr		move_unit	;straight
			lda		pNext_h,x	;NULL/
			bne		+		 	;offscrn?
			jmp		erase_unit	;-> erase
			;rts
aispr_ret:	rts
;unsigned age = Param[id];

;$11da,+391
;AI vector for LANDER
;	arg X:	unit id #
;void		ai_lander(id_t id);
ai_lander:	lda		_humanc
			bne		ldrshoot	;noplanet?
			jsr		erase_unit	;lander
			lda		#MUTANT		;#2
			sta		Unit,x		;->
			jmp		ai_mutant 	;mutant

ldrshoot:	lda		#10
			jsr		shootchance	;1:25 odds
			lda		Param,x
			pha		
			and		#%111111
			tay		
			pla		
			bne		+			;(param)?
			jmp		j1v_e		;12d2
+			bmi		j1v_c		;11fb

			lda		Y_h,x
			cmp		#190
			bcc		toj7v_0		;1227

			lda		#MAN		;6
			jsr		is_linked
			bne		j1v_b

			tya					;mutant	
			tax		
			jsr		kill_unit
			ldx		_id
			jsr		erase_unit
			lda		#MUTANT
			sta		Unit,x
			jmp		ai_mutant

j1v_a:		ldy		#LANDER		;121d 1
			jsr		init_dxy

-			lda		#0			;1222
			sta		Param,x
toj7v_0:	jmp		ai_update	;1227

j1v_b:		jsr		erase_unit	;122a
			lda		#LANDER
			sta		Unit,x
			jmp		init_unit
			;rts

j1v_c:		lda		Param,x		;1235
			asl		
			bmi		j1v_d		;1266

			lda		#MAN
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
			cmp		#MAN
			bne		j1v_a
			lda		Param,y
			and		#%1100 0000
			bne		j1v_a		;b6 || b7?

			lda		Param,y
			beq		+
			lda		#0
			sta		dY_l,x
			sta		dY_h,x
			jmp		ai_update

+			lda		Y_h,x		;1286
			sec		
			sbc		#10
			cmp		Y_h,y
			bcs		toj7v_1
			sta		Y_h,y

			lda		dXMinInit + LANDER
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
toj7v_1:	jmp		ai_update	;12cf

j1v_e:		jsr		random		;12d2
			and		#%11111		;[0,31]
;			cmp		#32
;			bcs		j1v_e		;impossbl?
			cmp		#ID_MIN		;2
			bcc		j1v_e	
			tay					;[2,31]

			lda		#MAN
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
			jmp		ai_update

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
			jmp		ai_update

yadd:		clc					;134d
			lda		Y_l,x
			adc		_temp_l
			sta		Y_l,x
			lda		Y_h,x
			adc		_temp_h
			sta		Y_h,x
			jmp		ai_update

;$1361,+151
;AI vector for MUTANT
;	arg X:	unit id #
;void		ai_mutant(id_t id);
ai_mutant:	lda		#25
			jsr		shootchance	;1:10 odds

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
			jmp		ai_update

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

;$13f8,+53	21loc	
;AI vector for BAITER
;	arg X:	unit id #
;void		ai_baiter(id_t id);
ai_baiter:	lda		#40
			jsr		shootchance	;1:6 odds
			lda		Param,x
			beq		baitcount	;re target
			dec		Param,x		;count--
			jmp		ai_update
			;rts
baitcount:	jsr		random
			and		#%111
			clc					;rand
			adc		#10			;[10,17]
			sta		Param,x		;new count
baitchase:	txa		
			tay					;arg =id
			jsr		target_ship
			asl		dY_l,x
			rol		dY_h,x
			asl		dX_l,x
			rol		dX_h,x
			asl		dX_l,x
			rol		dX_h,x
			jmp		ai_update
			;rts

;$142d,+9	3loc
;AI vector for BOMBER
;	arg X:	unit id #
;void		ai_bomber(id_t id);
ai_bomber:	jsr		minechance
			jsr		dy_sine
			jmp		ai_update
			;rts

;$1436,+58	24loc
;AI vector for SWARMER
;	arg X:	unit id #
;void		ai_swarmer(id_t id);
ai_swarmer:	jsr		dy_sine
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
			jmp		ai_update
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
			jmp		ai_update

;$1470,+65	33loc
;Moves unit vertically in a sine wave
;	arg X:	unit id
;	ret:	alters dY[id] in place
;vector_t	dysine(id_t id);
dy_sine:	lda		#0
			sta		_temp
			lda		Y_h,x
			sec					;Y' axis
			sbc		#98			;=(Y-98) 
			bcs		uppersine 	;Y' > 0??

lowersine:	eor		#$ff		;[-88,-2]
			clc					;negate
			adc		#1			;-> [88,2]
			asl					; * 4
			rol		_temp		;+ve accel
			asl					;ddY_l
			rol		_temp		;ddY_h
accelup:	clc
			adc		dY_l,x		;vel += 
			sta		dY_l,x		;accel
			lda		_temp
			adc		dY_h,x
			sta		dY_h,x
			rts			

uppersine:	asl
			rol		_temp		;* 4
			asl					
			rol		_temp		;ddY HI
			sta		_temp2		;ddY LO
acceldown:	sec					;-ve accel
			lda		dY_l,x		;/subtract
			sbc		_temp2		;dY
			sta		dY_l,x		;-= accel
			lda		dY_h,x
			sbc		_temp
			sta		dY_h,x
			rts		
; accel greatest at screen top/bottom,
; 		0 at midscreen   (Y' == 0)

;$14b1,+183
;AI vector for MAN
;	arg X:	unit id #
;void		ai_human(id_t id);
ai_human:	lda		Param,x
			bne		manlink		;active?
			jmp		walk		;no

manlink:	bmi		manfall
			tay					;id
			lda		#LANDER		;#1
			jsr		is_linked
			bne		startfall
			jmp		ai_update

manfall:	asl
			bmi		falling
			stx		_xreg		;ai id
			ldx		#HITCH
			jsr		get_ysurf	;Ysurf
			ldx		_xreg
			cmp		Y_h + HITCH	;landed?
			bcs		rescued		;drop off
			rts		

rescued:	dec		_hikerc		;hikerc--
			lda		X_h + HITCH
			sta		X_h,x
			lda		Y_h + HITCH	;update id
			sta		Y_h,x
			lda		#0
			sta		dY_h,x		
			sta		dY_l,x		;standing
			sta		Param,x		;idle
			lda		#15
			jsr		playsound
			jsr		score500
			jmp		ai_update
	
startfall:	lda		#$ff
			sta		Param,x		;falling
			lda		#0
			sta		dY_l,x
			sta		dY_h,x
falling:	sec
			lda		dY_l,x
			sbc		#64			;gravity
			sta		dY_l,x		;accel
			lda		dY_h,x
			sbc		#0
			sta		dY_h,x
			jsr		get_ysurf
			cmp		Y_h,x		;man hit
			bcc		ai_update	;ground?
			lda		dY_h,x		;fall velc
			cmp		#$fb		;> -5?
			bcs		+
			jmp		kill_unit	;splat

landsafe:	lda		#0			;safely
			sta		Param,x		;fell
			ldy		#MAN		;walking 
			jsr		init_dxy 	;speed
			lda		#15
			jsr		playsound
			jmp		score250 	;flash 250

walk:		lda		dX_l,x
			sta		_temp_l
			lda		dX_h,x
			asl		_temp_l
			rol		
			asl		_temp_l
			rol		
			asl		_temp_l
			rol		
			sta		_temp_h		;signed
			jsr		get_ysurf
			sec		
			sbc		Y_h,x
			cmp		#4
			bmi		walkdown
			cmp		#8
			bpl		walkup
			bmi		ai_update
walkup:		jmp		moveup
walkdown:	jmp		movedown

;$1568,+10	4loc
;AI vector for POD/all other AIs jump here
;	arg X:	unit id #
;void		ai_pod(id_t id);
ai_pod:
ai_update:	ldx		_id
			jsr		move_unit
			ldx		_id
			jmp		mm_update
			;rts

;$1572,68	35loc
;Play a sound
;	arg A:	sound #
;void		playsound(uint8_t sound);
playsound:	sta		_temp		;sound #
			txa
			pha
			tya
			pha
			ldx		_temp 		;arg A
			lda		HoldSync,x
			sta		_temp		;#of chans
sndloop:	lda		HoldSync,x	
			sta		ParamBlk +1
			lda		FlushChan,x	;chan #
			sta		ParamBlk
			ldy		#2
			lda		AmplEnvel,x
			jsr		ins_param
			lda		Pitch,x
			jsr		ins_param
			lda		Duration,x
			jsr		ins_param
sound:		txa	
			pha					;save chn#
			ldx		#<ParamBlk
			ldy		#>ParamBlk
			lda		#7
			jsr		OSWORD		;SOUND(..)
sndnext:	pla
			tax					;channel #
			inx
			dec		_temp
			bpl		sndloop

sndend:		pla
			tay
			pla
			tax
			rts

;$15b6,+16	9loc
;Sign extend parameter byte + add to block
;	arg Y:	ParamBlock[index]
;	arg A:	signed data byte (-> word)	
;void		ins_param(	uint8_t	index,
;						int8_t	data);
ins_param:	sta		ParamBlk,y ;lo byte
			iny		
			asl	
			lda		#0
			bcc		inshi		;-ve parm?
			lda		#$ff
insmsb:		sta		ParamBlk,y ;hi byte
			iny					;word->blk
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
			jsr		mm_blit  ; erase old

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
			jsr		mm_blit ; paint new

rpmapnext:	ldx		_xreg		 ; 161a
			dex  ; loop over slots #0-#31
			bpl		rpmaploop 

			pla		
			sta		_max_xscr ;not needed?
			pla		
			sta		_min_xscr
			rts		

;$1626
;mm_blit
mm_blit:	lda		_destptr_h
			bne		hiblit		;onscreen?
			rts					;NULL/no
hiblit:		ldy		#0
			lda		(_destptr),y
			eor		imgDot,x	;xor blit
			sta		(_destptr),y 
hicopy:		lda		_destptr_h	;copy
			sta		_srcptr_h	;ptr
			lda		_destptr_l	;   dest
			sta		_srcptr_l	;-> src
			and		#%111		;row [0,7]
			cmp		#7	 		;last row?
			bne		lowerdot
cellbelow:	clc					;point one
			lda		_srcptr_l	;cell down
			adc		#120		;+120
			sta		_srcptr_l
			lda		_srcptr_h
			adc		#2			;+512
			bpl		lowerp		;=(+640-8)
			sec		
			sbc		#$50		;wrap vram
loptr:		sta		_srcptr_h
loblit:		iny					;ptr++
			lda		(_srcptr),y	;/down 1px
			eor		imgDot+1,x	
			sta		(_srcptr),y	;xor blit
			rts		

;$165d
mm_update:	jsr		timerstate	;wait til
			bpl		mm_update	;raster >
			cpx		#ID_MAX + 1	;#32
			bcc		mmupd2		;id > MAX?
			rts					;not unit

mmupd2:		lda		_min_xscr
			pha		
			lda		_max_xscr
			pha		
			txa
			pha					;save id
			lda		#0
			sta		_min_xscr
			lda		#80
			sta		_max_xscr
mmerase:	lda		pDot_l,x	;old dot
			sta		_destptr_l	;@vram
			lda		pDot_h,x
			sta		_destptr_h
			lda		Dot,x
			tax		
			jsr		mm_blit		;erase old

ydot:		pla		
			pha					;id
			tax		
			lda		Y_h,x
			lsr		
			lsr					;Yunit / 4
			clc		
			adc		#196		;+ Yline
			tay					;-> Ydot
xdot:		sec		
			lda		X_l,x
			sbc		_xrel_l
			lda		X_h,x
			sbc		_xrel_h		;-> Xscr/2
			jsr		xoffset110
			lsr					;+27	
			lsr		
			php		; store carry = bit 1
			clc		
			adc		#8			;+8
			tax					;=35+(X/8)	
			jsr		xy_to_vidp
			plp	
			pla					;restore
			tax					;arg X	
			php		
			lda		_destptr_l	;new dot
			sta		pDot_l,x	;@vram
			lda		_destptr_h
			sta		pDot_h,x

			lda		Unit,x
			asl		
			plp		
			bcc		aligned
			adc		#21
aligned:	sta		Dot,x
			tax		
			jsr		mm_blit

			pla		
			sta		_max_xscr
			pla		
			sta		_min_xscr
			rts		

;$16d1
key_fire:	ldx		#KEY_RETURN	;-74	
			jsr		scan_inkey
			beq		kfire2		;!keydown?
			eor		_inkey_enter
kfire2:		stx		_inkey_enter
			beq		kfire_ret	;keypress?

			ldx		#3			;[4] find
kfireloop:	lda		_Laser,x	;free beam
			beq		fire_laser	;found?
			dex					;[3,0]	
			bpl		kfireloop	;loop
kfire_ret:	rts

;$16e8
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
fireright:	txa
			clc					;R side
			adc		#7			;width+1
			tax
			lda		#$01		;shoot R 
+			pha					;1705
			txa		
			pha					;save
			tya					;coords
			pha		
			jsr		xy_to_vidp	;_destptr

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
			sta		_Laser,x	;bm taken
			lda		#0
			sta		_Tail,x
			sta		_Head,x

			lda		#4
			jmp		playsound	;laser snd
			;rts

;$172f
do_laser:	ldx		#3			;beam
beamloop:
lzright:	lda		#8			;1731
			sta		_offset_l
			lda		#0
			sta		_offset_h	;+8
			lda		_dxwin		;+dxwin
			ldy		_Laser,x
			bpl		lzedge		;left?
lzleft:		lda		#$f8		
			sta		_offset_l
			lda		#$ff
			sta		_offset_h	;-8
			sec		
			lda		#0
			sbc		_dxwin		;-dxwin
lzedge:		sta		_dxedge		;174c
			sec		
			lda		_BeamX,x	;adjust
			sbc		_dxwin
			sta		_BeamX,x

			lda		_Laser,x
			bne		+
			jmp		lasernext	;free beam

+			lda		_pHead_l,x	;175c
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
llpright:	cmp		_max_xscr
			bpl		erase_laser
			inc		_BeamX,x
			bne		llppaint
llpleft:	cmp		_min_xscr	;1779
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
			rts					;fail
lznext:		dec		_laserc		;1797
			bne		lzloop		;[~4,0]

newhead:	lda		_destptr_l
			sta		_pHead_l,x
			lda		_destptr_h
			sta		_pHead_h,x
			bne		lzscroll	;always

;$17a5
erase_laser:lda		_destptr_l
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
			lda		imgLaser,x	;2bff
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
tailloop:	ldy		_Tail,x		;17ef
			jsr		blit_laser
			sta		_Tail,x
			jsr		next_ptr
			dec		_laserc		;[1-79,0]
			bne		tailloop
newtail:	lda		_destptr_l
			sta		_pTail_l,x
			lda		_destptr_h
			sta		_pTail_h,x

lasernext:	dex					;1805	
			bmi		+
			jmp		beamloop	;1731[3,0]
+			rts					;180b

;180c
laser_hit:	lda		_destptr_l	
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

;$1834
blit_laser:	iny					;++Y
			tya		
			pha					;store arg

			lda		imgLaser,y	;pixel
			ldy		#0
			eor		(_destptr),y ;XOR
			sta		(_destptr),y ;blit

			pla		
			cmp		#80			;max?
			bne		+			;[1,79]
			lda		#79		
+			rts					;retA 1847

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

;$1860
; arg A: _BeamX,x
lz_collide:	cmp		#80			
			bcc		lzcdinit	;offscrn?
			rts
lzcdinit:	stx		_xreg		;1865 beam
			sta		_anim_xscr	;7a unused
			lda		_BeamY,x	;yscr
			sta		_beam_yscr

			ldx		#ID_MIN		;2
lzcdloop:	lda		pSprite_h,x	;186f
			beq		lzcdnext	;0ptr?
			lda		Y_h,x		;unit Y
			sec		
			sbc		_beam_yscr	;Y displc
			cmp		#8
			bcs		lzcdnext	;within?

			lda		pSprite_l,x
			and		#%11111000	;cell
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
			ror		_offset_l	;/ 8
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
			cmp		#MAN		;6
			bne		hitfound
hithuman:	lda		Param,x
			cmp		#$80
			beq		lzcdnext	;fake man?
hitfound:	lda		#3			;18d1
			jsr		playsound
			jsr		score_unit
			jsr		kill_unit	;zzzzz
			ldx		_xreg
			clc					;success
			rts

lzcdnext:	inx					;18e0
			cpx		#32			;[2,31]
			bne		lzcdloop	;186f
			ldx		_xreg
			sec					;fail
			rts

;$18e9
kill_unit:	lda		Unit,x		
			and		#%01111111	;sprite #
			cmp		#KUGEL		;KUGEL/Sx?
			bcs		erase_unit	;rts
			cmp		#BAITER		;#3
			beq		kill_u2		;rts

			pha		
			jsr		kill_u2		;1910
			pla		
			bcs		killu_ret

			cmp		#MAN		;#6
			beq		+
			dec		_enemyc		;enemyc--
killu_ret:	rts					;1903

+			lda		#10			;man 1904
			jsr		playsound

			dec		_humanc
			bne		killu_ret
			jmp		rm_surface
			;rts	
kill_u2:	lda		Unit,x		;1910
			pha		
			jsr		erase_unit
			pla		
			bcs		killu_ret
			sta		Unit,x

			lda		#BLAST		;ff
			sta		Anim,x
			lda		#8
			sta		Param,x
			rts		

;$1928
erase_unit:	txa				  
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
			lda		#NULL		;make 0ptr
			sta		pDot_h,x
			lda		Dot,x
			tax					;[0,43]
			jsr		mm_blit		;erase dot

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
			jsr		xblt_sprite	;erase

nosprite:	pla					;1967
			tax		
			jsr		clear_data	;An,P,ptrs
			lda		Unit,x
			and		#%01111111
			cmp		#POD
			bne		erasesucc	;swarmers?
swarmcloud:	lda		X_h,x		;2e2a 1975
			sta		XMinInit + SWARMER
			lda		Y_h,x
			sec		
			sbc		#8			;2e3a
			sta		YMinInit + SWARMER
			jsr		random
			and		#%111		;spawn x#
			clc					;[5,12]
			adc		#5
			sta		Spawnc + SWARMER
			txa					;save pod#
			pha					;85
			lda		#(SWARMER|$80) 
			jsr		mspawn		;spw cloud
			pla					;pod id
			tax		

erasesucc:	lda		#EMPTY		;1998 ff
			sta		Unit,x		;clr slot
			clc		
			rts					;success
erasefail:	pla					;199f
			tax		
			sec		
			rts					;failed

;$19a3
mspawn:		sta		_spawn_spr	
			and		#%01111111	;sprite #
			tay		
			lda		Spawnc,y	;2e1d
			beq		mspw_ret	;none?
			sta		_count		;#to spawn
			cpy		#LANDER
			bne		mspwinit
			lda		_humanc		;no
			bne		mspwinit	;planet?
			ldy		#MUTANT		;all muts

mspwinit:	jsr		mspw_frame	;19b9
			ldx		#ID_MIN	 	;start sl
mspwloop:	lda		Unit,x		;19be
			asl
			bpl		mspwnext	;!b6?(!ff)
			tya					;free slot
			ora		#UPDATE		;set hibit
			sta		Unit,x
			jsr		init_unit	;create u

			cpy		#BAITER		;not in
			beq		+			
			cpy		#MAN		;enemyc
			beq		+
			inc		_enemyc		;curr #
+			dec		_count		;19d7
			beq		mspw_ret	;all done
;19db
mspwnext:	txa					;find next
			clc					;slot 
			adc		#5			;#2,#7..
			tax		
			cpx		#ID_MAX + 1	;#32	
			bcc		mspwloop
			sec		
			sbc		#29			;->#3,8..
			tax		
			cpx		#7			;#4,5,6.31
			bne		mspwloop

			bit		_spawn_spr	;no slots
			bpl		mspwinit	;tryagain?
mspw_ret:	rts					;19f0

;$19f1,+22	15loc
;Do one frame, before attempt to spawn
;	arg:	(_spawn_spr & $80) -> skip
;	saved:	Y, _spawn_spr, _count, 
;void		mspw_frame(bool skip);
mspw_frame:	lda		_spawn_spr	
			bmi		noframe		;hi bit?
			pha					;save vars
			lda		_count
			pha		
			tya		
			pha		
			jsr		frame		;x1
			pla		
			tay		
			pla		
			sta		_count
			pla		
			sta		_spawn_spr
noframe:	rts

;$1a07,+29	13loc
;Spawn a baiter, at (_baitdelay) intervals
;extern	uint16_t	baitdelay;
;void		spawn_bait(void);
spawn_bait:	dec		_baitdelay_l ;spawn
			bne		bait_ret	;interval
			dec		_baitdelay_h ;--count
			bne		bait_ret	;passed?

bait2:		lda		#1			;yes
			sta		Spawnc + BAITER
			lda		X_h + SHIP	;Xship ->
			sta		XMinInit + BAITER ;Xb
			lda		#($80|BAITER)  
			jsr		mspawn		;-> spawn

bait3:		lda		#2			;i.val=512
			sta		_baitdelay_h ;frames
bait_ret:	rts

;$1a24
init_unit:	lda		Unit,x		
			asl
			php		
			lsr					;sprite #
			tay		
			jsr		clear_data	;ret A = 0
			sta		pDot_h,x	;NULL
			plp		
			bpl		+			;free sl?
			rts
; slot taken, Y = sprite #  1a35
+			lda		DoWarp,y
			beq		+			;warp in?
			lda		#WARP		;1
			sta		Anim,x		;over
			lda		#8			;8 frames
			sta		Param,x

+			jsr		random		;1a44
			and		XRangeInit,y
			clc		
			adc		XMinInit,y
			sta		X_h,x

			jsr		random
			and		YRangeInit,y
			clc		
			adc		YMinInit,y
			cmp		#192
			bcc		+			; > Ytop?
			sbc		#192
+			sta		Y_h,x		;1a61

;$1a64
init_dxy:	jsr		random		
			and		dXRangeInit,y
			clc		
			adc		dXMinInit,y
			jsr		to_velocity	;ret A
			sta		dX_l,x		;-> temp_l
			lda		_temp_h
			sta		dX_h,x

			jsr		random
			and		dYRangeInit,y
			clc		
			adc		dYMinInit,y
			jsr		to_velocity
			sta		dY_l,x
			lda		_temp_h
			sta		dY_h,x
			rts		

;$1a8f
to_velocity:sta		_temp_l		
			lda		#0
			sta		_temp_h

			jsr		random
			bpl		+
			sec		
			lda		#0
			sbc		_temp_l		;negate
			sta		_temp_l		;val
			bcs		+			;+ve?
			dec		_temp_h		;-> ff
+			lda		_temp_l		;1aa5
			asl
			rol		_temp_h
			asl	
			rol		_temp_h		;* 8
			asl
			rol		_temp_h
			rts		

;$1ab1
mspawn_all:	ldx		#LANDER		;#1
-			txa					;1ab3
			pha		
			jsr		mspawn

			pla		
			tax		
			inx		
			cpx		#POD + 1	;8
			bne		-
			rts		

;$1ac0
smartbomb:	lda		_bombs
			bne		+			
			rts					;no bombs?
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
			jsr		detonate
			lda		#TRUE		;runs into
			;jsr	detonate
			;rts

;$1adc
;void		detonate(bool pass2);
detonate:	sta		_bomb_pass2
			lda		#(PAL_BG|WHITE)
			sta		_bgpal		;07
			ldx		#2
			jsr		do_nframes	;flash W
			jsr		bombscreen	;2 passes
			lda		#(PAL_BG|BLACK)
			sta		_bgpal		;00
			ldx		#2
			jsr		do_nframes	;back to B
			rts

bombscreen:	ldx		#ID_MIN		;1af4
bombloop:	lda		Unit,x		;1af6
			asl					;ff/
			bmi		bombnext	;freeslot?

			lsr					;sprite #
			cmp		#MAN		;humans
			beq		bombnext	;spared!
			lda		Anim,x		;drawn?
			bne		bombnext
			lda		pSprite_h,x	;onscreen?
			bne		blowup		;BOOM!
;0ptr -> unit offscreen
;EXCEPT new swarmers @pass2
			lda		_bomb_pass2
			beq		bombnext	;2nd pass?
			lda		Unit,x
			and		#%01111111	;sprite
			cmp		#SWARMER	;#5
			bne		bombnext	;swarmer?

			jsr		get_xscr
			cmp		#80
			bcs		bombnext	;offscrn?
			lda		X_h,x
			eor		#%10000000
			sta		X_h,x
			bne		bombnext	;always

blowup:		jsr		score_unit	;1b29
			jsr		kill_unit
bombnext:	inx					;1b2f
			cpx		#32
			bne		bombloop	;[2,31]
			rts		

;$1b35,+57	26loc
;void		keys_hyper(void);
keys_hyper:	ldx		#6			;traverse
khyploop:	stx		_xreg		;table
			lda		HyperKeys,x	;[7]
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
hypvars:	stx		Anim + SHIP
			lda		#8
			sta		Param + SHIP
			rts		

;$1b6e
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
flashbg:	lda		FlashPal,y
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

;$1b9a
shootchance:sta		_temp		;-> chance
			lda		_dead
			beq		+			;alive?	
			rts					;no

+			jsr		random		;1ba1
			cmp		_temp		;shoot? 
			bcs		shtch_ret
			sec					;horz disp
			lda		X_h + SHIP
			sbc		X_h,x		;un firing
			bpl		+			;absolute
			sta		_temp
			sec		
			lda		#0
			sbc		_temp		;negate A
+			cmp		#40			;1bb8
			bcs		shtch_ret	;too far?

			jsr		shoot		;1c84	
			bcc		+			;shoot ok?
shtch_ret:	rts					;1bc1
;actually shoot
+			lda		#8			;1bc2
			jsr		playsound

;$1bc7
target_ship:sec
			lda		X_h + SHIP
			sbc		X_h,x
			jsr		dist_div64	;ret _t_h
			sta		_srcptr_h
			clc		
			lda		_temp_l
			sta		_srcptr_l	;absolute
			adc		dX_l + SHIP
			sta		dX_l,y		;rel 2ship
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
			lda		dX_l,y		;+dx
++			cmp		_shootspeed	;1c22
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

;$1c4c
;!! no refs??
			lda		#8
			jmp		playsound
			;rts

;$1c51
minechance:	lda		pNext_h,x
			beq		mine_ret	;onscreen?
			jsr		random
			cmp		#60			;25%
			bcs		mine_ret	;chance?
plantmine:	jsr		spawn_misc	;lay mine
			bcs		mine_ret	;success?
			lda		#0			
			sta		dY_l,y		;still
			sta		dY_h,y
			sta		dX_l,y
			sta		dX_h,y
mine_ret:	rts

;$1c71
dist_div64:	sta		_temp_l		;/ 256
			php					;save N	
			lda		#0
			plp		
			bpl		distdiv2	;-ve?
			lda		#$ff 		;sign xtnd
distdiv2:	asl		_temp_l
			rol		
			asl		_temp_l
			rol					;* 4
			sta		_temp_h
			rts		

;$1c84
shoot:		ldy		#ID_BULLET1	;#32
			bne		shootloop	;always
;$1c88
spawn_misc:	ldy		#ID_ALT1	;#34	
shootloop:	jsr		shoot_id
			bcc		shoot_ret	;found?
			iny					;next slot
			cpy		#ID_ALT3 + 1
			bne		shootloop	;[x,36]
shoot_ret:	rts

;$1c95
;Spawn bullet/mine
shoot_id:	lda		Unit,y
			eor		#%11000000
			asl		
			asl					;b6/!ff?
			bcs		shtid_ret	;taken?
			lda		#(UPDATE|KUGEL)
			sta		Unit,y		;spawn 88
kugelx:		lda		X_l,x
			sta		X_l,y
			clc		
			lda		X_h,x		;4px right
			adc		#1			;of unit
			sta		X_h,y		;->@middle
kugely:		lda		Y_l,x
			sta		Y_l,y
			sec		
			lda		Y_h,x	
			sbc		#4			;4px below
			sta		Y_h,y		;u -> @mid
kugelvars:	lda		#0
			sta		Param,y
			sta		Anim,y
			clc					;=success
shtid_ret:	rts					;ret C

;$1ccb,+27	12loc
;Scan for TAB and H, frame_nochk(), then
;check alive -> do_death()
;	called:	game(), spawn_squad(),
;			mspw_frame()
;runs into:	do_death()
;void		frame(void);
frame:
key_tab:	ldx		#KEY_TAB	;(-97)
			jsr		scan_inkey
			beq		tab0		;TAB down?
			eor		_inkey_tab	;(!tab)
tab0:		stx		_inkey_tab	;-> Z
			beq		frame2		;_press_?
			jsr		smartbomb	;-> bomb

frame2:		jsr		keys_hyper	;hyperspc
			jsr		frame_nochk	;one frame
			lda		_dead
			bne		do_death	;dead?
			rts					;no	

;$1ce6,+203	93loc
;Flash bg, ship explodes into shrapnel
;Player has died - done/continue/game over
;void		do_death(void);
do_death:	lda		#(PAL_BG|WHITE)
			sta		_bgpal		;07
			jsr		frame_all	;flash W
			lda		#(PAL_BG|BLACK)
			sta		_bgpal		;00
			ldx		#50			;flash shp
			jsr		do_nframes	;red/white
death2:		ldx		#FALSE		;prevent
			stx		_dead		;re-entry
			;ldx	#SHIP
			jsr		erase_unit  ;erase shp
			lda		#12
			jsr		playsound
;set up shrapnel (all 30 unit slots)
			ldx		#ID_MAX		;id #31
shrapsetup:	jsr		clear_sptrs
			lda		Unit,x
			sta		Param,x		;backup
			lda		Anim,x		;Unit,Anim
			sta		pDot_l,x
sprite0:	lda		#(UPDATE|U_SHIP) ;$80
			sta		Unit,x		;all slots
			lda		#0
			sta		Anim,x
;			lda		#NULL
			sta		pDot_h,x	;not @MM
shrapx:		lda		X_h + SHIP	;+2
			clc		
			adc		#2			;= Xship
			sta		X_h,x		;  @centre
			lda		X_l + SHIP
			sta		X_l,x
shrapy:		lda		Y_h + SHIP	
			sta		Y_h,x		;= Yship
			lda		Y_l + SHIP
			sta		Y_l,x
shrapdxy:	ldy		#U_SHIP		;random
			jsr		init_dxy	;dX,dY
			dex					;loop all
			bpl		shrapsetup	;id#[31,0]
; explode into shrapnel
shrapspr:	lda		#<imgShrapnel
			sta		SpriteV_l + U_SHIP
			lda		#>imgShrapnel
			sta		SpriteV_h + U_SHIP
			lda		#4			;[4]
			sta		SpriteLen + U_SHIP
batchall:	lda		_batch		;save
			pha					;batchsize
			lda		#30			;process
			sta		_batch		;all slots
			ldx		#60			;60 frames
shrapnel:	txa					;save
			pha					;frame ctr
			jsr		ai_batch	;30x slots
			jsr		next_frame	;waitVsync
			jsr		repaint_all	;    blits
			pla
			tax					;-> framec
			cpx		#18			;frame
			bne		shrapnext	;#42?
shrapred:	lda		#(PALX_METAL|RED) ;f1
			jsr		set_palette	;red shrap
shrapnext:	dex					;nxt frame
			bne		shrapnel	;[60,1]

			ldx		#ID_MAX		;id #31
unbackup:	lda		Param,x		;restore
			sta		Unit,x		;-> Unit
			lda		pDot_l,x	;@backup
			sta		Anim,x		;-> Anim
			dex					;loop all
			bpl		unbackup	;ids[31,0]
;_lives--, branch according to game state
death3:		pla					;-> normal
			sta		_batch		;batchsize
			ldx		#100		;wait 100
			jsr		delay		; frames
			sed					;bcd_t
			sec		
			lda		_lives
			sbc		#1			;lose life
			sta		_lives
			cld		
death4:		lda		_is_spawning	
			ora		_enemyc		;level
			beq		tonextlvl	;complete?
			lda		_lives
			bne		continue	;continue?
togameover:	ldx		_gameover_sp ;no lives
			txs					;game over
			rts					;-> main()
tonextlvl:	ldx		_nextlvl_sp
			txs					;planetoid
			rts					;-> ()	
continue:	jsr		cont_level	;same lvl
			ldx		#50			;wait 50
			jsr		delay		;frames
			rts					;-> game()

;$1db1,+52	23loc
;Main game routine, returns level complete
;	called:	planetoid()
;void		game(void);
game:		tsx					;save SP
			stx		_nextlvl_sp	;->longjmp
			lda		#TRUE
			sta		_is_spawning
gamemen:	lda		#MAN
			jsr		mspawn		;spawn men
			lda		#0			;(persist)
			sta		Spawnc + MAN
			ldx		#20			;wait 20
			jsr		do_nframes	;frames
gamesquads:	jsr		mspawn_all	;squad #1
			jsr		spawn_squad	;      #2
			jsr		spawn_squad	;      #3
			lda		_level
			cmp		#6
			bcc		spawned		;level 6+?
			jsr		spawn_squad	;->[sq #4]
spawned:	lda		#FALSE		;all
			sta		_is_spawning ;spawned

gameframe:	jsr		frame		;do frame;
			lda		_enemyc		;while
			bne		gameframe	;(enemyc);
			rts					; -> done

;$1de5,+38	17loc
;Either every $200 frames or enemies are
;all dead, spawn a squad (5 landers)
;void		spawn_squad(uint8_t delay);
spawn_squad:lda		#0
			sta		_framec_l	;reset
			sta		_framec_h	;frame ctr

squadloop:	jsr		frame		;one frame
			lda		_enemyc		;enemies
			beq		newsquad	;all dead?
			lda		_humanc		;or
			beq		newsquad	;no men?
squadwait:	inc		_framec_l
			bne		squadnext	;count++
			inc		_framec_h
squadnext:	lda		_framec_h
			cmp		_squaddelay	;$200 frs?
			bne		squadloop	;delay

newsquad:	lda		#LANDER		;#1
			jsr		mspawn		;spawn x5
			rts		

;$1e08,+12	8loc
;Hide planet surface, by making it black
;	X:		preserved
;void		rm_surface(void);
rm_surface:	txa					;save X
			pha
			lda		#(PAL_SURF|BLACK)
			sta		_surfpal	;60
			jsr		set_palette	;no surf
			pla		
			tax					;restore X
			rts		

;$1e14,+9	5loc
;Scan keyboard, return if (-ve INKEY) down
;	arg X: 	keycode (-ve) 
;	ret A,Z:-1 if down, 0 not
;int		scan_inkey(int8_t keycode);
scan_inkey:	ldy		#$ff		;scan keyb
			lda		#$81		;INKEY
			jsr		OSBYTE		;key down?
			txa					;-> 00/ff
			rts					;-> Z

;$1e1d,+20	9loc
;Get chars until spacebar pressed
;void		wait_spaceb(void);
wait_spaceb:lda		#$0f
			ldx		#1			;input buf
			jsr		OSBYTE		;flush it
spcloop:	lda		#$7e		;clear ESC
			jsr		OSBYTE		;(+keybuf)
			jsr		OSRDCH		;getchar()
			cmp		#' '		;space?
			bne		spcloop		;loop til
			rts					;pressed

;$1e31,+77	48loc
;Calculate screen ram ptr for coords (X,Y)
;	arg XY:	screen X coord, screen Y coord
;	ret:	(succ) destptr	-> @screen ram
;			(fail)			-> null ptr
;void	   *xy_to_vidp(	uint8_t	 xscr,
;						uint8_t	 yscr);	
xy_to_vidp:	lda		#NULL		;ret 0ptr
			sta		_destptr_h	;on fail
			cpx		_min_xscr
			bcc		xytop_ret	;Xscr
			cpx		_max_xscr	;offscrn?
			bcs		xytop_ret
yscrin:		tya					;Yscr
			eor		#$ff		;~
			pha					;b0-2 cell
			lsr		
			lsr		
			lsr		
			tay		
			lsr					;bit 3
			sta		_temp
			lda		#0
			ror
			adc		_originp_l	;C clear
			php					;save C	
			sta		_destptr_l
setcell:	tya					;~Yscr >>3
			asl		
			adc		_temp		;b4-7
			plp					;carry
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
xytop_ret:	rts					;destptr

;$1e7e,+121	44loc
;XOR blit a sprite on to video RAM
;	called:	xblt_sprite()
;	X preserved
;	ret:	(_paintmask & %11000000)
;uint8_t	xorblit(void	*srcptr,
;					void	*destptr,
;					size_t	imglen,
;					uint8_t	heightmask);
xor_blit:	lda		_destptr_h
			bne		xblt1		;NULL ptr?
			rts					;no dest
xblt1:		lda		#0
			sta		_paintmask	;collision
			lda		_imglen
			pha		
			ldy		#0
xorpinit:	lda		_destptr_h	;save orig
			pha		
			lda		_destptr_l
			pha		
destcell:	lda		_destptr_l
			and		#%00000111	;cell row
			sta		_dest_row
			lda		_destptr_l
			and		#%11111000	;cell addr
			sta		_destptr_l

xorploop:	lda		(_srcptr),y
			php					;save Z	
			iny		
			sty		_temp  		;src row
bitblt:		ldy		_dest_row
			eor		(_destptr),y ;XOR
			sta		(_destptr),y ;blit
			iny					;detect
orcollide:	plp					;collision
			beq		xblt2		;src px
			ora		_paintmask	;nonzero?
			sta		_paintmask	;|= hibit
xblt2:		cpy		#8
			beq		cellbelow	;last row?
xorpnext:	sty		_dest_row
			ldy		_temp		;src row
			tya		
			and		_heightmask	;next
			beq		cellright	;column?
			dec		_imglen		;len--
			bne		xorploop	;loop
xblt_ret:	pla					;original
			pla					;destptr,
			pla					;imglen
			sta		_imglen
			rts		

cellbelow:	ldy		#0
			clc		
			lda		_destptr_l
			adc		#$80		;destptr
			sta		_destptr_l	;+= 640
			lda		_destptr_h
			adc		#2
			bpl		xblt3	
			sec		
			sbc		#$50		;wrap vram
xblt3:		sta		_destptr_h
			bne		xorpnext	;continue

cellright:	clc					;(Y = 0)
			pla					;-> dest_l
			adc		#8  		;next cell
			sta		_destptr_l	;+= 8
			pla					;-> dest_h
			adc		#0			;R of curr
			bpl		xblt4		;cell
			sec		
			sbc		#$50  		;wrap vram
xblt4:		sta		_destptr_h
			dec		_imglen		;len--
			bne		xorpinit	;re-push..
xblt_ret2:	pla		
			sta		_imglen
			rts		

;$1ef7,+27	14loc
;Write new video RAM origin to 6845 R12/13
;	arg:	_originp
;void		screenstart(void *originp);
screenstart:lda		_originp_l	;new
			sta		_temp		;screen
			lda		_originp_h	;origin
			lsr		
			ror		_temp
			lsr	
			ror		_temp		; / 8
			lsr		
			ror		_temp
originout:	ldx		#12			;reg 12,13
			jsr		out6845		;screen
			ldx		#13			;start
			lda		_temp		;addr >> 3
			jmp		out6845
			;rts

;$1f12,+95	44loc
;New vram origin, @vsync start timer,
; next PAL_FLASH/PAL_ROTx colours
;void		next_frame(void);
next_frame:	jsr		screenstart
			jsr		wait_vsync	;middle of
			ldy		#$14  		;count hi
			ldx		#$80  	 	;      lo
			jsr		start_timer ;5248 cyc

palette1:	lda		_bgpal		;PAL_BG
			jsr		set_palette	;BLACK
			lda		_humanc
			bne		palette2 	;no men?
nosurf:		lda		_bgpal		;BLACK
			ora		#PAL_SURF	;$60
			jsr		set_palette
palette2:	dec		_flpalc		;every 6th
			bne		palette3	;frame?
flashpal:	lda		_flpalframes ;= 6
			sta		_flpalc		;-> [5,0]
			inc		_flashc		
			lda		_flashc		;loop over
			and		#%111		;[0,7] 
			sta		_flashc
			tax		
			lda		FlashPal,x
			jsr		set_palette ;PAL_FLASH

palette3:	inc		_rotpalc	;every
			lda		_rotpalc	;4th frame
			and		#%11 		;(% 4)
			bne		nxfrm_ret
rotatepal:	ldx		rotatec		;[3] index
			lda		#PAL_ROT1	;$10
rotloop:	sta		_temp		
			stx		rotatec
			lda		RotColour,x
			ora		_temp		;PAL_ROTx
			jsr		set_palette
rotnext:	inx					;colour
			cpx		#3			;[0,2]
			bne		palnext		;wrap?
			ldx		#0
palnext:	lda		_temp
			clc					
			adc		#$10
			cmp		#$40 		;rotate
			bne		rotloop		;3x PAL_
nxfrm_ret:	rts

;$1f71,+22	13loc
;Blit planet surface, left to right
;also psurf_left()
;	arg A:	dxwin (+ve)
;	arg X:	LEFT/RIGHT (0/1)
;	arg Y:	Xscr @starting point
;	ret A:	dxwin preserved
;#define	LEFT	0
;#define 	RIGHT	1
;int8_t		psurf_right(int8_t	dxwin,
;						int		direction,
;						uint8_t	xscr);
psurf_right:pha					;dXwin
			sta		_dxwinc		;(-ve)
			sty		_xscrc		;start pt
			ldy		_xwinedge,x	;xwinL/R
rsurfloop:	jsr		xblt_surf
			inc		_xscrc		;Xscr++
			iny					;Xwin++
			dec		_dxwinc		;while
			bne		rsurfloop	;(--dXwin)

rsurf_ret:	tya
			sta		_xwinedge,x	;endpoint
			pla					;-> orig
			rts					;   dXwin

;$1f87,+22	13loc
;Blit planet surface, right to left
;also psurf_right()
;	arg A:	dxwin (-ve)
;	arg X:	LEFT/RIGHT (0/1)
;	arg Y:	Xscr @starting point
;	ret A:	dxwin preserved
;#define	LEFT	0
;#define 	RIGHT	1
;int8_t		psurf_left(int8_t	dxwin,
;						int		direction,
;						uint8_t	xscr);
psurf_left:	pha					;dXwin
			sta		_dxwinc		;(-ve)
			sty		_xscrc		;start pt
			ldy		_xwinedge,x ;XwinL/R
lsurfloop:	dec		_xscrc		;Xscr--
			dey					;Xwin--	
			jsr		xblt_surf
			inc		_dxwinc		;while
			bne		lsurfloop	;(++dXwin)

lsurf_ret:	tya		
			sta		_xwinedge,x	;endpoint
			pla					;-> orig
			rts					;   dXwin

;$1f9d,+83	46loc
;XOR blit a planet surface tile (2x4 px),
; and 2px of blue dividing line
;	called:	psurf_left(), psurf_right()
;	X,Y preserved
;	arg Y:	tile _xwinleft/_xwinright
;	arg:	_xscrc -> tile Xscr
;void		xblt_surf(	uint8_t	xwin,
;						uint8_t	xscr);
xblt_surf:	stx		_xreg		;LEFT/RIGH
			sty		_yreg		;Xwin[x]
			tya		
			and		#%11		;mod 4
			tax					;-> [0,3]
getquad:	tya		
			lsr					;Xwin
			lsr					;/ 4
			tay					;-> [0,63]
			lda		SurfQuad,y  ;[64]
unpakq:		dex					;[4]
			bmi		gettile
			lsr
			lsr
			bne		unpakq		;unpack

gettile:	and		#%11		;dw/flt/up
			asl					;4 byte
			asl					;tiles
			adc		#<imgSurface ;+tile#
			sta		_srcptr_l
			lda		#>imgSurface ;[3][4]
			sta		_srcptr_h
tilexy:		ldx		_xscrc  	;arg Xscr
			ldy		_yreg 		;Xwin[lr]
			lda		SurfaceY,y
			tay					;-> Yscr
			jsr		xy_to_vidp	;tile vidp
tileblt:	lda		#4			;height
			sta		_imglen		;=4px
			lda		#7			;{1x4}
			sta		_heightmask
			jsr		xor_blit	;blit

linexy:		ldx		_xscrc
			ldy		#196		;top of
			jsr		xy_to_vidp	;playfield
lineblt:	ldy		#0			;blue line
			lda		#$f0		;PALX_EN.B
			eor		(_destptr),y ;XOR
			sta		(_destptr),y ;blit
			iny					;1px below
			lda		#$f0		;blue|blue
			eor		(_destptr),y
			sta		(_destptr),y ;blit
xbsur_ret:	ldx		_xreg		;restore
			ldy		_yreg
			rts		

;$1ff0
ship_all:	lda		Anim + SHIP	;in
			beq		nohyper		;hyperspc?
			jmp		scroll_scrn	;yes,done
			;rts
nohyper:	lda		_dead
			beq		to_pausquit	;alive?
			;pause_quit() .. below
flashship:	lda		_shippal	;dead ->
			eor		#$80 	 	;$7x|$fx
			sta		_shippal	;every 2nd
			bmi		flashframe	;frame?
			eor		#%110 		;red/white
			sta		_shippal	;$71/$77
			jsr		set_palette	;flash sp
flashframe:	lda		#0			;stop ship
			sta		dX_l + SHIP
			sta		dX_h + SHIP	
			jmp		updateship
			;scroll_scrn()
			;move_ship(SHIP)
			;mm_update(SHIP)
			;rts
to_pausquit:jmp		pause_quit
			;key_fire()
			;keys_nav()
			;scroll_scrn()
			;move_ship()
			;mm_update()
			;rts

;$2019
keys_nav:
key_up:		ldx		#KEY_A		;(-66)
			jsr		scan_inkey
			beq		key_down	;!pressed?
shipup:		clc		
			lda		Y_h + SHIP	;+2px
			adc		#2
			cmp		#195		;ship
			bcs		key_down	;@top?
			sta		Y_h + SHIP	;move up

key_down:	ldx		#KEY_Z		;(-98)
			jsr		scan_inkey
			beq		key_reverse	;!pressed?
shipdown:	sec
			lda		Y_h + SHIP
			sbc		#2			;-2px
			cmp		#9			;ship
			bcc		key_reverse	;@bottom?
			sta		Y_h + SHIP	;move down
		
key_reverse:ldx		#KEY_SPACE	;(-99)
			jsr		scan_inkey
			beq		space0		;key down?
			eor		_inkey_space ;(!space)
space0:		stx		_inkey_space ;-> Z
			beq		key_thrust	;_press_?
ship180:	lda		pSprite_l + SHIP
			sta		_destptr_l
			lda		pSprite_h + SHIP ;ship
			sta		_destptr_h	;ptr @vram
			ldx		#U_SHIP		;erase
			jsr		xblt_sprite	;ship
spritelr:	lda		SpriteV_l + U_SHIP ;lr
			eor		#%0011 0000 ;fc0|ff0
			sta		SpriteV_l + U_SHIP
			lda		#NULL		;no sprite
			sta		pSprite_h + SHIP
changedir:	sec		
			lda		#0
			sbc		_ddx_l		;negate
			sta		_ddx_l		;accel
			lda		#0			;vector
			sbc		_ddx_h		;-> change
			sta		_ddx_h		;direction

key_thrust:	ldx		#KEY_SHIFT	;-1
			jsr		scan_inkey
			beq		shipdrag	;key down?
thrust:		clc					;velc
			lda		dX_l + SHIP	;+= accel
			adc		_ddx_l	  	;(+- $700)
			sta		dX_l + SHIP
			lda		dX_h + SHIP
			adc		_ddx_h	  
			sta		dX_h + SHIP
; compute ship velocity etc.
shipdrag:	lda		dX_h + SHIP
			ora		dX_l + SHIP
			beq		dragdone	;velc 0?
			lda		dX_h + SHIP ;sp moving
			bpl		rdrag		;+ve velc?
ldrag:		clc					;(going L)
			lda		dX_l + SHIP
			adc		#3			;decel.ate
			sta		dX_l + SHIP	;until
			lda		dX_h + SHIP	;stopped
			adc		#0
			sta		dX_h + SHIP
			bcs		stopship	;cross 0?

			lda		dX_h + SHIP
			cmp		#$ff		;velocity 
			bpl		dragdone	;< -$ff?
			lda		#$ff
			sta		dX_h + SHIP
			lda		#0			;max velc
			sta		dX_l + SHIP
			beq		dragdone	;always

rdrag:		sec					;(going R)
			lda		dX_l + SHIP
			sbc		#3
			sta		dX_l + SHIP
			lda		dX_h + SHIP
			sbc		#0
			sta		dX_h + SHIP
			bcc		stopship	;cross 0?

			lda		dX_h + SHIP
			cmp		#1			;velocity
			bmi		dragdone	;>$ff?
			lda		#0			;max velc
			sta		dX_l + SHIP
			beq		dragdone	;always

stopship:	lda		#0			;zero dx
			sta		dX_l + SHIP
			sta		dX_h + SHIP
dragdone:	ldx		#SHIP		;current
			jsr		get_xscr	;ship Xscr
			tax		
			ldy		#15			;facing R
			lda		_ddx_h
			bpl		xscrnew		;facing L?
			ldy		#59			;target

xscrnew:	sty		_temp		;ship Xscr
			lda		#0			;lo rel
			ldy		#0			;hi move 
			cpx		_temp		
			beq		dxrel		;Xpos ok?
			lda		#$80		;-> win R
			;ldy	#0
			bcs		dxrel
			lda		#$80		;-> win L
			ldy		#$ff

dxrel:		clc					;compute
			adc		dX_l + SHIP	;relative
			sta		_dxrel_l	;velocity
			tya					;+scrollng
			adc		dX_h + SHIP
			sta		_dxrel_h
			clc					;move
			lda		_dxrel_l	;scrn edge
			adc		_xrel_l
			sta		_xrel_l
			lda		_dxrel_h
			adc		_xrel_h
			sta		_xrel_h

updateship:	jsr		scroll_scrn
			ldx		#SHIP
			jsr		move_xunit	;dX only
			ldx		#SHIP
			jsr		mm_update	;dot
			rts		

;$2132,+48	21loc
;Update/erase hitch hiker(s)
;	arg:	_hikerc = # of hikers
;void		hitchhiker(uint8_t hikerc);
hitchhiker:	lda		_hikerc
			beq		hherase		;no hikers

			lda		#MAN		;hiker/s
			sta		Unit + HITCH
hhx:		lda		X_l + SHIP
			clc	
;			adc		#0			;unneeded
			sta		X_l + HITCH	;ship left
			lda		#1			;+ 4px	
			adc		X_h + SHIP	
			sta		X_h + HITCH	;Xpos
hhy:		lda		Y_h + SHIP
			sec		
			sbc		#10			;below shp
			sta		Y_h + HITCH	;Ypos
hhupdate:	ldx		#HITCH		;id #1
			jsr		next_vidp	;-> BLIT
			jmp		mm_update	;dot	
			;rts
hherase:	ldx		#HITCH		;id #1
			jmp		erase_unit
			;rts

;$2162,+117	
move_unit:	lda		Unit,x
			and		#%01110111	;(sprite #
			tay					; mod 8)
ynext:		clc		
			lda		dY_l,x
			adc		Y_l,x		;Y = Y' + 
			sta		Y_l,x		;dY
			lda		dY_h,x
			adc		Y_h,x		;Ynew
ytop:		cmp		#195		;Ytop
			bcc		ybottom		;on field?
			cpy		#(U_SHIP&KUGEL) ;off
ymaxproj:	beq		offscreen	;prjctile?
ymaxunit:	lda		#9			;unit,wrap
ybottom:	cmp		#9			;Ybottom
			bcs		ymove		;on field?
			cpy		#(U_SHIP&KUGEL) ;off
			bne		yminunit	;unit?
yminproj:	cmp		#4			;proj 4px
			bcs		ymove		;> bottom?
			bcc		offscreen	;off
yminunit:	cpy		#MAN
			php					;Z	
			lda		#194		;-> wrap
			plp
			bne		ymove		;human?
			lda		#9			;->no wrap
movey:		sta		Y_h,x		;=Ynext

			clc		
;$219d
move_xunit:	lda		dX_l,x
			adc		X_l,x
			sta		X_l,x
			lda		dX_h,x
			adc		X_h,x
			sta		X_h,x
;$21b0
next_vidp:	ldy		Y_h,x		;Yunit
			txa		
			pha					;save id
			jsr		get_xscr
			tax					;Xscr
			jsr		xy_to_vidp	;->destptr
			pla					
			tax					;unit id
setnextp:	lda		_destptr_l
			sta		pNext_l,x
			lda		_destptr_h	;update
			sta		pNext_h,x	;nextvidp
			lda		Unit,x		;u state
			and		#%01111111	;-> BLIT
			sta		Unit,x
			rts					;done

offscreen:	lda		#NULL		;dont draw
			sta		_destptr_h	;null ptr
			beq		setnextp	;always

;$21d7,+30	16loc
;Computes a unit's Xscr (screen X pos.n)
;	arg X:	unit id
;int8_t		get_xscr(id_t unit);
get_xscr:	sec	
			lda		X_l,x		;Xunit
			sbc		_xrel_l		;Xleftedge
			sta		_offset_l
			lda		X_h,x	; *
			sbc		_xrel_h
			sta		_offset_h
toxscr:		asl		_offset_l	;-> Xscr
			rol		
			sta		_temp
			eor		_offset_h
			bmi		offscreen
			lda		_temp
			rts					;ret A
offscreen:	lda		#$80
			rts	

;$21f5
repaint_all:ldx		#SHIP		;#0
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
			cpx		#SHIP 		;un still?
			bne		rpanext	 	;norepaint
rpaerase:	lda		pSprite_l,x	;221c
			sta		_destptr_l
			lda		pSprite_h,x
			sta		_destptr_h
			lda		Unit,x
			and		#%01111111
			tax					;sprite #
			jsr		xblt_sprite	;erase old

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
			jsr		xor_blit
rpanext:	pla					;2246
			tax					;id #
			inx		
			cpx		#ID_ALT3 + 1
			bne		rpaloop		;21f7
			rts		

;$224e,+32	14loc
;XOR blit a given sprite onto video RAM
;If ship, also return collision mask
;	arg X:	sprite #
;uint8_t	xblt_sprite(sprite_t sprite);
xblt_sprite:lda		SpriteMaxY,x
			sta		_heightmask	;height
			lda		SpriteLen,x	;length
			sta		_imglen		;(bytes)
			lda		SpriteV_l,x
			sta		_srcptr_l	;-> sprite
			lda		SpriteV_h,x	;   data
			sta		_srcptr_h	;paint/
			jsr		xor_blit 	;erase

xbspr2:		cpx		#U_SHIP		;ship
			bne		xbspr_ret	;erased?
			lda		_paintmask
			sta		_collision	;detection
xbspr_ret:	rts

;$226e
scroll_surf:lda		#0
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
ssurfleft:	ldx		#RIGHT		;228a
			ldy		#80			;-ve A
			jsr		psurf_left
			sta		_temp		;dxwin
			pla					;restore
			sta		_originp_h	;curr ptr
			pla		
			sta		_originp_l

			sec			
			lda		#0
			sbc		_temp		;-_dxwin
			tay					;(+ve)	
			ldx		#LEFT		;0
			lda		_temp
			jsr		psurf_left
			jmp		ssurf_ret

ssurfright:	ldx		#LEFT		;22a9
			ldy		#0			;A: +dxwin
			jsr		psurf_right
			sta		_temp
			pla		
			sta		_originp_h
			pla		
			sta		_originp_l

;code fragment at $1086 matches here
			sec		
			lda		#80
			sbc		_temp		;80-dxwin
			tay		
			ldx		#RIGHT		;1
			lda		_temp
			jsr		psurf_right
			jmp		ssurf_ret

ssurfstill:	pla					;22c8
			sta		_originp_h
			pla		
			sta		_originp_l
ssurf_ret:	rts					;22ce

;$22cf
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

;$230b
collision:	lda		_collision		
			and		#%11000000	;enemy+shp
			beq		nocollide	;overlap?
			lda		_dead
			beq		cllshipx	;alive?
nocollide:	rts
; ship has collided, find unit
cllshipx:	ldx		#SHIP
			jsr		get_xscr
			sta		_ship_xscr
			ldx		#ID_ALT3	;[36,2]
cllloop:	lda		Unit,x
			asl		
			bmi		cllnext		;b6/empty?
			cmp		#%10010		;(9 <<1)
			bcs		cllnext		;S250/500?
			lda		Anim,x
			bne		cllnext		;transient
cllydisp:	lda		Y_h,x
			sec		
			sbc		Y_h + SHIP	;Ydispl
			cmp		#8
			bpl		cllnext		;> 7?
			cmp		#$f9	
			bmi		cllnext		;< -7?
; -7 >= ydisp >= 7
;(ship/enemy height 8px) 
cllxdisp:	jsr		get_xscr
			cmp		#80
			bcs		cllnext		;offscrn?
			sec		
			sbc		_ship_xscr	;Xdispl
			cmp		#6
			bpl		cllnext		; > 5?
			cmp		#$fd
			bmi		cllnext		; < -3?
;-3 <= Xdisp <= 5
;(ship width 6px, enemy 4px)
			lda		Unit,x
			and		#%01111111	;sprite #
			cmp		#MAN
			beq		cllman		;man?
cllsmash:	jsr		score_unit	;collision
			jsr		kill_unit	;w/enemy
			lda		#TRUE
			sta		_dead		;die
			lda		#(PAL_SHIP|WHITE)
			sta		_shippal
cllman:		lda		Param,x
			bpl		cllnext
			cmp		#$80
			beq		cllnext
cllhh:		jsr		erase_unit	;man
			lda		#$80		; ->
			sta		Param,x		;hiker
			lda		#(UPDATE|MAN)	;86
			sta		Unit,x
			inc		_hikerc 	;rescued!
			lda		#14
			jsr		playsound
			jsr		score500
cllnext:	dex
			cpx		#ID_MIN		;#2?
			bcs		cllloop		;[36,2]
			rts		

;$238c,+26	17loc
;Generate pseudorandom byte (seed: rand_l)
;	X preserved
;	ret A:	random [0,255]
;#define	SEED	_rand_l /* $80 */
;extern uint8_t _rand[3];
;uint8_t	random(void);
random:		txa					;save X
			pha		
			ldx		#8			;count
randgen:	lda		_rand_h		;-> seed
			and		#%01001000	;pseudornd
			adc		#%00111000	;& 72 + 56
bitshift:	asl					;b7 lost
			asl					;b6 << buf
			rol		_rand_l		;(3 byte
			rol		_rand_m		; buffer)
			rol		_rand_h
randnext:	dex					;[8,1]
			bne		randgen		;repeat 8x

randend:	pla					;restore X
			tax		
			lda		_rand_h		;rnd[0,ff]
			rts					;-> ret A

;$23a6,+172	87loc
;Level up, reset all global vars
;runs into:	cont_level()
;			new_screen()
;void		next_level(bcd_t *_level);
next_level:	sed					;bcd_t
			lda		_level
			clc		
			adc		#1			;level++
			sta		_level
nxlev2:		cmp		#5			;lev #1-4?
			bcc		manbonus	;bonus #00
			lda		#5			;#5+: 500
manbonus:	sta		_humanbonus
nxlev3:		lda		_level		;bcd_t
			sec					;(norm.red
			ldx		#(PAL_SURF|RED)	;surf)
modulo5:	sbc		#5			;(level
			bcs		modulo5		;mod 5)==0
			cmp		#$95		;every 5th
			bne		notbonus	;level?
bonuslevel:	lda		#10			;renew
			sta		_humanc		;# of men
			lda		#FALSE		;restore
			sta		_no_planet	;(gr.surf)
			ldx		#(PAL_SURF|GREEN)
			inc		_batch		;size = 6+
			;-> 6(+..) units per batch
notbonus:	cld					;end bcd_t
			lda		_humanc
			bne		setsurface	;no men?
			ldx		#(PAL_SURF|BLACK) ;(no
setsurface:	stx		_surfpal	;surf)
nxlev4:		clc		
			lda		_shootspeed	;init.ly 0
			adc		#8			;+= 8 
			sta		_shootspeed	;dX{kugel}
			lda		#10			;1st bait,
			sta		_baitdelay_h ;then =2
			lda		#0			;-> spawn_
			sta		Spawnc + BAITER ;_bait
			lda		_humanc		;survivors
			sta		Spawnc + MAN
nxlev5:		ldx		#Uf			;id #
			lda		#EMPTY		;ff
nlclrslots:	sta		Unit,x		;clr slots
			dex					;S,HH,Uall
			bpl		nlclrslots	;[31,0]

nxlev6:		lda		#0			;no hitch
			sta		_hikerc		;hikers
;			sta		_enemyc
;			sta		rotatec		;[0,2]
;			sta		_flashc		;[0,7]
			lda		#ID_ALT1
			sta		_id_alt		;init #34
;			lda		#0
;			sta		rotatec
;			sta		_flashc
			lda		#6
			sta		_flpalframes ;every
			sta		_flpalc		;6th frame
;			lda		#0
;			sta		_enemyc
			lda		#2			;$200
			sta		_squaddelay	;frames
nxlev7:		lda		#0			;only spwd
			sta		Spawnc + SWARMER ;@pod
			ldx		#0			;# bombers
			lda		_level		;per level
			cmp		#1			;#1: none
			beq		bomberc
			ldx		#4			;#2/#3: x4
			cmp		#4
			bcc		bomberc		;#4 onward
			ldx		#7			;   x7
bomberc:	stx		Spawnc + BOMBER	
			ldx		#4			;# pods
			cmp		#4			;level #4
			bcs		podc		;onward x4
			dex					
			cmp		#3			;#3: x3
			beq		podc
			dex		
			dex					;#2: x1
			cmp		#2
			beq		podc
			dex					;#1: none
podc:		stx		Spawnc + POD

nxlev8:		lda		dXMinInit + LANDER
			clc					;dXinit 8
			adc		#2			;+= 2	
			cmp		#24 		;max dX
			bcs		nxlev9		;(22 << 3)
			sta		dXMinInit + LANDER
nxlev9:		lda		#(PAL_BG|BLACK)
			sta		_bgpal		;00

;$2452,+46	21loc
;Continue this level, after life lost
;runs into:	new_screen()
;void		cont_level(void);
cont_level:	lda		#$80
			sta		XMinInit + SWARMER
			ldx		#ID_MAX + 1	;#32
contloop:	lda		Unit,x
			and		#%01111111	;sprite #
			cmp		#BAITER	
			bne		notbaiter	;baiter?
			lda		#EMPTY		;->	clear
			sta		Unit,x		;	slot
notbaiter:	jsr		reset_unit
			jsr		init_unit
			dex					;reset all
			bpl		contloop	;#[32,0]

ctlev2:		lda		#ID_MIN		;start #2
			sta		_id
			lda		#0			;no hikers
			sta		_hikerc
			lda		#KEYDOWN	;ff
			sta		_inkey_space ;no late
			sta		_inkey_enter ;key
			sta		_inkey_tab	;presses
			;A = $ff  runs into
			;new_screen();

;$2480,+207
; either $ff or passed in A
;	arg A:	old Xedge, persists (or $ff)
;New screen
;void		new_screen(uint8_t xedge);
new_screen:	sta		_xrel_h
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
			lda		#100		;of field
			sta		Y_h + SHIP
			lda		#7			;+ve ->
			sta		_ddx_l		;facing R
			lda		#0
			sta		_ddx_h

			lda		#0			;clear
			ldx		#3			;beams
clrbeams:	sta		_Laser,x	;[4]
			dex
			bpl		clrbeams	;[3,0]

			lda		#EMPTY		;ff
			sta		Unit + HITCH ;free hh
			ldx		#ID_ALT3	;id #36
freeobjs:	lda		#EMPTY		;ff
			sta		Unit,x		;free
			jsr		clear_data	;obj slots
			dex
			cpx		#ID_BULLET1	;id #32
			bpl		freeobjs	;[36,32]
resetus:	jsr		reset_unit	;X: id #31
			dex					;reset all
			bpl		resetus		;[31,0]

			lda		#$80
			sta		Param + HITCH
			lda		#0
			sta		Unit + SHIP
			sta		dX_l + SHIP	;stop ship
			sta		dX_h + SHIP
			sta		Anim + SHIP
			;lda	#FALSE
			sta		_dead		;alive
			sta		_collision
; ship facing right, by default
			lda		#<imgShipR	;fc0
			sta		SpriteV_l + U_SHIP	
			lda		#>imgShipR
			sta		SpriteV_h + U_SHIP	
			lda		#(6*8)		;48 bytes
			sta		SpriteLen + U_SHIP

			lda		#0			;stop
			sta		_dxwin		;scrolling
			sta		_scrolloff_l
			sta		_scrolloff_h
;			lda		#<VRAM		;unneeded
			sta		_originp_l	;00
			sta		_oldorgp_l
			lda		#>VRAM		;$3000
			sta		_originp_h
			sta		_oldorgp_h
			sta		_digitp_h
			lda		#<VRAM + (26*8)
			sta		_digitp_l	;$30d0

			jsr		wait_vblank ;ready
			lda		#(PAL_BG|BLACK) ;00
blackpal:	jsr		set_palette
			clc
			adc		#$10		;palette
			bne		blackpal	;all BLACK

			lda		#0			;string0
			jsr		print_n		;VDU 20,12

			lda		#(PALX_ENEMYB|BLACK)
setpalx:	jsr		set_palette	;80
			clc
			adc		#$11		;[91,a2 ..
			bcc		setpalx		; ,e6,f7]

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
			ldx		#0			;paint
			ldy		#0			;digits
			jmp		add_score 
			;rts

;$254f,+26	11loc
;Reset unit (on new/continue level)
;	arg X:	unit id
;void		reset_unit(id_t unit);
reset_unit:	lda		Anim,x
			beq		++			;drawn?
			bpl		+			;spawning?
			lda		#EMPTY		;exploded
			sta		Unit,x		;->free
			bne		++	  		;always

+			lda		#8			;255d
			sta		Param,x		;re warp
++			jsr		clear_sptrs	;2562
			;lda	#NULL
			sta		pDot_h,x
			rts

;$2569
clear_data:	lda		#0
			sta		Anim,x
			sta		Param,x
;$2571
clear_sptrs:lda		#NULL
			sta		pNext_h,x
			sta		pSprite_h,x
			rts

;$257a,+36	18loc
;Print message stringX, from StringV[7]
;	X,Y preserved
;	arg A:	msg # (0-6)
;void		print_n(uint8_t msg);
print_n:	stx		_savedx 	;save
			sty		_savedy		; X,Y
print2:		tax					;msg #
			lda		StringV_l,x	;[7]
			sta		_destptr_l	
			lda		StringV_h,x	;get ptr
			sta		_destptr_h	;->stringX
print3:		ldy		#0		 	
			lda		(_destptr),y ;1st char
			sta		_strlen		;get len
coutlp:		iny					;do {
			lda		(_destptr),y
			jsr		OSWRCH		;print chr
			cpy		_strlen		;} while
			bne		coutlp		;(--len);

print4:		ldx		_savedx		;restore
			ldy		_savedy		; X,Y
			rts

;$259e
score_unit:	txa					;nemy id
			pha		
			tya					;save Y
			pha		
			lda		Unit,x
			cmp		#EMPTY		;ff
			beq		+			;empty?
			and		#%0111 1111	;slot full
			tax					;-> spr #
			lda		Points_h,x
			tay		
			lda		Points_l,x
			tax		
			jsr		add_score
+			pla					;25b7
			tay		
			pla		
			tax		
			rts		

;$25bc
score500:	tya					
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
			lda		#(UPDATE|S500)
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

;$2602
score250:	tya					;score500
			pha					;()
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
			lda		#(UPDATE|S250)
			sta		Unit,y		;89
			bne		spawn_score	;always
			; as for score500() above

;$261b
add_score:	sed					;bcd_t
			clc
			txa					;args X,Y
			adc		_score_lsb
			sta		_score_lsb	;+= X
			tya
			adc		_score_100	;+carry
			sta		_score_100	;+= Y x00
			; carry .. ##
			php
			lda		#0
			adc		_score_msb	;+= carry
			sta		_score_msb
			plp		; C preserved
			cld
; every 10,000 points
			bcc		+			;scoreMSB?
			jsr		reward		;+1up,bomb
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
			bpl		-			;[2,0]

			jsr		paint_digit	;spacer
			ldx		#0
			lda		_lives
			jsr		paint_bcd	;#of lives

			lda		#FALSE
			sta		_leading0	;erase
			jsr		paint_digit	;spacer
; args for paint_bcd
			ldx		#0
			lda		_bombs   	;#of bombs
			;jsr	paint_bcd	;runs thru
			;rts

;$2664
paint_bcd:	pha					;hhhhllll 
			and		#%11110000
			jsr		paint_digit
;use high nibble -> 16 byte intervals
			cpx		#0
			bne		+
; make sure paint_digit doesnt erase
			lda		#TRUE		;copy
			sta		_leading0
;2672
+			pla					;restore
			asl					;arg
			asl
			asl					;lo nibble
			asl
;			jsr		paint_digit	;runs into
;			rts

;2677
paint_digit:stx		_temp		;save X
			tax
			ora		_leading0	;nonzero
			sta		_leading0	;digit?

			ldy		#0
pdigloop:	lda		_leading0	;2680
			beq		+			;blank?
			lda		imgDigit,x	;src =f00
+			sta		(_destptr),y ;dst 2687
			iny
			inx					;next byte
			tya
			and		#%111		;mod 8
			tay					;[0,7]
			bne		plnext		;while(Y)

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
			sta		dXMinInit + LANDER
			lda		#0
			sta		_shootspeed
			lda		#5
			sta		_batch		;batchsize
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

;$279d,+57	20loc
;Main routine
; ret X:	-1 if ESCAPE condition clred
;			0  otherwise
;int 		frame_all(void);
frame_all:	jsr		do_laser
			jsr		ship_all
			jsr		hitchhiker
			jsr		repaint_dig	;26ad
			jsr		repaint_map	;15c6

			ldx		#ID_BULLET1	;32
			jsr		ai_unit		;1191
			ldx		#ID_BULLET2	;33
			jsr		ai_unit
			jsr		ai_alt		;34
			jsr		ai_alt		;35
			jsr		ai_alt 		;36
			jsr		ai_batch	;5x

			jsr		next_frame	;1f12
					;wait_vblank()
					;start_timer()
			jsr		scroll_surf	;226e
			jsr		repaint_all	;21f5
			jsr		collision	;230b
			jsr		spawn_bait
			lda		#$7e  		;ack ESC
			jmp		OSBYTE		;condition
			;rts
;OSBYTE &7E, among other things, clears the keyboard buffer.
;This ensures the key scans done in ship_all() will work properly.

;27d6
cursor_on:	lda		#$04  		;enable
			ldx		#0  		;cursor
			jsr		OSBYTE		;editing
			ldx		#10
			lda		#%0111 0010
			jmp		out6845
			;rts

;27e4
cursor_off:	lda		#$04		;disable
			ldx		#1			;cursor
			jsr		OSBYTE		;editing
			ldx		#10			;reg #10
			lda		#%0010 0000	;-> cursor
			jmp		out6845		;blink off
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
-			lda		_score_lsb,x ;27ff
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
;2830
cursor_xy:	lda		#31			;mv cursor
			jsr		OSWRCH
			txa					;VDU 31,
			jsr		OSWRCH		;rowX,colY
			tya				
			jmp		OSWRCH
			;rts

hiscore:	lda		#$7e		;283d
			jsr		OSBYTE 		;ack ESC

			ldx		#0		  	;top score
highloop:	lda		HiScore,x	;2844
			cmp		_score_lsb	;> C clear
			lda		HiScore+1,x
			sbc		_score_100	;> clear
			lda		HiScore+2,x
			sbc		_score_msb	;[-1]
			bcc		newhigh3	;> hi[x]?

			txa		
			clc		
			adc		#24			;nextscore
			tax					;@tbl
			cpx		#(24*7 + 1)	;=169
			bcc		highloop	;8x scores
			bcs		print_highs	;too low?

			; found place @tbl
newhigh:	stx		_temp		;2860
			cpx		#(24 * 7)	;=168
			beq		+			;@lowest?

			ldx		#168
-			dex					;2868
			lda		HiScore,x 	;2nd last
			sta		HiScore+24,x ;last
			cpx		_temp
			bne		-  			;downshift

+			lda		#'\r'		;2873 0d
			sta		HiScore+3,x3 ;blank
			lda		_score_lsb
			sta		HiScore,x
			lda		_score_100
			sta		HiScore+1,x
			lda		_score_msb	;enter in
			sta		HiScore+2,x ;score

			jsr		print_highs
			jsr		input_name

;$288d
print_highs:lda		#3
			jsr		print_n
			jsr		cursor_off

			ldx		#0
			stx		_high_rank
			ldy		#6			;text row
prhiloop:	txa					;289b
			pha		
			pha		

			sed
			clc		
			lda		_high_rank	;#1 to #8
			adc		#1
			sta		_high_rank
			cld		

			ldx		#3
			jsr		cursor_xy
			lda		_high_rank
			jsr		rjust_bcd	;print
			lda		#'.'		;2e
			jsr		OSWRCH
			ldx		#7
			jsr		cursor_xy

			pla					;tbl off
			tax		
			lda		HiScore+2,x
			jsr		rjust_bcd
			lda		HiScore+1,x
			jsr		print_bcd
			lda		HiScore,x
			jsr		print_bcd

			cpx		_temp
			bne		+
			sty		_temp2		;entry row
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
			iny					;next row
			pla		 			;of text
			clc		
			adc		#24
			tax		
			cpx		#(24 * 8)	;=192
			bne		prhiloop

			rts		

;$28f4
input_name:	lda		#4
			jsr		print_n
			jsr		cursor_on

			lda		#$0f
			ldx		#1
			jsr		OSBYTE
			ldx		#18
			ldy		_temp2		;entry row
			jsr		cursor_xy

			clc		
			lda		_temp
			adc		#3
			sta		ParamBlk
			lda		#0
			adc		#>HiScore	;7
			sta		ParamBlk +1
			lda		#20			;max len
			sta		ParamBlk +2
			lda		#$20
			sta		ParamBlk +3
			lda		#$7e
			sta		ParamBlk +4
			ldx		#<ParamBlk
			ldy		#>ParamBlk
			lda		#0
			jsr		OSWORD		;input

			bcc		+	
			ldx		_temp
			lda		#'\r'
			sta		HiScore+3,x
+			jmp		cursor_off
			;rts

;$293d
init_video:	lda		#22
			jsr		OSWRCH		;VDU 22,2
			lda		#2
			jsr		OSWRCH		;-> MODE 2
; no video/cursor blanking delay
			ldx		#8			;reg 8
			lda		#0			;non-i.lcd
			jsr		out6845		;sync
; disable cursor editing + blink
			jmp		cursor_off
			;rts

;$2951
done_level:	lda		_xrel_h
			jsr		new_screen
			lda		#1
			jsr		print_n

			ldx		#40
			ldy		#159
			jsr		xy_to_vidp
			lda		#FALSE
			sta		_leading0
			lda		_level
			jsr		paint_bcd
			
			ldx		#42
			ldy		#135
			jsr		xy_to_vidp
			lda		#FALSE
			sta		_leading0
			lda		_humanbonus	
			jsr		paint_bcd
			lda		#0
			jsr		paint_bcd	;'00'

			lda		_humanc
			beq		lvldone
			sta		_count		;bonus ctr
			ldx		#25			;+3 ..
bonusloop:	ldy		#119		;2988
			txa		
			pha		
			jsr		xy_to_vidp
			ldx		#MAN		;6
			jsr		xblt_sprite	;paint man

			ldy		_humanbonus	;x100
			ldx		#00			;per man
			jsr		add_score

			ldx		#4
			jsr		delay
			pla					;Xpos
			clc
			adc		#3			;spacing
			tax					;[25,28..]
			dec		_count		;humanc--
			bne		bonusloop
;29a9
lvldone:	ldx		#70
			jsr		delay
			rts	

;$29af
delay:		txa
			pha		
			jsr		next_frame
			pla		
			tax		
			dex		
			bne		delay
			rts		

;$29ba
main:		jsr		init_video	;play game
			jsr		planetoid
; _gameover_sp returns here / game over
gameover:	lda		_xrel_h 	;same Xpos
			jsr		new_screen
			lda		#2
			jsr		print_n
			ldx		#100
			jsr		delay
; quit() jumps here (zero score)
main_hisc:	jsr		hiscore
			lda		#6
			jsr		print_n
			jsr		waitspc_in
			jmp		main		;inf loop

;$29dd
planetoid:	tsx
			stx		_gameover_sp
; sp returns as if from this fn
			lda		#0
			jsr		playsound
			jsr		init_zp
planetloop:	jsr		next_level
			jsr		game
;_nextlvl_sp returns here / level complete
			jsr		done_level	;2951
; make sure lives remain
			lda		_lives		
			bne		planetloop	;level++
			rts					;game over

;$29f6
anim_frame:	lda		Param,x		
			cmp		#8			;1stframe?
			beq		+			;nix2erase

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

			jsr		xoranimate	;erase old

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
			
			jmp		xoranimate	;paint new
			;rts

+			lda		Anim,x		;2a4d
			bmi		++
			cpx		#SHIP		;#0
			bne		+
			asl		
			bpl		+
			lda		#TRUE
			sta		_dead
+			lda		#0			;2a5d
			sta		Anim,x
			sta		pSprite_h,x
			sta		pNext_h,x
			rts		

++			lda		#EMPTY		;2a69 ff
			sta		Unit,x
			jmp		init_unit
			;rts

;$2a71
xoranimate:	lda		_min_xscr
			pha		
			lda		_max_xscr
			pha		
			lda		#0
			sta		_min_xscr
			lda		#80
			sta		_max_xscr

			jsr		get_xscr	;Xpos
			cmp		#100
			bpl		xanim_ret
			cmp		#ec			;< -20?
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
warploop:	sty		_yreg		;2a9f lpc
			ldx		_anim_xscr
			lda		WarpX,y
			jsr		warp_coord	;2b3a
			pha		
			ldx		_id
			lda		Y_h,x
			tax		
			lda		WarpY,y
			jsr		warp_coord
			tay		
			pla		
			tax		
			jsr		xy_to_vidp

			lda		_destptr_h	;offscrn?
			beq		warpnext	;null ptr?
warpdot:	ldy		#0			;2abf
			ldx		_id
			lda		Unit,x		;sprite #
			asl		
			tax	
			lda		imgDot,x	;map cl
			eor		(_destptr),y ;XOR
			sta		(_destptr),y ;blit
warpnext:	ldy		_yreg		;2ad0 lpc
			dey		
			bpl		warploop	;8x dots

			ldx		_id
xanim_ret:	pla					;2ad7
			sta		_max_xscr
			pla		
			sta		_min_xscr
			rts		

;$2ade
anim_blast:	ldy		#7
blastloop:	lda		_anim_xscr	;2ae0
			ldx		BlastX,y	;2c60
			jsr		blast_coord	;Xscr
			pha		
			lda		Y_h,x
			ldx		BlastY,y	;2c68
			jsr		blast_coord	;Yscr
blastptr:	tay					;2af2
			pla		
			tax		
			cpy		#192
			bcs		blastnext	;too high?
			jsr		xy_to_vidp

			lda		_destptr_h
			beq		blastnext	;offscrn?
blastdot:	ldy		#0			;2b05
			ldx		_id
			lda		Unit,x		;sprite #
			asl					; * 2
			tax		
			lda		imgDot,x	;colour
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

;$2b1e
blast_coord:sty		_yreg		
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
			bne		-			;[1,7] ->0

			php		
			ldy		_yreg
			ldx		_id
			plp		
			rts		

;$2b3a
warp_coord:	stx		_xreg
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

;$2b73,+13	7loc
;	arg X:	unit id
;	ret A:	surface Ypos (-> Y_h)
;Get planet surface height at unit's Xpos
;uint8_t	get_ysurf(id_t unit);
get_ysurf:	lda		X_l,x
			asl		
			lda		X_h,x
			rol					;Xscale
			tay		
			lda		SurfaceY,y	;surf
			rts					;height

;$2b80,+12	7loc
; arg A:	linked sprite # (LANDER|MAN)
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

;$2b8c,+20	9loc
; arg A:	linked sprite #	(LANDER|MAN)
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

;$2f90,+32	20loc
;Handle pause(P/@) + quit(ESC) keys,
;then key_fire(); keys_nav();
;void		pause_quit(void);
pause_quit:
key_pause:	ldx		#KEY_P		;-56
			jsr		scan_inkey
			beq		key_quit
pauseloop:	ldx		#KEY_AT		;-72
			jsr		scan_inkey	;busy wait
			beq		pauseloop	;until '@'

key_quit:	ldx		#KEY_ESCAPE	;-113
			jsr		scan_inkey	;escape
			beq		gotokeys	;!pressed?
quit:		lda		#0			
			sta		_score_lsb	;[3]
			sta		_score_100	;zero out
			sta		_score_msb	;score
			ldx		_gameover_sp
			inx					;stack ptr
			inx					;as if
			txs					;RTS
			jmp		main_hisc	;quit game
			;..
			;jmp	main

gotokeys:	jsr		key_fire	;fire
			jmp		keys_nav	;up,down..
			;rts

;$2ff0,+11	7loc
;Offset (Xunit rel edge) by +110 [-2]
;Called once from mm_update():xdot
;	arg A:	Xdispl b/w unit + screen edge
;	arg X:	unit id
;	ret a:	(Xdisp on minimap)
;int8_t		xoffset110(	int8_t	xdot,
;						id_t	id);
xoffset110:	clc
			adc		#110		;+110
			cpx		#LANDER
			bne		a110_ret	;lander?
			sec					;-> -2
			sbc		#2			;   (+108)
a110_ret:	rts

;$3000
;Program entry point, JMPed from $1100
;void		boot(void);
boot:		lda		#&00		;get OS
			ldx		#1			;version
			jsr		OSBYTE 		;X unused?
			ldx		#$ff		;init
			txs					;stack ptr

hook:		sei					;IRQs off
			lda		IRQ1V
			sta		_irq1v		;save MOS
			lda		IRQ1V + 1	;vector
			sta		_irq1v + 1
			lda		#<irq_hook
			sta		IRQ1V		;hook IRQ
			lda		#>irq_hook
			sta		IRQ1V + 1
			cli					;done
			
mkscores:	ldx		#0			;make
yreset:		ldy		#0			;hiscores
mkscloop:	lda		DefHigh,y	;[24]
			sta		HiScore,x	;copy
			inx					;Acornsoft
			iny					;1000 pts
			cpy		#24	
			bcc		mkscloop
			cpx		#(24*7 + 1)	;=169
			bcc		yreset		;loop [8]

to_main:	lda		#(PAL_SHIP|WHITE)
			sta		_shippal	;77
			jmp		main 		;new game
