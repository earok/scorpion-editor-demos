//Level three is a "quick time event" type sewing game.
//There's no bobs - the level uses it's own palette. At no point is game control passed over to the scorpion game engine
//Everything is purely "ink script"

VAR Level3_Part = 0

=== level3 ===
~ lvl_timer_left = LevelTimeMax
~ level3_part = 0

//Select normal or flipped level
~ dice = 2
{ dice == 1:
    ~ level = lvl_sew
}
{ dice == 2:
    ~ level = lvl_sew2
}

=== level3_startloop ===
~ camera_y = Level3_Part * 144

{ Level3_Part == 0:
    { control1_x != 0:
        ~ Level3_Part = 1
    }
}

{ Level3_Part == 1:
    { control1_y < 0:
        ~ Level3_Part = 2
    }
}

{ Level3_Part == 2:
    { control1_x != 0:
        ~ Level3_Part = 3
    }
}

{ Level3_Part == 3:
    { control1_y < 0:
        -> level3_success //We've won this level
    }
}

~ lvl_timer_left = lvl_timer_left - 1
{ lvl_timer_left < 0:

    //Unload the level
    ~ level = null
    -> level4
}

// Wait for one frame to pass
~ wait = 1

 //Go back to the start of our timer loop
-> level3_startloop


=== level3_success ===
~ sound = snd_tada
~ camera_y = 144 * 4
~ wait = 25
~ camera_y = 144 * 5
~ wait = 25
~ camera_y = 144 * 4
~ wait = 25
~ camera_y = 144 * 5
~ wait = 25
~ level = null
~ lvl3_success = true
-> level4