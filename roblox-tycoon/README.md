# Roblox Tycoon — Полный набор скриптов

Готовая система тайкуна для Roblox с дропперами, конвейерами, коллекторами, улучшателями и системой сохранений.

## Возможности

- **6 плотов** для мультиплеера
- **10 покупаемых объектов**: дропперы, конвейеры, коллекторы, улучшатели
- **Система валюты** с красивым UI и анимациями
- **Магазин** с описаниями и ценами
- **Автосохранение** через DataStore
- **Billboard-подсказки** над свободными плотами
- **Пульсирующие анимации** и уведомления

## Структура файлов

```
roblox-tycoon/
├── ReplicatedStorage/
│   ├── TycoonConfig.lua          -- Настройки (цены, интервалы, цвета)
│   └── SetupRemotes.lua          -- Создание RemoteEvent-ов
├── ServerScriptService/
│   ├── TycoonManager.server.lua  -- Главный серверный скрипт
│   └── DataStoreManager.lua      -- Сохранение/загрузка прогресса
├── StarterGui/
│   ├── TycoonHUD.client.lua      -- UI денег + магазин
│   └── ClaimPlotUI.client.lua    -- Billboard-ы над плотами
└── Workspace/
    └── PlotSetup.server.lua      -- Авто-генерация плотов
```

## Установка в Roblox Studio

### Шаг 1: Создай новый Place
1. Открой **Roblox Studio**
2. Создай новый **Baseplate** проект

### Шаг 2: Добавь скрипты

#### ReplicatedStorage
1. В **Explorer** выбери `ReplicatedStorage`
2. Нажми **правой кнопкой → Insert Object → ModuleScript**
3. Назови его `TycoonConfig`
4. Скопируй содержимое `ReplicatedStorage/TycoonConfig.lua`
5. Повтори для `SetupRemotes` (тоже **ModuleScript**)

#### ServerScriptService
1. Выбери `ServerScriptService`
2. **Insert Object → ModuleScript**, назови `DataStoreManager`
3. Скопируй содержимое `ServerScriptService/DataStoreManager.lua`
4. **Insert Object → Script** (обычный серверный Script), назови `TycoonManager`
5. Скопируй содержимое `ServerScriptService/TycoonManager.server.lua`

#### StarterGui
1. Выбери `StarterGui`
2. **Insert Object → LocalScript**, назови `TycoonHUD`
3. Скопируй содержимое `StarterGui/TycoonHUD.client.lua`
4. **Insert Object → LocalScript**, назови `ClaimPlotUI`
5. Скопируй содержимое `StarterGui/ClaimPlotUI.client.lua`

#### Генерация плотов
1. Выбери `ServerScriptService`
2. **Insert Object → Script**, назови `PlotSetup`
3. Скопируй содержимое `Workspace/PlotSetup.server.lua`
4. **Запусти игру (Play)** — плоты создадутся автоматически
5. После этого можешь удалить скрипт `PlotSetup` или оставить (он не создаст дубликаты)

### Шаг 3: Включи DataStore (для сохранений)
1. **Game Settings → Security**
2. Включи **"Enable Studio Access to API Services"**

### Шаг 4: Тестируй!
1. Нажми **Play** в Roblox Studio
2. Подойди к зелёной платформе (ClaimPad) чтобы занять плот
3. Кликай на кнопки покупок чтобы разблокировать объекты
4. Открой магазин кнопкой "Shop" справа

## Дерево покупок

| # | Название | Цена | Описание |
|---|----------|------|----------|
| 1 | Базовый дроппер | $0 | Блоки по $5 |
| 2 | Конвейер | $200 | Перемещает блоки |
| 3 | Коллектор | $300 | Собирает деньги |
| 4 | Продвинутый дроппер | $1,000 | Блоки по $25 |
| 5 | Авто-коллектор | $2,500 | Автосбор |
| 6 | Золотой дроппер | $5,000 | Блоки по $100 |
| 7 | Алмазный дроппер | $15,000 | Блоки по $500 |
| 8 | Улучшатель | $25,000 | x2 стоимость |
| 9 | Мега-дроппер | $75,000 | Блоки по $2,500 |
| 10 | Супер-улучшатель | $150,000 | x3 стоимость |

## Настройка

Все параметры можно изменить в файле `TycoonConfig.lua`:

- `MaxPlots` — количество плотов
- `StartingCash` — стартовые деньги
- `DropperInterval` — скорость дропперов (секунды)
- `ConveyorSpeed` — скорость конвейера
- `Buttons` — список покупок (добавляй свои!)

## Как добавить свою кнопку

1. Добавь запись в `TycoonConfig.Buttons`:
```lua
{
    Name = "MyCustomDropper",
    DisplayName = "Мой дроппер",
    Price = 50000,
    Description = "Супер-крутой дроппер!",
    DropValue = 1000,
    Order = 11,
},
```

2. Добавь цвет в `TycoonConfig.DropColors`:
```lua
MyCustomDropper = Color3.fromRGB(255, 0, 255),
```

3. Добавь модель в `PlotSetup.server.lua` (или создай вручную в Studio)

## Лицензия

Свободное использование. Делай что хочешь!
