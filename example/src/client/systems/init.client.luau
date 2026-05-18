local RunService = game:GetService("RunService")

local soma = require("./soma")

local systems = {}
for _, system in script:GetChildren() do
	table.insert(systems, require(system))
end

RunService.Heartbeat:Connect(function(dt)
	soma.update(dt)
	for _, system in systems do
		system()
	end
end)
