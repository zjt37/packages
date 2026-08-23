local api = require "luci.nodepool.api"
api.set_default_cbi()

m = Map()

m:appendTemplate("/node_subscribe/title")

s = m:section(TypedSection, "subscribe_list")
s.addremove = true
s.anonymous = true
s.sortable = true
s.template = "cbi/tblsection"
s.extedit = api.url("node_subscribe_config", "%s")
function s.create(e, t)
	local uid = "sub_" .. api.gen_random_char(5)
	TypedSection.create(e, uid)
	m:set(uid, "hysteria_up_mbps", "100")
	m:set(uid, "hysteria_down_mbps", "100")
	luci.http.redirect(e.extedit:format(uid))
end

o = s:option(Value, "remark", translate("Remarks"))
o.width = "auto"
o.rmempty = false
o.validate = function(self, value, section)
	value = api.trim(value)
	if value == "" then
		return nil, translate("Remark cannot be empty.")
	end
	local duplicate = false
	m:foreach(s.sectiontype, function(e)
		if e[".name"] ~= section and e["remark"] and e["remark"]:lower() == value:lower() then
			duplicate = true
			return false
		end
	end)
	if duplicate or value:lower() == "default" then
		return nil, translate("This remark already exists, please change a new remark.")
	end
	return value
end
o.write = function(self, section, value)
	local old = m:get(section, self.option) or ""
	if old ~= value then
		m:foreach("nodes", function(e)
			if e["group"] and e["group"]:lower() == old:lower() then
				m:set(e[".name"], "group", value)
			end
			if e["protocol"] and (e["protocol"] == "_balancing" or e["protocol"] == "_urltest") and e["node_group"] then
				local gs = ""
				for g in e["node_group"]:gmatch("%S+") do
					if api.UrlEncode(old) == g then
						gs = gs .. " " .. api.UrlEncode(value)
					else
						gs = gs .. " " .. g
					end
				end
				gs = api.trim(gs)
				m:set(e[".name"], "node_group", gs)
			end
		end)
	end
	return Value.write(self, section, value)
end

o = s:option(DummyValue, "_node_count", translate("Subscribe Info"))
o.rawhtml = true
o.cfgvalue = function(t, n)
	local remark = m:get(n, "remark") or ""
	local str = m:get(n, "rem_traffic") or ""
	local expired_date = m:get(n, "expired_date") or ""
	if expired_date ~= "" then
		str = str .. (str ~= "" and "/" or "") .. expired_date
	end
	str = str ~= "" and "<br>" .. str or ""
	local num = 0
	m:foreach("nodes", function(s)
		if s["group"] and s["group"]:lower() == remark:lower() then
			num = num + 1
		end
	end)
	return string.format("%s%s", translate("Node num") .. ": " .. num, str)
end

o = s:option(Value, "url", translate("Subscribe URL"))
o.width = "auto"
o.rmempty = false

o = s:option(DummyValue, "_remove", translate("Delete the subscribed node"))
o.rawhtml = true
function o.cfgvalue(self, section)
	local remark = m:get(section, "remark") or ""
	return string.format(
		[[<input type="button" class="btn cbi-button cbi-button-remove" onclick="return confirmDeleteNode('%s')" value="%s" />]],
		remark, translate("Delete the subscribed node"))
end

o = s:option(DummyValue, "_update", translate("Manual subscription"))
o.rawhtml = true
o.cfgvalue = function(self, section)
    return string.format([[
        <input type="button" class="btn cbi-button cbi-button-apply" onclick="ManualSubscribe('%s')" value="%s" />]],
	section, translate("Manual subscription"))
end

	m:appendTemplate("/cbi/sortable", {sectiontype = s.sectiontype})

	m:appendTemplate("/node_subscribe/js")

if true then
	m:appendTemplate("/node_list/node_list")

	if luci.http.formvalue("cbi.submit") == "1" then
		local group_order = {}
		group_order = luci.http.formvaluetable("group.order")
		if group_order then
			for k, v in pairs(group_order) do
				if v and v~= "" then
					local new_order = {}
					string.gsub(v, "[^" .. " " .. "]+", function(w)
						new_order[#new_order + 1] = w
					end)
					for idx, name in ipairs(new_order) do
						m.uci:reorder(m.config, name, idx - 1)
					end
				end
			end
		end
	end
end

return api.return_map(m)
