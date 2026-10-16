--!strict
--[[
    ========================================================================
    TRADE SERVICE (SERVER - P2P LIVE ECONOMY TRADE)
    ========================================================================
    Sistem transaksi aman antar pemain dengan konsep Live Economy:
    1. Undangan Trade (Invite -> Accept)
    2. Input Tawaran (Barang & Uang Tunai)
    3. Proteksi Kunci 2 Arah (Lock Offer -> Countdown Timer)
    4. Anti-Scam & Anti-Duplikasi (Atomic Validation)
    5. Trade Tax / Pajak Pasar (Mekanisme Deflasi / Money Sink Otomatis)
--]]

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EconomyConfig = require(ReplicatedStorage.EconomySystem.Config.EconomyConfig)
local EconomyNetwork = require(ReplicatedStorage.EconomySystem.Modules.EconomyNetwork)
local Types = require(ReplicatedStorage.EconomySystem.Modules.Types)

type TradeSession = Types.TradeSession
type TradeOffer = Types.TradeOffer

local TradeService = {}
local ActiveSessions: { [string]: TradeSession } = {}
local PlayerToSessionId: { [Player]: string } = {}
local WalletService = nil

function TradeService.Init(walletServiceRef)
    WalletService = walletServiceRef
end

local function GetDistance(p1: Player, p2: Player): number
    local c1 = p1.Character and p1.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
    local c2 = p2.Character and p2.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
    if c1 and c2 then
        return (c1.Position - c2.Position).Magnitude
    end
    return 9999
end

function TradeService.GetSession(player: Player): TradeSession?
    local id = PlayerToSessionId[player]
    if not id then return nil end
    return ActiveSessions[id]
end

function TradeService.CreateOffer(): TradeOffer
    return {
        Cash = 0,
        Items = {},
        IsLocked = false,
        IsConfirmed = false,
    }
end

-- Memulai Sesi Trade antara dua pemain
function TradeService.StartTrade(p1: Player, p2: Player): (boolean, string?)
    if PlayerToSessionId[p1] or PlayerToSessionId[p2] then
        return false, "Salah satu pemain sedang berada dalam sesi transaksi lain!"
    end

    if GetDistance(p1, p2) > EconomyConfig.Trade.MaxDistanceBetweenPlayers then
        return false, "Jarak terlalu jauh untuk memulai perdagangan!"
    end

    local sessionId = HttpService:GenerateGUID(false)
    local session: TradeSession = {
        SessionId = sessionId,
        Player1 = p1,
        Player2 = p2,
        Offer1 = TradeService.CreateOffer(),
        Offer2 = TradeService.CreateOffer(),
        CreatedAt = os.time(),
        LastInteractionAt = os.time(),
        Status = "Trading",
    }

    ActiveSessions[sessionId] = session
    PlayerToSessionId[p1] = sessionId
    PlayerToSessionId[p2] = sessionId

    local startedRem = EconomyNetwork.GetEvent("TradeStarted")
    startedRem:FireClient(p1, { PartnerName = p2.DisplayName, PartnerUser = p2.Name, SessionId = sessionId })
    startedRem:FireClient(p2, { PartnerName = p1.DisplayName, PartnerUser = p1.Name, SessionId = sessionId })

    return true, nil
end

-- Update Penawaran (Tambah/Ubah Uang atau Item)
function TradeService.UpdateOffer(player: Player, cash: number, items: { [string]: number }): boolean
    local session = TradeService.GetSession(player)
    if not session or session.Status == "Completed" or session.Status == "Cancelled" then
        return false
    end

    local isP1 = (session.Player1 == player)
    local myOffer = if isP1 then session.Offer1 else session.Offer2

    -- Jika sudah di-lock, tidak bisa diubah kecuali di-unlock dulu
    if myOffer.IsLocked then
        return false
    end

    -- Validasi kepemilikan Uang Tunai
    local playerData = WalletService.GetData(player)
    if not playerData then return false end

    cash = math.clamp(math.floor(math.abs(cash)), 0, math.min(playerData.Cash, EconomyConfig.Trade.MaxCashPerTrade))

    -- Validasi kepemilikan Item di inventory
    local validatedItems: { [string]: number } = {}
    local itemCount = 0
    for itemId, quantity in pairs(items) do
        if itemCount >= EconomyConfig.Trade.MaxSlotsPerTrade then break end
        local invQty = WalletService.GetItemQuantity(player, itemId)
        local safeQty = math.clamp(math.floor(math.abs(quantity)), 0, invQty)
        if safeQty > 0 then
            validatedItems[itemId] = safeQty
            itemCount += 1
        end
    end

    myOffer.Cash = cash
    myOffer.Items = validatedItems
    myOffer.IsConfirmed = false

    -- Setiap perubahan mereset lock lawan untuk mencegah scam penukaran cepat
    session.Offer1.IsLocked = false
    session.Offer2.IsLocked = false
    session.Offer1.IsConfirmed = false
    session.Offer2.IsConfirmed = false
    session.LastInteractionAt = os.time()

    TradeService.BroadcastUpdate(session)
    return true
end

-- Kunci Penawaran (Lock-in)
function TradeService.SetLocked(player: Player, locked: boolean): boolean
    local session = TradeService.GetSession(player)
    if not session then return false end

    local isP1 = (session.Player1 == player)
    local myOffer = if isP1 then session.Offer1 else session.Offer2

    myOffer.IsLocked = locked
    myOffer.IsConfirmed = false

    -- Jika di-unlock, reset konfirmasi keduanya
    if not locked then
        session.Offer1.IsConfirmed = false
        session.Offer2.IsConfirmed = false
    end

    session.LastInteractionAt = os.time()
    TradeService.BroadcastUpdate(session)
    return true
end

-- Konfirmasi Final Pertukaran Barang & Uang
function TradeService.ConfirmTrade(player: Player): boolean
    local session = TradeService.GetSession(player)
    if not session then return false end

    -- Keduanya harus terkunci (Locked) terlebih dahulu
    if not (session.Offer1.IsLocked and session.Offer2.IsLocked) then
        WalletService.Notify(player, "Kedua pemain harus mengunci tawaran sebelum konfirmasi!", "Warning")
        return false
    end

    local isP1 = (session.Player1 == player)
    if isP1 then
        session.Offer1.IsConfirmed = true
    else
        session.Offer2.IsConfirmed = true
    end

    TradeService.BroadcastUpdate(session)

    -- Jika kedua pemain telah menekan tombol Confirm, jalankan eksekusi atomik
    if session.Offer1.IsConfirmed and session.Offer2.IsConfirmed then
        TradeService.ExecuteTrade(session)
    end

    return true
end

-- Eksekusi Pertukaran Barang & Uang (Atomic Execution dengan Pajak Pasar)
function TradeService.ExecuteTrade(session: TradeSession)
    local p1 = session.Player1
    local p2 = session.Player2

    -- Verifikasi jarak fisik karakter saat trade dieksekusi
    if GetDistance(p1, p2) > EconomyConfig.Trade.MaxDistanceBetweenPlayers then
        TradeService.CancelTrade(p1, "Jarak terlalu jauh saat pertukaran berlangsung!")
        return
    end

    local d1 = WalletService.GetData(p1)
    local d2 = WalletService.GetData(p2)
    if not d1 or not d2 then
        TradeService.CancelTrade(p1, "Gagal memverifikasi data salah satu pemain!")
        return
    end

    local off1 = session.Offer1
    local off2 = session.Offer2

    -- Re-validasi saldo & barang Player 1
    if d1.Cash < off1.Cash then
        TradeService.CancelTrade(p1, p1.DisplayName .. " kekurangan uang tunai!")
        return
    end
    for id, qty in pairs(off1.Items) do
        if WalletService.GetItemQuantity(p1, id) < qty then
            TradeService.CancelTrade(p1, p1.DisplayName .. " tidak memiliki jumlah barang yang cukup!")
            return
        end
    end

    -- Re-validasi saldo & barang Player 2
    if d2.Cash < off2.Cash then
        TradeService.CancelTrade(p2, p2.DisplayName .. " kekurangan uang tunai!")
        return
    end
    for id, qty in pairs(off2.Items) do
        if WalletService.GetItemQuantity(p2, id) < qty then
            TradeService.CancelTrade(p2, p2.DisplayName .. " tidak memiliki jumlah barang yang cukup!")
            return
        end
    end

    -- [ KALKULASI PAJAK PERDAGANGAN (SINK INFLASI) ]
    -- Pajak ditarik dari uang tunai yang ditukarkan, mengurangi suplai uang server
    local taxPercent = EconomyConfig.LiveEconomy.P2PTradeTaxPercent
    local tax1 = 0
    local tax2 = 0

    if off1.Cash > 0 then
        tax1 = math.max(math.floor(off1.Cash * (taxPercent / 100)), EconomyConfig.LiveEconomy.MinTradeTax)
        tax1 = math.min(tax1, off1.Cash) -- Pajak tidak boleh melebihi nilai cash itu sendiri
    end

    if off2.Cash > 0 then
        tax2 = math.max(math.floor(off2.Cash * (taxPercent / 100)), EconomyConfig.LiveEconomy.MinTradeTax)
        tax2 = math.min(tax2, off2.Cash)
    end

    local netCash1 = off1.Cash - tax1 -- Uang yang diterima Player 2
    local netCash2 = off2.Cash - tax2 -- Uang yang diterima Player 1

    -- [ EKSEKUSI TRANSAKSI ATOMIK ]
    -- Potong dari Player 1
    if off1.Cash > 0 then
        WalletService.RemoveCash(p1, off1.Cash, "Trade ke " .. p2.DisplayName)
        d1.TotalTaxPaid += tax1
    end
    for id, qty in pairs(off1.Items) do
        WalletService.RemoveItem(p1, id, qty)
    end

    -- Potong dari Player 2
    if off2.Cash > 0 then
        WalletService.RemoveCash(p2, off2.Cash, "Trade ke " .. p1.DisplayName)
        d2.TotalTaxPaid += tax2
    end
    for id, qty in pairs(off2.Items) do
        WalletService.RemoveItem(p2, id, qty)
    end

    -- Berikan ke penerima
    if netCash1 > 0 then
        WalletService.AddCash(p2, netCash1, "Hasil Trade dari " .. p1.DisplayName)
    end
    for id, qty in pairs(off1.Items) do
        WalletService.AddItem(p2, id, qty)
    end

    if netCash2 > 0 then
        WalletService.AddCash(p1, netCash2, "Hasil Trade dari " .. p2.DisplayName)
    end
    for id, qty in pairs(off2.Items) do
        WalletService.AddItem(p1, id, qty)
    end

    session.Status = "Completed"

    -- Notifikasi Sukses
    local compRem = EconomyNetwork.GetEvent("TradeCompleted")
    compRem:FireClient(p1, {
        ReceivedCash = netCash2,
        TaxDeducted = tax1,
        PartnerName = p2.DisplayName,
    })
    compRem:FireClient(p2, {
        ReceivedCash = netCash1,
        TaxDeducted = tax2,
        PartnerName = p1.DisplayName,
    })

    TradeService.CleanupSession(session.SessionId)
end

function TradeService.CancelTrade(player: Player, reason: string?)
    local session = TradeService.GetSession(player)
    if not session then return end

    session.Status = "Cancelled"
    local cancelRem = EconomyNetwork.GetEvent("TradeCancelled")
    local msg = reason or (player.DisplayName .. " membatalkan transaksi.")

    cancelRem:FireClient(session.Player1, msg)
    cancelRem:FireClient(session.Player2, msg)

    TradeService.CleanupSession(session.SessionId)
end

function TradeService.BroadcastUpdate(session: TradeSession)
    local updateRem = EconomyNetwork.GetEvent("TradeUpdated")
    
    updateRem:FireClient(session.Player1, {
        MyOffer = session.Offer1,
        TheirOffer = session.Offer2,
        PartnerName = session.Player2.DisplayName,
    })
    updateRem:FireClient(session.Player2, {
        MyOffer = session.Offer2,
        TheirOffer = session.Offer1,
        PartnerName = session.Player1.DisplayName,
    })
end

function TradeService.CleanupSession(sessionId: string)
    local session = ActiveSessions[sessionId]
    if not session then return end

    PlayerToSessionId[session.Player1] = nil
    PlayerToSessionId[session.Player2] = nil
    ActiveSessions[sessionId] = nil
end

return TradeService
