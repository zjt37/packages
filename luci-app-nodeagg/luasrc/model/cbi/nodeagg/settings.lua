local m, s, o

m = Map("nodeagg", translate("聚合"))

s = m:section(TypedSection, "nodeagg")
s.anonymous = true
s.addremove = false

o = s:option(Flag, "enabled", translate("启用"))
o.default = 0
o.rmempty = false

s2 = m:section(TypedSection, "nodeagg")
s2.anonymous = true
s2.addremove = false
s2.template = "nodeagg/agg_url_row"

return m
