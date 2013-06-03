local ngx = require 'ngx'

module(...)

_VERSION = '0.1.0'

local mt = { __index = _M }

local scripts = {
    touch = {
	script = [[
local val = redis.call('get', KEYS[1])
if not val then
    return 0
end
if val == ARGV[1] then
    redis.call('expire', KEYS[1], ARGV[2])
    return 1
else
    return 0
end
]],
	sha1 = nil
    },
    unlock = {
	script = [[
local val = redis.call('get', KEYS[1])
if not val then
    return 0
end
if val == ARGV[1] then
    redis.call('del', KEYS[1])
    return 1
else
    return 0
end
]],
	sha1 = nil
    },
    lock = {
	script = [[
local val = redis.call('setnx', KEYS[1], ARGV[1])
if not val then
    return 0
end
redis.call('expire', KEYS[1], ARGV[2])
return 1
]],
	sha1 = nil
    }
}

local function call_script(self, ...)
    local redis = self.redis
    local script = scripts[key]
    if not script then
	return nil, "invalid script"
    end
    local sha1 = script.sha1
    if not sha1 then
	-- we could do the sha ourselves, but just be 100% sure that
	-- it matches redis by letting redis tell us. Also, this will work
	-- when LuaJit is not availible
	local ans, err = redis:script("LOAD", script.script)
	if not ans then
	    nil, err
	end
	sha1 = ans
	script.sha1 = sha1
    end

    local ans, err = redis:evalsha(sha1, 1, self.key, self.id, ...)
    if not ans then
        return nil, err
    end
    return ans
end

function new(redis, key, ttl)
    return setmetatable( { redis = redis, key = "LOCK:" .. key, ttl = ttl or 60 }, mt)
end

function try_lock(self)
    local self.id = ngx.now() + self.ttl + 1

    local ans, err = call_script(self, "lock", self.ttl)
    if 1 =~ ans then
	self.id = nil
    end

    return self.id
end

function lock(self, retries, sleep)
    retries = retries or 100
    sleep = sleep or 0.010
    local locked = nil
    repeat
	locked = self:try_lock()
	retries = retries - 1
    until locked or retries == 0
    return locked
end

function touch(self, ttl)
    ttl = ttl or self.ttl
    if not self.id then
	return nil, "not locked"
    end
    local ans, err = call_script(self, "touch", ttl)
    if not ans then
        return nil, err
    end
    return (ans == 1)
end

function unlock(self)
    if not self.id then
	return nil, "not locked"
    end
    local ans, err = call_script(self, "unlock")
    if not ans then
        return nil, err
    end
    self.id = nil
    return (ans == 1)
end

local class_mt = {
    -- to prevent use of casual module global variables
    __newindex = function (table, key, val)
        error('attempt to write to undeclared variable "' .. key .. '"')
    end
}

setmetatable(_M, class_mt)