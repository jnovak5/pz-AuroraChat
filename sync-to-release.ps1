$source = "c:\MyApps\PZ Mods\AuroraChat\AuroraChatLocal"
$dest = "c:\MyApps\PZ Mods\AuroraChat\AuroraChat"

if (Test-Path $dest) {
    Remove-Item -Path $dest -Recurse -Force
}

Copy-Item -Path $source -Destination $dest -Recurse

# Update mod.info
$modInfo = "$dest\common\mod.info"
(Get-Content $modInfo) -replace 'id=AuroraChatLocal$', 'id=AuroraChat' -replace 'name=AuroraChatLocal', 'name=Aurora Chat' | Set-Content $modInfo

# Update sandbox options
$sandboxOptions = "$dest\42\media\sandbox-options.txt"
if (Test-Path $sandboxOptions) {
    (Get-Content $sandboxOptions) -replace 'AuroraChatLocal\.', 'AuroraChat.' -replace 'page = AuroraChatLocal', 'page = AuroraChat' | Set-Content $sandboxOptions
}

# Update all Lua files to use SandboxVars.AuroraChat instead of SandboxVars.AuroraChatLocal
Get-ChildItem -Path "$dest\42\media\lua" -Recurse -Filter "*.lua" | ForEach-Object {
    $content = Get-Content $_.FullName
    $newContent = $content -replace 'SandboxVars\.AuroraChatLocal ', 'SandboxVars.AuroraChat ' -replace 'SandboxVars\.AuroraChatLocal\.', 'SandboxVars.AuroraChat.' -replace 'SandboxVars\.AuroraChatLocal\b', 'SandboxVars.AuroraChat'
    Set-Content $_.FullName $newContent
}

Write-Host "Successfully synced AuroraChatLocal (Development) to AuroraChat (Release)!"
