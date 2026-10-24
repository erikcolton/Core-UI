--[[
	Codes: enter and redeem promo codes.

		Codes.new({
			OnRedeem = function(code)
				return redeemRemote:InvokeServer(code) -- return ok, message
			end,
		})

	OnRedeem may yield. Return true/false and an optional message to show.
	Check codes on the server; the client only sends what the player typed.
	Registers itself with the Manager as props.Id (default "Codes").
]]

local Manager = require(script.Parent.Parent.Manager)
local Create = require(script.Parent.Parent.Util.Create)
local Window = require(script.Parent.Parent.Components.Window)
local Text = require(script.Parent.Parent.Components.Text)
local TextInput = require(script.Parent.Parent.Components.TextInput)
local Button = require(script.Parent.Parent.Components.Button)
local Notifications = require(script.Parent.Notifications)

local Codes = {}
Codes.__index = Codes

function Codes.new(props: { [string]: any }?)
	local p = props or {}
	local self = setmetatable({}, Codes)
	self.Id = p.Id or "Codes"
	self._onRedeem = p.OnRedeem
	self._busy = false

	self.Window = Window.new({
		Name = self.Id,
		Title = p.Title or "Codes",
		Size = p.Size or UDim2.fromOffset(440, 300),
	})
	self.Instance = self.Window.Instance

	local body = self.Window.Body
	Create("UIListLayout", {
		FillDirection = Enum.FillDirection.Vertical,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 10),
		Parent = body,
	})
	Text.new({
		Text = p.Description or "Enter a code to get free rewards.",
		Role = "body",
		Color = "textMuted",
		Wrap = true,
		Size = UDim2.new(1, 0, 0, 24),
		LayoutOrder = 1,
		Parent = body,
	})
	self.Input = TextInput.new({
		Placeholder = p.Placeholder or "Type a code",
		Size = UDim2.new(1, 0, 0, 46),
		LayoutOrder = 2,
		Parent = body,
		OnSubmit = function()
			self:Redeem()
		end,
	})
	self.RedeemButton = Button.new({
		Text = "Redeem",
		Variant = "buy",
		FullWidth = true,
		LayoutOrder = 3,
		Parent = body,
		OnClick = function()
			self:Redeem()
		end,
	})
	self._status = Text.new({
		Role = "caption",
		Size = UDim2.new(1, 0, 0, 20),
		LayoutOrder = 4,
		Parent = body,
	})

	Manager.register(self.Id, self)
	return self
end

function Codes:SetStatus(ok: boolean, message: string?)
	self._status:SetColor(if ok then "success" else "error")
	self._status:SetText(message or (if ok then "Code redeemed!" else "That code didn't work."))
end

function Codes:Redeem()
	if self._busy then
		return
	end
	local code = string.gsub(self.Input:GetText(), "^%s*(.-)%s*$", "%1")
	if code == "" then
		self:SetStatus(false, "Type a code first.")
		return
	end
	if not self._onRedeem then
		warn("CoreUI Codes: no OnRedeem handler")
		return
	end

	self._busy = true
	self.RedeemButton:SetEnabled(false)
	self.RedeemButton:SetText("Checking…")
	local success, ok, message = pcall(self._onRedeem, code)
	self._busy = false
	self.RedeemButton:SetEnabled(true)
	self.RedeemButton:SetText("Redeem")

	if not success then
		self:SetStatus(false, "Something went wrong. Try again.")
		warn("CoreUI Codes: OnRedeem errored: " .. tostring(ok))
		return
	end
	self:SetStatus(ok == true, message)
	if ok == true then
		self.Input:SetText("")
		Notifications.success(message or "Code redeemed!")
	end
end

function Codes:Open()
	Manager.open(self.Id)
end

function Codes:Close()
	Manager.close(self.Id)
end

function Codes:Destroy()
	Manager.unregister(self.Id)
	self.Window:Destroy()
end

return Codes
