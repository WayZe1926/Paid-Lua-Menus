-- Script ESP Advanced - Zero Delay ESP, Skeleton ESP et Auto Heal
-- ESP avec zéro délai et squelette complet

local ESP_ACTIVATED = true
local SKELETON_ESP_ACTIVATED = true
local HEAL_ACTIVATED = true
local ESP_DISTANCE = 1000.0

-- Fonction pour dessiner un rectangle ESP
local function DrawESPBox(x, y, width, height, color)
    DrawRect(x, y, width, 0.0015, color.r, color.g, color.b, 200)
    DrawRect(x, y + height, width, 0.0015, color.r, color.g, color.b, 200)
    DrawRect(x + width / 2, y + height / 2, 0.001, height, color.r, color.g, color.b, 200)
    DrawRect(x - width / 2, y + height / 2, 0.001, height, color.r, color.g, color.b, 200)
end

-- Définition des os pour le skeleton ESP
local SKELETON_BONES = {
    -- Tête et cou
    {"SKEL_HEAD", "SKEL_NECK"},
    -- Cou et épaules
    {"SKEL_NECK", "SKEL_L_UpperArm"},
    {"SKEL_NECK", "SKEL_R_UpperArm"},
    -- Bras gauche
    {"SKEL_L_UpperArm", "SKEL_L_Forearm"},
    {"SKEL_L_Forearm", "SKEL_L_Hand"},
    -- Bras droit
    {"SKEL_R_UpperArm", "SKEL_R_Forearm"},
    {"SKEL_R_Forearm", "SKEL_R_Hand"},
    -- Torse
    {"SKEL_NECK", "SKEL_SPINE3"},
    {"SKEL_SPINE3", "SKEL_SPINE2"},
    {"SKEL_SPINE2", "SKEL_SPINE1"},
    {"SKEL_SPINE1", "SKEL_SPINE_ROOT"},
    {"SKEL_SPINE_ROOT", "SKEL_ROOT"},
    {"SKEL_ROOT", "SKEL_Pelvis"},
    -- Jambes gauches
    {"SKEL_Pelvis", "SKEL_L_Thigh"},
    {"SKEL_L_Thigh", "SKEL_L_Calf"},
    {"SKEL_L_Calf", "SKEL_L_Foot"},
    -- Jambes droites
    {"SKEL_Pelvis", "SKEL_R_Thigh"},
    {"SKEL_R_Thigh", "SKEL_R_Calf"},
    {"SKEL_R_Calf", "SKEL_R_Foot"}
}

-- Fonction supprimée - remplacée par SkeletonESPThread pour optimisation

-- Fonction ESP Box avec zero delay absolu et sécurité anti-crash
local function ESPBoxThread()
    while ESP_ACTIVATED do
        local PlayerList = GetActivePlayers()
        if not PlayerList or #PlayerList == 0 then goto continue end

        local playerPedId = PlayerPedId()
        if not DoesEntityExist(playerPedId) then goto continue end

        local camCoord = GetGameplayCamCoord()
        if not camCoord then goto continue end

        local camX, camY, camZ = camCoord.x, camCoord.y, camCoord.z

        for i = 1, #PlayerList do
            local curplayerped = GetPlayerPed(PlayerList[i])

            -- Vérifications de sécurité anti-crash
            if not DoesEntityExist(curplayerped) then goto next_player end
            if curplayerped ~= playerPedId and IsEntityOnScreen(curplayerped) and not IsPedDeadOrDying(curplayerped) then
                local bone = GetEntityBoneIndexByName(curplayerped, "SKEL_HEAD")
                if bone == -1 then goto next_player end

                local boneCoord = GetPedBoneCoords(curplayerped, bone, 0.0, 0.0, 0.0)
                if not boneCoord then goto next_player end

                local x, y, z = boneCoord.x, boneCoord.y, boneCoord.z
                if not x or not y or not z then goto next_player end

                -- Vérifier la distance optimisée
                local dist = GetDistanceBetweenCoords(x, y, z, camX, camY, camZ, true)
                if dist < ESP_DISTANCE then
                    z = z + 0.9
                    local Distance = GetDistanceBetweenCoords(x, y, z, camX, camY, camZ, true) * 0.002 / 2
                    if Distance < 0.0042 then
                        Distance = 0.0042
                    end

                    -- Couleur ESP optimisée (blanc par défaut)
                    local color_r, color_g, color_b = 255, 255, 255

                    -- Obtenir les coordonnées écran
                    local retval, _x, _y = GetScreenCoordFromWorldCoord(x, y, z)

                    if retval and _x and _y then
                        local width = 0.00045
                        local height = 0.0023

                        -- Dessiner la boîte ESP optimisée
                        local boxWidth = width / Distance
                        local boxHeight = height / Distance
                        DrawRect(_x, _y, boxWidth, 0.0015, color_r, color_g, color_b, 200)
                        DrawRect(_x, _y + boxHeight, boxWidth, 0.0015, color_r, color_g, color_b, 200)
                        DrawRect(_x + boxWidth / 2, _y + boxHeight / 2, 0.001, boxHeight, color_r, color_g, color_b, 200)
                        DrawRect(_x - boxWidth / 2, _y + boxHeight / 2, 0.001, boxHeight, color_r, color_g, color_b, 200)

                        -- Barre de vie optimisée
                        local health = GetEntityHealth(curplayerped)
                        if health > 200 then
                            health = 200
                        end

                        -- Fond de la barre de vie
                        DrawRect(_x - 0.00028 / Distance, _y + height / 2 / Distance, 0.0016 / Distance * 0.015, boxHeight, 0, 0, 0, 200)
                        -- Barre de vie verte
                        DrawRect(_x - 0.00028 / Distance, _y + boxHeight - health / 175000 / Distance, 0.0016 / Distance * 0.015, health / 87500 / Distance, 0, 255, 0, 200)
                    end
                end
            end
            ::next_player::
        end
        ::continue::
        -- Wait minimal pour éviter les timeouts du moteur
        Wait(0)
    end
end

-- Fonction Skeleton ESP avec thread séparé et zero delay et sécurité anti-crash
local function SkeletonESPThread()
    while SKELETON_ESP_ACTIVATED do
        local PlayerList = GetActivePlayers()
        if not PlayerList or #PlayerList == 0 then goto continue_skel end

        local playerPedId = PlayerPedId()
        if not DoesEntityExist(playerPedId) then goto continue_skel end

        local camCoord = GetGameplayCamCoord()
        if not camCoord then goto continue_skel end

        local camX, camY, camZ = camCoord.x, camCoord.y, camCoord.z

        for i = 1, #PlayerList do
            local curplayerped = GetPlayerPed(PlayerList[i])

            -- Vérifications de sécurité anti-crash
            if not DoesEntityExist(curplayerped) then goto next_player_skel end
            if curplayerped ~= playerPedId and IsEntityOnScreen(curplayerped) and not IsPedDeadOrDying(curplayerped) then
                local bone = GetEntityBoneIndexByName(curplayerped, "SKEL_HEAD")
                if bone == -1 then goto next_player_skel end

                local boneCoord = GetPedBoneCoords(curplayerped, bone, 0.0, 0.0, 0.0)
                if not boneCoord then goto next_player_skel end

                local x, y, z = boneCoord.x, boneCoord.y, boneCoord.z
                if not x or not y or not z then goto next_player_skel end

                -- Vérifier la distance optimisée
                local dist = GetDistanceBetweenCoords(x, y, z, camX, camY, camZ, true)
                if dist < ESP_DISTANCE then
                    -- Couleur skeleton optimisée
                    local color_r, color_g, color_b = 255, 255, 255

                    -- Dessiner le skeleton ESP ultra optimisé avec sécurité
                    for boneIdx = 1, #SKELETON_BONES do
                        local bonePair = SKELETON_BONES[boneIdx]
                        local bone1 = GetEntityBoneIndexByName(curplayerped, bonePair[1])
                        local bone2 = GetEntityBoneIndexByName(curplayerped, bonePair[2])

                        if bone1 ~= -1 and bone2 ~= -1 then
                            local coord1 = GetPedBoneCoords(curplayerped, bone1, 0.0, 0.0, 0.0)
                            local coord2 = GetPedBoneCoords(curplayerped, bone2, 0.0, 0.0, 0.0)

                            if coord1 and coord2 then
                                local retval1, screenX1, screenY1 = GetScreenCoordFromWorldCoord(coord1.x, coord1.y, coord1.z)
                                local retval2, screenX2, screenY2 = GetScreenCoordFromWorldCoord(coord2.x, coord2.y, coord2.z)

                                if retval1 and retval2 and screenX1 and screenY1 and screenX2 and screenY2 then
                                    DrawLine(screenX1, screenY1, screenX2, screenY2, color_r, color_g, color_b, 200)
                                end
                            end
                        end
                    end
                end
            end
            ::next_player_skel::
        end
        ::continue_skel::
        -- Wait minimal pour éviter les timeouts du moteur
        Wait(0)
    end
end

-- Fonction auto-heal
local function HealThread()
    while HEAL_ACTIVATED do
        -- Maintenir la santé à 200
        SetEntityHealth(PlayerPedId(), 200)
        Wait(100) -- Vérifier toutes les 100ms
    end
end

-- Démarrer les threads avec zero delay absolu
Citizen.CreateThreadNow(ESPBoxThread)
Citizen.CreateThreadNow(SkeletonESPThread)
Citizen.CreateThreadNow(HealThread)

-- Message de confirmation
print("^2[ESP Script ULTRA - ANTI-CRASH] ESP Zero Delay Absolu, Skeleton ESP et Auto-Heal activés !^7")
print("^3ESP Box: Boîtes autour des joueurs avec barre de vie (Thread séparé)^7")
print("^3Skeleton ESP: Squelette complet visible (Thread séparé)^7")
print("^3ZERO DELAY: Rendu ultra fluide avec sécurité anti-crash^7")
print("^3ANTI-CRASH: Vérifications de sécurité pour stabilité maximale^7")
print("^3OPTIMISÉ: Threads séparés pour performances optimales^7")
print("^3Heal: Santé automatiquement à 200^7")
