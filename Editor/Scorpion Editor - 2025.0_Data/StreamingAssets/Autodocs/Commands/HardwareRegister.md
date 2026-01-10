### HardwareRegister

**Category:**
Variable

**Syntax:**

```scorpionengine
HardwareRegister Size VarName=Expression
```

**Description:**

ADVANCED. Peek or poke the bare metal.

Size: The variable size in Byte/Word/Long/Fraction
VarName: The variable name
Expression: The expression such as X+5

```scorpionengine

HardwareRegister Word MyVariable=5*5

```
