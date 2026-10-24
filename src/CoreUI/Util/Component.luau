--[[
	Shared plumbing for components: common layout props and parenting.

	Every component is a table with an Instance field (its root GuiObject) and a
	Destroy method. Components that hold children also expose Content, and passing
	such a component as Parent puts the new child inside its Content.
]]

local Component = {}

local LAYOUT_PROPS = {
	"Name",
	"Position",
	"AnchorPoint",
	"Size",
	"LayoutOrder",
	"Visible",
	"ZIndex",
	"AutomaticSize",
	"SizeConstraint",
}

-- Accepts an Instance or a component and returns the Instance to parent into.
function Component.container(target: any): Instance?
	if target == nil then
		return nil
	elseif typeof(target) == "Instance" then
		return target
	end
	return target.Content or target.Instance
end

function Component.instance(target: any): Instance?
	if typeof(target) == "Instance" then
		return target
	end
	return target and target.Instance
end

function Component.applyLayout(instance: Instance, props: { [string]: any })
	for _, key in LAYOUT_PROPS do
		if props[key] ~= nil then
			(instance :: any)[key] = props[key]
		end
	end
end

-- Apply layout props and parent last. Returns self for chaining in constructors.
function Component.finish(self: any, props: { [string]: any }): any
	Component.applyLayout(self.Instance, props)
	local parent = Component.container(props.Parent)
	if parent then
		self.Instance.Parent = parent
	end
	return self
end

return Component
