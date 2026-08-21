local api = require "luci.nodeagg.api"
api.set_default_cbi()

local m, s, o

m = Map("nodeagg", translate("聚合"))

function m.on_before_save(self)
	self:foreach("subscribe_list", function(e)
		self:del(e[".name"], "md5")
	end)
end

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
s = m:section(TypedSection, "subscribe_list", "", "<font color='red'>" .. translate("添加新订阅后请保存并应用，再手动订阅。如果只修改了订阅地址，可以手动订阅，系统会自动保存。") .. "</font>")
s.addremove = true
s.anonymous = true
s.sortable = true
s.template = "cbi/tblsection"
s.extedit = luci.dispatcher.build_url("admin", "services", "nodeagg", "subscribe_edit", "%s")
function s.create(e, t)
	local uid = "sub_" .. api.gen_random_char(5)
	TypedSection.create(e, uid)
	luci.http.redirect(e.extedit:format(uid))
end

o = s:option(Value, "remark", translate("备注"))
o.width = "auto"
o.rmempty = false
o.validate = function(self, value, section)
	value = api.trim(value)
	if value == "" then
		return nil, translate("备注不能为空。")
	end
	local duplicate = false
	m:foreach(s.sectiontype, function(e)
		if e[".name"] ~= section and e["remark"] and e["remark"]:lower() == value:lower() then
			duplicate = true
			return false
		end
	end)
	if duplicate or value:lower() == "default" then
		return nil, translate("备注已存在，请更换。")
	end
	return value
end

o = s:option(DummyValue, "_node_count", translate("订阅信息"))
o.rawhtml = true
o.cfgvalue = function(t, n)
	local remark = m:get(n, "remark") or ""
	local num = 0
	m:foreach("nodes", function(s)
		if s["group"] and s["group"]:lower() == remark:lower() then
			num = num + 1
		end
	end)
	return translate("节点数量") .. ": " .. num
end

o = s:option(Value, "url", translate("订阅地址"))
o.width = "auto"
o.rmempty = false

o = s:option(DummyValue, "_remove", translate("删除订阅节点"))
o.rawhtml = true
function o.cfgvalue(self, section)
	local remark = m:get(section, "remark") or ""
	return string.format(
		[[<input type="button" class="btn cbi-button cbi-button-remove" onclick="return confirmDeleteNode('%s')" value="%s" />]],
		remark, translate("删除订阅节点"))
end

o = s:option(DummyValue, "_update", translate("手动订阅"))
o.rawhtml = true
o.cfgvalue = function(self, section)
	return string.format(
		[[<input type="button" class="btn cbi-button cbi-button-apply" onclick="ManualSubscribe('%s')" value="%s" />]],
		section, translate("手动订阅"))
end

m:appendTemplate("/cbi/sortable", {sectiontype = s.sectiontype})

m:appendTemplate("/node_subscribe/js")

return m
