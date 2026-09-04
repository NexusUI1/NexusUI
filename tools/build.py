import re, os, sys, json

SRC = os.path.join(os.path.dirname(__file__), "..", "src")
OUT = os.path.join(os.path.dirname(__file__), "..", "build", "NexusUI.lua")

MODULE_ORDER = [
	"Core/Signal.luau",
	"Core/Maid.luau",
	"Core/Config.luau",
	"Core/Device.luau",
	"Core/Icons.luau",
	"Core/Input.luau",
	"Animation/Easing.luau",
	"Animation/Spring.luau",
	"Animation/Animator.luau",
	"Theme/ThemeManager.luau",
	"Theme/DefaultTheme.luau",
	"Utilities/UIUtils.luau",
	"Utilities/Sound.luau",
	"Core/Component.luau",
	"Components/BaseComponent.luau",
	"Components/Label.luau",
	"Components/Paragraph.luau",
	"Components/Divider.luau",
	"Components/Badge.luau",
	"Components/Button.luau",
	"Components/Toggle.luau",
	"Components/Checkbox.luau",
	"Components/Slider.luau",
	"Components/Dropdown.luau",
	"Components/MultiDropdown.luau",
	"Components/TextBox.luau",
	"Components/SearchBox.luau",
	"Components/Keybind.luau",
	"Components/ColorPicker.luau",
	"Components/ProgressBar.luau",
	"Components/LoadingIndicator.luau",
	"Components/Card.luau",
	"Components/Image.luau",
	"Components/Toast.luau",
	"Components/Tooltip.luau",
	"Components/ContextMenu.luau",
	"Components/Modal.luau",
	"Components/Tab.luau",
	"Components/Section.luau",
	"Components/Window.luau",
	"Components/QuickActions.luau",
	"Services/NotificationSystem.luau",
	"Services/CommandPalette.luau",
	"Services/Preset.luau",
	"Services/Debug.luau",
	"Services/Fluent.luau",
	"Services/Welcome.luau",
	"Services/KeySystem.luau",
	"Demo/Demo.luau",
	"init.luau",
]

def read(path):
	with open(path, "r", encoding="utf-8") as f:
		return f.read()

def pick_bracket_level(content):
	level = 0
	while ("]" + "=" * level + "]") in content:
		level += 1
	return level

def module_key(rel_path):
	return rel_path[:-5].replace("/", ".").replace("\\", ".")

registry = {}
for rel in MODULE_ORDER:
	key = module_key(rel)
	registry[key] = rel

keyset = set(registry.keys())

def resolve_require(module_dir, expr):
	# expr: content between require( and )
	# patterns: script.X | script.Parent.X | script.Parent.Parent.X | script.Parent.Parent
	if not expr.startswith("script"):
		return None

	rest = expr[len("script"):]
	parts = rest.split(".") if rest else []
	parts = [p for p in parts if p != ""]

	up = 0
	while parts and parts[0] == "Parent":
		up += 1
		parts = parts[1:]

	dir_parts = module_dir.split("/") if module_dir else []
	for _ in range(up):
		if dir_parts:
			dir_parts = dir_parts[:-1]

	segments = dir_parts + parts
	candidate = ".".join(segments)

	if candidate in keyset:
		return candidate

	# suffix fallback: match by last segment
	if parts:
		last = parts[-1]
		for k in keyset:
			if k == last or k.endswith("." + last):
				return k

	return candidate  # unresolved, keep as-is

REQ_RE = re.compile(r"require\(\s*(script(?:\.[A-Za-z_]\w*)*)\s*\)")

def transform(content, module_dir):
	def repl(m):
		expr = m.group(1)
		key = resolve_require(module_dir, expr)
		return '__require("' + key + '")'
	return REQ_RE.sub(repl, content)

out = []
out.append("-- NexusUI v1.0.0 | https://github.com/NexusUI1 | MIT License")
out.append("-- Bundled build. Do not edit manually - rebuild with tools/build.py")
out.append("")
out.append('local __MODULES = {}')
out.append('local __CACHE = {}')
out.append("")

total_source_lines = 0
unresolved = []

for rel in MODULE_ORDER:
	path = os.path.normpath(os.path.join(SRC, rel))
	if not os.path.exists(path):
		print("MISSING:", rel)
		continue

	raw = read(path)
	total_source_lines += raw.count("\n") + 1

	key = module_key(rel)
	module_dir = os.path.dirname(rel)
	content = transform(raw, module_dir)

	# detect unresolved requires (kept as script references)
	if "require(script" in content:
		for m in REQ_RE.finditer(content):
			unresolved.append((rel, m.group(1)))

	level = pick_bracket_level(content)
	opens = "[" + "=" * level + "["
	closes = "]" + "=" * level + "]"

	out.append("__MODULES[\"" + key + "\"] = " + opens + content + closes)

out.append("")
out.append("""local function __require(key)
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

NexusUI.__require = __require

if getgenv then
	getgenv().NexusUI = NexusUI
elseif _G then
	_G.NexusUI = NexusUI
end

return NexusUI""")

result = "\n".join(out)

os.makedirs(os.path.dirname(OUT), exist_ok=True)
with open(OUT, "w", encoding="utf-8", newline="\n") as f:
	f.write(result)

bundle_lines = result.count("\n") + 1

print("Build complete:", os.path.normpath(OUT))
print("Modules:", len(MODULE_ORDER))
print("Source lines:", total_source_lines)
print("Bundle lines:", bundle_lines)

if unresolved:
	print("UNRESOLVED REQUIRES:")
	for f_, e in unresolved:
		print("  ", f_, "->", e)
	sys.exit(1 if unresolved else 0)
