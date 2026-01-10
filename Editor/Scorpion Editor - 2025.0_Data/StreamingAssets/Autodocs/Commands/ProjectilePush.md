### ProjectilePush

**Category:**
Projectile

**Syntax:**

```scorpionengine
ProjectilePush Frames X=Expression Y=Expression ResetMovement Decay
```

**Description:**

Push this entity a certain amount over a number of frames

Frames: The number of frames
X: The X coordinate
Y: The Y coordinate
ResetMovement: Resets Actor Movement to new type
Decay: Smoothly decays push

```scorpionengine

ProjectilePush 5 X=5*MyVar Y=5*MyVar ResetMovement Decay

```
