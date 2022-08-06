RegisterServerEvent('qb-banking:server:Deposit')
AddEventHandler('qb-banking:server:Deposit', function(account, amount, note, uuid)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)

    if not Player or Player == -1 then
        return
    end

    if not amount or tonumber(amount) <= 0 then
        TriggerClientEvent("QBCore:Notify", src, "Invalid Amount!", "error")
        return
    end

    local amount = tonumber(amount)
    if amount > Player.PlayerData.money["cash"] then
        TriggerClientEvent("QBCore:Notify", src, "You can't afford this!", "error")
        return
    end

    if account == "personal"  then
        local amt = math.floor(amount)

        Player.Functions.RemoveMoney('cash', amt)
        Wait(500)
        Player.Functions.AddMoney('bank', amt)
        RefreshTransactions(src)
        AddTransaction(src, "personal", Player.PlayerData.citizenid, amount, "deposit", "N/A", (note ~= "" and note or ""), uuid)
        return
    end

    if account == "business"  then
        local job = Player.PlayerData.job
        local job_grade = job.grade.name

        local low = string.lower(job.name)
        local grade = string.lower(job_grade)


        local result = MySQL.Sync.fetchAll('SELECT * FROM society WHERE name= ?', {job.name})
        local data = result[1]

        if data then
            local deposit = math.floor(amount)

            Player.Functions.RemoveMoney('cash', deposit)
            TriggerEvent('qb-banking:society:server:DepositMoney', src, deposit, data.name)
            AddTransaction(src, "business", low, amount, "deposit", job.label, (note ~= "" and note or ""), uuid)
        end
    end

    if account == "organization"  then
        local gang = Player.PlayerData.gang
        local gang_grade = gang.grade.name
    
        local low = string.lower(gang.name)
        local grade = string.lower(gang_grade)
    
    
        local result = MySQL.Sync.fetchAll('SELECT * FROM society WHERE name= ?', {gang.name})
        local data = result[1]
    
        if data then
            local deposit = math.floor(amount)
    
            Player.Functions.RemoveMoney('cash', deposit)
            TriggerEvent('qb-banking:society:server:DepositMoney',src, deposit, data.name)
            AddTransaction(src, "organization", low, amount, "deposit", gang.label, (note ~= "" and note or ""), uuid)
        end
    end
end)
