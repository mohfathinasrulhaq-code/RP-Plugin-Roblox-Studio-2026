const fs = require('fs');
const path = require('path');

const rootDir = path.resolve(__dirname, '..');
const frameworkDir = path.join(rootDir, 'framework');

const filesToBundle = [
    {
        relPath: 'ReplicatedStorage/EconomySystem/Config/EconomyConfig',
        srcFile: 'ReplicatedStorage/EconomySystem/Config/EconomyConfig.luau',
        className: 'ModuleScript',
        targetParent: 'game:GetService("ReplicatedStorage").EconomySystem.Config',
        instanceName: 'EconomyConfig'
    },
    {
        relPath: 'ReplicatedStorage/EconomySystem/Modules/EconomyNetwork',
        srcFile: 'ReplicatedStorage/EconomySystem/Modules/EconomyNetwork.luau',
        className: 'ModuleScript',
        targetParent: 'game:GetService("ReplicatedStorage").EconomySystem.Modules',
        instanceName: 'EconomyNetwork'
    },
    {
        relPath: 'ReplicatedStorage/EconomySystem/Modules/Types',
        srcFile: 'ReplicatedStorage/EconomySystem/Modules/Types.luau',
        className: 'ModuleScript',
        targetParent: 'game:GetService("ReplicatedStorage").EconomySystem.Modules',
        instanceName: 'Types'
    },
    {
        relPath: 'ServerScriptService/EconomySystem/Services/WalletService',
        srcFile: 'ServerScriptService/EconomySystem/Services/WalletService.luau',
        className: 'ModuleScript',
        targetParent: 'game:GetService("ServerScriptService").EconomySystem.Services',
        instanceName: 'WalletService'
    },
    {
        relPath: 'ServerScriptService/EconomySystem/Services/TradeService',
        srcFile: 'ServerScriptService/EconomySystem/Services/TradeService.luau',
        className: 'ModuleScript',
        targetParent: 'game:GetService("ServerScriptService").EconomySystem.Services',
        instanceName: 'TradeService'
    },
    {
        relPath: 'ServerScriptService/EconomySystem/Services/JobService',
        srcFile: 'ServerScriptService/EconomySystem/Services/JobService.luau',
        className: 'ModuleScript',
        targetParent: 'game:GetService("ServerScriptService").EconomySystem.Services',
        instanceName: 'JobService'
    },
    {
        relPath: 'ServerScriptService/EconomySystem/Services/ShopService',
        srcFile: 'ServerScriptService/EconomySystem/Services/ShopService.luau',
        className: 'ModuleScript',
        targetParent: 'game:GetService("ServerScriptService").EconomySystem.Services',
        instanceName: 'ShopService'
    },
    {
        relPath: 'ServerScriptService/EconomySystem/EconomyServer',
        srcFile: 'ServerScriptService/EconomySystem/EconomyServer.server.luau',
        className: 'Script',
        targetParent: 'game:GetService("ServerScriptService").EconomySystem',
        instanceName: 'EconomyServer'
    },
    {
        relPath: 'StarterPlayer/StarterPlayerScripts/EconomySystem/EconomyClient',
        srcFile: 'StarterPlayer/StarterPlayerScripts/EconomySystem/EconomyClient.client.luau',
        className: 'LocalScript',
        targetParent: 'game:GetService("StarterPlayer").StarterPlayerScripts.EconomySystem',
        instanceName: 'EconomyClient'
    }
];

let luaScriptEntries = [];

for (const item of filesToBundle) {
    const fullPath = path.join(frameworkDir, item.srcFile);
    const content = fs.readFileSync(fullPath, 'utf8');
    
    // Gunakan format string literal Luau dengan separator aman [====[ ... ]====]
    luaScriptEntries.push(`    {
        ClassName = "${item.className}",
        Name = "${item.instanceName}",
        TargetParent = function() return ${item.targetParent} end,
        Source = [====[\n${content}\n]====],
    }`);
}

const installerLua = `--!strict
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
${luaScriptEntries.join(',\n')}
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
`;

const outputPath = path.join(rootDir, 'tools', 'InstallCommandBar.luau');
fs.mkdirSync(path.dirname(outputPath), { recursive: true });
fs.writeFileSync(outputPath, installerLua, 'utf8');
console.log('Successfully generated ' + outputPath);
