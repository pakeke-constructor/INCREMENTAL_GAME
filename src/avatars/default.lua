g.defineCatAvatar("cat", "Happy Cat", {
    image = "happy_cat"
})
g.defineCatAvatar("business_cat", "Business Cat", {})
g.defineCatAvatar("evil_cat", "Evil Cat", {})
g.defineCatAvatar("grass_farmer_cat", "Grass Farmer Cat", {})
g.defineCatAvatar("lumberjack_cat", "Lumberjack Cat", {})


g.defineAvatarBackground("white", "White", {
    image = "1x1",
    upscale = consts.AVATAR_SIZE,
})
g.defineAvatarBackground("pink", "Pink", {
    image = "1x1",
    upscale = consts.AVATAR_SIZE,
    color = objects.Color("#".."FFDF28B5")
})


g.defineAvatarHat("farmer_hat", "Farmer Hat", {
    offsetY = 6
})