-> Startup

//Warning: Do not change this file

//`# Virtual Machine Registers and predefined functions
//`
//`There are several predefined Scorpion script variables that have particular side effects when set.
//`
//`These are the "hardware registers" of the virtual machine.
//`
//`## Actor Registers
//`
//`In all variable listings underneath, "actor_" is a pointer to the active actor
//`
//`For example, if an actor has a "divert_playercollision" setting in project.txt, then "actor_" refers to the actor that has been collided with
//`
//`"player_" is a pointer to the currently active player
//`
//`"playerprojectile_" is a pointer to the currently active player projectile

//`
//`### Actor_X | Actor_Y | Player_X | Player_Y | PlayerProjectile_X | PlayerProjectile_Y
//`*Read | Write*
//`
//``~ Actor_X = 5`
//`
//`Set or get the absolute X or Y position of an actor in the level.
//`
VAR Player_x = 0

//`
//`### Actor_Shoot | Player_Shoot | PlayerProjectile_Shoot
//`*Write*
//`
//``~ Player_Shoot = Player_Bullets`
//`
//`Spawns another actor facing the same direction as the player.
//`
VAR Player_shoot = 0

//Simply get or set where the player is on the y axis
VAR Player_y = 0

//`
//`### Actor_Spawn | Player_Spawn | PlayerProjectile_Spawn
//`*Write*
//`
//``~ Player_Spawn = Bomb`
//`
//`Spawns another actor. Simplar to _Shoot, but does not change the actor's default direction.
//`
VAR Player_spawn = 0

//`
//`### Actor_XSpeed | Actor_YSpeed | Player_XSpeed | Player_YSpeed | Player_ProjectileXSpeed | Player_ProjectileYSpeed
//`*Read | Write*
//`
//``{ Player_XSpeed > 0 :`
//`
//`Gets or sets the actor's X or Y speed. 
//`Note that this value is rounded down to the nearest whole number. While Scorpion internally supports floating points for movement, the virtual machine currently does not.
//`
VAR Player_xspeed = 0

//`
//`### Actor_XPush | Actor_YPush | Player_XPush | Player_YPush | Player_ProjectileXPush | Player_ProjectileYPush
//`*Write*
//`
//``~ Actor_XPush = 255`
//`
//`Pushes an actor by a specified amount, respecting collisions.
//`
//`If there's only one digit, the actor will be moved immediately by that amount.
//`But if there's two digits (as per the example), the second digit is movement speed in pixels/frame, and all of the others are the total movement amount.
//`So in the above example, the actor will be pushed a total of 25 pixels over 5 frames.
//`
VAR Player_xpush = 0

//Get or set the current move speed of the player on the yaxis
VAR Player_yspeed = 0

//As per x-push but on the y-axis
VAR Player_ypush = 0

//`
//`### Actor_Animation | Player_Animation | Player_ProjectileAnimation
//`*Write*
//`
//``~ Actor_Animation = DeathAnimation`
//`
//`Set an actor's animation.
//`
//``~ Actor_Animation = TriggerAttack_Animation`
//`
//`The above value is a special setting, that sets the actor to play it's attack animation for it's current direction
//`
VAR Player_animation = 0

//`
//`### Actor_LookDir | Player_LookDir | PlayerProjectile_LookDir
//`*Read | Write*
//`
//``~ Actor_LookDir = Look_UpLeft`
//`
//`Get or set the direction the actor is looking in.
//`
VAR Player_lookdir = 0

//`
//`### Actor_Type | Player_Type | PlayerProjectile_Type
//`*Read | Write*
//`
//``~ Actor_Chest = Actor_ChestItem`
//`
//`Get or set the current type of actor.
//`
//`Note that this will NOT trigger the spawn divert.
//`
VAR Player_type = 0

//`
//`### Actor_Var1-Actor_Var5 | Player_Var1-Player_Var5 | PlayerProjectile_Var1-PlayerProjectile_Var5
//`*Read | Write*
//`
//``~ Actor_Var1 = EnemyHealth`
//`
//`The Var1-Var5 variables are used as generic containers for each actors. They could be used for health, lives, ammo etc
VAR Player_var1 = 0
VAR Player_var2 = 0
VAR Player_var3 = 0
VAR Player_var4 = 0
VAR Player_var5 = 0

VAR Actor_x = 0
VAR Actor_shoot = 0
VAR Actor_y = 0
VAR Actor_spawn = 0
VAR Actor_xspeed = 0
VAR Actor_xpush = 0
VAR Actor_yspeed = 0
VAR Actor_ypush = 0

VAR Actor_animation = 0
VAR Actor_lookdir = 0
VAR Actor_type = 0
VAR Actor_var1 = 0
VAR Actor_var2 = 0
VAR Actor_var3 = 0
VAR Actor_var4 = 0
VAR Actor_var5 = 0

VAR PlayerProjectile_x = 0
VAR PlayerProjectile_shoot = 0
VAR PlayerProjectile_y = 0
VAR PlayerProjectile_spawn = 0
VAR PlayerProjectile_xspeed = 0
VAR PlayerProjectile_xpush = 0
VAR PlayerProjectile_yspeed = 0
VAR PlayerProjectile_ypush = 0

VAR PlayerProjectile_animation = 0
VAR PlayerProjectile_lookdir = 0
VAR PlayerProjectile_type = 0
VAR PlayerProjectile_var1 = 0
VAR PlayerProjectile_var2 = 0
VAR PlayerProjectile_var3 = 0
VAR PlayerProjectile_var4 = 0
VAR PlayerProjectile_var5 = 0

//`
//`### Actor_ShootAtPlayer
//`*Write*
//`
//``~ Actor_ShootAtPlayer = Enemy_Projectile`
//`
//`Fires at the player - but only if facing in the same direction. Only valid for Actor pointer (not Player or PlayerProjectile)
//`
VAR Actor_ShootAtPlayer = 0

//`
//`## Other Registers
//`

//`### Camera_X | Camera_Y
//`*Read | Write*
//`
//``~ Camera_X = 5`
//`
//`Set the camera X or Y to an absolute value. Note that this automatically disables camera following.
VAR Camera_X = 0
VAR Camera_Y = 0

//`### Camera_XMin | Camera_XMax | Camera_YMin | Camera_YMax
//`*Read | Write*
//`
//``~ Camera_XMin = 15`
//`
//`Set the min and max follow bounds of the camera. Reset when loading a level.
//`
VAR Camera_XMin = 0
VAR Camera_YMin = 0
VAR Camera_XMax = 0
VAR Camera_YMax = 0

//`### Y_Resolution
//`*Read | Write*
//`
//``~ YRes = 212`
//`
//`Set the Y Resolution of the game area
//`Cannot exceed 212 pixels, but can be as low as you need it to be
VAR Yres = 212

//`### Wait
//`*Write*
//`
//``~ Wait = 50`
//`
//`Set this to make the game wait for X number of frames. Useful for basic scrolling cutscenes
//`
//`Set to 0 in order to wait until the use presses joystick fire. Useful for static screens and menus.
//`
VAR Wait = 0

//`### Dice
//`*Read | Write*
//`
//```
//`~ Dice = 6
//`{ Dice == 6:
//`-> RolledASix
//`}
//```
//`Set this to generate a random number. Eg, "~dice = 6" will simulate a dice roll.
//`Afterwards, you can then get this to retrieve the generated number
VAR dice = 0

//`### Level
//`*Write*
//`
//``~ Level = Level1`
//`
//`Set this to load and play a level  (must be declared in project.txt)
//`
VAR Level = 0

//`### Music
//`*Write*
//`
//``~ Music = Song1`
//`
//`Set this to load and play a music file (must be declared in project.txt)
//`
VAR Music = 0

//`### MusicPos
//`*Write*
//`
//``~ MusicPos = 10`
//`
//`Jumps to a specific position in a currently playing song.
//`
VAR MusicPos = 0

//`### Sound
//`*Write*
//`
//``~ Sound = SFXShoot`
//`
//`Set this to play a specific sound effect (must be declared in project.txt)
//`
VAR Sound = 0

//`### Anim
//`*Write*
//`
//``~ Anim = IntroAnimation`
//`
//`Set this to load and play an ANIM5 animation
//`
VAR Anim = 0

//`### Talkpad
//`*Read | Write*
//`
//``~ Talkpad = Talkpad_main`
//`
//`Set the current panel for printing to. Leave as 0 to print to AmigaDOS.
//`
VAR Talkpad = 0

//`### Talkpad_TextDelay
//`*Write*
//`
//``~ Talkpad_TextDelay = 5`
//`
//`Set the number of frames to delay between each character when there is text being displayed on the talkpad
//`
VAR Talkpad_TextDelay = 1

//`### Panel
//`*Write*
//`
//``~ Panel = MainMenu`
//`
//`Set a panel that takes over the 'center' of the display (where the game is normally displayed)
//`
VAR Panel = 0

//`### Panel_Top
//`*Write*
//`
//``~ Panel_Top = TopHUD`
//`
//`Set a panel that takes over the top of the display
//`
VAR Panel_Top = 0

//`### Panel_Bottom
//`*Write*
//`
//``~ Panel_Bottom = TopHUD`
//`
//`Set a panel that takes over the bottom of the display
//`
VAR Panel_Bottom = 0

//`### Option
//`*Read*
//`
//```
//`~ Panel = MainMenu
//`~ Wait = 0
//`{ Option == 0:
//`-> StartGame
//`}
//`{ Option == 1:
//`-> EndGame
//`}
//```
//`
//`Get this to retrieve the currently selected option on a menu panel
//`
VAR Option = 0

//`### Block_Type
//`*Read | Write*
//`
//``~ BlockType = Null`
//`
//`Get or set the block under the block pointer. Set to null to delete it.
//`
VAR Block_Type = 0

//`### Block_Spawn
//`*Write*
//`
//``~ Block_Spawn = Null`
//`
//`Spawn an actor on the current block pointer.
//`
VAR Block_Spawn = 0

//`### Block_X | Block_Y
//`*Read | Write*
//`
//``~ Block_X = 0`
//`
//`Get or set the current block pointer position on the map, in tile co-ordinates
//`
//`The block pointer can be set manually, but is automatically set after a block divert is called (such as divert_playercollision in project.txt for a block)
//`
VAR Block_X = 0
VAR Block_Y = 0

//`### Control1_X | Control1_Y
//`*Read*
//`
//``{ Control1_X > 0 : //If the joystick is being held left...`
//`
//`The current joystick axes
VAR Control1_X = 0
VAR Control1_Y = 0

//`### Control1_Fire
//`*Read*
//`
//``{ Control1_Fire : //If the joystick button is being pressed`
//`
//`If the fire buttons for joystick 1 have been pressed
VAR Control1_Fire = 0

//`### Control1_FireHit
//`*Read*
//`
//``{ Control1_FireHit : //If the joystick button has just been pressed`
//`
//`Similar to above, but is only true on the first frame that fire is hit
VAR Control1_FireHit = 0

//`### Yield
//`*Write*
//`
//``~ Yield = 50`
//`
//`The same as 'wait', except yield also allows the game logic and animation to continue after X number of frames have passed
//`
//`Useful for animated cutscenes
VAR Yield = 0

//`### Teleport
//`*Write*
//`
//``~ Teleport = TeleportEventLocation`
//`
//`Teleport the player to a defined teleport event. This works across levels as well as inside levels.
//`
VAR Teleport = 0

//`### ForceFadeOut
//`*Read | Write*
//`
//``~ ForceFadeOut = True`
//`
//`Set to true to Force the screen to fade out. Set back to false to let the screen fade back in.
//`
VAR ForceFadeOut = 0

//`### Camera_Follow
//`*Write*
//`
//``~ Camera_Follow = false`
//`
//`Set to true for the camera to follow the player, false for the camera to be static
//`
//`The camera can be restrained. In the following example, the camera only flows down and right
//`
//``~ Camera_Follow = Camera_Follow_Right + Camera_Follow_Down`
VAR Camera_Follow = -1

//`### Param
//`*Read*
//`
//```
//`{ Param == 2 :
//`-> Level2 
//`}
//```
//`
//`This is a value set by command line. Eg, 'game.exe 5' would set Param to 5. Useful for testing and development.
VAR Param = 0

//`### framewait
//`*Write*
//`
//``~ framewait = 1`
//`
//`Sets the fludity of your engine. 
//`
//`1. 50 frames per second
//`2. 25 frames per second
//`3. 12.5 frames per second
//`etc.
//`
//`Higher values will allow you to render more on screen at once without skips, but at the cost of a less fluid game.
//`This does NOT affect the fluidity of Anim5 animations or static screens, only the core game.
//`
VAR FrameWait = 1

CONST true = -1
CONST false = 0
CONST null = 0

CONST look_upleft = 0
CONST look_up = 1
CONST look_upright = 2

CONST look_left = 3
CONST look_center = 4
CONST look_right = 5

CONST look_downleft = 6
CONST look_down = 7
CONST look_downright = 8

CONST Camera_Follow_Left = 1
CONST Camera_Follow_Right = 2
CONST Camera_Follow_Up = 4
CONST Camera_Follow_Down = 8

CONST Trigger_Attack_Animation = -1

//`
//`## Standard Functions
//`

//`### Snap_To_Screen
//`
//``-> Snap_To_Screen`
//`
//`Predefined function for keeping the current actor within the screen space
//`
=== snap_to_screen ===
{ actor_x <= camera_x + 16:
	~actor_x = camera_x + 16
}
{ actor_x >= camera_x + 256 + 16:
	~actor_x = camera_x + 256 + 16
}
{ actor_y <= camera_y + 16:
	~actor_y = camera_y + 16
}
{ actor_y >= camera_y + yres + 16:
	~actor_y = camera_y + yres + 16
}
-> Game

//`### destroy_actor
//`
//``-> destroy_actor`
//`
//`Predefined function for destroying the current actor
//`
=== destroy_actor ===
~ actor_type = null
-> Game

//`### destroy_block
//`
//``-> destroy_block`
//`
//`Predefined function for destroying the current block
//`
=== destroy_block ===
~ block_type = null
-> Game

=== game ===
-> Game

=== end ===
-> End

//`
//`
//`# [Back to Table of Contents](../README.md)