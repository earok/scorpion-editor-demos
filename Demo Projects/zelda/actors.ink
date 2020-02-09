=== Link_Spawn ===
{ has_sword:
    ~player_type=link_sword
    ->GAME
}
{ has_shield:
    ~player_type=link_shield
}
->GAME

=== sword_pickup_spawn ===
//If we have the sword already, set to null
{ player_type == link_sword : 
    ~actor_type = null
}
-> GAME

=== sword_pickup_COLLISION ===
~actor_type = null
-> HAPPY_SOUND ->
~player_animation = link_pickup_sword
~player_type=link_sword
~has_sword=true
You found a sword!!!<br><br>You can now fight monsters.
-> GAME
