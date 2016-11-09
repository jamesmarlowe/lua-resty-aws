-- USE an IAM User with limited access
-- example:
-- "Action": [
--     "s3:PutObject"
-- ],
-- "Resource": [
--     "arn:aws:s3:::*"
-- ]

local aws = require "resty.aws"
local request = aws.request
local default_batch_size = 20000
local concat = table.concat
local uuid = require 'resty.jit-uuid' -- https://github.com/thibaultcha/lua-resty-jit-uuid
uuid.seed() -- very important!
local zlib = require "zlib" -- https://github.com/LuaDist/lzlib
local deflate = zlib.deflate

local ok, new_tab = pcall(require, "table.new")
if not ok then
    new_tab = function (narr, nrec) return {} end
end

local _M = new_tab(0, 155)
_M._VERSION = '0.01'
_M._USER_AGENT = "lua-resty-aws/" .. _M._VERSION .. " (Lua) ngx_lua/" .. ngx.config.ngx_lua_version

local mt = { __index = _M }


function _M.new(self, id, key, region)
    local id, key, region = id, key, region
    
    if not id then
        return nil, "must provide id"
    end
    if not key then
        return nil, "must provide key"
    end
    if not region then
        region = "us-east-1"
    end
    
    return setmetatable({id = id,key = key,region = region,batch = {}}, mt)
end


-- takes a table of event_information to send in the s3 bucket
-- keeps a table of the stream data to batch together
-- required parameters:
-- bucket_name (the s3 bucket name)
-- stream_data (the data you wish to send)
function _M.put_batch(self, _event_information, _batch_size)
    if not _batch_size then _batch_size = default_batch_size end
    if not self.batch[_event_information.bucket_name] then
        self.batch[_event_information.bucket_name] = {} 
    end
    local _batch_length = #(self.batch[_event_information.bucket_name])+1
    self.batch[_event_information.bucket_name][_batch_length] = _event_information.stream_data
    if _batch_length >= _batch_size then
        _M.put_record(self, _event_information, true)
    end
end


-- takes a table of event_information to send in the s3 bucket
-- required parameters:
-- bucket_name (the s3 bucket name)
-- stream_data (the data you wish to send)
-- optional parameters:
-- bucket_date (boolean if date should be used to bucket and name the upload) default false
-- gzip_upload (boolean if upload should be gzipped) default false
-- file_name (string name of file or filename prefix if using bucket_date)
function _M.put_record(self, _event_information, _batch)
    local _utc = ngx.utctime()
    local _date = _utc:gsub("%p",""):gsub(" ","T").."Z"
    local _method = "PUT"
    
    local _body
    if _batch then
        _body = concat(self.batch[_event_information.bucket_name],string.char(10))
        self.batch[_event_information.bucket_name] = {}
    else
        _body = _event_information.stream_data
    end
    
    local _content_type = "application/octet-stream"
    local _resource
    if _event_information.bucket_date then
        local _date_file_name = (_event_information.file_name or "data").."-".._utc:gsub("[%p,%s]","-").."-"..uuid()
        _resource = "/".._utc:gsub("[%p,%s]","/"):sub(1,14).._date_file_name
    else
        local _body_md5 = ngx.md5(_body)
        _resource = "/"..(_event_information.file_name or _body_md5)
    end
    
    if _event_information.gzip_upload then
        local buffer = {}
        local func = function(data)
               table.insert(buffer, data)
        end
        local stream = zlib.deflate(func, -1, nil, 15 + 16)
        stream:write(_body)
        stream:flush("finish")
        stream:close()
        _body = table.concat(buffer)
        _resource = _resource..".gz"
    end
    
    local sha256 = resty_sha256:new()
    sha256:update(_body)
    local _payload_hash = str.to_hex(sha256:final())
    
    local _query = '' -- there are no query args
    local _bucket = _event_information.bucket_name
    local _host = _bucket..".s3.amazonaws.com"
    local _service = "s3"
    local _event_type = "S3 Put Object"
    local _headers = {
              ["content-type"] = _content_type,
              ["host"] = _host,
              ["user-agent"] = _M._USER_AGENT,
              ["x-amz-date"] = _date,
              ["x-amz-content-sha256"] = _payload_hash,
            }
    
    local _rest_information = {
        id = self.id,
        key = self.key,
        host = _host,
        body = _body,
        query = _query,
        method = _method,
        region = self.region,
        headers = _headers,
        service = _service,
        resource = _resource,
        event_type = _event_type,
    }
    
    return request(_rest_information)
end

return _M
