
---@param s string
---@return string
return function (s)
    return s:gsub("([%^%$%(%)%%%.%[%]%*%+%-%?])","%%%1")
end