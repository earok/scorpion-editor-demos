### Level

**Category:**
Level

**Syntax:**

```scorpionengine
Level Level Music=Expression MusicPos=Expression PanelTop=Expression PanelBottom=Expression Background=Expression NoFadeIn
```

**Description:**

Load and run a new level

Level: The Level to load
Music: The music to load
MusicPos: The position to start the music from (Protracker)
PanelTop: The top panel to load
PanelBottom: The bottom panel to load
Background: The background to load
NoFadeIn: Prevent automatic fade in

```scorpionengine

Level MyLevel Music=MyMusic MusicPos=5*MyVar PanelTop=MyTopPanel PanelBottom=MyBottomPanel PanelBackground=MyBottomPanel NoFadeIn

```
