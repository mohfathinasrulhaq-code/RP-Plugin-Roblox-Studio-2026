--!strict
--[[
    ========================================================================
    ECONOMY SERVER (MAIN SERVER CONTROLLER)
    ========================================================================
    Inisialisasi sistem Live Economy di Server:
    - Bootstrapping RemoteEvents & RemoteFunctions
    - Loading Player Data on Join & Saving on Leave
    - Event Routing untuk P2P Trade, ATM Bank, Job & Toko
    - Pengurangan Kebutuhan Hidup (Hunger & Thirst Sink Loop)
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local EconomyConfig = require(ReplicatedStorage.EconomySystem.Config.EconomyConfig)
local EconomyNetwork = require(ReplicatedStorage.EconomySystem.Modules.EconomyNetwork)

-- Init Remotes
EconomyNetwork.InitServer()

-- Inisialisasi Layanan
local WalletService = require(ServerScriptService.EconomySystem.Services.WalletService)
local TradeService = require(ServerScriptService.EconomySystem.Services.TradeService)
local JobService = require(ServerScriptService.EconomySystem.Services.JobService)
local ShopService = require(ServerScriptService.EconomySystem.Services.ShopService)

TradeService.Init(WalletService)
JobService.Init(WalletService)
ShopService.Init(WalletService)

print("[IndoRP Live Economy] Server System Initialized Successfully!")

-- [ KONEKSI EVENT PLAYER ]
Players.PlayerAdded:Connect(function(player)
    WalletService.LoadPlayerData(player)
end)

Players.PlayerRemoving:Connect(function(player)
    -- Batalkan trade jika pemain disconnect saat trade
    TradeService.CancelTrade(player, player.DisplayName .. " telah keluar dari game.")
    WalletService.CleanupPlayer(player)
end)

-- Untuk player yang sudah ada jika script di-reload
for _, player in ipairs(Players:GetPlayers()) do
    task.spawn(function()
        WalletService.LoadPlayerData(player)
    end)
end

-- [ P2P TRADE INVITATION TRACKER ]
local PendingInvites: { [Player]: Player } = {} -- Inviter -> Target

EconomyNetwork.GetFunction("SendTradeInvite").OnServerInvoke = function(inviter: Player, targetName: string): (boolean, string?)
    local target = Players:FindFirstChild(targetName)
    if not target or target == inviter then
        return false, "Pemain tidak ditemukan atau tidak valid!"
    end

    local c1 = inviter.Character and inviter.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
    local c2 = target.Character and target.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
    if not c1 or not c2 or (c1.Position - c2.Position).Magnitude > EconomyConfig.Trade.MaxDistanceBetweenPlayers then
        return false, "Jarak terlalu jauh dengan pemain tersebut!"
    end

    PendingInvites[inviter] = target

    -- Kirimkan prompt ke target
    local rem = EconomyNetwork.GetEvent("TradeInviteReceived")
    rem:FireClient(target, {
        InviterName = inviter.DisplayName,
        InviterUser = inviter.Name,
    })

    return true, "Undangan transaksi berhasil dikirim ke " .. target.DisplayName
end

EconomyNetwork.GetFunction("RespondTradeInvite").OnServerInvoke = function(respondent: Player, inviterName: string, accept: boolean): boolean
    local inviter = Players:FindFirstChild(inviterName)
    if not inviter then return false end

    if PendingInvites[inviter] ~= respondent then
        return false
    end

    PendingInvites[inviter] = nil

    if accept then
        local success, msg = TradeService.StartTrade(inviter, respondent)
        if not success and msg then
            WalletService.Notify(respondent, msg, "Warning")
            WalletService.Notify(inviter, msg, "Warning")
        end
        return success
    else
        WalletService.Notify(inviter, respondent.DisplayName .. " menolak undangan transaksi.", "Info")
        return true
    end
end

EconomyNetwork.GetFunction("UpdateTradeOffer").OnServerInvoke = function(player: Player, cash: number, items: { [string]: number }): boolean
    return TradeService.UpdateOffer(player, cash, items)
end

EconomyNetwork.GetFunction("SetTradeLocked").OnServerInvoke = function(player: Player, locked: boolean): boolean
    return TradeService.SetLocked(player, locked)
end

EconomyNetwork.GetFunction("ConfirmTrade").OnServerInvoke = function(player: Player): boolean
    return TradeService.ConfirmTrade(player)
end

EconomyNetwork.GetFunction("CancelTrade").OnServerInvoke = function(player: Player): boolean
    TradeService.CancelTrade(player, player.DisplayName .. " membatalkan transaksi.")
    return true
end

-- [ PERBANKAN & ATM ]
EconomyNetwork.GetFunction("DepositCash").OnServerInvoke = function(player: Player, amount: number): boolean
    return WalletService.Deposit(player, amount)
end

EconomyNetwork.GetFunction("WithdrawBank").OnServerInvoke = function(player: Player, amount: number): boolean
    return WalletService.Withdraw(player, amount)
end

EconomyNetwork.GetFunction("TransferBank").OnServerInvoke = function(player: Player, targetName: string, amount: number): boolean
    return WalletService.Transfer(player, targetName, amount)
end

-- [ PEKERJAAN ]
EconomyNetwork.GetFunction("ApplyJob").OnServerInvoke = function(player: Player, jobId: string): boolean
    return JobService.SetJob(player, jobId)
end

EconomyNetwork.GetFunction("QuitJob").OnServerInvoke = function(player: Player): boolean
    return JobService.QuitJob(player)
end

-- [ TOKO & PASAR ]
EconomyNetwork.GetFunction("BuyShopItem").OnServerInvoke = function(player: Player, itemId: string, quantity: number, paymentMethod: "Cash" | "Bank"): boolean
    return ShopService.BuyItem(player, itemId, quantity, paymentMethod or "Cash")
end

EconomyNetwork.GetFunction("SellShopItem").OnServerInvoke = function(player: Player, itemId: string, quantity: number): boolean
    return ShopService.SellItem(player, itemId, quantity)
end

-- [ SINK OTOMATIS: AUTO-SAVE & PAJAK KEKAYAAN BERKALA ]
task.spawn(function()
    while true do
        task.wait(EconomyConfig.DataStore.AutoSaveInterval)
        for _, player in ipairs(Players:GetPlayers()) do
            WalletService.SavePlayerData(player)
        end
    end
end)
