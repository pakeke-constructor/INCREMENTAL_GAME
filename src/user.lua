-- This is user management service.
-- Includes doing first-time (login) bonus, getting friend code, and entering friend code.

local asynchttp = require("src.modules.asynchttp.asynchttp")
local cosmetics = require("src.cosmetics.cosmetics")
local SteamTicket = require("src.steam.ticket")

local User = {}

local hasSubmittedCode = true
local friendCode = ""

function User.init()
    if not consts.ANALYTICS_URL or not Steam.getSteam() then
        return
    end

    SteamTicket.request(function(ticket, err)
        if ticket and err == "OK" then
            asynchttp.request(function(code, body)
                if code == 200 then
                    local jsondata = json.decode(body)
                    local steamid = assert(Steam.getSteam()).user.getSteamID()
                    assert(jsondata.steam_id == tostring(steamid), "?")
                    hasSubmittedCode = jsondata.has_used_code --[[@as boolean]]
                    friendCode = jsondata.friend_code --[[@as string]]

                    cosmetics.tryRefresh()
                end

                ticket:destroy()
            end, consts.ANALYTICS_URL.."/login", {
                headers = {
                    ["Content-Type"] = "application/json"
                },
                data = json.encode({
                    hexticket = ticket:getHexTicket()
                })
            })
        end
    end)
end

function User.canSubmitFriendCode()
    return not hasSubmittedCode
end

function User.getFriendCode()
    if #friendCode > 0 then
        return friendCode
    end
    return nil
end

---@param friendcode string
---@param callback fun(success:boolean,reason:string?)
function User.submitFriendCode(friendcode, callback)
    assert(User.canSubmitFriendCode(), "Check User.canSubmitFriendCode() first")

    SteamTicket.request(function(ticket, err)
        if ticket and err == "OK" then
            asynchttp.request(function(code, body)
                ticket:destroy()

                if code == 200 then
                    local jsondata = json.decode(body)
                    local steamid = assert(Steam.getSteam()).user.getSteamID()
                    assert(jsondata.steam_id == tostring(steamid), "?")
                    hasSubmittedCode = jsondata.has_used_code --[[@as boolean]]
                    friendCode = jsondata.friend_code --[[@as string]]
                    callback(true)
                else
                    local ok, jsondata = pcall(json.decode, body)
                    jsondata = ok and jsondata or {}
                    callback(false, jsondata.message)
                end
            end, consts.ANALYTICS_URL.."/referral", {
                headers = {
                    ["Content-Type"] = "application/json"
                },
                data = json.encode({
                    hexticket = ticket:getHexTicket(),
                    friend_code = friendcode,
                })
            })
        else
            callback(false)
        end
    end)
end

return User
