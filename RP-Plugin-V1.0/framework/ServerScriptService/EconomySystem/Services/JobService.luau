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
