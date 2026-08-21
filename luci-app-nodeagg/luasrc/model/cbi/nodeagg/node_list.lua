local api = require "luci.nodeagg.api"
api.set_default_cbi()

m = Map("nodeagg")
m.redirect = luci.dispatcher.build_url("admin", "services", "nodeagg", "node_list")

-- [[ Other Settings ]]--
s = m:section(TypedSection, "global_other")
s.anonymous = true

o = s:option(ListValue, "auto_detection_time", translate("自动检测延迟"))
o:value("0", translate("关闭"))
o:value("icmp", "Ping")
o:value("tcping", "TCP Ping")

o = s:option(Flag, "show_node_info", translate("显示服务器地址和端口"))
o.default = "0"

m:appendTemplate("nodeagg/node_list/node_list")

return m
