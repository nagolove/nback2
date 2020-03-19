local clone = require "libs.lume".clone
local inspect = require "libs.inspect"

local function generate(sig_count, gen, cmp, level)
    print("generate", "sig_count", sig_count, "gen", inspect(gen), "cmp", inspect(cmp), "level", level)
    --[[print(string.format("generating signal array for %d signals of %d level.", sig_count, level))]]

    local ret = {} -- массив сигналов, который будет сгенерирован и возвращен
    --функцией.
    --Если поставить меньше 3, то может зависать генерация в бесконечном цикле.
    local ratio = 5 
    -- что делает эта таблица, задает границы цему-то? С какой вероятностью
    -- должно выпадать событие? 1/3?
    local range = {1, 3} 
    local null = {} -- обозначает пустой элемент массива, отсутствие сигнала.

    -- забиваю пустыми значениями весь массив, по всей длине.
    for i = 1, ratio * sig_count do
        table.insert(ret, null)
    end

    repeat
        local i = 1
        repeat
            if sig_count > 0 then
                -- вероятность выпадения значения
                -- помоему здесб написана хрень
                local prob = math.random(unpack(range))
                print("prob", prob)
                if prob == range[2] then
                    if i + level <= #ret and ret[i] == null and ret[i + level] == null then
                        ret[i] = gen()
                        if type(ret[i]) == "table" then
                            ret[i + level] = clone(ret[i])
                        else
                            ret[i + level] = ret[i]
                        end
                        sig_count = sig_count - 1
                    end
                end
            end
            i = i + 1
        until i > #ret
    until sig_count == 0

    -- замена пустых мест в массиве случайно сгенерированным сигналом так, что-бы 
    -- он не совпадал на текущем уровне n-назад
    for i = 1, #ret do
        if ret[i] == null then
            repeat
                ret[i] = gen()
            until not (i + level <= #ret and cmp(ret[i], ret[i + level]))
        end
    end

    return ret
end

local function make_hit_arr(signals, level, comparator)
    local ret = {}
    if signals then
        print("make_hit_arr")
        for k, v in pairs(signals) do
            ret[#ret + 1] = k > level and comparator(v, signals[k - level])
        end
    end
    return ret
end

local function makeEqArrays(signals, level)
    local ret = {
        pos = make_hit_arr(signals.pos, level, function(a, b) return a[1] == b[1] and a[2] == b[2] end),
        sound = make_hit_arr(signals.sound, level, function(a, b) return a == b end),
        color = make_hit_arr(signals.color, level, function(a, b) return a == b end),
        form = make_hit_arr(signals.form, level, function(a, b) return a == b end),
    }
    print("makeEqArrays", inspect(ret))
    return ret
end

--[[
   [function makeColorArr()
   [    local colorConstants = require "colorconstants"
   [    local color_arr = {}
   [    for k, _ in pairs(colorConstants) do
   [        color_arr[#color_arr + 1] = k
   [    end
   [    return color_arr
   [end
   ]]
local function generateAll(sig_count, level, dim, soundsNum)
    --[[local color_arr = makeColorArr()]]
    --[[local colorArr = require "colorconstants".new():makeNamesArray()]]
    local colorArr = require "colorconstants":makeNamesArray()

    function genArrays(sig_count, level, dim, soundsNum)
        local signals = {}
        signals.pos = generate(sig_count, level,
            function() return {math.random(1, dim - 1), 
                               math.random(1, dim - 1)} end,
            function(a, b) return  a[1] == b[1] and a[2] == b[2] end)
        print("pos", inspect(signals.pos))

        signals.form = generate(sig_count, level,
            function()
                local arr = {"trup", "trdown", "trupdown", "quad", "circle", "rhombus"}
                return arr[math.random(1, 6)]
            end,
            function(a, b) return a == b end)
        print("form", inspect(signals.form))

        signals.sound = generate(sig_count, level, 
            function() return math.random(1, soundsNum) end,
            function(a, b) return a == b end)
        print("snd", inspect(signals.sound))

        signals.color = generate(sig_count, level,
            function() return colorArr[math.random(1, 6)] end,
            function(a, b) 
                print(string.format("color comparator a = %s, b = %s", a, inspect(b)))
                return a == b 
            end)
        print("color", inspect(signals.color))

        signals.eq = makeEqArrays(signals, level)
    end

    -- попытка балансировки массивов от множественного совпадения(более двух сигналов на фрейм)
    -- случайной перегенерацией
    function balance(forIterCount)
        local i, changed = 0, false
        local signals
        repeat
            i = i + 1
            signals = genArrays(sig_count, level, dim, soundsNum)
            for k, v in pairs(signals.eq.pos) do
                local n = 0
                n = n + (v and 1 or 0)
                n = n + (signals.eq.sound[k] and 1 or 0)
                n = n + (signals.eq.form[k] and 1 or 0)
                n = n + (signals.eq.color[k] and 1 or 0)
                if n > 2 then
                    changed = true
                    print("changed")
                end
            end
            print("changed = " .. tostring(changed))
        until i >= forIterCount or not changed
        print("balanced for " .. i .. " iterations")
        return signals
    end

    return balance(5)
end

return { 
    makeEqArrays = makeEqArrays,
    generateAll = generateAll, 
}

