
local red<const> = "\27[31m"
local Reset<const> = "\27[0m"
local unpack<const> = table.unpack

return function(...)
    local new_texts = {}

    for idx, text in ipairs({...}) do
        new_texts[idx] = red .. text .. Reset
    end

    print(unpack(new_texts))
end