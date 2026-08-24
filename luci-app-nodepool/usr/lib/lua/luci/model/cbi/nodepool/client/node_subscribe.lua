local api = require "luci.nodepool.api"
api.set_default_cbi()

m = Map()

m:appendTemplate("/node_subscribe/tpl_editor")

return api.return_map(m)
