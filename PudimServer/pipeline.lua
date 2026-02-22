---@diagnostic disable: duplicate-doc-field

if not _G.log then _G.log = require("loglua") end
local utils = require("PudimServer.utils")
local debugPrint = require("PudimServer.lib.debugPrint")


--- interfaces


local PipelineEntryInter = utils:createInterface{
  name = "string",
  Handler = "function"
}


---------
--- main

---@type Pipeline
local Pipeline = {}
Pipeline.__index = Pipeline


function Pipeline.new()
  local self = setmetatable({}, Pipeline)
  self._handlers = {}
  return self
end


Pipeline.__call = Pipeline.new


function Pipeline:use(entry)
  utils:verifyTypes(entry, PipelineEntryInter, print, true)

  table.insert(self._handlers, entry)
end


function Pipeline:remove(name)
  for i = #self._handlers, 1, -1 do
    if self._handlers[i].name == name then
      table.remove(self._handlers, i)
      return true
    end
  end
  return false
end


function Pipeline:execute(req, res, finalHandler)
  local handlers = self._handlers
  local index = 0

  local function next()
    index = index + 1

    if index <= #handlers then
      local handler = handlers[index]
      debugPrint(("running pipeline: %s"):format(handler.name))
      return handler.Handler(req, res, next)
    else
      return finalHandler(req, res)
    end
  end

  return next()
end


return Pipeline
