local x509 = require("openssl").x509
local _x509_name = require("openssl").x509.name
local _x509_ext = require("openssl").x509.extension
local pkey = require("openssl").pkey


local utils = require("PS.utils")
local log = _G.log or require("loglua")


--- interfaces

---@class EnsureCAParams
---@field dir string Diretório para salvar os certificados

local EnsureCAParamsInter = utils:createInterface({
    dir = "string"
})

---@class EnsureParams
---@field dir string Diretório para salvar os certificados
---@field DNSs string[]? Lista de domínios DNS
---@field IPs string[]? Lista de IPs

local EnsureParamsInter = utils:createInterface({
    dir = "string",
    DNSs = {"table", "nil"},
    IPs = {"table", "nil"}
})


---------
--- main

local TSL = {}





---@type fun(self: table, dir: string): any, any
function TSL:ensureCA(dir)
  local TL = log.inSection("TSL CA")
  local msid = 0 
  local function _msg(msg)
      utils:loadMessageOnChange("TLS-ensureCA" .. msid, msg, TL.debug)
      msid = msid + 1
  end
  
  utils:verifyTypes(
    {dir = dir},
    EnsureCAParamsInter,
    TL.error,
    true
  )
    
  _msg("init ensure TSL")
  
  local keyPath = dir .. "/ca.key"
  local crtPath = dir .. "/ca.crt"

  if utils:checkFilesExist(keyPath) and utils:checkFilesExist(crtPath) then
    _msg("already exist, skipping generation")
    local key = utils:getContentFile(keyPath)
    local crt = utils:getContentFile(crtPath)
    local caKey = pkey.read(key, true, "pem")
    local caCert = x509.read(crt)
    if caKey and caCert then
      return caKey, caCert
    end
    _msg("failed to read CA files, regenerating...")
    os.remove(keyPath)
    os.remove(crtPath)
  end

  utils:mkdir(dir)
  _msg("directory checked/created: " .. dir)


  local keyObj = pkey.new("ec", "prime256v1")
  _msg("private key _msgd")

  local key_pem = keyObj:export("pem", true)
  _msg("private key exported to PEM")

  local x509_obj = x509.new()
  _msg("x509 certificate object created")


  x509_obj:serial(tostring(os.time()))
  local subject = _x509_name.new{
    { CN = "pudim.local" } 
  }
  subject:add_entry("O", "DaviPassos")
  subject:add_entry("C", "BR")
  
  x509_obj:subject(subject)
  x509_obj:issuer(subject)

  _msg("issuer set (self-signed) for CA")

  x509_obj:notbefore(os.time())
  x509_obj:notafter(os.time() + 365 * 24 * 60 * 60)
  _msg("validity period set (1 year)")

  x509_obj:pubkey(keyObj:get_public())
  _msg("public key associated with certificate")



  local bc = _x509_ext.new_extension({
      object = "basicConstraints",
      critical = true,
      value = "CA:TRUE"
    }
  )

  local ku = _x509_ext.new_extension({
      object = "keyUsage",
      critical = true,
      value = "keyCertSign,cRLSign"
    }
  )


  
  x509_obj:extensions({bc, ku})
  _msg("defined extensions")

  x509_obj:sign(keyObj, x509_obj:subject(), "sha256")
  _msg("certificate signed with private key (sha256)")



  local crt_pem = x509_obj:export()
  _msg("certificate exported to PEM")



  utils:writeFile(keyPath, key_pem)
  _msg("ca.key saved at: " .. keyPath)

  utils:writeFile(crtPath, crt_pem)
  _msg("ca.crt saved at: " .. crtPath)

  _msg("TSL generation completed successfully")
  return keyObj, x509_obj
end


function TSL:createSan(DNSs, IPs)
  local config = {}
  for _, domain in ipairs(DNSs or {"localhost"}) do
    config[#config + 1] = ("DNS:%s"):format(domain)
  end
  for _, ip in ipairs(IPs or {"127.0.0.1"}) do
    config[#config + 1] = ("IP:%s"):format(ip)
  end

  return table.concat(config, ",")
end



function  TSL:ensure(dir, DNSs, IPs)
  local TL = log.inSection("TSL server")
  local msid = 0 
  local function _msg(msg)
      utils:loadMessageOnChange("TLS-ensure" .. msid, msg, TL.debug)
      msid = msid + 1
  end

  utils:verifyTypes(
    {dir = dir, DNSs = DNSs, IPs = IPs},
    EnsureParamsInter,
    TL.error,
    true
  )

  local caKey, caCert = self:ensureCA(dir)
  local caSubject = caCert:subject()
  _msg("get caKey and caCert")

  local key_obj = pkey.new("ec", "prime256v1")
  _msg("create server pkey ")

  local crt = x509.new()
  _msg("create server crt")

  local subject = _x509_name.new{{CN = "localhost"}}
    subject:add_entry("O","PudimServer")
    subject:add_entry("C","BR")


  crt:serial(tostring(os.time()))
  crt:subject(subject)
  crt:issuer(caSubject)
  crt:notbefore(os.time())
  crt:notafter(os.time()+365*24*60*60)
  crt:pubkey(key_obj:get_public())


  local bc = _x509_ext.new_extension({
      object = "basicConstraints",
      critical = true,
      value = "CA:FALSE"
    }
  )
  local ku = _x509_ext.new_extension({
      object = "keyUsage",
      critical = true,
      value = "digitalSignature,keyEncipherment"
    }
  )

  local eku = _x509_ext.new_extension({
      object = "extendedKeyUsage",
      critical = true,
      value = "serverAuth"
    }
  )

  local san = _x509_ext.new_extension({
      object = "subjectAltName",
      value =  self:createSan(DNSs, IPs)
    }
  )


  crt:extensions({bc, ku, eku, san})
  _msg("defined extensions")

  crt:sign(caKey, caCert, "sha256")

  local keyPath = dir .. "/server.key"
  local crtPath = dir .. "/server.crt"

  utils:writeFile(keyPath, key_obj:export("pem"))
  utils:writeFile(crtPath, crt:export("pem"))

  return keyPath, crtPath
end


return TSL