RegisterServerEvent('qb-banking:server:Withdraw', function(account, amount, note, uuid)
    local src = source
    if not src then return end
    local Player = QBCore.Functions.GetPlayer(src)

    if not Player or Player == -1 then
        return
    end

    if not amount or tonumber(amount) <= 0 then
        TriggerClientEvent("QBCore:Notify", src, "Invalid Amount!", "error")
        return
    end

    amount = tonumber(amount)

    if account == "personal" then
        if amount > Player.PlayerData.money["bank"] then
            TriggerClientEvent("QBCore:Notify", src, "Your bank doesn't have this much money!", "error") 
            return
        end
        local withdraw = math.floor(amount)

        Player.Functions.AddMoney('cash', withdraw)
        Player.Functions.RemoveMoney('bank', withdraw)

        AddTransaction(src, "personal", Player.PlayerData.citizenid, -amount, "withdraw", "N/A", (note ~= "" and note or ""), uuid)
        RefreshTransactions(src)
    end

    if(account == "business") then
        local job = Player.PlayerData.job

        if not SimpleBanking.Config["business_ranks"][string.lower(job.grade.name)] and not SimpleBanking.Config["business_ranks_overrides"][string.lower(job.name)] then
            return
        end

        local low = string.lower(job.name)
        local grade = string.lower(job.grade.name)

        if (SimpleBanking.Config["business_ranks_overrides"][low] and not SimpleBanking.Config["business_ranks_overrides"][low][grade]) then

            return
        end

        local result = MySQL.Sync.fetchAll('SELECT * FROM society WHERE name = ?', {job.name})
        local data = result[1]

        if data then
            local sM = tonumber(data.money)
            if sM >= amount then
                TriggerEvent('qb-banking:society:server:WithdrawMoney',src, amount, data.name)

                AddTransaction(src, "business", low, -amount, "deposit", job.label, (note ~= "" and note or ""), uuid)
                Player.Functions.AddMoney('cash', amount)
            else
                TriggerClientEvent("QBCore:Notify", src, "Not enough money current balance: €"..sM, "error") 
            end
        end
    end

    if(account == "organization") then
        local gang = Player.PlayerData.gang

        if not SimpleBanking.Config["gang_ranks"][string.lower(gang.grade.name)] and not SimpleBanking.Config["gang_ranks_overrides"][string.lower(gang.name)] then
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
            local sM = tonumber(data.money)
            if sM >= amount then
                TriggerEvent('qb-banking:society:server:WithdrawMoney',src, amount, data.name)

                AddTransaction(src, "organization", low, -amount, "deposit", gang.label, (note ~= "" and note or ""), uuid)
                Player.Functions.AddMoney('cash', amount)
            else
                TriggerClientEvent("QBCore:Notify", src, "Not enough money current balance: €"..sM, "error") 
            end
        end
    end
end)