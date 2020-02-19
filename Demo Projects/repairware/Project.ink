//Our constants
 //Five seconds max per level
CONST LevelTimeMax = 50 * 5

//Our variables
VAR LVL1_Success = false
VAR LVL2_Success = false
VAR LVL3_Success = false
VAR LVL4_Success = false
VAR LVL_Timer_Left = 0
VAR LVL_Score = 0
VAR loop_counter_x = 0
VAR loop_counter_y = 0

//The start of our program
=== Startup ===
//The Y Resolution is only 144!
~ yres = 144

//No camera following
~ camera_follow = 0

~ lvl1_Success = false
~ lvl2_success = false
~ lvl3_success = false
~ lvl4_success = false

//Load the title screen
~ panel = title
~ sound = snd_repair

//Wait for the user to press fire
~ wait = wait_forjoystick

//Unload the title screen
~ panel = null

//Start level 1
-> level1

//Back to the start
-> startup

