

# Architecture:


## Overarching architecture: `HYBRID-OOP`
Each object has methods that can respond to events.  

Everything is an Object.
- Resources are objects,
- Particles are objects,
- UI are also objects...? <-- ensures that juice code works with UI too


Scenes: represent a "screen" that the player can be on.
    - Collection (represents a spatial-partitioned collection of objects)
    - UI-Elements

SceneManager -> responsible for navigating between scenes


## Services / Tools:
UpgradeService -> handles ALL upgrades, prestige, perks, etc etc.



## Specific Scenes:
Main-Menu: Scene, basic main menu.
Map: Scene object. Represents the world map
Skill-Tree: Scene object. Has a big skill-tree that can be modified
Forest-Zone: Scene object. Forest-zone where you can mine logs




## QUESTION:
How do we declare the UI layout??
```lua

function Scene:init()
    self.map = MapWidget()
end


```


