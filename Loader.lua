--[[
	NexusUI Loader
	https://github.com/NexusUI1

	Usage (executor):
		loadstring(game:HttpGet("https://raw.githubusercontent.com/NexusUI1/NexusUI/main/build/NexusUI.lua"))()
]]

local BUNDLE_URL = "https://raw.githubusercontent.com/NexusUI1/NexusUI/main/build/NexusUI.lua"

local function fetch(url)
	if game and game.HttpGet then
		local ok, result = pcall(function()
			return game:HttpGet(url, true)
		end)
		if ok and result then
			return result
		end
	end

	if typeof(http_request) == "function" then
		local ok, result = pcall(function()
			return http_request({ Url = url, Method = "GET" }).Body
		end)
		if ok and result then
			return result
		end
	end

	if typeof(syn_request) == "function" then
		local ok, result = pcall(function()
			return syn_request({ Url = url, Method = "GET" }).Body
		end)
		if ok and result then
			return result
		end
	end

	return nil
end

local source = fetch(BUNDLE_URL)

if not source then
	warn("[NexusUI] Failed to fetch bundle from: " .. BUNDLE_URL)
	warn("[NexusUI] Check your internet connection or the repository URL.")
	return nil
end

local fn, err = loadstring(source, "=NexusUI")

if not fn then
	warn("[NexusUI] Failed to compile bundle: " .. tostring(err))
	return nil
end

return fn()
