local m, s, o

m = Map("nodeagg", translate("节点列表"),
	translate("管理所有聚合节点"))

s = m:section(TypedSection, "nodeagg")
s.anonymous = true
s.addremove = false

o = s:option(Flag, "enabled", translate("启用"))
o.default = 0
o.rmempty = false

return m
