### PaletteSet

**Category:**
Palette

**Syntax:**

```scorpionengine
PaletteSet "FileName" PaletteFrom PaletteTo PaletteCount
```

**Description:**

Set a range of colors from a PNG

FileName: The relative file path
PaletteFrom: The source index of the palette operation
PaletteTo: The destination index of the palette operation
PaletteCount: The total number of colors to transfer

```scorpionengine

PaletteSet "MyFile.txt" 0 0 16

```
