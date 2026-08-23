local api = require "luci.nodepool.api"
api.set_default_cbi()

m = Map()

m:appendTemplate("/node_list/converter")

return api.return_map(m)
