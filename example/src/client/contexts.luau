local soma = require("./soma")
local context = soma.context

local contexts = {
	Lobby = context("LOBBY"):enable(),
	Match = context("MATCH"),
}

return contexts
