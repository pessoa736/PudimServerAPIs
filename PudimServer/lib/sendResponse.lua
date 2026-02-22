


---@param client table
---@param response string
---@param yieldFn? fun()
---@return boolean ok
---@return string? err
return function (client, response, yieldFn)
  local index = 1

    while index <= #response do
        local sent, err, last = client:send(response, index)
        if sent then
            index = sent + 1
        elseif err == "timeout" or err == "wantread" or err == "wantwrite" then
            if last and last >= index then
                index = last + 1
            end
            if yieldFn then
                yieldFn()
            else
                return false, err
            end
        else
            return false, err
        end
    end

  return true
end