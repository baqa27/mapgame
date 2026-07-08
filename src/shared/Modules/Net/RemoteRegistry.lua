-- ReplicatedStorage/Modules/Net/RemoteRegistry.lua
-- Server: RemoteRegistry.Init() creates one RemoteEvent per entry in RemoteDefinitions
--         under ReplicatedStorage.Remotes.
-- Server & Client: RemoteRegistry.Get(name) returns the RemoteEvent, waiting for it if
--         the client asks before the server has created it yet.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local RemoteDefinitions = require(script.Parent.RemoteDefinitions)

local RemoteRegistry = {}
local cache = {}

local function getFolder()
	local folder = ReplicatedStorage:FindFirstChild("Remotes")
	if folder then
		return folder
	end
	if RunService:IsServer() then
		folder = Instance.new("Folder")
		folder.Name = "Remotes"
		folder.Parent = ReplicatedStorage
		return folder
	end
	return ReplicatedStorage:WaitForChild("Remotes")
end

function RemoteRegistry.Init()
	assert(RunService:IsServer(), "RemoteRegistry.Init() must only run on the server")
	local folder = getFolder()
	for _, path in ipairs(RemoteDefinitions) do
		if not folder:FindFirstChild(path) then
			local remote = Instance.new("RemoteEvent")
			remote.Name = path
			remote.Parent = folder
		end
	end
end

function RemoteRegistry.Get(path)
	local cached = cache[path]
	if cached then
		return cached
	end
	local folder = getFolder()
	local remote = folder:FindFirstChild(path) or folder:WaitForChild(path, 10)
	if not remote then
		warn("[RemoteRegistry] Remote not found after waiting:", path)
	end
	cache[path] = remote
	return remote
end

return RemoteRegistry
