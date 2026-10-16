--!strict
--[[
    ========================================================================
    ONE-CLICK COMMAND BAR INSTALLER: INDORP LIVE ECONOMY FRAMEWORK
    ========================================================================
    CARA PENGGUNAAN:
    1. Buka Roblox Studio dan muat Map Anda.
    2. Buka jendela 'Command Bar' (Menu View -> Command Bar).
    3. Copy dan Paste seluruh isi script ini ke Command Bar, lalu tekan Enter!
    4. Seluruh sistem ekonomi, modul, script server, script client, dan folder
       akan dibuat secara instan dan otomatis!
--]]

local ChangeHistoryService = game:GetService("ChangeHistoryService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local StarterPlayer = game:GetService("StarterPlayer")

ChangeHistoryService:SetWaypoint("BeforeIndoRPEconomyInstall")

print("------------------------------------------------------------------------")
print("[IndoRP Live Economy] Memulai instalasi sistem ke dalam DataModel...")

-- 1. Folder Struktur ReplicatedStorage
local repFolder = ReplicatedStorage:FindFirstChild("EconomySystem") or Instance.new("Folder")
repFolder.Name = "EconomySystem"
repFolder.Parent = ReplicatedStorage

local configFolder = repFolder:FindFirstChild("Config") or Instance.new("Folder")
configFolder.Name = "Config"
configFolder.Parent = repFolder

local modulesFolder = repFolder:FindFirstChild("Modules") or Instance.new("Folder")
modulesFolder.Name = "Modules"
modulesFolder.Parent = repFolder

local remotesFolder = ReplicatedStorage:FindFirstChild("EconomyRemotes") or Instance.new("Folder")
remotesFolder.Name = "EconomyRemotes"
remotesFolder.Parent = ReplicatedStorage

-- 2. Folder Struktur ServerScriptService
local sssFolder = ServerScriptService:FindFirstChild("EconomySystem") or Instance.new("Folder")
sssFolder.Name = "EconomySystem"
sssFolder.Parent = ServerScriptService

local servicesFolder = sssFolder:FindFirstChild("Services") or Instance.new("Folder")
servicesFolder.Name = "Services"
servicesFolder.Parent = sssFolder

-- 3. Folder Struktur StarterPlayerScripts
local sps = StarterPlayer:FindFirstChild("StarterPlayerScripts")
assert(sps, "StarterPlayerScripts tidak ditemukan!")
local clientFolder = sps:FindFirstChild("EconomySystem") or Instance.new("Folder")
clientFolder.Name = "EconomySystem"
clientFolder.Parent = sps

-- 4. Injeksi Seluruh Source Code File
local BundledFiles = {
    {
        ClassName = "ModuleScript",
        Name = "EconomyConfig",
        TargetParent = function() return game:GetService("ReplicatedStorage").EconomySystem.Config end,
        Source = [====[
--!strict
--[[
    ========================================================================
    ECONOMY CONFIGURATION - INDONESIA ROLEPLAY ISLAND LIVE ECONOMY
    ========================================================================
    File ini mengatur seluruh parameter ekonomi dalam server:
    - Mata Uang (Currency)
    - Faucet (Penghasilan: Gaji Pekerjaan, Jual Barang)
    - Sink (Penghabisan/Pembakaran Uang: Pajak, Makan/Minum, Bahan Bakar, Denda)
    - Sistem Trade P2P (Trade Tax, Cooldown, Limits)
--]]

export type ItemData = {
    Id: string,
    Name: string,
    Category: "Consumable" | "Tool" | "Commodity" | "License" | "Vehicle",
    BasePrice: number,        -- Harga beli di toko/NPC
    SellPrice: number,        -- Harga jual balik ke toko/NPC
    Description: string,
    MaxStack: number,
    SinkEffect: {             -- Pengaruh terhadap status pemain (Hunger, Thirst, Stamina)
        Hunger: number?,
        Thirst: number?,
        Health: number?,
        Duration: number?,
    }?,
}

export type JobData = {
    Id: string,
    Title: string,
    Department: "Sipil" | "Pemerintah" | "Kriminal" | "Jasa",
    BaseSalaryPerCycle: number, -- Gaji dasar tiap payday (misal 5 menit)
    SalaryIntervalSeconds: number,
    RequirementLevel: number,
    UniformId: string?,
    ToolRewardIds: { string }?,
    Description: string,
}

local EconomyConfig = {
    -- [ INFORMASI MATA UANG & STARTER ]
    Currency = {
        Name = "Rupiah",
        Symbol = "Rp",
        Format = "id_ID", -- 1000000 -> "Rp 1.000.000"
        StartingCash = 250000, -- Uang saku awal (Rp 250.000)
        StartingBank = 1000000, -- Uang tabungan awal di bank (Rp 1.000.000)
        MaxCashOnHand = 50000000, -- Batas maksimal uang tunai (mencegah inflasi tak terkontrol & resiko begal)
        MaxBankBalance = 1000000000, -- Batas saldo rekening
        DailyLoginReward = 50000, -- Bonus login harian
    },

    -- [ LIVE ECONOMY & INFLATION CONTROL (SINK & FAUCET BALANCER) ]
    -- Supaya ekonomi game seimbang, uang yang keluar (Sink) harus seimbang dengan uang yang dicetak (Faucet).
    LiveEconomy = {
        -- Pajak Transaksi Antar Pemain (P2P Trade Tax)
        -- Dikenakan pada setiap trade uang tunai agar uang ter-burn dari server secara konstan
        P2PTradeTaxPercent = 3.5, -- 3.5% dari nominal trade akan dihapus (burn) sebagai pajak server
        MinTradeTax = 1000,       -- Minimal pajak per trade
        
        -- Pajak Transfer Bank (Admin Bank Fee)
        BankTransferFeePercent = 1.0, -- Biaya admin transfer antar rekening
        BankTransferFeeMin = 2500,

        -- Pajak Kekayaan / Biaya Pemeliharaan (Maintenance Sink)
        EnableHourlyTax = true,
        HourlyTaxPercentage = 0.1, -- 0.1% per jam untuk pemain berharta di atas 10jt
        HourlyTaxThreshold = 10000000,

        -- Inflasi Otomatis (Dynamic Price Index)
        -- Jika total uang beredar di server melebihi batas, harga toko otomatis naik sedikit
        DynamicMarketPrices = true,
        ServerMoneyTarget = 200000000, -- Target uang beredar per 20 pemain
    },

    -- [ SISTEM PERDAGANGAN ANTAR PEMAIN (P2P TRADE) ]
    Trade = {
        MaxSlotsPerTrade = 8,
        TradeTimeoutSeconds = 120, -- Batas waktu trade 2 menit
        TradeAcceptCountdown = 3,   -- Waktu jeda setelah keduanya setuju untuk mencegah scam/tukar item mendadak
        MaxDistanceBetweenPlayers = 15, -- Jarak maksimal studs agar trade tetap aktif
        AllowCashInTrade = true,
        MaxCashPerTrade = 10000000, -- Maksimal trade uang tunai sekaligus
        AntiDupeLockSeconds = 5,   -- Cooldown selesai trade sebelum data disimpan
    },

    -- [ SISTEM PEKERJAAN (FAUCET / PENGHASILAN) ]
    Jobs = {
        PaydayCycleSeconds = 300, -- Pembagian gaji setiap 5 menit (300 detik)
        JobList = {
            ["Unemployed"] = {
                Id = "Unemployed",
                Title = "Warga Bebas",
                Department = "Sipil",
                BaseSalaryPerCycle = 15000, -- Bantuan sosial pemda Rp 15.000 / 5 min
                SalaryIntervalSeconds = 300,
                RequirementLevel = 1,
                Description = "Mencari peluang usaha mandiri di pulau.",
            },
            ["Courier"] = {
                Id = "Courier",
                Title = "Kurir Ekspedisi Pulau",
                Department = "Jasa",
                BaseSalaryPerCycle = 65000, -- Gaji dasar + komisi per paket
                SalaryIntervalSeconds = 300,
                RequirementLevel = 1,
                Description = "Mengantar paket barang dari pelabuhan ke warga kepulauan.",
            },
            ["Fisherman"] = {
                Id = "Fisherman",
                Title = "Nelayan Tradisional",
                Department = "Sipil",
                BaseSalaryPerCycle = 45000,
                SalaryIntervalSeconds = 300,
                RequirementLevel = 1,
                Description = "Menangkap ikan di pesisir dan menjual hasil tangkapan ke pasar TPI.",
            },
            ["Merchant"] = {
                Id = "Merchant",
                Title = "Pedagang Pasar",
                Department = "Sipil",
                BaseSalaryPerCycle = 50000,
                SalaryIntervalSeconds = 300,
                RequirementLevel = 2,
                Description = "Membeli barang grosir dan menjual eceran ke pemain lain di lapak pasar.",
            },
            ["Police"] = {
                Id = "Police",
                Title = "Polisi Kepulauan",
                Department = "Pemerintah",
                BaseSalaryPerCycle = 120000,
                SalaryIntervalSeconds = 300,
                RequirementLevel = 3,
                Description = "Menjaga ketertiban pulau, patroli, dan memberi tilang pada pelanggar lalu lintas.",
            },
            ["Medic"] = {
                Id = "Medic",
                Title = "Tenaga Medis Puskesmas",
                Department = "Pemerintah",
                BaseSalaryPerCycle = 115000,
                SalaryIntervalSeconds = 300,
                RequirementLevel = 2,
                Description = "Mengobati warga sakit/lapar kritis dan menyediakan pertolongan darurat.",
            },
        } :: { [string]: JobData },
    },

    -- [ DAFTAR ITEM & BARANG EKONOMI (FAUCET & SINK) ]
    Items = {
        -- Kebutuhan Pokok (Sink: Pemain WAJIB belanja agar tidak lapar/kehausan)
        ["food_nasgor"] = {
            Id = "food_nasgor",
            Name = "Nasi Goreng Spesial",
            Category = "Consumable",
            BasePrice = 20000,
            SellPrice = 5000,
            Description = "Makanan hangat khas Indonesia. Memulihkan 60 poin kelaparan.",
            MaxStack = 10,
            SinkEffect = { Hunger = 60, Thirst = -5, Health = 10 },
        },
        ["food_mieayam"] = {
            Id = "food_mieayam",
            Name = "Mie Ayam Bakso",
            Category = "Consumable",
            BasePrice = 18000,
            SellPrice = 4000,
            Description = "Mengenyangkan perut dan menambah stamina kerja.",
            MaxStack = 10,
            SinkEffect = { Hunger = 45, Thirst = 5, Health = 5 },
        },
        ["drink_esteh"] = {
            Id = "drink_esteh",
            Name = "Es Teh Manis Jumbo",
            Category = "Consumable",
            BasePrice = 6000,
            SellPrice = 1000,
            Description = "Minuman segar penghilang dahaga di cuaca panas pulau.",
            MaxStack = 15,
            SinkEffect = { Thirst = 50 },
        },
        ["drink_kopi"] = {
            Id = "drink_kopi",
            Name = "Kopi Tubruk Robusta",
            Category = "Consumable",
            BasePrice = 8000,
            SellPrice = 1500,
            Description = "Kopi hitam khas nusantara penambah energi.",
            MaxStack = 15,
            SinkEffect = { Thirst = 30, Hunger = 5 },
        },
        ["item_medkit"] = {
            Id = "item_medkit",
            Name = "P3K & Obat Medis",
            Category = "Consumable",
            BasePrice = 75000,
            SellPrice = 20000,
            Description = "Peralatan medis darurat untuk memulihkan kesehatan penuh.",
            MaxStack = 5,
            SinkEffect = { Health = 100 },
        },

        -- Komoditas Laut / Kerajinan (Faucet: Dihasilkan pemain lewat kerja, dijual/ditradingkan)
        ["commodity_fish_tongkol"] = {
            Id = "commodity_fish_tongkol",
            Name = "Ikan Tongkol Segar",
            Category = "Commodity",
            BasePrice = 35000,
            SellPrice = 28000, -- Hasil nelayan jual ke TPI
            Description = "Tangkapan laut berkualitas tinggi dari perairan pulau.",
            MaxStack = 20,
        },
        ["commodity_fish_kakap"] = {
            Id = "commodity_fish_kakap",
            Name = "Ikan Kakap Merah",
            Category = "Commodity",
            BasePrice = 60000,
            SellPrice = 48000,
            Description = "Ikan bernilai ekonomi tinggi favorit restoran.",
            MaxStack = 20,
        },
        ["commodity_kelapa"] = {
            Id = "commodity_kelapa",
            Name = "Kelapa Muda Pulau",
            Category = "Commodity",
            BasePrice = 15000,
            SellPrice = 10000,
            Description = "Bisa diminum langsung atau dijual ke pedagang minuman.",
            MaxStack = 30,
            SinkEffect = { Thirst = 35, Hunger = 10 },
        },

        -- Peralatan & Izin Usaha (Sink Pembelian Investasi)
        ["tool_pancing"] = {
            Id = "tool_pancing",
            Name = "Joran Pancing Modern",
            Category = "Tool",
            BasePrice = 120000,
            SellPrice = 30000,
            Description = "Alat untuk memancing ikan di dermaga atau perahu.",
            MaxStack = 1,
        },
        ["license_dagang"] = {
            Id = "license_dagang",
            Name = "Izin Lapak Dagang Pulau",
            Category = "License",
            BasePrice = 350000,
            SellPrice = 0,
            Description = "Surat izin resmi dari RT/RW untuk membuka lapak jual-beli di pasar.",
            MaxStack = 1,
        },
        ["license_sim"] = {
            Id = "license_sim",
            Name = "SIM C Kepulauan",
            Category = "License",
            BasePrice = 150000,
            SellPrice = 0,
            Description = "Surat Izin Mengemudi resmi motor & perahu nelayan.",
            MaxStack = 1,
        },
    } :: { [string]: ItemData },

    -- [ BIAYA PENGELUARAN KEHIDUPAN (SINK DINAMIS) ]
    LifeExpenses = {
        HungerDrainRatePerMinute = 2.5,   -- Lapar turun 2.5 per menit (perlu makan tiap 40 menit)
        ThirstDrainRatePerMinute = 3.5,   -- Haus turun 3.5 per menit (perlu minum tiap ~28 menit)
        HospitalBillOnDeath = 100000,     -- Biaya RS jika pingsan/mati (Rp 100.000 ter-burn)
        VehicleFuelCostPerLiter = 12500,  -- Harga bensin per liter
        ImpoundReleaseFee = 75000,        -- Biaya tebus motor jika disita polisi
    },

    -- [ PENGATURAN DATASTORE & KEAMANAN ]
    DataStore = {
        DataStoreKey = "IndoRP_LiveEconomy_v1_0",
        AutoSaveInterval = 180, -- Auto-save tiap 3 menit
        SaveOnLeave = true,
        EnableSessionLock = true,
    },
}

-- Helper Utility: Format Rupiah (contoh: 1500000 -> "Rp 1.500.000")
function EconomyConfig.FormatMoney(amount: number): string
    local formatted = tostring(math.floor(math.abs(amount)))
    local k: number
    while true do
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", "%1.%2")
        if k == 0 then break end
    end
    if amount < 0 then
        return "- " .. EconomyConfig.Currency.Symbol .. " " .. formatted
    else
        return EconomyConfig.Currency.Symbol .. " " .. formatted
    end
end

return EconomyConfig

]====],
    },
    {
        ClassName = "ModuleScript",
        Name = "EconomyNetwork",
        TargetParent = function() return game:GetService("ReplicatedStorage").EconomySystem.Modules end,
        Source = [====[
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

]====],
    },
    {
        ClassName = "ModuleScript",
        Name = "Types",
        TargetParent = function() return game:GetService("ReplicatedStorage").EconomySystem.Modules end,
        Source = [====[
--!strict
--[[
    ========================================================================
    ECONOMY DATA TYPES (LUAU STRICT TYPING)
    ========================================================================
--]]

export type InventoryItem = {
    Id: string,
    Quantity: number,
    ItemKey: string, -- Unique identifier in inventory
}

export type PlayerEconomyData = {
    Cash: number,
    Bank: number,
    JobId: string,
    JobExperience: number,
    Inventory: { [string]: InventoryItem },
    LastPaydayTimestamp: number,
    TotalEarned: number,
    TotalSpent: number,
    TotalTaxPaid: number,
}

export type TradeOffer = {
    Cash: number,
    Items: { [string]: number }, -- ItemId -> Quantity
    IsLocked: boolean,
    IsConfirmed: boolean,
}

export type TradeSession = {
    SessionId: string,
    Player1: Player,
    Player2: Player,
    Offer1: TradeOffer,
    Offer2: TradeOffer,
    CreatedAt: number,
    LastInteractionAt: number,
    Status: "Pending" | "Trading" | "Locked" | "Confirmed" | "Completed" | "Cancelled",
}

return {}

]====],
    },
    {
        ClassName = "ModuleScript",
        Name = "WalletService",
        TargetParent = function() return game:GetService("ServerScriptService").EconomySystem.Services end,
        Source = [====[
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

]====],
    },
    {
        ClassName = "ModuleScript",
        Name = "TradeService",
        TargetParent = function() return game:GetService("ServerScriptService").EconomySystem.Services end,
        Source = [====[
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

]====],
    },
    {
        ClassName = "ModuleScript",
        Name = "JobService",
        TargetParent = function() return game:GetService("ServerScriptService").EconomySystem.Services end,
        Source = [====[
--!strict
--[[
    ========================================================================
    JOB SERVICE (SERVER - PENGHASILAN / FAUCET SYSTEM)
    ========================================================================
    Mengatur sistem pekerjaan di pulau roleplay:
    - Pengambilan Pekerjaan di Lokasi / Pos Kerja
    - Pembagian Gaji Berkala (Payday Cycle)
    - Bonus Penyelesaian Misi / Tugas Kerja (Kurir, Nelayan, Polisi)
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EconomyConfig = require(ReplicatedStorage.EconomySystem.Config.EconomyConfig)
local EconomyNetwork = require(ReplicatedStorage.EconomySystem.Modules.EconomyNetwork)

local JobService = {}
local WalletService = nil
local ActivePaydayThreads: { [Player]: thread } = {}

function JobService.Init(walletServiceRef)
    WalletService = walletServiceRef

    -- Loop Payday Global
    task.spawn(function()
        while true do
            task.wait(EconomyConfig.Jobs.PaydayCycleSeconds)
            JobService.DistributeGlobalPayday()
        end
    end)
end

function JobService.SetJob(player: Player, jobId: string): boolean
    local jobDef = EconomyConfig.Jobs.JobList[jobId]
    if not jobDef then
        WalletService.Notify(player, "Pekerjaan tidak ditemukan!", "Warning")
        return false
    end

    local data = WalletService.GetData(player)
    if not data then return false end

    data.JobId = jobId
    WalletService.SyncToClient(player)
    
    local jobRem = EconomyNetwork.GetEvent("JobUpdated")
    jobRem:FireClient(player, {
        JobId = jobId,
        JobTitle = jobDef.Title,
        Salary = jobDef.BaseSalaryPerCycle,
        Department = jobDef.Department,
    })

    WalletService.Notify(player, "Selamat! Anda resmi bekerja sebagai " .. jobDef.Title, "Success")
    return true
end

function JobService.QuitJob(player: Player): boolean
    return JobService.SetJob(player, "Unemployed")
end

function JobService.DistributeGlobalPayday()
    for _, player in ipairs(Players:GetPlayers()) do
        local data = WalletService.GetData(player)
        if data then
            local jobDef = EconomyConfig.Jobs.JobList[data.JobId]
            if jobDef and jobDef.BaseSalaryPerCycle > 0 then
                -- Gaji otomatis ditransfer langsung ke rekening bank (mencegah begal tunai instan)
                WalletService.AddBank(player, jobDef.BaseSalaryPerCycle, "Gaji: " .. jobDef.Title)
            end
        end
    end
end

-- Bonus Tugas Pekerjaan (Contoh: Kurir antar paket, Nelayan tangkap ikan)
function JobService.CompleteTaskReward(player: Player, taskType: string, bonusCash: number, rewardItemId: string?, rewardItemQty: number?)
    local data = WalletService.GetData(player)
    if not data then return end

    if bonusCash > 0 then
        WalletService.AddCash(player, bonusCash, "Upah Tugas: " .. taskType)
    end

    if rewardItemId and (rewardItemQty or 0) > 0 then
        WalletService.AddItem(player, rewardItemId, rewardItemQty or 1)
    end
end

return JobService

]====],
    },
    {
        ClassName = "ModuleScript",
        Name = "ShopService",
        TargetParent = function() return game:GetService("ServerScriptService").EconomySystem.Services end,
        Source = [====[
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

]====],
    },
    {
        ClassName = "Script",
        Name = "EconomyServer",
        TargetParent = function() return game:GetService("ServerScriptService").EconomySystem end,
        Source = [====[
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

]====],
    },
    {
        ClassName = "LocalScript",
        Name = "EconomyClient",
        TargetParent = function() return game:GetService("StarterPlayer").StarterPlayerScripts.EconomySystem end,
        Source = [====[
--!strict
--[[
    ========================================================================
    ECONOMY CLIENT (STARTER PLAYER SCRIPTS)
    ========================================================================
    Mengatur tampilan antarmuka (HUD), Interaksi ProximityPrompt di Map,
    dan Modal UI untuk Trade P2P, ATM Bank, Toko Warung, dan Pekerjaan.
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local ProximityPromptService = game:GetService("ProximityPromptService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui") :: PlayerGui

local EconomyConfig = require(ReplicatedStorage:WaitForChild("EconomySystem"):WaitForChild("Config"):WaitForChild("EconomyConfig"))
local EconomyNetwork = require(ReplicatedStorage.EconomySystem:WaitForChild("Modules"):WaitForChild("EconomyNetwork"))

-- [ STATE LOKAL ]
local CurrentData = {
    Cash = 0,
    Bank = 0,
    JobId = "Unemployed",
    Inventory = {},
    TotalTaxPaid = 0,
}

-- [ PEMBUATAN HUD DASAR ]
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "EconomyScreenGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = PlayerGui

-- Panel Status Keuangan (Kiri Atas atau Kanan Atas)
local HudFrame = Instance.new("Frame")
HudFrame.Name = "WalletHUD"
HudFrame.Size = UDim2.new(0, 240, 0, 100)
HudFrame.Position = UDim2.new(1, -260, 0, 20)
HudFrame.BackgroundColor3 = Color3.fromRGB(24, 27, 34)
HudFrame.BorderSizePixel = 0
HudFrame.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 10)
UICorner.Parent = HudFrame

local UIStroke = Instance.new("UIStroke")
UIStroke.Color = Color3.fromRGB(48, 54, 66)
UIStroke.Thickness = 1.5
UIStroke.Parent = HudFrame

-- Label Cash (Uang Tunai)
local CashLabel = Instance.new("TextLabel")
CashLabel.Name = "CashLabel"
CashLabel.Size = UDim2.new(1, -20, 0, 24)
CashLabel.Position = UDim2.new(0, 12, 0, 10)
CashLabel.BackgroundTransparency = 1
CashLabel.Font = Enum.Font.GothamBold
CashLabel.TextColor3 = Color3.fromRGB(76, 209, 55) -- Hijau Uang
CashLabel.TextSize = 16
CashLabel.TextXAlignment = Enum.TextXAlignment.Left
CashLabel.Text = "💵 Tunai: Rp 0"
CashLabel.Parent = HudFrame

-- Label Bank (Rekening)
local BankLabel = Instance.new("TextLabel")
BankLabel.Name = "BankLabel"
BankLabel.Size = UDim2.new(1, -20, 0, 24)
BankLabel.Position = UDim2.new(0, 12, 0, 36)
BankLabel.BackgroundTransparency = 1
BankLabel.Font = Enum.Font.GothamMedium
BankLabel.TextColor3 = Color3.fromRGB(0, 168, 255) -- Biru Rekening
BankLabel.TextSize = 14
BankLabel.TextXAlignment = Enum.TextXAlignment.Left
BankLabel.Text = "🏦 Bank: Rp 0"
BankLabel.Parent = HudFrame

-- Label Pekerjaan
local JobLabel = Instance.new("TextLabel")
JobLabel.Name = "JobLabel"
JobLabel.Size = UDim2.new(1, -20, 0, 20)
JobLabel.Position = UDim2.new(0, 12, 0, 64)
JobLabel.BackgroundTransparency = 1
JobLabel.Font = Enum.Font.Gotham
JobLabel.TextColor3 = Color3.fromRGB(220, 221, 225)
JobLabel.TextSize = 12
JobLabel.TextXAlignment = Enum.TextXAlignment.Left
JobLabel.Text = "💼 Profesi: Warga Bebas"
JobLabel.Parent = HudFrame

-- Container Notifikasi Melayang (Toast)
local ToastContainer = Instance.new("Frame")
ToastContainer.Name = "ToastContainer"
ToastContainer.Size = UDim2.new(0, 320, 0, 300)
ToastContainer.Position = UDim2.new(0.5, -160, 0.75, 0)
ToastContainer.BackgroundTransparency = 1
ToastContainer.Parent = ScreenGui

local ToastListLayout = Instance.new("UIListLayout")
ToastListLayout.SortOrder = Enum.SortOrder.LayoutOrder
ToastListLayout.Padding = UDim.new(0, 8)
ToastListLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
ToastListLayout.Parent = ToastContainer

-- Fungsi Tampilkan Toast Notifikasi
local function ShowToast(text: string, notifType: string)
    local toast = Instance.new("Frame")
    toast.Size = UDim2.new(1, 0, 0, 36)
    toast.BackgroundColor3 = if notifType == "Success" then Color3.fromRGB(39, 174, 96)
        elseif notifType == "Warning" then Color3.fromRGB(230, 126, 34)
        elseif notifType == "Danger" then Color3.fromRGB(192, 57, 43)
        else Color3.fromRGB(41, 128, 185)
    toast.BackgroundTransparency = 0.1
    toast.BorderSizePixel = 0
    toast.Parent = ToastContainer

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = toast

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -20, 1, 0)
    lbl.Position = UDim2.new(0, 10, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
    lbl.TextSize = 13
    lbl.Text = text
    lbl.Parent = toast

    task.delay(4, function()
        local tween = TweenService:Create(toast, TweenInfo.new(0.5), { BackgroundTransparency = 1 })
        local textTween = TweenService:Create(lbl, TweenInfo.new(0.5), { TextTransparency = 1 })
        tween:Play()
        textTween:Play()
        tween.Completed:Connect(function()
            toast:Destroy()
        end)
    end)
end

-- [ P2P TRADE WINDOW & PROMPT DIALOG ]
local TradeInviteFrame = Instance.new("Frame")
TradeInviteFrame.Name = "TradeInviteModal"
TradeInviteFrame.Size = UDim2.new(0, 320, 0, 140)
TradeInviteFrame.Position = UDim2.new(0.5, -160, 0.35, 0)
TradeInviteFrame.BackgroundColor3 = Color3.fromRGB(20, 24, 30)
TradeInviteFrame.Visible = false
TradeInviteFrame.BorderSizePixel = 0
TradeInviteFrame.Parent = ScreenGui

local inviteCorner = Instance.new("UICorner")
inviteCorner.CornerRadius = UDim.new(0, 8)
inviteCorner.Parent = TradeInviteFrame

local inviteStroke = Instance.new("UIStroke")
inviteStroke.Color = Color3.fromRGB(52, 152, 219)
inviteStroke.Thickness = 2
inviteStroke.Parent = TradeInviteFrame

local InviteTitle = Instance.new("TextLabel")
InviteTitle.Size = UDim2.new(1, -20, 0, 50)
InviteTitle.Position = UDim2.new(0, 10, 0, 10)
InviteTitle.BackgroundTransparency = 1
InviteTitle.Font = Enum.Font.GothamBold
InviteTitle.TextColor3 = Color3.fromRGB(240, 240, 240)
InviteTitle.TextSize = 14
InviteTitle.TextWrapped = true
InviteTitle.Text = "Pemain mengajak transaksi perdagangan!"
InviteTitle.Parent = TradeInviteFrame

local AcceptBtn = Instance.new("TextButton")
AcceptBtn.Size = UDim2.new(0, 130, 0, 36)
AcceptBtn.Position = UDim2.new(0, 20, 0, 80)
AcceptBtn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
AcceptBtn.Font = Enum.Font.GothamBold
AcceptBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
AcceptBtn.Text = "Terima (Trade)"
AcceptBtn.Parent = TradeInviteFrame
local accCor = Instance.new("UICorner")
accCor.CornerRadius = UDim.new(0, 6)
accCor.Parent = AcceptBtn

local DeclineBtn = Instance.new("TextButton")
DeclineBtn.Size = UDim2.new(0, 130, 0, 36)
DeclineBtn.Position = UDim2.new(1, -150, 0, 80)
DeclineBtn.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
DeclineBtn.Font = Enum.Font.GothamBold
DeclineBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
DeclineBtn.Text = "Tolak"
DeclineBtn.Parent = TradeInviteFrame
local decCor = Instance.new("UICorner")
decCor.CornerRadius = UDim.new(0, 6)
decCor.Parent = DeclineBtn

local currentInviterUser = ""

AcceptBtn.MouseButton1Click:Connect(function()
    TradeInviteFrame.Visible = false
    if currentInviterUser ~= "" then
        EconomyNetwork.GetFunction("RespondTradeInvite"):InvokeServer(currentInviterUser, true)
    end
end)

DeclineBtn.MouseButton1Click:Connect(function()
    TradeInviteFrame.Visible = false
    if currentInviterUser ~= "" then
        EconomyNetwork.GetFunction("RespondTradeInvite"):InvokeServer(currentInviterUser, false)
    end
end)

-- [ EVENT LISTENER DARI SERVER ]
EconomyNetwork.GetEvent("WalletUpdated").OnClientEvent:Connect(function(data)
    CurrentData.Cash = data.Cash
    CurrentData.Bank = data.Bank
    CurrentData.JobId = data.JobId
    CurrentData.Inventory = data.Inventory
    CurrentData.TotalTaxPaid = data.TotalTaxPaid

    CashLabel.Text = "💵 Tunai: " .. EconomyConfig.FormatMoney(data.Cash)
    BankLabel.Text = "🏦 Bank: " .. EconomyConfig.FormatMoney(data.Bank)

    local jobDef = EconomyConfig.Jobs.JobList[data.JobId]
    if jobDef then
        JobLabel.Text = "💼 Profesi: " .. jobDef.Title
    end
end)

EconomyNetwork.GetEvent("EconomyNotification").OnClientEvent:Connect(function(msg: string, notifType: string)
    ShowToast(msg, notifType)
end)

EconomyNetwork.GetEvent("TradeInviteReceived").OnClientEvent:Connect(function(info)
    currentInviterUser = info.InviterUser
    InviteTitle.Text = info.InviterName .. " mengajak Anda berdagang secara langsung!"
    TradeInviteFrame.Visible = true
end)

EconomyNetwork.GetEvent("TradeCompleted").OnClientEvent:Connect(function(details)
    ShowToast("Transaksi Sukses dengan " .. details.PartnerName .. "! (Pajak Pasar: " .. EconomyConfig.FormatMoney(details.TaxDeducted) .. ")", "Success")
end)

EconomyNetwork.GetEvent("TradeCancelled").OnClientEvent:Connect(function(reason: string)
    ShowToast("Transaksi dibatalkan: " .. reason, "Warning")
end)

-- [ INTERAKSI PROXIMITY PROMPT WORLD OBJECTS ]
ProximityPromptService.PromptTriggered:Connect(function(prompt, player)
    if player ~= LocalPlayer then return end

    local promptType = prompt:GetAttribute("EconomyType")
    if promptType == "ATM" then
        -- Dialog cepat ATM: Pilihan Setor atau Tarik
        ShowToast("Mesin ATM Terhubung. Tekan tombol untuk transaksi rekening.", "Info")
        -- Contoh cepat setor 50k / tarik 50k (atau dialog custom)
        if CurrentData.Cash >= 50000 then
            EconomyNetwork.GetFunction("DepositCash"):InvokeServer(50000)
        elseif CurrentData.Bank >= 50000 then
            EconomyNetwork.GetFunction("WithdrawBank"):InvokeServer(50000)
        else
            ShowToast("Saldo tidak cukup untuk transaksi standar ATM (Rp 50.000)", "Warning")
        end
    elseif promptType == "Shop" then
        local shopItemId = prompt:GetAttribute("ShopItemId") or "food_nasgor"
        EconomyNetwork.GetFunction("BuyShopItem"):InvokeServer(shopItemId, 1, "Cash")
    elseif promptType == "JobStation" then
        local targetJob = prompt:GetAttribute("JobId") or "Courier"
        EconomyNetwork.GetFunction("ApplyJob"):InvokeServer(targetJob)
    elseif promptType == "FishBuyer" then
        -- Otomatis jual semua ikan yang dimiliki ke TPI
        local tongkolQty = if CurrentData.Inventory["commodity_fish_tongkol"] then CurrentData.Inventory["commodity_fish_tongkol"].Quantity else 0
        if tongkolQty > 0 then
            EconomyNetwork.GetFunction("SellShopItem"):InvokeServer("commodity_fish_tongkol", tongkolQty)
        else
            ShowToast("Anda tidak memiliki Ikan Tongkol untuk dijual!", "Warning")
        end
    elseif promptType == "PlayerTrade" then
        local otherPlayer = prompt:GetAttribute("TargetPlayerName")
        if otherPlayer then
            EconomyNetwork.GetFunction("SendTradeInvite"):InvokeServer(otherPlayer)
        end
    end
end)

print("[IndoRP Live Economy] Client Controller Ready!")

]====],
    }
}

for _, fileInfo in ipairs(BundledFiles) do
    local parent = fileInfo.TargetParent()
    local existing = parent:FindFirstChild(fileInfo.Name)
    local targetInstance: any = existing

    if not targetInstance then
        targetInstance = Instance.new(fileInfo.ClassName)
        targetInstance.Name = fileInfo.Name
        targetInstance.Parent = parent
    end

    targetInstance.Source = fileInfo.Source
    print("  + Terpasang: [" .. fileInfo.ClassName .. "] " .. fileInfo.Name)
end

ChangeHistoryService:SetWaypoint("AfterIndoRPEconomyInstall")
print("------------------------------------------------------------------------")
print("✅ [IndoRP Live Economy] INSTALASI BERHASIL 100%!")
print("   - ReplicatedStorage.EconomySystem (Config & Modules)")
print("   - ServerScriptService.EconomySystem (Services & Controller)")
print("   - StarterPlayerScripts.EconomySystem (Client & HUD)")
print("Tekan Play (F5) untuk menguji Live Economy, P2P Trade, dan ATM!")
print("------------------------------------------------------------------------")
