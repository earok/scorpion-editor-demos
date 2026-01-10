### Choice

**Category:**
Dialogue

**Syntax:**

```scorpionengine
Choice "Expression" Label Conditions
```

**Description:**

Configure a dialogue option for the player

Expression: A string expression such as "Hello World"
Label: The label name
Conditions: A number of expressions such as X>5 separated by AND or OR

```scorpionengine

Choice "Hello world" MyLabel 5 > MyVar1 AND 1 < MyVar2

```
