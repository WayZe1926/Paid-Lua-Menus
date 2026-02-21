local isSpawning = false 
local hasRun = false 


function GetClosestPlayer()
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local closestPlayer = -1
    local closestDistance = math.huge

    for _, playerId in ipairs(GetActivePlayers()) do
        if playerId ~= PlayerId() then -- Exclude the local player
            local targetPed = GetPlayerPed(playerId)
            if DoesEntityExist(targetPed) and NetworkIsPlayerActive(playerId) then
                local targetCoords = GetEntityCoords(targetPed)
                local distance = #(playerCoords - targetCoords)
                if distance < closestDistance then
                    closestDistance = distance
                    closestPlayer = playerId
                end
            end
        end
    end

    return closestPlayer
end


function ForceDeleteAllPeds(spawnedPeds, pedModel)
    for _, ped in ipairs(spawnedPeds) do
        if DoesEntityExist(ped) then
            DeleteEntity(ped)
        end
    end
    if pedModel then
        SetModelAsNoLongerNeeded(pedModel)
    end
end


function SpawnPedsAtPlayer2()
    if isSpawning or hasRun then return end
    isSpawning = true
    hasRun = true

    local playerPed = PlayerPedId()
    local selectedPlayer = GetClosestPlayer()

    if selectedPlayer == -1 then
        isSpawning = false
        hasRun = false
        return
    end

    local targetPed = GetPlayerPed(selectedPlayer)

    if DoesEntityExist(targetPed) and targetPed ~= playerPed and NetworkIsPlayerActive(selectedPlayer) then
        local pedModel = GetHashKey("cs_wade")
        RequestModel(pedModel)
        while not HasModelLoaded(pedModel) do
            Citizen.Wait(100)
        end

        local spawnedPeds = {}
        local maxPedsPerBatch = 5
        local maxIterations = 22

        for i = 0, maxIterations - 1 do
            targetPed = GetPlayerPed(selectedPlayer)
            if not DoesEntityExist(targetPed) or not NetworkIsPlayerActive(selectedPlayer) then
                ForceDeleteAllPeds(spawnedPeds, pedModel)
                break
            end

            local coords = GetEntityCoords(targetPed)
            if not coords then
                ForceDeleteAllPeds(spawnedPeds, pedModel)
                break
            end

            for j = 1, maxPedsPerBatch do
                local offsetX = math.random(-3.0, 3.0)
                local offsetY = math.random(-3.0, 3.0)
                local foundGround, groundZ = GetGroundZFor_3dCoord(coords.x + offsetX, coords.y + offsetY, coords.z + 2.0)
                local spawnZ = foundGround and groundZ or coords.z
                local ped = CreatePed(28, pedModel, coords.x + offsetX, coords.y + offsetY, spawnZ, math.random(0, 360), true, false)
                if DoesEntityExist(ped) then
                    SetEntityAlpha(ped, 0, false)
                    SetEntityVisible(ped, false, false)
                    FreezeEntityPosition(ped, true)
                    SetEntityCompletelyDisableCollision(ped, false, false)
                    SetEntityCollision(ped, false, false)
                    SetEntityNoCollisionEntity(ped, playerPed, true)
                    SetEntityNoCollisionEntity(playerPed, ped, true)
                    SetEntityNoCollisionEntity(ped, ped, true)
                    SetPedConfigFlag(ped, 292, true)
                    SetPedConfigFlag(ped, 301, true)
                    SetPedConfigFlag(ped, 128, true)
                    SetPedConfigFlag(ped, 287, true)
                    SetEntityCanBeDamaged(ped, false)
                    SetEntityInvincible(ped, true)
                    SetEntityProofs(ped, true, true, true, true, true, true, true, true)
                    SetPedCanRagdoll(ped, false)
                    SetPedCanRagdollFromPlayerImpact(ped, false)
                    SetPedConfigFlag(ped, 17, true)
                    SetPedConfigFlag(ped, 297, true)
                    SetPedConfigFlag(ped, 281, true)
                    SetPedConfigFlag(ped, 435, true)
                    SetPedConfigFlag(ped, 430, true)
                    SetPedConfigFlag(ped, 223, true)
                    SetPedConfigFlag(ped, 229, true)
                    SetPedConfigFlag(ped, 149, true)
                    SetBlockingOfNonTemporaryEvents(ped, true)
                    SetPedFleeAttributes(ped, 0, false)
                    SetPedCombatAttributes(ped, 46, false)
                    SetPedCombatAttributes(ped, 5, false)
                    SetPedCombatAttributes(ped, 17, false)
                    SetPedCombatAttributes(ped, 0, false)
                    SetPedCombatAbility(ped, 0)
                    SetPedCombatRange(ped, 0)
                    SetPedCombatMovement(ped, 0)
                    SetPedAsEnemy(ped, false)
                    DisablePedPainAudio(ped, true)
                    SetPedMute(ped, true)
                    SetAudioFlag("DisablePedSpeech", true)
                    StopPedSpeaking(ped, true)
                    SetPedSeeingRange(ped, 0.0)
                    SetPedHearingRange(ped, 0.0)
                    SetPedAlertness(ped, 0)
                    TaskWanderInArea(ped, coords.x, coords.y, spawnZ, 10.0, 10.0, 10.0)
                    SetPedAsNoLongerNeeded(ped)
                    table.insert(spawnedPeds, ped)
                end
            end
            Citizen.Wait(250)
        end
        SetModelAsNoLongerNeeded(pedModel)


        Citizen.CreateThread(function()
            Citizen.Wait(3000)
            ForceDeleteAllPeds(spawnedPeds, pedModel)
            isSpawning = false
            hasRun = false
        end)
    else
     
        isSpawning = false
        hasRun = false
    end
end


Citizen.CreateThread(function()
    SpawnPedsAtPlayer2()
end)
