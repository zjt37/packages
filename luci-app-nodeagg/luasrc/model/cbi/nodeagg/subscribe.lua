local m, s, o

m = Map("nodeagg", translate("节点订阅"))

-- 订阅源
s = m:section(TypedSection, "subscribe_list", translate("订阅源"))
s.addremove = true
s.anonymous = true
s.sortable = true
s.template = "cbi/tblsection"
s.extedit = luci.dispatcher.build_url("admin", "services", "nodeagg", "subscribe_edit", "%s")
function s.create(e, t)
	local uid = "sub_" .. os.date("%Y%m%d%H%M%S")
	TypedSection.create(e, uid)
	luci.http.redirect(e.extedit:format(uid))
end

o = s:option(Value, "remark", translate("备注"))
o.width = "auto"
o.rmempty = false

o = s:option(DummyValue, "_node_count", translate("节点数量"))
o.rawhtml = true
o.cfgvalue = function(self, section)
	local num = 0
	return string.format("%s: %d", translate("节点数量"), num)
end

o = s:option(Value, "url", translate("订阅地址"))
o.width = "auto"
o.rmempty = false

o = s:option(DummyValue, "_subscribe", " ")
o.rawhtml = true
o.cfgvalue = function(self, section)
	return string.format(
		[[<input type="button" class="btn cbi-button cbi-button-apply" onclick="ManualSubscribe('%s')" value="%s" />]],
		section, translate("手动订阅"))
end

return m
