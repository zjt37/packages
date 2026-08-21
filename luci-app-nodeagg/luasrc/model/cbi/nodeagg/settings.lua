local m, s, o

m = Map("nodeagg", translate("节点聚合"),
	translate("节点聚合与订阅转换"))

s = m:section(TypedSection, "nodeagg")
s.anonymous = true
s.addremove = false

o = s:option(Flag, "enabled", translate("启用"))
o.default = 0
o.rmempty = false

return m
