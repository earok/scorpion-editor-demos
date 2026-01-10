### SetTileProperty

**Category:**
Level

**Syntax:**

```scorpionengine
SetTileProperty True/False TileProperty X=Expression Y=Expression
```

**Description:**

Set the property of a tile

True/False: Only True or False accepted (defaults to True)
Tile Property: The tile property such as Solid, Platform, Spare or AIBlock
X: The X coordinate
Y: The Y coordinate

```scorpionengine

SetTileProperty False Solid X=5*MyVar Y=5*MyVar

```
