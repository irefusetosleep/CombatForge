param([Parameter(Mandatory = $true)][string]$Path)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
[xml]$package = Get-Content -Raw -LiteralPath $Path
$roots = $package.SelectNodes('/roblox/Item')
if ($roots.Count -ne 1 -or $roots[0].GetAttribute('class') -ne 'Script') {
    throw 'Plugin package must have one executable Script at its root, not a Folder wrapper.'
}
$root = $roots[0]
$context = $root.SelectSingleNode("Properties/token[@name='RunContext']")
if ($null -eq $context -or $context.InnerText -ne '0') {
    throw 'Plugin entry Script must retain its tested Legacy RunContext.'
}
$disabled = $root.SelectSingleNode("Properties/bool[@name='Disabled']")
if ($null -ne $disabled -and $disabled.InnerText -eq 'true') { throw 'Plugin entry Script is disabled.' }

function Test-Source($Node, [string]$RelativePath) {
    $source = $Node.SelectSingleNode("Properties/*[@name='Source']")
    $expected = Get-Content -Raw -LiteralPath (Join-Path $projectRoot $RelativePath)
    if ($null -eq $source -or $source.InnerText.Replace("`r`n", "`n") -cne $expected.Replace("`r`n", "`n")) {
        throw "Packaged source mismatch: $RelativePath"
    }
}
Test-Source $root 'Plugin/Main.server.luau'
$modules = @{
    UI = 'Plugin/UI.luau'
    Theme = 'Plugin/Theme.luau'
    ColourPicker = 'Plugin/ColourPicker.luau'
    AbilityConfig = 'Plugin/AbilityConfig.luau'
    AbilityManager = 'Plugin/AbilityManager.luau'
    RuntimeInstaller = 'Plugin/RuntimeInstaller.luau'
    HitboxTemplate = 'Runtime/Hitbox.luau'
    ExampleInstaller = 'Plugin/ExampleInstaller.luau'
    ExampleConfigTemplate = 'Examples/ExampleSlashConfig.luau'
}
if ($root.SelectNodes('Item').Count -ne $modules.Count + 1) { throw 'Unexpected plugin child count.' }
foreach ($moduleName in $modules.Keys) {
    $matches = $root.SelectNodes("Item[@class='ModuleScript'][Properties/string[@name='Name']='$moduleName']")
    if ($matches.Count -ne 1) { throw "Missing or duplicated module: $moduleName" }
    Test-Source $matches[0] $modules[$moduleName]
}
$tool = $root.SelectSingleNode("Item[@class='Tool'][Properties/string[@name='Name']='ExampleToolTemplate']")
if ($null -eq $tool -or $tool.SelectNodes('Item').Count -ne 4) { throw 'Missing example Tool or unexpected Tool children.' }
if ($tool.SelectSingleNode("Properties/bool[@name='RequiresHandle']").InnerText -ne 'false') { throw 'Example Tool must work without a Handle.' }
foreach ($entry in @(@('Skill', 'ModuleScript', 'Examples/ExampleSlash.luau'), @('Server', 'Script', 'Examples/ExampleTool.server.luau'), @('Client', 'LocalScript', 'Examples/ExampleTool.client.luau'))) {
    $child = $tool.SelectSingleNode("Item[@class='$($entry[1])'][Properties/string[@name='Name']='$($entry[0])']")
    if ($null -eq $child) { throw "Missing example child: $($entry[0])" }
    Test-Source $child $entry[2]
    if ($entry[1] -ne 'ModuleScript' -and $child.SelectSingleNode("Properties/bool[@name='Disabled']").InnerText -ne 'true') {
        throw 'Example script templates must be disabled inside the plugin.'
    }
}
if ($null -eq $tool.SelectSingleNode("Item[@class='RemoteEvent'][Properties/string[@name='Name']='ActivateSkill']")) { throw 'Example RemoteEvent missing.' }
Write-Output 'Verified executable root Script, module sources and playable example Tool.'
