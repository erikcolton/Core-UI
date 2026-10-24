--[[
	Plays theme UI sounds (click, open, close, notify) locally. Silent when the
	active theme has no id for that sound.
]]

local SoundService = game:GetService("SoundService")

local Create = require(script.Parent.Create)
local Theme = require(script.Parent.Parent.Theme)

local Sound = {}

local cache: { [string]: Sound } = {}

function Sound.play(key: string)
	local sounds = Theme.get().sounds
	local id = sounds[key]
	if not id or id == "" then
		return
	end
	local sound = cache[id]
	if not sound or not sound.Parent then
		sound = Create("Sound", { Name = "CoreUI_" .. key, SoundId = id, Parent = SoundService })
		cache[id] = sound
	end
	sound.Volume = sounds.volume or 0.5
	SoundService:PlayLocalSound(sound)
end

return Sound
