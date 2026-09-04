param(
	[string]$SourceDir = "src",
	[string]$OutputFile = "build\NexusUI.lua"
)

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Split-Path -Parent $root

$srcPath = Join-Path $projectRoot $SourceDir
$outPath = Join-Path $projectRoot $OutputFile

if (-not (Test-Path $srcPath)) {
	Write-Error "Source directory not found: $srcPath"
}

if (-not (Test-Path (Split-Path -Parent $outPath))) {
	New-Item -ItemType Directory -Force -Path (Split-Path -Parent $outPath) | Out-Null
}

$moduleOrder = @(
	"Core\Signal.luau",
	"Core\Maid.luau",
	"Core\Config.luau",
	"Core\Device.luau",
	"Core\Icons.luau",
	"Core\Input.luau",
	"Animation\Easing.luau",
	"Animation\Spring.luau",
	"Animation\Animator.luau",
	"Theme\ThemeManager.luau",
	"Theme\DefaultTheme.luau",
	"Utilities\UIUtils.luau",
	"Utilities\Sound.luau",
	"Core\Component.luau",
	"Components\BaseComponent.luau",
	"Components\Label.luau",
	"Components\Paragraph.luau",
	"Components\Divider.luau",
	"Components\Badge.luau",
	"Components\Button.luau",
	"Components\Toggle.luau",
	"Components\Checkbox.luau",
	"Components\Slider.luau",
	"Components\Dropdown.luau",
	"Components\MultiDropdown.luau",
	"Components\TextBox.luau",
	"Components\SearchBox.luau",
	"Components\Keybind.luau",
	"Components\ColorPicker.luau",
	"Components\ProgressBar.luau",
	"Components\LoadingIndicator.luau",
	"Components\Card.luau",
	"Components\Image.luau",
	"Components\Toast.luau",
	"Components\Tooltip.luau",
	"Components\ContextMenu.luau",
	"Components\Modal.luau",
	"Components\Tab.luau",
	"Components\Section.luau",
	"Components\Window.luau",
	"Components\QuickActions.luau",
	"Services\NotificationSystem.luau",
	"Services\CommandPalette.luau",
	"Services\Preset.luau",
	"Services\Debug.luau",
	"Services\Fluent.luau",
	"Services\Welcome.luau",
	"Services\KeySystem.luau",
	"Demo\Demo.luau",
	"init.luau"
)

function getModuleKey([string]$relativePath) {
	$rel = $relativePath -replace "\.luau$", ""
	$rel = $rel -replace "\\", "."
	$rel = $rel -replace "/", "."
	return $rel
}

$bundle = New-Object System.Text.StringBuilder

[void]$bundle.AppendLine("-- NexusUI v1.0.0 | https://github.com/NexusUI1 | MIT License")
[void]$bundle.AppendLine("-- Bundled build generated at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')")
[void]$bundle.AppendLine("")
[void]$bundle.AppendLine("local __MODULES = {}")
[void]$bundle.AppendLine("local __CACHE = {}")
[void]$bundle.AppendLine("")

$totalLines = 0

foreach ($modulePath in $moduleOrder) {
	$fullPath = Join-Path $srcPath $modulePath

	if (-not (Test-Path $fullPath)) {
		Write-Warning "Module not found, skipping: $modulePath"
		continue
	}

	$content = Get-Content -LiteralPath $fullPath -Raw
	$lines = (Get-Content -LiteralPath $fullPath).Count
	$totalLines += $lines

	$moduleKey = getModuleKey $modulePath

	$bracketDepth = 0
	while ($true) {
		$equals = "=" * $bracketDepth
		$openToken = "[$equals["
		$closeToken = "]$equals]"
		if (-not $content.Contains($closeToken)) {
			break
		}
		$bracketDepth++
	}

	$equals = "=" * $bracketDepth

	[void]$bundle.AppendLine('__MODULES["' + $moduleKey + '"] = [' + $equals + '[' + $content + ']' + $equals + ']')
}

[void]$bundle.AppendLine("")

$loader = @'
local function __require(key)
	if __CACHE[key] then
		return __CACHE[key]
	end

	local source = __MODULES[key]
	if not source then
		error("[NexusUI] Module not found: " .. tostring(key), 2)
	end

	local fn, loadErr = loadstring(source, "=" .. key)
	if not fn then
		error("[NexusUI] Failed to load module " .. tostring(key) .. ": " .. tostring(loadErr), 2)
	end

	local module = fn()
	__CACHE[key] = module

	return module
end

local NexusUI = __require("init")

if getgenv then
	getgenv().NexusUI = NexusUI
end

return NexusUI
'@

[void]$bundle.AppendLine($loader)

$output = $bundle.ToString()
Set-Content -LiteralPath $outPath -Value $output -Encoding UTF8

$outLines = (Get-Content -LiteralPath $outPath).Count
Write-Output "Build complete: $outPath"
Write-Output "Source modules: $($moduleOrder.Count)"
Write-Output "Source lines: $totalLines"
Write-Output "Bundle lines: $outLines"
