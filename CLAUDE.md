

# Project:
Catx11 is an incremental game made in lua, using love2d.
You are a coding assistant who writes extremely simple code, and is extremely concise.


## Core Game Loop:
Harvest resources in the world / harvest_scene.
Buy upgrades on the upgrade-tree. (upgrade_scene)

## Minor parts of game loop:
Occasionally, the player levels up, and can select a reward.

Late-game, the player may choose to summon the boss. If it kills (harvests) the boss-crop, the player will `prestige`.
Prestige will reset ALL upgrades, reset ALL resources (currency), and create a new upgrade tree. (Starting upgrade tree is defined as `prestige_0.json`.)



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
    - loads from `prestige_0.json`
- g.Tree.Upgrade: An entry on the upgrade-tree; (upgradeId, position, price: g.Bundle, maxLevel)

The `world` is an object that exists inside the harvest_scene, and is where all entities/tokens live.


## Event-buses, Question-buses:
How upgrades (and tokens) interact with the game. Defined in `src/ev_q_definitions.lua`.

**Events** = broadcast, no return value. `g.call("tokenDestroyed", tok)`
**Questions** = ask all upgrades, combine answers with a reducer. `g.ask("getTokenDamageMultiplier", tok)`

Reducers: `ADD` (sum all answers), `MULTIPLY` (multiply all answers), `PRIORITY`, `OR`, `AND`.

### Upgrade handlers get implicit args: `(uinfo, level, ...)`
Every event/question handler defined in an upgrade receives `uinfo` and `level` automatically, followed by the event's own args:
```lua
defUpgrade("crit_knives", "Critical Knives", {
    -- getValues: maps level -> values. Used for description AND game logic.
    getValues = function(uinfo, level) return level*2 end,
    valueFormatter = {"%d"},  -- formats getValues output for description
    description = "When a crop is {CRIT}Critically hit{/CRIT}, spawn %{1} knives!",
    -- %{1} replaced with formatted getValues()[1]
    -- (When crop is crit, Spawn {level*2} knives!)

    -- Event handler. Args: (uinfo, level, <event args...>)
    tokenCrit = function(uinfo, level, tok)
        local numKnives = uinfo:getValues(level)
        -- spawn knives ...
    end
})
```

`uinfo:getValues(level)` calls the upgrade's `getValues` function. Centralizes level-scaling so description and logic stay in sync.


## Architecture:
src/g.lua: All core functions stored here, >2000loc
src/scenes/*: All scenes defined here, in folders.
src/upgrades/**: All upgrades defined here. Multiple upgrades per file.
src/upgrades/tokens/**: All crops (tokens) defined here.
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
- IN ALL INTERACTIONS, BE EXTREMELY CONCISE, EVEN IF IT MEANS GRAMMATICAL INCORRECTNESS.
- You are working with a talented engineer who understands the codebase, if you need guidance or clarifications, ask.
- When writing code, write the simplest code possible. Aggressively avoid complexity.
- Before appending new code, consider whether it can be made simpler, or shortened. Proper error-handling and "best practices" are less important than short code.
- If a feature is too complex/adds too much code, ask the engineer for help/guidance.
- Try not to add more data structures, layers, or indirections. ALWAYS consider options before starting in case there is a simpler solution you missed.
</IMPORTANT-INSTRUCTIONS>




