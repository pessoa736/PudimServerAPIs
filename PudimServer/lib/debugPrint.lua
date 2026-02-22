
local yellow<const> = "\27[33m"
local Reset<const> = "\27[0m"
local unpack<const> = table.unpack

return function(...)
    local new_texts = {}

    for idx, text in ipairs({...}) do
        new_texts[idx] = yellow .. text .. Reset
    end

    print(unpack(new_texts))
end