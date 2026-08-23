local api = require "luci.nodepool.api"
api.set_default_cbi()
m = Map()
return api.return_map(m)
