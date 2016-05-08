Name
====

lua-resty-aws - Make Authenticated AWS Rest API Requests

Table of Contents
=================

* [Name](#name)
* [Status](#status)
* [Description](#description)
* [Synopsis](#synopsis)
* [Modules](#modules)
    * [new](#new)
    * [mobileanalytics](#mobileanalytics)
    * [kinesisfirehose](#kinesisfirehose)
* [Limitations](#limitations)
* [Installation](#installation)
* [TODO](#todo)
* [Author](#author)
* [Copyright and License](#copyright-and-license)
* [See Also](#see-also)

Status
======

This library is still under early development and considered experimental.

Description
===========

This Lua library handles communicating with the amazon REST api endpoints. With it you can make signed requests to the Amazon APIs much more easily.

Synopsis
========

```
    lua_package_path "/path/to/lua-resty-aws/lib/?.lua;;";
    
    server {
        location /aws/mobile_analytics {
            content_by_lua_block {
                local aws = require "resty.aws"
                local aws, err = aws:new("aws-id", "aws-key")
                
            }
        }
    }
```

[Back to TOC](#table-of-contents)

Modules
=======

Each module contains a `new` function that initializes it.

All of the commands return either something that evaluates to true on success, or `nil` and an error message on failure.

new
---
`syntax: module, err = module:new(id, key, region)`

Creates an uploading object. In case of failures, returns `nil` and a string describing the error.

[Back to TOC](#table-of-contents)

mobileanalytics
---------------
```lua
local mobile_analytics = require "resty.mobile_analytics"
local ma, err = mobile_analytics:new("id", "key", "[region]")
local event_information = {
        client_id = "TEST-TEST-TEST-TEST",
        mobile_analytics_app_id = "testtesttesttesttest",
        event_type = "LevelComplete",
        session_id = "TEST-TEST-TEST-TEST",
    }
local ok, err = ma:record(event_information)
```

Send an event to mobile analytics for tracking.

[Back to TOC](#table-of-contents)

kinesisfirehose
---------------
```lua
local kinesis_firehose = require "resty.kinesis_firehose"
local fh, err = kinesis_firehose:new("id", "key", "[region]")
local event_information = {
        stream_name = "TEST",
        stream_data = "testtesttesttesttest",
        partition_key = "TESTTEST",
    }
local ok, err = fh:put_record(event_information)
```

Send an event to kinesis firehose.

[Back to TOC](#table-of-contents)



Limitations
===========
* only has support for very few aws apis currently


[Back to TOC](#table-of-contents)

Installation
============
You can install it with luarocks `luarocks install lua-resty-aws`

Otherwise you need to configure the lua_package_path directive to add the path of your lua-resty-aws source to ngx_lua's LUA_PATH search path, as in

```nginx
    # nginx.conf
    http {
        lua_package_path "/path/to/lua-resty-aws/lib/?.lua;;";
        ...
    }
```

This package also requires the lua-resty-http package to be installed (https://github.com/pintsized/lua-resty-http)

Ensure that the system account running your Nginx ''worker'' proceses have
enough permission to read the `.lua` file.

[Back to TOC](#table-of-contents)

TODO
====



[Back to TOC](#table-of-contents)

Author
======

James Marlowe "jamesmarlowe" <jameskmarlowe@gmail.com>, Lumate LLC.

[Back to TOC](#table-of-contents)

Copyright and License
=====================

This module is licensed under the BSD license.

Copyright (C) 2012-2014, by James Marlowe (jamesmarlowe) <jameskmarlowe@gmail.com>, Lumate LLC.

All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice, this
  list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright notice,
  this list of conditions and the following disclaimer in the documentation
  and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

[Back to TOC](#table-of-contents)

See Also
========
* the ngx_lua module: http://wiki.nginx.org/HttpLuaModule
* the [lua-resty-hmac](https://github.com/jamesmarlowe/lua-resty-hmac) library

[Back to TOC](#table-of-contents)
