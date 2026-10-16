const fs = require('fs');
const path = require('path');

const pluginPath = path.join(__dirname, '..', 'plugin', 'LiveEconomy_StudioPlugin.server.luau');
const installerPath = path.join(__dirname, '..', 'tools', 'InstallCommandBar.luau');

let pluginCode = fs.readFileSync(pluginPath, 'utf8');
const installerCode = fs.readFileSync(installerPath, 'utf8');

const match = installerCode.match(/local BundledFiles = \{[\s\S]*?\n\}/);
if (!match) {
    console.error('Could not find BundledFiles');
    process.exit(1);
}
const bundledFilesCode = match[0];

const oldLogic = '-- 4. Pastikan Remote Folder Terdaftar';
const newLogic = `-- Injeksi Script Source Otomatis
    ${bundledFilesCode}

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

    -- 4. Pastikan Remote Folder Terdaftar`;

pluginCode = pluginCode.replace(oldLogic, newLogic);
fs.writeFileSync(pluginPath, pluginCode, 'utf8');
console.log('Plugin updated with bundled scripts successfully!');
