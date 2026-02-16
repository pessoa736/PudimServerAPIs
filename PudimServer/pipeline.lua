---@diagnostic disable: duplicate-doc-field

if not _G.log then _G.log = require("loglua") end
local utils = require("PudimServer.utils")


--- interfaces

---@alias PipelineHandler fun(req: Request, res: HttpModule, next: fun(): string?): string?

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


--- Creates a new empty Pipeline instance.
---@return Pipeline pipeline New pipeline ready to register handlers
function Pipeline.new()
  local self = setmetatable({}, Pipeline)
  self._handlers = {}
  return self
end


--- Adds a handler to the pipeline. Handlers execute in insertion order.
---@param entry PipelineEntry Handler entry with name (string) and Handler (function)
function Pipeline:use(entry)
  local PL = log.inSection("Pipeline")
  utils:verifyTypes(entry, PipelineEntryInter, PL.error, true)
  table.insert(self._handlers, entry)
end


--- Removes a handler from the pipeline by name.
---@param name string Name of the handler to remove
---@return boolean removed True if handler was found and removed
function Pipeline:remove(name)
  for i = #self._handlers, 1, -1 do
    if self._handlers[i].name == name then
      table.remove(self._handlers, i)
      return true
    end
  end
  return false
end


--- Executes the pipeline chain, calling each handler in order.
--- Each handler receives (req, res, next) and must call next() to continue.
--- The finalHandler runs after all pipeline handlers complete.
---@param req Request The HTTP request object
---@param res HttpModule The HTTP response builder
---@param finalHandler fun(req: Request, res: HttpModule): string? The route handler
---@return string? response The HTTP response string or nil
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
