# NB3Lang

Простой язык программирования для игр.

## Запуск

```bash
# Запустить файл
python -m nb3lang examples/hello.nb3

# Интерактивный режим (REPL)
python -m nb3lang
```

## Синтаксис

### Переменные
```
name = "Player"
hp = 100
speed = 3.5
alive = true
```

### Ввод/вывод
```
# input() автоматически определяет тип (число или строка)
a = input("Введи число: ")
b = input()

# print() автоматически склеивает строки и числа
print("Результат: " + a + b)
```

### Условия
```
if hp > 50:
    print("Healthy")
elif hp > 20:
    print("Wounded")
else:
    print("Critical!")
```

### Циклы
```
# while
while enemy_hp > 0:
    enemy_hp -= 10
    print("Hit!")

# for
for i in range(10):
    print(i)

for item in inventory:
    print(item)
```

### Функции
```
func attack(target, damage):
    target -= damage
    print("Dealt " + damage + " damage!")
    return target

func factorial(n):
    if n <= 1:
        return 1
    return n * factorial(n - 1)
```

### Списки
```
inventory = ["sword", "shield", "potion"]
inventory.append("bow")
inventory.sort()
print(len(inventory))
print(inventory[0])
```

### Строковые методы
```
name = "hello world"
print(name.upper())
print(name.split(" "))
print(name.replace("world", "NB3"))
```

## Встроенные функции

| Функция | Описание |
|---------|----------|
| `print(...)` | Вывод в консоль |
| `input(prompt)` | Ввод (авто-тип) |
| `len(x)` | Длина строки/списка |
| `str(x)` | В строку |
| `int(x)` | В целое число |
| `float(x)` | В дробное число |
| `type(x)` | Тип значения |
| `range(n)` / `range(a, b)` / `range(a, b, step)` | Диапазон |
| `abs(x)` | Модуль числа |
| `min(a, b)` / `max(a, b)` | Минимум / Максимум |
| `round(x)` | Округление |
| `random()` | Случайное 0.0–1.0 |
| `randint(a, b)` | Случайное целое a–b |
| `sqrt(x)` | Квадратный корень |
| `sleep(sec)` | Пауза |

## Примеры

Смотри папку `examples/`:
- `hello.nb3` — Hello World
- `calculator.nb3` — Калькулятор
- `guess_game.nb3` — Угадай число
- `functions.nb3` — Функции и рекурсия
- `lists.nb3` — Списки и циклы
- `rpg.nb3` — RPG-бой
