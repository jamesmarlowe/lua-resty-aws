local http = require "resty.http"
local insert = table.insert
local concat = table.concat
local sort = table.sort

local ok, new_tab = pcall(require, "table.new")
if not ok then
    new_tab = function (narr, nrec) return {} end
end

local _M = new_tab(0, 155)
_M._VERSION = '0.01'
_M._USER_AGENT = "lua-resty-aws/" .. _M._VERSION .. " (Lua) ngx_lua/" .. ngx.config.ngx_lua_version


local function request_uri(_uri, _params, _event_type)
    local httpc = http.new()
    httpc:set_timeout(60000)
    local res, err = httpc:request_uri(_uri, _params)
    if err then
        ngx.log(ngx.ERR, err)
        httpc:set_keepalive(1000,1000)
        httpc:close()
    else
        if (res.status < 200 or res.status > 299) then
            ngx.log(ngx.ERR, res.status..":".._event_type)
            ngx.log(ngx.ERR, res.body)
        else
            ngx.log(ngx.INFO, res.status..":".._event_type)
        end
        ngx.log(ngx.INFO, res.headers["x-amzn-RequestId"]) -- UUID
        ngx.log(ngx.INFO, res.body)
    end
    return err == nil
end


local function header_concat(headers, delimiter)
    local t = {}
    for k,v in pairs(headers) do
        insert(t,k..":"..v)
    end
    sort(t)
    return concat(t,delimiter)
end


local function header_list(headers)
    local t = {}
    for k,v in pairs(headers) do
        insert(t,k)
    end
    sort(t)
    return concat(t,";")
end


function _M.request(_rest_information)
    local _newline = string.char(10)
    local _date = ngx.utctime():gsub("%p",""):gsub(" ","T").."Z" -- form: 20130315T092054Z
    local _day = _date:sub(1,8)
    local _endpoint = "https://".._rest_information.host
    local _algorithm = "AWS4-HMAC-SHA256"
    local _api_name = "aws4_request"
    local _credential_scope = table.concat({_day,_rest_information.region,_rest_information.service,_api_name},"/")
    local _headers_c = header_concat(_rest_information.headers,_newline)
    local _signed_headers = header_list(_rest_information.headers)
    local sha256 = resty_sha256:new()
    sha256:update(_rest_information.body)
    local _payload_hash = str.to_hex(sha256:final())
    
    -- canonical_request
    local _canonical_request = table.concat({_rest_information.method,_rest_information.resource,_rest_information.query,_headers_c,'',_signed_headers,_payload_hash}, _newline)
    ngx.log(ngx.INFO, _canonical_request)
    
    -- string_to_sign
    local sha256 = resty_sha256:new()
    sha256:update(_canonical_request)
    local _string_to_sign = table.concat({_algorithm,_date,_credential_scope,str.to_hex(sha256:final())}, _newline)
    ngx.log(ngx.INFO, _string_to_sign)
    
    -- authentication
    local _signing_date = crypto_hmac.digest("sha256",_day,"AWS4".._rest_information.key, true)
    local _signing_region = crypto_hmac.digest("sha256",_rest_information.region,_signing_date, true)
    local _signing_service = crypto_hmac.digest("sha256",_rest_information.service,_signing_region, true)
    local _signing_key = crypto_hmac.digest("sha256",_api_name,_signing_service, true)
    local _signature = str.to_hex(crypto_hmac.digest("sha256",_string_to_sign,_signing_key, true)):lower()
    local _credential = _rest_information.id.."/".._credential_scope
    local _auth = _algorithm.." Credential=".._credential..", SignedHeaders=".._signed_headers..", Signature=".._signature
    _rest_information.headers["authorization"] = _auth
    
    -- uri request parameters
    local _params = {
            ssl_verify = false,
            method = _rest_information.method,
            body = _rest_information.body,
            headers = _rest_information.headers
        }
    ngx.log(ngx.INFO, cjson.encode(_params))
    return request_uri(_endpoint.._rest_information.resource, _params, _rest_information.event_type)
end


return _M
