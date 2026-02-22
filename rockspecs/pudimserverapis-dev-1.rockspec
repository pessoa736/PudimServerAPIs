package = "PudimServerAPIs"
version = "dev-1"
source = {
   url = "git+https://github.com/pessoa736/PudimServerAPIs.git"
}
description = {
   summary = "Create simple, lightweight and customizable HTTP servers",
   detailed = "Create simple, lightweight and customizable HTTP servers",
   homepage = "https://github.com/pessoa736/PudimServerAPIs",
   license = "*** please specify a license ***"
}
dependencies = {
   queries = {}
}
build_dependencies = {
   queries = {}
}
build = {
   type = "builtin",
   modules = {
      ["PudimServer.ServerChecks"] = "PudimServer/ServerChecks.lua",
      ["PudimServer.http"] = "PudimServer/http.lua",
      ["PudimServer.init"] = "PudimServer/init.lua",
      ["PudimServer.mysandbox.test"] = "PudimServer/mysandbox/test.lua",
      ["PudimServer.utils"] = "PudimServer/utils.lua"
   }
}
test_dependencies = {
   queries = {}
}
