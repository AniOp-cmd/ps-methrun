local QBCore = exports['qb-core']:GetCoreObject() 

local Itemtime = 300 * 1000 -- 5 minutes
local Carspawn = vector3(3814.76, 4461.75, 3.6)
local VehicleCoords = nil
local CurrentCops = 0


CreateThread(function()
    Wait(1000)
    if QBCore.Functions.GetPlayerData().job ~= nil and next(QBCore.Functions.GetPlayerData().job) then
        PlayerJob = QBCore.Functions.GetPlayerData().job
    end
end)

RegisterNetEvent('police:SetCopCount', function(amount)
    CurrentCops = amount
end)


Citizen.CreateThread(function()
	MethPed()
end)

function MethPed()
  RequestModel(GetHashKey('g_m_m_mexboss_01'))
  while not HasModelLoaded(GetHashKey('g_m_m_mexboss_01')) do
  Wait(1)
  end
  methboss = CreatePed(2, GetHashKey('g_m_m_mexboss_01'), 481.18, -591.21, 23.75, 299.77, false, false) -- change here the cords for the ped 
  SetPedFleeAttributes(methboss, 0, 0)
  SetPedDiesWhenInjured(methboss, false)
  TaskStartScenarioInPlace(methboss, "WORLD_HUMAN_STAND_IMPATIENT", 0, true)
  SetPedKeepTask(methboss, true)
  SetBlockingOfNonTemporaryEvents(methboss, true)
  SetEntityInvincible(methboss, true)
  FreezeEntityPosition(methboss, true)
end

--- Target Stuff
CreateThread(function()
    exports['qb-target']:AddTargetModel('g_m_m_mexboss_01', {
        options = {
            { 
                type = "client",
                event = "ps-methrun:client:start",
                icon = "fas fa-circle",
                label = "Get Job ($1500)",
            },
            { 
                type = "client",
                event = "ps-methrun:client:reward",
                icon = "fas fa-circle",
                label = "Check Product",
                item = 'meth_cured',
            },
        },
        distance = 3.0 
    })
    ---
    exports['qb-target']:AddTargetModel('prop_security_case_01', {
        options = {
            {
                type = 'client',
                event = "ps-methrun:client:items",
                icon = "fas fa-circle",
                label = "Grab Goods",
                item = 'casekey',            
            },
        },
        distance = 2.5
    })
end)
---Phone msgs
function RunStart()
	Citizen.Wait(2000)
	TriggerServerEvent('qb-phone:server:sendNewMail', {
	sender = "Unknown",
	subject = "Vehicle Location",
	message = "Updated your gps with the location to a vehicle I got a tip about that contains a briefcase. Retrieve whats inside it and bring it back to me. I've given you a special key that would be used to remove the first layer of security on the case.",
	})
	Citizen.Wait(3000)
end

function Itemtimemsg()
    Citizen.Wait(2000)
	TriggerServerEvent('qb-phone:server:sendNewMail', {
	sender = "Unknown",
	subject = "Goods Collection",
	message = "Looks like you got the goods, the case should unlock automatically 5 minutes you unlocked the first layer of security on it. Once completed bring back the items to me and get paid.",
	})
    Citizen.Wait(Itemtime)
    TriggerServerEvent('QBCore:Server:RemoveItem', "securitycase", 5)
    TriggerEvent("inventory:client:ItemBox", QBCore.Shared.Items["securitycase"], "remove")
    TriggerServerEvent('QBCore:Server:AddItem', "meth_cured", 20)
    TriggerEvent("inventory:client:ItemBox", QBCore.Shared.Items["meth_cured"], "add")
    QBCore.Functions.Notify("Security case has been unlocked.", "success")
end
---
RegisterNetEvent('ps-methrun:client:start', function ()
    if CurrentCops >= Config.MinimumMethJobPolice then
        QBCore.Functions.TriggerCallback("ps-methrun:server:coolc",function(isCooldown)
            if not isCooldown then
                TriggerEvent('animations:client:EmoteCommandStart', {"idle11"})
                QBCore.Functions.Progressbar("start_job", "Talking to boss..", 10000, false, true, {
                    disableMovement = true,
                    disableCarMovement = true,
                    disableMouse = false,
                    disableCombat = true,
                }, {
                }, {}, {}, function() -- Done
                    TriggerEvent('animations:client:EmoteCommandStart', {"c"})
                    TriggerServerEvent('QBCore:Server:AddItem', "casekey", 1)
                    TriggerEvent("inventory:client:ItemBox", QBCore.Shared.Items["casekey"], "add")
                    TriggerServerEvent('ps-methrun:server:startr')
                    TriggerServerEvent('ps-methrun:server:coolout')

                end, function() -- Cancel
                    TriggerEvent('animations:client:EmoteCommandStart', {"c"})
                    QBCore.Functions.Notify("Canceled..", "error")
                end)
            else
                QBCore.Functions.Notify("Someone recently did this, try again later..", "error")
            end
        end)
    else
        QBCore.Functions.Notify("Cannot do this right now...", "error")
    end
end)

RegisterNetEvent('ps-methrun:server:runactivate')
AddEventHandler('ps-methrun:server:runactivate', function()
RunStart()
local DrawCoord = 1
if DrawCoord == 1 then
VehicleCoords = Carspawn
end
RequestModel(GetHashKey('slamvan2'))
while not HasModelLoaded(GetHashKey('slamvan2')) do
Citizen.Wait(0)
end
SetNewWaypoint(VehicleCoords.x, VehicleCoords.y)
ClearAreaOfVehicles(VehicleCoords.x, VehicleCoords.y, VehicleCoords.z, 15.0, false, false, false, false, false)
transport = CreateVehicle(GetHashKey('slamvan2'), VehicleCoords.x, VehicleCoords.y, VehicleCoords.z, 52.0, true, true)
--
SpawnGuards()
spawncase()
end)

function spawncase()
    local case = CreateObject(GetHashKey("prop_security_case_01"), 3828.87, 4471.85, 3.0, true,  true, true)
    CreateObject(case)
    SetEntityHeading(case, 176.02)
    FreezeEntityPosition(case, true)
    SetEntityAsMissionEntity(case)
    case = AddBlipForEntity(case)
    SetBlipSprite(case, 586)
    SetBlipColour(case, 2)
    SetBlipFlashes(case, false)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString('Case')
    EndTextCommandSetBlipName(case)
end

methguards = {
    ['npcguards'] = {}
}

function loadModel(model)
    if type(model) == 'number' then
        model = model
    else
        model = GetHashKey(model)
    end
    while not HasModelLoaded(model) do
        RequestModel(model)
        Citizen.Wait(0)
    end
end

function SpawnGuards()
    local ped = PlayerPedId()

    SetPedRelationshipGroupHash(ped, GetHashKey('PLAYER'))
    AddRelationshipGroup('npcguards')

    for k, v in pairs(Config['methguards']['npcguards']) do
        loadModel(v['model'])
        methguards['npcguards'][k] = CreatePed(26, GetHashKey(v['model']), v['coords'], v['heading'], true, true)
        NetworkRegisterEntityAsNetworked(methguards['npcguards'][k])
        networkID = NetworkGetNetworkIdFromEntity(methguards['npcguards'][k])
        SetNetworkIdCanMigrate(networkID, true)
        SetNetworkIdExistsOnAllMachines(networkID, true)
        SetPedRandomComponentVariation(methguards['npcguards'][k], 0)
        SetPedRandomProps(methguards['npcguards'][k])
        SetEntityAsMissionEntity(methguards['npcguards'][k])
        SetEntityVisible(methguards['npcguards'][k], true)
        SetPedRelationshipGroupHash(methguards['npcguards'][k], GetHashKey("npcguards"))
        SetPedAccuracy(methguards['npcguards'][k], 75)
        SetPedArmour(methguards['npcguards'][k], 100)
        SetPedCanSwitchWeapon(methguards['npcguards'][k], true)
        SetPedDropsWeaponsWhenDead(methguards['npcguards'][k], false)
        SetPedFleeAttributes(methguards['npcguards'][k], 0, false)
        GiveWeaponToPed(methguards['npcguards'][k], GetHashKey('WEAPON_PISTOL'), 255, false, false)
        local random = math.random(1, 2)
        if random == 2 then
            TaskGuardCurrentPosition(methguards['npcguards'][k], 10.0, 10.0, 1)
        end
    end

    SetRelationshipBetweenGroups(0, GetHashKey("npcguards"), GetHashKey("npcguards"))
    SetRelationshipBetweenGroups(5, GetHashKey("npcguards"), GetHashKey("PLAYER"))
    SetRelationshipBetweenGroups(5, GetHashKey("PLAYER"), GetHashKey("npcguards"))
end

RegisterNetEvent("ps-methrun:client:items")
AddEventHandler('ps-methrun:client:items', function()
    QBCore.Functions.TriggerCallback('QBCore:HasItem', function(result)
        if result then
            TriggerEvent("qb-dispatch:methjob")
            exports["memorygame_2"]:thermiteminigame(8, 3, 2, 20,
            function() -- Success
                TriggerEvent('animations:client:EmoteCommandStart', {"type3"})
                QBCore.Functions.Progressbar("grab_case", "Unlocking case..", 10000, false, true, {
                    disableMovement = true,
                    disableCarMovement = true,
                    disableMouse = false,
                    disableCombat = true,
                }, {
                }, {}, {}, function() -- Done
                    TriggerEvent('animations:client:EmoteCommandStart', {"c"})
                    RemoveBlip(case)
                    TriggerServerEvent('QBCore:Server:AddItem', "securitycase", 1)
                    TriggerEvent("inventory:client:ItemBox", QBCore.Shared.Items["securitycase"], "add")
                    TriggerServerEvent('QBCore:Server:RemoveItem', "casekey", 1)
                    TriggerEvent("inventory:client:ItemBox", QBCore.Shared.Items["casekey"], "remove")

                    local playerPedPos = GetEntityCoords(PlayerPedId(), true)
                    local case = GetClosestObjectOfType(playerPedPos, 10.0, GetHashKey("prop_security_case_01"), false, false, false)
                    if (IsPedActiveInScenario(PlayerPedId()) == false) then
                    SetEntityAsMissionEntity(case, 1, 1)
                    DeleteEntity(case)
                    QBCore.Functions.Notify("You removed the the first layer of security on the case", "success")
                    Itemtimemsg()
                end
                end, function()
                    TriggerEvent('animations:client:EmoteCommandStart', {"c"})
                    QBCore.Functions.Notify("Cancelled..", "error")
                end)
            end,
            function() -- Fail thermite game
                QBCore.Functions.Notify("You failed!")
            end)
        else
            QBCore.Functions.Notify("You cannot do this..", "error")
        end

    end, "casekey")
end)

RegisterNetEvent("ps-methrun:client:reward")
AddEventHandler('ps-methrun:client:reward', function()
    QBCore.Functions.TriggerCallback('QBCore:HasItem', function(result)
        if result then
            TriggerEvent('animations:client:EmoteCommandStart', {"suitcase2"})
            QBCore.Functions.Progressbar("product_check", "Checking Quality", 7000, false, true, {
                disableMovement = true,
                disableCarMovement = true,
                disableMouse = false,
                disableCombat = true,
            }, {
            }, {}, {}, function() -- Done
                TriggerEvent('animations:client:EmoteCommandStart', {"c"})
                ClearPedTasks(PlayerPedId())
                TriggerServerEvent('QBCore:Server:RemoveItem', "meth_cured", 1)
                TriggerEvent("inventory:client:ItemBox", QBCore.Shared.Items["meth_cured"], "remove")
                local MethChance = math.random(1,1000)
                if MethChance <= Config.MethChance then
                    TriggerServerEvent("ps-methrun:server:givemeth")
                elseif MethChance <= Config.SpecialRewardChance then
                    TriggerServerEvent("ps-meth:server:giveitemreward")
                else
                    TriggerServerEvent("ps-methrun:server:givemoney")
                end
                
                QBCore.Functions.Notify("You got paid", "success")
            end, function()
                TriggerEvent('animations:client:EmoteCommandStart', {"c"})
                QBCore.Functions.Notify("Cancelled..", "error")
            end)
        else
            QBCore.Functions.Notify("You cannot do this..", "error")
        end
    end, "meth_cured")
end)


