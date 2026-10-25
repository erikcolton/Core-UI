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
	local SLIDE_DISTANCE = 48

	--[[
	Open or close animation for windows and dialogs, picked by motion.openStyle:
	"pop" (scale up from motion.openFrom), "slide" (rise from below) or "none".
	target is the moving frame, scale its UIScale and home its resting Position.
	Returns the tween, or nil when nothing animates.
]]
	function Tween.reveal(target: GuiObject, scale: UIScale, home: UDim2, opening: boolean): Tween?
		local motion = Theme.get().motion
		local style = motion.openStyle or "pop"
		local below = home + UDim2.fromOffset(0, SLIDE_DISTANCE)
		if opening then
			if style == "slide" then
				scale.Scale = 1
				target.Position = below
				return Tween.play(target, { Position = home }, "normal")
			elseif style == "pop" then
				target.Position = home
				scale.Scale = motion.openFrom
				return Tween.pop(scale, { Scale = 1 })
			end
			target.Position = home
			scale.Scale = 1
			return nil
		end
		if style == "slide" then
			return Tween.play(target, { Position = below }, "fast", nil, Enum.EasingDirection.In)
		elseif style == "pop" then
			return Tween.play(scale, { Scale = motion.openFrom }, "fast", nil, Enum.EasingDirection.In)
		end
		return nil
	end

	return Tween.play(instance, goals, speed, Theme.get().motion.pop)
end

local SLIDE_DISTANCE = 48

--[[
	Open or close animation for windows and dialogs, picked by motion.openStyle:
	"pop" (scale up from motion.openFrom), "slide" (rise from below) or "none".
	target is the moving frame, scale its UIScale and home its resting Position.
	Returns the tween, or nil when nothing animates.
]]
function Tween.reveal(target: GuiObject, scale: UIScale, home: UDim2, opening: boolean): Tween?
	local motion = Theme.get().motion
	local style = motion.openStyle or "pop"
	local below = home + UDim2.fromOffset(0, SLIDE_DISTANCE)
	if opening then
		if style == "slide" then
			scale.Scale = 1
			target.Position = below
			return Tween.play(target, { Position = home }, "normal")
		elseif style == "pop" then
			target.Position = home
			scale.Scale = motion.openFrom
			return Tween.pop(scale, { Scale = 1 })
		end
		target.Position = home
		scale.Scale = 1
		return nil
	end
	if style == "slide" then
		return Tween.play(target, { Position = below }, "fast", nil, Enum.EasingDirection.In)
	elseif style == "pop" then
		return Tween.play(scale, { Scale = motion.openFrom }, "fast", nil, Enum.EasingDirection.In)
	end
	return nil
end

return Tween
