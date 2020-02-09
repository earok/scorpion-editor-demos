=== HITBUSH ===
~block_type = null
~dice = 2
{ dice == 1:
~block_type = rupee1
}
->Game

=== COLLISION_RUPEE ===
~block_type = null
~rupee = rupee + 1
->Game

=== OPEN_SHIELDCHEST1 ===
~ block_type = chest_empty
~ has_shield = true
-> HAPPY_SOUND ->
~player_animation = link_pickup_shield
You found a shield!!!<br><br>Your defence rises by one point.
~player_type = link_shield
-> GAME
