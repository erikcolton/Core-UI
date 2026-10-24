--[[
	Tweens timed by the active theme's motion tokens.
	Respects the player's Reduced Motion setting where the engine exposes it.
]]

local GuiService = game:GetService("GuiService")
local TweenService = game:GetService("TweenService")

local Theme = require(script.Parent.Parent.Theme)

local Tween = {}

local function reducedMotion(): boolean
	local ok, value = pcall(function()
		return (GuiService :: any).ReducedMotionEnabled
	end)
	return ok and value == true
end

-- speed: "fast" | "normal" | "slow" | seconds. style defaults to motion.easing.
function Tween.play(
	instance: Instance,
	goals: { [string]: any },
	speed: (string | number)?,
	style: Enum.EasingStyle?,
	direction: Enum.EasingDirection?
): Tween
	local motion = Theme.get().motion
	local duration = if type(speed) == "number" then speed else motion[speed or "normal"]
	if reducedMotion() then
		duration = 0
	end
	local info = TweenInfo.new(duration, style or motion.easing, direction or Enum.EasingDirection.Out)
	local tween = TweenService:Create(instance, info, goals)
	tween:Play()
	return tween
end

-- Pop: overshoot easing from the theme, used for opening and pulses.
function Tween.pop(instance: Instance, goals: { [string]: any }, speed: (string | number)?): Tween
	return Tween.play(instance, goals, speed, Theme.get().motion.pop)
end

return Tween
