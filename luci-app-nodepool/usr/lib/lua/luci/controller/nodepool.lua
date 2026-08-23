-- Copyright (C) 2018-2020 L-WRT Team
-- Copyright (C) 2021-2025 xiaorouji
-- Copyright (C) 2026 Openwrt-Passwall Organization

module("luci.controller.nodepool", package.seeall)
local api = require "luci.nodepool.api"
local appname = api.appname		-- not available
local c_config = api.c_config	-- not available
local uci, uci_get, uci_set, uci_del, uci_foreach, uci_save = api.uci, api.uci_get_c, api.uci_set_c, api.uci_del_c, api.uci_foreach_c, api.uci_save_c
local fs = api.fs
local http = require "luci.http"
local util = require "luci.util"
local i18n = require "luci.i18n"
local jsonStringify = luci.jsonc.stringify
local jsonParse = luci.jsonc.parse

function index()
	if not nixio.fs.access("/etc/config/nodepool") then
		if nixio.fs.access("/usr/share/nodepool/0_default_config") then
			luci.sys.call('cp -f /usr/share/nodepool/0_default_config /etc/config/nodepool')
		else return end
	end
	local api = require "luci.nodepool.api"
	local appname = api.appname		-- global definitions not available
	local fs = api.fs
	entry({"admin", "services", appname}).dependent = true
	local e
	if api.uci_get_c("@global[0]", "hide_from_luci") ~= "1" then
		e = entry({"admin", "services", appname}, alias("admin", "services", appname, "settings"), _("Node Pool"), -1)
	else
		e = entry({"admin", "services", appname}, alias("admin", "services", appname, "settings"), nil, -1)
	end
	e.dependent = true
	e.acl_depends = { "luci-app-nodepool" }
	--[[ Client ]]
	entry({"admin", "services", appname, "settings"}, cbi(appname .. "/client/settings"), "节点聚合", 1).dependent = true
	entry({"admin", "services", appname, "node_list"}, cbi(appname .. "/client/node_list"), "订阅转换", 2).dependent = true
	entry({"admin", "services", appname, "node_subscribe"}, cbi(appname .. "/client/node_subscribe"), "节点订阅", 3).dependent = true
	entry({"admin", "services", appname, "node_subscribe_config"}, cbi(appname .. "/client/node_subscribe_config")).leaf = true
	entry({"admin", "services", appname, "node_config"}, cbi(appname .. "/client/node_config")).leaf = true
	entry({"admin", "services", appname, "socks_config"}, cbi(appname .. "/client/socks_config")).leaf = true
	entry({"admin", "services", appname, "clash_set_tpl"}, call("clash_set_tpl")).leaf = true

	--[[ API ]]
	entry({"admin", "services", appname, "link_add_node"}, call("link_add_node")).leaf = true
	entry({"admin", "services", appname, "socks_autoswitch_add_node"}, call("socks_autoswitch_add_node")).leaf = true
	entry({"admin", "services", appname, "socks_autoswitch_remove_node"}, call("socks_autoswitch_remove_node")).leaf = true
	entry({"admin", "services", appname, "gen_client_config"}, call("gen_client_config")).leaf = true
	entry({"admin", "services", appname, "get_now_use_node"}, call("get_now_use_node")).leaf = true
	entry({"admin", "services", appname, "ping_node"}, call("ping_node")).leaf = true
	entry({"admin", "services", appname, "urltest_node"}, call("urltest_node")).leaf = true
	entry({"admin", "services", appname, "update_config"}, call("update_config")).leaf = true
	entry({"admin", "services", appname, "add_node"}, call("add_node")).leaf = true
	entry({"admin", "services", appname, "delete_select_nodes"}, call("delete_select_nodes")).leaf = true
	entry({"admin", "services", appname, "get_node"}, call("get_node")).leaf = true
	entry({"admin", "services", appname, "save_node_list_opt"}, call("save_node_list_opt")).leaf = true
	entry({"admin", "services", appname, "subscribe_del_node"}, call("subscribe_del_node")).leaf = true
	entry({"admin", "services", appname, "subscribe_del_all"}, call("subscribe_del_all")).leaf = true
	entry({"admin", "services", appname, "subscribe_manual"}, call("subscribe_manual")).leaf = true
	entry({"admin", "services", appname, "subscribe_manual_all"}, call("subscribe_manual_all")).leaf = true

	entry({"admin", "services", appname, "fetch_certsha256"}, call("fetch_certsha256")).leaf = true
end

local function http_write_json(content)
	http.prepare_content("application/json")
	http.write(jsonStringify(content or {code = 1}))
end

local function http_write_json_ok(data)
	http.prepare_content("application/json")
	http.write(jsonStringify({code = 1, data = data}))
end

local function http_write_json_error(data)
	http.prepare_content("application/json")
	http.write(jsonStringify({code = 0, data = data}))
end

function link_add_node()
	-- 分片接收以突破uhttpd的限制
	local tmp_file = "/tmp/links.conf"
	local chunk = http.formvalue("chunk")
	local chunk_index = tonumber(http.formvalue("chunk_index"))
	local total_chunks = tonumber(http.formvalue("total_chunks"))

	if chunk and chunk_index ~= nil and total_chunks ~= nil then
		-- 按顺序拼接到文件
		local mode = "a"
		if chunk_index == 0 then
			mode = "w"
		end
		local f = io.open(tmp_file, mode)
		if f then
			f:write(chunk)
			f:close()
		end
		-- 如果是最后一片，才执行
		if chunk_index + 1 == total_chunks then
			luci.sys.call("lua /usr/share/nodepool/subscribe.lua add default")
		end
	end
end

function socks_autoswitch_add_node()
	local id = http.formvalue("id")
	local key = http.formvalue("key")
	if id and id ~= "" and key and key ~= "" then
		uci_set(id, "enable_autoswitch", "1")
		local new_list = uci_get(id, "autoswitch_backup_node") or {}
		for i = #new_list, 1, -1 do
			if (uci_get(new_list[i], "remarks") or ""):find(key) then
				table.remove(new_list, i)
			end
		end
		for k, e in ipairs(api.get_valid_nodes()) do
			if e.node_type == "normal" and e["remark"]:find(key) then
				table.insert(new_list, e.id)
			end
		end
		uci_set(id, "autoswitch_backup_node", new_list)
		uci_save()
	end
	http.redirect(api.url("socks_config", id))
end

function socks_autoswitch_remove_node()
	local id = http.formvalue("id")
	local key = http.formvalue("key")
	if id and id ~= "" and key and key ~= "" then
		uci_set(id, "enable_autoswitch", "1")
		local new_list = uci_get(id, "autoswitch_backup_node") or {}
		for i = #new_list, 1, -1 do
			if (uci_get(new_list[i], "remarks") or ""):find(key) then
				table.remove(new_list, i)
			end
		end
		uci_set(id, "autoswitch_backup_node", new_list)
		uci_save()
	end
	http.redirect(api.url("socks_config", id))
end


function gen_client_config()
	local id = http.formvalue("id")
	local config_file = api.TMP_PATH .. "/config_" .. id
	luci.sys.call(string.format("/usr/share/nodepool/app.sh run_socks flag=config_%s node=%s bind=127.0.0.1 socks_port=1080 config_file=%s no_run=1", id, id, config_file))
	if nixio.fs.access(config_file) then
		http.prepare_content("application/json")
		http.write(luci.sys.exec("cat " .. config_file))
		luci.sys.call("rm -f " .. config_file)
	else
		http.redirect(api.url("node_list"))
	end
end

function get_now_use_node()
	local path = api.TMP_PATH .. "/acl/default"
	local e = {}
	local tcp_node = api.get_cache_var("ACL_GLOBAL_TCP_node")
	if tcp_node then
		e["TCP"] = tcp_node
	end
	local udp_node = api.get_cache_var("ACL_GLOBAL_UDP_node")
	if udp_node then
		e["UDP"] = udp_node
	end
	http_write_json(e)
end
function ping_node()
	local index = http.formvalue("index")
	local address = http.formvalue("address")
	local port = http.formvalue("port")
	local type = http.formvalue("type") or "icmp"
	local e = {}
	e.index = index
	if type == "tcping" and luci.sys.exec("echo -n $(command -v tcping)") ~= "" then
		if api.is_ipv6(address) then
			address = api.get_ipv6_only(address)
		end
		e.ping = luci.sys.exec(string.format("echo -n $(tcping -q -c 1 -i 1 -t 2 -p %s %s 2>&1 | grep -o 'time=[0-9]*' | awk -F '=' '{print $2}') 2>/dev/null", port, address))
	else
		e.ping = luci.sys.exec("echo -n $(ping -c 1 -W 1 %q 2>&1 | grep -o 'time=[0-9]*' | awk -F '=' '{print $2}') 2>/dev/null" % address)
	end
	http_write_json(e)
end

function urltest_node()
	local index = http.formvalue("index")
	local id = http.formvalue("id")
	local e = {}
	e.index = index
	local result = luci.sys.exec(string.format("/usr/share/nodepool/test.sh url_test_node %s %s", id, "urltest_node"))
	local code = tonumber(luci.sys.exec("echo -n '" .. result .. "' | awk -F ':' '{print $1}'") or "0")
	if code ~= 0 then
		local use_time_str = luci.sys.exec("echo -n '" .. result .. "' | awk -F ':' '{print $2}'")
		local use_time = tonumber(use_time_str)
		if use_time then
			if use_time_str:find("%.") then
				e.use_time = string.format("%.2f", use_time * 1000)
			else
				e.use_time = string.format("%.2f", use_time / 1000)
			end
		end
	end
	http_write_json(e)
end

function update_config()
	local id = http.formvalue("id") -- Node id
	local data = http.formvalue("data") -- json new Data
	if id and data then
		local data_t = jsonParse(data) or {}
		if next(data_t) then
			for k, v in pairs(data_t) do
				uci_set(id, k, v)
			end
			uci_save()
			http_write_json_ok()
			luci.sys.call("lua /usr/share/nodepool/gen_sub.lua >/dev/null 2>&1 &")
			return
		end
	end
	http_write_json_error()
end

function add_node()
	local redirect = http.formvalue("redirect")

	local uid = api.gen_random_char()
	uci:section(c_config, "nodes", uid)

	local group = http.formvalue("group")
	if group and group ~= "default" then
		uci_set(uid, "group", group)
	end

	uci_set(uid, "type", "Socks")

	if redirect == "1" then
		uci_save()
		http.redirect(api.url("node_config", uid))
	else
		uci_save(true, true)
		http_write_json({result = uid})
	end
	luci.sys.call("lua /usr/share/nodepool/gen_sub.lua >/dev/null 2>&1 &")
end

function delete_select_nodes()
	local ids = http.formvalue("ids")
	local redirect = http.formvalue("redirect")
	local ids_t = {}
	string.gsub(ids, '[^' .. "," .. ']+', function(w)
		ids_t[#ids_t + 1] = w
		if (uci_get("@global[0]", "tcp_node") or "") == w then
			uci_del('@global[0]', "tcp_node")
		end
		if (uci_get("@global[0]", "udp_node") or "") == w then
			uci_del('@global[0]', "udp_node")
		end
		uci_foreach("socks", function(t)
			local changed = false
			local auto_switch_node_list = uci_get(t[".name"], "autoswitch_backup_node") or {}
			for i = #auto_switch_node_list, 1, -1 do
				if w == auto_switch_node_list[i] then
					table.remove(auto_switch_node_list, i)
					changed = true
				end
			end
			if changed then
				uci_set(t[".name"], "autoswitch_backup_node", auto_switch_node_list)
			end
			if t["node"] == w then
				local new_node = api.get_random_normal_node(ids_t)
				if new_node then
					uci_set(t[".name"], "node", new_node[".name"])
				else
					uci_set(t[".name"], "enabled", "0")
				end
			end
		end)
		uci_foreach("haproxy_config", function(t)
			if t["lbss"] == w then
				uci_del(t[".name"])
			end
		end)
		uci_foreach("nodes", function(t)
			if t["preproxy_node"] == w then
				uci_del(t[".name"], "preproxy_node")
				uci_del(t[".name"], "chain_proxy")
			end
			if t["to_node"] == w then
				uci_del(t[".name"], "to_node")
				uci_del(t[".name"], "chain_proxy")
			end
			local list_name = t["urltest_node"] and "urltest_node" or (t["balancing_node"] and "balancing_node")
			if list_name then
				local nodes = uci:get_list(c_config, t[".name"], list_name)
				if nodes then
					local changed = false
					local new_nodes = {}
					for _, node in ipairs(nodes) do
						if node ~= w and node ~= socks then
							table.insert(new_nodes, node)
						else
							changed = true
						end
					end
					if changed then
						uci_set(t[".name"], list_name, new_nodes)
					end
				end
			end
			if t["fallback_node"] == w then
				uci_del(t[".name"], "fallback_node")
			end
		end)
		uci_foreach("subscribe_list", function(t)
			if t["preproxy_node"] == w then
				uci_del(t[".name"], "preproxy_node")
				uci_del(t[".name"], "chain_proxy")
			end
			if t["to_node"] == w then
				uci_del(t[".name"], "to_node")
				uci_del(t[".name"], "chain_proxy")
			end
		end)
		if (uci_get(w, "add_mode") or "0") == "2" then
			local group = uci_get(w, "group") or ""
			if group ~= "" then
				uci_foreach("subscribe_list", function(t)
					if t["remark"] == group then
						uci_del(t[".name"], "md5")
					end
				end)
			end
		end
		uci_del(w)
	end)
	if redirect == "1" then
		uci:commit(c_config)
		http.redirect(api.url("settings"))
	else
		uci_save(true, true)
	end
	luci.sys.call("lua /usr/share/nodepool/gen_sub.lua >/dev/null 2>&1 &")
end

function get_node()
	local id = http.formvalue("id")
	local result = {}
	local show_node_info = uci_get("@global_other[0]", "show_node_info") or "0"

	local function add_is_ipv6_key(o)
		if o and o.address and show_node_info == "1" then
			local f = api.get_ipv6_full(o.address)
			if f ~= "" then
				o.ipv6 = true
				o.full_address = f
			end
		end
	end

	if id then
		result = uci_get(id)
		add_is_ipv6_key(result)
	else
		local default_nodes = {}
		local other_nodes = {}
		uci_foreach("nodes", function(t)
			add_is_ipv6_key(t)
			if not t.group or t.group == "" then
				default_nodes[#default_nodes + 1] = t
			else
				other_nodes[#other_nodes + 1] = t
			end
		end)
		for i = 1, #default_nodes do result[#result + 1] = default_nodes[i] end
		for i = 1, #other_nodes do result[#result + 1] = other_nodes[i] end
	end
	http_write_json(result)
end

function save_node_list_opt()
	local option = http.formvalue("option") or ""
	local value = http.formvalue("value") or ""
	if option ~= "" then
		api.sh_uci_set(c_config, "@global_other[0]", option, value, true)
	end
	http_write_json({ status = "ok" })
end


function subscribe_del_node()
	local remark = http.formvalue("remark")
	if remark and remark ~= "" then
		luci.sys.call("lua /usr/share/" .. appname .. "/subscribe.lua truncate " .. luci.util.shellquote(remark) .. " > /dev/null 2>&1")
	end
	http.status(200, "OK")
end

function subscribe_del_all()
	luci.sys.call("lua /usr/share/" .. appname .. "/subscribe.lua truncate > /dev/null 2>&1")
	http.status(200, "OK")
end

function subscribe_manual()
	local section = http.formvalue("section") or ""
	local current_url = http.formvalue("url") or ""
	if section == "" or current_url == "" then
		http_write_json({ success = false, msg = "Missing section or URL, skip." })
		return
	end
	local uci_url = api.sh_uci_get(c_config, section, "url")
	if not uci_url or uci_url == "" then
		http_write_json({ success = false, msg = i18n.translate("Please save and apply before manually subscribing.") })
		return
	end
	if uci_url ~= current_url then
		api.sh_uci_set(c_config, section, "url", current_url, true)
	end
	luci.sys.call("lua /usr/share/" .. appname .. "/subscribe.lua start " .. section .. " manual >/dev/null 2>&1 &")
	http_write_json({ success = true, msg = "Subscribe triggered." })
end

function subscribe_manual_all()
	local sections = http.formvalue("sections") or ""
	local urls = http.formvalue("urls") or ""
	if sections == "" or urls == "" then
		http_write_json({ success = false, msg = "Missing section or URL, skip." })
		return
	end
	local section_list = util.split(sections, ",")
	local url_list = util.split(urls, ",")
	-- 检查是否存在未保存配置
	for i, section in ipairs(section_list) do
		local uci_url = api.sh_uci_get(c_config, section, "url")
		if not uci_url or uci_url == "" then
			http_write_json({ success = false, msg = i18n.translate("Please save and apply before manually subscribing.") })
			return
		end
	end
	-- 保存有变动的url
	for i, section in ipairs(section_list) do
		local current_url = url_list[i] or ""
		local uci_url = api.sh_uci_get(c_config, section, "url")
		if current_url ~= "" and uci_url ~= current_url then
			api.sh_uci_set(c_config, section, "url", current_url, true)
		end
	end
	luci.sys.call("lua /usr/share/" .. appname .. "/subscribe.lua start all manual >/dev/null 2>&1 &")
	http_write_json({ success = true, msg = "Subscribe triggered." })
end

function clash_set_tpl()
	local tpl = http.formvalue("tpl") or ""
	if tpl:match("^[^/\\]+%.yml$") and nixio.fs.access("/usr/share/nodepool/templates/" .. tpl) then
		uci_set("@global[0]", "clash_tpl", tpl)
		uci_save()
		luci.sys.call("lua /usr/share/nodepool/gen_clash_sub.lua >/dev/null 2>&1")
		http_write_json_ok({ tpl = tpl })
	else
		http_write_json_error()
	end
end

function fetch_certsha256()
	local id = http.formvalue("id") or ""
	local address = (id ~= "") and uci_get(id, "address") or ""
	local port = (id ~= "") and uci_get(id, "port") or 0
	local sni = (id ~= "") and uci_get(id, "tls_serverName") or ""
	sni = (sni ~= "") and sni or address
	local protocol = uci_get(id, "protocol")
	local h3, timeout = false, 10
	if protocol == "hysteria2" then
		h3 = true
		timeout = 60
		if port == 0 then
			local hop = uci_get(id, "hysteria2_hop") or "0"
			port = tonumber(hop:match("^%s*(%d+)"))
		end
	end
	if address == "" or port == 0 then
		http_write_json_error()
		return
	end
	local data = api.fetch_cert_sha256(address, port, sni, timeout, h3)
	http_write_json(data ~= "" and { code = 1, data = data } or { code = 0 })
end

