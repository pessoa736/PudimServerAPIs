local openssl = require("openssl")
local utils = require("PS.utils")
local log = _G.log or require("loglua")

local TSL = {}

function TSL.ensure(dir, DNS, IPs)
  local TL = log.inSection("TSL")

  TL.debug("init ensure TSL")

  local keyPath = dir .. "/server.key"
  local crtPath = dir .. "/server.crt"

  if utils:checkFilesExist(keyPath) and utils:checkFilesExist(crtPath) then
    TL.debug("already exist, skipping generation")
    return keyPath, crtPath
  end

  utils:mkdir(dir)
  TL.debug("directory checked/created: " .. dir)

  -- 1) gerar chave privada
  local key_obj = assert(openssl.pkey.new({ type = "rsa", bits = 4096 }))
  TL.debug("private key generated")

  local key_pem = assert(key_obj:export("pem"))
  TL.debug("private key exported to PEM")

  -- 2) criar objeto de certificado
  local cert_obj = openssl.x509.new()
  TL.debug("x509 certificate object created")

  -- 3) definir propriedades básicas
  cert_obj:set("version", 2)
  cert_obj:set("serialNumber", tostring(os.time()))
  TL.debug("set version=2 (X.509 v3) and serial number")

  -- 4) definir subject
  local subject = {
    commonName = DNS or "localhost",
    organizationName = "PudimServer",
    countryName = "BR"
  }
  cert_obj:set("subject", subject)
  TL.debug("subject set: CN=" .. subject.commonName)

  -- 5) issuer = subject (autoassinado)
  cert_obj:set("issuer", cert_obj:get("subject"))
  TL.debug("issuer set (self-signed)")

  -- 6) validade
  cert_obj:set("notBefore", os.time())
  cert_obj:set("notAfter", os.time() + 365 * 24 * 60 * 60)
  TL.debug("validity period set (1 year)")

  -- 7) chave pública
  cert_obj:set("publicKey", key_obj:get_public())
  TL.debug("public key associated with certificate")

  -- 8) assinar certificado
  cert_obj:sign(key_obj, "sha256")
  TL.debug("certificate signed with private key (sha256)")

  -- 9) exportar certificado PEM
  local crt_pem = assert(cert_obj:export("pem"))
  TL.debug("certificate exported to PEM")

  -- 10) gravar arquivos
  local f = assert(io.open(keyPath, "w"))
  f:write(key_pem)
  f:close()
  TL.debug("server.key saved at: " .. keyPath)

  local c = assert(io.open(crtPath, "w"))
  c:write(crt_pem)
  c:close()
  TL.debug("server.crt saved at: " .. crtPath)

  TL.debug("TSL generation completed successfully")

  return keyPath, crtPath
end

return TSL