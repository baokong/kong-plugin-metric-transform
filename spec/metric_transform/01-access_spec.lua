local helpers = require "spec.helpers"
local cjson = require('cjson')

local PLUGIN_NAME = "metric-transform"

for _, strategy in helpers.each_strategy() do
    describe("Plugin: metric-transform", function ()
        local client

        setup(function()
            local service = bp.services:insert {
                name = "rl-service",
                host = "138.68.29.156",
                protocol = "http",
                port = 4000,
                path = "/random_length"
            }

            local route1 = bp.routes:insert {
                hosts = { "test.com" },
                service = { id = service.id }
            }

            assert(bp.plugins:insert {
                route = { id = route1.id },
                name = "metric_transform"
            })

            assert(helpers.start_kong({
                plugins = "bundled," .. PLUGIN_NAME
            }))

            admin_client = helpers.admin_ssl_client()

        end)

        teardown(function()
            if admin_client then
                admin_client:close()
            end

            helpers.stop_kong()
        end)

        before_each(function()
            proxy_client = helpers.proxy_client()
        end)

        after_each(function()
            if proxy_client then
                proxy_client.close()
            end
        end)

        describe("transformer", function()
            it("should transform length unit to metric", function()
                -- send requests through Kong
                local res = assert(proxy_client:send {
                    method="GET",
                    headers = {
                        host="test.com"
                    }
                })

                assert.response(res).has.status(200)
                -- body is a string containing the response
                local json = assert.response(r).has.jsonbody()
                assert.is.True(json.data)
                assert.is.True(json.data.value)
                assert.are.equal(json.data.unit, "m")
            end)
        end)
    end)
end
