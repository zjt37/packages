local api = require "luci.nodeagg.api"
api.set_default_cbi()

m = Map("nodeagg")
m.redirect = luci.dispatcher.build_url("admin", "services", "nodeagg", "settings")

if not arg[1] or not m:get(arg[1]) then
	luci.http.redirect(m.redirect)
end

function m.on_before_save(self)
	self:del(arg[1], "md5")
end

m:appendTemplate("/cbi/nodes_listvalue_com")

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
	table.insert(ss_type, "shadowsocks-rust")
end
if has_singbox then
	table.insert(trojan_type, "sing-box")
	table.insert(ss_type, "sing-box")
	table.insert(vmess_type, "sing-box")
	table.insert(vless_type, "sing-box")
	table.insert(hysteria2_type, "sing-box")
end
if has_xray then
	table.insert(trojan_type, "xray")
	table.insert(ss_type, "xray")
	table.insert(vmess_type, "xray")
	table.insert(vless_type, "xray")
	if api.compare_versions(xray_version, ">=", "26.1.13") then
		table.insert(hysteria2_type, "xray")
	end
end
if has_hysteria2 then
	table.insert(hysteria2_type, "hysteria2")
end

s = m:section(NamedSection, arg[1])
s.addremove = false
s.dynamic = false

o = s:option(Value, "remark", translate("订阅备注"))
o.rmempty = false
o.validate = function(self, value, section)
	value = api.trim(value)
	if value == "" then
		return nil, translate("备注不能为空。")
	end
	local duplicate = false
	m:foreach("subscribe_list", function(e)
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

o = s:option(TextValue, "url", translate("订阅地址"))
o.rows = 5
o.rmempty = false
o.validate = function(self, value)
	if not value or value == "" then
		return nil, translate("URL不能为空。")
	end
	return value:gsub("%s+", ""):gsub("%z", "")
end

o = s:option(ListValue, "domain_resolver", translate("域名DNS解析"))
o.description = translate("如果节点地址是域名，将使用此DNS进行解析。") .. "<br>" ..
		translate("仅支持Xray或Sing-box节点类型。") .. "<br>" .. string.format('<font color="red">%s</font>',
		translate("注意：仅用于节点DNS。保持自动以避免额外开销。"))
o:value("", translate("自动"))
o:value("tcp", "TCP")
o:value("udp", "UDP")
o:value("https", "DoH")

o = s:option(Value, "domain_resolver_dns", "DNS")
o.datatype = "or(ipaddr,ipaddrport)"
o:value("114.114.114.114")
o:value("223.5.5.5:53")
o.default = o.keylist[1]
o:depends({ domain_resolver = "tcp" })
o:depends({ domain_resolver = "udp" })

o = s:option(Value, "domain_resolver_dns_https", "DNS")
o:value("https://120.53.53.53/dns-query", "DNSPod")
o:value("https://223.5.5.5/dns-query", "AliDNS")
o.default = o.keylist[1]
o:depends({ domain_resolver = "https" })

o = s:option(ListValue, "domain_strategy", translate("域名策略"), translate("如果是域名，请求的域名将在连接前解析为IP。"))
o.default = ""
o:value("", translate("自动"))
o:value("UseIPv4v6", translate("优先IPv4"))
o:value("UseIPv6v4", translate("优先IPv6"))
o:value("UseIPv4", translate("仅IPv4"))
o:value("UseIPv6", translate("仅IPv6"))

o = s:option(Flag, "allowInsecure", translate("允许不安全连接"))
o.default = "0"
o.rmempty = false
o.description = translate("是否允许不安全连接。勾选后将跳过证书验证。") .. "<br>" ..
		translate("当节点链接未包含此参数时使用。")

o = s:option(ListValue, "filter_keyword_mode", translate("过滤关键词模式"))
o.default = "5"
o:value("0", translate("关闭"))
o:value("1", translate("丢弃列表"))
o:value("2", translate("保留列表"))
o:value("3", translate("丢弃列表,但保留列表优先"))
o:value("4", translate("保留列表,但丢弃列表优先"))
o:value("5", translate("使用全局配置"))

o = s:option(DynamicList, "filter_discard_list", translate("丢弃列表"))
o:depends("filter_keyword_mode", "1")
o:depends("filter_keyword_mode", "3")
o:depends("filter_keyword_mode", "4")

o = s:option(DynamicList, "filter_keep_list", translate("保留列表"))
o:depends("filter_keyword_mode", "2")
o:depends("filter_keyword_mode", "3")
o:depends("filter_keyword_mode", "4")

if #ss_type > 0 then
	o = s:option(ListValue, "ss_type", translatef("%s 节点使用类型", "Shadowsocks"))
	o.default = "global"
	o:value("global", translate("使用全局配置"))
	for key, value in pairs(ss_type) do o:value(value) end
end

if #trojan_type > 0 then
	o = s:option(ListValue, "trojan_type", translatef("%s 节点使用类型", "Trojan"))
	o.default = "global"
	o:value("global", translate("使用全局配置"))
	for key, value in pairs(trojan_type) do o:value(value) end
end

if #vmess_type > 0 then
	o = s:option(ListValue, "vmess_type", translatef("%s 节点使用类型", "VMess"))
	o.default = "global"
	o:value("global", translate("使用全局配置"))
	for key, value in pairs(vmess_type) do o:value(value) end
end

if #vless_type > 0 then
	o = s:option(ListValue, "vless_type", translatef("%s 节点使用类型", "VLESS"))
	o.default = "global"
	o:value("global", translate("使用全局配置"))
	for key, value in pairs(vless_type) do o:value(value) end
end

if #hysteria2_type > 0 then
	o = s:option(ListValue, "hysteria2_type", translatef("%s 节点使用类型", "Hysteria2"))
	o.default = "global"
	o:value("global", translate("使用全局配置"))
	for key, value in pairs(hysteria2_type) do o:value(value) end

	o = s:option(Value, "hysteria_up_mbps", "Hy/Hy2 " .. translate("最大上传Mbps"))
	o.datatype = "uinteger"

	o = s:option(Value, "hysteria_down_mbps", "Hy/Hy2 " .. translate("最大下载Mbps"))
	o.datatype = "uinteger"
end

o = s:option(Flag, "boot_update", translate("启动时更新一次"), translate("系统每次启动后首次运行时自动更新订阅。"))
o.default = 0

o = s:option(ListValue, "update_week_mode", translate("自动更新模式"))
o:value("", translate("禁用"))
o:value(8, translate("循环模式"))
o:value(7, translate("每天"))
o:value(1, translate("每周一"))
o:value(2, translate("每周二"))
o:value(3, translate("每周三"))
o:value(4, translate("每周四"))
o:value(5, translate("每周五"))
o:value(6, translate("每周六"))
o:value(0, translate("每周日"))

o = s:option(Value, "update_time_mode", translate("更新时间"))
for t = 0, 23 do o:value(t .. ":00") end
o.default = "0:00"
o.datatype = "timehhmm"
o:depends("update_week_mode", "0")
o:depends("update_week_mode", "1")
o:depends("update_week_mode", "2")
o:depends("update_week_mode", "3")
o:depends("update_week_mode", "4")
o:depends("update_week_mode", "5")
o:depends("update_week_mode", "6")
o:depends("update_week_mode", "7")

o = s:option(ListValue, "update_interval_mode", translate("更新间隔(小时)"))
for t = 1, 24 do o:value(t, t .. " " .. translate("小时")) end
o.default = 2
o:depends("update_week_mode", "8")
o.rmempty = true

o = s:option(ListValue, "access_mode", translate("订阅地址访问方式"))
o.default = ""
o:value("", translate("自动"))
o:value("direct", translate("直连"))
o:value("proxy", translate("代理"))

o = s:option(Value, "user_agent", translate("User-Agent"))
o.default = "nodeagg"
o:value("nodeagg", "NodeAgg")
o:value("v2rayN/9.99", "v2rayN")
o:value("clash.meta", "Clash.Meta")
o:value("Clash", "Clash")
o:value("curl", "Curl")

o = s:option(ListValue, "chain_proxy", translate("链式代理"))
o:value("", translate("关闭(不使用)"))
o:value("1", translate("前置代理节点"))
o:value("2", translate("落地节点"))
o:value("3", translate("出站接口"))

o1 = s:option(ListValue, "preproxy_node", translate("前置代理节点"))
o1:depends({ ["chain_proxy"] = "1" })
o1.description = translate("链式代理仅支持Xray或Sing-box节点。只能使用手动或导入的节点作为链式节点。") .. "<br>" .. translate("仅支持一层代理。")
o1.template = m:template_path("/cbi/nodes_listvalue")
o1.group = {}

o2 = s:option(ListValue, "to_node", translate("落地节点"))
o2:depends({ ["chain_proxy"] = "2" })
o2.description = translate("链式代理仅支持Xray或Sing-box节点。只能使用手动或导入的节点作为链式节点。") .. "<br>" .. translate("仅支持一层代理。")
o2.template = m:template_path("/cbi/nodes_listvalue")
o2.group = {}

o3 = s:option(Value, "outbound_iface", translate("出站接口"))
o3:depends({ ["chain_proxy"] = "3" })
o3:value("", translate("全部"))
local iface = api.get_network_devices()
for _, d in ipairs(iface) do
	o3:value(d.name, d.label)
end

local nodes_table = {}
for k, e in ipairs(api.get_valid_nodes()) do
	if e.node_type == "normal" then
		nodes_table[#nodes_table + 1] = {
			id = e[".name"],
			remark = e["remark"],
			type = e["type"],
			add_mode = e["add_mode"],
			chain_proxy = e["chain_proxy"],
			group = e["group"]
		}
	end
end

for k, v in pairs(nodes_table) do
	if (v.type == "Xray" or v.type == "sing-box") and (not v.chain_proxy or v.chain_proxy == "") and v.add_mode ~= "2" then
		o1:value(v.id, v.remark)
		o1.group[#o1.group+1] = (v.group and v.group ~= "") and v.group or translate("默认")
		o2:value(v.id, v.remark)
		o2.group[#o2.group+1] = (v.group and v.group ~= "") and v.group or translate("默认")
	end
end

return m
