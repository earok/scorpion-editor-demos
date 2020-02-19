//Level 4, we have to fit a piece of a broken column into the larger column
VAR BigHandDelay = 0

=== level4 ===
~ level = lvl_column
~ bighanddelay = 0
-> GAME

=== bighand_update ===
~ bighanddelay = bighanddelay + 1

//Slows down hand and prevents it from moving while the level is starting
{ bighanddelay > 50 :

    ~ bighanddelay = bighanddelay - 2
    ~ player_x = player_x + 1  
    
    //End of the level
    { player_x >= 173 :
        
        ~ level = null
        
        //Bad ending?
        { player_y < 80 :
            -> level4_badending
        }
        { player_y > 88 :
            -> level4_badending
        }
        
        //Good ending
        ~ lvl4_success = true
        ~ sound = snd_heaven
        ~ panel = column_fix
        ~ wait = wait_for3seconds
        ~ panel = null
        -> endscreen
        
    }
}

-> GAME

=== level4_badending ===
~ sound = snd_collapse
~ panel = column_destroy
~ wait = wait_for3seconds
~ panel = null
-> endscreen
