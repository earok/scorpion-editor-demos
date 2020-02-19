//In level one, we play as a spider and have to fix holes in the web
//The "holes" are static blocks that are painted at a random location on the web
//When the player overlaps with the hole, it deletes the hole 
//and instead spawns a short lived "webfix" object that simulates the hole being fixed

=== Level1 ===

//Load and play level 1 (spider)
~ lvl_score = 0
~ lvl_timer_left = LevelTimeMax
~ level = lvl_spider

//Roll four sided dice to determine which corner to make the hole in
~ dice = 4

{ dice == 1:
    //Set the block pointer to these co-ordinates, before running the "make holes" routine
    ~ block_x = 1
    ~ block_y = 1
    -> MakeHoles
}
{ dice == 2:
    ~ block_x = 13
    ~ block_y = 1
    -> MakeHoles
}
{ dice == 3:
    ~ block_x = 1
    ~ block_y = 6
    -> MakeHoles
}
{ dice == 4:
    ~ block_x = 13
    ~ block_y = 6
    -> MakeHoles
}
-> GAME


=== Spider_Update ===
~ lvl_timer_left = lvl_timer_left - 1
{ lvl_timer_left <= 0 : //Time up!
    
    
    //Did we fix all of the holes?   
    { lvl_score > 3 :
        ~ lvl1_success = true
    }

    ~ level = null //Unload this level, go to next level
    -> level2
}
-> GAME

=== HoleRepaired ===
~ lvl_score = lvl_score + 1 //We've earned one point
~ block_type = null //Destroy this hole block
~ block_spawn = webfix //Show fixing web animation
->GAME

//Routine to make four holes from selected block pointer co-ordinates, and then play the game
=== MakeHoles ===
~ block_type = blk_webhole
~ block_x = block_x + 1
~ block_type = blk_webhole
~ block_y = block_y + 1
~ block_type = blk_webhole
~ block_x = block_x - 1
~ block_type = blk_webhole
-> GAME

