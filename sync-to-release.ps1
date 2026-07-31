$source = "c:\MyApps\PZ Mods\[SVRP] Chat\[SVRP] ChatLocal"
$dest = "c:\MyApps\PZ Mods\[SVRP] Chat\[SVRP] Chat"

if (Test-Path $dest) {
    Remove-Item -Path $dest -Recurse -Force
}

Copy-Item -Path $source -Destination $dest -Recurse

# Remove development files from the release folder
$devExtensions = @("*.fbx", "*.blend", "*.psd", "*.kra", "*.pdn", "*.code-workspace", ".gitignore", ".git", ".vscode")
foreach ($ext in $devExtensions) {
    Get-ChildItem -Path $dest -Recurse -Filter $ext | Remove-Item -Force
}
# Update mod.info
$modInfo = "$dest\common\mod.info"
(Get-Content $modInfo) -replace 'id=[SVRP] ChatLocal$', 'id=[SVRP] Chat' -replace 'name=[SVRP] ChatLocal', 'name=[SVRP]  Chat' | Set-Content $modInfo

# Update sandbox options
$sandboxOptions = "$dest\42\media\sandbox-options.txt"
if (Test-Path $sandboxOptions) {
    (Get-Content $sandboxOptions) -replace '[SVRP] ChatLocal\.', '[SVRP] Chat.' -replace 'page = [SVRP] ChatLocal', 'page = [SVRP] Chat' | Set-Content $sandboxOptions
}

# Update all Lua files to use SandboxVars.[SVRP] Chat instead of SandboxVars.[SVRP] ChatLocal
Get-ChildItem -Path "$dest\42\media\lua" -Recurse -Filter "*.lua" | ForEach-Object {
    $content = Get-Content $_.FullName
    $newContent = $content -replace 'SandboxVars\.[SVRP] ChatLocal ', 'SandboxVars.[SVRP] Chat ' -replace 'SandboxVars\.[SVRP] ChatLocal\.', 'SandboxVars.[SVRP] Chat.' -replace 'SandboxVars\.[SVRP] ChatLocal\b', 'SandboxVars.[SVRP] Chat'
    Set-Content $_.FullName $newContent
}

Write-Host "Successfully synced [SVRP] ChatLocal (Development) to [SVRP] Chat (Release)!"

$workshopDest = "$env:USERPROFILE\Zomboid\Workshop\[SVRP] Chat\Contents\mods\[SVRP] Chat"
if (Test-Path $workshopDest) {
    Copy-Item -Path "$dest\*" -Destination $workshopDest -Recurse -Force
    Write-Host "Successfully copied release files to Zomboid Workshop directory for Steam upload!"
} else {
    Write-Host "Workshop directory not found, skipping Workshop sync."
}

