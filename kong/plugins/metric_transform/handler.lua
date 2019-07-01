-- If you're not sure your plugin is executing, uncomment the line below and restart Kong
-- then it will throw an error which indicates the plugin is being loaded at least.

--assert(ngx.get_phase() == "timer", "The world is coming to an end!")

local cjson = require "cjson"

-- Grab pluginname from module name
local plugin_name = "metric-transform"

-- load the base plugin object and create a subclass
local MetricTransformHandler = require("kong.plugins.base_plugin"):extend()

-- constructor
function MetricTransformHandler:new()
  MetricTransformHandler.super.new(self, plugin_name)

  -- do initialization here, runs in the 'init_by_lua_block', before worker processes are forked

end

function MetricTransformHandler:header_filter(conf)
  MetricTransformHandler.super.header_filter(self)

end

---------------------------------------------------------------------------------------------
-- In the code below, just remove the opening brackets; `[[` to enable a specific handler
--
-- The handlers are based on the OpenResty handlers, see the OpenResty docs for details
-- on when exactly they are invoked and what limitations each handler has.
--
-- The call to `.super.xxx(self)` is a call to the base_plugin, which does nothing, except logging
-- that the specific handler was executed.
---------------------------------------------------------------------------------------------


--[[ handles more initialization, but AFTER the worker process has been forked/created.
-- It runs in the 'init_worker_by_lua_block'
function plugin:init_worker()
  plugin.super.init_worker(self)

  -- your custom code here

end --]]

--[[ runs in the ssl_certificate_by_lua_block handler
function plugin:certificate(plugin_conf)
  plugin.super.certificate(self)

  -- your custom code here

end --]]

--[[ runs in the 'rewrite_by_lua_block' (from version 0.10.2+)
-- IMPORTANT: during the `rewrite` phase neither the `api` nor the `consumer` will have
-- been identified, hence this handler will only be executed if the plugin is
-- configured as a global plugin!
function plugin:rewrite(plugin_conf)
  plugin.super.rewrite(self)

  -- your custom code here

end --]]

local MULTIPLIER = {
  ["km"] = 1 / 1000,
  ["hm"] = 1 / 100,
  ["dam"] = 1 / 10,
  ["m"] = 1,
  ["dm"] =  10,
  ["cm"] = 100,
  ["mm"] = 1000
}

---[[ runs in the 'access_by_lua_block'
function MetricTransformHandler:access(plugin_conf)
  MetricTransformHandler.super.access(self)

  -- your custom code here
  ngx.req.set_header("Hello-World", "this is on a request")

end --]]

---[[ runs in the 'header_filter_by_lua_block'
function MetricTransformHandler:header_filter(plugin_conf)
  MetricTransformHandler.super.header_filter(self)

  -- your custom code here, for example;
  ngx.header["Bye-World"] = "this is on the response"

end --]]

-- TODO: Upstream's response not correct to the format of the plugin
local function upstream_error(msg, body)

end

-- TODO: Return boolean whether json is up to format
local function check_format()
  return true
end

-- Transforms unit length into meters from any
-- metric length measurement.
local function transform_json_body(buffered_data)
  if buffered_data == nil then
    return
  end

  local json_data = cjson.decode(buffered_data)
  if not json_data or not check_format(json_data) then
    return upstream_error('Upstream formatting incorrect', buffered_data)
  end

  local len, unit = json_data.data.value, json_data.data.metric
  json_data.data[unit] = "m"
  json_data.data[len] = len * MULTIPLIER[unit]

  return cjson.encode(json_data)
end

-- This stage takes into buffer chunks from upstream response
function MetricTransformHandler:body_filter(plugin_conf)
  MetricTransformHandler.super.body_filter(self)

  local ctx = ngx.ctx
  local chunk, eof = ngx.arg[1], ngx.arg[2]

  ctx.rt_body_chunks = ctx.rt_body_chunks or {}
  ctx.rt_body_chunk_i = ctx.rt_body_chunk_i or 1

  if eof then
    local chunks = table.concat(ctx.rt_body_chunks)
    local body = transform_json_body(chunks)
    ngx.arg[1] = body or chunks
  else
    ctx.rt_body_chunks[rt_body_chunk_i] = chunk
    ctx.rt_body_chunk_i = ctx.rt_body_chunk_i + 1
    ngx.arg[1] = nil  -- Reset input stream content
  end
end

--[[ runs in the 'log_by_lua_block'
function plugin:log(plugin_conf)
  plugin.super.log(self)

  -- your custom code here

end --]]


-- set the plugin priority, which determines plugin execution order
MetricTransformHandler.PRIORITY = 1000

-- return our plugin object
return MetricTransformHandler
