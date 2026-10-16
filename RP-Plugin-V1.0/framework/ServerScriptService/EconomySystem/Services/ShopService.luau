--!strict
--[[
    ========================================================================
    SHOP & MARKET SERVICE (SERVER - SINK & COMMODITY FAUCET)
    ========================================================================
    Mengatur transaksi Toko/Warung & Pengepul Hasil Bumi/Laut:
    - Beli Barang Kebutuhan Pokok (Makanan, Minuman, Pancing) -> Money Sink
    - Jual Hasil Tangkapan (Ikan Tongkol, Kakap, Kelapa) -> Commodity Faucet
    - Dynamic Price Index (Pencegah inflasi berdasarkan jumlah uang di server)
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EconomyConfig = require(ReplicatedStorage.EconomySystem.Config.EconomyConfig)
local EconomyNetwork = require(ReplicatedStorage.EconomySystem.Modules.EconomyNetwork)

local ShopService = {}
local WalletService = nil

function ShopService.Init(walletServiceRef)
    WalletService = walletServiceRef
end

-- Menghitung faktor pengali harga jika sistem Dynamic Pricing aktif
function ShopService.GetMarketInflationMultiplier(): number
    if not EconomyConfig.LiveEconomy.DynamicMarketPrices then
        return 1.0
    end

    local totalCashInCirculation = 0
    local playerCount = 0
    for _, player in ipairs(Players:GetPlayers()) do
        local data = WalletService.GetData(player)
        if data then
            totalCashInCirculation += (data.Cash + data.Bank)
            playerCount += 1
        end
    end

    if playerCount == 0 then return 1.0 end

    -- Target per kapita: misal 10 juta per orang
    local targetPerPlayer = EconomyConfig.LiveEconomy.ServerMoneyTarget / 20
    local currentPerPlayer = totalCashInCirculation / playerCount

    if currentPerPlayer > targetPerPlayer then
        -- Naikkan harga toko 1% s/d 25% jika pemain terlalu kaya (meredam inflasi)
        local ratio = (currentPerPlayer - targetPerPlayer) / targetPerPlayer
        return math.clamp(1.0 + (ratio * 0.15), 1.0, 1.35)
    end

    return 1.0
end

-- Beli Barang dari Toko / Warung (MONEY SINK UTAMA)
function ShopService.BuyItem(player: Player, itemId: string, quantity: number, paymentMethod: "Cash" | "Bank"): boolean
    if quantity <= 0 then return false end

    local itemDef = EconomyConfig.Items[itemId]
    if not itemDef then
        WalletService.Notify(player, "Barang tidak terdaftar di katalog toko!", "Warning")
        return false
    end

    local multiplier = ShopService.GetMarketInflationMultiplier()
    local unitPrice = math.floor(itemDef.BasePrice * multiplier)
    local totalPrice = unitPrice * quantity

    local data = WalletService.GetData(player)
    if not data then return false end

    if paymentMethod == "Cash" then
        if data.Cash < totalPrice then
            WalletService.Notify(player, "Uang tunai tidak cukup! Butuh " .. EconomyConfig.FormatMoney(totalPrice), "Warning")
            return false
        end
        WalletService.RemoveCash(player, totalPrice, "Beli " .. itemDef.Name .. " (" .. quantity .. "x)")
    else
        if data.Bank < totalPrice then
            WalletService.Notify(player, "Saldo rekening ATM tidak cukup! Butuh " .. EconomyConfig.FormatMoney(totalPrice), "Warning")
            return false
        end
        WalletService.RemoveBank(player, totalPrice, "Debit Toko: " .. itemDef.Name)
    end

    WalletService.AddItem(player, itemId, quantity)
    return true
end

-- Jual Barang ke Pengepul / TPI (PENJUALAN KOMODITAS PULAU)
function ShopService.SellItem(player: Player, itemId: string, quantity: number): boolean
    if quantity <= 0 then return false end

    local itemDef = EconomyConfig.Items[itemId]
    if not itemDef or itemDef.SellPrice <= 0 then
        WalletService.Notify(player, "Barang ini tidak dapat dijual ke pedagang!", "Warning")
        return false
    end

    local currentQty = WalletService.GetItemQuantity(player, itemId)
    if currentQty < quantity then
        WalletService.Notify(player, "Jumlah barang di tas Anda tidak mencukupi!", "Warning")
        return false
    end

    local totalEarnings = itemDef.SellPrice * quantity

    WalletService.RemoveItem(player, itemId, quantity)
    -- Uang penjualan hasil bumi/laut diberikan dalam bentuk Tunai (Cash)
    WalletService.AddCash(player, totalEarnings, "Jual " .. itemDef.Name .. " (" .. quantity .. "x)")
    return true
end

return ShopService
