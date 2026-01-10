### ForEachActor

**Category:**
Conditional

**Syntax:**

```scorpionengine
ForEachActor Conditions Goto Label
```

**Description:**

Execute a codeblock on each actor of type (or all actors)

Conditions: A number of expressions such as X>5 separated by AND or OR
Goto: The Destination Label

```scorpionengine

ForEachActor 5 > MyVar1 AND 1 < MyVar2 MyLabel

```
