global type Settings = record
    volume: number
    firstRun: boolean
    level: integer
    pause_time: number
    dim: integer
end

global type Date = record
    year : number
    month : number
    day : number
    hour : number
    min : number
    sec : number
    wday : number
    yday : number
    isdst : boolean
end

global type Signals = record
    enum Forms
        "trup"
        "trdown"
        "trupdown"
        "quad"
        "circle"
        "rhombus"
    end

    record Pos
        x: integer
        y: integer
    end

    enum EqKeys
        "color"
        "form"
        "pos"
        "sound"
    end

    record Eq
        color: {boolean}
        form: {boolean}
        pos: {boolean}
        sound: {boolean}
    end

    color: {string}
    form: {Forms}
    pos: {Pos}
    --sounds: {number}
    sound: {integer}

    eq: Eq
end

global type Percentage = record
    sound: number
    color: number
    form: number
    pos: number
    common: number
end


global record History
    date: Date
    signals: Signals
    pressed: Signals.Eq
    level: integer
    pause_time: number
end
