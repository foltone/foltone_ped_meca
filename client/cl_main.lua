local pedCreatedTable = {}
local pedInAction = false;

local function createPed(model, pos, heading)
    modelPed = GetHashKey(model);
    RequestModel(modelPed)

    while not HasModelLoaded(modelPed) do
        Wait(1)
    end

    ped = CreatePed(0, modelPed, pos, heading, true)
    Wait(1000)
    SetBlockingOfNonTemporaryEvents(ped, 1)
    SetEntityInvincible(ped, true)
    FreezeEntityPosition(ped, true)

    table.insert(pedCreatedTable, ped)
end

local function helpMsg(text)
    BeginTextCommandDisplayHelp("STRING")
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayHelp(0, 0, 1, -1)
end

local function helpNotifcation(text)
    SetNotificationTextEntry("STRING")
    AddTextComponentString(text)
    DrawNotification(false, false)
end

local function openMenu()
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = "open",
    })
end

local function closeMenu()
    SetNuiFocus(false, false)
    SendNUIMessage({
        action = "close",
    })
end

RegisterNUICallback("action", function(data)
    closeMenu()
    choice(data)
end)

RegisterNUICallback("exit", function(data)
    closeMenu()
end)

local function findNearestVehicleSetPos(coords, heading)
    local veh = GetClosestVehicle(coords.x, coords.y, coords.z, 5.0, 0, 70)
    if veh ~= 0 then
        SetEntityCoords(veh, coords.x, coords.y, coords.z)
        SetEntityHeading(veh, heading)
        return veh
    end
end

local function lockVehicle(veh)
    FreezeEntityPosition(veh, true)
    SetVehicleUndriveable(veh, true)
    SetVehicleDoorsLocked(veh, 2)
    SetVehicleDoorsLockedForAllPlayers(veh, true)
    SetVehicleDoorsLockedForPlayer(veh, PlayerId(), true)
end

local function unlockVehicle(veh)
    FreezeEntityPosition(veh, false)
    SetVehicleUndriveable(veh, false)
    SetVehicleDoorsLocked(veh, 0)
    SetVehicleDoorsLockedForAllPlayers(veh, false)
    SetVehicleDoorsLockedForPlayer(veh, PlayerId(), false)
end

local function returnInitialPos(ped, pos, heading)
    TaskGoStraightToCoord(ped, pos, 1.0, 5000, 0.0, 0.0)
    while math.abs(GetEntityCoords(ped).x - pos.x) > 0.1 and math.abs(GetEntityCoords(ped).y - pos.y) > 0.1 do
        Citizen.Wait(500)
    end
    Wait(2000)
    SetEntityHeading(ped, heading)
    FreezeEntityPosition(ped, true)
end

local function repairEngine(ped, vehicle, initialCoords, initialHeading)
    lockVehicle(vehicle)

    if not DoesEntityExist(ped) then return end
    FreezeEntityPosition(ped, false)
    RequestAnimDict("mini@repair")
    while not HasAnimDictLoaded("mini@repair") do
        Citizen.Wait(0)
    end

    local engineCoords = GetWorldPositionOfEntityBone(vehicle, GetEntityBoneIndexByName(vehicle, "engine"))

    if engineCoords then
        TaskGoStraightToCoord(ped, engineCoords.x, engineCoords.y, engineCoords.z, 1.0, 5000, 0.0, 0.0)
        while math.abs(GetEntityCoords(ped).x - engineCoords.x) > 0.25 and math.abs(GetEntityCoords(ped).y - engineCoords.y) > 0.25 do
            Citizen.Wait(0)
        end

        SetVehicleDoorOpen(vehicle, 4, false, false)

        SetEntityHeading(ped, GetEntityHeading(vehicle) + 90.0)
        TaskPlayAnim(ped, "mini@repair", "fixing_a_ped", 8.0, -8, -1, 0, 0, false, false, false)
        local startAnim = GetGameTimer()
        while true do
            Citizen.Wait(0)
            if GetGameTimer() - startAnim >= 5000 then
                ClearPedTasksImmediately(player)
                break
            end
        end

        Wait(1000)

        unlockVehicle(vehicle)
        returnInitialPos(ped, initialCoords, initialHeading)
        SetVehicleFixed(vehicle)
        helpNotifcation(_U('vehicle_repaired'))
        pedInAction = false
    end
end

local function cleanVehicle(ped, vehicle, initialCoords, initialHeading)
    lockVehicle(vehicle)

    if not DoesEntityExist(ped) then return end
    FreezeEntityPosition(ped, false)

    local vehicleCoords = GetEntityCoords(vehicle)

    if vehicleCoords then
        TaskGoStraightToCoord(ped, vehicleCoords.x, vehicleCoords.y, vehicleCoords.z, 1.0, 5000, 0.0, 0.0)
        while math.abs(GetEntityCoords(ped).x - vehicleCoords.x) > 0.25 and math.abs(GetEntityCoords(ped).y - vehicleCoords.y) > 0.25 do
            Citizen.Wait(0)
        end

        SetEntityHeading(ped, GetEntityHeading(vehicle) + 90.0)
        TaskStartScenarioInPlace(ped, 'WORLD_HUMAN_MAID_CLEAN', 0, true)
        local startAnim = GetGameTimer()
        while true do
            Citizen.Wait(0)
            if GetGameTimer() - startAnim >= 10000 then
                ClearPedTasksImmediately(player)
                break
            end
        end

        Wait(1000)

        unlockVehicle(vehicle)
        returnInitialPos(ped, initialCoords, initialHeading)
        SetVehicleDirtLevel(vehicle, 0.0)
        helpNotifcation(_U('vehicle_cleaned'))
        pedInAction = false
    end
end

Citizen.CreateThread(function()
    for k, v in pairs(Config.list_ped_meca) do
        createPed(v.model, v.ped_pos, v.ped_heading);
        local blipPedMeca = AddBlipForCoord(v.ped_pos)
        SetBlipSprite(blipPedMeca, 402)
        SetBlipScale (blipPedMeca, 0.8)
        SetBlipColour(blipPedMeca, 47)
        SetBlipAsShortRange(blipPedMeca, true)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentSubstringPlayerName(_U('blip_name'))
        EndTextCommandSetBlipName(blipPedMeca)
    end
    while true do
        local wait = 500
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        for k, v in pairs(Config.list_ped_meca) do
            local distance = #(playerCoords - v.ped_pos)
            if not pedInAction then
                if distance < 1.5 then
                    wait = 0
                    helpMsg(_U('press_e'))
                    if IsControlJustPressed(0, 38) then
                        openMenu()
                        function choice(data)
                            for i, j in pairs(pedCreatedTable) do
                                if i == k then
                                    local vehicle = findNearestVehicleSetPos(v.vehicle_pos, v.vehicle_heading)
                                    if vehicle then
                                        if data == "repair" then
                                            pedInAction = true
                                            repairEngine(j, vehicle, v.ped_pos, v.ped_heading)
                                        elseif data == "clean" then
                                            pedInAction = true
                                            cleanVehicle(j, vehicle, v.ped_pos, v.ped_heading)
                                        else
                                            pedInAction = false
                                            print('error')
                                        end
                                    else
                                        helpNotifcation(_U('no_vehicle_nearby'))
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
        Citizen.Wait(wait)
    end
end)
