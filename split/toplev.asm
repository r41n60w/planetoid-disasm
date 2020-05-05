; vi: syntax=asmM6502 ts=8 sw=8

;$279d	+57 bytes	10 loc
;Main routine, executes once a frame
;Subroutines are in order of timing,
;relative to vertical sync V:+[# ms]
;
;Vsync-relative timing map:
;
;+5.248ms CRT @play field,Yscr 0-195
; ->	[ALL upper screen blits
;	 digit row/minimap]
;+18ms	  CRT @1st half vblank intvl
;+20ms	  next Vsync pulse
;[+0ms]   CRT @2nd half vblank intvl
;[+2ms]	  CRT @123/mmap,Yscr 196-256
; ->	[ALL play field blits
;	 sprite/surface/laser/anim]
frame_all:		;[20 loc]
	jsr	next_laser
scrtop	jsr	update_ship
	;-> ping_mmap(), timer zero
	jsr	update_hiker
	jsr	repaint_123
	jsr	repaint_mmap
	;update all objects O[abxyz]
bolt1	ldx	#Oa
	jsr	update_any
bolt2	ldx	#Ob
	jsr	update_any
updobj	jsr	update_obj ;Ox
	jsr	update_obj ;Oy
	jsr	update_obj ;Oz
	;batch of 5+ consecutive U*
	jsr	update_batch
vsync	jsr	next_frame
	;-> wait_vsync()
	;[Vsync] start_timer()
scrbtm	jsr	repaint_surf
	jsr	repaint_sprs
	;_hitmask -> _hitship
	jsr	collide_ship
	jsr	spawn_bait
	;acknowledge ESCAPE cond.n
fflush	lda	#$7e  	;clear
	jmp	OSBYTE	;input buf[]
	;rts

;	:pause_quit,keys_nav
;spdrag	spxscr	dxrel
;nxship	scroll_scrn(Sp)
;	move_x(Sp)

;$1db1,+52 bytes	23 loc
;Game toplevel routine ->planetoid()
;Spawn all units, then exec frames
;Returns on level end -> no enemies
game_level:
	tsx		;save stack
	stx	_nxlevsp ;ptr -> RTS
spwon	lda	#TRUE	;spawn in
	sta	_spawning ; progress
	;spawn men (initially 10x)
spwmen	lda	#MAN	
	jsr	spawn_units
	lda	#0	;men persist
	sta	(Spawnc + MAN)
	ldx	#20	; " frames
	jsr	frames	;wait
	;squad #1, bombers, pods
spwall	jsr	spawn_all
	;squads #2,#3 (at intervals)
squads	jsr	spawn_squad
	jsr	spawn_squad
	;squad #4 (level 6 onward)
	lda	_level
	cmp	#6	;>= 6?
	bcc	spwoff	;skip squad
squad4	jsr	spawn_squad 
spwoff	lda	#FALSE	;finished
	sta	_spawning ; spawn
	;while(enemies)  frame();
gamelp	jsr	frame_full
	lda	_enemyc	;enemies?
	bne	gamelp	;next frame
endlvl	rts		;level done

;$29ba,+35 bytes	13 loc
;Acornsoft top-level game loop
;{ Game, high score screen, SPACE } 
main:
	jsr	init_video
	;play actual game
	jsr	planetoid
	;game over -> (_gameovsp)
gmover	lda	_xpos_h	;same Xpos
	jsr	reset_game ;clr scrn
	lda	#2
	jsr	print_n
	ldx	#100
	jsr	delay
;[$29cf]		[:+21 bytes]
;If high score, input player name
;pause_quit() jumps here, no score
main_hiscore:		;[+8 loc]
	jsr	hiscore
	;"Press SPACE to play again"
	lda	#6
	jsr	print_n
	jsr	wait_spaceb
	jmp	main	;inf loop

;$29dd,+25 bytes	11 loc	
;Top-level game routine -> main()
planetoid:
	tsx		;save stack
	stx	_gameovsp ;   ptr
	lda	#SND_INIT
	jsr	play_sound
	jsr	init_game ;globals
	;start level #1
gmloop	jsr	next_level ;++level
	jsr	game_level
	;level complete ->(_nxlevsp)
levok	jsr	done_level
	lda	_lives
	bne	gmloop	;next level
	;no lives left, game over
	rts		;->_gameovsp

;$3000	+59 bytes	28 loc	
;Boot program
;Entry point ($1100) jumps here
boot:
	lda	#&00	;get OS
	ldx	#1	;version
	jsr	OSBYTE 	;[ret] -> X
	;discard result X, useless?
stackp	ldx	#$ff	;init
	txs		;stack ptr
	;hook general interrupt
hook	sei		;IRQs off
	lda	IRQ1V
	sta	_irq1v_l ;  save OS
	lda	(IRQ1V+1) ; vector
	sta	_irq1v_h
	lda	#<irq_hook
	sta	IRQ1V	;hook irq
	lda	#>irq_hook
	sta	(IRQ1V + 1)
	cli		;IRQs on
	;make 8x default high scores
mkscor	ldx	#0	;dest index
yreset	ldy	#0	; src "
scorlp	lda	DefHigh,y
	sta	HiScore,x
	inx		;"Acornsoft"
	iny		; 1000 pts
	cpy	#24	
	bcc	scorlp	;copy def.lt
	cpx	#(24*7)+1 ;=(169)?
	bcc	yreset	;loop 8x
	;set ship colour
tomain	lda	#(PAL_SHIP|WHITE)
	sta	_shippal
	jmp	main	;-> new game
