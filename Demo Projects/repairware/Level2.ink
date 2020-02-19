//In level 2, we play as a cat and have to get into shelter
//You just need to move the cat to a certain position, and then you're done
//There's left/right flips of this level for variety

VAR RainTimer = 0
VAR RainOffset = 0

=== Level2 ===
//Load and play level 2 (cat)
//Select whether flipped or not
~ dice = 2

{ dice == 1:
    ~ level = lvl_cat
}
{ dice == 2:
    ~ level = lvl_cat2
}

//Set the rain color BEFORE fading in
-> AnimateRain ->

~ lvl_timer_left = LevelTimeMax
-> GAME

=== cat_update ===
//Animate the rain by poking the palette
~ raintimer = raintimer - 1
{ raintimer < 0 :
    ~ raintimer = 10
    -> AnimateRain ->
}

//If the cat has gotten to shelter
{ actor_type == cat:
    { level == lvl_cat:
        { actor_x < 64 :
            ~ actor_type = cat_happy
            ~ sound = snd_meow
        }
    }
    
    { level == lvl_cat2:
        { actor_x > 196 :
            ~ actor_type = cat_happy
            ~ sound = snd_meow            
        }
    }
}

//Count down the timer by one tick
~ lvl_timer_left = lvl_timer_left - 1
{ lvl_timer_left <= 0 : //Time up!
   
    
    //Did we get the cat to shelter?
    { actor_type == cat_happy :
        ~ lvl2_success = true
    }

    ~ level = null //Unload this level, go to next level
    -> level3
}

-> GAME

//ADVANCED palette manipulation. Changes two palette values and then returns to previous position
=== AnimateRain ===
{ rainoffset == 0:
    ~ rainoffset = 1
    ~ palette_pointer = 9
    ~ palette_value = 1400
    ~ palette_pointer = 3
    ~ palette_value = 0
    ->->
}

~ rainoffset = 0
~ palette_pointer = 9
~ palette_value = 0
~ palette_pointer = 3
~ palette_value = 1400
->->
