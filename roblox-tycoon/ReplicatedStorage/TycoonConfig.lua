--[[
	TycoonConfig — настройки тайкуна
	Помести этот ModuleScript в ReplicatedStorage
]]

local TycoonConfig = {}

-- Максимальное количество плотов (тайкунов) на сервере
TycoonConfig.MaxPlots = 6

-- Стартовые деньги игрока
TycoonConfig.StartingCash = 100

-- Интервал дроппера (секунды)
TycoonConfig.DropperInterval = 2

-- Время жизни дропа (секунды) перед удалением
TycoonConfig.DropLifetime = 30

-- Скорость конвейера
TycoonConfig.ConveyorSpeed = 10

-- Названия RemoteEvent-ов
TycoonConfig.Remotes = {
	ClaimPlot = "TycoonClaimPlot",
	PurchaseButton = "TycoonPurchaseButton",
	UpdateCash = "TycoonUpdateCash",
	TycoonClaimed = "TycoonClaimed",
	ButtonPurchased = "TycoonButtonPurchased",
}

-- Определения кнопок покупок
-- Каждая кнопка разблокирует определённый объект на плоте
TycoonConfig.Buttons = {
	{
		Name = "BasicDropper",
		DisplayName = "Базовый дроппер",
		Price = 0, -- бесплатный стартовый
		Description = "Производит базовые блоки стоимостью $5",
		DropValue = 5,
		Order = 1,
	},
	{
		Name = "Conveyor",
		DisplayName = "Конвейер",
		Price = 200,
		Description = "Перемещает блоки к коллектору",
		Order = 2,
	},
	{
		Name = "Collector",
		DisplayName = "Коллектор",
		Price = 300,
		Description = "Собирает блоки и начисляет деньги",
		Order = 3,
	},
	{
		Name = "AdvancedDropper",
		DisplayName = "Продвинутый дроппер",
		Price = 1000,
		Description = "Производит блоки стоимостью $25",
		DropValue = 25,
		Order = 4,
	},
	{
		Name = "AutoCollector",
		DisplayName = "Авто-коллектор",
		Price = 2500,
		Description = "Автоматически собирает деньги",
		Order = 5,
	},
	{
		Name = "GoldenDropper",
		DisplayName = "Золотой дроппер",
		Price = 5000,
		Description = "Производит золотые блоки стоимостью $100",
		DropValue = 100,
		Order = 6,
	},
	{
		Name = "DiamondDropper",
		DisplayName = "Алмазный дроппер",
		Price = 15000,
		Description = "Производит алмазные блоки стоимостью $500",
		DropValue = 500,
		Order = 7,
	},
	{
		Name = "Upgrader",
		DisplayName = "Улучшатель",
		Price = 25000,
		Description = "Удваивает стоимость проходящих блоков",
		Multiplier = 2,
		Order = 8,
	},
	{
		Name = "MegaDropper",
		DisplayName = "Мега-дроппер",
		Price = 75000,
		Description = "Производит мега-блоки стоимостью $2500",
		DropValue = 2500,
		Order = 9,
	},
	{
		Name = "SuperUpgrader",
		DisplayName = "Супер-улучшатель",
		Price = 150000,
		Description = "Утраивает стоимость проходящих блоков",
		Multiplier = 3,
		Order = 10,
	},
}

-- Цвета блоков по типу дроппера
TycoonConfig.DropColors = {
	BasicDropper = Color3.fromRGB(100, 100, 100),
	AdvancedDropper = Color3.fromRGB(0, 150, 255),
	GoldenDropper = Color3.fromRGB(255, 215, 0),
	DiamondDropper = Color3.fromRGB(185, 242, 255),
	MegaDropper = Color3.fromRGB(255, 0, 100),
}

-- Размеры блоков
TycoonConfig.DropSize = Vector3.new(1.5, 1.5, 1.5)

return TycoonConfig
