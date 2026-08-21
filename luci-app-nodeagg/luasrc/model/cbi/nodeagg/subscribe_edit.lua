local api = require "luci.passwall.api"
api.set_default_cbi()

m = Map()
m.redirect = api.url("node_subscribe")

if not arg[1] or not m:get(arg[1]) then
	luci.http.redirect(m.redirect)
end

function m.on_before_save(self)
	self:del(arg[1], "md5")
end

s = m:section(NamedSection, arg[1])
s.addremove = false
s.dynamic = false

o = s:option(Value, "remark", translate("订阅备注"))
o.rmempty = false

o = s:option(TextValue, "url", translate("订阅地址"))
o.rows = 5
o.rmempty = false

o = s:option(ListValue, "filter_keyword_mode", translate("过滤关键词模式"))
o:value("0", translate("关闭"))
o:value("1", translate("丢弃列表"))
o:value("2", translate("保留列表"))
o:value("3", translate("丢弃列表,但保留列表优先"))
o:value("4", translate("保留列表,但丢弃列表优先"))
o:value("5", translate("使用全局配置"))
o.default = "5"

o = s:option(DynamicList, "filter_discard_list", translate("丢弃列表"))
o:depends("filter_keyword_mode", "1")
o:depends("filter_keyword_mode", "3")
o:depends("filter_keyword_mode", "4")

o = s:option(DynamicList, "filter_keep_list", translate("保留列表"))
o:depends("filter_keyword_mode", "2")
o:depends("filter_keyword_mode", "3")
o:depends("filter_keyword_mode", "4")

o = s:option(Flag, "boot_update", translate("启动时更新一次"))
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

return api.return_map(m)
