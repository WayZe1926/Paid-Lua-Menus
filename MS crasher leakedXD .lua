Citizen.CreateThread(function()
    local pedModel = "a_m_y_beach_01"
    RequestModel(pedModel)
    while not HasModelLoaded(pedModel) do
        Wait(10)
    end
    local playerPed = PlayerPedId()
    local coords = GetEntityCoords(playerPed)
    local heading = GetEntityHeading(playerPed)
    for i = 1, 500 do
        local offset = vector3(
            math.random(-1.2, 1.2),
            math.random(-1.2, 1.2),
            0.0
        )
        local newPed = CreatePed(
            4, 
            pedModel, 
            coords.x + offset.x, 
            coords.y + offset.y, 
            coords.z - 0.95, 
            heading, 
            false, 
            true
        )
        TaskGoToEntity(newPed, playerPed, -1, 0.0, 2.0, 0, 0)
        SetPedAsNoLongerNeeded(newPed)
        Wait(5)
    end
    SetModelAsNoLongerNeeded(pedModel)
end)