local m, s, o

m = Map("nodeagg", translate("节点聚合"))

-- 聚合
s = m:section(TypedSection, "nodeagg", translate("聚合"))
s.anonymous = true
s.addremove = false

o = s:option(Flag, "enabled", translate("启用"))
o.default = 0
o.rmempty = false

o = s:option(Value, "agg_url", translate("聚合地址"))
o.readonly = true
o.placeholder = "http://192.168.2.30:8080/nodeagg"

return m
