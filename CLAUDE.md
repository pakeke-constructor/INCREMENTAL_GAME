

# Project:
Catx11 is an incremental game made in lua, using love2d.
You are a coding assistant who is extremely concise and effective.


## Game loop:
Harvest resources in the world / harvest_scene.
Buy upgrades on the upgrade-tree. (upgrade_scene)



## Systems/Components:
- Resources: money, fabric, bread, fish. Like a currency. Money is the main resource. `g.Resources` is a type {[resourceId] -> number}
- g.stats: Represent the player's stats, like HitDamage, HitSpeed. Recalculated every frame.
- Tokens: represent crops in the world to be harvested (includes chests, bonus-crops)
    - `g.defineToken`
    - Every token has a corresponding upgrade
    - Most tokens yield resources when destroyed
- Entities: things in the world that aren't crops. E.g. spinning axes, lightning strikes, particles
    - `g.defineEntity`
- Upgrades: Upgrades have an effect on harvesting. The same upgrade can be placed multiple times on the same tree, with different pricing, and different max-level.
    - `g.defineUpgrade`
- g.Tree: the upgrade tree
- g.Tree.Upgrade: An entry on the upgrade-tree; (upgradeId, position, price: g.Bundle, maxLevel)

The `world` is an object that exists inside the harvest_scene, and is where all entities/tokens live.


## Event-buses, Question-buses:
How control flow is propagated to tokens and especially upgrades.
eg:
```lua
g.call("tokenDestroyed", tok) -- event

-- and an upgrade:
g.defineUprade("test", {
    tokenDestroyed = function()
        g.addMoney(1)
    end,
    description = "When a crop is harvested, earn $1!"
})
```
Questions need to return a value; which is combined with all other questions (usually multiplication or addition).

`src/ev_q_definitions.lua`: Where all questions/events are defined


## Architecture:
src/g.lua: All core functions stored here, >2000loc
src/scenes/*: All scenes defined here, in folders.
src/upgrades/**: All upgrades defined here. Multiple upgrades per file.
src/modules/*: Extra modules (analytics, lighting, richtext, typechecking)
src/world/*: Stuff to do with the world (used by harvest_scene)
src/entities/*: Entities defined here
src/rewards/*: XP rewards for level-up
src/Session.lua: Represents a game-session (ie a game-save)
src/consts.lua: Constants.


## Agent directions:
The codebase is rather large; >20k LOC.
*USE CHEAP EXPLORE AGENTS IF POSSIBLE.*


# IMPORTANT AGENT INSTRUCTIONS:
<IMPORTANT-INSTRUCTIONS>
- You are working with a talented engineer who understands the codebase, if you need guidance or clarifications, ask.
- In all interactions, be extremely concise, even if it means grammatical incorrectness.
- When writing code, write the simplest code possible. Aggressively avoid complexity.
- Before appending new code, consider whether it can be made simpler, or shortened. Proper error-handling and "best practices" are less important than short code.
- If a feature is too complex/adds too much code, ask the engineer for help/guidance.
</IMPORTANT-INSTRUCTIONS>




