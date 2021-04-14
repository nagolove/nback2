require "common"
require "cmn"
require "nbtypes"

local inspect = require "inspect"

local logfile = love.filesystem.newFile("log-generator.txt", "w")

local type GenFunction = function<T>(): T
local type CmpFunction = function<T>(T, T): boolean

local function generate<T>(sig_count: number, level: integer, gen: GenFunction<T>, cmp: CmpFunction<T>): {T}
    local ret: {T} = {} -- массив сигналов, который будет сгенерирован и возвращен
    local ratio = 5 
    local range = {1, 3} 
    local null = {} -- обозначает пустой элемент массива, отсутствие сигнала.

    for _ = 1, ratio * sig_count do
        table.insert(ret, null as T)
    end

    repeat
        local i = 1
        repeat
            if sig_count > 0 then
                -- вероятность выпадения значения
                -- помоему здесб написана хрень
                local prob = math.random(table.unpack(range))
                --[[print("prob", prob)]]
                if prob == range[2] then
                    if i + level <= #ret and ret[i] == null and ret[i + level] == null then
                        ret[i] = gen()
                        if type(ret[i]) == "table" then
                            ret[i + level] = shallowCopy(ret[i])
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

local function make_hit_arr<T>(signals: {T}, level: integer, comparator: CmpFunction<T>): {boolean}
    local ret: {boolean} = {}
    if signals then
        for k, v in ipairs(signals) do
            ret[#ret + 1] = k > level and comparator(v, signals[k - level])
        end
    end
    return ret
end

local function makeEqArrays(signals: Signals, level: integer): Signals.Eq
    local ret = {
        pos = make_hit_arr(signals.pos, level, isPositionEqual),
        sound = make_hit_arr(signals.sound, level, 
            function(a: number, b: number): boolean
                return a == b 
            end),
        color = make_hit_arr(signals.color, level, function(a: string, b: string): boolean
            return a == b 
        end),
        form = make_hit_arr(signals.form, level, function(a: Signals.Forms, b: Signals.Forms): boolean
            return a == b 
        end),
    }
    return ret
end

function generateAll(sig_count: integer, level: integer, dim: integer, soundsNum: integer, map: {{number}}): Signals

    local colorArr = require "colorconstants".makeNamesArray()

    function genArrays(sig_count: number, level: integer, _: number, soundsNum: number): Signals
        local signals: Signals = {}

        logfile:write("--pos gen--\n")

        signals.pos = generate(sig_count, level,
            function(): Signals.Pos
                local result: Signals.Pos = {}
                local x, y = math.random(1, #map), math.random(1, #map[1])
                local i = 0
                while map[x][y] ~= 1 do
                    x, y = math.random(1, #map), math.random(1, #map[1])
                    i = i + 1
                    if i > 31 then
                        error("Something goes wrong, hmm")
                    end
                end
                result.x, result.y = x, y
                return result
            end,
            function(a: Signals.Pos, b: Signals.Pos): boolean
                return a.x == b.x and a.y == b.y
            end)

        logfile:write("--pos gen--\n")

        signals.form = generate(sig_count, level,
            function(): Signals.Forms
                local arr = {"trup", "trdown", "trupdown", "quad", "circle", "rhombus"}
                return arr[math.random(1, 6)]
            end,
            function(a: Signals.Forms, b: Signals.Forms): boolean 
                return a == b 
            end)

        signals.sound = generate(sig_count, level, 
            function(): number 
                return math.random(1, soundsNum) 
            end,
            function(a: number, b: number): boolean
                return a == b 
            end)

        signals.color = generate(sig_count, level,
            function(): string return colorArr[math.random(1, 6)] end,
            function(a: string, b: string): boolean
                return a == b 
            end)
        --print("color", inspect(signals.color))

        signals.eq = makeEqArrays(signals, level)
        return signals
    end

    -- попытка балансировки массивов от множественного совпадения(более двух сигналов на фрейм)
    -- случайной перегенерацией
    function balance(forIterCount: number): Signals
        local i, changed = 0, false
        local signals: Signals
        repeat
            i = i + 1
            signals = genArrays(sig_count, level, dim, soundsNum)
            for k, v in ipairs(signals.eq.pos) do
                local n = 0
                n = n + (v and 1 or 0)
                n = n + (signals.eq.sound[k] and 1 or 0)
                n = n + (signals.eq.form[k] and 1 or 0)
                n = n + (signals.eq.color[k] and 1 or 0)
                if n > 2 then
                    changed = true
                    --print("changed")
                end
            end
            --print("changed = " .. tostring(changed))
        until i >= forIterCount or not changed
        --print("balanced for " .. i .. " iterations")
        return signals
    end

    local result =  balance(1)

    logfile:write("\n")
    logfile:write(inspect(result))
    logfile:write("\n")
    logfile:close()

    return result
end

return { 
    makeEqArrays = makeEqArrays,
    generateAll = generateAll, 
}

