ESX = exports["es_extended"]:getSharedObject()

local DISCORD_WEBHOOK = "https://discord.com/api/webhooks/1434010308623470653/rRw4sDUTkxhqAGjFGbwr3GewqFQ1k6-soODGRmCHIrk1fVY6r3piPujF6CHL-6r9Ufcb"
local TIG_BUCKET = 555 -- ✅ instance de TIG

-- =============================
-- ENVOI DES LOGS DISCORD
-- =============================
local function sendToDiscord(title, message, color)
    if not DISCORD_WEBHOOK or DISCORD_WEBHOOK == "" then return end

    PerformHttpRequest(DISCORD_WEBHOOK, function() end, "POST", json.encode({
        username = "TIG Logs",
        embeds = {{
            title = title,
            description = message,
            color = color or 3066993
        }}
    }), { ["Content-Type"] = "application/json" })
end

-- =============================
-- COMMANDE MENU STAFF
-- =============================
RegisterCommand("tig", function(src)
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end

    -- Admin / mod
    if xPlayer.getGroup and (xPlayer.getGroup() == "admin" or xPlayer.getGroup() == "mod") then
        TriggerClientEvent('tig:openMenu', src)
        return
    end

    -- Police / sheriff
    if xPlayer.job and (xPlayer.job.name == "police" or xPlayer.job.name == "saspn") then
        TriggerClientEvent('tig:openMenu', src)
        return
    end

    TriggerClientEvent('esx:showNotification', src, "❌ Accès refusé.")
end)

-- =============================
-- STOP TIG MANUEL
-- =============================
RegisterCommand("stoptig", function(src, args)
    local staff = ESX.GetPlayerFromId(src)
    if not staff then return end

    if not args[1] then
        return TriggerClientEvent('esx:showNotification', src, "Usage : /stoptig [id]")
    end

    local targetId = tonumber(args[1])
    local target = ESX.GetPlayerFromId(targetId)
    if not target then
        return TriggerClientEvent('esx:showNotification', src, "Joueur introuvable.")
    end

    exports.oxmysql:update(
        "UPDATE users SET tig_tasks = 0, tig_zone = NULL, tig_reason = NULL WHERE identifier = ?",
        { target.identifier }
    )

    -- ✅ Retirer instance TIG
    SetPlayerRoutingBucket(target.source, 0)

    TriggerClientEvent('tig:forcedStop', targetId)

    sendToDiscord(
        "⛔ TIG retirées par staff",
        ("👮 Staff : **%s** (%s)\n🎯 Joueur : **%s** (%s)\nTIG annulées manuellement.")
        :format(staff.getName(), src, target.getName(), targetId),
        15105570
    )
end)

-- =============================
-- START TIG POUR UN JOUEUR
-- =============================
RegisterNetEvent('tig:startForPlayer')
AddEventHandler('tig:startForPlayer', function(playerId, tasks, reason, zone)
    local src = source
    local staff = ESX.GetPlayerFromId(src)
    local target = ESX.GetPlayerFromId(playerId)

    if not staff or not target then
        print("[TIG] Staff ou joueur introuvable")
        return
    end

    tasks = tonumber(tasks)

    exports.oxmysql:update(
        "UPDATE users SET tig_tasks = ?, tig_zone = ?, tig_reason = ? WHERE identifier = ?",
        { tasks, zone, reason, target.identifier }
    )

    -- ✅ Met le joueur en instance TIG
    SetPlayerRoutingBucket(target.source, TIG_BUCKET)

    TriggerClientEvent('tig:start', playerId, tasks, staff.getName(), reason, zone, false)

    sendToDiscord(
        "🛠️ TIG attribuées",
        ("👮 Staff : **%s** (%s)\n🎯 Joueur : **%s** (%s)\n🧹 Tâches : **%s**\n📍 Zone : **%s**\n📄 Raison : **%s**")
        :format(staff.getName(), src, target.getName(), playerId, tasks, zone, reason),
        15158332
    )
end)

-- =============================
-- UPDATE DU NOMBRE DE TIG RESTANT
-- =============================
RegisterNetEvent('tig:update')
AddEventHandler('tig:update', function(left)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end

    exports.oxmysql:update(
        "UPDATE users SET tig_tasks = ? WHERE identifier = ?",
        { left, xPlayer.identifier }
    )
end)

-- =============================
-- FIN TIG
-- =============================
RegisterNetEvent('tig:finished')
AddEventHandler('tig:finished', function()
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)

    exports.oxmysql:update(
        "UPDATE users SET tig_tasks = 0, tig_zone = NULL, tig_reason = NULL WHERE identifier = ?",
        { xPlayer.identifier }
    )

    -- ✅ Sortie instance, retour monde normal
    SetPlayerRoutingBucket(src, 0)

    sendToDiscord(
        "✅ TIG terminées",
        ("Le joueur **%s** (%s) a terminé toutes ses TIG ✅")
        :format(xPlayer.getName(), src),
        3066993
    )
end)

-- =============================
-- CHECK SI LE JOUEUR A DES TIG EN SE CONNECTANT
-- =============================
RegisterNetEvent('tig:checkResume')
AddEventHandler('tig:checkResume', function()
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end

    exports.oxmysql:single(
        "SELECT tig_tasks, tig_zone, tig_reason FROM users WHERE identifier = ?",
        { xPlayer.identifier },
        function(data)
            if data and data.tig_tasks and tonumber(data.tig_tasks) > 0 then

                -- ✅ Re-met le joueur dans l’instance TIG
                SetPlayerRoutingBucket(src, TIG_BUCKET)

                TriggerClientEvent('tig:start', src, data.tig_tasks, "Déconnexion", data.tig_reason, data.tig_zone, true)

                sendToDiscord(
                    "🔄 Reprise TIG",
                    ("Le joueur **%s** (%s) est revenu avec **%s TIG restantes**.")
                    :format(xPlayer.getName(), src, data.tig_tasks),
                    8421504
                )
            end
        end
    )
end)

-- =============================
-- LOG DÉCONNEXION AVEC TIG EN COURS
-- =============================
AddEventHandler('playerDropped', function()
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end

    exports.oxmysql:single(
        "SELECT tig_tasks FROM users WHERE identifier = ?",
        { xPlayer.identifier },
        function(data)
            if data and data.tig_tasks and tonumber(data.tig_tasks) > 0 then
                sendToDiscord(
                    "⚠️ Déconnexion en TIG",
                    ("Le joueur **%s** (%s) s'est déconnecté avec **%s TIG restantes**.")
                    :format(xPlayer.getName(), src, data.tig_tasks),
                    16753920
                )
            end
        end
    )
end)