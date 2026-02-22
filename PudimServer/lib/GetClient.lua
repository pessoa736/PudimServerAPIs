local socket<const> = require "socket"


---@param ServerRun table|userdata Socket do servidor
---@param Middlewares Middlewares[] Middlewares de socket
---@param httpsConfig? table Config HTTPS interna
---@return table client Conexão do cliente
---@return boolean ok Se o cliente foi obtido com sucesso
---@return string message Mensagem de status
return function (ServerRun, Middlewares, httpsConfig)
    local responseObject, responseCheck, responseMessage 
    local client, acceptErr<const> = ServerRun:accept()

    if not client then -- if not found
        responseCheck = false
        responseObject = {}
        
        if acceptErr == "timeout" then
            responseMessage = "waiting client"
            goto continue
        end

        responseMessage = "accept error: " .. tostring(acceptErr)
        goto continue
  end
  


    for idx, mw in ipairs(Middlewares) do --traveling Middlewares
        client = mw.Handler(client)
        if not client then
            responseObject, responseCheck, responseMessage = {}, false, "middleware " .. idx .. " returned nil"
            goto continue
        end
    end


  
    if not client then 
        responseMessage = "not found client" 
        goto continue
    end

    if httpsConfig then
        local secureClient, wrapErr = httpsConfig.ssl.wrap(client, httpsConfig.params)
        if not secureClient then
            client:close()
            responseObject, responseCheck, responseMessage = {}, false, "https wrap error: " .. tostring(wrapErr)
            goto continue
        end

        secureClient:settimeout(0)
        local start = socket.gettime()
        while true do
            local okHandshake, handshakeErr = secureClient:dohandshake()
            if okHandshake then
                break
            end

            if handshakeErr == "wantread" or handshakeErr == "wantwrite" or handshakeErr == "timeout" then
                if socket.gettime() - start > 10 then
                    secureClient:close()
                    responseObject, responseCheck, responseMessage =  {}, false, "https handshake timeout"
                    goto continue
                end
                socket.sleep(0.001)
            else
                secureClient:close()
                responseObject, responseCheck, responseMessage = {}, false, "https handshake error: " .. tostring(handshakeErr)
                goto continue
            end
        end

        client = secureClient
    end
  

  client:settimeout(10)


  responseObject, responseCheck, responseMessage = client, true, "Get Client"
  
  ::continue::
  print(responseObject, responseCheck, responseMessage)
  return responseObject, responseCheck, responseMessage
end