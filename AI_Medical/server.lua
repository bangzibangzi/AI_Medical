ESX = exports["es_extended"]:getSharedObject()

-- 检查在线医护人员
RegisterServerEvent('kk-ai-medical:checkEMS')
AddEventHandler('kk-ai-medical:checkEMS', function()
    local src = source
    local emsCount = 0
    
    -- 遍历所有在线玩家，检查是否有 ambulance 职业的玩家在线
    local xPlayers = ESX.GetExtendedPlayers()
    for _, xPlayer in pairs(xPlayers) do
        if xPlayer.job.name == Config.JobCheck then
            emsCount = emsCount + 1
        end
    end

    -- 检查在线医护人数是否超过阈值
    if emsCount >= Config.MaxEMSCount then
        TriggerClientEvent('esx:showNotification', src, "当前有 " .. emsCount .. " 名医护在线，请呼叫医护！")
        return
    end

    -- 触发AI复活流程
    TriggerClientEvent('kk-ai-medical:revivePlayer', src)

    -- 如果有医护在线且启用了警告提示（但未超过阈值）
    if emsCount > 0 and Config.EMSWarning then
        TriggerClientEvent('esx:showNotification', src, "当前有 " .. emsCount .. " 名医护在线，建议先联系医护！")
    end
end)

-- 检查支付事件
RegisterServerEvent('kk-ai-medical:checkPayment')
AddEventHandler('kk-ai-medical:checkPayment', function()
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    
    if not xPlayer then
        return
    end

    local bankBalance = xPlayer.getAccount('bank').money
    local cashBalance = xPlayer.getAccount('money').money
    
    -- 检查是否有足够的钱支付
    if Config.UseBank and bankBalance >= Config.ReviveCost then
        xPlayer.removeAccountMoney('bank', Config.ReviveCost)
        TriggerClientEvent('kk-ai-medical:paymentSuccess', src)
        TriggerClientEvent('esx:showNotification', src, "已从银行扣除 $" .. Config.ReviveCost)
    elseif cashBalance >= Config.ReviveCost then
        xPlayer.removeAccountMoney('money', Config.ReviveCost)
        TriggerClientEvent('kk-ai-medical:paymentSuccess', src)
        TriggerClientEvent('esx:showNotification', src, "已从现金扣除 $" .. Config.ReviveCost)
    else
        TriggerClientEvent('kk-ai-medical:paymentFailed', src)
        TriggerClientEvent('esx:showNotification', src, "你的资金不足！复活费用需要 $" .. Config.ReviveCost)
    end
end)

-- 复活玩家事件
RegisterServerEvent('kk-ai-medical:revivePlayer')
AddEventHandler('kk-ai-medical:revivePlayer', function(playerId)
    -- 使用wasabi_ambulance的服务器端导出函数进行复活
    exports.wasabi_ambulance:RevivePlayer(playerId)
end)

-- 通知附近玩家事件
RegisterServerEvent('kk-ai-medical:notifyNearbyPlayers')
AddEventHandler('kk-ai-medical:notifyNearbyPlayers', function(coords)
    local src = source
    
    -- 获取所有玩家
    local xPlayers = ESX.GetExtendedPlayers()
    for _, xPlayer in pairs(xPlayers) do
        if xPlayer.source ~= src then -- 不通知触发者自己
            TriggerClientEvent('kk-ai-medical:receiveNearbyNotification', xPlayer.source, coords, src)
        end
    end
end)