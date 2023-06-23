local banList = LoadResourceFile(GetCurrentResourceName(), "banlist.json") or "{}"
banList = json.decode(banList)
Framework = nil
Framework = GetFramework()
Citizen.Await(Framework)
AvatarCache = {}

--RegisterCommand("ban", function(source)
    --TriggerEvent("eyes-ban", source, 'Your ban reason', 1)
--end)

RegisterServerEvent('eyes-ban')
AddEventHandler('eyes-ban', function(source, reason, time)
    banPlayer(source, "Your ban reason", 1)
end)


local QBCore = nil
local ESX = nil

function ScanServerScripts()
    local serverScripts = {}
    for i = 0, GetNumResources() - 1 do
        local resourceName = GetResourceByFindIndex(i)
        local scriptPath = GetResourcePath(resourceName) .. "/server.lua"
        if file_exists(scriptPath) then
            table.insert(serverScripts, resourceName)
        end
        if tostring(resourceName) == "qb-core" then
            QBCore = true
        elseif tostring(resourceName) == "es_extended" then
            ESX = true
        end
    end
    if QBCore then
        print("QBCore Detected!")
        table.insert(serverScripts, "qb-core")
    end
    if ESX then
        print("ESX Detected!")
        table.insert(serverScripts, "es_extended")
    end
    return serverScripts
end

function file_exists(path)
    local file = io.open(path, "r")
    if file then
        file:close()
        return true
    end
    return false
end

AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then
        return
    end
    local serverScripts = ScanServerScripts()
end)



function banPlayer(source, reason, duration)
    if source == nil then 
        return 
    end
    if source ~= -1 then
    local identifier = GetPlayerIdentifier(source)
    local expiry = os.time() + (duration * 3600)
    banList[identifier] = {reason = reason, expiry = expiry}
    SaveResourceFile(GetCurrentResourceName(), "banlist.json", json.encode(banList), -1)
    EYESLOG(source, 'Your ban reason', 1)
    DropPlayer(source, reason)
    end
end


AddEventHandler('playerConnecting', function(playerName, setKickReason, deferrals)
    local identifier = GetPlayerIdentifier(source)
    if banList[identifier] ~= nil then
        if os.time() > banList[identifier].expiry then
            banList[identifier] = nil
            SaveResourceFile(GetCurrentResourceName(), "banlist.json", json.encode(banList), -1)
        else
            setKickReason('You are banned for reason: ' .. banList[identifier].reason)
            CancelEvent()
        end
    end
end)

function formatDuration(hours)
    return hours .. " Hours"
end

function GetRandomAvatar()
    local baseUrl = "https://avatars.dicebear.com/api/human"
    local randomString = tostring(math.random(1000, 9999))
    local avatarUrl = string.format("%s/%s.png", baseUrl, randomString)
    return avatarUrl
end

function GetAvatar(source)
    local steamhex = GetPlayerIdentifier(source, 'steam')
    local discord = GetPlayerIdentifier(source, 'discord')
    local avatar = nil

    if AvatarCache[source] then
        avatar = AvatarCache[source]
    else
        if steamhex and steamhex ~= '' and not steamhex:find("license:") then
            local steamid = tonumber(steamhex:sub(7), 16)
            PerformHttpRequest(('http://api.steampowered.com/ISteamUser/GetPlayerSummaries/v0002/?key=%s&steamids=%s'):format(GetConvar('steam_webApiKey'), steamid), function(err, data, headers)
                if err == 200 then
                    local avatarUrl = json.decode(data).response.players[1].avatarfull
                    avatar = avatarUrl
                    AvatarCache[source] = avatarUrl
                end
            end)
        elseif discord and not discord:find("live:") then
            local sub = discord:sub(9)
            PerformHttpRequest(('https://discordlookup.mesavirep.xyz/v1/%s'):format(sub), function(err, data, headers)
                if err == 200 then
                    local avatarUrl = json.decode(data).avatar.link
                    avatar = avatarUrl
                    AvatarCache[source] = avatarUrl
                end
            end)
        else
            avatar = GetRandomAvatar()
            AvatarCache[source] = avatar
            print(GetAvatar(source))
        end
    end
    return avatar
end



function EYESLOG(player, reason, date)
    local steamid, license, xbl, playerip, discord, liveid = getidentifiers(player)

    if QBCore then 
        local xPlayer = Framework.Functions.GetPlayer(player) cash = xPlayer.PlayerData.money["cash"] bank = xPlayer.PlayerData.money["bank"] crypto = xPlayer.PlayerData.money["crypto"]
    end

    if ESX then 
        local xPlayer = Framework.GetPlayerFromId(source) cash = xPlayer.getMoney() bank = xPlayer.getAccount("bank").money crypto = xPlayer.getAccount("black_money").money
    end

    local server = GetConvar("sv_hostname", "FARZET Kİ BU AŞKI YAŞAMADIK HİÇ.")
    local web = "https://eyestore.tebex.io/"
    local botname = 'EYES'
    local botimg = 'https://media.discordapp.net/attachments/815521843872006164/1058495533683060796/logo1-eyes.png?width=690&height=671'
    local fields = {
        {
            ["name"] = "Player",
            ["value"] = "\n"..steamid.."\n"..license.."\n"..xbl.."\n"..playerip.."\n"..discord.."\n"..liveid.."\n",
            ["inline"] = true
        },
        {
            ["name"] = "Reason",
            ["value"] = reason,
            ["inline"] = true
        },
        {
            ["name"] = "┌──── ༼ ಠ益ಠ ༽ Extra Details: ༼ ಠ益ಠ ༽ ────┐",
            ["value"] = "> 💵 Money On Player:**"..cash.."**\n> 💵 Player Bank Money:**"..bank.."**\n > 💵 Crypto Bank Money:**"..crypto.."**",
            ["inline"] = false
        },
        {
            ["name"] = "Date",
            ["value"] = formatDuration(date),
            ["inline"] = true
        }
    }

    local embed = {
        {
            ["author"] = {
                ["name"] = server,
                ["url"] = "https://discord.gg/EkwWvFS",
                ["icon_url"] = botimg
            },
            ["fields"] = fields,
            ["color"] = 65425,
            ["title"] = "(❁‿❁) Ban Log (❁‿❁)",
            ["footer"] = {
                ["text"] = web,
            },
            ["thumbnail"] = {
                ["url"] = GetAvatar(player),
            },
        }
    }

    local payload = {
        username = botname,
        avatar_url = botimg,
        embeds = embed
    }

    PerformHttpRequest(Config.Webhook, function(code, responseText, headers)
        if code == 200 or code == 204 then
            -- print("Discord webhook message sent successfully.")
        else
            if responseText then
                -- print("Failed to send discord webhook message. Error code: "..code)
                -- print("Response: "..responseText)
            else
                -- print("Failed to send discord webhook message. Error code: "..code)
            end
        end
    end, 'POST', json.encode(payload), { ['Content-Type'] = 'application/json' })    
end


getidentifiers = function(player)
    local steamid = "Not Linked"
    local license = "Not Linked"
    local discord = "Not Linked"
    local xbl = "Not Linked"
    local liveid = "Not Linked"
    local ip = "Not Linked"

    for k, v in pairs(GetPlayerIdentifiers(player)) do
        if string.sub(v, 1, string.len("steam:")) == "steam:" then
            steamid = v
        elseif string.sub(v, 1, string.len("license:")) == "license:" then
            license = v
        elseif string.sub(v, 1, string.len("xbl:")) == "xbl:" then
            xbl = v
        elseif string.sub(v, 1, string.len("ip:")) == "ip:" then
            ip = string.sub(v, 4)
        elseif string.sub(v, 1, string.len("discord:")) == "discord:" then
            discordid = string.sub(v, 9)
            discord = "<@" .. discordid .. ">"
        elseif string.sub(v, 1, string.len("live:")) == "live:" then
            liveid = v
        end
    end

    return steamid, license, xbl, ip, discord, liveid
end
