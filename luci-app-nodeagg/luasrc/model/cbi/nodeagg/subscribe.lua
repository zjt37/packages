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

-- [[ Subscribe Settings ]]--
s = m:section(NamedSection, "@global_subscribe[0]", "global_subscribe")

o = s:option(ListValue, "filter_keyword_mode", translate("Filter keyword Mode"))
o:value("0", translate("Close"))
o:value("1", translate("Discard List"))
o:value("2", translate("Keep List"))
o:value("3", translate("Discard List,But Keep List First"))
o:value("4", translate("Keep List,But Discard List First"))

o = s:option(DynamicList, "filter_discard_list", translate("Discard List"))

o = s:option(DynamicList, "filter_keep_list", translate("Keep List"))

if #ss_type > 0 then
	o = s:option(ListValue, "ss_type", translatef("%s Node Use Type", "Shadowsocks"))
	o:value("", translate("Auto"))
	for key, value in pairs(ss_type) do
		o:value(value)
	end
end

if #trojan_type > 0 then
	o = s:option(ListValue, "trojan_type", translatef("%s Node Use Type", "Trojan"))
	o:value("", translate("Auto"))
	for key, value in pairs(trojan_type) do
		o:value(value)
	end
end

if #vmess_type > 0 then
	o = s:option(ListValue, "vmess_type", translatef("%s Node Use Type", "VMess"))
	o:value("", translate("Auto"))
	for key, value in pairs(vmess_type) do
		o:value(value)
	end
end

if #vless_type > 0 then
	o = s:option(ListValue, "vless_type", translatef("%s Node Use Type", "VLESS"))
	o:value("", translate("Auto"))
	for key, value in pairs(vless_type) do
		o:value(value)
	end
end

if #hysteria2_type > 0 then
	o = s:option(ListValue, "hysteria2_type", translatef("%s Node Use Type", "Hysteria2"))
	o:value("", translate("Auto"))
	for key, value in pairs(hysteria2_type) do
		o:value(value)
	end
end

if #ss_type > 0 or #trojan_type > 0 or #vmess_type > 0 or #vless_type > 0 or #hysteria2_type > 0 then
	o.description = string.format("<font color='red'>%s</font>",
			translate("The configured type also applies to the core specified when manually importing nodes."))
end

---- Subscribe Delete All
o = s:option(DummyValue, "_stop", translate("Delete All Subscribe Node"))
o.rawhtml = true
function o.cfgvalue(self, section)
	return string.format(
		[[<input type="button" class="btn cbi-button cbi-button-remove" onclick="return confirmDeleteAll()" value="%s" />]],
		translate("Delete All Subscribe Node"))
end

o = s:option(DummyValue, "_update", translate("Manual subscription All"))
o.rawhtml = true
o.cfgvalue = function(self, section)
    return string.format([[
        <input type="button" class="btn cbi-button cbi-button-apply" onclick="ManualSubscribeAll()" value="%s" />]],
	 translate("Manual subscription All"))
end

return m
