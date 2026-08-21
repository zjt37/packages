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
	return '<script type="text/javascript">//<![CDATA[\n' ..
		'var initCopy=function(){var inputs=document.querySelectorAll("input[type=text]");' ..
		'for(var i=0;i<inputs.length;i++){if(inputs[i].value.indexOf("nodeagg")!==-1||inputs[i].id.indexOf("agg_url")!==-1){' ..
		'var b=document.createElement("input");b.type="button";b.className="cbi-button";b.value="' .. translate("复制") .. '";' ..
		'b.onclick=(function(input){return function(){navigator.clipboard.writeText(input.value).then(function(){alert("' .. translate("已复制") .. ': "+input.value)})}})(inputs[i]);' ..
		'inputs[i].parentNode.appendChild(b);break}}};' ..
		'if(document.readyState==="loading"){document.addEventListener("DOMContentLoaded",initCopy)}else{initCopy()}\n' ..
		'//]]></script>'
end

return m
