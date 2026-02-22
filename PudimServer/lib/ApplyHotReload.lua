

---@param config HotReloadConfig?
return function (config)
  if not config or not config.Enabled then return end

  for _, moduleName in ipairs(config.Modules or {}) do
    package.loaded[moduleName] = nil
  end

  local prefixes = config.Prefixes or {}
  if #prefixes == 0 then return end

  for loadedName, _ in pairs(package.loaded) do
    if type(loadedName) == "string" then
      for _, prefix in ipairs(prefixes) do
        if loadedName:sub(1, #prefix) == prefix then
          package.loaded[loadedName] = nil
          break
        end
      end
    end
  end
end