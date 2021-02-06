local type Splash = record
    metamethod __call: function(Splash): Splash
end

return Splash
