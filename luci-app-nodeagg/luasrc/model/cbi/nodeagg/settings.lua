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

o = s:option(DummyValue, "_script", " ")
o.rawhtml = true
o.cfgvalue = function(self, section)
	return '<script type="text/javascript">document.addEventListener("DOMContentLoaded",function(){var u=document.querySelector("[id$=_agg_url]");if(u){var b=document.createElement("input");b.type="button";b.className="cbi-button";b.value="' .. translate("复制") .. '";b.onclick=function(){navigator.clipboard.writeText(u.value).then(function(){alert("' .. translate("已复制") .. ': "+u.value)})};u.parentNode.appendChild(b)}});</script>'
end

return m
