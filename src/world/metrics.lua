


local metrics = {}


local validMetrics = {--[[
    [name] -> true
]]}



local storage = {}


function metrics.reset()
    storage = {}
end


function metrics.getMetric(name)
    return 
end


function metrics.defineMetric(name)

end


function metrics.setMetric(name, x)
    storage[name]=x
end



return metrics
