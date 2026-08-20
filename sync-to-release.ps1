$source = "c:\MyApps\PZ Mods\[SVRP] Chat\[SVRP] ChatLocal"
$dest = "c:\MyApps\PZ Mods\[SVRP] Chat\[SVRP] Chat"

Write-Host "Syncing development files from $source to $dest..."

if (Test-Path -LiteralPath $dest) {
    Remove-Item -LiteralPath $dest -Recurse -Force
}

Copy-Item -LiteralPath $source -Destination $dest -Recurse

# Remove development files from the release folder
$devExtensions = @("*.fbx", "*.blend", "*.psd", "*.kra", "*.pdn", "*.code-workspace", ".gitignore", ".git", ".vscode")
foreach ($ext in $devExtensions) {
    Get-ChildItem -LiteralPath $dest -Recurse -Filter $ext -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
}

# Update mod.info
$modInfo = "$dest\common\mod.info"
if (Test-Path -LiteralPath $modInfo) {
    $content = Get-Content -LiteralPath $modInfo -Raw
    $content = $content -replace 'id=SVRPChatLocal', 'id=SVRPChat' -replace 'name=\[SVRP\] ChatLocal', 'name=[SVRP] Chat'
    Set-Content -LiteralPath $modInfo $content -NoNewline
}

# Update sandbox options
$sandboxOptions = "$dest\42\media\sandbox-options.txt"
if (Test-Path -LiteralPath $sandboxOptions) {
    $content = Get-Content -LiteralPath $sandboxOptions -Raw
    $content = $content -replace 'SVRPChatLocal', 'SVRPChat'
    Set-Content -LiteralPath $sandboxOptions $content -NoNewline
}

# Update all Lua files to use SandboxVars.SVRPChat and SVRPChat instead of SVRPChatLocal
Get-ChildItem -LiteralPath "$dest\42\media\lua" -Recurse -Filter "*.lua" | ForEach-Object {
    $content = Get-Content -LiteralPath $_.FullName -Raw
    $newContent = $content -replace 'SandboxVars\.SVRPChatLocal\b', 'SandboxVars.SVRPChat' -replace 'SVRPChatLocal', 'SVRPChat'
    Set-Content -LiteralPath $_.FullName $newContent -NoNewline
}

Write-Host "Successfully synced [SVRP] ChatLocal (Development) to [SVRP] Chat (Release)!"

# Helper function to reliably clean and copy directory contents using LiteralPaths
function Sync-DirectoryContents($fromDir, $toDir) {
    if (-not (Test-Path -LiteralPath $toDir)) {
        New-Item -ItemType Directory -Path $toDir -Force | Out-Null
    } else {
        Get-ChildItem -LiteralPath $toDir | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
    }
    Get-ChildItem -LiteralPath $fromDir | ForEach-Object {
        Copy-Item -LiteralPath $_.FullName -Destination $toDir -Recurse -Force
    }
}

# 1. Sync to Zomboid Workshop directory for Steam upload
$workshopBase = "$env:USERPROFILE\Zomboid\Workshop\[SVRP] Chat"
$workshopDest = "$workshopBase\Contents\mods\[SVRP] Chat"
if (Test-Path -LiteralPath $workshopBase) {
    Sync-DirectoryContents $dest $workshopDest
    Write-Host "Successfully copied release files to Zomboid Workshop directory ($workshopDest) for Steam upload!"
}

# 2. Sync Release to local Zomboid mods directory (SVRPChat)
$localModsBase = "$env:USERPROFILE\Zomboid\mods"
$localModsRelease = "$localModsBase\SVRPChat"
if (Test-Path -LiteralPath $localModsBase) {
    Sync-DirectoryContents $dest $localModsRelease
    Write-Host "Successfully copied release files to local Zomboid mods directory ($localModsRelease)!"
}

# 3. Sync Development to local Zomboid mods directory (SVRPChatLocal)
$localModsDev = "$localModsBase\SVRPChatLocal"
if (Test-Path -LiteralPath $localModsBase) {
    Sync-DirectoryContents $source $localModsDev
    # Clean dev models/files from local mods directory so it matches clean game state
    foreach ($ext in $devExtensions) {
        Get-ChildItem -LiteralPath $localModsDev -Recurse -Filter $ext -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
    }
    Write-Host "Successfully copied dev files to local Zomboid mods directory ($localModsDev)!"
}

Write-Host "All sync operations completed successfully!"
