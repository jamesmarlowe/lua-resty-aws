-- USE an IAM User with limited access
-- example:
-- "Action": [
--   "firehose:PutRecord",
--   "firehost:PutRecordBatch"
-- ],
-- "Resource": [
--   "arn:aws:firehose:us-east-1:<accountid>:deliverystream/<streamname>"
-- ]

local aws = require "resty.aws"
local request = aws.request
local default_batch_size = 499

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


-- takes a table of event_information to send in the event to kinesis firehose
-- keeps a table of the stream data to batch together
-- required parameters:
-- stream_name (the kinesis stream name)
-- stream_data (the data you wish to send)
-- partition_key (input to a hash function that maps data to a specific shard)
function _M.put_batch(self, _event_information, _batch_size)
    if not _batch_size then _batch_size = default_batch_size end
    if not self.batch[_event_information.stream_name] then
        self.batch[_event_information.stream_name] = {} 
    end
    local _batch_length = #(self.batch[_event_information.stream_name])+1
    self.batch[_event_information.stream_name][_batch_length] = _event_information.stream_data
    if _batch_length >= _batch_size then
        _M.put_record(self, _event_information, true)
    end
end


-- takes a table of event_information to send in the event to kinesis firehose
-- required parameters:
-- stream_name (the kinesis stream name)
-- stream_data (the data you wish to send)
-- partition_key (input to a hash function that maps data to a specific shard)
function _M.put_record(self, _event_information, _batch) -- batch pattern ie. %Z+ for null delimited
    local _date = ngx.utctime():gsub(" ","T").."Z"
    local _method = "POST"
    local _body = {
            ['DeliveryStreamName'] = _event_information.stream_name
        }
    if _batch then
        _body['Records'] = {}
        for _,_data in pairs(self.batch[_event_information.stream_name]) do
            _body['Records'][#_body['Records']+1]={['Data'] = ngx.encode_base64(_data..string.char(10))}
        end
        self.batch[_event_information.stream_name] = {}
    else
        _body['Record'] = {
                ['Data'] = ngx.encode_base64(_event_information.stream_data..string.char(10)),
            }
    end
    _body = cjson.encode(_body)
    local _accept = "application/hal+json"
    local _content_type = "application/x-amz-json-1.1"
    local _resource = "/"
    local _query = '' -- there are no query args
    local _host = "firehose.us-east-1.amazonaws.com"
    local _service = "firehose"
    local _target_prefix = "Firehose_20150804"
    local _action = _batch and "PutRecordBatch" or "PutRecord"
    local _target = table.concat({_target_prefix,_action},".")
    local _headers = {
              ["accept"] = _accept,
              ["content-type"] = _content_type,
              ["host"] = _host,
              ["x-amz-target"] = _target,
              ["user-agent"] = _M._USER_AGENT,
              ["x-amz-date"] = _date,
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
        event_type = _target,
    }
    
    return request(_rest_information)
end

return _M
