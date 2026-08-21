local m, s, o
local section = luci.dispatcher.context.route_match

m = Map("nodeagg", translate("节点订阅"))

s = m:section(NamedSection, section, "subscribe_list")
s.anonymous = true
s.addremove = false

o = s:option(Value, "remark", translate("备注"))
o.rmempty = false

o = s:option(Value, "url", translate("订阅地址"))
o.rmempty = false

return m
