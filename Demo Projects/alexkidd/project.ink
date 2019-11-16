CONST Song_Start = 0
CONST Song_StageComplete = 16
CONST Song_Water = 17

CONST CheckpointNA = 0
CONST CheckpointLand = 1
CONST CheckpointWater = 2
VAR CheckpointType = 0
VAR CheckpointX = 0
VAR CheckpointY = 0
VAR Ammo = 0

=== Startup ===
~ yres = 192
~ checkpointtype = CheckpointNA
~ panel = pnl_title
~ wait = Wait_ForJoystick
~ panel = null

=== RestartLevel ===
~ music = song
~ musicpos = song_start
~ ammo = 0
~ camera_follow = camera_follow_down
~ level = level1

{ CheckpointType:
    ~ player_X = CheckpointX
    ~ player_Y = CheckpointY
    { CheckpointType == CheckpointWater:
        -> HitWater
    }
}
-> GAME

=== entered_checkpoint ===
{ player_Type == AlexKidd:
    ~ CheckpointType = CheckpointLand
}
{ player_Type == AlexKidd_Swim:
    ~ CheckpointType = CheckpointWater
}
~ CheckpointX = Block_X * 16 + 8
~ CheckpointY = Block_Y * 16 + 8
~ Block_Type = null
-> GAME

=== HitWater ===
{ player_Type == alexkidd :
    ~ musicpos = song_water
    ~ sound = sndwater
    ~ player_Type = alexkidd_swim
}
~camera_follow = camera_follow_down + camera_follow_right
-> GAME

=== alex_punch ===
{ ammo:
    ~ player_shoot = ringshot
    ~ ammo = ammo - 1
}
->GAME

=== player_kill ===
~music = null
~sound = snddie
~player_type = alexkidd_ghost
~yield = 100
-> RestartLevel

=== SpawnBrokenBlock ===
~ sound = sndblock
~ block_spawn = blockbreakleft
~ block_spawn = blockbreakright
->->

=== BreakBlock ===
-> SpawnBrokenBlock ->
{ block_type == MysteryContainer :
    ~ block_type = Ring
    -> GAME
}
{ block_type == StarContainer :
    ~ block_type = Money
    -> GAME
}
{ block_type == UnderwaterBurgerRock:
    ~ block_type = burger
    -> GAME
}
~ block_type = null
-> GAME

=== GetMoney ===
~ sound = sndcoin
~ block_type = null
-> GAME

=== GetRing ===
~ sound = sndcoin
~ ammo = 10
~ block_type = null
-> GAME

=== Kill_Enemy ===
~ sound = sndenemykill
~ actor_type = killpuff
-> GAME

=== merman_spawn ===
~ actor_var1 = 5
-> GAME

=== hit_merman ===
~ actor_var1 = actor_var1 - 1
{ actor_var1 < 1:
    -> Kill_Enemy    
}
-> GAME

=== finishlevel ===
~ musicpos = song_stagecomplete
~ level = null
-> StartUp
