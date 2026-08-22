api = require "luci.nodehub.api"
datatypes = api.datatypes
local fs = api.fs
has_singbox = api.finded_com("sing-box")
has_xray = api.finded_com("xray")

api.set_default_cbi()

m = Map()

m:appendTemplate("/cbi/nodes_listvalue_com")

m:appendTemplate("/global/status")

s = m:section(NamedSection, "@global[0]", "global")

s:tab("Main", translate("Main"))
s:tab("DNS", translate("DNS"))
s:tab("Proxy", translate("Mode"))
s:tab("faq", "FAQ")
o = s:taboption("faq", DummyValue, "")
o.template = m:template_path("/global/faq")

s:tab("maintain", translate("Maintain"))
o = s:taboption("maintain", DummyValue, "")
o.template = m:template_path("/global/backup")

m:appendTemplate("/global/footer", {shunt_list = "[]"})

return api.return_map(m)
