=== Startup ===
VAR rupee=0
VAR has_sword=false
VAR has_shield=false

=== TITLE ===
~music = mod_intro
~panel = pic_title
~wait = 0
~panel = null
~music = null

=== GAMEMENU ===
~panel_bottom = null
~has_shield = false
~has_sword = false
~panel = main_menu
~wait = wait_forjoystick
~panel = null

{ option == 0 :
	-> PART1
}
{ option == 1 :
	~panel_bottom = hud
	-> PART2
}
{ option == 2 :
	~panel_bottom = hud
	~has_shield = true
	-> PART3
}
{ option == 3 :
	-> QUIT
}

=== PART1 ===
~music = mod_intro
~level = map_intro
~wait = 50
The Kingdom of Hyrule has been in peace since Link, the last knight of Hyrule, had defeated the malicious Ganon and reclaimed the precious triforce from him.

=== INTROLOOP1 ===
{ camera_x < 256 :
	~camera_x = camera_x + 2
	~wait = 1
	-> INTROLOOP1
}
Nobody knows what Link's wish to the triforce was, but it had the effect of reunifying the Light and Dark world, and awakening the 7 wise men's descendants.

=== INTROLOOP2 ===
{ camera_x < 512 :
	~camera_x = camera_x + 2
	~wait = 1
	-> INTROLOOP2
}
Next, Link handed the Triforce and Master Sword over to Princess Zelda, and people started to believe that peace would last.<5><br>But the people were wrong<3>.<3>.<3>.

=== INTROLOOP3 ===
{ camera_x < 768 :
	~camera_x = camera_x + 2
	~wait = 1
	-> INTROLOOP3
}
Unfortunately, Link's wish also had negative effects. Ganon and his henchmen were resurrected and got ready to attack.

=== INTROLOOP4 ===
{ camera_x < 1024 :
	~camera_x = camera_x + 2
	~wait = 1
	-> INTROLOOP4
}
Somewhere in Hyrule Forest, Link is sleeping without suspecting that Ganon has already moved into attack.<br><5>Until<3>.<3>.<3>.

=== GAMESTART ===
~music = null
~level = map_house_night
~camera_x = 320 - 256
~camera_y = 256 - 212
~wait = 50

//We want to move diagonally
//Back to the "0,0" camera position
=== CAMERALOOP ===

{ camera_y > 0 : 
	~camera_y = camera_y - 1
}

{ camera_x > 0 : 
	~camera_x = camera_x - 1
	~wait = 1
	-> CAMERALOOP
}

//We check this a second time, incase we still
//Need to move on the Y
{ camera_y :
	~wait = 1
	-> CAMERALOOP
}

Help me!<5><br>Help me!<5><br>It's me,<2> Zelda!<3><br>I'm talking to you by telepathy.
I am a prisoner in the dungeon of the castle!<br>
I need your help!<br>
Ganon is back, and he surely has already found the Triforce<3>.<3>.<3>.
Come quickly to the castle Link, you are my only hope<3>.<3>.<3>.
~wait = 50

=== PART2 ===
~level = map_bedroom
~panel_bottom = hud
~camera_follow = true

-> GAME


=== TRY_HOUSE_EXIT ===
{ has_shield == false :
	Don't go anywhere without your shield
	-> GAME
}

=== PART3 ===
~level = map_outside
-> GAME

=== ENTER_HOUSE ===
~teleport = housedoor
//Since we already have the shield, we can delete it
~ block_x = 15
~ block_y = 10
~ block_type = chest_empty
-> GAME

=== HAPPY_SOUND ===
~sound=snd_happy
->->

=== SIGNPOST ===
N: Link's Home<br>W: Hyrule Field<br>E: Forest Temple
-> GAME

=== QUIT ===
-> END
