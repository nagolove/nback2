-- lk.isDown()
local shortcutsDown = {}
-- love.keypressed()
local shortcutsPressed = {}

local shortcutsList = nil

local lk = love.keyboard

local function combo2str(comboTbl)
    local res = "["
    for k, v in pairs(comboTbl) do
        res = res .. v
        if k < #comboTbl then
            res = res .. "+"
        end
    end
    return res .. "]"
end

local function prepareDrawing()
    shortcutsList = require "list":new(5, 5)
    for k, v in pairs(shortcutsDown) do
        shortcutsList:add(v.description .. " " .. combo2str(v.combo), k)
    end
    for k, v in pairs(shortcutsPressed) do
        shortcutsList:add(v.description .. " " .. combo2str(v.combo), k)
    end
    table.sort(shortcutsList.items, function(a, b)
        return a.id < b.id
    end)
    shortcutsList:done()
end

local function drawList()
    if not shortcutsList then
        prepareDrawing()
    end
    shortcutsList:draw()
end

local function updateList()
    if shortcutsList then
        shortcutsList:update(dt)
    end
end

-- рисовать список шорткатов, расположенный в определенных координатах
local function drawShortcutsList(x0, y0)
    x0 = x0 and x0 or 0
    y0 = y0 and y0 or 0
    local x, y = x0, y0

    local maxStringWidth = 0 -- сюда складывается максимальная длина строки символов, которая будет выводиться.
    local delimiter = "+"

    -- формирует и возвращает таблицу со списком комбинаций клавиш и описания их действия
    function makeTextList(list)
        local textList = {}      
        for k, v in pairs(list) do
            local keyCombination = ""
            for k, keyValue in pairs(v.combo) do
                if k < #v.combo then
                    keyCombination = keyValue  .. delimiter .. keyCombination
                else
                    keyCombination = keyCombination .. keyValue 
                end
            end
            local common = {}
            common[#common + 1] = {1, 0, 0}                       -- index  1
            common[#common + 1] = "\"" .. keyCombination .. "\""  --        2
            common[#common + 1] = {0, 1, 0}                       --        3
            common[#common + 1] = ": " .. v.description           --        4
            table.insert(textList, common) -- строка с цветами и строками для рисовки через lg.print()
            local textLen = string.len(common[2]) + string.len(common[4])
            maxStringWidth = textLen > maxStringWidth and textLen or maxStringWidth -- определение самой длинной текстовой строки для вывода цветного фонового прямоугольника
        end
        return textList
    end

    -- для списка list расчитывает высоту рисуемого поля текущим шрифтом
    function calcHeight(list)
        local h = 0
        for k, v in pairs(list) do
            h = h + lg.getFont():getHeight()
        end
        return h
    end

    local tmpFont = lg.getFont()
    lg.setFont(keyBindingsFont) 

    local list1, list2 = makeTextList(shortcutsPressed), makeTextList(shortcutsDown)

    -- XXX: здесь применен частный случай(workaround) - считается длина строки, потом считается ширина строки 'zzzzzzzzzzzzzzzzzz' такой длины.
    local str = ""
    for i = 1, maxStringWidth do str = str .. "z" end
    --

    -- расчет размера выводимого прямоугольника подложки
    local rectW, rectH = lg.getFont():getWidth(str), (calcHeight(shortcutsDown) + calcHeight(shortcutsPressed))

    lg.rectangle("fill", x0, y0, rectW, rectH)
    local oldWidth = lg.getLineWidth()
    local delta = 1
    lg.setLineWidth(3)
    lg.setColor{1, 0, 1}
    lg.rectangle("line", x0 - delta, y0 - delta, rectW + delta, rectH + delta)
    lg.setLineWidth(oldWidth)
    lg.setColor{1, 1, 1}
    function drawList(list)
        for k, v in pairs(list) do
            lg.print(v, x, y) -- выводится цветной текст
            y = y + lg.getFont():getHeight()
        end
    end
    drawList(list1) drawList(list2)
    lg.setFont(tmpFont)
end

-- usage example:
-- bindKey({"q"}, quit)
-- bindKey({"lshift", "x"}, changeCameraMode)
-- use scancode
local function bindKeyDown(stringID, keyCombination, action, description)
  assert(action, "action == nil in bindKey()")
  assert(stringID, "stringID should'not be empty")
  assert(action, "action == nil in bindKeyDown()")

  --[[здесь добавить проверки в таблице keyCombination на допустимость закодированных в них сочетаний. Если сочетание клавиш используется, то вызывать
  исключение, которое в идеале может обработать вызывающая функция.
  --]]

--  assert(shortcuts[stringID]) -- слот должен быть пустой
--  assert(description, "description == nil in bindKey()")
  -- извлечь из keyCombination значения
  -- проверить на дубликаты
  description = description and description or ""
  shortcutsDown[stringID] = {combo = keyCombination, action = action, 
    description = description, enabled = true}
end

-- должна быть возможность запускать с пустым stringID
-- может поле description поставить после stringID?
local function bindKeyPressed(stringID, keyCombination, action, description)
  assert(action, "action == nil in bindKeyPressed()")
  assert(description, "description == nil in bindKeyPressed()")
  shortcutsPressed[stringID] = {combo = keyCombination, action = action, 
    description = description, enabled = true}
end

-- очень неподходящее название
-- TODO: работает странно, если определить несколько горячих клавиш, к примеру f1 и f1+lshift
local function checkPressedKeys(key)
  for k, v in pairs(shortcutsPressed) do
    if v.enabled then
      -- обрати внимание на магию - первый элемент проверяется на love.keypressed(),
      -- а последущие - как дополнительные модификаторы на lk.isDown()
      local pressed = key == v.combo[1]
--    print("checkKeyboardInput2", key, v.combo[1])
--    print("#shortcuts2", #shortcuts2, inspect(shortcuts2))
      for i = 2, #v.combo do
--        print("checkKeyboardInput2", k, v.combo[i])
        pressed = pressed and lk.isDown(v.combo[i]) -- эта строчка что делает? Добавляет проверку модификатора при нажатии клавиш.
        if not pressed then break end
      end
      if pressed and v.action then
--        print("call action on shortcuts2", inspect(v.combo))
        v.action()
      end
    end
  end
end


-- проверка ввода. Используются значения, заранее
-- установленные при помощи bindKey(). Проверка выполняется через lk.isDown()
local function checkDownKeys()
-- а в чем хранить значения keyCombination? как назвать глобальную переменную?
  for k, v in pairs(shortcutsDown) do
    if v.enabled then
      local pressed = true
      for _, keyValue in pairs(v.combo) do
        pressed = pressed and lk.isScancodeDown(keyValue)
        if not pressed then break end -- если хоть одна клавиша в комбинации не нажата, то сбрасываю комбинацию.      
      end
      if pressed and v.action then 
        v.action() 
      end
    end
  end
end

local function send(stringID)
    local t = shortcutsDown[stringID]
    if t and t.enabled and t.action then
        t.action()
    else
        t = shortcutsPressed[stringID]
        if t and t.enabled and t.action then 
            t.action() 
        end
    end
end

return {
    bindKeyPressed = bindKeyPressed,
    bindKeyDown = bindKeyDown,
    checkDownKeys = checkDownKeys,
    checkPressedKeys = checkPressedKeys,
    shortcutsPressed = shortcutsPressed,
    drawShortcutsList = drawShortcutsList,
    send = send,

    updateList = updateList,
    drawList = drawList,
}
