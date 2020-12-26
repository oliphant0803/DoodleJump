#####################################################################
#
# CSC258H5S Fall 2020 Assembly Final Project
# University of Toronto, St. George
#
# Student: Name: Haoze Huang
# Student Number: 1006073204
#
# Bitmap Display Configuration:
# - Unit width in pixels: 8
# - Unit height in pixels: 8
# - Display width in pixels: 256
# - Display height in pixels: 256
# - Base Address for Display: 0x10008000 ($gp)
#
# Which milestone is reached in this submission?
# (See the assignment handout for descriptions of the milestones)
#####################################################################
# - Milestone 1/2/3/4/5 (choose the one the applies)
# MileStone 1 completed
# MileStone 2 completed
# MileStone 3: Die completed, Random platforms completed, scrolling completed
# MileStone 4: GameOver/Retry completed, Score completed
# MileStone 5: BGM completed. OnScreenNotification completed. UserInput in progress
#####################################################################
# Which approved additional features have been implemented?
# (See the assignment handout for the list of additional features)
# 1. GameOver/Retry
# 2. Score, more deatils in additional information
# 3. Music
# 4. On Screen Notification
#
# Any additional information that the TA needs to know:
# - The score display auto adjusts depends on the score there
# - If score is 8, then it displays 8. If score is 18, it displays 018
# - You can change the varibales such as score increment, plat length by simply changing in .data
# - The BGM sounds bad :(
# - It will get a bit laggy if the message counter set long
# - Input strings allows "a c d f g h i l o p s t u v " 
#####################################################################

.data
#data for display and world size
	displayAddress: .word 0x10008000
	World_Pixel:	.word 64
	World_Size: .word 4096
#Color reference
	Plat_Color: .word 0xbce672
	Doodler_Color: .word 0xd6ecf0
	Background: .word 0x065379
#position for reference
	Pos_Doodler: .word 3280
	Init_Doodler: .word 3280
	NextHeight: .word 0
	Pos_Relative: .word 3280
	Max_Height: .word 1260
	FixedMax: .word 1260
#Plat array info
	Plat_Begin: .space 12
	Plat_Length: .word 40
#messages
	Display_Counter: .word 0
	Instruction:	.asciiz "Enter 3 letter name: "
	WelcomeMsg:	.asciiz "Hello, "
	UserName:	.space 12
	Message1:	.asciiz "WOW \n"
	Message2:	.asciiz "POG \n"
	Message3:	.asciiz "GOOD \n"
#Music Reference
	Music_Counter: .word 0
#Score Reference, goes up to 999
	score:		.word 0 
	increment:	.word 3
	achivement:	.word 0
	
.text
#####################################################################
# Check start or exit
#####################################################################
GetName:
	li $v0, 4
	la $a0, Instruction
	syscall
	
	li $v0, 8
	la $a0, UserName
	li $a1, 20
	syscall
	
	li $v0, 4
	la $a0, WelcomeMsg
	syscall
	
	li $v0, 4
	la $a0, UserName
	syscall
	j DisplayName
	
CheckInitialInput:
	lw $s0, 0xffff0000
	beq $s0, 1, InitialInput
	j CheckInitialInput			#loop until recongized input
InitialInput:
	lw $s0, 0xffff0004
	beq $s0, 0x73, main			#loop until recongized s
	beq $s0, 0x65, exit			#input e for exit the program
	j CheckInitialInput


main:
	li $v0, 31				# play sound like taking off
	li $a0, 28
	li $a1, 100
	li $a2, 7
	li $a3, 127
	syscall
		
	li $a0, 33
	li $a1, 1000
	li $a2, 7
	li $a3, 127
	syscall
#####################################################################
# Initialization of the program
#####################################################################
Init:
	lw $t0, displayAddress 			# $t0 stores the base address for display
	la $t1, Pos_Doodler
	lw $t2, Init_Doodler
	add $t2, $t2, $t0
	sw $t2, ($t1)
	la $t1, Max_Height
	lw $t2, FixedMax
	add $t2, $t2, $t0
	sw $t2, ($t1)
	lw $t5, Pos_Doodler
	la $s5, Pos_Relative
	sw $t5, ($s5)
	lw $a3, World_Pixel
	mul $a3, $a3, 30
	sub $t4, $t5, $a3
	la $s4, NextHeight
	sw $t4, ($s4)
	la $s1, Plat_Begin
	addi $s2, $s1, 0
	addi $s3, $s2, 12
	addi $t3, $t0, 3640
	add $a3, $zero, 3640
GeneratePlat:
	sw $t3, ($s2)
	addi $s2, $s2, 4			# increment index
	beq $s2, $s3, GameLoop
	addi $a1, $zero, 2			
	addi $v0, $zero, 42			#(will generate 1 to 5 in future milestone to create complexity)
	syscall					#generate random from 1 to 1 
	beq $a0, 1, GetNextPlat 		#get next level if the number is 1
GetNextPlat:
	addi $a1, $zero, 64
	addi $v0, $zero, 42
	syscall					#generate random number from 
	mul $a0, $a0, 4				#to make the random number multiple of 4
	subi $a3, $a3, 1280			#ensure the next plat is at least 4 lines apart
	add $t3, $t0, $a3			#$t3 stores the display address for plats
	sub $t3, $t3, $a0			#add to the random generated number
	jal GeneratePlat			# go back to get plat	


#####################################################################
# Game Loop and check for inputs
#####################################################################	
GameLoop:	 
	la $k0, Display_Counter
	lw $k1, Display_Counter
	subi $k1, $k1, 1
	sw $k1, ($k0)
	bgt $k1, 0, ShowMessage
	la $k0, Music_Counter
	lw $k1, Music_Counter
	addi $k1, $k1, 1
	sw $k1, ($k0)
	beq $k1, 30, PlaySound
	j Check_Input
Check_Input:
	lw $s0, 0xffff0000
	beq $s0, 1, Keyboard_input 
	j CheckMove
Keyboard_input:
	lw $s0, 0xffff0004
	lw $t1, NextHeight				#Updating the next target accordingly right or left
	lw $t2, Pos_Doodler				#Updating the doodler position
	lw $t3, Pos_Relative				#Updating relative position to the plats
	la $s1, NextHeight
	la $s2, Pos_Doodler				
	la $s3, Pos_Relative
	beq $s0, 0x6a, MoveLocationsRight
	beq $s0, 0x6b, MoveLocationsLeft
	j CheckMove
MoveLocationsRight:
	subi $t1, $t1, 4
	subi $t2, $t2, 4
	subi $t3, $t3, 4
	j UpdateLocations	
MoveLocationsLeft:
	addi $t1, $t1, 4
	addi $t2, $t2, 4
	addi $t3, $t3, 4
	j UpdateLocations	
UpdateLocations:
	sw $t1, ($s1)
	sw $t2, ($s2)
	sw $t3, ($s3)
	j CheckMove
#####################################################################
# Check for jumping and update doodler reference locations
#####################################################################	
CheckMove:
	lw $t0, displayAddress 
	addi $t4, $t0, 3704			#This is the boundary of dying
	lw $t3, Pos_Relative
	bge $t4, $t3, CheckMoveContinue 	#Check which step of jumping if in bound 				
	j die					#Check if die after passing $t4	
CheckMoveContinue:	
	lw $t4 NextHeight
	blt $t3, $t4, FallDownReady		#If it reached NextHeight, then start falling
	lw $t4, Max_Height			
	lw $t5, Pos_Relative
	la $s5, Pos_Relative
	j JumpUp				#Start jump if not reached NextHeight
FallDownReady:
	la $s4, NextHeight			#Update the next targeted height to the end of screen so it will fall
	lw $t4, World_Size			#Load data of end of screen
	add $t4, $t4, $t0
	sw $t4, ($s4)
	j CheckPlatReady
FallDown:					
	addi $t5, $t5, 128			#Doodler fall down 1 row (increment)
	j UpdateDoodler
JumpUp:
	subi $t5, $t5, 128			#Doodler jump up 1 row (decrement)
	sw $t5, ($s5)
	bge $t5, $t4, UpdateDoodler		#Update the location of doodler for drawing reference
	j RandomPlatReady			#Otherwise Update the location of plats for drawing reference	

UpdateDoodler:					#Update the location of the doodler
	la $s1, Pos_Doodler
	la $s2, Pos_Relative
	sw $t5, ($s1)
	sw $t5, ($s2)
	j Repaint	
CheckPlatReady:	
	la $t1, Plat_Begin
	addi $s1, $zero, 0
	addi $s2, $zero, 12
	j CheckPlat		
CheckPlat:
	lw $t5, Pos_Doodler
	blt $s1, $s2, Continue_1		#continue until the index end
	j FallDown 				#or else keep falling
Continue_1:
	add $t3, $s1, $t1
	lw $t4, ($t3)
	lw $a3, World_Pixel
	mul $a3, $a3, 6				#get the correct pixels for the plat 
	addi $a3, $a3, 4			#add one pixel for the final range
	add $t5, $t5, $a3			#$t5 is the final range
	bge $t5, $t4, Continue_2
	addi $s1, $s1, 4			
	j CheckPlat
Continue_2:
	addi $t4, $t4, 40
	subi $t5, $t5, 8
	ble $t5, $t4, UpdateNextJumpingPlat
	addi $s1, $s1, 4			#Check the next plat with index ++
	j CheckPlat
UpdateNextJumpingPlat:	
	lw $t5, Pos_Doodler
	la $s5, Pos_Relative
	sw $t5, ($s5)
	lw $a3, World_Pixel
	mul $a3, $a3, 30
	sub $t4, $t5, $a3
	la $s4, NextHeight
	sw $t4, ($s4)
	j GameLoop
#####################################################################
# Update plate location for reference
#####################################################################	
RandomPlatReady:					
	la $s5, Plat_Begin			#load the address to update three plats
	add $s1, $zero, $zero			#give range (initial index)
	add $s2, $zero, 12			#give range (ending index)
	j StorePlat
StorePlat:	
	beq $s1, $s2, Repaint
	add $s3, $s5, $s1
	lw $t4, ($s3)				#load the address of the current plat
	lw $t5, World_Size
	add $t5, $t0, $t5
	addi $t4, $t4, 128			#move the plats location up		
	bge $t4, $t5, GenerateNew		#if the plat is outside of the display, reset it to the new one
	sw $t4,($s3) 				#otherwise its still in the array
	addi $s1, $s1, 4			#increment
	j StorePlat
GenerateNew:
	la $a0, achivement
	lw $a1, achivement
	addi $a1, $a1, 1
	sw $a1, ($a0)
	la $s6, score
	lw $s7, score
	lw $a2, increment
	add $s7, $s7, $a2
	sw $s7, ($s6)
	
	li $v0, 31				#boom sounds for acheiving a new plate
	li $a0, 85
	li $a1, 150
	li $a2, 7
	li $a3, 127
	syscall	
	
	li $a0, 46
	li $a1, 150
	li $a2, 7
	li $a3, 127
	syscall
		
	addi $v0, $zero, 42			#refresh a new plate
	addi $a1, $zero, 28
	syscall					#Generate random number for plat
	mul $a0, $a0, 4 			#Multiply by 4 so it can store in bitmap			
	add $t6, $t0, $a0			#t6 stores the ending position
	sw $t6,($s3) 				#store it in the array with index
	addi $s1, $s1, 4
	
	addi $a0, $zero, 5
	lw $a1, achivement
	div $a1, $a0
	mfhi $a1
	beq $a1, 0, GenerateMessage
	j StorePlat
	
GenerateMessage:
	la $k0, Display_Counter
	lw $k1, Display_Counter
	addi $k1, $zero, 1800
	sw $k1, ($k0)
	addi $v0, $zero, 42			#refresh a new plate
	addi $a1, $zero, 4			# number from 1 - 3
	syscall
	add $sp, $a0, $zero
	j ShowMessage
ShowMessage:
	ble $sp, 1, DrawMessage1
	beq $sp, 2, DrawMessage2
	bge $sp, 3, DrawMessage3

#####################################################################
# Repaint the entities 
#####################################################################
Repaint:
	lw $t4, World_Size			#load range
	lw $t0, displayAddress
	addi $t3, $t0, 0
	add $t4, $t0, $t4
	addi $t4, $t4, 4			#increment counter
	lw $t7, Background			#load color
FillBackground: 
	beq $t3, $t4, GetPlatsReady		#end loop when index equal range
	sw $t7, ($t3)				#store color
	addi $t3, $t3, 4			#increment counter address
	j FillBackground

GetPlatsReady:
	lw $t9, Plat_Color 			#load color
	la $t1, Plat_Begin			#load array
	add $s1, $zero, $zero
	addi $s2, $zero, 12			#space for array
	j GetPlatLocation	
GetPlatLocation:
	beq $s1, $s2, DrawDoodler		#Draw doodler after drawing plats
	add $t2, $t1, $s1
	lw $t3, ($t2)				
	addi $t4, $t3,40			#assign length of plate
	addi $s1, $s1, 4			#index ++
	j DrawPlat		
DrawPlat:
	beq $t3,$t4, GetPlatLocation		#if t3 = t4, get next plat
	sw $t9,	($t3)				#store color
	addi $t3, $t3, 4			#increment counter
	j DrawPlat
	
DrawDoodler:
	lw $t8, Doodler_Color 			#load data for doodler color
	lw $t2, Pos_Doodler			#load position for doodler
  	sw $t8, ($t2)
  	addi $t2, $t2, 124
	sw $t8, ($t2)
	addi $t2, $t2, 4
	sw $t8, ($t2)
	addi $t2, $t2, 4
	sw $t8, ($t2)
	addi $t2, $t2, 120
	sw $t8, ($t2)
	addi $t2, $t2, 8
	sw $t8, ($t2)
	j Sleep
#####################################################################
# Sleep
#####################################################################
Sleep:
	li $v0, 32
	li $a0, 50
	syscall
j GameLoop					#Back to game loop

restart:					#Draw Dying message
	li $t0, 0x10008000			#Ask restart or exit
	addi $s0, $t0, 1052
	li $t0, 0xff4777 
	sw $t0, ($s0)	
	sw $t0, 128($s0)
	sw $t0, 256($s0)
	sw $t0, 384($s0)
	sw $t0, 512($s0)
	sw $t0, 640($s0)
	sw $t0, 4($s0)
	sw $t0, 8($s0)
	sw $t0, 644($s0)
	sw $t0, 648($s0)
	sw $t0, 140($s0)
	sw $t0, 268($s0)
	sw $t0, 396($s0)
	sw $t0, 524($s0)
	sw $t0, 24($s0)
	sw $t0, 28($s0)
	sw $t0, 32($s0)
	sw $t0, 156($s0)
	sw $t0, 284($s0)
	sw $t0, 412($s0)
	sw $t0, 540($s0)
	sw $t0, 668($s0)
	sw $t0, 672($s0)
	sw $t0, 664($s0)
	sw $t0, 48($s0)
	sw $t0, 52($s0)
	sw $t0, 56($s0)
	sw $t0, 60($s0)
	sw $t0, 176($s0)
	sw $t0, 304($s0)
	sw $t0, 308($s0)
	sw $t0, 312($s0)
	sw $t0, 432($s0)
	sw $t0, 560($s0)
	sw $t0, 688($s0)
	sw $t0, 692($s0)
	sw $t0, 696($s0)
	sw $t0, 700($s0) 
	sw $t0, 76($s0)
	sw $t0, 204($s0)
	sw $t0, 332($s0)
	sw $t0, 460($s0)
	sw $t0, 716($s0)
	li $t0, 0xf9906f
	addi $s0, $s0, 1420
	sw $t0, ($s0)
	sw $t0, 128($s0)
	sw $t0, 256($s0)
	sw $t0, 4($s0)
	sw $t0, 8($s0)
	sw $t0, 260($s0)
	sw $t0, 264($s0)
	sw $t0, 392($s0)
	sw $t0, 520($s0)
	sw $t0, 516($s0)
	sw $t0, 512($s0)
	sw $t0, 552($s0)
	sw $t0, 680($s0)
	sw $t0, 808($s0)
	sw $t0, 936($s0)
	sw $t0, 1064($s0)
	sw $t0, 1068($s0)
	sw $t0, 1072($s0)
	sw $t0, 812($s0)
	sw $t0, 816($s0)
	sw $t0, 556($s0)
	sw $t0, 560($s0)
	li $t0, 0xff4777 
	sw $t0, 164($s0)
	sw $t0, 288($s0)
	sw $t0, 412($s0)
	sw $t0, 536($s0)
	sw $t0, 660($s0)
	sw $t0, 784($s0)
	sw $t0, 908($s0)
	j ShowScore
#	CheckRestartInput:
#	lw $s0, 0xffff0000
#	beq $s0, 1, RestartInput
#	j CheckRestartInput			#loop until recongized input
#	RestartInput:
#	lw $s0, 0xffff0004
#	beq $s0, 0x73, main			#input s for restart
#	beq $s0, 0x65, exit			#input e for exit the program
#	j RestartInput


ShowScore:
    	la $s6, score
	lw $s7, score
	li $v0, 1
    	move $a0, $s7
    	syscall
	addi $s1, $zero, 0
	j DrawScore
DrawScore:
	li $t0, 0x10008000			
	addi $s0, $t0, 284
	li $t0, 0xf3f463
	sw $t0, ($s0)	
	sw $t0, 128($s0)
	sw $t0, 256($s0)
	sw $t0, 384($s0)
	sw $t0, 512($s0)
	sw $t0, 4($s0)
	sw $t0, 8($s0)
	sw $t0, 136($s0)
	sw $t0, 264($s0)
	sw $t0, 260($s0)
	addi $s0, $s0, 16
	sw $t0, 4($s0)	
	sw $t0, 132($s0)
	sw $t0, 260($s0)
	sw $t0, 388($s0)
	sw $t0, 520($s0)
	sw $t0, 516($s0)
	sw $t0, 264($s0)
	sw $t0, 256($s0)
	addi $s0, $s0, 16
	sw $t0, 128($s0)
	sw $t0, 384($s0)
PrintThirdDigit:
	li $t0, 0x10008000
    	addi $s0, $t0, 332
	lw $s5, score
	add $s7, $s5, $zero
	addi $a0, $zero, 100
	div $s7, $a0
	mfhi $s5
	mflo $s7
	sw $s5, ($s6)
	li $t0, 0xf3f463
	beq $s7, 0, DrawZero 
	beq $s7, 1, DrawOne
	beq $s7, 2, DrawTwo
	beq $s7, 3, DrawThree
	beq $s7, 4, DrawFour
	beq $s7, 5, DrawFive
	beq $s7, 6, DrawSix
	beq $s7, 7, DrawSeven
	beq $s7, 8, DrawEight
	beq $s7, 9, DrawNine
PrintSecondDigit:
	li $t0, 0x10008000
    	addi $s0, $t0, 348
	lw $s5, score
	add $s7, $s5, $zero
	addi $a0, $zero, 10
	div $s7, $a0
	mfhi $s5
	mflo $s7
	sw $s5, ($s6)
	li $t0, 0xf3f463
	beq $s7, 0, DrawZero 
	beq $s7, 1, DrawOne
	beq $s7, 2, DrawTwo
	beq $s7, 3, DrawThree
	beq $s7, 4, DrawFour
	beq $s7, 5, DrawFive
	beq $s7, 6, DrawSix
	beq $s7, 7, DrawSeven
	beq $s7, 8, DrawEight
	beq $s7, 9, DrawNine
PrintSingleDigit:
	beq $s1, 1, ResetScore
	li $t0, 0x10008000
    	addi $s0, $t0, 364
	li $t0, 0xf3f463
	la $s6, score
	lw $s5, score
	add $s7, $s5, $zero
	addi $s5, $zero, 0
	sw $s5, ($s6)
	addi $s1, $s1, 1
	beq $s7, 0, DrawZero 
	beq $s7, 1, DrawOne
	beq $s7, 2, DrawTwo
	beq $s7, 3, DrawThree
	beq $s7, 4, DrawFour
	beq $s7, 5, DrawFive
	beq $s7, 6, DrawSix
	beq $s7, 7, DrawSeven
	beq $s7, 8, DrawEight
	beq $s7, 9, DrawNine

ResetScore:	
	la $s6, score
	lw $s7, score 		
	addi $s7, $zero, 0
	sw $s7, ($s6)
	j CheckInitialInput


DrawZero:
	sw $t0, ($s0)	
	sw $t0, 128($s0)
	sw $t0, 256($s0)
	sw $t0, 384($s0)
	sw $t0, 512($s0)
	sw $t0, 4($s0)
	sw $t0, 8($s0)
	sw $t0, 516($s0)
	sw $t0, 520($s0)
	sw $t0, 136($s0)
	sw $t0, 264($s0)
	sw $t0, 392($s0)
	lw $s7, score
	beq $s7, 0, ResetScore
	blt $s7, 10,  PrintSingleDigit
	blt $s7, 100,  PrintSecondDigit
DrawOne:
	sw $t0, ($s0)
	sw $t0, 4($s0)	
	sw $t0, 132($s0)
	sw $t0, 260($s0)
	sw $t0, 388($s0)
	sw $t0, 512($s0)
	sw $t0, 520($s0)
	sw $t0, 516($s0)
	lw $s7, score
	blt $s7, 10,  PrintSingleDigit
	blt $s7, 100,  PrintSecondDigit
DrawTwo:
	sw $t0, ($s0)
	sw $t0, 4($s0)
	sw $t0, 8($s0)
	sw $t0, 136($s0)
	sw $t0, 256($s0)
	sw $t0, 260($s0)
	sw $t0, 264($s0)
	sw $t0, 384($s0)
	sw $t0, 512($s0)
	sw $t0, 516($s0)
	sw $t0, 520($s0)
	lw $s7, score
	blt $s7, 10,  PrintSingleDigit
	blt $s7, 100,  PrintSecondDigit
DrawThree:
	sw $t0, ($s0)
	sw $t0, 4($s0)
	sw $t0, 8($s0)
	sw $t0, 136($s0)
	sw $t0, 256($s0)
	sw $t0, 260($s0)
	sw $t0, 264($s0)
	sw $t0, 392($s0)
	sw $t0, 512($s0)
	sw $t0, 516($s0)
	sw $t0, 520($s0)
	lw $s7, score
	blt $s7, 10,  PrintSingleDigit
	blt $s7, 100,  PrintSecondDigit
DrawFour:
	sw $t0, ($s0)
	sw $t0, 128($s0)
	sw $t0, 8($s0)
	sw $t0, 136($s0)
	sw $t0, 256($s0)
	sw $t0, 260($s0)
	sw $t0, 264($s0)
	sw $t0, 392($s0)
	sw $t0, 520($s0)
	lw $s7, score
	blt $s7, 10,  PrintSingleDigit
	blt $s7, 100,  PrintSecondDigit
DrawFive:
	sw $t0, ($s0)
	sw $t0, 4($s0)
	sw $t0, 8($s0)
	sw $t0, 128($s0)
	sw $t0, 256($s0)
	sw $t0, 260($s0)
	sw $t0, 264($s0)
	sw $t0, 392($s0)
	sw $t0, 512($s0)
	sw $t0, 516($s0)
	sw $t0, 520($s0)
	lw $s7, score
	blt $s7, 10,  PrintSingleDigit
	blt $s7, 100,  PrintSecondDigit
DrawSix:
	sw $t0, ($s0)
	sw $t0, 4($s0)
	sw $t0, 8($s0)
	sw $t0, 128($s0)
	sw $t0, 256($s0)
	sw $t0, 260($s0)
	sw $t0, 264($s0)
	sw $t0, 384($s0)
	sw $t0, 392($s0)
	sw $t0, 512($s0)
	sw $t0, 516($s0)
	sw $t0, 520($s0)
	lw $s7, score
	blt $s7, 10,  PrintSingleDigit
	blt $s7, 100,  PrintSecondDigit
DrawSeven:
	sw $t0, ($s0)
	sw $t0, 4($s0)
	sw $t0, 8($s0)
	sw $t0, 520($s0)
	sw $t0, 136($s0)
	sw $t0, 264($s0)
	sw $t0, 392($s0)
	lw $s7, score
	blt $s7, 10,  PrintSingleDigit
	blt $s7, 100,  PrintSecondDigit
DrawEight:
	sw $t0, ($s0)	
	sw $t0, 128($s0)
	sw $t0, 256($s0)
	sw $t0, 384($s0)
	sw $t0, 512($s0)
	sw $t0, 4($s0)
	sw $t0, 8($s0)
	sw $t0, 516($s0)
	sw $t0, 520($s0)
	sw $t0, 136($s0)
	sw $t0, 264($s0)
	sw $t0, 392($s0)
	sw $t0, 260($s0)
	lw $s7, score
	blt $s7, 10,  PrintSingleDigit
	blt $s7, 100,  PrintSecondDigit
DrawNine:
	sw $t0, ($s0)
	sw $t0, 4($s0)
	sw $t0, 8($s0)
	sw $t0, 128($s0)
	sw $t0, 136($s0)
	sw $t0, 256($s0)
	sw $t0, 260($s0)
	sw $t0, 264($s0)
	sw $t0, 392($s0)
	sw $t0, 512($s0)
	sw $t0, 516($s0)
	sw $t0, 520($s0)
	lw $s7, score
	blt $s7, 10,  PrintSingleDigit
	blt $s7, 100,  PrintSecondDigit

die:						#reset all registers
	li $v0, 0
	li $a0, 0
	li $a1, 0
	li $a2, 0
	li $a3, 0
	li $t0, 0
	li $t1, 0
	li $t2, 0
	li $t3, 0
	li $t4, 0
	li $t5, 0
	li $t6, 0
	li $t7, 0
	li $t8, 0
	li $t9, 0
	li $s0, 0
	li $s1, 0
	li $s2, 0
	li $s3, 0
	li $s4, 0		
	# play sound beep for dying
	li $v0, 31
	li $a0, 79
	li $a1, 150
	li $a2, 7
	li $a3, 127
	syscall	
	li $a0, 96
	li $a1, 250
	li $a2, 7
	li $a3, 127
	syscall

	j restart				

PlaySound:
	li $v0, 31
	li $a0, 28
	li $a1, 250
	li $a2, 32
	li $a3, 127
	syscall
		
	li $a0, 33
	li $a1, 250
	li $a2, 32
	li $a3, 127
	syscall
	
	li $a0, 23
	li $a1, 250
	li $a2, 32
	li $a3, 127
	syscall
	
	li $a0, 43
	li $a1, 250
	li $a2, 32
	li $a3, 127
	syscall
	
	li $a0, 36
	li $a1, 250
	li $a2, 32
	li $a3, 127
	syscall
	
	li $a0, 47
	li $a1, 250
	li $a2, 32
	li $a3, 127
	syscall
	
	li $a0, 28
	li $a1, 250
	li $a2, 32
	li $a3, 127
	syscall
		
	li $a0, 23
	li $a1, 250
	li $a2, 32
	li $a3, 127
	syscall
	
	li $a0, 33
	li $a1, 250
	li $a2, 32
	li $a3, 127
	syscall

	
	li $a0, 31
	li $a1, 250
	li $a2, 32
	li $a3, 127
	syscall
	
	li $a0, 28
	li $a1, 250
	li $a2, 32
	li $a3, 127
	syscall
		
	li $a0, 43
	li $a1, 250
	li $a2, 32
	li $a3, 127
	syscall
	
	li $a0, 63
	li $a1, 250
	li $a2, 32
	li $a3, 127
	syscall
	
	li $a0, 47
	li $a1, 250
	li $a2, 32
	li $a3, 127
	syscall
	
	li $a0, 32
	li $a1, 250
	li $a2, 32
	li $a3, 127
	syscall
	
	li $a0, 22
	li $a1, 250
	li $a2, 32
	li $a3, 127
	syscall
	
	li $a0, 31
	li $a1, 250
	li $a2, 32
	li $a3, 127
	syscall
	
	li $a0, 28
	li $a1, 250
	li $a2, 32
	li $a3, 127
	syscall
		
	li $a0, 33
	li $a1, 250
	li $a2, 32
	li $a3, 127
	syscall
	
	li $a0, 23
	li $a1, 250
	li $a2, 32
	li $a3, 127
	syscall
	
	li $a0, 43
	li $a1, 250
	li $a2, 32
	li $a3, 127
	syscall
	
	li $a0, 36
	li $a1, 250
	li $a2, 32
	li $a3, 127
	syscall	
	
	addi $k1, $zero, 0
	sw $k1, ($k0)
	j Check_Input

DrawMessage1:
	lw $t0, displayAddress			
	addi $s0, $t0, 1052
	li $t9, 0xff4777
	sw $t9, -128($s0)
	sw $t9, -120($s0)
	sw $t9, -112($s0)
	sw $t9, ($s0)
	sw $t9, 128($s0)
	sw $t9, 260($s0)
	sw $t9, 268($s0)
	sw $t9, 8($s0)
	sw $t9, 136($s0)
	sw $t9, 16($s0)
	sw $t9, 144($s0)
	addi $s0, $s0, 24
	sw $t9, ($s0)
	sw $t9, 128($s0)
	sw $t9, 256($s0)
	sw $t9, 384($s0)
	sw $t9, 4($s0)
	sw $t9, 8($s0)
	sw $t9, 392($s0)
	sw $t9, 388($s0)
	sw $t9, 136($s0)
	sw $t9, 264($s0)
	addi $s0, $t0, 1092
	li $t9, 0xff4777
	sw $t9, -128($s0)
	sw $t9, -120($s0)
	sw $t9, -112($s0)
	sw $t9, ($s0)
	sw $t9, 128($s0)
	sw $t9, 260($s0)
	sw $t9, 268($s0)
	sw $t9, 8($s0)
	sw $t9, 136($s0)
	sw $t9, 16($s0)
	sw $t9, 144($s0)
	li $v0, 4
	la $a0, Message1
	syscall
	j GameLoop
	
	
DrawMessage2:
	lw $t0, displayAddress			
	addi $s0, $t0, 924
	li $t9, 0xff4777
	sw $t9, ($s0)
	sw $t9, 4($s0)
	sw $t9, 8($s0)
	sw $t9, 128($s0)
	sw $t9, 256($s0)
	sw $t9, 384($s0)
	sw $t9, 260($s0)
	sw $t9, 264($s0)
	sw $t9, 136($s0)
	addi $s0, $s0, 16
	sw $t9, ($s0)
	sw $t9, 4($s0)
	sw $t9, 8($s0)
	sw $t9, 128($s0)
	sw $t9, 256($s0)
	sw $t9, 384($s0)
	sw $t9, 392($s0)
	sw $t9, 388($s0)
	sw $t9, 136($s0)
	sw $t9, 264($s0)
	addi $s0, $s0, 16
	sw $t9, ($s0)
	sw $t9, 4($s0)
	sw $t9, 8($s0)
	sw $t9, 128($s0)
	sw $t9, 256($s0)
	sw $t9, 384($s0)
	sw $t9, 388($s0)
	sw $t9, 392($s0)
	sw $t9, 264($s0)
	li $v0, 4
	la $a0, Message2
	syscall
	j GameLoop
DrawMessage3:
	lw $t0, displayAddress			
	addi $s0, $t0, 924
	li $t9, 0xff4777
	sw $t9, ($s0)
	sw $t9, 4($s0)
	sw $t9, 8($s0)
	sw $t9, 128($s0)
	sw $t9, 256($s0)
	sw $t9, 384($s0)
	sw $t9, 388($s0)
	sw $t9, 392($s0)
	sw $t9, 264($s0)
	addi $s0, $s0, 16
	sw $t9, ($s0)
	sw $t9, 4($s0)
	sw $t9, 8($s0)
	sw $t9, 128($s0)
	sw $t9, 256($s0)
	sw $t9, 384($s0)
	sw $t9, 392($s0)
	sw $t9, 388($s0)
	sw $t9, 136($s0)
	sw $t9, 264($s0)
	addi $s0, $s0, 16
	sw $t9, ($s0)
	sw $t9, 4($s0)
	sw $t9, 8($s0)
	sw $t9, 128($s0)
	sw $t9, 256($s0)
	sw $t9, 384($s0)
	sw $t9, 392($s0)
	sw $t9, 388($s0)
	sw $t9, 136($s0)
	sw $t9, 264($s0)
	addi $s0, $s0, 16
	sw $t9, ($s0)
	sw $t9, 4($s0)
	sw $t9, 128($s0)
	sw $t9, 256($s0)
	sw $t9, 384($s0)
	sw $t9, 388($s0)
	sw $t9, 136($s0)
	sw $t9, 264($s0)
	li $v0, 4
	la $a0, Message3
	syscall
	j GameLoop

	
DisplayName:
	lw $t0, displayAddress			
	addi $s0, $t0, 924
	li $t9, 0xff4777
	j FirstLetter

FirstLetter:
	addi $a1, $zero, 0
	la $t1, UserName
	lb $s1, ($t1)
	beq $s1, 'o', O
	beq $s1, 'l', L
	beq $s1, 'd', D
	beq $s1, 'g', G
	beq $s1, 'i', I
	beq $s1, 'p', P
	beq $s1, 'a', A
	beq $s1, 'c', C
	beq $s1, 'f', F
	beq $s1, 'h', H
	beq $s1, 's', S
	beq $s1, 't', T
	beq $s1, 'u', U
	beq $s1, 'v', V
	j O
SecondLetter:
	addi $s0, $s0, 16
	addi $a1, $zero, 4
	la $t1, UserName
	lb $s1, 1($t1)
	beq $s1, 'o', O
	beq $s1, 'l', L
	beq $s1, 'd', D
	beq $s1, 'g', G
	beq $s1, 'i', I
	beq $s1, 'p', P
	beq $s1, 'a', A
	beq $s1, 'c', C
	beq $s1, 'f', F
	beq $s1, 'h', H
	beq $s1, 's', S
	beq $s1, 't', T
	beq $s1, 'u', U
	beq $s1, 'v', V
	j L
ThirdLetter:
	addi $s0, $s0, 16
	addi $a1, $zero, 8
	la $t1, UserName
	lb $s1, 2($t1)
	beq $s1, 'o', O
	beq $s1, 'l', L
	beq $s1, 'd', D
	beq $s1, 'g', G
	beq $s1, 'i', I
	beq $s1, 'p', P
	beq $s1, 'a', A
	beq $s1, 'c', C
	beq $s1, 'f', F
	beq $s1, 'h', H
	beq $s1, 's', S
	beq $s1, 't', T
	beq $s1, 'u', U
	beq $s1, 'v', V
	j I
NextStep:
	bge $a1, 8, CheckInitialInput
	bge $a1, 4, ThirdLetter
	j SecondLetter			
O:
	sw $t9, ($s0)	
	sw $t9, 128($s0)
	sw $t9, 256($s0)
	sw $t9, 384($s0)
	sw $t9, 512($s0)
	sw $t9, 4($s0)
	sw $t9, 8($s0)
	sw $t9, 516($s0)
	sw $t9, 520($s0)
	sw $t9, 136($s0)
	sw $t9, 264($s0)
	sw $t9, 392($s0)
	j NextStep

I:	
	sw $t9, ($s0)	
	sw $t9, 128($s0)
	sw $t9, 256($s0)
	sw $t9, 384($s0)
	sw $t9, 512($s0)
	j NextStep

L:	
	sw $t9, ($s0)	
	sw $t9, 128($s0)
	sw $t9, 256($s0)
	sw $t9, 384($s0)
	sw $t9, 512($s0)
	sw $t9, 516($s0)
	sw $t9, 520($s0)
	j NextStep
	
P:	
	sw $t9, ($s0)
	sw $t9, 4($s0)
	sw $t9, 8($s0)
	sw $t9, 128($s0)
	sw $t9, 256($s0)
	sw $t9, 384($s0)
	sw $t9, 260($s0)
	sw $t9, 264($s0)
	sw $t9, 136($s0)
	j NextStep

G:	
	sw $t9, ($s0)
	sw $t9, 4($s0)
	sw $t9, 8($s0)
	sw $t9, 128($s0)
	sw $t9, 256($s0)
	sw $t9, 384($s0)
	sw $t9, 388($s0)
	sw $t9, 392($s0)
	sw $t9, 264($s0)
	j NextStep
D:	
	sw $t9, ($s0)
	sw $t9, 4($s0)
	sw $t9, 128($s0)
	sw $t9, 256($s0)
	sw $t9, 384($s0)
	sw $t9, 388($s0)
	sw $t9, 136($s0)
	sw $t9, 264($s0)
	j NextStep
H:
	sw $t9, ($s0)	
	sw $t9, 128($s0)
	sw $t9, 256($s0)
	sw $t9, 384($s0)
	sw $t9, 512($s0)
	sw $t9, 8($s0)
	sw $t9, 264($s0)	
	sw $t9, 136($s0)	
	sw $t9, 392($s0)	
	sw $t9, 520($s0)	
	sw $t9, 388($s0)
A:
	sw $t9, ($s0)
	sw $t9, 4($s0)	
	sw $t9, 128($s0)
	sw $t9, 256($s0)
	sw $t9, 384($s0)
	sw $t9, 512($s0)
	sw $t9, 8($s0)
	sw $t9, 264($s0)	
	sw $t9, 136($s0)	
	sw $t9, 392($s0)	
	sw $t9, 520($s0)	
	sw $t9, 388($s0)
	j NextStep
C:
	sw $t9, ($s0)	
	sw $t9, 128($s0)
	sw $t9, 256($s0)
	sw $t9, 384($s0)
	sw $t9, 512($s0)
	sw $t9, 4($s0)
	sw $t9, 8($s0)
	sw $t9, 516($s0)
	sw $t9, 520($s0)
	j NextStep
F:
	sw $t9, ($s0)	
	sw $t9, 128($s0)
	sw $t9, 256($s0)
	sw $t9, 384($s0)
	sw $t9, 512($s0)
	sw $t9, 4($s0)
	sw $t9, 8($s0)
	sw $t9, 260($s0)
	sw $t9, 264($s0)
	j NextStep

S:
	sw $t9, ($s0)
	sw $t9, 4($s0)
	sw $t9, 8($s0)
	sw $t9, 128($s0)
	sw $t9, 256($s0)
	sw $t9, 260($s0)
	sw $t9, 264($s0)
	sw $t9, 392($s0)
	sw $t9, 512($s0)
	sw $t9, 516($s0)
	sw $t9, 520($s0)
	j NextStep
T:
	sw $t9, ($s0)
	sw $t9, 8($s0)
	sw $t9, 4($s0)	
	sw $t9, 132($s0)
	sw $t9, 260($s0)
	sw $t9, 388($s0)
	sw $t9, 516($s0)
	j NextStep
U:
	sw $t9, ($s0)	
	sw $t9, 128($s0)
	sw $t9, 256($s0)
	sw $t9, 384($s0)
	sw $t9, 512($s0)
	sw $t9, 516($s0)
	sw $t9, 520($s0)
	sw $t9, 8($s0)	
	sw $t9, 136($s0)
	sw $t9, 264($s0)
	sw $t9, 392($s0)
	j NextStep
V:
	sw $t9, ($s0)	
	sw $t9, 128($s0)
	sw $t9, 256($s0)
	sw $t9, 384($s0)
	sw $t9, 516($s0)
	sw $t9, 8($s0)	
	sw $t9, 136($s0)
	sw $t9, 264($s0)
	sw $t9, 392($s0)
	j NextStep
exit: