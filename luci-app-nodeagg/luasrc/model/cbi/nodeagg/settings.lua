local m, s, o

m = Map("nodeagg", translate("聚合"))

-- 聚合
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
	local url = m.uci:get("nodeagg", section, "agg_url") or "http://192.168.2.30/nodeagg.txt"
	return '<input type="button" class="cbi-button" value="' .. translate("复制") .. '" onclick="var t=document.createElement(\'textarea\');t.textContent=\'' .. url .. '\';t.style.position=\'fixed\';document.body.appendChild(t);t.select();try{document.execCommand(\'copy\');alert(\'' .. translate("已复制") .. ': \'+t.textContent)}catch(e){alert(\'copy failed\')}finally{document.body.removeChild(t)}" />'
end

-- 订阅源标题
s = m:section(TypedSection, "nodeagg")
s.anonymous = true
s.addremove = false
s.title = translate("订阅源")
s.template = "nodeagg/heading"

-- 订阅源
s = m:section(TypedSection, "subscribe_list")
s.addremove = true
s.anonymous = true
s.sortable = true
s.template = "cbi/tblsection"

o = s:option(Value, "remark", translate("备注"))
o.width = "auto"
o.rmempty = false

o = s:option(Value, "url", translate("订阅地址"))
o.width = "auto"
o.rmempty = false

return m
