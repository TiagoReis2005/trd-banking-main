function AddTransaction(source, sAccount, sName, iAmount, sType, sReceiver, sMessage, sUuid, cb)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local CitizenId = Player.PlayerData.citizenid

    MySQL.Async.insert("INSERT INTO `transaction_history` (`citizenid`, `trans_id`, `account`, `name`, `amount`, `trans_type`, `receiver`, `message`) VALUES(?, ?, ?, ?, ?, ?, ?, ?)", {
        CitizenId,
        sUuid,
        sAccount,
        sName,
        iAmount,
        sType,
        sReceiver,
        sMessage
    }, function()
        RefreshTransactions(src)
    end)
end

RegisterServerEvent('qb-banking:server:RefreshTransactions', function(prefix)
    local src = source
    SimpleBanking.Config["acc_using"] = prefix
    RefreshTransactions(src)
end)

function RefreshTransactions(source)
    local src = source
    if not src then return end

    local Player = QBCore.Functions.GetPlayer(src)

    if not Player then return end

    local result = MySQL.Sync.fetchAll("SELECT * FROM transaction_history WHERE name =  ? AND DATE(date) > (NOW() - INTERVAL "..SimpleBanking.Config["Days_Transaction_History"].." DAY)", {SimpleBanking.Config["acc_using"] == "personal" and Player.PlayerData.citizenid or SimpleBanking.Config["acc_using"]})

    if result ~= nil then
        TriggerClientEvent("qb-banking:client:UpdateTransactions", src, result)
    end
end

RegisterServerEvent('qb-banking:server:CloseBankMenu', function(prefix)
    SimpleBanking.Config["acc_using"] = "personal"
end)