QBCore = exports['qb-core']:GetCoreObject()
QBCore.Functions.CreateCallback("qb-banking:server:GetBankData", function(source, cb)
    local src = source
    if not src then return end

    local Player = QBCore.Functions.GetPlayer(src)

    if not Player then return end

    local PlayerMoney = Player.PlayerData.money["bank"] or 0 
    local CitizenId = Player.PlayerData.citizenid 

    local TransactionHistory = {}
    local TransactionRan = false
    local tbl = {}
    tbl[1] = {
        type = "personal",
        amount = PlayerMoney
    }

    local job = Player.PlayerData.job
    
    if (job.name and job.grade.name) then
        if(SimpleBanking.Config["business_ranks"][string.lower(job.grade.name)] or SimpleBanking.Config["business_ranks_overrides"][string.lower(job.name)] and SimpleBanking.Config["business_ranks_overrides"][string.lower(job.name)][string.lower(job.grade.name)]) then
            local result =  MySQL.Sync.fetchAll('SELECT * FROM society WHERE name= ?', {job.name})
            local data = result[1]

            if data ~= nil then
                tbl[#tbl + 1] = {
                    type = "business",
                    name = job.label,
                    amount = format_int(data.money) or 0,
                    prefix = job.name
                }
            end
        end
    end

    local gang = Player.PlayerData.gang

    if (gang.name and gang.grade.name) then
        if(SimpleBanking.Config["gang_ranks"][string.lower(gang.grade.name)] or SimpleBanking.Config["gang_ranks_overrides"][string.lower(gang.name)] and SimpleBanking.Config["gang_ranks_overrides"][string.lower(gang.name)][string.lower(gang.grade.name)]) then

            local result = MySQL.Sync.fetchAll('SELECT * FROM society WHERE name= ?', {gang.name})
            local data = result[1]

            if data ~= nil then
                tbl[#tbl + 1] = {
                    type = "organization",
                    name = gang.label,
                    amount = format_int(data.money) or 0
                }
            end
        end
    end
    local accSearch = (SimpleBanking.Config["acc_using"] == "personal" and Player.PlayerData.citizenid) or SimpleBanking.Config["acc_using"]
    local result = MySQL.Sync.fetchAll("SELECT * FROM transaction_history WHERE name =  ? AND DATE(date) > (NOW() - INTERVAL "..SimpleBanking.Config["Days_Transaction_History"].." DAY)", {accSearch})

    if result ~= nil then
        TransactionRan = true
        TransactionHistory = result
    end


    repeat
        Wait(0)
    until 
        TransactionRan
    cb(tbl, TransactionHistory)
end)
