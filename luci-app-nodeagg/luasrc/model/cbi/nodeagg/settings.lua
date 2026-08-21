local m, s, o

m = Map("nodeagg", translate("聚合"))

s = m:section(TypedSection, "nodeagg")
s.anonymous = true
s.addremove = false

o = s:option(Flag, "enabled", translate("启用"))
o.default = 0
o.rmempty = false

o = s:option(DummyValue, "agg_url_display", " ")
o.rawhtml = true
o.cfgvalue = function(self, section)
	local url = m.uci:get("nodeagg", section, "agg_url") or "http://192.168.2.30/nodeagg.txt"
	return '<div class="cbi-value"><label class="cbi-value-title">' .. translate("聚合地址") .. '</label><div class="cbi-value-field"><input type="text" id="nodeagg_agg_url" value="' .. url .. '" readonly style="width:300px;" /> <input type="button" class="cbi-button" value="' .. translate("复制") .. '" onclick="var u=document.getElementById(\'nodeagg_agg_url\').value;navigator.clipboard.writeText(u).then(function(){alert(\'已复制: \'+u)})" /></div></div>'
end

return m
