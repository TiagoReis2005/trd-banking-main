RegisterServerEvent('qb-banking:server:Transfer')
AddEventHandler('qb-banking:server:Transfer', function(citizenid, target, account, amount, note, uuid)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)

    target = target ~= nil and tonumber(target) or nil
    if target == src or Player.PlayerData.citizenid == citizenid then
        TriggerClientEvent("QBCore:Notify", src, "You can't afford this!", "error")
        return
    end

    target = tonumber(target)
    amount = tonumber(amount)
    local targetPly = QBCore.Functions.GetPlayer(target)
    if not targetPly then
        targetPly = QBCore.Functions.GetPlayerByCitizenId(citizenid)
    end

    if not targetPly or targetPly == -1 then
        TriggerClientEvent("QBCore:Notify", src, "This citizen is out of town!", "error")
        return
    end

    if (target == src) then
        TriggerClientEvent("QBCore:Notify", src, "You can't send money to yourself!", "error")
        return
    end

    if (not amount or amount <= 0) then
        TriggerClientEvent("QBCore:Notify", src, "Invalid Amount!", "error")
        return
    end

    if (account == "personal") then
        local balance = Player.PlayerData.money["bank"]--ply.getAccount("bank").money

        if amount > balance then
            TriggerClientEvent("QBCore:Notify", src, "You can't afford this!", "error")
            return
        end

        Player.Functions.RemoveMoney('bank', amount)
        targetPly.Functions.AddMoney('bank', math.floor(amount))

        AddTransaction(src, "personal", Player.PlayerData.citizenid, -amount, "transfer", targetPly.PlayerData.charinfo.firstname, "Transfered $" .. format_int(amount) .. " to " .. targetPly.PlayerData.charinfo.firstname, uuid)
        AddTransaction(targetPly.PlayerData.source, "personal", targetPly.PlayerData.citizenid, amount, "transfer", Player.PlayerData.charinfo.firstname, "Received $" .. format_int(amount) .. " from " ..Player.PlayerData.charinfo.firstname, uuid)
    end

    if (account == "business") then
        local job = Player.PlayerData.job

        if (not SimpleBanking.Config["business_ranks"][string.lower(job.grade.name)] and not SimpleBanking.Config["business_ranks_overrides"][string.lower(job.name)]) then
            return
        end

        local low = string.lower(job.name)
        local grade = string.lower(job.grade.name)

        if (SimpleBanking.Config["business_ranks_overrides"][low] and not SimpleBanking.Config["business_ranks_overrides"][low][grade]) then
            return
        end

        local result = MySQL.Sync.fetchAll('SELECT * FROM society WHERE name= ?', {job.name})
        local data = result[1]
        if data then
            local society = data.name

            TriggerEvent('qb-banking:society:server:WithdrawMoney', src, amount, society)
            Wait(50)
            targetPly.Functions.AddMoney('cash', amount)
            AddTransaction(src, "personal", low, -amount, "transfer", targetPly.PlayerData.charinfo.firstname, "Transfered $" .. format_int(amount) .. " to " .. targetPly.PlayerData.charinfo.firstname .. " from " .. job.label .. "'s account", uuid)
        end
    end

    if (account == "organization") then
        local gang = Player.PlayerData.gang

        if (not SimpleBanking.Config["gang_ranks"][string.lower(gang.grade.name)] and not SimpleBanking.Config["gang_ranks_overrides"][string.lower(gang.name)]) then
            return
        end

        local low = string.lower(gang.name)
        local grade = string.lower(gang.grade.name)

        if (SimpleBanking.Config["gang_ranks_overrides"][low] and not SimpleBanking.Config["gang_ranks_overrides"][low][grade]) then
            return
        end

        local result = MySQL.Sync.fetchAll('SELECT * FROM society WHERE name= ?', {gang.name})
        local data = result[1]
        if data then
            local society = data.name

            TriggerEvent('qb-banking:society:server:WithdrawMoney', src, amount, society)
            Wait(50)
            targetPly.Functions.AddMoney('cash', amount)
            AddTransaction(src, "personal", low, -amount, "transfer", targetPly.PlayerData.charinfo.firstname, "Transfered $" .. format_int(amount) .. " to " .. targetPly.PlayerData.charinfo.firstname .. " from " .. gang.label .. "'s account", uuid)
        end
    end
end)
