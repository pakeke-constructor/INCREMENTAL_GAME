

# XP BAR SYSTEM



## What gains XP? IDEAS:
- Destroying tokens (health = progress?)
- Destroying tokens (each token = progress) <-- a bit inconsistent

idea; have XP gain increase the longer you've been harvesting-for;
self-balancing.

Long time without XP-upgrade => more xp gain.

How do we deduce the "target time for level-up?"



## What happens when level up?
- Godray visual (megabonk-like)
- Choose between 3 stat-ups
- If upgrades available; go to map option highlighted (notification)


## TECHNICAL:
Where is XP stored? (Session)
How do we get XP cap? A: inside harvest-scene






### NOTES / RUBBER DUCK:
we will prooobably need to either store xp-requirement,
OR make it consistent.

If we iterate over `tokens`, then we risk having a different number when token dies.

2 SOLUTIONS:
- iterate over tokenPool, get exact maxHealth of tokens (robust, works with bosses)
- store the xp-requirement somewhere





