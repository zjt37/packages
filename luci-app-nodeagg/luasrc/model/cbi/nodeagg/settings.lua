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
o.placeholder = "http://192.168.2.30/nodeagg.txt"

o = s:option(DummyValue, "_copy", " ")
o.rawhtml = true
o.cfgvalue = function(self, section)
	local url = m.uci:get("nodeagg", section, "agg_url") or ""
	return '<input type="button" class="cbi-button" style="background-color:#2196F3 !important;color:white !important;border-color:#1976D2 !important;" value="' .. translate("复制") .. '" onclick="var u=document.querySelector(\'[id$=_agg_url]\').value;navigator.clipboard.writeText(u).then(function(){alert(\'已复制: \'+u)})" />'
end

return m
