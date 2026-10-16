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
