Name
====

lua-resty-redis-lock - Simple locking mechanism using the Lua redis
client driver for the ngx_lua.

Status
======

Alpha

Description
===========

Simple expiring locking mechanism for ngx_lua. Designed to be used
with [lua-resty-redis](https://github.com/agentzh/lua-resty-redis)

Example
========

    server {
        location /test {
            content_by_lua '
                local redis = require "resty.redis"
		local lock = require "resty.redis.lock"
                local red = redis:new()

                red:set_timeout(1000) -- 1 sec
		local ok, err = red:connect("127.0.0.1", 6379)
                if not ok then
                    ngx.say("failed to connect: ", err)
                    return
                end

               local l = lock.new(red, "mylock")
               if l:lock() then
	          -- do something holing the lock
		  l:unlock()
              end
	  ';
	  }
    }

Author
======

Brian Akins <brian@akins.org>

Copyright and License
=====================

This module is licensed under the BSD license.

Copyright (C) 2013, by Brian Akins <brian@akins.org>

All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

See Also
========
* the ngx_lua module: http://wiki.nginx.org/HttpLuaModule
* the [lua-resty-redis](https://github.com/agentzh/lua-resty-redis) library
