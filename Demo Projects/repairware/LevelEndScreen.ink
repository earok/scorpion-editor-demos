//The end screen
VAR End_AnyFails = false

=== endscreen ===
~ level = lvl_endscreen

//We're using "tunneling" (with an ending ->) because we want to return here

{ lvl1_success == false :
    ~ block_x = 4
    ~ block_y = 0
    -> removecorner ->
}
{ lvl2_success == false :
    ~ block_x = 8
    ~ block_y = 0
    -> removecorner ->
}
{ lvl3_success == false :
    ~ block_x = 4
    ~ block_y = 4
    -> removecorner ->
}
{ lvl4_success == false :
    ~ block_x = 8
    ~ block_y = 4
    -> removecorner ->
}

//If there are any fails, we want to show the try again panel
{ end_anyfails :
    ~ panel_bottom = tryagain
}
{ end_anyfails == false :
    ~ sound = snd_congrats
}

~ wait = wait_for5seconds
~ level = null
~ panel_bottom = null
-> startup

//If we didn't get this corner, remove it.
=== removecorner ===
~ end_anyfails = true
~ loop_counter_x = 0
~ loop_counter_y = 0

=== loopbeginning ===
{ loop_counter_y < 4:

    ~ block_type = blk_endscreenblank
    ~ block_x = block_x + 1
    ~ loop_counter_x = loop_counter_x + 1

    //End of this row
    { loop_counter_x >= 4:
        ~ block_x = block_x - 4
        ~ block_y = block_y + 1
        ~ loop_counter_x = 0
        ~ loop_counter_y = loop_counter_y + 1
    }
    
    -> loopbeginning
}

//Return back to where we were using ->->
->->
