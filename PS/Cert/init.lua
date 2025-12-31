local scriptDir = debug.getinfo(1, "S").source:match("@(.*/)") or "./"

if not _G.log then _G.log = require("loglua") end
local openssl = require("openssl")

local Cert = {}

function Cert:CreateKey(keyCfg)
    keyCfg = keyCfg or { type="rsa", bits=4096 }
    
    local CK = log.inSection("Create Key Certificate")

    local pkey = openssl.pkey.new(keyCfg)

    CK.debug("create pkey", pkey)

    -- exporta para PEM
    local key_pem = pkey:export("pem")
    CK.debug("pkey exported to PEM", key_pem)

    local f = assert(io.open(scriptDir.."server.key","w"))
    CK.debug("saving Server.key")
    f:write(key_pem)
    f:close()

    return pkey
end

function Cert:CreateCertificate(subjectCfg, keyCfg)
    local subjectCfg = subjectCfg or {
        CN = "pudim.local",
        C  = "BR",
        ST = "RN",
    }

    local pkey = self:CreateKey(keyCfg)
    local x509 = openssl.x509.new()

    x509:set_version(2)                 
    x509:set_serial(os.time())          

    x509:set_subject_name(subjectCfg)
    x509:set_issuer_name(subjectCfg)
    x509:set_pubkey(pkey)

    x509:set_not_before(os.time())
    x509:set_not_after(os.time() + 365*24*60*60)

    x509:sign(pkey, "sha256")

    local cert_pem = x509:export("pem")
    local f = assert(io.open(scriptDir.."server.crt","w"))
    f:write(cert_pem)
    f:close()
end



return Cert