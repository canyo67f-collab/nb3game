# NB3Lang Wiki

Полная документация языка программирования NB3Lang.

---

## Содержание

1. [Запуск](#запуск)
2. [Типы данных](#типы-данных)
3. [Переменные](#переменные)
4. [Операторы](#операторы)
5. [Ввод и вывод](#ввод-и-вывод)
6. [Условия](#условия)
7. [Циклы](#циклы)
8. [Функции](#функции)
9. [Списки](#списки)
10. [Строковые методы](#строковые-методы)
11. [Методы списков](#методы-списков)
12. [Встроенные функции](#встроенные-функции)
13. [Комментарии](#комментарии)
14. [Ошибки](#ошибки)
15. [Примеры программ](#примеры-программ)

---

## Запуск

```bash
# Запустить файл .nb3
python -m nb3lang my_program.nb3

# Интерактивный режим (REPL)
python -m nb3lang
```

В REPL можно писать код построчно. Для многострочных блоков (if, while, for, func) продолжайте вводить строки — пустая строка завершает блок. Введите `exit` для выхода.

---

## Типы данных

| Тип | Пример | Описание |
|-----|--------|----------|
| `int` | `42`, `-5`, `0` | Целое число |
| `float` | `3.14`, `-0.5` | Дробное число |
| `string` | `"hello"`, `'world'` | Строка (одинарные или двойные кавычки) |
| `bool` | `true`, `false` | Логическое значение |
| `list` | `[1, 2, 3]` | Список |
| `none` | — | Пустое значение (возврат функции без return) |

Узнать тип: `type(значение)`

```
print(type(42))       # int
print(type(3.14))     # float
print(type("hello"))  # string
print(type(true))     # bool
print(type([1,2]))    # list
```

---

## Переменные

Переменные создаются при первом присваивании. Тип определяется автоматически.

```
name = "Player"
hp = 100
speed = 3.5
alive = true
inventory = ["sword", "shield"]
```

### Составное присваивание

```
x = 10
x += 5    # x = 15
x -= 3    # x = 12
x *= 2    # x = 24
x /= 4   # x = 6.0
```

---

## Операторы

### Арифметические

| Оператор | Описание | Пример | Результат |
|----------|----------|--------|-----------|
| `+` | Сложение | `3 + 5` | `8` |
| `-` | Вычитание | `10 - 3` | `7` |
| `*` | Умножение | `4 * 5` | `20` |
| `/` | Деление | `10 / 3` | `3.333...` |
| `%` | Остаток от деления | `10 % 3` | `1` |
| `-x` | Унарный минус | `-5` | `-5` |

**Особенность:** `+` автоматически склеивает строки и числа:
```
print("Score: " + 100)     # Score: 100
print(42 + " points")      # 42 points
print("Hi" + " " + "NB3")  # Hi NB3
```

**Повторение строки:**
```
print("ha" * 3)  # hahaha
print(3 * "ha")  # hahaha
```

### Сравнения

| Оператор | Описание | Пример |
|----------|----------|--------|
| `==` | Равно | `x == 5` |
| `!=` | Не равно | `x != 5` |
| `<` | Меньше | `x < 10` |
| `>` | Больше | `x > 10` |
| `<=` | Меньше или равно | `x <= 10` |
| `>=` | Больше или равно | `x >= 10` |

### Логические

| Оператор | Описание | Пример |
|----------|----------|--------|
| `and` | Логическое И | `x > 0 and x < 10` |
| `or` | Логическое ИЛИ | `x == 0 or x == 1` |
| `not` | Логическое НЕ | `not alive` |

```
print(true and false)   # false
print(true or false)    # true
print(not true)         # false
```

---

## Ввод и вывод

### `print(...)`

Выводит значения в консоль. Принимает любое количество аргументов, разделённых пробелом.

```
print("Hello!")                    # Hello!
print("HP:", 100)                  # HP: 100
print("Score: " + 42 + " pts")    # Score: 42 pts
```

### `input(prompt)`

Считывает ввод от пользователя. **Автоматически определяет тип:**
- Если ввели целое число → `int`
- Если ввели дробное число → `float`
- Иначе → `string`

```
# Не нужно писать int(input())!
age = input("Сколько лет? ")    # Вводим 25 → age = 25 (int)
name = input("Имя: ")           # Вводим Alex → name = "Alex" (string)
```

---

## Условия

### if / elif / else

```
hp = 35

if hp > 75:
    print("Здоров")
elif hp > 25:
    print("Ранен")
elif hp > 0:
    print("Критический")
else:
    print("Мёртв")
```

**Результат:** `Ранен`

### Вложенные условия

```
level = 5
has_key = true

if level >= 5:
    if has_key:
        print("Дверь открыта!")
    else:
        print("Нужен ключ!")
else:
    print("Слишком низкий уровень")
```

---

## Циклы

### while

```
hp = 100
while hp > 0:
    hp -= 25
    print("HP: " + hp)
# HP: 75
# HP: 50
# HP: 25
# HP: 0
```

### for ... in

```
# Перебор списка
items = ["sword", "shield", "potion"]
for item in items:
    print("- " + item)

# range(n) — от 0 до n-1
for i in range(5):
    print(i)    # 0 1 2 3 4

# range(start, end) — от start до end-1
for i in range(1, 4):
    print(i)    # 1 2 3

# range(start, end, step)
for i in range(10, 0, -2):
    print(i)    # 10 8 6 4 2
```

### break и continue

```
# break — выход из цикла
for i in range(100):
    if i == 5:
        break
    print(i)    # 0 1 2 3 4

# continue — пропустить итерацию
for i in range(6):
    if i == 3:
        continue
    print(i)    # 0 1 2 4 5
```

---

## Функции

### Определение и вызов

```
func greet(name):
    print("Привет, " + name + "!")

greet("Player")    # Привет, Player!
```

### Возврат значения

```
func square(x):
    return x * x

result = square(7)
print(result)    # 49
```

### Несколько параметров

```
func damage(base, multiplier):
    return base * multiplier

dmg = damage(15, 2)
print("Урон: " + dmg)    # Урон: 30
```

### Рекурсия

```
func factorial(n):
    if n <= 1:
        return 1
    return n * factorial(n - 1)

print(factorial(5))    # 120
print(factorial(10))   # 3628800
```

### Вложенные вызовы

```
func add(a, b):
    return a + b

func mul(a, b):
    return a * b

print(add(3, mul(4, 5)))    # 23
```

---

## Списки

### Создание и доступ

```
scores = [100, 250, 75]

print(scores[0])     # 100 (первый элемент)
print(scores[2])     # 75 (третий элемент)
print(scores[-1])    # 75 (последний элемент)
```

### Изменение элемента

```
scores[1] = 999
print(scores)    # [100, 999, 75]
```

### Вложенные списки

```
grid = [[1, 2], [3, 4]]
print(grid[0])       # [1, 2]
print(grid[1][0])    # 3
```

---

## Строковые методы

| Метод | Описание | Пример | Результат |
|-------|----------|--------|-----------|
| `.upper()` | В верхний регистр | `"hello".upper()` | `"HELLO"` |
| `.lower()` | В нижний регистр | `"HELLO".lower()` | `"hello"` |
| `.strip()` | Убрать пробелы по краям | `" hi ".strip()` | `"hi"` |
| `.split(sep)` | Разделить строку | `"a,b,c".split(",")` | `["a","b","c"]` |
| `.replace(old, new)` | Заменить подстроку | `"hello".replace("l","r")` | `"herro"` |
| `.startswith(s)` | Начинается с... | `"hello".startswith("he")` | `true` |
| `.endswith(s)` | Заканчивается на... | `"hello".endswith("lo")` | `true` |
| `.contains(s)` | Содержит подстроку | `"hello".contains("ell")` | `true` |
| `.find(s)` | Позиция подстроки | `"hello".find("ll")` | `2` |
| `.len()` | Длина строки | `"hello".len()` | `5` |
| `.repeat(n)` | Повторить n раз | `"ha".repeat(3)` | `"hahaha"` |
| `.join(list)` | Склеить список | `", ".join(["a","b"])` | `"a, b"` |

---

## Методы списков

| Метод | Описание | Пример |
|-------|----------|--------|
| `.append(x)` | Добавить в конец | `items.append("bow")` |
| `.pop()` | Удалить последний | `items.pop()` |
| `.pop(i)` | Удалить по индексу | `items.pop(0)` |
| `.insert(i, x)` | Вставить по индексу | `items.insert(0, "axe")` |
| `.remove(x)` | Удалить по значению | `items.remove("sword")` |
| `.sort()` | Сортировать | `numbers.sort()` |
| `.reverse()` | Перевернуть | `numbers.reverse()` |
| `.contains(x)` | Содержит элемент | `items.contains("sword")` |
| `.index(x)` | Индекс элемента | `items.index("shield")` |
| `.len()` | Длина списка | `items.len()` |

---

## Встроенные функции

### Преобразование типов

| Функция | Описание | Пример |
|---------|----------|--------|
| `str(x)` | В строку | `str(42)` → `"42"` |
| `int(x)` | В целое число | `int("42")` → `42` |
| `float(x)` | В дробное число | `float("3.14")` → `3.14` |
| `type(x)` | Узнать тип | `type(42)` → `"int"` |

### Математика

| Функция | Описание | Пример |
|---------|----------|--------|
| `abs(x)` | Модуль числа | `abs(-5)` → `5` |
| `round(x)` | Округление | `round(3.7)` → `4` |
| `round(x, n)` | Округление до n знаков | `round(3.14159, 2)` → `3.14` |
| `min(a, b)` | Минимум | `min(3, 7)` → `3` |
| `max(a, b)` | Максимум | `max(3, 7)` → `7` |
| `min(list)` | Минимум в списке | `min([1,2,3])` → `1` |
| `max(list)` | Максимум в списке | `max([1,2,3])` → `3` |
| `sqrt(x)` | Квадратный корень | `sqrt(16)` → `4.0` |

### Случайные числа (для игр!)

| Функция | Описание | Пример |
|---------|----------|--------|
| `random()` | Случайное от 0.0 до 1.0 | `random()` → `0.7312...` |
| `randint(a, b)` | Случайное целое от a до b | `randint(1, 6)` → бросок кубика |

### Коллекции

| Функция | Описание | Пример |
|---------|----------|--------|
| `len(x)` | Длина строки/списка | `len("hello")` → `5` |
| `range(n)` | Числа от 0 до n-1 | `range(5)` → `[0,1,2,3,4]` |
| `range(a, b)` | Числа от a до b-1 | `range(2, 5)` → `[2,3,4]` |
| `range(a, b, step)` | С шагом | `range(0, 10, 2)` → `[0,2,4,6,8]` |
| `list(x)` | В список | `list("abc")` → `["a","b","c"]` |

### Работа со списками (функции)

| Функция | Описание | Пример |
|---------|----------|--------|
| `append(lst, x)` | Добавить в конец | `append(items, "bow")` |
| `pop(lst)` | Удалить последний | `pop(items)` |
| `sort(lst)` | Сортировать | `sort(numbers)` |
| `reverse(lst)` | Перевернуть | `reverse(numbers)` |

### Работа со строками (функции)

| Функция | Описание | Пример |
|---------|----------|--------|
| `upper(s)` | В верхний регистр | `upper("hi")` → `"HI"` |
| `lower(s)` | В нижний регистр | `lower("HI")` → `"hi"` |
| `strip(s)` | Убрать пробелы | `strip(" hi ")` → `"hi"` |
| `split(s, sep)` | Разделить | `split("a,b", ",")` → `["a","b"]` |
| `replace(s, old, new)` | Заменить | `replace("hi", "i", "ey")` → `"hey"` |
| `join(sep, lst)` | Склеить | `join(", ", ["a","b"])` → `"a, b"` |
| `contains(s, sub)` | Содержит | `contains("hello", "ell")` → `true` |

### Прочее

| Функция | Описание | Пример |
|---------|----------|--------|
| `sleep(sec)` | Пауза (секунды) | `sleep(1.5)` |
| `print(...)` | Вывод | `print("Hello!")` |
| `input(prompt)` | Ввод (авто-тип) | `input("Name: ")` |

---

## Комментарии

Однострочные комментарии начинаются с `#`:

```
# Это комментарий
hp = 100  # Здоровье игрока
```

---

## Ошибки

NB3Lang показывает понятные сообщения об ошибках:

```
# Необъявленная переменная
print(x)
# Runtime error: Variable 'x' is not defined

# Деление на ноль
print(10 / 0)
# Runtime error: Division by zero

# Неверный синтаксис
if true
# Parse error: [Line 1, Col 8] Expected COLON, got NEWLINE

# Неправильные отступы
if true:
print("hi")
# Lexer error: [Line 2, Col 1] Indentation error
```

---

## Примеры программ

### Калькулятор

```
a = input("Первое число: ")
b = input("Второе число: ")
c = a + b
print(a + " + " + b + " = " + c)
```

### Угадай число

```
secret = randint(1, 100)
attempts = 0
print("Я загадал число от 1 до 100!")

while true:
    guess = input("Твоя догадка: ")
    attempts += 1

    if guess == secret:
        print("Верно! Попыток: " + attempts)
        break
    elif guess < secret:
        print("Больше!")
    else:
        print("Меньше!")
```

### RPG-бой

```
player_hp = 100
enemy_hp = 80
enemy_name = "Goblin"

print("=== БИТВА ===")
round = 1

while player_hp > 0 and enemy_hp > 0:
    print("--- Раунд " + round + " ---")

    dmg = randint(10, 20)
    enemy_hp -= dmg
    print("Ты наносишь " + dmg + " урона!")

    if enemy_hp <= 0:
        print("Победа!")
        break

    dmg = randint(7, 13)
    player_hp -= dmg
    print(enemy_name + " наносит " + dmg + " урона!")

    round += 1
```

### Сортировка пузырьком

```
func bubble_sort(arr):
    n = len(arr)
    for i in range(n):
        for j in range(0, n - i - 1):
            if arr[j] > arr[j + 1]:
                temp = arr[j]
                arr[j] = arr[j + 1]
                arr[j + 1] = temp
    return arr

numbers = [64, 34, 25, 12, 22, 11, 90]
print("До: " + numbers)
bubble_sort(numbers)
print("После: " + numbers)
```

### Генератор паролей

```
chars = "abcdefghijklmnopqrstuvwxyz0123456789"
password = ""
for i in range(12):
    idx = randint(0, len(chars) - 1)
    password = password + chars[idx]
print("Пароль: " + password)
```

---

## Расширения файлов

Программы NB3Lang используют расширение `.nb3`:
- `game.nb3`
- `calculator.nb3`
- `my_program.nb3`
