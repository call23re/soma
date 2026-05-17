export type Context = {
	Name: string,
	Enabled: boolean,
	enable: () -> Context,
	disable: () -> Context,
}

local function context(name: string)
	local self = {
		Name = name,
		Enabled = false,
	}

	self.enable = function()
		self.Enabled = true
		return self
	end

	self.disable = function()
		self.Enabled = false
		return self
	end

	return self
end

return context
