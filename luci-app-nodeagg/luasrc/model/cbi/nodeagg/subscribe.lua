local api = require "luci.nodeagg.api"
-- api.set_default_cbi()

m = Map()

function m.on_before_save(self)
	self:foreach("subscribe_list", function(e)
		self:del(e[".name"], "md5")
	end)
end

-- [[ 订阅设置 ]]--
s = m:section(NamedSection, "@global_subscribe[0]", "global_subscribe")

o = s:option(ListValue, "filter_keyword_mode", translate("过滤关键词模式"))
o:value("0", translate("关闭"))
o:value("1", translate("丢弃列表"))
o:value("2", translate("保留列表"))
o:value("3", translate("丢弃列表,但保留列表优先"))
o:value("4", translate("保留列表,但丢弃列表优先"))

o = s:option(DynamicList, "filter_discard_list", translate("丢弃列表"))

o = s:option(DynamicList, "filter_keep_list", translate("保留列表"))

local has_ss_rust = api.is_finded("sslocal")
local has_singbox = api.finded_com("sing-box")
local has_xray = api.finded_com("xray")
local has_hysteria2 = api.finded_com("hysteria")

if has_ss_rust or has_singbox or has_xray then
	o = s:option(ListValue, "ss_type", translatef("%s 节点使用类型", "Shadowsocks"))
	o:value("", translate("自动"))
	if has_singbox then o:value("sing-box", "sing-box") end
	if has_xray then o:value("xray", "xray") end
end

if has_ss_rust or has_singbox or has_xray then
	o = s:option(ListValue, "trojan_type", translatef("%s 节点使用类型", "Trojan"))
	o:value("", translate("自动"))
	if has_singbox then o:value("sing-box", "sing-box") end
	if has_xray then o:value("xray", "xray") end
end

if has_ss_rust or has_singbox or has_xray then
	o = s:option(ListValue, "vmess_type", translatef("%s 节点使用类型", "VMess"))
	o:value("", translate("自动"))
	if has_singbox then o:value("sing-box", "sing-box") end
	if has_xray then o:value("xray", "xray") end
end

if has_ss_rust or has_singbox or has_xray then
	o = s:option(ListValue, "vless_type", translatef("%s 节点使用类型", "VLESS"))
	o:value("", translate("自动"))
	if has_singbox then o:value("sing-box", "sing-box") end
	if has_xray then o:value("xray", "xray") end
end

if has_singbox or has_xray or has_hysteria2 then
	o = s:option(ListValue, "hysteria2_type", translatef("%s 节点使用类型", "Hysteria2"))
	o:value("", translate("自动"))
	if has_singbox then o:value("sing-box", "sing-box") end
	if has_xray then o:value("xray", "xray") end
	if has_hysteria2 then o:value("hysteria2", "hysteria2") end
end

---- 删除所有订阅节点
o = s:option(DummyValue, "_stop", translate("删除所有订阅节点"))
o.rawhtml = true
function o.cfgvalue(self, section)
	return string.format(
		[[<input type="button" class="btn cbi-button cbi-button-remove" onclick="return confirmDeleteAll()" value="%s" />]],
		translate("删除所有订阅节点"))
end

---- 手动订阅所有
o = s:option(DummyValue, "_update", translate("手动订阅所有"))
o.rawhtml = true
function o.cfgvalue(self, section)
	return string.format(
		[[<input type="button" class="btn cbi-button cbi-button-apply" onclick="ManualSubscribeAll()" value="%s" />]],
		translate("手动订阅所有"))
end

-- [[ 订阅列表 ]]--
s = m:section(TypedSection, "subscribe_list", "", '<font color="red">' .. translate("添加新订阅后请保存并应用，再手动订阅。如果只修改了订阅地址，可以手动订阅，系统会自动保存。") .. '</font>')
s.addremove = true
s.anonymous = true
s.sortable = true
s.template = "cbi/tblsection"
s.extedit = luci.dispatcher.build_url("admin", "services", "nodeagg", "subscribe_edit", "%s")
function s.create(e, t)
	local uid = "sub_" .. api.gen_random_char(5)
	TypedSection.create(e, uid)
	m:set(uid, "hysteria_up_mbps", "100")
	m:set(uid, "hysteria_down_mbps", "100")
	luci.http.redirect(e.extedit:format(uid))
end

o = s:option(Value, "remark", translate("备注"))
o.width = "auto"
o.rmempty = false

o = s:option(DummyValue, "_node_count", translate("订阅信息"))
o.rawhtml = true
function o.cfgvalue(self, section)
	local remark = m:get(section, "remark") or ""
	local num = 0
	return string.format("%s: %d", translate("节点数量"), num)
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

o = s:option(DummyValue, "_update2", translate("手动订阅"))
o.rawhtml = true
function o.cfgvalue(self, section)
	return string.format(
		[[<input type="button" class="btn cbi-button cbi-button-apply" onclick="ManualSubscribe('%s')" value="%s" />]],
		section, translate("手动订阅"))
end

s2 = m:section(TypedSection, "nodeagg")
s2.anonymous = true
s2.addremove = false
o = s2:option(DummyValue, "_js", " ")
o.rawhtml = true
function o.cfgvalue(self, section)
	return '<script type="text/javascript">'
		.. 'function confirmDeleteNode(remark){if(!confirm("' .. translate("删除订阅节点") .. ': "+remark+" ?"))return false;return true;}'
		.. 'function confirmDeleteAll(){if(!confirm("' .. translate("确定要删除所有订阅节点吗？") .. '"))return false;return true;}'
		.. 'function ManualSubscribe(sectionId){var urlInput=document.querySelector("input[name=\'cbid.nodeagg."+sectionId+".url\']");var currentUrl=urlInput?urlInput.value.trim():"";if(!currentUrl){alert("' .. translate("订阅地址不能为空") .. '");return;}alert("' .. translate("手动订阅") .. ': "+currentUrl);}'
		.. 'function ManualSubscribeAll(){alert("' .. translate("手动订阅所有") .. '");}'
		.. '</script>'
end

return m
