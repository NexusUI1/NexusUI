local SoundService = game:GetService("SoundService")

local Config = require(script.Parent.Parent.Core.Config)

local Sound = {}
Sound.__index = Sound

Sound._cache = {}
Sound.Enabled = true
Sound.Volume = 0.5

local function getSound(id)
	if not id then
		return nil
	end

	if Sound._cache[id] then
		return Sound._cache[id]
	end

	local sound = Instance.new("Sound")
	sound.SoundId = id
	sound.Volume = Sound.Volume
	sound.Name = "NexusSound"

	Sound._cache[id] = sound
	return sound
end

function Sound.Play(name, customVolume, playbackSpeed)
	if not Sound.Enabled then
		return
	end
	if not Config.Sounds.Enabled then
		return
	end

	local id = Config.Sounds[name] or name
	if type(id) ~= "string" then
		return
	end

	local sound = getSound(id)
	if not sound then
		return
	end

	sound.Volume = customVolume or Config.Sounds.Volume or 0.4
	sound.PlaybackSpeed = playbackSpeed or 1

	local success, err = pcall(function()
		SoundService:PlayLocalSound(sound)
	end)

	if not success then
		warn("[NexusUI] Failed to play sound:", name, err)
	end

	return sound
end

function Sound.SetVolume(volume)
	Sound.Volume = volume
	Config.Sounds.Volume = volume
end

function Sound.SetEnabled(enabled)
	Sound.Enabled = enabled
	Config.Sounds.Enabled = enabled
end

function Sound.ClearCache()
	for id, sound in pairs(Sound._cache) do
		pcall(function() sound:Destroy() end)
		Sound._cache[id] = nil
	end
end

Sound.Click = function() return Sound.Play("Click", nil, 1.1) end
Sound.Hover = function() return Sound.Play("Hover", nil, 1.2) end
Sound.Open = function() return Sound.Play("Open") end
Sound.Close = function() return Sound.Play("Close") end
Sound.Error = function() return Sound.Play("Error") end
Sound.Success = function() return Sound.Play("Success") end
Sound.Toggle = function() return Sound.Play("Toggle", nil, 1.15) end
Sound.Pop = function() return Sound.Play("Pop", nil, 1.3) end

return Sound
