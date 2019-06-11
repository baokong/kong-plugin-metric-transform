return {
  no_consumer = false, -- this plugin is available on APIs as well as on Consumers,
  name = "metric_transform",
  fields = {
    -- Describe your plugin's configuration's schema here.
    
  },
  self_check = function(schema, plugin_t, dao, is_updating)
    -- perform any custom verification
    return true
  end
}
