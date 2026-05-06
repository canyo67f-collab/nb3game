--[[
	DataStoreManager — сохранение и загрузка данных игрока
	Помести этот ModuleScript в ServerScriptService

	Сохраняет: деньги, купленные кнопки
]]

local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")

local DataStoreManager = {}

-- Имя DataStore
local STORE_NAME = "TycoonSaveData_v1"
local dataStore = DataStoreService:GetDataStore(STORE_NAME)

-- Кэш для предотвращения спама запросов
local saveCache = {}
local SAVE_COOLDOWN = 10 -- секунд между сохранениями

-------------------------------------------------------
-- ЗАГРУЗКА ДАННЫХ ИГРОКА
-------------------------------------------------------
function DataStoreManager.LoadPlayerData(player: Player): {Cash: number, OwnedButtons: {[string]: boolean}}?
	local key = "Player_" .. player.UserId
	local success, data = pcall(function()
		return dataStore:GetAsync(key)
	end)

	if success and data then
		print("[DataStore] Данные загружены для " .. player.Name)
		return data
	elseif not success then
		warn("[DataStore] Ошибка загрузки для " .. player.Name .. ": " .. tostring(data))
	end

	return nil
end

-------------------------------------------------------
-- СОХРАНЕНИЕ ДАННЫХ ИГРОКА
-------------------------------------------------------
function DataStoreManager.SavePlayerData(player: Player, data: {Cash: number, OwnedButtons: {[string]: boolean}})
	local key = "Player_" .. player.UserId

	-- Проверяем кулдаун
	local now = os.clock()
	if saveCache[key] and (now - saveCache[key]) < SAVE_COOLDOWN then
		return
	end
	saveCache[key] = now

	local saveData = {
		Cash = data.Cash,
		OwnedButtons = data.OwnedButtons,
		LastSave = os.time(),
	}

	local success, err = pcall(function()
		dataStore:SetAsync(key, saveData)
	end)

	if success then
		print("[DataStore] Данные сохранены для " .. player.Name)
	else
		warn("[DataStore] Ошибка сохранения для " .. player.Name .. ": " .. tostring(err))
	end
end

-------------------------------------------------------
-- СБРОС ДАННЫХ (для тестирования)
-------------------------------------------------------
function DataStoreManager.ResetPlayerData(player: Player)
	local key = "Player_" .. player.UserId

	local success, err = pcall(function()
		dataStore:RemoveAsync(key)
	end)

	if success then
		print("[DataStore] Данные сброшены для " .. player.Name)
	else
		warn("[DataStore] Ошибка сброса для " .. player.Name .. ": " .. tostring(err))
	end
end

return DataStoreManager
