---@diagnostic disable: duplicate-doc-field

if not _G.log then _G.log = require("loglua") end
local utils = require("PudimServer.utils")


--- interfaces

---@alias PipelineHandler fun(req: Request, res: HttpModuler, next: fun(): string?): string?

---@class PipelineEntry
---@field name string Nome do handler
---@field Handler PipelineHandler Função do handler

local PipelineEntryInter = utils:createInterface{
  name = "string",
  Handler = "function"
}


---------
--- main

---@class Pipeline
---@field _handlers PipelineEntry[]
local Pipeline = {}
Pipeline.__index = Pipeline


---@return Pipeline
function Pipeline.new()
  local self = setmetatable({}, Pipeline)
  self._handlers = {}
  return self
end


---@param entry PipelineEntry
function Pipeline:use(entry)
  local PL = log.inSection("Pipeline")
  utils:verifyTypes(entry, PipelineEntryInter, PL.error, true)
  table.insert(self._handlers, entry)
end


---@param name string
function Pipeline:remove(name)
  for i = #self._handlers, 1, -1 do
    if self._handlers[i].name == name then
      table.remove(self._handlers, i)
      return true
    end
  end
  return false
end


---@param req Request
---@param res HttpModuler
---@param finalHandler fun(req: Request, res: HttpModuler): string?
---@return string?
function Pipeline:execute(req, res, finalHandler)
  local PL = log.inSection("Pipeline")
  local handlers = self._handlers
  local index = 0

  local function next()
    index = index + 1

    if index <= #handlers then
      local handler = handlers[index]
      PL.debug(("running pipeline: %s"):format(handler.name))
      return handler.Handler(req, res, next)
    else
      return finalHandler(req, res)
    end
  end

  return next()
end


return Pipeline
