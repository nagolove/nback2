global type LibSplash = record
    metamethod __call: function(LibSplash): LibSplash

    skip: function()
    draw: function()
    update: function(number)
end

return LibSplash
