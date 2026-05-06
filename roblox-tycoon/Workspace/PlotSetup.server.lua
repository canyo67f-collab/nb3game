--[[
	PlotSetup — автоматическая генерация плотов тайкуна
	Помести этот Script в ServerScriptService (или запусти один раз в Command Bar)

	Создаёт базовую структуру плотов в Workspace если её нет.
	После первого запуска можно удалить этот скрипт.

	СТРУКТУРА ПЛОТА:
	TycoonPlots (Folder)
	├── Plot1 (Model)
	│   ├── ClaimPad (Part) — платформа для захвата
	│   ├── Base (Part) — основание плота
	│   ├── OwnerLabel (SurfaceGui) — табличка с именем
	│   ├── Buttons (Folder) — кнопки покупок
	│   │   ├── BasicDropperButton (Part)
	│   │   ├── ConveyorButton (Part)
	│   │   ├── CollectorButton (Part)
	│   │   └── ...
	│   ├── BasicDropper (Model) — разблокируемый дроппер
	│   │   └── SpawnPoint (Part)
	│   ├── Conveyor (Model)
	│   │   └── ConveyorPart (Part)
	│   ├── Collector (Model)
	│   │   └── CollectorPart (Part)
	│   └── ...
	└── Plot2 (Model)
	    └── ...
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Попробуем загрузить конфиг, если доступен
local TycoonConfig
pcall(function()
	TycoonConfig = require(ReplicatedStorage:WaitForChild("TycoonConfig", 5))
end)

local PLOT_COUNT = TycoonConfig and TycoonConfig.MaxPlots or 6
local PLOT_SPACING = 80 -- расстояние между плотами
local BASE_SIZE = Vector3.new(60, 1, 60) -- размер основания

-------------------------------------------------------
-- СОЗДАНИЕ ОДНОГО ПЛОТА
-------------------------------------------------------
local function createPlot(index: number, position: Vector3): Model
	local plotModel = Instance.new("Model")
	plotModel.Name = "Plot" .. index

	-- ══════ ОСНОВАНИЕ ══════
	local base = Instance.new("Part")
	base.Name = "Base"
	base.Size = BASE_SIZE
	base.Position = position
	base.Anchored = true
	base.CanCollide = true
	base.Material = Enum.Material.Concrete
	base.Color = Color3.fromRGB(80, 80, 90)
	base.Parent = plotModel

	plotModel.PrimaryPart = base

	-- ══════ CLAIM PAD (платформа захвата) ══════
	local claimPad = Instance.new("Part")
	claimPad.Name = "ClaimPad"
	claimPad.Size = Vector3.new(8, 0.5, 8)
	claimPad.Position = position + Vector3.new(0, 0.75, -20)
	claimPad.Anchored = true
	claimPad.CanCollide = true
	claimPad.Material = Enum.Material.SmoothPlastic
	claimPad.Color = Color3.fromRGB(50, 200, 50)
	claimPad.Parent = plotModel

	-- ══════ ТАБЛИЧКА ВЛАДЕЛЬЦА ══════
	local signPart = Instance.new("Part")
	signPart.Name = "SignPart"
	signPart.Size = Vector3.new(10, 5, 0.5)
	signPart.Position = position + Vector3.new(0, 4, -25)
	signPart.Anchored = true
	signPart.CanCollide = false
	signPart.Material = Enum.Material.SmoothPlastic
	signPart.Color = Color3.fromRGB(30, 30, 50)
	signPart.Parent = plotModel

	local ownerGui = Instance.new("SurfaceGui")
	ownerGui.Name = "OwnerLabel"
	ownerGui.Face = Enum.NormalId.Front
	ownerGui.Parent = signPart

	local ownerText = Instance.new("TextLabel")
	ownerText.Size = UDim2.new(1, 0, 1, 0)
	ownerText.BackgroundTransparency = 1
	ownerText.Text = "Свободно"
	ownerText.TextColor3 = Color3.fromRGB(255, 215, 0)
	ownerText.TextScaled = true
	ownerText.Font = Enum.Font.GothamBold
	ownerText.Parent = ownerGui

	-- ══════ ПАПКА КНОПОК ══════
	local buttonsFolder = Instance.new("Folder")
	buttonsFolder.Name = "Buttons"
	buttonsFolder.Parent = plotModel

	-- Позиции кнопок (вдоль левой стороны плота)
	local buttonPositions = {}
	local buttons = TycoonConfig and TycoonConfig.Buttons or {}

	for i, btnConfig in ipairs(buttons) do
		local btnPos = position + Vector3.new(-25, 1.5, -15 + (i - 1) * 6)

		local btnPart = Instance.new("Part")
		btnPart.Name = btnConfig.Name .. "Button"
		btnPart.Size = Vector3.new(5, 2, 4)
		btnPart.Position = btnPos
		btnPart.Anchored = true
		btnPart.CanCollide = true
		btnPart.Material = Enum.Material.SmoothPlastic

		-- Цвет по цене
		if btnConfig.Price == 0 then
			btnPart.Color = Color3.fromRGB(0, 200, 0)
		elseif btnConfig.Price < 1000 then
			btnPart.Color = Color3.fromRGB(50, 150, 255)
		elseif btnConfig.Price < 10000 then
			btnPart.Color = Color3.fromRGB(200, 150, 0)
		else
			btnPart.Color = Color3.fromRGB(200, 50, 200)
		end

		-- GUI на кнопке
		local btnGui = Instance.new("SurfaceGui")
		btnGui.Face = Enum.NormalId.Front
		btnGui.Parent = btnPart

		local btnLabel = Instance.new("TextLabel")
		btnLabel.Size = UDim2.new(1, 0, 0.5, 0)
		btnLabel.BackgroundTransparency = 1
		btnLabel.Text = btnConfig.DisplayName
		btnLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		btnLabel.TextScaled = true
		btnLabel.Font = Enum.Font.GothamBold
		btnLabel.Parent = btnGui

		local priceLabel = Instance.new("TextLabel")
		priceLabel.Size = UDim2.new(1, 0, 0.5, 0)
		priceLabel.Position = UDim2.new(0, 0, 0.5, 0)
		priceLabel.BackgroundTransparency = 1
		priceLabel.Text = "$" .. tostring(btnConfig.Price)
		priceLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
		priceLabel.TextScaled = true
		priceLabel.Font = Enum.Font.GothamBold
		priceLabel.Parent = btnGui

		-- ClickDetector
		local clickDetector = Instance.new("ClickDetector")
		clickDetector.MaxActivationDistance = 10
		clickDetector.Parent = btnPart

		btnPart.Parent = buttonsFolder
	end

	-- ══════ РАЗБЛОКИРУЕМЫЕ ОБЪЕКТЫ ══════

	-- BasicDropper
	local basicDropper = Instance.new("Model")
	basicDropper.Name = "BasicDropper"
	basicDropper.Parent = plotModel

	local dropperBase = Instance.new("Part")
	dropperBase.Name = "DropperBase"
	dropperBase.Size = Vector3.new(6, 4, 6)
	dropperBase.Position = position + Vector3.new(10, 2.5, -10)
	dropperBase.Anchored = true
	dropperBase.Material = Enum.Material.DiamondPlate
	dropperBase.Color = Color3.fromRGB(100, 100, 100)
	dropperBase.Transparency = 1
	dropperBase.CanCollide = false
	dropperBase.Parent = basicDropper

	local spawnPoint = Instance.new("Part")
	spawnPoint.Name = "SpawnPoint"
	spawnPoint.Size = Vector3.new(2, 1, 2)
	spawnPoint.Position = position + Vector3.new(10, 5, -10)
	spawnPoint.Anchored = true
	spawnPoint.Transparency = 1
	spawnPoint.CanCollide = false
	spawnPoint.Parent = basicDropper

	-- Conveyor
	local conveyor = Instance.new("Model")
	conveyor.Name = "Conveyor"
	conveyor.Parent = plotModel

	local conveyorPart = Instance.new("Part")
	conveyorPart.Name = "ConveyorPart"
	conveyorPart.Size = Vector3.new(4, 0.5, 20)
	conveyorPart.Position = position + Vector3.new(10, 0.75, 5)
	conveyorPart.Anchored = true
	conveyorPart.Material = Enum.Material.DiamondPlate
	conveyorPart.Color = Color3.fromRGB(50, 50, 60)
	conveyorPart.Transparency = 1
	conveyorPart.CanCollide = false
	conveyorPart.Parent = conveyor

	-- Collector
	local collector = Instance.new("Model")
	collector.Name = "Collector"
	collector.Parent = plotModel

	local collectorPart = Instance.new("Part")
	collectorPart.Name = "CollectorPart"
	collectorPart.Size = Vector3.new(8, 4, 4)
	collectorPart.Position = position + Vector3.new(10, 2.5, 18)
	collectorPart.Anchored = true
	collectorPart.Material = Enum.Material.Neon
	collectorPart.Color = Color3.fromRGB(0, 200, 255)
	collectorPart.Transparency = 1
	collectorPart.CanCollide = false
	collectorPart.Parent = collector

	-- AdvancedDropper
	local advDropper = Instance.new("Model")
	advDropper.Name = "AdvancedDropper"
	advDropper.Parent = plotModel

	local advBase = Instance.new("Part")
	advBase.Name = "DropperBase"
	advBase.Size = Vector3.new(6, 5, 6)
	advBase.Position = position + Vector3.new(18, 3, -10)
	advBase.Anchored = true
	advBase.Material = Enum.Material.DiamondPlate
	advBase.Color = Color3.fromRGB(0, 150, 255)
	advBase.Transparency = 1
	advBase.CanCollide = false
	advBase.Parent = advDropper

	local advSpawn = Instance.new("Part")
	advSpawn.Name = "SpawnPoint"
	advSpawn.Size = Vector3.new(2, 1, 2)
	advSpawn.Position = position + Vector3.new(18, 6, -10)
	advSpawn.Anchored = true
	advSpawn.Transparency = 1
	advSpawn.CanCollide = false
	advSpawn.Parent = advDropper

	-- AutoCollector
	local autoCollector = Instance.new("Model")
	autoCollector.Name = "AutoCollector"
	autoCollector.Parent = plotModel

	local autoCollPart = Instance.new("Part")
	autoCollPart.Name = "CollectorPart"
	autoCollPart.Size = Vector3.new(10, 5, 6)
	autoCollPart.Position = position + Vector3.new(10, 3, 24)
	autoCollPart.Anchored = true
	autoCollPart.Material = Enum.Material.Neon
	autoCollPart.Color = Color3.fromRGB(255, 100, 255)
	autoCollPart.Transparency = 1
	autoCollPart.CanCollide = false
	autoCollPart.Parent = autoCollector

	-- GoldenDropper
	local goldDropper = Instance.new("Model")
	goldDropper.Name = "GoldenDropper"
	goldDropper.Parent = plotModel

	local goldBase = Instance.new("Part")
	goldBase.Name = "DropperBase"
	goldBase.Size = Vector3.new(7, 6, 7)
	goldBase.Position = position + Vector3.new(-5, 3.5, -10)
	goldBase.Anchored = true
	goldBase.Material = Enum.Material.DiamondPlate
	goldBase.Color = Color3.fromRGB(255, 215, 0)
	goldBase.Transparency = 1
	goldBase.CanCollide = false
	goldBase.Parent = goldDropper

	local goldSpawn = Instance.new("Part")
	goldSpawn.Name = "SpawnPoint"
	goldSpawn.Size = Vector3.new(2, 1, 2)
	goldSpawn.Position = position + Vector3.new(-5, 7, -10)
	goldSpawn.Anchored = true
	goldSpawn.Transparency = 1
	goldSpawn.CanCollide = false
	goldSpawn.Parent = goldDropper

	-- DiamondDropper
	local diamondDropper = Instance.new("Model")
	diamondDropper.Name = "DiamondDropper"
	diamondDropper.Parent = plotModel

	local diamondBase = Instance.new("Part")
	diamondBase.Name = "DropperBase"
	diamondBase.Size = Vector3.new(8, 7, 8)
	diamondBase.Position = position + Vector3.new(-15, 4, -10)
	diamondBase.Anchored = true
	diamondBase.Material = Enum.Material.Glass
	diamondBase.Color = Color3.fromRGB(185, 242, 255)
	diamondBase.Transparency = 1
	diamondBase.CanCollide = false
	diamondBase.Parent = diamondDropper

	local diamondSpawn = Instance.new("Part")
	diamondSpawn.Name = "SpawnPoint"
	diamondSpawn.Size = Vector3.new(2, 1, 2)
	diamondSpawn.Position = position + Vector3.new(-15, 8, -10)
	diamondSpawn.Anchored = true
	diamondSpawn.Transparency = 1
	diamondSpawn.CanCollide = false
	diamondSpawn.Parent = diamondDropper

	-- Upgrader
	local upgrader = Instance.new("Model")
	upgrader.Name = "Upgrader"
	upgrader.Parent = plotModel

	local upgraderPart = Instance.new("Part")
	upgraderPart.Name = "UpgraderPart"
	upgraderPart.Size = Vector3.new(6, 3, 4)
	upgraderPart.Position = position + Vector3.new(10, 2, 10)
	upgraderPart.Anchored = true
	upgraderPart.Material = Enum.Material.Neon
	upgraderPart.Color = Color3.fromRGB(255, 255, 0)
	upgraderPart.Transparency = 1
	upgraderPart.CanCollide = false
	upgraderPart.Parent = upgrader

	-- MegaDropper
	local megaDropper = Instance.new("Model")
	megaDropper.Name = "MegaDropper"
	megaDropper.Parent = plotModel

	local megaBase = Instance.new("Part")
	megaBase.Name = "DropperBase"
	megaBase.Size = Vector3.new(10, 8, 10)
	megaBase.Position = position + Vector3.new(0, 4.5, 10)
	megaBase.Anchored = true
	megaBase.Material = Enum.Material.DiamondPlate
	megaBase.Color = Color3.fromRGB(255, 0, 100)
	megaBase.Transparency = 1
	megaBase.CanCollide = false
	megaBase.Parent = megaDropper

	local megaSpawn = Instance.new("Part")
	megaSpawn.Name = "SpawnPoint"
	megaSpawn.Size = Vector3.new(3, 1, 3)
	megaSpawn.Position = position + Vector3.new(0, 9, 10)
	megaSpawn.Anchored = true
	megaSpawn.Transparency = 1
	megaSpawn.CanCollide = false
	megaSpawn.Parent = megaDropper

	-- SuperUpgrader
	local superUpgrader = Instance.new("Model")
	superUpgrader.Name = "SuperUpgrader"
	superUpgrader.Parent = plotModel

	local superUpgraderPart = Instance.new("Part")
	superUpgraderPart.Name = "UpgraderPart"
	superUpgraderPart.Size = Vector3.new(8, 4, 6)
	superUpgraderPart.Position = position + Vector3.new(10, 2.5, 14)
	superUpgraderPart.Anchored = true
	superUpgraderPart.Material = Enum.Material.Neon
	superUpgraderPart.Color = Color3.fromRGB(255, 50, 255)
	superUpgraderPart.Transparency = 1
	superUpgraderPart.CanCollide = false
	superUpgraderPart.Parent = superUpgrader

	return plotModel
end

-------------------------------------------------------
-- ГЕНЕРАЦИЯ ВСЕХ ПЛОТОВ
-------------------------------------------------------
local function generatePlots()
	-- Проверяем, есть ли уже плоты
	if workspace:FindFirstChild("TycoonPlots") then
		print("[PlotSetup] Плоты уже существуют! Пропускаем генерацию.")
		return
	end

	local plotsFolder = Instance.new("Folder")
	plotsFolder.Name = "TycoonPlots"
	plotsFolder.Parent = workspace

	for i = 1, PLOT_COUNT do
		-- Располагаем плоты в ряд
		local row = math.ceil(i / 3) - 1
		local col = ((i - 1) % 3)
		local position = Vector3.new(
			col * PLOT_SPACING,
			0,
			row * PLOT_SPACING
		)

		local plotModel = createPlot(i, position)
		plotModel.Parent = plotsFolder

		print("[PlotSetup] Создан плот #" .. i)
	end

	print("[PlotSetup] Все плоты созданы! (" .. PLOT_COUNT .. " шт.)")
end

generatePlots()
