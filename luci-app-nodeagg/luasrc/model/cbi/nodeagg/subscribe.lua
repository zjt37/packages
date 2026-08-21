local m, s, o

m = Map("nodeagg", translate("节点订阅"))

-- [[ 订阅设置 ]]--
s = m:section(TypedSection, "nodeagg")
s.anonymous = true
s.addremove = false

o = s:option(ListValue, "filter_keyword_mode", translate("过滤关键词模式"))
o:value("0", translate("关闭"))
o:value("1", translate("丢弃列表"))
o:value("2", translate("保留列表"))
o:value("3", translate("丢弃列表,但保留列表优先"))
o:value("4", translate("保留列表,但丢弃列表优先"))
o.default = "0"

o = s:option(DynamicList, "filter_discard_list", translate("丢弃列表"))

o = s:option(DynamicList, "filter_keep_list", translate("保留列表"))

---- 删除所有订阅节点
o = s:option(DummyValue, "_stop", translate("删除所有订阅节点"))
o.rawhtml = true
o.cfgvalue = function(self, section)
	return string.format(
		[[<input type="button" class="btn cbi-button cbi-button-remove" onclick="confirmDeleteAll()" value="%s" />]],
		translate("删除所有订阅节点"))
end

---- 手动订阅所有
o = s:option(DummyValue, "_update", translate("手动订阅所有"))
o.rawhtml = true
o.cfgvalue = function(self, section)
	return string.format(
		[[<input type="button" class="btn cbi-button cbi-button-apply" onclick="ManualSubscribeAll()" value="%s" />]],
		translate("手动订阅所有"))
end

-- [[ 订阅列表 ]]--
s = m:section(TypedSection, "subscribe_list", "", "<font color='red'>" .. translate("添加新订阅后请保存并应用，再手动订阅。如果只修改了订阅地址，可以手动订阅，系统会自动保存。") .. "</font>")
s.addremove = true
s.anonymous = true
s.sortable = true
s.template = "cbi/tblsection"

o = s:option(Value, "remark", translate("备注"))
o.width = "auto"
o.rmempty = false

o = s:option(DummyValue, "_node_count", translate("订阅信息"))
o.rawhtml = true
o.cfgvalue = function(self, section)
	local remark = m:get(section, "remark") or ""
	local num = 0
	m:foreach("nodes", function(s)
		if s["group"] and s["group"]:lower() == remark:lower() then
			num = num + 1
		end
	end)
	return string.format("%s: %d", translate("节点数量"), num)
end

o = s:option(Value, "url", translate("订阅地址"))
o.width = "auto"
o.rmempty = false

o = s:option(DummyValue, "_remove", translate("删除订阅节点"))
o.rawhtml = true
o.cfgvalue = function(self, section)
	local remark = m:get(section, "remark") or ""
	return string.format(
		[[<input type="button" class="btn cbi-button cbi-button-remove" onclick="confirmDeleteNode('%s')" value="%s" />]],
		remark, translate("删除订阅节点"))
end

o = s:option(DummyValue, "_update", translate("手动订阅"))
o.rawhtml = true
o.cfgvalue = function(self, section)
	return string.format(
		[[<input type="button" class="btn cbi-button cbi-button-apply" onclick="ManualSubscribe('%s')" value="%s" />]],
		section, translate("手动订阅"))
end

m:appendTemplate("/nodeagg/subscribe_js")

return m
