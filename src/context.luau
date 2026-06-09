export type SubscriptionCallback = (cur: boolean, prev: boolean?) -> ()

export type Context = {
	Name: string,
	Enabled: boolean,
	enable: (Context) -> Context,
	disable: (Context) -> Context,
	subscribe: (Context, SubscriptionCallback) -> (),
	unsubscribe: (Context, SubscriptionCallback) -> (),
}

type Private = {
	subscriptions: { [SubscriptionCallback]: SubscriptionCallback },
}

local function context(name: string)
	local self = {
		Name = name,
		Enabled = false,
	} :: Context

	local private = {
		subscriptions = {},
	} :: Private

	self.enable = function()
		local prev = self.Enabled
		self.Enabled = true
		for _, cb in private.subscriptions do
			cb(true, prev)
		end
		return self
	end

	self.disable = function()
		local prev = self.Enabled
		self.Enabled = false
		for _, cb in private.subscriptions do
			cb(false, prev)
		end
		return self
	end

	self.subscribe = function(_, cb)
		private.subscriptions[cb] = cb
	end

	self.unsubscribe = function(_, cb)
		if private.subscriptions[cb] then
			private.subscriptions[cb] = nil
		end
	end

	return self
end

return context
