


return function (client, yieldFn)
    while true do
      local line, lineErr = client:receive("*l")
      if line then
        return line, nil
      end

      if (lineErr == "timeout" or lineErr == "wantread" or lineErr == "wantwrite") and yieldFn then
        yieldFn()
      else
        return nil, lineErr
      end
    end
  end