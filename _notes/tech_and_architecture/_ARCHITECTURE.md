

# Architecture:

World: ECS-world; each Zone has a world.
- Resources are entities,
- Particles are entities,
- (Even UI are entities...? (<-- juice code works with UI too..?))

Scenes: represent a "screen" that the player can be on.
    -> (Scenes contain ECS worlds)

SceneManager -> responsible for navigating between scenes



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








