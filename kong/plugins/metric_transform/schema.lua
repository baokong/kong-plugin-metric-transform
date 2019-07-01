local typedefs = require"kong.db.schema.typedefs"

return {

  no_consumer = false, -- this plugin is available on APIs as well as on Consumers,
  name = "metric-transform",
  fields = {
    -- Describe your plugin's configuration's schema here.
	{ run_on = typedefs.run_on_first },    
  },
  self_check = function(schema, plugin_t, dao, is_updating)
    -- perform any custom verification
    return true
  end
}
