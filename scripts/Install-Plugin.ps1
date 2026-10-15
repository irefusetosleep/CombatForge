$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path -Parent $PSScriptRoot
$pluginPath = 'C:\Users\lewis\AppData\Local\Roblox\Plugins\CombatForge.rbxmx'
$buildDirectory = Join-Path $projectRoot 'build'
$artifactPath = Join-Path $buildDirectory 'CombatForge.rbxmx'
$projectFile = Join-Path $projectRoot 'default.project.json'

if (-not (Test-Path -LiteralPath (Split-Path -Parent $pluginPath) -PathType Container)) {
    throw "Roblox Plugins folder not found: $pluginPath"
}

New-Item -ItemType Directory -Force -Path $buildDirectory | Out-Null
& rojo build $projectFile -o $artifactPath
if ($LASTEXITCODE -ne 0) { throw 'Rojo build failed; installed plugin was not changed.' }
& (Join-Path $PSScriptRoot 'Test-PluginPackage.ps1') -Path $artifactPath

if (Test-Path -LiteralPath $pluginPath -PathType Leaf) {
    if ((Get-FileHash -LiteralPath $artifactPath).Hash -eq (Get-FileHash -LiteralPath $pluginPath).Hash) {
        Write-Output 'CombatForge is already up to date.'
        exit 0
    }
    $backupDirectory = Join-Path $buildDirectory 'plugin-backups'
    New-Item -ItemType Directory -Force -Path $backupDirectory | Out-Null
    $backupPath = Join-Path $backupDirectory ("CombatForge-{0}.rbxmx" -f (Get-Date -Format 'yyyyMMdd-HHmmss-fffffff'))
    Copy-Item -LiteralPath $pluginPath -Destination $backupPath
    Write-Output "Previous installation backed up to $backupPath"
}

Copy-Item -LiteralPath $artifactPath -Destination $pluginPath -Force
if ((Get-FileHash -LiteralPath $artifactPath).Hash -ne (Get-FileHash -LiteralPath $pluginPath).Hash) {
    throw 'Installed plugin verification failed. The previous installation is in build/plugin-backups if it existed.'
}
Write-Output "Installed and verified: $pluginPath"
Write-Output 'If Studio still shows the previous version, save your place and restart Studio.'
