### NewAnimation

**Category:**
New

**Syntax:**

```scorpionengine
NewAnimation Animation Frame=Expression Loop AutoFlip
```

**Description:**

Trigger an animation on the entity

Animation: The animation to play
Frame: The first frame
Loop: Loop until cancelled
AutoFlip: Try to flip the animation left/right automatically if needed

```scorpionengine

NewAnimation MyAnimation Frame=5*MyVar Loop AutoFlip

```
