module("luci.controller.nodeagg", package.seeall)

local appname = "nodeagg"

function index()
	entry({"admin", "services", "nodeagg"}, alias("admin", "services", "nodeagg", "settings"), _("节点聚合"), 60).dependent = true

	entry({"admin", "services", "nodeagg", "settings"}, cbi("nodeagg/settings"), _("节点聚合"), 1).dependent = true
	entry({"admin", "services", "nodeagg", "node_list"}, cbi("nodeagg/node_list"), _("节点列表"), 2).dependent = true
	entry({"admin", "services", "nodeagg", "subscribe"}, cbi("nodeagg/subscribe"), _("节点订阅"), 3).dependent = true
	entry({"admin", "services", "nodeagg", "subscribe_edit"}, cbi("nodeagg/subscribe_edit")).leaf = true

	entry({"admin", "services", "nodeagg", "node_list", "add_node"}, call("action_add_node")).leaf = true
	entry({"admin", "services", "nodeagg", "node_list", "copy_node"}, call("action_copy_node")).leaf = true
	entry({"admin", "services", "nodeagg", "node_list", "delete_select_nodes"}, call("action_delete_select_nodes")).leaf = true
	entry({"admin", "services", "nodeagg", "node_list", "clear_all_nodes"}, call("action_clear_all_nodes")).leaf = true
	entry({"admin", "services", "nodeagg", "node_list", "set_node"}, call("action_set_node")).leaf = true
	entry({"admin", "services", "nodeagg", "node_list", "get_node"}, call("action_get_node")).leaf = true
	entry({"admin", "services", "nodeagg", "node_list", "get_now_use_node"}, call("action_get_now_use_node")).leaf = true
	entry({"admin", "services", "nodeagg", "node_list", "ping_node"}, call("action_ping_node")).leaf = true
	entry({"admin", "services", "nodeagg", "node_list", "urltest_node"}, call("action_urltest_node")).leaf = true
	entry({"admin", "services", "nodeagg", "node_list", "link_add_node"}, call("action_link_add_node")).leaf = true
	entry({"admin", "services", "nodeagg", "node_list", "reassign_group"}, call("action_reassign_group")).leaf = true
	entry({"admin", "services", "nodeagg", "node_list", "save_node_list_opt"}, call("action_save_node_list_opt")).leaf = true
	entry({"admin", "services", "nodeagg", "node_list", "node_config"}, call("action_node_config")).leaf = true
end

local function uci_save()
	require("luci.model.uci").cursor():commit(appname)
end

local function gen_uid()
	local chars = "abcdefghijklmnopqrstuvwxyz0123456789"
	local s = ""
	for i = 1, 8 do
		local r = math.random(#chars)
		s = s .. chars:sub(r, r)
	end
	return s
end

function action_add_node()
	local redirect = http.formvalue("redirect")
	local uid = gen_uid()

	local uci = require("luci.model.uci").cursor()
	uci:section(appname, "nodes", uid)

	local group = http.formvalue("group")
	if group and group ~= "" and group ~= "default" then
		uci:set(appname, uid, "group", group)
	end

	uci:set(appname, uid, "type", "sing-box")
	uci:set(appname, uid, "remarks", uid)
	uci_save()

	if redirect == "1" then
		http.redirect(luci.dispatcher.build_url("admin", "services", "nodeagg", "node_list"))
	else
		luci.http.prepare_content("application/json")
		luci.http.write('{"result":"' .. uid .. '"}')
	end
end

function action_copy_node()
	local section = http.formvalue("section")
	if not section then
		http.redirect(luci.dispatcher.build_url("admin", "services", "nodeagg", "node_list"))
		return
	end

	local uci = require("luci.model.uci").cursor()
	local uid = gen_uid()
	uci:section(appname, "nodes", uid)

	for k, v in pairs(uci:get_all(appname, section) or {}) do
		if not k:match("^%.") and k ~= "group" then
			if k == "remarks" then v = (v or "") .. "(1)" end
			uci:set(appname, uid, k, v)
		end
	end

	uci_save()
	http.redirect(luci.dispatcher.build_url("admin", "services", "nodeagg", "node_list"))
end

function action_delete_select_nodes()
	local ids = http.formvalue("ids")
	if not ids or ids == "" then
		luci.http.status(400, "No IDs")
		return
	end

	local uci = require("luci.model.uci").cursor()
	for id in ids:gmatch("[^,]+") do
		uci:delete(appname, id)
	end
	uci_save()
	luci.http.prepare_content("application/json")
	luci.http.write('{"result":"ok"}')
end

function action_clear_all_nodes()
	local uci = require("luci.model.uci").cursor()
	uci:foreach(appname, "nodes", function(t)
		uci:delete(appname, t[".name"])
	end)
	uci_save()
	luci.http.prepare_content("application/json")
	luci.http.write('{"result":"ok"}')
end

function action_set_node()
	local protocol = http.formvalue("protocol")
	local section = http.formvalue("section")
	if not protocol or not section then
		http.redirect(luci.dispatcher.build_url("admin", "services", "nodeagg", "node_list"))
		return
	end

	local uci = require("luci.model.uci").cursor()
	uci:set(appname, "@global[0]", protocol .. "_node", section)
	uci_save()
	http.redirect(luci.dispatcher.build_url("admin", "services", "nodeagg", "node_list"))
end

function action_get_node()
	local uci = require("luci.model.uci").cursor()
	local e = {}
	uci:foreach(appname, "nodes", function(t)
		if t["type"] and t["type"] ~= "global" and t["type"] ~= "global_other"
			and t["type"] ~= "global_subscribe" then
			e[#e + 1] = t
		end
	end)

	luci.http.prepare_content("application/json")
	luci.http.write(luci.jsonc.stringify(e))
end

function action_get_now_use_node()
	local uci = require("luci.model.uci").cursor()
	local result = {}
	result["TCP"] = uci:get(appname, "@global[0]", "tcp_node") or ""
	result["UDP"] = uci:get(appname, "@global[0]", "udp_node") or ""
	luci.http.prepare_content("application/json")
	luci.http.write(luci.jsonc.stringify(result))
end

function action_ping_node()
	local address = http.formvalue("address")
	local port = http.formvalue("port")
	local type = http.formvalue("type")
	if not address or address == "" then
		luci.http.prepare_content("application/json")
		luci.http.write('{"ping":""}')
		return
	end

	local result = ""
	if type == "icmp" then
		local cmd = "ping -c 1 -W 3 " .. luci.util.shellquote(address) .. " 2>/dev/null | grep -oP 'time=\\K[0-9.]+'"
		result = luci.sys.exec(cmd):match("^%s*(.-)%s*$") or ""
	elseif type == "tcping" and port and port ~= "" then
		local cmd = "tcping -c 1 -W 3 " .. luci.util.shellquote(address) .. " " .. port .. " 2>/dev/null | grep -oP 'time=\\K[0-9.]+'"
		result = luci.sys.exec(cmd):match("^%s*(.-)%s*$") or ""
		if result == "" then
			cmd = "timeout 3 bash -c 'echo > /dev/tcp/" .. luci.util.shellquote(address) .. "/" .. port .. "' 2>/dev/null && echo 0"
			result = luci.sys.exec(cmd):match("^%s*(.-)%s*$") or ""
		end
	end

	luci.http.prepare_content("application/json")
	luci.http.write('{"ping":"' .. result .. '"}')
end

function action_urltest_node()
	local id = http.formvalue("id")
	if not id then
		luci.http.prepare_content("application/json")
		luci.http.write('{"use_time":""}')
		return
	end

	local uci = require("luci.model.uci").cursor()
	local address = uci:get(appname, id, "address") or ""
	local port = uci:get(appname, id, "port") or ""

	if address == "" or port == "" then
		luci.http.prepare_content("application/json")
		luci.http.write('{"use_time":""}')
		return
	end

	local cmd = "curl -sko /dev/null -w '%{time_total}' --connect-timeout 5 --max-time 10 " .. luci.util.shellquote("https://" .. address .. ":" .. port)
	local use_time = luci.sys.exec(cmd):match("^%s*(.-)%s*$") or ""
	if use_time ~= "" then
		use_time = tostring(math.floor(tonumber(use_time) * 1000))
	end

	luci.http.prepare_content("application/json")
	luci.http.write('{"use_time":"' .. use_time .. '"}')
end

function action_link_add_node()
	local chunk = http.formvalue("chunk")
	local chunk_index = tonumber(http.formvalue("chunk_index"))
	local total_chunks = tonumber(http.formvalue("total_chunks"))
	local group = http.formvalue("group") or "default"
	local tmp_file = "/tmp/nodeagg_links.txt"

	if chunk and chunk_index ~= nil and total_chunks ~= nil then
		local mode = chunk_index == 0 and "w" or "a"
		local f = io.open(tmp_file, mode)
		if f then
			f:write(chunk)
			f:close()
		end
		if chunk_index + 1 == total_chunks then
			luci.sys.call("nodeagg-subscribe add " .. group .. " " .. tmp_file)
			os.remove(tmp_file)
		end
	end

	luci.http.prepare_content("application/json")
	luci.http.write('{"result":"ok"}')
end

function action_reassign_group()
	local ids = http.formvalue("ids")
	local group = http.formvalue("group") or "default"
	if not ids or ids == "" then
		luci.http.status(400, "No IDs")
		return
	end

	local uci = require("luci.model.uci").cursor()
	for id in ids:gmatch("[^,]+") do
		if group == "default" then
			uci:delete(appname, id, "group")
		else
			uci:set(appname, id, "group", group)
		end
	end
	uci_save()
	luci.http.prepare_content("application/json")
	luci.http.write('{"result":"ok"}')
end

function action_save_node_list_opt()
	local option = http.formvalue("option")
	local value = http.formvalue("value")
	if option then
		local uci = require("luci.model.uci").cursor()
		uci:set(appname, "@global_other[0]", option, value)
		uci_save()
	end
	luci.http.prepare_content("application/json")
	luci.http.write('{"result":"ok"}')
end

function action_node_config()
	local section = http.formvalue("section")
	if not section then
		http.redirect(luci.dispatcher.build_url("admin", "services", "nodeagg", "node_list"))
		return
	end
	http.redirect(luci.dispatcher.build_url("admin", "services", "nodeagg", "node_list"))
end
