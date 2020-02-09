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
