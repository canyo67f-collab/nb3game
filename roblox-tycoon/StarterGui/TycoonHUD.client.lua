--[[
	TycoonHUD — интерфейс тайкуна (клиентский скрипт)
	Помести этот LocalScript в StarterGui

	Показывает:
	- Текущие деньги
	- Магазин кнопок / апгрейдов
	- Уведомления о покупках
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local TycoonConfig = require(ReplicatedStorage:WaitForChild("TycoonConfig"))

-- Ждём Remote-ы
local remotesFolder = ReplicatedStorage:WaitForChild("TycoonRemotes")
local updateCashRemote = remotesFolder:WaitForChild(TycoonConfig.Remotes.UpdateCash)
local purchaseRemote = remotesFolder:WaitForChild(TycoonConfig.Remotes.PurchaseButton)
local claimedRemote = remotesFolder:WaitForChild(TycoonConfig.Remotes.TycoonClaimed)
local buttonPurchasedRemote = remotesFolder:WaitForChild(TycoonConfig.Remotes.ButtonPurchased)

-------------------------------------------------------
-- СОЗДАНИЕ UI
-------------------------------------------------------
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "TycoonHUD"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = player.PlayerGui

-- ═══════════════════════════════════════════════════
-- ПАНЕЛЬ ДЕНЕГ (верхняя часть экрана)
-- ═══════════════════════════════════════════════════
local cashFrame = Instance.new("Frame")
cashFrame.Name = "CashFrame"
cashFrame.Size = UDim2.new(0, 280, 0, 60)
cashFrame.Position = UDim2.new(0.5, -140, 0, 10)
cashFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
cashFrame.BackgroundTransparency = 0.2
cashFrame.BorderSizePixel = 0
cashFrame.Parent = screenGui

local cashCorner = Instance.new("UICorner")
cashCorner.CornerRadius = UDim.new(0, 12)
cashCorner.Parent = cashFrame

local cashStroke = Instance.new("UIStroke")
cashStroke.Color = Color3.fromRGB(255, 215, 0)
cashStroke.Thickness = 2
cashStroke.Parent = cashFrame

local cashIcon = Instance.new("TextLabel")
cashIcon.Name = "CashIcon"
cashIcon.Size = UDim2.new(0, 40, 1, 0)
cashIcon.Position = UDim2.new(0, 10, 0, 0)
cashIcon.BackgroundTransparency = 1
cashIcon.Text = "$"
cashIcon.TextColor3 = Color3.fromRGB(255, 215, 0)
cashIcon.TextSize = 32
cashIcon.Font = Enum.Font.GothamBold
cashIcon.Parent = cashFrame

local cashLabel = Instance.new("TextLabel")
cashLabel.Name = "CashLabel"
cashLabel.Size = UDim2.new(1, -60, 1, 0)
cashLabel.Position = UDim2.new(0, 50, 0, 0)
cashLabel.BackgroundTransparency = 1
cashLabel.Text = "0"
cashLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
cashLabel.TextSize = 28
cashLabel.Font = Enum.Font.GothamBold
cashLabel.TextXAlignment = Enum.TextXAlignment.Left
cashLabel.Parent = cashFrame

-------------------------------------------------------
-- ФОРМАТИРОВАНИЕ ЧИСЕЛ
-------------------------------------------------------
local function formatCash(amount: number): string
	if amount >= 1_000_000 then
		return string.format("%.1fM", amount / 1_000_000)
	elseif amount >= 1_000 then
		return string.format("%.1fK", amount / 1_000)
	end
	return tostring(amount)
end

-------------------------------------------------------
-- АНИМАЦИЯ ИЗМЕНЕНИЯ ДЕНЕГ
-------------------------------------------------------
local currentDisplayCash = 0

local function animateCashChange(newAmount: number)
	local oldAmount = currentDisplayCash
	currentDisplayCash = newAmount

	-- Вспышка цвета
	if newAmount > oldAmount then
		cashLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
	elseif newAmount < oldAmount then
		cashLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
	end

	-- Плавное возвращение к белому
	local tween = TweenService:Create(cashLabel, TweenInfo.new(0.5), {
		TextColor3 = Color3.fromRGB(255, 255, 255)
	})
	tween:Play()

	-- Плавное изменение числа
	local steps = 10
	local diff = newAmount - oldAmount
	for i = 1, steps do
		local value = math.floor(oldAmount + (diff * i / steps))
		cashLabel.Text = formatCash(value)
		task.wait(0.02)
	end
	cashLabel.Text = formatCash(newAmount)
end

-- ═══════════════════════════════════════════════════
-- КНОПКА МАГАЗИНА
-- ═══════════════════════════════════════════════════
local shopButton = Instance.new("TextButton")
shopButton.Name = "ShopButton"
shopButton.Size = UDim2.new(0, 60, 0, 60)
shopButton.Position = UDim2.new(1, -80, 0.5, -30)
shopButton.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
shopButton.BorderSizePixel = 0
shopButton.Text = "Shop"
shopButton.TextColor3 = Color3.fromRGB(255, 255, 255)
shopButton.TextSize = 14
shopButton.Font = Enum.Font.GothamBold
shopButton.Parent = screenGui

local shopCorner = Instance.new("UICorner")
shopCorner.CornerRadius = UDim.new(0, 30)
shopCorner.Parent = shopButton

local shopStroke = Instance.new("UIStroke")
shopStroke.Color = Color3.fromRGB(100, 255, 100)
shopStroke.Thickness = 2
shopStroke.Parent = shopButton

-- ═══════════════════════════════════════════════════
-- ПАНЕЛЬ МАГАЗИНА
-- ═══════════════════════════════════════════════════
local shopFrame = Instance.new("Frame")
shopFrame.Name = "ShopFrame"
shopFrame.Size = UDim2.new(0, 350, 0, 500)
shopFrame.Position = UDim2.new(0.5, -175, 0.5, -250)
shopFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 40)
shopFrame.BackgroundTransparency = 0.05
shopFrame.BorderSizePixel = 0
shopFrame.Visible = false
shopFrame.Parent = screenGui

local shopFrameCorner = Instance.new("UICorner")
shopFrameCorner.CornerRadius = UDim.new(0, 16)
shopFrameCorner.Parent = shopFrame

local shopFrameStroke = Instance.new("UIStroke")
shopFrameStroke.Color = Color3.fromRGB(100, 200, 255)
shopFrameStroke.Thickness = 2
shopFrameStroke.Parent = shopFrame

-- Заголовок магазина
local shopTitle = Instance.new("TextLabel")
shopTitle.Name = "ShopTitle"
shopTitle.Size = UDim2.new(1, 0, 0, 50)
shopTitle.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
shopTitle.BackgroundTransparency = 0.3
shopTitle.BorderSizePixel = 0
shopTitle.Text = "МАГАЗИН"
shopTitle.TextColor3 = Color3.fromRGB(255, 215, 0)
shopTitle.TextSize = 24
shopTitle.Font = Enum.Font.GothamBold
shopTitle.Parent = shopFrame

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 16)
titleCorner.Parent = shopTitle

-- Кнопка закрытия
local closeButton = Instance.new("TextButton")
closeButton.Name = "CloseButton"
closeButton.Size = UDim2.new(0, 36, 0, 36)
closeButton.Position = UDim2.new(1, -42, 0, 7)
closeButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
closeButton.BorderSizePixel = 0
closeButton.Text = "X"
closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
closeButton.TextSize = 18
closeButton.Font = Enum.Font.GothamBold
closeButton.Parent = shopFrame

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 18)
closeCorner.Parent = closeButton

-- Скролл-фрейм для кнопок
local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Name = "ButtonsList"
scrollFrame.Size = UDim2.new(1, -20, 1, -60)
scrollFrame.Position = UDim2.new(0, 10, 0, 55)
scrollFrame.BackgroundTransparency = 1
scrollFrame.BorderSizePixel = 0
scrollFrame.ScrollBarThickness = 6
scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(100, 200, 255)
scrollFrame.CanvasSize = UDim2.new(0, 0, 0, #TycoonConfig.Buttons * 90)
scrollFrame.Parent = shopFrame

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 8)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Parent = scrollFrame

-------------------------------------------------------
-- СОЗДАНИЕ ЭЛЕМЕНТОВ МАГАЗИНА
-------------------------------------------------------
local purchasedButtons = {}

local function createShopItem(buttonConfig, index: number)
	local itemFrame = Instance.new("Frame")
	itemFrame.Name = buttonConfig.Name .. "Item"
	itemFrame.Size = UDim2.new(1, -10, 0, 80)
	itemFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 55)
	itemFrame.BorderSizePixel = 0
	itemFrame.LayoutOrder = buttonConfig.Order
	itemFrame.Parent = scrollFrame

	local itemCorner = Instance.new("UICorner")
	itemCorner.CornerRadius = UDim.new(0, 10)
	itemCorner.Parent = itemFrame

	-- Название
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(0.6, 0, 0, 30)
	nameLabel.Position = UDim2.new(0, 12, 0, 5)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = buttonConfig.DisplayName
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.TextSize = 16
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Parent = itemFrame

	-- Описание
	local descLabel = Instance.new("TextLabel")
	descLabel.Size = UDim2.new(0.7, 0, 0, 20)
	descLabel.Position = UDim2.new(0, 12, 0, 32)
	descLabel.BackgroundTransparency = 1
	descLabel.Text = buttonConfig.Description
	descLabel.TextColor3 = Color3.fromRGB(180, 180, 200)
	descLabel.TextSize = 12
	descLabel.Font = Enum.Font.Gotham
	descLabel.TextXAlignment = Enum.TextXAlignment.Left
	descLabel.TextWrapped = true
	descLabel.Parent = itemFrame

	-- Кнопка покупки
	local buyButton = Instance.new("TextButton")
	buyButton.Name = "BuyButton"
	buyButton.Size = UDim2.new(0, 100, 0, 36)
	buyButton.Position = UDim2.new(1, -112, 0.5, -18)
	buyButton.BackgroundColor3 = Color3.fromRGB(50, 180, 50)
	buyButton.BorderSizePixel = 0
	buyButton.Text = "$" .. formatCash(buttonConfig.Price)
	buyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	buyButton.TextSize = 14
	buyButton.Font = Enum.Font.GothamBold
	buyButton.Parent = itemFrame

	local buyCorner = Instance.new("UICorner")
	buyCorner.CornerRadius = UDim.new(0, 8)
	buyCorner.Parent = buyButton

	-- Обработка нажатия
	buyButton.MouseButton1Click:Connect(function()
		if purchasedButtons[buttonConfig.Name] then return end
		purchaseRemote:FireServer(buttonConfig.Name)
	end)

	return itemFrame, buyButton
end

-- Создаём элементы магазина
local shopItems = {}
for i, buttonConfig in ipairs(TycoonConfig.Buttons) do
	local itemFrame, buyButton = createShopItem(buttonConfig, i)
	shopItems[buttonConfig.Name] = {
		Frame = itemFrame,
		BuyButton = buyButton,
	}
end

-------------------------------------------------------
-- ОБНОВЛЕНИЕ СТАТУСА КНОПОК
-------------------------------------------------------
local function updateButtonStatus(buttonName: string)
	purchasedButtons[buttonName] = true

	local item = shopItems[buttonName]
	if item then
		item.BuyButton.Text = "Куплено"
		item.BuyButton.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
		item.Frame.BackgroundColor3 = Color3.fromRGB(25, 40, 25)
	end
end

-------------------------------------------------------
-- УВЕДОМЛЕНИЯ
-------------------------------------------------------
local function showNotification(text: string, color: Color3?)
	local notif = Instance.new("TextLabel")
	notif.Size = UDim2.new(0, 300, 0, 40)
	notif.Position = UDim2.new(0.5, -150, 1, 0)
	notif.BackgroundColor3 = color or Color3.fromRGB(50, 150, 50)
	notif.BackgroundTransparency = 0.2
	notif.BorderSizePixel = 0
	notif.Text = text
	notif.TextColor3 = Color3.fromRGB(255, 255, 255)
	notif.TextSize = 16
	notif.Font = Enum.Font.GothamBold
	notif.Parent = screenGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = notif

	-- Анимация появления
	local tweenIn = TweenService:Create(notif, TweenInfo.new(0.3, Enum.EasingStyle.Back), {
		Position = UDim2.new(0.5, -150, 1, -60)
	})
	tweenIn:Play()

	-- Анимация исчезновения
	task.delay(2.5, function()
		local tweenOut = TweenService:Create(notif, TweenInfo.new(0.3), {
			Position = UDim2.new(0.5, -150, 1, 20),
			BackgroundTransparency = 1,
			TextTransparency = 1,
		})
		tweenOut:Play()
		tweenOut.Completed:Connect(function()
			notif:Destroy()
		end)
	end)
end

-------------------------------------------------------
-- ОБРАБОТКА СОБЫТИЙ
-------------------------------------------------------

-- Обновление денег
updateCashRemote.OnClientEvent:Connect(function(amount)
	animateCashChange(amount)
end)

-- Кнопка куплена
buttonPurchasedRemote.OnClientEvent:Connect(function(buyer, buttonName)
	if buyer == player then
		updateButtonStatus(buttonName)

		-- Найти DisplayName
		for _, btn in ipairs(TycoonConfig.Buttons) do
			if btn.Name == buttonName then
				showNotification(btn.DisplayName .. " куплен!", Color3.fromRGB(50, 200, 50))
				break
			end
		end
	end
end)

-- Тайкун захвачен
claimedRemote.OnClientEvent:Connect(function(claimer, plotIndex)
	if claimer == player then
		showNotification("Ты занял плот #" .. plotIndex .. "!", Color3.fromRGB(50, 100, 255))
	else
		showNotification(claimer.Name .. " занял плот #" .. plotIndex, Color3.fromRGB(150, 150, 150))
	end
end)

-------------------------------------------------------
-- ОТКРЫТИЕ/ЗАКРЫТИЕ МАГАЗИНА
-------------------------------------------------------
local shopOpen = false

local function toggleShop()
	shopOpen = not shopOpen
	shopFrame.Visible = shopOpen

	if shopOpen then
		shopFrame.Size = UDim2.new(0, 0, 0, 0)
		shopFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
		local tween = TweenService:Create(shopFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back), {
			Size = UDim2.new(0, 350, 0, 500),
			Position = UDim2.new(0.5, -175, 0.5, -250),
		})
		tween:Play()
	end
end

shopButton.MouseButton1Click:Connect(toggleShop)
closeButton.MouseButton1Click:Connect(function()
	shopOpen = true
	toggleShop()
end)

print("[TycoonHUD] UI загружен!")
