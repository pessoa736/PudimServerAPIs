---@diagnostic disable: missing-return


---@alias PipelineHandler fun(req: Request, res: httpParser, next: fun(): string?): string?

---@class PipelineEntry
---@field name string Nome do handler
---@field Handler PipelineHandler Função do handler



---@class Pipeline
---@field _handlers PipelineEntry[]
local Pipeline = {}
Pipeline.__index = Pipeline

--- Creates a new empty Pipeline instance.
---@return Pipeline pipeline New pipeline ready to register handlers
function Pipeline.new() end

--- Creates a new empty Pipeline instance.
---@return Pipeline pipeline New pipeline ready to register handlers
function Pipeline.__call() end


--- Adds a handler to the pipeline. Handlers execute in insertion order.
---@param entry PipelineEntry Handler entry with name (string) and Handler (function)
---@param self Pipeline
function Pipeline.use(self, entry) end


--- Removes a handler from the pipeline by name.
---@param self Pipeline
---@param name string Name of the handler to remove
---@return boolean removed True if handler was found and removed
function Pipeline.remove(self, name) end



--- Executes the pipeline chain, calling each handler in order.
--- Each handler receives (req, res, next) and must call next() to continue.
--- The finalHandler runs after all pipeline handlers complete.
---@param self Pipeline
---@param req Request The HTTP request object
---@param res httpParser The HTTP response builder
---@param finalHandler fun(req: Request, res: httpParser): string? The route handler
---@return string? response The HTTP response string or nil
function Pipeline.execute(self, req, res, finalHandler) end

return Pipeline