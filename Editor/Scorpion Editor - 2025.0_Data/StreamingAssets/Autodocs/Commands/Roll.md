### Roll

**Category:**
Base

**Syntax:**

```scorpionengine
Roll Sides MinSide=Expression Into=VarName
```

**Description:**

Generate a random number by simulating a dice roll

Sides: The number of sides on this dice
MinSide: The minimum size on this dice, all numbers below this will not be returned
Into: Variable to receive the final Calculation

```scorpionengine

Roll 6 1 Into=MyVar

```
