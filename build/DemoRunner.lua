--[[
	NexusUI Demo Runner
	https://github.com/NexusUI1

	Requires the main bundle to be loaded first:
		loadstring(game:HttpGet("https://raw.githubusercontent.com/NexusUI1/NexusUI/main/build/NexusUI.lua"))()

	Then:
		loadstring(game:HttpGet("https://raw.githubusercontent.com/NexusUI1/NexusUI/main/build/DemoRunner.lua"))()
]]

local NexusUI = (getgenv and getgenv().NexusUI) or _G.NexusUI

if not NexusUI then
	warn("[NexusUI] Library not loaded. Run the main loader first.")
	return
end

if NexusUI.LaunchDemo then
	local success, result = pcall(function()
		return NexusUI:LaunchDemo()
	end)

	if success then
		print("[NexusUI] Demo launched successfully.")
		print("[NexusUI] Press RightShift to toggle the window, Ctrl+K for command palette.")
	else
		warn("[NexusUI] Demo failed to launch: " .. tostring(result))
	end
else
	warn("[NexusUI] This build does not include the Demo module.")
end
