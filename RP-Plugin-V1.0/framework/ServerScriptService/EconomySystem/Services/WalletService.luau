--!strict
--[[
    ========================================================================
    WALLET SERVICE (SERVER)
    ========================================================================
    Mengatur keuangan pemain:
    - Saldo Tunai (Cash di dompet) & Saldo Bank (Rekening)
    - DataStore Persistence (Auto-save, Session locking)
    - Transaksi Setor / Tarik ATM & Transfer Antar Pemain
    - Pengurangan Uang (Sinks) & Pencatatan Pajak
--]]

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EconomyConfig = require(ReplicatedStorage.EconomySystem.Config.EconomyConfig)
local EconomyNetwork = require(ReplicatedStorage.EconomySystem.Modules.EconomyNetwork)

local Types = require(ReplicatedStorage.EconomySystem.Modules.Types)
type PlayerEconomyData = Types.PlayerEconomyData

local WalletService = {}
local PlayerDataCache: { [Player]: PlayerEconomyData } = {}
local DataStore = nil

-- Coba akses DataStore (jika diaktifkan di Game Settings)
pcall(function()
    DataStore = DataStoreService:GetDataStore(EconomyConfig.DataStore.DataStoreKey)
end)

function WalletService.GetDefaultData(): PlayerEconomyData
    return {
        Cash = EconomyConfig.Currency.StartingCash,
        Bank = EconomyConfig.Currency.StartingBank,
        JobId = "Unemployed",
        JobExperience = 0,
        Inventory = {
            ["food_nasgor"] = { Id = "food_nasgor", Quantity = 2, ItemKey = "food_nasgor" },
            ["drink_esteh"] = { Id = "drink_esteh", Quantity = 3, ItemKey = "drink_esteh" },
        },
        LastPaydayTimestamp = os.time(),
        TotalEarned = 0,
        TotalSpent = 0,
        TotalTaxPaid = 0,
    }
end

function WalletService.LoadPlayerData(player: Player): PlayerEconomyData
    local defaultData = WalletService.GetDefaultData()
    local loadedData = nil

    if DataStore then
        local success, err = pcall(function()
            loadedData = DataStore:GetAsync("Player_" .. tostring(player.UserId))
        end)
        if not success then
            warn("[WalletService] Gagal memuat DataStore untuk " .. player.Name .. ": " .. tostring(err))
        end
    end

    if loadedData and type(loadedData) == "table" then
        -- Gabungkan loadedData dengan defaultData untuk memastikan backward-compatibility
        for k, v in pairs(defaultData) do
            if loadedData[k] == nil then
                loadedData[k] = v
            end
        end
        PlayerDataCache[player] = loadedData
    else
        PlayerDataCache[player] = defaultData
    end

    WalletService.SyncToClient(player)
    return PlayerDataCache[player]
end

function WalletService.SavePlayerData(player: Player)
    local data = PlayerDataCache[player]
    if not data or not DataStore then return end

    local success, err = pcall(function()
        DataStore:SetAsync("Player_" .. tostring(player.UserId), data)
    end)
    if not success then
        warn("[WalletService] Gagal menyimpan data untuk " .. player.Name .. ": " .. tostring(err))
    end
end

function WalletService.GetData(player: Player): PlayerEconomyData?
    return PlayerDataCache[player]
end

function WalletService.SyncToClient(player: Player)
    local data = PlayerDataCache[player]
    if not data then return end

    local rem = EconomyNetwork.GetEvent("WalletUpdated")
    rem:FireClient(player, {
        Cash = data.Cash,
        Bank = data.Bank,
        JobId = data.JobId,
        Inventory = data.Inventory,
        TotalTaxPaid = data.TotalTaxPaid,
    })
end

function WalletService.Notify(player: Player, message: string, notifType: "Success" | "Warning" | "Info" | "Danger")
    local rem = EconomyNetwork.GetEvent("EconomyNotification")
    rem:FireClient(player, message, notifType)
end

-- [ OPERASI KEUANGAN ]

function WalletService.AddCash(player: Player, amount: number, reason: string?): boolean
    if amount <= 0 then return false end
    local data = PlayerDataCache[player]
    if not data then return false end

    data.Cash = math.min(data.Cash + amount, EconomyConfig.Currency.MaxCashOnHand)
    data.TotalEarned += amount
    WalletService.SyncToClient(player)
    WalletService.Notify(player, "+ " .. EconomyConfig.FormatMoney(amount) .. " (" .. (reason or "Pemasukan") .. ")", "Success")
    return true
end

function WalletService.RemoveCash(player: Player, amount: number, reason: string?): boolean
    if amount <= 0 then return false end
    local data = PlayerDataCache[player]
    if not data or data.Cash < amount then
        WalletService.Notify(player, "Uang tunai tidak mencukupi!", "Warning")
        return false
    end

    data.Cash -= amount
    data.TotalSpent += amount
    WalletService.SyncToClient(player)
    WalletService.Notify(player, "- " .. EconomyConfig.FormatMoney(amount) .. " (" .. (reason or "Pengeluaran") .. ")", "Info")
    return true
end

function WalletService.AddBank(player: Player, amount: number, reason: string?): boolean
    if amount <= 0 then return false end
    local data = PlayerDataCache[player]
    if not data then return false end

    data.Bank = math.min(data.Bank + amount, EconomyConfig.Currency.MaxBankBalance)
    data.TotalEarned += amount
    WalletService.SyncToClient(player)
    WalletService.Notify(player, "Transfer masuk ke rekening: + " .. EconomyConfig.FormatMoney(amount), "Success")
    return true
end

function WalletService.RemoveBank(player: Player, amount: number, reason: string?): boolean
    if amount <= 0 then return false end
    local data = PlayerDataCache[player]
    if not data or data.Bank < amount then
        WalletService.Notify(player, "Saldo rekening ATM tidak mencukupi!", "Warning")
        return false
    end

    data.Bank -= amount
    data.TotalSpent += amount
    WalletService.SyncToClient(player)
    WalletService.Notify(player, "Saldo terpotong: - " .. EconomyConfig.FormatMoney(amount) .. " (" .. (reason or "Debit") .. ")", "Info")
    return true
end

-- Setor Tunai di ATM
function WalletService.Deposit(player: Player, amount: number): boolean
    if amount <= 0 then return false end
    local data = PlayerDataCache[player]
    if not data or data.Cash < amount then
        WalletService.Notify(player, "Uang tunai Anda tidak cukup untuk disetor!", "Warning")
        return false
    end

    data.Cash -= amount
    data.Bank = math.min(data.Bank + amount, EconomyConfig.Currency.MaxBankBalance)
    WalletService.SyncToClient(player)
    WalletService.Notify(player, "Berhasil menyetor " .. EconomyConfig.FormatMoney(amount) .. " ke rekening bank.", "Success")
    return true
end

-- Tarik Tunai di ATM
function WalletService.Withdraw(player: Player, amount: number): boolean
    if amount <= 0 then return false end
    local data = PlayerDataCache[player]
    if not data or data.Bank < amount then
        WalletService.Notify(player, "Saldo ATM Anda tidak cukup untuk penarikan ini!", "Warning")
        return false
    end

    data.Bank -= amount
    data.Cash = math.min(data.Cash + amount, EconomyConfig.Currency.MaxCashOnHand)
    WalletService.SyncToClient(player)
    WalletService.Notify(player, "Berhasil menarik tunai " .. EconomyConfig.FormatMoney(amount), "Success")
    return true
end

-- Transfer Bank Antar Pemain (Dikenakan Biaya Admin Bank)
function WalletService.Transfer(sender: Player, targetPlayerName: string, amount: number): boolean
    if amount <= 0 then return false end
    local senderData = PlayerDataCache[sender]
    if not senderData then return false end

    local targetPlayer = Players:FindFirstChild(targetPlayerName)
    if not targetPlayer or targetPlayer == sender then
        WalletService.Notify(sender, "Pemain penerima tidak valid atau sedang offline!", "Warning")
        return false
    end

    local targetData = PlayerDataCache[targetPlayer]
    if not targetData then
        WalletService.Notify(sender, "Data penerima belum siap!", "Warning")
        return false
    end

    local fee = math.max(
        math.floor(amount * (EconomyConfig.LiveEconomy.BankTransferFeePercent / 100)),
        EconomyConfig.LiveEconomy.BankTransferFeeMin
    )
    local totalDeduction = amount + fee

    if senderData.Bank < totalDeduction then
        WalletService.Notify(sender, "Saldo tidak cukup! Biaya transfer: " .. EconomyConfig.FormatMoney(fee), "Warning")
        return false
    end

    senderData.Bank -= totalDeduction
    senderData.TotalTaxPaid += fee
    targetData.Bank = math.min(targetData.Bank + amount, EconomyConfig.Currency.MaxBankBalance)

    WalletService.SyncToClient(sender)
    WalletService.SyncToClient(targetPlayer)

    WalletService.Notify(sender, "Transfer " .. EconomyConfig.FormatMoney(amount) .. " ke " .. targetPlayer.DisplayName .. " berhasil! (Biaya Admin: " .. EconomyConfig.FormatMoney(fee) .. ")", "Success")
    WalletService.Notify(targetPlayer, "Menerima transfer saldo " .. EconomyConfig.FormatMoney(amount) .. " dari " .. sender.DisplayName, "Info")
    return true
end

-- [ MANAJEMEN INVENTORY ]

function WalletService.GetItemQuantity(player: Player, itemId: string): number
    local data = PlayerDataCache[player]
    if not data or not data.Inventory[itemId] then return 0 end
    return data.Inventory[itemId].Quantity
end

function WalletService.AddItem(player: Player, itemId: string, quantity: number): boolean
    local itemDef = EconomyConfig.Items[itemId]
    if not itemDef or quantity <= 0 then return false end

    local data = PlayerDataCache[player]
    if not data then return false end

    local cur = data.Inventory[itemId]
    if cur then
        cur.Quantity += quantity
    else
        data.Inventory[itemId] = {
            Id = itemId,
            Quantity = quantity,
            ItemKey = itemId,
        }
    end

    WalletService.SyncToClient(player)
    WalletService.Notify(player, "+ " .. quantity .. "x " .. itemDef.Name, "Success")
    return true
end

function WalletService.RemoveItem(player: Player, itemId: string, quantity: number): boolean
    local data = PlayerDataCache[player]
    if not data or not data.Inventory[itemId] or data.Inventory[itemId].Quantity < quantity then
        return false
    end

    data.Inventory[itemId].Quantity -= quantity
    if data.Inventory[itemId].Quantity <= 0 then
        data.Inventory[itemId] = nil
    end

    WalletService.SyncToClient(player)
    local itemDef = EconomyConfig.Items[itemId]
    if itemDef then
        WalletService.Notify(player, "- " .. quantity .. "x " .. itemDef.Name, "Info")
    end
    return true
end

function WalletService.CleanupPlayer(player: Player)
    WalletService.SavePlayerData(player)
    PlayerDataCache[player] = nil
end

return WalletService
