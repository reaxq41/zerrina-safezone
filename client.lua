local QBCore = exports['qb-core']:GetCoreObject()
local isInSafeZone = {} 
local uiState = false 

local onSafezone = true

CreateThread(function()
    while true do
        local player = PlayerId()
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        local newUiState = false 

        for index, v in pairs(Config.Bolgeler) do
            local distance = #(coords - v.coord)
            v.isInSafeZone = distance < v.radius
            isInSafeZone[index] = v.isInSafeZone

            if v.isInSafeZone then
                newUiState = false 

                SetEntityInvincible(ped, true)
                SetPlayerInvincible(player, true)
                SetPedCanBeKnockedOffVehicle(ped, false)

                if Config.DisableDriveBy then
                    SetPlayerCanDoDriveBy(player, false)
                end
            
                if Config.AntiVDM then
                    local vehicle = GetVehiclePedIsIn(ped, false)
                    if IsEntityAVehicle(vehicle) then
                        SetEntityNoCollisionEntity(vehicle, ped, true)
                    end
                end
            
                if Config.LimitSpeed then
                    local vehicle = GetVehiclePedIsIn(ped, false)
                    if IsEntityAVehicle(vehicle) then
                        local currentSpeed = GetEntitySpeed(vehicle)
                        local safezonespeed = Config.maxSafeZoneSpeed / 3.6
                        local maxSpeedMps = safezonespeed * 1.05 
                        if currentSpeed > maxSpeedMps then
                            SetEntityMaxSpeed(vehicle, maxSpeedMps)
                        end
                    end
                end    
            
                local myJob = QBCore.Functions.GetPlayerData().job.name
                if Config.DisableDrawWeapon and not IsWhitelistedJob(myJob) then
                end
            else
                SetEntityInvincible(ped, false)
                SetPlayerInvincible(player, false)
                SetPedCanBeKnockedOffVehicle(ped, true)
                local vehicle = GetVehiclePedIsIn(ped, false)
                if IsEntityAVehicle(vehicle) then
                    SetEntityCollision(vehicle, true, true)
                end
            end
        end

        if newUiState ~= uiState then
            setUiShow(newUiState)
            uiState = newUiState
        end

        Wait(500)
    end
end)

CreateThread(function()
    while true do
        local isInAnySafeZone = false
        for _, v in pairs(isInSafeZone) do
            if v then
                isInAnySafeZone = true
                break
            end
        end

        if isInAnySafeZone then
            if Config.DisablePunching then
                DisableControlAction(0, 140, true)
                DisableControlAction(0, 141, true)
                DisableControlAction(0, 142, true)
            end

            if Config.DisableFreeAim then
                DisableControlAction(0, 25, true)
            end

            if Config.DisableShooting then
                DisablePlayerFiring(PlayerId(), true)
            end
        end
        Wait(0)
    end
end)

for _, v in pairs(Config.Bolgeler) do
    local blip = AddBlipForRadius(v.coord.x, v.coord.y, v.coord.z, v.radius)
    SetBlipHighDetail(blip, true)
    SetBlipColour(blip, 2)
    SetBlipAlpha(blip, 128)
end

function setUiShow(bool)
    SendNUIMessage({
        type = "show",
        show = bool
    })
end

function IsWhitelistedJob(job)
    for _, whitelistedJob in pairs(Config.WhitelistedJobs) do
        if job == whitelistedJob then
            return true
        end
    end
    return false
end

local function notifySafeZoneEntry(isEntering)
    if isEntering then
        QBCore.Functions.Notify("Güvenli bir bölgeye girdiniz.", "success")
    else
        QBCore.Functions.Notify("Güvenli bölgeden çıktınız.", "error")
    end
end

CreateThread(function()
    while true do
        Citizen.Wait(1)

        local isInAnySafeZone = false
        for _, v in pairs(isInSafeZone) do
            if v then
                isInAnySafeZone = true
                break
            end
        end

        if isInAnySafeZone then
            if not onSafezone then
                onSafezone = true
                notifySafeZoneEntry(true) -- Notify entering safe zone
            end

            local player = PlayerId()
            local playerPed = PlayerPedId()
            SetEntityInvincible(playerPed, true)
            SetPlayerInvincible(player, true)
            SetPedCanBeKnockedOffVehicle(playerPed, false)

            local carros = GetGamePool("CVehicle")
            for i = 1, #carros, 1 do
                local veh = GetVehiclePedIsIn(playerPed, false)
                if veh ~= 0 then
                    SetEntityNoCollisionEntity(carros[i], veh, true)
                else
                    SetEntityNoCollisionEntity(carros[i], playerPed, true)
                end
            end

            for _, i in ipairs(GetActivePlayers()) do
                if i ~= PlayerId() then
                    local closestPlayerPed = GetPlayerPed(i)
                    SetEntityNoCollisionEntity(closestPlayerPed, playerPed, true)
                end
            end
        else
            if onSafezone then
                onSafezone = false
                notifySafeZoneEntry(false) -- Notify exiting safe zone
            end

            local playerPed = PlayerPedId()
            local vehicle = GetVehiclePedIsIn(playerPed, false)
            SetEntityInvincible(playerPed, false)
            SetPlayerInvincible(PlayerId(), false)
            SetPedCanBeKnockedOffVehicle(playerPed, true)

            if IsEntityAVehicle(vehicle) then
                SetEntityNoCollisionEntity(vehicle, playerPed, false)
            end
        end
    end
end)

local function isSafezone()
    return onSafezone
end
exports('isSafezone', isSafezone)

CreateThread(function()
    while true do
        Citizen.Wait(0)

        local playerPed = PlayerPedId()
        local weapon = GetSelectedPedWeapon(playerPed)

        
        if weapon == `WEAPON_UNARMED` then
            -- Disable punch actions
            DisableControlAction(0, 140, true) -- Melee attack
            DisableControlAction(0, 141, true) -- Additional punch control
            DisableControlAction(0, 142, true) -- Additional punch control

            -- Disable R key when not in a vehicle
            if not IsPedInAnyVehicle(playerPed, false) then
                DisableControlAction(0, 45, true) -- R key control code
            end
        end
    end
end)

CreateThread(function()
    while true do
        if PlayerPedId() ~= lastped then
            lastped = PlayerPedId()
            SetPedCanLosePropsOnDamage(PlayerPedId(), false, 0)
        end
        Wait(100)
    end
end)


CreateThread(function()
    while true do
        Citizen.Wait(0)
        local ped = PlayerPedId()
        local weapon = GetSelectedPedWeapon(ped)
      
        if IsPedArmed(ped, 6) then
            DisableControlAction(1, 140, true)
            DisableControlAction(1, 141, true)
            DisableControlAction(1, 142, true)
        end
      
      
        if weapon == GetHashKey("WEAPON_FIREEXTINGUISHER") then     
            if IsPedShooting(ped) then
                SetPedInfiniteAmmo(ped, true, GetHashKey("WEAPON_FIREEXTINGUISHER"))
            end
        end
    end
end)

local function isSafezone()
    return onSafezone
end
exports('isSafezone', isSafezone)