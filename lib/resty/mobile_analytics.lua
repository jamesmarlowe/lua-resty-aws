-- USE an IAM User with limited access

local aws = require "resty.aws"
local request = aws.request

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
    
    return setmetatable({id = id,key = key,region = region}, mt)
end


-- takes a table of event_information to send in the event to mobile analytics
-- required parameters:
-- client_id (GUID to link to this user)
-- mobile_analytics_app_id (app id from your mobile analytics dashboard)
-- event_type (what kind of event this is eg level-complete)
-- session_id (an identifier for the current session)
function _M.record(self, _event_information)
    local _date = ngx.utctime():gsub(" ","T").."Z"
    local _method = "POST"
    local _context = cjson.encode({
            client = {
                client_id = _event_information.client_id,
                app_title = _event_information.app_title,
                app_version_name = _event_information.app_version_name,
                app_version_code = _event_information.app_version_code,
                app_package_name = _event_information.app_package_name,
            },
            env = {
                -- Valid Platforms = iphoneos, android, windowsphone, blackberry, macos, windows, linux
                make   = _event_information.env_make,
                model  = _event_information.env_model,
                locale = _event_information.env_locale,
                platform = _event_information.env_platform,
                platform_version = _event_information.env_platform_version,
            },
            
            -- required (app id from your mobile analytics dashboard)
            services = {
                mobile_analytics = {
                    app_id = _event_information.mobile_analytics_app_id
                }
            }
        })
    local _body = cjson.encode({
        events = {
            {
                eventType = _event_information.event_type,
                timestamp = _date,
                version = "v2.0", -- AWS Mobile Analytics specific
                
                -- session is required
                session = {
                    id = _event_information.session_id, -- GUID to link to this "session"
                    startTimestamp = _event_information.session_start, -- form yyyy-mm-ddThh:mm:ssZ
                    stopTimestamp = _event_information.session_start,
                },
                
                -- must be strings (keys are pre-created in mobile analytics)
                attributes = _event_information.attributes,
                
                -- must be numbers (keys are pre-created in mobile analytics)
                metrics = _event_information.metrics,
            }
        }
    })
    local _accept = "application/hal+json"
    local _content_type = "application/json"
    local _resource = "/2014-06-05/events"
    local _query = '' -- there are no query args
    local _host = "mobileanalytics.us-east-1.amazonaws.com"
    local _service = "mobileanalytics"
    local _event_type = "Mobile Analytics"
    
    local _headers = {
            ["accept"] = _accept,
            ["content-type"] = _content_type,
            ["host"] = _host,
            ["x-amz-date"] = _date,
            ["user-agent"] = _M._USER_AGENT,
            ["x-amz-client-context"] = _context,
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
