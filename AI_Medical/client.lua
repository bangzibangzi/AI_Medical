ESX = exports["es_extended"]:getSharedObject()

-- 创建一个表来存储需要显示3D文字的玩家
local activeRevives = {}
local isReviving = false -- 添加状态标记

-- 显示3D文字函数
function Draw3DText(x, y, z, text, remainingTime)
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local distance = #(playerCoords - vector3(x, y, z))
    
    if distance <= Config.TextDistance then
        local onScreen, _x, _y = World3dToScreen2d(x, y, z)
        if onScreen then
            -- 设置文字属性
            SetTextScale(Config.TextScale, Config.TextScale)
            SetTextFont(0)
            SetTextProportional(1)
            SetTextColour(Config.TextColor.r, Config.TextColor.g, Config.TextColor.b, 255)
            SetTextDropshadow(0, 0, 0, 0, 255)
            SetTextEdge(2, 0, 0, 0, 150)
            SetTextDropShadow()
            SetTextOutline()
            SetTextEntry("STRING")
            SetTextCentre(1)
            
            -- 添加文字内容和倒计时
            local displayText = text
            if remainingTime then
                displayText = displayText .. "\n剩余时间: " .. remainingTime .. " 秒"
            end
            AddTextComponentString(displayText)
            DrawText(_x, _y)
        end
    end
end

-- 创建一个线程来处理所有3D文字的显示
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        for coords, endTime in pairs(activeRevives) do
            if GetGameTimer() < endTime then
                local remainingTime = math.ceil((endTime - GetGameTimer()) / 1000)
                Draw3DText(coords.x, coords.y, coords.z + 1.0, "正在呼叫AI医护...\n请等待救援", remainingTime)
            else
                activeRevives[coords] = nil
            end
        end
    end
end)

-- 注册聊天命令 /120
RegisterCommand('120', function()
    local player = PlayerPedId()
    local playerId = GetPlayerServerId(PlayerId())
    
    -- 检查是否正在复活中
    if isReviving then
        Notify("正在复活中，请稍候...", "error")
        return
    end
    
    -- 检查玩家是否死亡
    local isDead = exports['wasabi_ambulance']:isPlayerDead(playerId)
    
    if not isDead then
        Notify("你并没有死亡，无法使用该命令！", "error")
        return
    end

    -- 如果玩家死亡，检查服务器是否有在线的医护人员
    isReviving = true
    TriggerServerEvent('kk-ai-medical:checkEMS')
end, false)

-- 事件：复活玩家
RegisterNetEvent('kk-ai-medical:revivePlayer')
AddEventHandler('kk-ai-medical:revivePlayer', function()
    local player = PlayerPedId()
    local playerId = GetPlayerServerId(PlayerId())
    local playerCoords = GetEntityCoords(player)
    
    -- 再次检查玩家是否死亡
    local isDead = exports['wasabi_ambulance']:isPlayerDead(playerId)
    
    if not isDead then
        isReviving = false
        Notify("你现在是活着的状态，无法使用复活功能。", "error")
        return
    end

    -- 通知服务器通知附近的玩家
    TriggerServerEvent('kk-ai-medical:notifyNearbyPlayers', playerCoords)
    
    -- 添加到活动复活列表
    local coords = GetEntityCoords(player)
    activeRevives[coords] = GetGameTimer() + Config.ProgressTime
    
    Notify("AI医护系统已接收呼叫", "success")
    
    -- 发送付款请求到服务器
    TriggerServerEvent('kk-ai-medical:checkPayment')
end)

-- 付款成功事件
RegisterNetEvent('kk-ai-medical:paymentSuccess')
AddEventHandler('kk-ai-medical:paymentSuccess', function()
    local player = PlayerPedId()
    local playerId = GetPlayerServerId(PlayerId())
    
    -- 执行复活流程
    Citizen.SetTimeout(Config.ProgressTime, function()
        TriggerServerEvent('kk-ai-medical:revivePlayer', playerId)
        exports['wasabi_ambulance']:clearPlayerInjury(true)
        ClearPedTasks(player)
        isReviving = false
        
        -- 清除该玩家的3D文字显示
        local coords = GetEntityCoords(player)
        activeRevives[coords] = nil
    end)
end)

-- 付款失败事件
RegisterNetEvent('kk-ai-medical:paymentFailed')
AddEventHandler('kk-ai-medical:paymentFailed', function()
    local player = PlayerPedId()
    local coords = GetEntityCoords(player)
    
    -- 清除复活状态和3D文字显示
    isReviving = false
    activeRevives[coords] = nil
    Notify("由于支付失败，无法进行救援", "error")
end)

-- 接收附近玩家通知
RegisterNetEvent('kk-ai-medical:receiveNearbyNotification')
AddEventHandler('kk-ai-medical:receiveNearbyNotification', function(targetCoords, targetId)
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local distance = #(playerCoords - vector3(targetCoords.x, targetCoords.y, targetCoords.z))
    
    if distance <= Config.NotifyDistance then
        Notify("附近的玩家 #" .. targetId .. " 正在呼叫AI医护\n距离: " .. math.floor(distance) .. "米", "info")
        
        -- 添加到活动复活列表
        local coords = vector3(targetCoords.x, targetCoords.y, targetCoords.z)
        activeRevives[coords] = GetGameTimer() + Config.ProgressTime
    end
end)

-- 通知函数
function Notify(message, type)
    if Config.NotifyType == 'esx' then
        ESX.ShowNotification(message)
    elseif Config.NotifyType == 'mythic_notify' then
        exports['mythic_notify']:DoHudText(type, message)
    end
end