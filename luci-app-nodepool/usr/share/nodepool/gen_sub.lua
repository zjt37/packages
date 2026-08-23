#!/usr/bin/lua

package.path = "/usr/lib/lua/?.lua;/usr/lib/lua/?/init.lua;" .. package.path
package.cpath = "/usr/lib/lua/?.so;" .. package.cpath

local api = require "luci.nodepool.api"

local uci = api.uci
local enabled = uci:get("nodepool", "@global[0]", "aggregate_sub_enabled") or "0"
if enabled ~= "1" then
	os.remove("/www/nodepool_sub.txt")
	os.remove("/www/nodepool_clash.yaml")
	return
end

local function b64_safe(text)
	return api.base64Encode(text):gsub("+", "-"):gsub("/", "_"):gsub("=+$", "")
end

local function b64_url_utf8(text)
	return b64_safe(api.UrlEncode(text))
end

local function b64_json(obj)
	return api.base64Encode(luci.jsonc.stringify(obj))
end

local function build_transport_params(n, prefix)
	prefix = prefix or ""
	local params = ""
	local transport = n[prefix .. "transport"] or ""
	if transport == "ws" then
		if n[prefix .. "ws_host"] and n[prefix .. "ws_host"] ~= "" then
			params = params .. "&host=" .. api.UrlEncode(n[prefix .. "ws_host"])
		end
		if n[prefix .. "ws_path"] and n[prefix .. "ws_path"] ~= "" then
			local path = n[prefix .. "ws_path"]
			if n[prefix .. "ws_enableEarlyData"] == "1" and n[prefix .. "ws_maxEarlyData"] and n[prefix .. "ws_maxEarlyData"] ~= "" then
				path = path .. "?ed=" .. n[prefix .. "ws_maxEarlyData"]
			end
			params = params .. "&path=" .. api.UrlEncode(path)
		end
	elseif transport == "http" then
		if n[prefix .. "http_host"] and n[prefix .. "http_host"] ~= "" then
			params = params .. "&host=" .. api.UrlEncode(n[prefix .. "http_host"])
		end
		if n[prefix .. "http_path"] and n[prefix .. "http_path"] ~= "" then
			params = params .. "&path=" .. api.UrlEncode(n[prefix .. "http_path"])
		end
	elseif transport == "raw" or transport == "tcp" then
		transport = "tcp"
		if n[prefix .. "tcp_guise"] and n[prefix .. "tcp_guise"] ~= "" then
			params = params .. "&headerType=" .. api.UrlEncode(n[prefix .. "tcp_guise"])
			if n[prefix .. "tcp_guise"] == "http" then
				if n[prefix .. "tcp_guise_http_host"] and n[prefix .. "tcp_guise_http_host"] ~= "" then
					params = params .. "&host=" .. api.UrlEncode(n[prefix .. "tcp_guise_http_host"])
				end
				if n[prefix .. "tcp_guise_http_path"] and n[prefix .. "tcp_guise_http_path"] ~= "" then
					params = params .. "&path=" .. api.UrlEncode(n[prefix .. "tcp_guise_http_path"])
				end
			end
		end
	elseif transport == "mkcp" then
		transport = "kcp"
		if n[prefix .. "mkcp_guise"] and n[prefix .. "mkcp_guise"] ~= "" then
			params = params .. "&headerType=" .. api.UrlEncode(n[prefix .. "mkcp_guise"])
		end
		if n[prefix .. "mkcp_seed"] and n[prefix .. "mkcp_seed"] ~= "" then
			params = params .. "&seed=" .. api.UrlEncode(n[prefix .. "mkcp_seed"])
		end
	elseif transport == "grpc" then
		if n[prefix .. "grpc_serviceName"] and n[prefix .. "grpc_serviceName"] ~= "" then
			params = params .. "&serviceName=" .. api.UrlEncode(n[prefix .. "grpc_serviceName"])
		end
		if n[prefix .. "grpc_mode"] and n[prefix .. "grpc_mode"] ~= "" then
			params = params .. "&mode=" .. api.UrlEncode(n[prefix .. "grpc_mode"])
		end
	elseif transport == "xhttp" then
		if n[prefix .. "xhttp_host"] and n[prefix .. "xhttp_host"] ~= "" then
			params = params .. "&host=" .. api.UrlEncode(n[prefix .. "xhttp_host"])
		end
		if n[prefix .. "xhttp_path"] and n[prefix .. "xhttp_path"] ~= "" then
			params = params .. "&path=" .. api.UrlEncode(n[prefix .. "xhttp_path"])
		end
		if n[prefix .. "xhttp_mode"] and n[prefix .. "xhttp_mode"] ~= "" then
			params = params .. "&mode=" .. api.UrlEncode(n[prefix .. "xhttp_mode"])
		end
	elseif transport == "httpupgrade" then
		if n[prefix .. "httpupgrade_host"] and n[prefix .. "httpupgrade_host"] ~= "" then
			params = params .. "&host=" .. api.UrlEncode(n[prefix .. "httpupgrade_host"])
		end
		if n[prefix .. "httpupgrade_path"] and n[prefix .. "httpupgrade_path"] ~= "" then
			params = params .. "&path=" .. api.UrlEncode(n[prefix .. "httpupgrade_path"])
		end
	end
	if transport ~= "" then
		params = params .. "&type=" .. transport
	end
	return params
end

local function build_tls_params(n, prefix)
	prefix = prefix or ""
	local params = ""
	if n[prefix .. "tls"] == "1" then
		local security = "tls"
		if n[prefix .. "fingerprint"] and n[prefix .. "fingerprint"] ~= "" then
			params = params .. "&fp=" .. api.UrlEncode(n[prefix .. "fingerprint"])
		end
		if n[prefix .. "reality"] == "1" then
			security = "reality"
			if n[prefix .. "reality_publicKey"] and n[prefix .. "reality_publicKey"] ~= "" then
				params = params .. "&pbk=" .. api.UrlEncode(n[prefix .. "reality_publicKey"])
			end
			if n[prefix .. "reality_shortId"] and n[prefix .. "reality_shortId"] ~= "" then
				params = params .. "&sid=" .. api.UrlEncode(n[prefix .. "reality_shortId"])
			end
			if n[prefix .. "reality_spiderX"] and n[prefix .. "reality_spiderX"] ~= "" then
				params = params .. "&spx=" .. api.UrlEncode(n[prefix .. "reality_spiderX"])
			end
		end
		if n[prefix .. "flow"] and n[prefix .. "flow"] ~= "" then
			params = params .. "&flow=" .. api.UrlEncode(n[prefix .. "flow"])
		end
		params = params .. "&security=" .. security
		if n[prefix .. "alpn"] and n[prefix .. "alpn"] ~= "" and n[prefix .. "alpn"] ~= "default" then
			params = params .. "&alpn=" .. api.UrlEncode(n[prefix .. "alpn"])
		end
		if n[prefix .. "tls_serverName"] and n[prefix .. "tls_serverName"] ~= "" then
			params = params .. "&sni=" .. api.UrlEncode(n[prefix .. "tls_serverName"])
		end
		if n[prefix .. "tls_allowInsecure"] == "1" then
			params = params .. "&allowinsecure=1"
		end
		if n[prefix .. "tls_pinSHA256"] and n[prefix .. "tls_pinSHA256"] ~= "" then
			params = params .. "&pcs=" .. api.UrlEncode(n[prefix .. "tls_pinSHA256"])
		end
		if n[prefix .. "ech_config"] and n[prefix .. "ech_config"] ~= "" then
			params = params .. "&ech=" .. api.UrlEncode(n[prefix .. "ech_config"])
		end
	else
		params = params .. "&security=none"
	end
	return params
end

local function build_share_link(n)
	local type_name = n.type or ""
	local protocol = n.protocol or ""
	local address = n.address or ""
	local remarks = n.remarks or ""
	if address == "" then return nil end
	if protocol == "_balancing" or protocol == "_shunt" or protocol == "_iface" or protocol == "_urltest" then return nil end
	local port = n.port or n.hysteria_hop or n.hysteria2_hop or ""
	if port == "" then return nil end

	local real_protocol = protocol
	if type_name == "SS-Rust" then real_protocol = "shadowsocks" end

	if real_protocol == "shadowsocks" then
		local method = n.method or n.ss_method or ""
		local password = n.password or ""
		if method == "" or password == "" then return nil end
		local params = ""
		if n.tcp_fast_open == "1" then params = "&tfo=1" end
		local plugin = n.plugin
		if plugin and plugin ~= "" and plugin ~= "none" then
			if plugin == "simple-obfs" or plugin == "obfs-local" then plugin = "obfs-local" end
			if n.plugin_opts and n.plugin_opts ~= "" then plugin = plugin .. ";" .. n.plugin_opts end
			params = params .. "&plugin=" .. api.UrlEncode(plugin)
		end
		params = params .. "#" .. api.UrlEncode(remarks)
		if params:sub(1,1) == "&" then params = params:sub(2) end
		return "ss://" .. b64_safe(method .. ":" .. password) .. "@" .. address .. ":" .. port .. "/?" .. params
	elseif real_protocol == "shadowsocksr" then
		local ssr_str = address .. ":" .. port .. ":" .. (n.ssr_protocol or "") .. ":" .. (n.method or "") .. ":" .. (n.obfs or "") .. ":" .. b64_safe(n.password or "") .. "/?obfsparam=" .. b64_safe(n.obfs_param or "") .. "&protoparam=" .. b64_safe(n.protocol_param or "") .. "&remarks=" .. b64_url_utf8(remarks)
		return "ssr://" .. b64_safe(ssr_str)
	elseif real_protocol == "vmess" then
		local info = { v="2", ps=remarks, add=address, port=port, id=n.uuid or "", aid="0", net=n.transport or "tcp", type="none", host="", path="", tls="", scy="" }
		local transport = n.transport or "tcp"
		if transport == "ws" then
			info.host = n.ws_host or ""
			local path = n.ws_path or ""
			if n.ws_enableEarlyData == "1" and n.ws_maxEarlyData and n.ws_maxEarlyData ~= "" then path = path .. "?ed=" .. n.ws_maxEarlyData end
			info.path = path
		elseif transport == "http" then info.host = n.http_host or ""; info.path = n.http_path or ""
		elseif transport == "raw" or transport == "tcp" then info.net = "tcp"; info.type = n.tcp_guise or "none"; if info.type == "http" then info.host = n.tcp_guise_http_host or ""; info.path = n.tcp_guise_http_path or "" end
		elseif transport == "mkcp" then info.net = "kcp"; info.type = n.mkcp_guise or "none"; info.seed = n.mkcp_seed or ""
		elseif transport == "quic" then info.net = "quic"; info.type = n.quic_guise or "none"; info.key = n.quic_key or ""; info.securty = n.quic_security or ""
		elseif transport == "grpc" then info.path = n.grpc_serviceName or ""
		end
		if n.tls == "1" then info.tls = "tls"; info.sni = n.tls_serverName or ""; if n.alpn and n.alpn ~= "" and n.alpn ~= "default" then info.alpn = n.alpn end; if n.fingerprint and n.fingerprint ~= "" then info.fp = n.fingerprint end; if n.tls_allowInsecure == "1" then info.insecure = "1" end end
		if n.tcp_fast_open == "1" then info.tfo = "1" end
		info.security = n.security or "auto"; info.scy = info.security
		return "vmess://" .. b64_json(info)
	elseif real_protocol == "vless" then
		local params = build_transport_params(n) .. "&encryption=none" .. build_tls_params(n)
		if n.tcp_fast_open == "1" then params = params .. "&tfo=1" end
		params = params .. "#" .. api.UrlEncode(remarks)
		if params:sub(1,1) == "&" then params = params:sub(2) end
		return "vless://" .. api.UrlEncode(n.uuid or "") .. "@" .. address .. ":" .. port .. "?" .. params
	elseif real_protocol == "trojan" then
		local params = build_transport_params(n) .. build_tls_params(n)
		if n.tcp_fast_open == "1" then params = params .. "&tfo=1" end
		params = params .. "#" .. api.UrlEncode(remarks)
		if params:sub(1,1) == "&" then params = params:sub(2) end
		return "trojan://" .. api.UrlEncode(n.password or "") .. "@" .. address .. ":" .. port .. "?" .. params
	elseif real_protocol == "hysteria2" or type_name == "Hysteria2" then
		local params = ""
		if n.tls_serverName and n.tls_serverName ~= "" then params = params .. "&sni=" .. api.UrlEncode(n.tls_serverName) end
		if n.tls_allowInsecure == "1" then params = params .. "&insecure=1" end
		if n.hysteria2_obfs_type and n.hysteria2_obfs_type ~= "" then params = params .. "&obfs=" .. api.UrlEncode(n.hysteria2_obfs_type); if n.hysteria2_obfs_password and n.hysteria2_obfs_password ~= "" then params = params .. "&obfs-password=" .. api.UrlEncode(n.hysteria2_obfs_password) end end
		if n.hysteria2_hop and n.hysteria2_hop ~= "" then params = params .. "&mport=" .. api.UrlEncode(n.hysteria2_hop) end
		params = params:gsub("^&", "")
		local url = address .. ":" .. port .. "?" .. params .. "#" .. api.UrlEncode(remarks)
		if n.hysteria2_auth_password and n.hysteria2_auth_password ~= "" then url = api.UrlEncode(n.hysteria2_auth_password) .. "@" .. url end
		return "hysteria2://" .. url
	elseif real_protocol == "anytls" then
		local params = build_tls_params(n) .. "#" .. api.UrlEncode(remarks)
		if params:sub(1,1) == "&" then params = params:sub(2) end
		return "anytls://" .. api.UrlEncode(n.password or "") .. "@" .. address .. ":" .. port .. "?" .. params
	elseif real_protocol == "tuic" then
		local params = ""
		if n.tls_serverName and n.tls_serverName ~= "" then params = params .. "&sni=" .. api.UrlEncode(n.tls_serverName) end
		if n.tuic_alpn and n.tuic_alpn ~= "" then params = params .. "&alpn=" .. api.UrlEncode(n.tuic_alpn) end
		if n.tuic_congestion_control and n.tuic_congestion_control ~= "" then params = params .. "&congestion_control=" .. api.UrlEncode(n.tuic_congestion_control) end
		if n.tuic_udp_relay_mode and n.tuic_udp_relay_mode ~= "" then params = params .. "&udp_relay_mode=" .. api.UrlEncode(n.tuic_udp_relay_mode) end
		if n.tls_allowInsecure == "1" then params = params .. "&allowinsecure=1" end
		params = params:gsub("^&", "")
		return "tuic://" .. api.UrlEncode(n.uuid or "") .. ":" .. api.UrlEncode(n.password or "") .. "@" .. address .. ":" .. port .. "?" .. params .. "#" .. api.UrlEncode(remarks)
	elseif real_protocol == "naive" then
		local params = "security=tls"
		if n.tls_serverName and n.tls_serverName ~= "" then params = params .. "&sni=" .. api.UrlEncode(n.tls_serverName) end
		local proto = "naive+https"
		if n.naive_quic == "1" then proto = "naive+quic" end
		params = params .. "#" .. api.UrlEncode(remarks)
		return proto .. "://" .. api.UrlEncode(n.username or "") .. ":" .. api.UrlEncode(n.password or "") .. "@" .. address .. ":" .. port .. "?" .. params
	end
	return nil
end

local nodes = api.get_valid_nodes()
local links = {}
for _, n in ipairs(nodes) do
	if n.node_type == "normal" then
		local link = build_share_link(n)
		if link then links[#links + 1] = link end
	end
end
local content = table.concat(links, "\n")
local encoded = api.base64Encode(content)

local f = io.open("/www/nodepool_sub.txt", "w")
if f then
	f:write(encoded)
	f:close()
	os.execute("lua /usr/share/nodepool/gen_clash_sub.lua >/dev/null 2>&1")
	print("OK: " .. #links .. " nodes exported to /www/nodepool_sub.txt")
else
	print("ERROR: cannot write /www/nodepool_sub.txt")
end
