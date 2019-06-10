local helpers = require "spec.helpers"
local cjson = require('cjson')

local PLUGIN_NAME = ({...})[1]:match("^kong%.plugins%.([^%.]+)")

for _, strategy in helpers.each_strategy() do
  describe("Metric transform tests", function ()
    local bp = helpers.get_db_utils(strategy)

    setup(function()
      local service = bp.services:insert {
        name = "rl-service",
        host = "random_length_address"
      }
    end)

    bp.routes:insert({
      hosts = { "test.com" },
      service = { id = service.id }
    })

    assert(helpers.start_kong({
      plugins = "bundled,".. PLUGIN_NAME
    }))

    admin_client = helpers.admin_ssl_client()
  end)

  teardown(function()
    if admin_client then
      admin_client:close()
    end

    helpers.stop_kong()
  end)

  before_each(function ()
    proxy_client = helpers.proxy_client()
  end)

  after_each(function()
    if proxy_client then
      proxy_client.close()
    end
  end)
  
  describe("transformer", function ()
    it("should transform length unit to metric", function ()
      -- send requests through Kong
      local res = proxy_client:get("/get", {
        headers = {
          ["Host"] = "test.com"
        },

      })

      local body = assert.res_status(200, res)
      -- body is a string containing the response
      local json = cjson.decode(body)
      assert.is.True(json.data)
      assert.are.equal(json.data.value, 389000)
      assert.are.equal(json.data.unit, "m")
    end)
  end)
end
