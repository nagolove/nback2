local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local pairs = _tl_compat and _tl_compat.pairs or pairs


























local colors = {

   ["black"] = { 136 / 255, 55 / 255, 41 / 255 },
   ["white"] = { 136 / 255, 55 / 255, 41 / 255 },


   ["brown"] = { 136 / 255, 55 / 255, 41 / 255 },
   ["green"] = { 72 / 255, 180 / 255, 66 / 255 },
   ["blue"] = { 27 / 255, 30 / 255, 249 / 255 },
   ["red"] = { 241 / 255, 30 / 255, 27 / 255 },
   ["yellow"] = { 231 / 255, 227 / 255, 11 / 255 },
   ["purple"] = { 128 / 255, 7 / 255, 128 / 255 },
}

local function makeNamesArray()
   local color_arr = {}
   for k, _ in pairs(colors) do
      color_arr[#color_arr + 1] = k
   end
   return color_arr
end

return {
   colors = colors,
   makeNamesArray = makeNamesArray,
}
