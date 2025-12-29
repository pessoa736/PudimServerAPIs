--- Important: this file must be executed in Root Project. "lua ./PS/mysandbox/test.lua"

local PS = assert(require("PS"), "PSA Fails to load")

log.activateDebugMode()
log.live()

local serverTest = PS:CreateServer({
    Address = "localhost",
    Port = 3000,
    UseHttps = false
})


serverTest:run()

log.save("./PS/mysandbox/", "log.txt")