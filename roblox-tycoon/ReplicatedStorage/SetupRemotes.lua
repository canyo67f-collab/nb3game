--[[
	SetupRemotes — создаёт RemoteEvent-ы для тайкуна
	Этот скрипт вызывается сервером при инициализации.
	Помести этот ModuleScript в ReplicatedStorage
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TycoonConfig = require(ReplicatedStorage:WaitForChild("TycoonConfig"))

local SetupRemotes = {}

function SetupRemotes.Init()
	-- Создаём папку для Remote-ов
	local remotesFolder = Instance.new("Folder")
	remotesFolder.Name = "TycoonRemotes"
	remotesFolder.Parent = ReplicatedStorage

	-- Создаём RemoteEvent для каждого события
	for _, remoteName in pairs(TycoonConfig.Remotes) do
		local remote = Instance.new("RemoteEvent")
		remote.Name = remoteName
		remote.Parent = remotesFolder
	end

	return remotesFolder
end

function SetupRemotes.GetRemote(name: string): RemoteEvent
	local remotesFolder = ReplicatedStorage:WaitForChild("TycoonRemotes")
	return remotesFolder:WaitForChild(name)
end

return SetupRemotes
