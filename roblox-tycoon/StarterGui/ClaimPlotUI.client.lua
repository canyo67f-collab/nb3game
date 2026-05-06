--[[
	ClaimPlotUI — UI для захвата плота (BillboardGui)
	Помести этот LocalScript в StarterGui

	Показывает подсказку "Встань сюда, чтобы занять плот"
	над свободными ClaimPad-ами
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local TycoonConfig = require(ReplicatedStorage:WaitForChild("TycoonConfig"))

local remotesFolder = ReplicatedStorage:WaitForChild("TycoonRemotes")
local claimedRemote = remotesFolder:WaitForChild(TycoonConfig.Remotes.TycoonClaimed)

-------------------------------------------------------
-- СОЗДАНИЕ BILLBOARD GUI НАД КАЖДЫМ CLAIMPAD
-------------------------------------------------------
local billboards = {}

local function createClaimBillboard(claimPad: BasePart, plotIndex: number)
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "ClaimBillboard"
	billboard.Size = UDim2.new(0, 250, 0, 80)
	billboard.StudsOffset = Vector3.new(0, 5, 0)
	billboard.AlwaysOnTop = true
	billboard.Adornee = claimPad
	billboard.Parent = claimPad

	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(1, 0, 1, 0)
	frame.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
	frame.BackgroundTransparency = 0.2
	frame.BorderSizePixel = 0
	frame.Parent = billboard

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = frame

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(100, 255, 100)
	stroke.Thickness = 2
	stroke.Parent = frame

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(1, 0, 0.5, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = "ПЛОТ #" .. plotIndex
	titleLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
	titleLabel.TextSize = 20
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.Parent = frame

	local hintLabel = Instance.new("TextLabel")
	hintLabel.Size = UDim2.new(1, 0, 0.5, 0)
	hintLabel.Position = UDim2.new(0, 0, 0.5, 0)
	hintLabel.BackgroundTransparency = 1
	hintLabel.Text = "Встань сюда!"
	hintLabel.TextColor3 = Color3.fromRGB(200, 200, 220)
	hintLabel.TextSize = 14
	hintLabel.Font = Enum.Font.Gotham
	hintLabel.Parent = frame

	-- Пульсирующая анимация
	task.spawn(function()
		while billboard.Parent do
			local tweenUp = TweenService:Create(billboard, TweenInfo.new(1, Enum.EasingStyle.Sine), {
				StudsOffset = Vector3.new(0, 5.5, 0)
			})
			tweenUp:Play()
			tweenUp.Completed:Wait()

			local tweenDown = TweenService:Create(billboard, TweenInfo.new(1, Enum.EasingStyle.Sine), {
				StudsOffset = Vector3.new(0, 4.5, 0)
			})
			tweenDown:Play()
			tweenDown.Completed:Wait()
		end
	end)

	billboards[plotIndex] = billboard
	return billboard
end

-------------------------------------------------------
-- ИНИЦИАЛИЗАЦИЯ
-------------------------------------------------------
local function init()
	local plotsFolder = workspace:FindFirstChild("TycoonPlots")
	if not plotsFolder then return end

	for i, plotModel in ipairs(plotsFolder:GetChildren()) do
		local claimPad = plotModel:FindFirstChild("ClaimPad")
		if claimPad then
			createClaimBillboard(claimPad, i)
		end
	end
end

-------------------------------------------------------
-- КОГДА ПЛОТ ЗАХВАЧЕН — УБИРАЕМ BILLBOARD
-------------------------------------------------------
claimedRemote.OnClientEvent:Connect(function(claimer, plotIndex)
	if billboards[plotIndex] then
		billboards[plotIndex]:Destroy()
		billboards[plotIndex] = nil
	end
end)

-------------------------------------------------------
-- ПОДСВЕТКА CLAIMPAD КОГДА ИГРОК РЯДОМ
-------------------------------------------------------
RunService.Heartbeat:Connect(function()
	local character = player.Character
	if not character then return end
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then return end

	local plotsFolder = workspace:FindFirstChild("TycoonPlots")
	if not plotsFolder then return end

	for i, plotModel in ipairs(plotsFolder:GetChildren()) do
		local claimPad = plotModel:FindFirstChild("ClaimPad")
		if claimPad and billboards[i] then
			local distance = (rootPart.Position - claimPad.Position).Magnitude
			if distance < 15 then
				-- Подсвечиваем
				claimPad.Color = Color3.fromRGB(0, 255, 100)
				claimPad.Material = Enum.Material.Neon
			else
				claimPad.Color = Color3.fromRGB(50, 200, 50)
				claimPad.Material = Enum.Material.SmoothPlastic
			end
		end
	end
end)

init()
print("[ClaimPlotUI] Загружен!")
