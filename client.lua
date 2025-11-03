local TASK_DURATION = 5000
local EXIT_POS = vec3(441.2, -981.9, 30.7)

local doingTIG = false
local tasksLeft = 0
local currentZoneKey = 'parc'
local currentIndex = nil
local blip = nil
local currentTool = nil
local fxHandle = nil
local spawnedProps = {}

-- ==============================
-- ZONES (points complets)
-- ==============================
local ZONES = {
    ["parc"] = {
        name = "Parc",
        center = vec3(858.2722, -284.6886, 65.6310),
        radius = 100.0,
        tool = `prop_leafblower_01`,
        animDict = "amb@world_human_gardener_leaf_blower@idle_a",
        anim = "idle_c",
        ptfx = "ent_amb_leaf_blower",
        points = {
            vec3(860.7192, -268.5081, 65.8470),
            vec3(839.5956, -280.2518, 66.2897),
            vec3(865.2253, -304.6632, 65.6395),
            vec3(876.0044, -286.8268, 65.6313),
            vec3(876.2966, -279.3117, 65.4989),
            vec3(864.8482, -261.3160, 66.7198),
        }
    },
    ["dechetterie"] = {
        name = "Déchetterie",
        center = vec3(-194.5101, 6297.3750, 31.4889),
        radius = 130.0,
        tool = `prop_cs_rub_binbag_01`,
        animDict = "anim@heists@narcotics@trash",
        anim = "pickup",
        ptfx = "bulldozer_dust",
        points = {
            vec3(-191.5718, 6278.6846, 31.4893),
            vec3(-207.3866, 6275.1748, 31.4893),
            vec3(-206.6225, 6287.9863, 31.4902),
            vec3(-176.5922, 6291.7295, 31.4894),
            vec3(-169.7930, 6270.5293, 31.4895),
            vec3(-157.0884, 6257.4717, 31.4895),
        }
    },
    ["chantier"] = {
        name = "Chantier",
        center = vec3(101.4868, -367.9602, 42.4216),
        radius = 110.0,
        tool = `prop_tool_shovel`,
        animDict = "melee@large_wpn@streamed_core",
        anim = "ground_attack_on_spot",
        ptfx = "bulldozer_dust",
        points = {
            vec3(-124.3864, -1033.5822, 27.2734),
            vec3(-97.1495, -1048.3977, 27.4056),
            vec3(-120.3964, -1089.0852, 21.7037),
            vec3(-132.8170, -1063.5428, 21.6835),
            vec3(-159.0712, -1031.5077, 27.2742),
            vec3(-137.0398, -995.2112, 27.2752),
        }
    },
    ["plage"] = {
        name = "Plage",
        center = vec3(-1403.2, -1471.8, 4.4),
        radius = 120.0,
        tool = `prop_tool_broom`,
        animDict = "amb@world_human_janitor@male@idle_a",
        anim = "idle_a",
        ptfx = "bulldozer_dust",
        points = {
            vec3(-1399.1, -1465.0, 4.4),
            vec3(-1405.7, -1478.6, 4.4),
            vec3(-1412.8, -1469.3, 4.4),
            vec3(-1407.2, -1460.2, 4.4),
            vec3(-1410.6, -1473.4, 4.4),
            vec3(-1401.3, -1476.8, 4.4),
        }
    },
    ["prison"] = {
        name = "Prison",
        center = vec3(1679.7625, 2513.4128, 45.5649),
        radius = 160.0,
        tool = `prop_tool_broom`,
        animDict = "amb@world_human_janitor@male@idle_a",
        anim = "idle_a",
        ptfx = "bulldozer_dust",
        points = {
            vec3(1672.7382, 2537.5552, 45.5649),
            vec3(1719.7131, 2504.2673, 45.5649),
            vec3(1680.3037, 2481.0559, 45.5649),
            vec3(1646.5930, 2537.6206, 45.5649),
            vec3(1685.8192, 2553.1931, 45.5649),
            vec3(1708.6877, 2554.8008, 45.5649),
        }
    }
}

-- ==============================
-- Utils props/FX/outils
-- ==============================
local function stopEffects()
    if fxHandle then
        StopParticleFxLooped(fxHandle, false)
        fxHandle = nil
    end
    if currentTool and DoesEntityExist(currentTool) then
        DeleteObject(currentTool)
        currentTool = nil
    end
end

local function deleteTIGProps()
    for _, obj in ipairs(spawnedProps) do
        if DoesEntityExist(obj) then DeleteObject(obj) end
    end
    spawnedProps = {}
end

local function spawnTIGProps()
    deleteTIGProps()
    for _, pos in ipairs(ZONES[currentZoneKey].points) do
        local _, gz = GetGroundZFor_3dCoord(pos.x, pos.y, pos.z, false)
        local obj = CreateObject(`prop_rub_litter_03`, pos.x, pos.y, (gz or pos.z) - 0.05, true, true, false)
        PlaceObjectOnGroundProperly(obj)
        table.insert(spawnedProps, obj)
    end
end

-- ==============================
-- Blip & point
-- ==============================
local function setBlipAt(coords)
    if blip and DoesBlipExist(blip) then RemoveBlip(blip) end
    blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(blip, 1)
    SetBlipColour(blip, 5)
    SetBlipRoute(blip, true)
end

local function setNewPoint()
    local pts = ZONES[currentZoneKey].points
    if #pts == 0 then return end
    local new
    repeat new = math.random(#pts) until new ~= currentIndex
    currentIndex = new
    setBlipAt(pts[currentIndex])
end

-- ==============================
-- Fin TIG
-- ==============================
local function finishTIG()
    doingTIG = false
    deleteTIGProps()
    stopEffects()
    if blip and DoesBlipExist(blip) then RemoveBlip(blip) end

    DoScreenFadeOut(500); Wait(500)
    SetEntityCoords(PlayerPedId(), EXIT_POS)
    Wait(300); DoScreenFadeIn(300)

    lib.notify({ type='success', title='TIG', description='TIG terminées ✅' })
    TriggerServerEvent('tig:finished')
end

-- ==============================
-- Anim + outil + particules + son
-- ==============================
local function playWorkAnimation(zoneKey)
    local z = ZONES[zoneKey]
    local ped = PlayerPedId()

    stopEffects()

    RequestAnimDict(z.animDict)
    while not HasAnimDictLoaded(z.animDict) do Wait(0) end

    RequestModel(z.tool)
    while not HasModelLoaded(z.tool) do Wait(0) end

    local bone = 28422
    if zoneKey == 'dechetterie' or zoneKey == 'chantier' then bone = 57005 end

    currentTool = CreateObject(z.tool, 0.0, 0.0, 0.0, true, true, false)
    AttachEntityToEntity(currentTool, ped, GetPedBoneIndex(ped, bone),
        0.0, 0.0, 0.0,
        0.0, 0.0, 0.0,
        true, true, false, true, 1, true)

    TaskPlayAnim(ped, z.animDict, z.anim, 6.0, -6.0, TASK_DURATION, 1, 0, false, false, false)

    if z.ptfx then
        if not HasNamedPtfxAssetLoaded("core") then
            RequestNamedPtfxAsset("core")
            while not HasNamedPtfxAssetLoaded("core") do Wait(0) end
        end
        UseParticleFxAssetNextCall("core")
        fxHandle = StartParticleFxLoopedOnEntity(z.ptfx, currentTool, 0.0, 0.0, 0.0, 0,0,0, 0.8, false, false, false)
    end

    PlaySoundFrontend(-1, "SELECT", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)

    local breakChance = math.random(1, 45) == 2
    if breakChance then
        lib.progressBar({
            duration = TASK_DURATION,
            label = 'L’outil se casse...',
            canCancel = false,
            disable = { move = true, combat = true, car = true }
        })
        ClearPedTasks(ped)
        stopEffects()
        lib.notify({ type='error', title='Outil cassé', description='Tu dois changer d’outil !' })
    else
        lib.progressBar({
            duration = TASK_DURATION,
            label = 'Travail en cours...',
            canCancel = false,
            disable = { move = true, combat = true, car = true }
        })
        ClearPedTasks(ped)
        stopEffects()
    end
end

-- ==============================
-- Évents
-- ==============================
RegisterNetEvent('tig:start', function(count, staff, reason, zone, offline)
    doingTIG = true
    tasksLeft = tonumber(count or 0)
    currentZoneKey = zone or "parc"

    local data = ZONES[currentZoneKey]
    if not data then
        print("^1[TIG] Zone inconnue:", tostring(currentZoneKey))
        doingTIG = false
        return
    end

    if not offline then
        SetEntityCoords(PlayerPedId(), data.center)
    end

    spawnTIGProps()
    setNewPoint()

    lib.notify({
        type='inform',
        title='TIG',
        description=("Zone : %s\nTâches restantes : %s"):format(data.name, tasksLeft)
    })
end)

RegisterNetEvent('tig:forcedStop', function()
    doingTIG = false
    deleteTIGProps()
    stopEffects()
    if blip and DoesBlipExist(blip) then RemoveBlip(blip) end
    SetEntityCoords(PlayerPedId(), EXIT_POS)
    lib.notify({ type='inform', title='TIG', description='Tu as été retiré des TIG.' })
end)

AddEventHandler('playerSpawned', function()
    TriggerServerEvent('tig:checkResume')
end)

-- ==============================
-- Protections basiques
-- ==============================
CreateThread(function()
    while true do
        Wait(100)
        if doingTIG then
            local ped = PlayerPedId()
            SetEntityInvincible(ped, true)
            if GetEntityHealth(ped) < 150 then SetEntityHealth(ped, 200) end
        else
            SetEntityInvincible(PlayerPedId(), false)
        end
    end
end)

CreateThread(function()
    while true do
        Wait(0)
        if doingTIG then
            local ped = PlayerPedId()
            DisablePlayerFiring(ped, true)
            SetCurrentPedWeapon(ped, `WEAPON_UNARMED`, true)
            DisableControlAction(0, 24, true)
            DisableControlAction(0, 25, true)
            DisableControlAction(0, 37, true)
            DisableControlAction(0, 47, true)
            DisableControlAction(0, 140, true)
            DisableControlAction(0, 141, true)
            DisableControlAction(0, 142, true)
        end
    end
end)

-- ==============================
-- Boucle principale
-- ==============================
CreateThread(function()
    while true do
        local wait = 400

        if doingTIG and currentIndex then
            wait = 0
            local ped = PlayerPedId()
            local z = ZONES[currentZoneKey]
            local target = z.points[currentIndex]

            if #(GetEntityCoords(ped) - z.center) > z.radius then
                SetEntityCoords(ped, z.center, false, false, false, true)
                lib.notify({ type='error', title='TIG', description='Reste dans la zone !' })
            end

            local _, gz = GetGroundZFor_3dCoord(target.x, target.y, target.z, false)
            local mz = gz or target.z
            DrawMarker(1, target.x, target.y, mz, 0,0,0, 0,0,0, 0.8,0.8,0.8, 255,255,0,200, false, true, 2)

            if #(GetEntityCoords(ped) - vec3(target.x, target.y, mz)) < 1.5 then
                lib.showTextUI('[E] Travailler ici')

                if IsControlJustPressed(0, 38) then
                    lib.hideTextUI()

                    playWorkAnimation(currentZoneKey)

                    if spawnedProps[currentIndex] and DoesEntityExist(spawnedProps[currentIndex]) then
                        DeleteObject(spawnedProps[currentIndex])
                        spawnedProps[currentIndex] = nil
                    end

                    tasksLeft = tasksLeft - 1
                    TriggerServerEvent('tig:update', tasksLeft)

                    lib.notify({
                        type='success',
                        title='TIG',
                        description=('Tâche terminée ✅\nIl te reste %s TIG.'):format(tasksLeft),
                        duration = 4500
                    })

                    if tasksLeft <= 0 then
                        finishTIG()
                    else
                        setNewPoint()
                    end
                end
            else
                lib.hideTextUI()
            end
        end

        Wait(wait)
    end
end)

-- ==============================
-- Menu staff ox_lib (joueurs proches)
-- ==============================
RegisterNetEvent('tig:openMenu', function()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local radius = 20.0

    local players = lib.getNearbyPlayers(coords, radius)

    if #players == 0 then
        return lib.notify({
            type='error',
            title='TIG',
            description='Aucun joueur proche dans un rayon de 20m.'
        })
    end

    local options = {}
    for _, p in pairs(players) do
        -- ✅ Correction : ID serveur au lieu d’ID client
        local serverID = GetPlayerServerId(p.id)
        table.insert(options, {
            label = ("[%s] %s"):format(serverID, GetPlayerName(p.id)),
            value = serverID
        })
    end

    local input = lib.inputDialog('TIG - Staff', {
        { type='select', label='Joueur à sanctionner', options = options },
        { type='number', label='Tâches', default = 10 },
        { type='select', label='Zone', default='parc', options={
            {label='Parc', value='parc'},
            {label='Déchetterie', value='dechetterie'},
            {label='Chantier', value='chantier'},
            {label='Plage', value='plage'},
            {label='Prison', value='prison'},
        }},
        { type='input', label='Raison', default='Non respect des règles' }
    })

    if not input then return end

    local selectedPlayer = tonumber(input[1])
    local tasks  = tonumber(input[2])
    local zone   = input[3]
    local reason = input[4]

    if not selectedPlayer or not tasks or not zone then
        return lib.notify({ type='error', title='TIG', description='Champs invalides.' })
    end

    TriggerServerEvent('tig:startForPlayer', selectedPlayer, tasks, reason, zone)
    lib.notify({ type='success', title='TIG', description='TIG attribuées ✅' })
end)