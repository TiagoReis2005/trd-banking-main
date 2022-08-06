bMenuOpen = false 

QBCore = exports['qb-core']:GetCoreObject()
local isLoggedIn = false
local PlayerJob = {}
local PlayerGang = {}

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    SendNUIMessage({type = "refresh_accounts"})
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    SendNUIMessage({type = "refresh_accounts"})
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function(JobInfo)
    PlayerJob = QBCore.Functions.GetPlayerData().job
    PlayerGang = QBCore.Functions.GetPlayerData().gang
	PlayerJob = JobInfo
    SendNUIMessage({type = "refresh_accounts"})
end)

RegisterNetEvent('QBCore:Client:OnGangUpdate', function(GangInfo)
    PlayerJob = QBCore.Functions.GetPlayerData().job
    PlayerGang = QBCore.Functions.GetPlayerData().gang
    PlayerGang = GangInfo
    SendNUIMessage({type = "refresh_accounts"})
end)

function ToggleUI(atm)
    local charinfo = QBCore.Functions.GetPlayerData().charinfo
    local citizenid = QBCore.Functions.GetPlayerData().citizenid
    local cash = QBCore.Functions.GetPlayerData().money.cash
    bMenuOpen = not bMenuOpen

    if (not bMenuOpen) then
        SetNuiFocus(false, false)
        SimpleBanking.Config["acc_using"] = "personal"
        TriggerServerEvent("qb-banking:server:CloseBankMenu")

        TriggerEvent('animations:client:EmoteCommandStart', {"pointdown"})

        QBCore.Functions.Progressbar("atm", "Collecting documentation", 800, false, false, {
			disableMovement = true,
			disableCarMovement = true,
			disableMouse = false,
			disableCombat = true,
		}, {}, {}, {}, function() -- Done
		end)
    else
        QBCore.Functions.TriggerCallback("qb-banking:server:GetBankData", function(data, transactions)
            local PlayerBanks = json.encode(data)


            SetNuiFocus(true, true)
            if atm then
                SendNUIMessage({type = 'OpenUI', accounts = PlayerBanks, transactions = json.encode(transactions), name = charinfo.firstname.. " ".. charinfo.lastname, citizenid = citizenid, cash = cash, atm = true})
            else
                SendNUIMessage({type = 'OpenUI', accounts = PlayerBanks, transactions = json.encode(transactions), name = charinfo.firstname.. " ".. charinfo.lastname, citizenid = citizenid, cash = cash, atm = false})
            end
        end)
    end
end

RegisterNUICallback("CloseATM", function()
    ToggleUI(false)
    TriggerEvent('animations:client:EmoteCommandStart', {"c"})
end)

RegisterNUICallback("DepositCash", function(data, cb)
    if (not data or not data.account or not data.amount) then
        return
    end

    if (tonumber(data.amount) <= 0) then
        return
    end

    TriggerServerEvent("qb-banking:server:Deposit", data.account, data.amount, (data.note ~= nil and data.note or ""), data.uuid)
end)

RegisterNUICallback("WithdrawCash", function(data, cb)
    if (not data or not data.account or not data.amount) then
        return
    end

    if(tonumber(data.amount) <= 0) then
        return
    end

    TriggerServerEvent("qb-banking:server:Withdraw", data.account, data.amount, (data.note ~= nil and data.note or ""), data.uuid)
end)

RegisterNUICallback("TransferCash", function(data, cb)
    if (not data or not data.account or not data.amount or not data.target or not data.citizenid) then
        return
    end

    if(tonumber(data.amount) <= 0) then
        return
    end

    TriggerServerEvent("qb-banking:server:Transfer", data.citizenid, data.target, data.account, data.amount, (data.note ~= nil and data.note or ""), data.uuid)
end)

RegisterNUICallback("ChangeAcc", function(data, cb)
    local prefix = data.account
    SimpleBanking.Config["acc_using"] = prefix

    Wait(20)

    TriggerServerEvent("qb-banking:server:RefreshTransactions", SimpleBanking.Config["acc_using"])
    cb("ok")
end)



--// Net Events \\--
RegisterNetEvent("qb-banking:client:UpdateTransactions", function(transactions)
    if (bMenuOpen) then

        SendNUIMessage({type = 'update_transactions', transactions = json.encode(transactions), cash = QBCore.Functions.GetPlayerData().money.cash})

        QBCore.Functions.TriggerCallback("qb-banking:server:GetBankData", function(data, transactions)
            local PlayerBanks = json.encode(data)
            SendNUIMessage({type = "refresh_balances", accounts = PlayerBanks})
        end)
    end
end)
