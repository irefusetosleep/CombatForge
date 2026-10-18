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
    Keybinds = 'Plugin/Keybinds.luau'
    SnapPreferences = 'Plugin/SnapPreferences.luau'
    UI = 'Plugin/UI.luau'
    Theme = 'Plugin/Theme.luau'
    ColourPicker = 'Plugin/ColourPicker.luau'
    HitboxEditor = 'Plugin/HitboxEditor.luau'
    ProjectileTrajectory = 'Runtime/ProjectileTrajectory.luau'
    AbilityConfig = 'Plugin/AbilityConfig.luau'
    AbilityManager = 'Plugin/AbilityManager.luau'
    RuntimeInstaller = 'Plugin/RuntimeInstaller.luau'
    HitboxTemplate = 'Runtime/Hitbox.luau'
    TemplateInstaller = 'Plugin/TemplateInstaller.luau'
    DummySpawner = 'Plugin/DummySpawner.luau'
}
if ($root.SelectNodes('Item').Count -ne $modules.Count + 2) { throw 'Unexpected plugin child count.' }
foreach ($moduleName in $modules.Keys) {
    $matches = $root.SelectNodes("Item[@class='ModuleScript'][Properties/string[@name='Name']='$moduleName']")
    if ($matches.Count -ne 1) { throw "Missing or duplicated module: $moduleName" }
    Test-Source $matches[0] $modules[$moduleName]
}
$idle = $root.SelectSingleNode("Item[@class='ModuleScript'][Properties/string[@name='Name']='DummySpawner']/Item[@class='Script'][Properties/string[@name='Name']='IdleTemplate']")
if ($null -eq $idle -or $idle.SelectSingleNode("Properties/bool[@name='Disabled']").InnerText -ne 'true') {
    throw 'Dummy idle template must exist and remain disabled inside the plugin.'
}
Test-Source $idle 'Runtime/DummyIdle.server.luau'
foreach ($kind in @('Melee', 'Projectile')) {
    $template = $root.SelectSingleNode("Item[@class='Tool'][Properties/string[@name='Name']='$($kind)ToolTemplate']")
    if ($null -eq $template -or $template.SelectNodes('Item').Count -ne 4) { throw "Missing $kind Tool template or unexpected children." }
    if ($template.SelectSingleNode("Properties/bool[@name='RequiresHandle']").InnerText -ne 'false' -or
        $template.SelectSingleNode("Properties/bool[@name='CanBeDropped']").InnerText -ne 'false') { throw "$kind Tool must work without a Handle and must not be droppable." }
    foreach ($entry in @(@('Skill', 'ModuleScript', "Templates/$($kind)Skill.luau"), @('Server', 'Script', 'Templates/ToolServer.server.luau'), @('Client', 'LocalScript', 'Templates/ToolClient.client.luau'))) {
        $matches = $template.SelectNodes("Item[@class='$($entry[1])'][Properties/string[@name='Name']='$($entry[0])']")
        if ($matches.Count -ne 1) { throw "Missing or duplicated $kind child: $($entry[0])" }
        Test-Source $matches[0] $entry[2]
        if ($entry[1] -ne 'ModuleScript' -and $matches[0].SelectSingleNode("Properties/bool[@name='Disabled']").InnerText -ne 'true') { throw "$kind runtime scripts must be disabled inside the plugin." }
    }
    if ($kind -eq 'Projectile') {
        $helper = $template.SelectNodes("Item[@class='ModuleScript'][Properties/string[@name='Name']='Skill']/Item[@class='ModuleScript'][Properties/string[@name='Name']='Trajectory']")
        if ($helper.Count -ne 1) { throw 'Projectile Skill must contain one Trajectory module.' }
        Test-Source $helper[0] 'Runtime/ProjectileTrajectory.luau'
    }
    if ($template.SelectNodes("Item[@class='RemoteEvent'][Properties/string[@name='Name']='ActivateSkill']").Count -ne 1) { throw "$kind activation RemoteEvent missing or duplicated." }
}
Write-Output 'Verified executable Legacy root, module sources, disabled basic skill Tool templates.'
