--!strict
--[[
    ========================================================================
    ECONOMY NETWORK MODULE
    ========================================================================
    Mengatur registrasi RemoteEvent dan RemoteFunction yang dibutuhkan
    oleh sistem Live Economy (Wallet, P2P Trade, Job, Shop, Pasar).
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local EconomyNetwork = {}

local REMOTE_EVENTS = {
    "WalletUpdated",          -- Server -> Client: Kirim data uang cash, bank, status
    "TradeInviteReceived",    -- Server -> Client: Undangan trade dari pemain lain
    "TradeStarted",           -- Server -> Client: Sesi trade dimulai
    "TradeUpdated",           -- Server -> Client: Perubahan item/uang di trade
    "TradeCompleted",         -- Server -> Client: Trade sukses dengan detail pajak
    "TradeCancelled",         -- Server -> Client: Trade dibatalkan / gagal
    "EconomyNotification",    -- Server -> Client: Notifikasi saldo bertambah/berkurang
    "JobUpdated",             -- Server -> Client: Status pekerjaan & waktu payday
}

local REMOTE_FUNCTIONS = {
    "SendTradeInvite",        -- Client -> Server: Ajak pemain lain trade
    "RespondTradeInvite",     -- Client -> Server: Terima / tolak trade
    "UpdateTradeOffer",       -- Client -> Server: Masukkan uang/item ke trade slot
    "SetTradeLocked",         -- Client -> Server: Kunci tawaran (Lock in)
    "ConfirmTrade",           -- Client -> Server: Konfirmasi final trade
    "CancelTrade",            -- Client -> Server: Batal trade
    "DepositCash",            -- Client -> Server: Masukkan tunai ke rekening bank
    "WithdrawBank",           -- Client -> Server: Tarik tunai dari bank
    "TransferBank",           -- Client -> Server: Transfer bank ke pemain lain
    "ApplyJob",               -- Client -> Server: Ambil pekerjaan di pos kerja
    "QuitJob",                -- Client -> Server: Resign dari pekerjaan
    "BuyShopItem",            -- Client -> Server: Beli barang dari warung / NPC toko
    "SellShopItem",           -- Client -> Server: Jual barang komoditas ke pedagang/TPI
}

function EconomyNetwork.GetRemoteFolder(): Folder
    local folder = ReplicatedStorage:FindFirstChild("EconomyRemotes")
    if not folder then
        if RunService:IsServer() then
            folder = Instance.new("Folder")
            folder.Name = "EconomyRemotes"
            folder.Parent = ReplicatedStorage
        else
            folder = ReplicatedStorage:WaitForChild("EconomyRemotes", 15) :: Folder
            if not folder then
                error("[EconomyNetwork] Folder EconomyRemotes tidak ditemukan!")
            end
        end
    end
    return folder
end

function EconomyNetwork.InitServer()
    assert(RunService:IsServer(), "[EconomyNetwork] InitServer hanya dapat dijalankan di Server!")
    local folder = EconomyNetwork.GetRemoteFolder()

    for _, eventName in ipairs(REMOTE_EVENTS) do
        if not folder:FindFirstChild(eventName) then
            local rem = Instance.new("RemoteEvent")
            rem.Name = eventName
            rem.Parent = folder
        end
    end

    for _, funcName in ipairs(REMOTE_FUNCTIONS) do
        if not folder:FindFirstChild(funcName) then
            local rem = Instance.new("RemoteFunction")
            rem.Name = funcName
            rem.Parent = folder
        end
    end
end

function EconomyNetwork.GetEvent(name: string): RemoteEvent
    local folder = EconomyNetwork.GetRemoteFolder()
    local rem = folder:FindFirstChild(name)
    if not rem and RunService:IsClient() then
        rem = folder:WaitForChild(name, 10)
    end
    assert(rem and rem:IsA("RemoteEvent"), "[EconomyNetwork] RemoteEvent tidak ditemukan: " .. name)
    return rem
end

function EconomyNetwork.GetFunction(name: string): RemoteFunction
    local folder = EconomyNetwork.GetRemoteFolder()
    local rem = folder:FindFirstChild(name)
    if not rem and RunService:IsClient() then
        rem = folder:WaitForChild(name, 10)
    end
    assert(rem and rem:IsA("RemoteFunction"), "[EconomyNetwork] RemoteFunction tidak ditemukan: " .. name)
    return rem
end

return EconomyNetwork
