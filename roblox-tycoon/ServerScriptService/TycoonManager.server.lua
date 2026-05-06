--[[
	TycoonManager — главный серверный скрипт тайкуна
	Помести этот Script в ServerScriptService

	Управляет:
	- Назначение плотов игрокам
	- Покупка кнопок / разблокировка объектов
	- Система дропперов и коллекторов
	- Лидерстатс (деньги)
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local RunService = game:GetService("RunService")

local TycoonConfig = require(ReplicatedStorage:WaitForChild("TycoonConfig"))
local SetupRemotes = require(ReplicatedStorage:WaitForChild("SetupRemotes"))
local DataStoreManager = require(script.Parent:WaitForChild("DataStoreManager"))

-- Инициализация Remote-ов
SetupRemotes.Init()

local remotesFolder = ReplicatedStorage:WaitForChild("TycoonRemotes")
local claimRemote = remotesFolder:WaitForChild(TycoonConfig.Remotes.ClaimPlot)
local purchaseRemote = remotesFolder:WaitForChild(TycoonConfig.Remotes.PurchaseButton)
local updateCashRemote = remotesFolder:WaitForChild(TycoonConfig.Remotes.UpdateCash)
local claimedRemote = remotesFolder:WaitForChild(TycoonConfig.Remotes.TycoonClaimed)
local buttonPurchasedRemote = remotesFolder:WaitForChild(TycoonConfig.Remotes.ButtonPurchased)

-------------------------------------------------------
-- ДАННЫЕ ИГРОКОВ
-------------------------------------------------------
local playerData = {} -- [Player] = { Cash, OwnedButtons, PlotIndex }
local plots = {}      -- [plotIndex] = { Model, Owner, Droppers, Collector }

-------------------------------------------------------
-- ИНИЦИАЛИЗАЦИЯ ПЛОТОВ
-------------------------------------------------------
local function initializePlots()
	local plotsFolder = workspace:FindFirstChild("TycoonPlots")
	if not plotsFolder then
		warn("[Tycoon] Папка 'TycoonPlots' не найдена в Workspace! Создай её по инструкции в README.")
		return
	end

	for i, plotModel in ipairs(plotsFolder:GetChildren()) do
		plots[i] = {
			Model = plotModel,
			Owner = nil,
			ActiveDroppers = {},
			ActiveDrops = {},
		}
	end

	print("[Tycoon] Инициализировано плотов: " .. #plots)
end

-------------------------------------------------------
-- ЛИДЕРСТАТС
-------------------------------------------------------
local function setupLeaderstats(player: Player)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local cash = Instance.new("IntValue")
	cash.Name = "Cash"
	cash.Value = TycoonConfig.StartingCash
	cash.Parent = leaderstats

	return cash
end

-------------------------------------------------------
-- ПОЛУЧИТЬ ДЕНЬГИ ИГРОКА
-------------------------------------------------------
local function getCash(player: Player): number
	if playerData[player] then
		return playerData[player].Cash
	end
	return 0
end

local function setCash(player: Player, amount: number)
	if not playerData[player] then return end
	playerData[player].Cash = amount

	-- Обновляем leaderstats
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local cashValue = leaderstats:FindFirstChild("Cash")
		if cashValue then
			cashValue.Value = amount
		end
	end

	-- Отправляем клиенту
	updateCashRemote:FireClient(player, amount)
end

local function addCash(player: Player, amount: number)
	setCash(player, getCash(player) + amount)
end

-------------------------------------------------------
-- СИСТЕМА ДРОППЕРОВ
-------------------------------------------------------
local function createDrop(plot, dropperConfig, spawnPosition: Vector3)
	local drop = Instance.new("Part")
	drop.Name = "TycoonDrop"
	drop.Size = TycoonConfig.DropSize
	drop.Position = spawnPosition + Vector3.new(0, 2, 0)
	drop.Anchored = false
	drop.CanCollide = true
	drop.Material = Enum.Material.SmoothPlastic

	-- Цвет по типу дроппера
	local color = TycoonConfig.DropColors[dropperConfig.Name]
	if color then
		drop.Color = color
	end

	-- Сохраняем стоимость блока
	local valueTag = Instance.new("IntValue")
	valueTag.Name = "DropValue"
	valueTag.Value = dropperConfig.DropValue or 5
	valueTag.Parent = drop

	drop.Parent = workspace

	-- Авто-удаление через время
	task.delay(TycoonConfig.DropLifetime, function()
		if drop and drop.Parent then
			drop:Destroy()
		end
	end)

	table.insert(plot.ActiveDrops, drop)
	return drop
end

local function startDropper(plot, dropperConfig, dropperPart)
	local dropperLoop = task.spawn(function()
		while plot.Owner and dropperPart and dropperPart.Parent do
			createDrop(plot, dropperConfig, dropperPart.Position)
			task.wait(TycoonConfig.DropperInterval)
		end
	end)
	table.insert(plot.ActiveDroppers, dropperLoop)
end

-------------------------------------------------------
-- СИСТЕМА КОЛЛЕКТОРА
-------------------------------------------------------
local function setupCollector(plot, collectorPart)
	if not collectorPart then return end

	collectorPart.Touched:Connect(function(hit)
		if hit.Name == "TycoonDrop" and plot.Owner then
			local valueTag = hit:FindFirstChild("DropValue")
			if valueTag then
				addCash(plot.Owner, valueTag.Value)
			end
			hit:Destroy()
		end
	end)
end

-------------------------------------------------------
-- СИСТЕМА КОНВЕЙЕРА
-------------------------------------------------------
local function setupConveyor(conveyorPart)
	if not conveyorPart then return end

	-- Создаём BodyVelocity на конвейере
	RunService.Heartbeat:Connect(function()
		-- Конвейер перемещает блоки через изменение Velocity
		for _, obj in ipairs(workspace:GetChildren()) do
			if obj.Name == "TycoonDrop" and obj:IsA("BasePart") then
				local distance = (obj.Position - conveyorPart.Position).Magnitude
				if distance < conveyorPart.Size.X / 2 + 2 then
					-- Двигаем блок в направлении конвейера
					local direction = conveyorPart.CFrame.LookVector
					obj.AssemblyLinearVelocity = direction * TycoonConfig.ConveyorSpeed
				end
			end
		end
	end)
end

-------------------------------------------------------
-- СИСТЕМА УЛУЧШАТЕЛЯ
-------------------------------------------------------
local function setupUpgrader(plot, upgraderPart, multiplier: number)
	if not upgraderPart then return end

	local upgradedDrops = {} -- Чтобы не улучшать один блок дважды

	upgraderPart.Touched:Connect(function(hit)
		if hit.Name == "TycoonDrop" and not upgradedDrops[hit] then
			local valueTag = hit:FindFirstChild("DropValue")
			if valueTag then
				valueTag.Value = valueTag.Value * multiplier
				upgradedDrops[hit] = true

				-- Визуальный эффект
				hit.BrickColor = BrickColor.new("Bright yellow")
				hit.Material = Enum.Material.Neon

				-- Очистка ссылки при удалении блока
				hit.Destroying:Connect(function()
					upgradedDrops[hit] = nil
				end)
			end
		end
	end)
end

-------------------------------------------------------
-- ПОКУПКА КНОПКИ / РАЗБЛОКИРОВКА
-------------------------------------------------------
local function purchaseButton(player: Player, buttonName: string)
	local data = playerData[player]
	if not data then return end

	-- Найти конфиг кнопки
	local buttonConfig = nil
	for _, btn in ipairs(TycoonConfig.Buttons) do
		if btn.Name == buttonName then
			buttonConfig = btn
			break
		end
	end

	if not buttonConfig then
		warn("[Tycoon] Кнопка не найдена: " .. buttonName)
		return
	end

	-- Проверяем, не куплена ли уже
	if data.OwnedButtons[buttonName] then
		return
	end

	-- Проверяем деньги
	if data.Cash < buttonConfig.Price then
		return
	end

	-- Списываем деньги
	setCash(player, data.Cash - buttonConfig.Price)

	-- Помечаем как купленную
	data.OwnedButtons[buttonName] = true

	-- Активируем объект на плоте
	local plot = plots[data.PlotIndex]
	if plot and plot.Model then
		local unlockable = plot.Model:FindFirstChild(buttonName)
		if unlockable then
			-- Делаем объект видимым
			for _, part in ipairs(unlockable:GetDescendants()) do
				if part:IsA("BasePart") then
					part.Transparency = 0
					part.CanCollide = true
				end
			end

			-- Активируем функционал
			if buttonConfig.DropValue then
				-- Это дроппер
				local spawnPart = unlockable:FindFirstChild("SpawnPoint")
				if spawnPart then
					startDropper(plot, buttonConfig, spawnPart)
				end
			end

			if buttonConfig.Name == "Collector" or buttonConfig.Name == "AutoCollector" then
				local collectorPart = unlockable:FindFirstChild("CollectorPart")
				if collectorPart then
					setupCollector(plot, collectorPart)
				end
			end

			if buttonConfig.Name == "Conveyor" then
				local conveyorPart = unlockable:FindFirstChild("ConveyorPart")
				if conveyorPart then
					setupConveyor(conveyorPart)
				end
			end

			if buttonConfig.Multiplier then
				local upgraderPart = unlockable:FindFirstChild("UpgraderPart")
				if upgraderPart then
					setupUpgrader(plot, upgraderPart, buttonConfig.Multiplier)
				end
			end
		end

		-- Убираем кнопку покупки
		local buttonModel = plot.Model:FindFirstChild("Buttons")
		if buttonModel then
			local btn = buttonModel:FindFirstChild(buttonName .. "Button")
			if btn then
				btn:Destroy()
			end
		end
	end

	-- Уведомляем всех клиентов
	buttonPurchasedRemote:FireAllClients(player, buttonName, data.PlotIndex)

	-- Сохраняем прогресс
	DataStoreManager.SavePlayerData(player, data)

	print("[Tycoon] " .. player.Name .. " купил: " .. buttonConfig.DisplayName)
end

-------------------------------------------------------
-- ЗАХВАТ ПЛОТА
-------------------------------------------------------
local function claimPlot(player: Player, plotIndex: number)
	-- Проверяем валидность
	if not plots[plotIndex] then return end
	if plots[plotIndex].Owner then return end

	-- Проверяем, нет ли у игрока уже плота
	if playerData[player] and playerData[player].PlotIndex then return end

	-- Назначаем плот
	plots[plotIndex].Owner = player

	-- Загружаем сохранённые данные
	local savedData = DataStoreManager.LoadPlayerData(player)

	playerData[player] = {
		Cash = savedData and savedData.Cash or TycoonConfig.StartingCash,
		OwnedButtons = savedData and savedData.OwnedButtons or {},
		PlotIndex = plotIndex,
	}

	-- Устанавливаем деньги
	setCash(player, playerData[player].Cash)

	-- Устанавливаем владельца на плоте (визуально)
	local plot = plots[plotIndex]
	if plot.Model then
		local ownerLabel = plot.Model:FindFirstChild("OwnerLabel")
		if ownerLabel and ownerLabel:IsA("SurfaceGui") then
			local textLabel = ownerLabel:FindFirstChildWhichIsA("TextLabel")
			if textLabel then
				textLabel.Text = player.Name .. " - Тайкун"
			end
		end
	end

	-- Восстанавливаем ранее купленные кнопки
	if savedData and savedData.OwnedButtons then
		for buttonName, owned in pairs(savedData.OwnedButtons) do
			if owned then
				-- Активируем без списания денег
				local buttonConfig = nil
				for _, btn in ipairs(TycoonConfig.Buttons) do
					if btn.Name == buttonName then
						buttonConfig = btn
						break
					end
				end

				if buttonConfig and plot.Model then
					local unlockable = plot.Model:FindFirstChild(buttonName)
					if unlockable then
						for _, part in ipairs(unlockable:GetDescendants()) do
							if part:IsA("BasePart") then
								part.Transparency = 0
								part.CanCollide = true
							end
						end

						if buttonConfig.DropValue then
							local spawnPart = unlockable:FindFirstChild("SpawnPoint")
							if spawnPart then
								startDropper(plot, buttonConfig, spawnPart)
							end
						end

						if buttonConfig.Name == "Collector" or buttonConfig.Name == "AutoCollector" then
							local collectorPart = unlockable:FindFirstChild("CollectorPart")
							if collectorPart then
								setupCollector(plot, collectorPart)
							end
						end

						if buttonConfig.Name == "Conveyor" then
							local conveyorPart = unlockable:FindFirstChild("ConveyorPart")
							if conveyorPart then
								setupConveyor(conveyorPart)
							end
						end

						if buttonConfig.Multiplier then
							local upgraderPart = unlockable:FindFirstChild("UpgraderPart")
							if upgraderPart then
								setupUpgrader(plot, upgraderPart, buttonConfig.Multiplier)
							end
						end
					end

					-- Убираем кнопку покупки
					local buttonModel = plot.Model:FindFirstChild("Buttons")
					if buttonModel then
						local btn = buttonModel:FindFirstChild(buttonName .. "Button")
						if btn then
							btn:Destroy()
						end
					end
				end
			end
		end
	end

	-- Уведомляем клиентов
	claimedRemote:FireAllClients(player, plotIndex)

	print("[Tycoon] " .. player.Name .. " занял плот #" .. plotIndex)
end

-------------------------------------------------------
-- ОБРАБОТКА КНОПОК ПОКУПКИ В WORKSPACE
-------------------------------------------------------
local function setupPurchaseButtons()
	local plotsFolder = workspace:FindFirstChild("TycoonPlots")
	if not plotsFolder then return end

	for plotIndex, plot in ipairs(plots) do
		local buttonsFolder = plot.Model:FindFirstChild("Buttons")
		if buttonsFolder then
			for _, buttonPart in ipairs(buttonsFolder:GetChildren()) do
				if buttonPart:IsA("BasePart") or buttonPart:IsA("Model") then
					local clickDetector = buttonPart:FindFirstChildWhichIsA("ClickDetector")
					if not clickDetector then
						clickDetector = Instance.new("ClickDetector")
						clickDetector.MaxActivationDistance = 10

						if buttonPart:IsA("Model") then
							local primaryPart = buttonPart.PrimaryPart or buttonPart:FindFirstChildWhichIsA("BasePart")
							if primaryPart then
								clickDetector.Parent = primaryPart
							end
						else
							clickDetector.Parent = buttonPart
						end
					end

					clickDetector.MouseClick:Connect(function(clicker)
						-- Определяем имя кнопки
						local btnName = buttonPart.Name:gsub("Button$", "")
						if plots[plotIndex].Owner == clicker then
							purchaseButton(clicker, btnName)
						end
					end)
				end
			end
		end
	end
end

-------------------------------------------------------
-- ПЛАТФОРМЫ ЗАХВАТА ПЛОТОВ
-------------------------------------------------------
local function setupClaimPads()
	local plotsFolder = workspace:FindFirstChild("TycoonPlots")
	if not plotsFolder then return end

	for i, plot in ipairs(plots) do
		local claimPad = plot.Model:FindFirstChild("ClaimPad")
		if claimPad and claimPad:IsA("BasePart") then
			claimPad.Touched:Connect(function(hit)
				local player = Players:GetPlayerFromCharacter(hit.Parent)
				if player and not plots[i].Owner then
					claimPlot(player, i)
				end
			end)
		end
	end
end

-------------------------------------------------------
-- ПОДКЛЮЧЕНИЕ СОБЫТИЙ
-------------------------------------------------------
claimRemote.OnServerEvent:Connect(function(player, plotIndex)
	claimPlot(player, plotIndex)
end)

purchaseRemote.OnServerEvent:Connect(function(player, buttonName)
	purchaseButton(player, buttonName)
end)

-------------------------------------------------------
-- ИГРОК ПОДКЛЮЧИЛСЯ
-------------------------------------------------------
Players.PlayerAdded:Connect(function(player)
	setupLeaderstats(player)
end)

-------------------------------------------------------
-- ИГРОК ОТКЛЮЧИЛСЯ
-------------------------------------------------------
Players.PlayerRemoving:Connect(function(player)
	local data = playerData[player]
	if data then
		-- Сохраняем данные
		DataStoreManager.SavePlayerData(player, data)

		-- Освобождаем плот
		if data.PlotIndex and plots[data.PlotIndex] then
			local plot = plots[data.PlotIndex]
			plot.Owner = nil

			-- Останавливаем дропперы
			for _, thread in ipairs(plot.ActiveDroppers) do
				task.cancel(thread)
			end
			plot.ActiveDroppers = {}

			-- Удаляем активные дропы
			for _, drop in ipairs(plot.ActiveDrops) do
				if drop and drop.Parent then
					drop:Destroy()
				end
			end
			plot.ActiveDrops = {}

			-- Сброс владельца на плоте
			local ownerLabel = plot.Model:FindFirstChild("OwnerLabel")
			if ownerLabel and ownerLabel:IsA("SurfaceGui") then
				local textLabel = ownerLabel:FindFirstChildWhichIsA("TextLabel")
				if textLabel then
					textLabel.Text = "Свободно"
				end
			end
		end

		playerData[player] = nil
	end
end)

-------------------------------------------------------
-- АВТОСОХРАНЕНИЕ
-------------------------------------------------------
task.spawn(function()
	while true do
		task.wait(120) -- Каждые 2 минуты
		for player, data in pairs(playerData) do
			if player.Parent then -- Игрок ещё в игре
				DataStoreManager.SavePlayerData(player, data)
			end
		end
		print("[Tycoon] Автосохранение завершено")
	end
end)

-------------------------------------------------------
-- ЗАКРЫТИЕ СЕРВЕРА
-------------------------------------------------------
game:BindToClose(function()
	for player, data in pairs(playerData) do
		DataStoreManager.SavePlayerData(player, data)
	end
end)

-------------------------------------------------------
-- ЗАПУСК
-------------------------------------------------------
initializePlots()
setupClaimPads()
setupPurchaseButtons()

print("[Tycoon] Тайкун система загружена!")
