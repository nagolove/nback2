local lume = require "libs.lume"
local function generate(sig_count, gen, cmp, level)
    print(string.format("generating signal array for %d signals of %d level.", 
        sig_count, level))

    local ret = {} -- массив сигналов, который будет сгенерирован и возвращен
    --функцией.
    local ratio = 8 --TODO FIXME XXX -- что за "отношение"?
    local range = {1, 3} -- что делает эта таблица, задает границы цему-то?
    local count = sig_count -- зачем это переименование переменной?
    local null = {} -- обозначает пустой элемент массива, отсутствие сигнала.

    -- забиваю пустыми значениями весь массив, по всей длине.
    for i = 1, ratio * sig_count do
        table.insert(ret, null)
    end

    repeat
        local i = 1
        repeat
            if count > 0 then
                -- вероятность выпадения значения
                -- помоему здесб написана хрень
                local prob = math.random(unpack(range))
                print("prob", prob)
                if prob == range[2] then
                    if i + level <= #ret and ret[i] == null and ret[i + level] == null then
                        ret[i] = gen()
                        if type(ret[i]) == "table" then
                            ret[i + level] = lume.clone(ret[i])
                        else
                            ret[i + level] = ret[i]
                        end
                        count = count - 1
                    end
                end
            end
            i = i + 1
        until i > #ret
    until count == 0

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

return {
    generate = generate
}
