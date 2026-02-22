local urlDecode = require "PudimServer.lib.urlDecode"

return function (qs)
    if not qs or qs == "" then return {} end
    local out = {}
    for pair in qs:gmatch("([^&]+)") do
        local k,v = pair:match("([^=]+)=?(.*)")
        if k then
            k = urlDecode(k)
            v = urlDecode(v)
            if out[k] == nil then
                out[k] = v
            else
                if type(out[k]) == 'table' then
                    table.insert(out[k], v)
                else
                    out[k] = { out[k], v }
                end
            end
        end
    end
    return out
end