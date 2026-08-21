local m, s, o

m = Map("nodeagg", translate("聚合"))

s = m:section(TypedSection, "nodeagg")
s.anonymous = true
s.addremove = false

o = s:option(Flag, "enabled", translate("启用"))
o.default = 0
o.rmempty = false

o = s:option(Value, "agg_url", translate("聚合地址"))
o.readonly = true
o.placeholder = "http://192.168.2.30:8080/nodeagg.txt"

o = s:option(Button, "_copy", translate("复制地址"))
o.inputstyle = "reset"
o.inputtitle = translate("复制")
o.onclick = function(self)
	local url = m.uci:get("nodeagg", "@nodeagg[0]", "agg_url") or ""
	luci.http.prepare_content("text/plain")
	luci.http.write(url)
end

return m
