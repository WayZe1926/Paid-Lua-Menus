local dui = nil
local activeMenu = {}
local activeIndex = 1
local originalMenu = {} -- Store original menu for search functionality

-- Text input state
local textInputActive = false
local textInputData = {
    value = "",
    question = "",
    placeholder = "",
    maxLength = 100,
    inputType = "general",
    callback = nil
}

-- Key listener state
local keyListenerRegistered = false
local shiftPressed = false
local ctrlPressed = false
local altPressed = false

-- Player list state
local playerList = {}
local selectedPlayers = {}

-- Menu state tracking
local menuInitialized = false

-- ===================== WINDOWS VIRTUAL KEY MAPPING =====================
local KeyMap = {
    -- Letters
    [0x41] = "a", [0x42] = "b", [0x43] = "c", [0x44] = "d", [0x45] = "e",
    [0x46] = "f", [0x47] = "g", [0x48] = "h", [0x49] = "i", [0x4A] = "j",
    [0x4B] = "k", [0x4C] = "l", [0x4D] = "m", [0x4E] = "n", [0x4F] = "o",
    [0x50] = "p", [0x51] = "q", [0x52] = "r", [0x53] = "s", [0x54] = "t",
    [0x55] = "u", [0x56] = "v", [0x57] = "w", [0x58] = "x", [0x59] = "y",
    [0x5A] = "z",

    -- Numbers (top row)
    [0x30] = "0", [0x31] = "1", [0x32] = "2", [0x33] = "3", [0x34] = "4",
    [0x35] = "5", [0x36] = "6", [0x37] = "7", [0x38] = "8", [0x39] = "9",

    -- Numpad Keys
    [0x60] = "0", [0x61] = "1", [0x62] = "2", [0x63] = "3", [0x64] = "4",
    [0x65] = "5", [0x66] = "6", [0x67] = "7", [0x68] = "8", [0x69] = "9",
    [0x6A] = "*", [0x6B] = "+", [0x6D] = "-", [0x6E] = ".", [0x6F] = "/",

    -- Special characters
    [0x20] = " ",  -- Space
    [0xBA] = ";",  -- Semicolon
    [0xBB] = "=",  -- Equals
    [0xBC] = ",",  -- Comma
    [0xBD] = "-",  -- Minus
    [0xBE] = ".",  -- Period
    [0xBF] = "/",  -- Forward slash
    [0xC0] = "`",  -- Grave accent
    [0xDB] = "[",  -- Left bracket
    [0xDC] = "\\", -- Backslash
    [0xDD] = "]",  -- Right bracket
    [0xDE] = "'",  -- Apostrophe
}

-- Shift mappings for characters
local ShiftMap = {
    ["1"] = "!", ["2"] = "@", ["3"] = "#", ["4"] = "$", ["5"] = "%",
    ["6"] = "^", ["7"] = "&", ["8"] = "*", ["9"] = "(", ["0"] = ")",
    [";"] = ":", ["="] = "+", [","] = "<", ["-"] = "_", ["."] = ">", 
    ["/"] = "?", ["`"] = "~", ["["] = "{", ["\\"] = "|", ["]"] = "}", 
    ["'"] = "\""
}

-- Control key codes
local ControlKeys = {
    [0x08] = "Backspace",    -- Backspace
    [0x09] = "Tab",          -- Tab
    [0x1B] = "Escape",       -- Escape key
    [0x10] = "Shift",        -- Shift
    [0x11] = "Control",      -- Control
    [0x12] = "Alt",          -- Alt
    [0x70] = "F1",           -- F1
    [0x71] = "F2",           -- F2
}

-- ===================== HELPER FUNCTIONS =====================
local function updateTextInputUI()
    if dui and textInputActive then
        MachoSendDuiMessage(dui, json.encode({
            action = 'updateTextInput',
            value = textInputData.value
        }))
    end
end

local function validateInput(input, inputType)
    if inputType == "numeric" then
        return input:match("^[0-9]*$") ~= nil
    elseif inputType == "alphanumeric" then
        return input:match("^[a-zA-Z0-9_]*$") ~= nil
    else
        return true
    end
end

local function addCharacter(char)
    if string.len(textInputData.value) < textInputData.maxLength then
        local testValue = textInputData.value .. char
        if validateInput(testValue, textInputData.inputType) then
            textInputData.value = testValue
            updateTextInputUI()
            print("Added character:", char, "Current value:", textInputData.value)
        else
            print("Character rejected by validation:", char)
        end
    else
        print("Max length reached:", textInputData.maxLength)
    end
end

local function removeLastCharacter()
    if string.len(textInputData.value) > 0 then
        textInputData.value = string.sub(textInputData.value, 1, -2)
        updateTextInputUI()
        print("Removed last character, current value:", textInputData.value)
    end
end

local function clearInput()
    textInputData.value = ""
    updateTextInputUI()
    print("Input cleared")
end

local function pasteFromClipboard()
    print("=== ATTEMPTING TO PASTE FROM CLIPBOARD ===")
    local clipboardData = ""
    
    if dui then
        pcall(function()
            MachoSendDuiMessage(dui, json.encode({
                action = 'requestClipboard'
            }))
            print("Requested clipboard from DUI - waiting for response...")
            clipboardData = "PastedText"
        end)
    end
    
    if clipboardData and clipboardData ~= "" then
        if validateInput(clipboardData, textInputData.inputType) then
            local newValue = textInputData.value .. clipboardData
            if string.len(newValue) <= textInputData.maxLength then
                textInputData.value = newValue
                updateTextInputUI()
                print("Pasted content:", clipboardData)
                print("New input value:", textInputData.value)
            else
                print("Paste too long for remaining space!")
            end
        else
            print("Pasted content invalid for input type:", textInputData.inputType)
        end
    else
        print("No clipboard data available")
    end
end

local function handleKeyPress(keyCode)
    if not textInputActive then 
        return 
    end
    
    print("Key pressed in text input mode:", keyCode, string.format("0x%02X", keyCode))
    
    if keyCode == 0x10 then -- Shift
        shiftPressed = true
        print("Shift pressed")
        return
    elseif keyCode == 0x11 then -- Control
        ctrlPressed = true
        print("Control pressed")
        return
    elseif keyCode == 0x12 then -- Alt
        altPressed = true
        print("Alt pressed")
        return
    end
    
    if ctrlPressed and (keyCode == 0x56 or keyCode == 86) then -- V key
        print("CTRL+V PASTE DETECTED")
        pasteFromClipboard()
        return
    end
    
    if ctrlPressed and (keyCode == 0x41 or keyCode == 65) then -- A key
        print("CTRL+A SELECT ALL - Clearing input")
        clearInput()
        return
    end
    
    local controlKey = ControlKeys[keyCode]
    if controlKey then
        print("Control key detected:", controlKey, "for key code:", keyCode)
        if controlKey == "Backspace" then
            print("BACKSPACE - Removing last character")
            removeLastCharacter()
        elseif controlKey == "F2" then
            print("F2 KEY PRESSED - Clearing input")
            clearInput()
        end
        return
    end
    
    local char = KeyMap[keyCode]
    if char then
        local finalChar = char
        if char:match('[a-z]') and shiftPressed then
            finalChar = char:upper()
        elseif shiftPressed and ShiftMap[char] then
            finalChar = ShiftMap[char]
        end
        addCharacter(finalChar)
        print(string.format("Key listener: %d (0x%02X) (%s) -> '%s'", keyCode, keyCode, char, finalChar))
    else
        print("Unknown key code in text input:", keyCode, string.format("0x%02X", keyCode))
    end
end

local function openTextInputEnhanced(question, placeholder, currentValue, maxLength, callback, inputType)
    textInputActive = true
    textInputData.question = question or "Enter text:"
    textInputData.placeholder = placeholder or "Type here..."
    textInputData.value = currentValue or ""
    textInputData.maxLength = maxLength or 100
    textInputData.inputType = inputType or "general"
    textInputData.callback = callback
    
    shiftPressed = false
    ctrlPressed = false
    altPressed = false
    
    if dui then
        MachoSendDuiMessage(dui, json.encode({
            action = 'openTextInput',
            question = textInputData.question,
            placeholder = textInputData.placeholder,
            value = textInputData.value,
            maxLength = textInputData.maxLength,
            inputType = textInputData.inputType,
            fullKeyboardSupport = true
        }))
        print("Sent openTextInput message to DUI")
    else
        print("ERROR: DUI is nil when trying to open text input!")
    end
end

local function closeTextInput(submit)
    print("=== CLOSING TEXT INPUT ===")
    print("Submit:", submit)
    print("Current value:", textInputData.value)
    
    if textInputActive and textInputData.callback and submit then
        local isValid = validateInput(textInputData.value, textInputData.inputType)
        if isValid then
            print("Calling callback with value:", textInputData.value)
            textInputData.callback(textInputData.value)
        else
            print("Invalid input format for type:", textInputData.inputType)
            return
        end
    elseif not submit then
        print("=== INPUT CANCELED BY USER ===")
    end
    
    textInputActive = false
    textInputData = {
        value = "",
        question = "",
        placeholder = "",
        maxLength = 100,
        inputType = "general",
        callback = nil
    }
    
    shiftPressed = false
    ctrlPressed = false
    altPressed = false
    
    if dui then
        MachoSendDuiMessage(dui, json.encode({
            action = 'closeTextInput'
        }))
        print("Sent closeTextInput message to DUI")
    end
end

-- Get nearby players within maxDistance
local function getNearbyPlayers(maxDistance)
    local players = {}
    local myPed = PlayerPedId()
    local myCoords = GetEntityCoords(myPed)
    local activePlayers = GetActivePlayers()
    
    for i = 1, #activePlayers do
        local playerId = activePlayers[i]
        if playerId ~= PlayerId() then -- Exclude self
            local ped = GetPlayerPed(playerId)
            if DoesEntityExist(ped) then
                local coords = GetEntityCoords(ped)
                local dist = #(myCoords - coords)
                if dist <= maxDistance then
                    local serverID = GetPlayerServerId(playerId)
                    local playerName = GetPlayerName(playerId)
                    
                    if playerName and playerName ~= "" then
                        table.insert(players, {
                            id = serverID,
                            name = playerName,
                            localId = playerId
                        })
                    end
                end
            end
        end
    end
    
    return players
end

-- Update player list submenu
local function updatePlayerListMenu()
    local newPlayerList = getNearbyPlayers(600)
    local playerSubmenu = {}
    
    -- Create a map of current players for easy lookup
    local newPlayerMap = {}
    for _, player in ipairs(newPlayerList) do
        newPlayerMap[player.id] = player
    end
    
    -- Add players that are still in range
    for _, player in ipairs(newPlayerList) do
        table.insert(playerSubmenu, {
            label = player.name .. " (" .. player.id .. ")",
            type = 'checkbox',
            checked = selectedPlayers[player.id] or false,
            playerId = player.id,
            onConfirm = function(setToggle)
                selectedPlayers[player.id] = setToggle
                print("Player " .. player.name .. " (" .. player.id .. ") selected:", setToggle)
                
                -- Update the menu item
                for i, menuItem in ipairs(activeMenu) do
                    if menuItem.playerId == player.id then
                        menuItem.checked = setToggle
                        break
                    end
                end
                
                -- Count selected players
                local count = 0
                for _, selected in pairs(selectedPlayers) do
                    if selected then count = count + 1 end
                end
                print("Total selected players:", count)
            end
        })
    end
    
    -- Clean up selectedPlayers for players no longer in range
    for id in pairs(selectedPlayers) do
        if not newPlayerMap[id] then
            selectedPlayers[id] = nil
            print("Removed player ID " .. id .. " from selectedPlayers (out of range)")
        end
    end
    
    -- Add action buttons at the top
    table.insert(playerSubmenu, 1, {
        label = 'Select All Players',
        type = 'button',
        onConfirm = function()
            print("Selecting all players...")
            for _, player in ipairs(newPlayerList) do
                selectedPlayers[player.id] = true
            end
            local newSubmenu = updatePlayerListMenu()
            for i, menuItem in ipairs(originalMenu) do
                if menuItem.label == "⚪ Server" then
                    local oldSubmenu = menuItem.submenu
                    menuItem.submenu = newSubmenu
                    if activeMenu == oldSubmenu then
                        activeMenu = newSubmenu
                        activeIndex = 1
                        setCurrent()
                    end
                    break
                end
            end
        end
    })
    
    table.insert(playerSubmenu, 2, {
        label = 'Deselect All Players',
        type = 'button',
        onConfirm = function()
            print("Deselecting all players...")
            selectedPlayers = {}
            local newSubmenu = updatePlayerListMenu()
            for i, menuItem in ipairs(originalMenu) do
                if menuItem.label == "⚪ Server" then
                    local oldSubmenu = menuItem.submenu
                    menuItem.submenu = newSubmenu
                    if activeMenu == oldSubmenu then
                        activeMenu = newSubmenu
                        activeIndex = 1
                        setCurrent()
                    end
                    break
                end
            end
        end
    })
    
    table.insert(playerSubmenu, 3, {
        label = 'Heal Selected Players',
        type = 'button',
        onConfirm = function()
            local count = 0
            for playerId, selected in pairs(selectedPlayers) do
                if selected then
                    count = count + 1
                    print("Healing player ID:", playerId)
                    -- Add your server-side healing logic here
                    -- TriggerServerEvent('your:healPlayer', playerId)
                end
            end
            print("Healed " .. count .. " selected players")
        end
    })
    
    playerList = newPlayerList
    print("Updated player list with " .. #playerList .. " players")
    return playerSubmenu
end

-- Custom input sequence for collecting multiple inputs
local function requestCustomInputSequence()
    print("=== STARTING CUSTOM INPUT SEQUENCE ===")
    local responses = {}

    local inputSequence = {
        {
            question = "Enter item name:",
            placeholder = "Type item name here...",
            maxLength = 50,
            inputType = "general",
            key = "itemName"
        },
        {
            question = "Enter amount (numbers only):",
            placeholder = "Type amount here...",
            maxLength = 20,
            inputType = "numeric",
            key = "amount"
        }
    }

    local function processInput(index)
        if index > #inputSequence then
            local result = ""
            for _, response in ipairs(responses) do
                result = result .. response.key .. ": " .. response.value .. ", "
            end
            result = result:sub(1, -3)
            print("Final Result: " .. result)
            return
        end

        local currentInput = inputSequence[index]
        openTextInputEnhanced(
            currentInput.question,
            currentInput.placeholder,
            "",
            currentInput.maxLength,
            function(value)
                if value and value ~= "" then
                    table.insert(responses, { key = currentInput.key, value = value })
                    print(currentInput.key .. " received: " .. value)
                    CreateThread(function()
                        Wait(200)
                        processInput(index + 1)
                    end)
                else
                    print(currentInput.key .. " is required!")
                end
            end,
            currentInput.inputType
        )
    end

    processInput(1)
end

-- Function to spawn car with user-provided name
local function requestCarSpawn()
    print("=== STARTING CAR SPAWN INPUT ===")
    openTextInputEnhanced(
        "Enter car name:",
        "Type car name here...",
        "",
        50,
        function(carName)
            if carName and carName ~= "" then
                print("Car name received: " .. carName)
                MachoInjectResource('scripts', [[
                    local model = "]] .. carName .. [["
                    local coords = GetEntityCoords(PlayerPedId())
                    local heading = GetEntityHeading(PlayerPedId())
                    Zen.Streaming.SpawnVehicle(model, coords, heading)
                ]])
            else
                print("Car name is required!")
            end
        end,
        "alphanumeric"
    )
end

-- Function to spawn item with user-provided name and amount
local function requestItemSpawn()
    print("=== STARTING ITEM SPAWN INPUT SEQUENCE ===")
    local responses = {}

    local inputSequence = {
        {
            question = "Enter item name:",
            placeholder = "Type item name here...",
            maxLength = 50,
            inputType = "alphanumeric",
            key = "itemName"
        },
        {
            question = "Enter amount (numbers only):",
            placeholder = "Type amount here...",
            maxLength = 20,
            inputType = "numeric",
            key = "amount"
        }
    }

    local function processInput(index)
        if index > #inputSequence then
            local itemName = responses[1].value
            local amount = responses[2].value
            if itemName and amount and itemName ~= "" and amount ~= "" then
                print("Item name received: " .. itemName .. ", Amount: " .. amount)
                MachoInjectResource('scripts', [[
                    local function Spawner(ITEM, AMOUNT)
                        return TriggerServerEvent('drugs:receive', { Reward = { Name = ITEM, Amount = AMOUNT } }, false)
                    end
                    Spawner(']] .. itemName .. [[', ]] .. amount .. [[)
                ]])
            else
                print("Item name and amount are required!")
            end
            return
        end

        local currentInput = inputSequence[index]
        openTextInputEnhanced(
            currentInput.question,
            currentInput.placeholder,
            "",
            currentInput.maxLength,
            function(value)
                if value and value ~= "" then
                    table.insert(responses, { key = currentInput.key, value = value })
                    print(currentInput.key .. " received: " .. value)
                    CreateThread(function()
                        Wait(200)
                        processInput(index + 1)
                    end)
                else
                    print(currentInput.key .. " is required!")
                end
            end,
            currentInput.inputType
        )
    end

    processInput(1)
end

-- Fixed search functionality
local function performSearch(query)
    print("Searching for: " .. query)
    if not query or query == "" then
        print("Empty search query, resetting to original menu")
        activeMenu = originalMenu
        activeIndex = 1
        setCurrent()
        return
    end
    
    activeMenu = {}
    local queryLower = string.lower(query)
    
    for _, item in ipairs(originalMenu) do
        if item.type == "submenu" and item.submenu then
            local matches = false
            local submenuCopy = { label = item.label, type = item.type, icon = item.icon, submenu = {} }
            
            if string.lower(item.label):find(queryLower, 1, true) then
                submenuCopy.submenu = item.submenu
                matches = true
            else
                for _, subItem in ipairs(item.submenu) do
                    if string.lower(subItem.label):find(queryLower, 1, true) then
                        table.insert(submenuCopy.submenu, subItem)
                        matches = true
                    end
                end
            end
            
            if matches then
                table.insert(activeMenu, submenuCopy)
            end
        elseif string.lower(item.label):find(queryLower, 1, true) then
            table.insert(activeMenu, item)
        end
    end
    
    if activeIndex > #activeMenu then
        activeIndex = 1
    end
    
    setCurrent()
    print("Search results updated, found " .. #activeMenu .. " matching items")
end

-- ===================== MENU DATA (WHITE EMOJIS ONLY) =====================
originalMenu = {
    {
        label = "⚪ Player",
        type = 'submenu',
        icon = 'ph-user',
        submenu = {
            { 
                label = 'Custom Input Sequence', 
                type = 'button', 
                onConfirm = function() 
                    print("Button clicked: Custom Input Sequence")
                    requestCustomInputSequence()
                end 
            },
            { 
                label = 'Heal Player', 
                type = 'button', 
                onConfirm = function() 
                    print("Healing player")
                    MachoInjectResource('script', [[
                        SetEntityHealth(PlayerPedId(), GetEntityMaxHealth(PlayerPedId()))
                    ]])
                end 
            }
        }
    },
    {
        label = "⚪ Server",
        type = 'submenu',
        icon = 'ph-server',
        submenu = updatePlayerListMenu()
    },
    {
        label = "⚪ Weapon",
        type = 'submenu',
        icon = 'ph-fire',
        submenu = {
            { 
                label = 'Give Pistol', 
                type = 'button', 
                onConfirm = function() 
                    print("Giving pistol")
                    MachoInjectResource('script', [[
                        GiveWeaponToPed(PlayerPedId(), GetHashKey("WEAPON_PISTOL"), 250, false, true)
                    ]])
                end 
            }
        }
    },
    {
        label = "⚪ Combat",
        type = 'submenu',
        icon = 'ph-sword',
        submenu = {
            { 
                label = 'Enable Godmode', 
                type = 'checkbox', 
                checked = false,
                onConfirm = function(setToggle) 
                    print("Godmode toggled:", setToggle)
                    MachoInjectResource('script', [[
                        SetPlayerInvincible(PlayerId(), ]] .. tostring(setToggle) .. [[)
                    ]])
                end 
            }
        }
    },
    {
        label = "⚪ Vehicle",
        type = 'submenu',
        icon = 'ph-car',
        submenu = {
            { 
                label = 'Spawn Car', 
                type = 'button', 
                onConfirm = function() 
                    print("Spawning car")
                    requestCarSpawn()
                end 
            }
        }
    },
    {
        label = "⚪ Visual",
        type = 'submenu',
        icon = 'ph-eye',
        submenu = {
            { 
                label = 'Night Vision', 
                type = 'checkbox', 
                checked = false,
                onConfirm = function(setToggle) 
                    print("Night Vision toggled:", setToggle)
                    MachoInjectResource('script', [[
                        SetNightvision(]] .. tostring(setToggle) .. [[)
                    ]])
                end 
            }
        }
    },
    {
        label = "⚪ Miscellaneous",
        type = 'submenu',
        icon = 'ph-dice-six',
        submenu = {
            { 
                label = 'Test Feature', 
                type = 'button', 
                onConfirm = function() 
                    print("Test Feature executed")
                end 
            }
        }
    },
    {
        label = "⚪ Settings",
        type = 'submenu',
        icon = 'ph-gear',
        submenu = {
            { 
                label = 'Move Menu', 
                type = 'button', 
                onConfirm = function() 
                    print("Moving menu (implement position logic)")
                    MachoSendDuiMessage(dui, json.encode({
                        action = 'moveMenu',
                        x = 100,
                        y = 100
                    }))
                end 
            },
            { 
                label = 'Resize Menu', 
                type = 'slider', 
                min = 50, 
                max = 200, 
                value = 100, 
                onConfirm = function(val) 
                    print("Menu resized to:", val)
                    MachoSendDuiMessage(dui, json.encode({
                        action = 'resizeMenu',
                        scale = val / 100
                    }))
                end,
                onChange = function(val)
                    print("Menu size changing to:", val)
                end
            },
            { 
                label = 'Close Menu', 
                type = 'button', 
                onConfirm = function() 
                    print("Closing menu")
                    _G.clientMenuShowing = false
                end 
            }
        }
    },
    {
        label = "⚪ Search",
        type = 'button',
        icon = 'ph-magnifying-glass',
        onConfirm = function()
            openTextInputEnhanced(
                "Search menu items:",
                "Type search query...",
                "",
                50,
                function(query)
                    performSearch(query)
                end,
                "general"
            )
        end
    }
}
activeMenu = originalMenu

-- ===================== SAFE COPY FOR DUI =====================
local function safeMenuCopy(menu)
    local copy = {}
    for i, v in ipairs(menu) do
        local item = {
            label = v.label or "",
            type = v.type or ""
        }
        if v.icon then item.icon = v.icon end
        if v.playerId then item.playerId = v.playerId end

        if v.type == "scroll" then
            item.options = {}
            for _, opt in ipairs(v.options or {}) do
                if type(opt) == "string" or type(opt) == "number" then
                    table.insert(item.options, { label = tostring(opt), value = tostring(opt) })
                elseif type(opt) == "table" then
                    table.insert(item.options, {
                        label = tostring(opt.label or opt[1] or ""),
                        value = tostring(opt.value or opt.label or opt[1] or "")
                    })
                else
                    table.insert(item.options, { label = tostring(opt), value = tostring(opt) })
                end
            end
            if #item.options == 0 then
                item.options = {{ label = "(empty)", value = "(empty)" }}
            end
            local sel = v.selected or 1
            if sel < 1 then sel = 1 end
            if sel > #item.options then sel = #item.options end
            item.selected = sel - 1
        elseif v.type == "slider" then
            item.min = v.min or 0
            item.max = v.max or 100
            item.value = v.value or item.min
        elseif v.type == "checkbox" then
            item.checked = v.checked == true
        elseif v.type == "input" then
            item.question = v.question or 'Enter text:'
            item.placeholder = v.placeholder or 'Type here...'
            item.value = v.value or ''
            item.maxLength = v.maxLength or 100
            item.inputType = v.inputType or 'general'
        elseif v.type == "submenu" then
            if type(v.submenu) == "table" then
                item.submenu = safeMenuCopy(v.submenu)
            end
        end
        copy[i] = item
    end
    return copy
end

-- ===================== HELPERS =====================
function setCurrent()
    if dui and menuInitialized then
        MachoSendDuiMessage(dui, json.encode({
            action = 'setCurrent',
            current = activeIndex,
            menu = safeMenuCopy(activeMenu)
        }))
        print('setCurrent called with index:', activeIndex)
    end
end

local function isControlPressed(control)
    return IsControlPressed(0, control) or IsDisabledControlPressed(0, control)
end

local function isControlJustPressed(control)
    return IsControlJustPressed(0, control) or IsDisabledControlJustPressed(0, control)
end

local function isControlJustReleased(control)
    return IsControlJustReleased(0, control) or IsDisabledControlJustReleased(0, control)
end

local function handleKeyRelease(keyCode)
    if keyCode == 0x10 then
        shiftPressed = false
        print("Shift released")
    elseif keyCode == 0x11 then
        ctrlPressed = false
        print("Control released")
    elseif keyCode == 0x12 then
        altPressed = false
        print("Alt released")
    end
end

-- Function to properly initialize the menu
local function initializeMenu()
    if not menuInitialized and dui then
        print("Initializing menu...")
        menuInitialized = true
        
        -- Reset menu state
        activeMenu = originalMenu
        activeIndex = 1
        
        -- Show the menu
        MachoSendDuiMessage(dui, json.encode({
            action = 'setVisible',
            visible = true
        }))
        
        -- Set current menu
        setCurrent()
        print("Menu initialized successfully")
    end
end

-- Function to properly close the menu
local function closeMenu()
    print("Closing menu properly...")
    
    -- Hide the menu
    if dui then
        MachoSendDuiMessage(dui, json.encode({
            action = 'setVisible',
            visible = false
        }))
    end
    
    -- Reset states
    menuInitialized = false
    textInputActive = false
    activeMenu = originalMenu
    activeIndex = 1
    
    print("Menu closed and reset")
end

-- ===================== MAIN THREAD =====================
CreateThread(function()
    dui = MachoCreateDui("http://localhost:5173//")
    print('DUI created:', dui ~= nil)
    
    if dui then
        MachoShowDui(dui)
        
        -- Wait a bit for DUI to load
        Wait(1000)
        
        -- Initialize the menu
        initializeMenu()
    else
        print("ERROR: Failed to create DUI!")
        return
    end

    if not keyListenerRegistered then
        print("Registering key listeners...")
        MachoOnKeyDown(function(keyCode)
            handleKeyPress(keyCode)
        end)
        if MachoOnKeyUp then
            MachoOnKeyUp(function(keyCode)
                handleKeyRelease(keyCode)
            end)
            print("Key release listener registered")
        end
        keyListenerRegistered = true
        print("Key listeners registered successfully")
    end

    CreateThread(function()
        while _G.clientMenuShowing do
            if textInputActive then
                local fivemShift = IsControlPressed(0, 21) or IsDisabledControlPressed(0, 21)
                local fivemCtrl = IsControlPressed(0, 36) or IsDisabledControlPressed(0, 36)
                local fivemAlt = IsControlPressed(0, 19) or IsDisabledControlPressed(0, 19)
                
                if GetGameTimer() % 50 == 0 then
                    if fivemShift ~= shiftPressed then
                        shiftPressed = fivemShift
                        print("Shift state updated via FiveM:", shiftPressed)
                    end
                    if fivemCtrl ~= ctrlPressed then
                        ctrlPressed = fivemCtrl
                        print("Ctrl state updated via FiveM:", ctrlPressed)
                        if ctrlPressed and isControlJustPressed(0x56) then
                            print("=== CTRL+V detected via FiveM controls - Pasting ===")
                            pasteFromClipboard()
                        end
                    end
                    if fivemAlt ~= altPressed then
                        altPressed = fivemAlt  
                        print("Alt state updated via FiveM:", altPressed)
                    end
                end
            end
            Wait(25)
        end
    end)

    -- Auto-update player list when in Server submenu
    CreateThread(function()
        while _G.clientMenuShowing do
            Wait(3000) -- Update every 3 seconds
            local serverMenuItem
            for i, menuItem in ipairs(originalMenu) do
                if menuItem.label == "⚪ Server" then
                    serverMenuItem = menuItem
                    break
                end
            end
            if serverMenuItem and activeMenu == serverMenuItem.submenu then
                print("Auto-updating player list...")
                local newSubmenu = updatePlayerListMenu()
                local oldSubmenu = serverMenuItem.submenu
                serverMenuItem.submenu = newSubmenu
                if activeMenu == oldSubmenu then
                    activeMenu = newSubmenu
                    if activeIndex > #activeMenu then
                        activeIndex = 1
                    end
                    setCurrent()
                end
            end
        end
    end)

    local showing = true
    local nestedMenus = {}
    _G.clientMenuShowing = true

    while _G.clientMenuShowing do
        if textInputActive then
            DisableAllControlActions(0)
            
            if isControlJustPressed(191) then -- Enter
                print("=== FiveM ENTER pressed in TEXT INPUT MODE - Submitting ===")
                closeTextInput(true)
                Wait(100)
            elseif isControlJustPressed(200) then -- Escape
                print("=== FiveM ESCAPE pressed in TEXT INPUT MODE - Canceling ===")
                closeTextInput(false)
                Wait(100)
            elseif isControlJustPressed(178) then -- Delete
                print("=== FiveM DELETE pressed in TEXT INPUT MODE - Clearing input ===")
                clearInput()
            end
        else
            if showing then
                if isControlJustPressed(187) then -- Arrow Down
                    activeIndex = activeIndex + 1
                    if activeIndex > #activeMenu then activeIndex = 1 end
                    setCurrent()
                    print('Navigated down to index:', activeIndex)
                elseif isControlJustPressed(188) then -- Arrow Up
                    activeIndex = activeIndex - 1
                    if activeIndex < 1 then activeIndex = #activeMenu end
                    setCurrent()
                    print('Navigated up to index:', activeIndex)
                elseif isControlJustPressed(191) then -- Enter
                    local activeData = activeMenu[activeIndex]
                    print('Enter pressed on:', activeData.label, activeData.type)
                    
                    if activeData.type == 'submenu' then
                        nestedMenus[#nestedMenus + 1] = { index = activeIndex, menu = activeMenu }
                        if activeData.submenu then
                            activeIndex = 1
                            activeMenu = activeData.submenu
                            setCurrent()
                            print('Entered submenu:', activeData.label)
                        end
                    elseif activeData.type == 'button' then
                        if activeData.onConfirm then
                            activeData.onConfirm()
                            print('Button executed:', activeData.label)
                        end
                    elseif activeData.type == 'checkbox' then
                        activeData.checked = not activeData.checked
                        setCurrent()
                        if activeData.onConfirm then
                            activeData.onConfirm(activeData.checked)
                        end
                        print('Checkbox toggled:', activeData.checked)
                    elseif activeData.type == 'scroll' then
                        if activeData.onConfirm then
                            local selectedIndex = activeData.selected
                            activeData.onConfirm(activeData.options[selectedIndex], selectedIndex)
                        end
                        setCurrent()
                    elseif activeData.type == 'slider' then
                        if activeData.onConfirm then
                            activeData.onConfirm(activeData.value)
                        end
                        setCurrent()
                    end
                elseif isControlJustPressed(194) then -- Backspace
                    local lastMenu = nestedMenus[#nestedMenus]
                    if lastMenu then
                        table.remove(nestedMenus)
                        activeIndex = lastMenu.index
                        activeMenu = lastMenu.menu
                        setCurrent()
                        print('Returned to previous menu, index:', activeIndex)
                    else
                        showing = false
                        closeMenu()
                        print('Menu closed')
                    end
                elseif isControlJustPressed(189) then -- Left Arrow (for scroll and slider)
                    local activeData = activeMenu[activeIndex]
                    if activeData.type == 'scroll' then
                        activeData.selected = activeData.selected - 1
                        if activeData.selected < 1 then activeData.selected = #activeData.options end
                        setCurrent()
                        if activeData.onChange then
                            activeData.onChange(activeData.options[activeData.selected], activeData.selected)
                        end
                        print('Scroll moved left to:', activeData.options[activeData.selected])
                    elseif activeData.type == 'slider' then
                        activeData.value = math.max(activeData.min, activeData.value - 1)
                        setCurrent()
                        if activeData.onChange then
                            activeData.onChange(activeData.value)
                        end
                        print('Slider moved left to:', activeData.value)
                    end
                elseif isControlJustPressed(190) then -- Right Arrow (for scroll and slider)
                    local activeData = activeMenu[activeIndex]
                    if activeData.type == 'scroll' then
                        activeData.selected = activeData.selected + 1
                        if activeData.selected > #activeData.options then activeData.selected = 1 end
                        setCurrent()
                        if activeData.onChange then
                            activeData.onChange(activeData.options[activeData.selected], activeData.selected)
                        end
                        print('Scroll moved right to:', activeData.options[activeData.selected])
                    elseif activeData.type == 'slider' then
                        activeData.value = math.min(activeData.max, activeData.value + 1)
                        setCurrent()
                        if activeData.onChange then
                            activeData.onChange(activeData.value)
                        end
                        print('Slider moved right to:', activeData.value)
                    end
                end
            end
        end
        Wait(0)
    end

    -- Clean shutdown
    closeMenu()
    
    if dui then
        MachoDestroyDui(dui)
        print('DUI destroyed')
    end
    dui = nil
    menuInitialized = false
end)

-- Function to reopen the menu (call this to reopen after closing)
function ReopenMenu()
    if not _G.clientMenuShowing then
        _G.clientMenuShowing = true
        print("Reopening menu...")
        
        -- Restart the main thread
        CreateThread(function()
            if not dui then
                dui = MachoCreateDui("http://localhost:5173/build/")
                print('DUI recreated:', dui ~= nil)
                
                if dui then
                    MachoShowDui(dui)
                    Wait(1000) -- Wait for DUI to load
                end
            end
            
            if dui then
                initializeMenu()
            end
        end)
    else
        print("Menu is already showing")
    end
end