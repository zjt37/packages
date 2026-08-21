local api = require "luci.nodeagg.api"
api.set_default_cbi()

local has_ss_rust = api.is_finded("sslocal")
local has_singbox = api.finded_com("sing-box")
local has_xray = api.finded_com("xray")
local has_hysteria2 = api.finded_com("hysteria")
local ss_type = {}
local trojan_type = {}
local vmess_type = {}
local vless_type = {}
local hysteria2_type = {}
local xray_version = api.get_app_version("xray")
if has_ss_rust then
	local s = "shadowsocks-rust"
	table.insert(ss_type, s)
end
if has_singbox then
	local s = "sing-box"
	table.insert(trojan_type, s)
	table.insert(ss_type, s)
	table.insert(vmess_type, s)
	table.insert(vless_type, s)
	table.insert(hysteria2_type, s)
end
if has_xray then
	local s = "xray"
	table.insert(trojan_type, s)
	table.insert(ss_type, s)
	table.insert(vmess_type, s)
	table.insert(vless_type, s)
	if api.compare_versions(xray_version, ">=", "26.1.13") then
		table.insert(hysteria2_type, s)
	end
end
if has_hysteria2 then
	local s = "hysteria2"
	table.insert(hysteria2_type, s)
end

m = Map("nodeagg")

function m.on_before_save(self)
	self:foreach("subscribe_list", function(e)
		self:del(e[".name"], "md5")
	end)
end

-- [[ Subscribe Settings ]]--
s = m:section(NamedSection, "@global_subscribe[0]", "global_subscribe")

o = s:option(ListValue, "filter_keyword_mode", translate("过滤关键词模式"))
o:value("0", translate("关闭"))
o:value("1", translate("丢弃列表"))
o:value("2", translate("保留列表"))
o:value("3", translate("丢弃列表,但保留列表优先"))
o:value("4", translate("保留列表,但丢弃列表优先"))

o = s:option(DynamicList, "filter_discard_list", translate("丢弃列表"))

o = s:option(DynamicList, "filter_keep_list", translate("保留列表"))

if #ss_type > 0 then
	o = s:option(ListValue, "ss_type", translatef("%s 节点使用类型", "Shadowsocks"))
	o:value("", translate("自动"))
	for key, value in pairs(ss_type) do
		o:value(value)
	end
end

if #trojan_type > 0 then
	o = s:option(ListValue, "trojan_type", translatef("%s 节点使用类型", "Trojan"))
	o:value("", translate("自动"))
	for key, value in pairs(trojan_type) do
		o:value(value)
	end
end

if #vmess_type > 0 then
	o = s:option(ListValue, "vmess_type", translatef("%s 节点使用类型", "VMess"))
	o:value("", translate("自动"))
	for key, value in pairs(vmess_type) do
		o:value(value)
	end
end

if #vless_type > 0 then
	o = s:option(ListValue, "vless_type", translatef("%s 节点使用类型", "VLESS"))
	o:value("", translate("自动"))
	for key, value in pairs(vless_type) do
		o:value(value)
	end
end

if #hysteria2_type > 0 then
	o = s:option(ListValue, "hysteria2_type", translatef("%s 节点使用类型", "Hysteria2"))
	o:value("", translate("自动"))
	for key, value in pairs(hysteria2_type) do
		o:value(value)
	end
end

if #ss_type > 0 or #trojan_type > 0 or #vmess_type > 0 or #vless_type > 0 or #hysteria2_type > 0 then
	o.description = string.format("<font color='red'>%s</font>",
			translate("配置的类型同样适用于手动导入节点时指定的内核。"))
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
o.cfgvalue = function(self, section)
    return string.format([[
        <input type="button" class="btn cbi-button cbi-button-apply" onclick="ManualSubscribeAll()" value="%s" />]],
	 translate("手动订阅所有"))
end

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
    return string.format([[
        <input type="button" class="btn cbi-button cbi-button-apply" onclick="ManualSubscribe('%s')" value="%s" />]],
	section, translate("手动订阅"))
end

m:appendTemplate("/cbi/sortable", {sectiontype = s.sectiontype})

m:appendTemplate("/node_subscribe/js")

return m
