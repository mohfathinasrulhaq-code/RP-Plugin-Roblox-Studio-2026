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
