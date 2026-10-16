--!strict
--[[
    ========================================================================================
    PLUGIN KHUSUS DEVELOPER MAP ROBLOX: INDO ROLEPLAY ISLAND - LIVE ECONOMY SUITE
    ========================================================================================
    Plugin Studio ini dirancang khusus untuk Developer Map Roleplay Indonesia.
    Fitur Utama:
    1. 🚀 One-Click Framework Installer: Menyiapkan seluruh struktur folder, script,
       dan remote event Live Economy ke dalam game secara otomatis.
    2. 🏗️ Interactive Node Spawner: Menaruh node map siap pakai dengan ProximityPrompt:
       - 🏦 Mesin ATM Bank Mandiri/BCA
       - 🏪 Warung Kelontong / Minimarket (Money Sink)
       - 📦 Pos Ekspedisi & Kurir (Job Node)
       - 🎣 Dermaga TPI / Pengepul Ikan (Komoditas Nelayan)
       - 🤝 Lapak Pasar Perdagangan Bebas (Safe Trade Zone)
    3. ⚖️ Live Economy Simulator & Balancer: Kalkulator inflasi server, rasio faucet vs sink,
       dan pengaturan pajak perdagangan P2P.
--]]

local Selection = game:GetService("Selection")
local ChangeHistoryService = game:GetService("ChangeHistoryService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local StarterPlayer = game:GetService("StarterPlayer")
local Workspace = game:GetService("Workspace")

-- Registrasi Toolbar & Tombol di Roblox Studio
local toolbar = plugin:CreateToolbar("IndoRP Live Economy")
local toggleButton = toolbar:CreateButton(
    "Live Economy Suite",
    "Buka Panel Developer IndoRP Live Economy",
    "rbxassetid://4458901886"
)

-- Pengaturan Dock Widget GUI
local widgetInfo = DockWidgetPluginGuiInfo.new(
    Enum.InitialDockState.Right,
    false, -- Awalnya tidak terbuka otomatis sampai ditekan
    false,
    340,
    580,
    280,
    400
)

local widget = plugin:CreateDockWidgetPluginGui("IndoRP_LiveEconomy_Suite", widgetInfo)
widget.Title = "IndoRP Live Economy Manager"

toggleButton.Click:Connect(function()
    widget.Enabled = not widget.Enabled
end)

-- [ WARNA TEMA STUDIO DARK MODE ]
local BG_COLOR = Color3.fromRGB(30, 34, 42)
local PANEL_COLOR = Color3.fromRGB(40, 45, 56)
local ACCENT_COLOR = Color3.fromRGB(52, 152, 219)
local ACCENT_GREEN = Color3.fromRGB(46, 204, 113)
local ACCENT_ORANGE = Color3.fromRGB(230, 126, 34)
local TEXT_MAIN = Color3.fromRGB(245, 245, 245)
local TEXT_MUTED = Color3.fromRGB(170, 175, 185)

-- [ ROOT UI CONTAINER ]
local mainFrame = Instance.new("ScrollingFrame")
mainFrame.Size = UDim2.new(1, 0, 1, -26)
mainFrame.Position = UDim2.new(0, 0, 0, 0)
mainFrame.BackgroundColor3 = BG_COLOR
mainFrame.BorderSizePixel = 0
mainFrame.ScrollBarThickness = 6
mainFrame.ScrollBarImageColor3 = Color3.fromRGB(100, 110, 125)
mainFrame.CanvasSize = UDim2.new(0, 0, 0, 930)
mainFrame.Parent = widget

local mainLayout = Instance.new("UIListLayout")
mainLayout.SortOrder = Enum.SortOrder.LayoutOrder
mainLayout.Padding = UDim.new(0, 12)
mainLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
mainLayout.Parent = mainFrame

local mainPadding = Instance.new("UIPadding")
mainPadding.PaddingTop = UDim.new(0, 12)
mainPadding.PaddingBottom = UDim.new(0, 16)
mainPadding.PaddingLeft = UDim.new(0, 12)
mainPadding.PaddingRight = UDim.new(0, 12)
mainPadding.Parent = mainFrame

-- Helper Card Creator
local function CreateSection(titleText: string, height: number): (Frame, Frame)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, 0, 0, height)
    card.BackgroundColor3 = PANEL_COLOR
    card.BorderSizePixel = 0
    card.Parent = mainFrame

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = card

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(55, 62, 75)
    stroke.Thickness = 1
    stroke.Parent = card

    local header = Instance.new("TextLabel")
    header.Size = UDim2.new(1, -20, 0, 26)
    header.Position = UDim2.new(0, 10, 0, 8)
    header.BackgroundTransparency = 1
    header.Font = Enum.Font.GothamBold
    header.TextColor3 = TEXT_MAIN
    header.TextSize = 13
    header.TextXAlignment = Enum.TextXAlignment.Left
    header.Text = titleText
    header.Parent = card

    local content = Instance.new("Frame")
    content.Size = UDim2.new(1, -20, 1, -40)
    content.Position = UDim2.new(0, 10, 0, 34)
    content.BackgroundTransparency = 1
    content.Parent = card

    return card, content
end

-- Helper Button Creator
local function CreateButton(parent: Instance, text: string, color: Color3, callback: () -> ())
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 36)
    btn.BackgroundColor3 = color
    btn.BorderSizePixel = 0
    btn.Font = Enum.Font.GothamBold
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 12
    btn.Text = text
    btn.AutoButtonColor = true
    btn.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = btn

    btn.MouseButton1Click:Connect(callback)
    return btn
end

-- ====================================================================================
-- SEKSI 1: STATUS & INSTALLER FRAMEWORK OTOMATIS
-- ====================================================================================
local _, installContent = CreateSection("📦 1. KONTROL DASAR FRAMEWORK", 130)

local installStatusLabel = Instance.new("TextLabel")
installStatusLabel.Size = UDim2.new(1, 0, 0, 34)
installStatusLabel.BackgroundTransparency = 1
installStatusLabel.Font = Enum.Font.Gotham
installStatusLabel.TextColor3 = TEXT_MUTED
installStatusLabel.TextSize = 11
installStatusLabel.TextWrapped = true
installStatusLabel.TextXAlignment = Enum.TextXAlignment.Left
installStatusLabel.Parent = installContent

local function CheckFrameworkStatus()
    local hasRep = ReplicatedStorage:FindFirstChild("EconomySystem") ~= nil
    local hasServer = ServerScriptService:FindFirstChild("EconomySystem") ~= nil
    local hasClient = StarterPlayer.StarterPlayerScripts:FindFirstChild("EconomySystem") ~= nil

    if hasRep and hasServer and hasClient then
        installStatusLabel.Text = "✅ Framework Live Economy AKTIF & Terpasang Lengkap."
        installStatusLabel.TextColor3 = ACCENT_GREEN
    else
        installStatusLabel.Text = "⚠️ Framework belum terpasang lengkap di tempat (Place) ini."
        installStatusLabel.TextColor3 = ACCENT_ORANGE
    end
end
CheckFrameworkStatus()

CreateButton(installContent, "🚀 Pasang / Update Framework Otomatis", ACCENT_COLOR, function()
    ChangeHistoryService:SetWaypoint("BeforeInstallEconomy")

    -- 1. Folder ReplicatedStorage
    local repFolder = ReplicatedStorage:FindFirstChild("EconomySystem")
    if not repFolder then
        repFolder = Instance.new("Folder")
        repFolder.Name = "EconomySystem"
        repFolder.Parent = ReplicatedStorage

        local configFolder = Instance.new("Folder")
        configFolder.Name = "Config"
        configFolder.Parent = repFolder

        local modulesFolder = Instance.new("Folder")
        modulesFolder.Name = "Modules"
        modulesFolder.Parent = repFolder
    end

    -- 2. Folder ServerScriptService
    local sssFolder = ServerScriptService:FindFirstChild("EconomySystem")
    if not sssFolder then
        sssFolder = Instance.new("Folder")
        sssFolder.Name = "EconomySystem"
        sssFolder.Parent = ServerScriptService

        local servicesFolder = Instance.new("Folder")
        servicesFolder.Name = "Services"
        servicesFolder.Parent = sssFolder
    end

    -- 3. Folder StarterPlayerScripts
    local sps = StarterPlayer:FindFirstChild("StarterPlayerScripts")
    if sps then
        local spsFolder = sps:FindFirstChild("EconomySystem")
        if not spsFolder then
            spsFolder = Instance.new("Folder")
            spsFolder.Name = "EconomySystem"
            spsFolder.Parent = sps
        end
    end

    -- Injeksi Script Source Otomatis
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

    for _, fileInfo in ipairs(BundledFiles) do
        local parent = fileInfo.TargetParent()
        local existing = parent:FindFirstChild(fileInfo.Name)
        local targetInstance = existing
        if not targetInstance then
            targetInstance = Instance.new(fileInfo.ClassName)
            targetInstance.Name = fileInfo.Name
            targetInstance.Parent = parent
        end
        targetInstance.Source = fileInfo.Source
        print("  + [Plugin Installer] Terpasang: [" .. fileInfo.ClassName .. "] " .. fileInfo.Name)
    end

    -- 4. Pastikan Remote Folder Terdaftar
    local remotesFolder = ReplicatedStorage:FindFirstChild("EconomyRemotes")
    if not remotesFolder then
        remotesFolder = Instance.new("Folder")
        remotesFolder.Name = "EconomyRemotes"
        remotesFolder.Parent = ReplicatedStorage
    end

    ChangeHistoryService:SetWaypoint("AfterInstallEconomy")
    CheckFrameworkStatus()
    print("[IndoRP Live Economy] Struktur Folder & Modul Framework berhasil disiapkan!")
end)

-- ====================================================================================
-- SEKSI 2: NODE & PROP SPAWNER (DESAIN DUNIA INTERAKTIF)
-- ====================================================================================
local _, spawnerContent = CreateSection("🏗️ 2. QUICK PROP & NODE SPAWNER", 330)

local spawnerLayout = Instance.new("UIListLayout")
spawnerLayout.Padding = UDim.new(0, 8)
spawnerLayout.Parent = spawnerContent

local function GetSpawnCFrame(): CFrame
    local camera = Workspace.CurrentCamera
    if camera then
        return camera.CFrame * CFrame.new(0, 0, -12)
    end
    return CFrame.new(0, 5, 0)
end

-- 1. Spawn Mesin ATM Bank
CreateButton(spawnerContent, "🏦 Spawn Mesin ATM (Setor/Tarik)", Color3.fromRGB(41, 128, 185), function()
    ChangeHistoryService:SetWaypoint("SpawnATM")

    local model = Instance.new("Model")
    model.Name = "ATM_Bank_MandiriBCA"

    local body = Instance.new("Part")
    body.Name = "Body"
    body.Size = Vector3.new(3, 6, 2.5)
    body.CFrame = GetSpawnCFrame()
    body.Anchored = true
    body.Material = Enum.Material.Metal
    body.Color = Color3.fromRGB(44, 62, 80)
    body.Parent = model

    -- Layar ATM
    local screen = Instance.new("Part")
    screen.Name = "Screen"
    screen.Size = Vector3.new(2.4, 2, 0.2)
    screen.CFrame = body.CFrame * CFrame.new(0, 1, 1.2)
    screen.Anchored = true
    screen.Material = Enum.Material.Neon
    screen.Color = Color3.fromRGB(52, 152, 219)
    screen.Parent = model

    -- ProximityPrompt
    local prompt = Instance.new("ProximityPrompt")
    prompt.ActionText = "Gunakan ATM"
    prompt.ObjectText = "Bank ATM Bersama"
    prompt.HoldDuration = 0.5
    prompt.MaxActivationDistance = 8
    prompt:SetAttribute("EconomyType", "ATM")
    prompt.Parent = body

    model.PrimaryPart = body
    model.Parent = Workspace
    Selection:Set({ model })

    ChangeHistoryService:SetWaypoint("SpawnedATM")
end)

-- 2. Spawn Warung Kelontong / Toko Kebutuhan
CreateButton(spawnerContent, "🏪 Spawn Warung Kelontong (Sink Belanja)", Color3.fromRGB(39, 174, 96), function()
    ChangeHistoryService:SetWaypoint("SpawnWarung")

    local model = Instance.new("Model")
    model.Name = "Warung_Makan_Madura"

    local counter = Instance.new("Part")
    counter.Name = "Counter"
    counter.Size = Vector3.new(6, 3, 2.5)
    counter.CFrame = GetSpawnCFrame()
    counter.Anchored = true
    counter.Material = Enum.Material.WoodPlanks
    counter.Color = Color3.fromRGB(180, 115, 60)
    counter.Parent = model

    local roof = Instance.new("Part")
    roof.Name = "Kanopi"
    roof.Size = Vector3.new(6.4, 0.4, 3.5)
    roof.CFrame = counter.CFrame * CFrame.new(0, 3, 0.2)
    roof.Anchored = true
    roof.Material = Enum.Material.Fabric
    roof.Color = Color3.fromRGB(192, 57, 43)
    roof.Parent = model

    local prompt = Instance.new("ProximityPrompt")
    prompt.ActionText = "Beli Makanan & Minuman"
    prompt.ObjectText = "Warung Berkah"
    prompt.HoldDuration = 0.5
    prompt.MaxActivationDistance = 10
    prompt:SetAttribute("EconomyType", "Shop")
    prompt:SetAttribute("ShopItemId", "food_nasgor")
    prompt.Parent = counter

    model.PrimaryPart = counter
    model.Parent = Workspace
    Selection:Set({ model })

    ChangeHistoryService:SetWaypoint("SpawnedWarung")
end)

-- 3. Spawn Pos Ekspedisi / Kurir
CreateButton(spawnerContent, "📦 Spawn Pos Kerja Kurir (Job Node)", Color3.fromRGB(243, 156, 18), function()
    ChangeHistoryService:SetWaypoint("SpawnKurir")

    local model = Instance.new("Model")
    model.Name = "Pos_Ekspedisi_Pulau"

    local desk = Instance.new("Part")
    desk.Name = "MejaDaftar"
    desk.Size = Vector3.new(4, 3, 2)
    desk.CFrame = GetSpawnCFrame()
    desk.Anchored = true
    desk.Material = Enum.Material.SmoothPlastic
    desk.Color = Color3.fromRGB(230, 126, 34)
    desk.Parent = model

    local prompt = Instance.new("ProximityPrompt")
    prompt.ActionText = "Daftar Jadi Kurir"
    prompt.ObjectText = "Ekspedisi Pulau Sejahtera"
    prompt.HoldDuration = 0.8
    prompt.MaxActivationDistance = 8
    prompt:SetAttribute("EconomyType", "JobStation")
    prompt:SetAttribute("JobId", "Courier")
    prompt.Parent = desk

    model.PrimaryPart = desk
    model.Parent = Workspace
    Selection:Set({ model })

    ChangeHistoryService:SetWaypoint("SpawnedKurir")
end)

-- 4. Spawn Dermaga Pengepul Ikan (TPI Nelayan)
CreateButton(spawnerContent, "🎣 Spawn Dermaga TPI (Jual Tangkapan)", Color3.fromRGB(22, 160, 133), function()
    ChangeHistoryService:SetWaypoint("SpawnTPI")

    local model = Instance.new("Model")
    model.Name = "Dermaga_TPI_Pengepul"

    local dock = Instance.new("Part")
    dock.Name = "Dermaga"
    dock.Size = Vector3.new(8, 1, 8)
    dock.CFrame = GetSpawnCFrame()
    dock.Anchored = true
    dock.Material = Enum.Material.Wood
    dock.Color = Color3.fromRGB(120, 80, 45)
    dock.Parent = model

    local box = Instance.new("Part")
    box.Name = "KotakIkan"
    box.Size = Vector3.new(2, 1.5, 2)
    box.CFrame = dock.CFrame * CFrame.new(0, 1.25, 0)
    box.Anchored = true
    box.Material = Enum.Material.Ice
    box.Color = Color3.fromRGB(180, 220, 240)
    box.Parent = model

    local prompt = Instance.new("ProximityPrompt")
    prompt.ActionText = "Jual Hasil Ikan"
    prompt.ObjectText = "Pengepul Ikan TPI"
    prompt.HoldDuration = 0.5
    prompt.MaxActivationDistance = 10
    prompt:SetAttribute("EconomyType", "FishBuyer")
    prompt.Parent = box

    model.PrimaryPart = dock
    model.Parent = Workspace
    Selection:Set({ model })

    ChangeHistoryService:SetWaypoint("SpawnedTPI")
end)

-- 5. Spawn Lapak Pasar Trade (Safe Zone)
CreateButton(spawnerContent, "🤝 Spawn Area Pasar (Safe Trade Zone)", Color3.fromRGB(142, 68, 173), function()
    ChangeHistoryService:SetWaypoint("SpawnPasar")

    local zone = Instance.new("Part")
    zone.Name = "Pasar_SafeTradeZone"
    zone.Size = Vector3.new(30, 0.5, 30)
    zone.CFrame = GetSpawnCFrame()
    zone.Anchored = true
    zone.CanCollide = false
    zone.Transparency = 0.7
    zone.Material = Enum.Material.ForceField
    zone.Color = Color3.fromRGB(155, 89, 182)
    zone:SetAttribute("IsTradeZone", true)
    zone.Parent = Workspace
    Selection:Set({ zone })

    ChangeHistoryService:SetWaypoint("SpawnedPasar")
end)

-- ====================================================================================
-- SEKSI 3: LIVE ECONOMY SIMULATOR & BALANCER (ANTI-INFLASI)
-- ====================================================================================
local _, calcContent = CreateSection("⚖️ 3. LIVE ECONOMY & INFLATION BALANCER", 280)

local calcInfo = Instance.new("TextLabel")
calcInfo.Size = UDim2.new(1, 0, 0, 95)
calcInfo.BackgroundTransparency = 1
calcInfo.Font = Enum.Font.Gotham
calcInfo.TextColor3 = TEXT_MUTED
calcInfo.TextSize = 11
calcInfo.TextWrapped = true
calcInfo.TextXAlignment = Enum.TextXAlignment.Left
calcInfo.Text = [[Simulasi Server (Kapasitas: 20 Pemain):
• Faucet (Uang Masuk / Jam):
  - 15 Pemain Bekerja @ Rp 65.000/5m = Rp 11.700.000 / Jam
• Sink (Uang Keluar / Dihapus per Jam):
  - Makanan & Minuman Wajib: Rp 4.800.000 / Jam
  - Pajak Perdagangan P2P (3.5% Trade Fee): ~Rp 2.100.000 / Jam
  - Bensin & Denda: ~Rp 1.500.000 / Jam
• Inflasi Bersih: + Rp 3.300.000 / Jam (Stabil & Sehat)]]
calcInfo.Parent = calcContent

CreateButton(calcContent, "🔍 Analisis Keseimbangan Ekonomi Sekarang", Color3.fromRGB(52, 73, 94), function()
    local configModule = ReplicatedStorage:FindFirstChild("EconomySystem")
        and ReplicatedStorage.EconomySystem:FindFirstChild("Config")
        and ReplicatedStorage.EconomySystem.Config:FindFirstChild("EconomyConfig")

    if configModule and configModule:IsA("ModuleScript") then
        local success, cfg = pcall(require, configModule)
        if success and cfg.LiveEconomy then
            print("==================================================")
            print("[IndoRP Live Economy Audit Report]")
            print("Pajak Trade P2P: " .. tostring(cfg.LiveEconomy.P2PTradeTaxPercent) .. "%")
            print("Pajak Transfer Bank: " .. tostring(cfg.LiveEconomy.BankTransferFeePercent) .. "%")
            print("Starter Cash: Rp " .. tostring(cfg.Currency.StartingCash))
            print("Starter Bank: Rp " .. tostring(cfg.Currency.StartingBank))
            print("Status Inflasi: Terkendali dengan Pajak Transaksi Atomik.")
            print("==================================================")
        end
    else
        warn("[IndoRP] EconomyConfig belum terpasang di ReplicatedStorage!")
    end
end)

local noteLabel = Instance.new("TextLabel")
noteLabel.Size = UDim2.new(1, 0, 0, 40)
noteLabel.Position = UDim2.new(0, 0, 0, 150)
noteLabel.BackgroundTransparency = 1
noteLabel.Font = Enum.Font.Gotham
noteLabel.TextColor3 = TEXT_MUTED
noteLabel.TextSize = 10
noteLabel.TextWrapped = true
noteLabel.Text = "💡 Tips: Agar mata uang bernilai tinggi, pastikan pajak transaksi P2P tidak di-set 0%. Pembakaran uang (sink) menjaga harga barang di pasar stabil."
noteLabel.Parent = calcContent

-- Watermark tambahan di bagian bawah canvas scroll
local innerWatermark = Instance.new("TextLabel")
innerWatermark.Name = "InnerWatermark"
innerWatermark.Size = UDim2.new(1, 0, 0, 24)
innerWatermark.BackgroundTransparency = 1
innerWatermark.Font = Enum.Font.GothamMedium
innerWatermark.TextColor3 = Color3.fromRGB(115, 125, 142)
innerWatermark.TextSize = 10
innerWatermark.Text = "MFNH Studio@2026"
innerWatermark.Parent = mainFrame

-- ====================================================================================
-- PERMANENT PROTECTED FOOTER (MFNH STUDIO WATERMARK & TAMPER GUARD)
-- ====================================================================================
local WATERMARK_TEXT = "MFNH Studio@2026"

local function BuildProtectedFooter()
    local existing = widget:FindFirstChild("MFNH_ProtectedFooter")
    if existing then
        existing:Destroy()
    end

    local footerFrame = Instance.new("Frame")
    footerFrame.Name = "MFNH_ProtectedFooter"
    footerFrame.Size = UDim2.new(1, 0, 0, 26)
    footerFrame.Position = UDim2.new(0, 0, 1, -26)
    footerFrame.BackgroundColor3 = Color3.fromRGB(20, 23, 29)
    footerFrame.BorderSizePixel = 0
    footerFrame.ZIndex = 100
    footerFrame.Parent = widget

    local footerTopBorder = Instance.new("Frame")
    footerTopBorder.Name = "BorderLine"
    footerTopBorder.Size = UDim2.new(1, 0, 0, 1)
    footerTopBorder.BackgroundColor3 = Color3.fromRGB(48, 54, 68)
    footerTopBorder.BorderSizePixel = 0
    footerTopBorder.ZIndex = 101
    footerTopBorder.Parent = footerFrame

    local footerLabel = Instance.new("TextLabel")
    footerLabel.Name = "WatermarkLabel"
    footerLabel.Size = UDim2.new(1, 0, 1, 0)
    footerLabel.BackgroundTransparency = 1
    footerLabel.Font = Enum.Font.GothamMedium
    footerLabel.TextColor3 = Color3.fromRGB(145, 155, 172)
    footerLabel.TextSize = 10
    footerLabel.Text = WATERMARK_TEXT
    footerLabel.ZIndex = 102
    footerLabel.Parent = footerFrame

    -- Proteksi Anti-Ubah / Anti-Hapus (Tamper Guard)
    footerLabel:GetPropertyChangedSignal("Text"):Connect(function()
        if footerLabel.Text ~= WATERMARK_TEXT then
            footerLabel.Text = WATERMARK_TEXT
        end
    end)

    footerLabel:GetPropertyChangedSignal("Visible"):Connect(function()
        if not footerLabel.Visible then
            footerLabel.Visible = true
        end
    end)

    footerFrame:GetPropertyChangedSignal("Visible"):Connect(function()
        if not footerFrame.Visible then
            footerFrame.Visible = true
        end
    end)

    footerFrame.AncestryChanged:Connect(function(_, parent)
        if parent ~= widget then
            task.delay(0.1, BuildProtectedFooter)
        end
    end)
end

BuildProtectedFooter()

print("[RP-Plugin Live Economy Suite] Plugin Loaded Successfully!")
