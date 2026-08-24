#!/usr/bin/lua
-- NodePool 订阅转换工具：聚合订阅(nodepool_sub.txt) -> Clash 订阅(nodepool_clash.yaml)

package.path = "/usr/lib/lua/?.lua;/usr/lib/lua/?/init.lua;" .. package.path
package.cpath = "/usr/lib/lua/?.so;" .. package.cpath

local api = require "luci.nodepool.api"

local SRC = "/www/nodepool_sub.txt"
local DST = "/www/nodepool_clash.yaml"
local TPL_DIR = "/usr/share/nodepool/templates/"
local LEGACY_TPL = "/usr/share/nodepool/clash_template.yml"

pcall(require, "nixio.fs")

local function list_templates()
	local list = {}
	local ok, iter = pcall(nixio.fs.dir, TPL_DIR)
	if ok and iter then
		for f in iter do
			if f:match("%.yml$") then list[#list + 1] = f end
		end
	end
	table.sort(list)
	return list
end

local function find_template()
	local sel = api.uci:get("nodepool", "@global[0]", "clash_tpl") or ""
	local list = list_templates()
	if sel ~= "" then
		for _, f in ipairs(list) do
			if f == sel then return TPL_DIR .. f end
		end
	end
	if #list > 0 then return TPL_DIR .. list[1] end
	if nixio.fs.access(LEGACY_TPL) then return LEGACY_TPL end
	return nil
end

local f = io.open(SRC, "r")
if not f then os.remove(DST); return end
local raw = f:read("*a")
f:close()
if not raw or raw == "" then os.remove(DST); return end
local content = api.base64Decode(raw)

local function q(v)
	v = tostring(v == nil and "" or v)
	return '"' .. v:gsub("\\", "\\\\"):gsub('"', '\\"'):gsub("\r", ""):gsub("\n", "\\n") .. '"'
end

local seen_names = {}
local function uniq(name)
	if not name or name == "" then name = "node" end
	if seen_names[name] then
		local i = 2
		while seen_names[name .. i] do i = i + 1 end
		name = name .. i
	end
	seen_names[name] = true
	return name
end

local proxies, names_list = {}, {}

local function add_proxy(display_name, fields)
	display_name = uniq(display_name)
	table.insert(fields, 1, "name: " .. q(display_name))
	proxies[#proxies + 1] = "  - {" .. table.concat(fields, ", ") .. "}"
	names_list[#names_list + 1] = "      - " .. q(display_name)
end

local function split_hostport(s)
	s = s or ""
	local host, port = s:match("^%[(.-)%]:(%d+)$")
	if host then return host, tonumber(port) end
	host, port = s:match("^(.+):(%d+)$")
	if host then return host, tonumber(port) end
	return s, nil
end

local function parse_uri(link)
	local rest = link
	local frag = rest:match("#(.*)$")
	rest = rest:gsub("#.*$", "")
	local query = rest:match("%?(.*)$") or ""
	rest = rest:gsub("%?.*$", "")
	rest = rest:gsub("^%w+://", "")
	local userinfo, hostport
	if rest:find("@") then
		userinfo, hostport = rest:match("^(.*)@(.*)$")
	else
		hostport = rest
	end
	hostport = (hostport or ""):gsub("/.*$", "")
	local server, port = split_hostport(hostport)
	local user, pass
	if userinfo then
		user = userinfo:match("^(.-):")
		pass = userinfo:match(":(.*)$")
		if user == nil then user = userinfo; pass = "" end
		user = api.UrlDecode(user)
		pass = api.UrlDecode(pass)
	end
	local params = {}
	for k, v in query:gmatch("([^&=]+)=([^&]*)") do
		params[api.UrlDecode(k)] = api.UrlDecode(v)
	end
	return { user = user, pass = pass, server = server, port = tonumber(port), params = params, frag = api.UrlDecode(frag or "") }
end

local function alpn_flow(s)
	if not s or s == "" then return nil end
	local t = {}
	for w in s:gmatch("[^,%s;]+") do t[#t + 1] = q(w) end
	if #t == 0 then return nil end
	return "[" .. table.concat(t, ", ") .. "]"
end

local function ws_opts(path, host)
	local o = { 'path: ' .. q((path and path ~= "") and path or "/") }
	if host and host ~= "" then o[#o + 1] = 'headers: {Host: ' .. q(host) .. '}' end
	return "ws-opts: {" .. table.concat(o, ", ") .. "}"
end

local function hu_opts(path, host)
	local o = { 'path: ' .. q((path and path ~= "") and path or "/") }
	if host and host ~= "" then o[#o + 1] = 'headers: {Host: ' .. q(host) .. '}' end
	return "httpupgrade-opts: {" .. table.concat(o, ", ") .. "}"
end

local function h2_opts(host, path)
	local o = {}
	local hosts = {}
	for w in (host or ""):gmatch("[^,%s]+") do hosts[#hosts + 1] = q(w) end
	if #hosts > 0 then o[#o + 1] = 'host: [' .. table.concat(hosts, ", ") .. ']' end
	o[#o + 1] = 'path: ' .. q((path and path ~= "") and path or "/")
	return "h2-opts: {" .. table.concat(o, ", ") .. "}"
end

local function apply_transport(fields, net, p)
	net = net or "tcp"
	if net == "ws" then
		fields[#fields + 1] = "network: ws"
		fields[#fields + 1] = ws_opts(p.path, p.host)
	elseif net == "grpc" then
		fields[#fields + 1] = "network: grpc"
		fields[#fields + 1] = "grpc-opts: {grpc-service-name: " .. q(p.serviceName or p.path or "") .. "}"
	elseif net == "http" or net == "h2" then
		fields[#fields + 1] = "network: h2"
		fields[#fields + 1] = h2_opts(p.host, p.path)
	elseif net == "httpupgrade" then
		fields[#fields + 1] = "network: httpupgrade"
		fields[#fields + 1] = hu_opts(p.path, p.host)
	elseif net == "xhttp" or net == "splithttp" then
		return false
	end
	return true
end

local function apply_tls(fields, sec, p, sni_key)
	if sec ~= "tls" and sec ~= "reality" then return end
	fields[#fields + 1] = "tls: true"
	if p.sni and p.sni ~= "" then fields[#fields + 1] = sni_key .. ": " .. q(p.sni) end
	local a = alpn_flow(p.alpn)
	if a then fields[#fields + 1] = "alpn: " .. a end
	if p.fp and p.fp ~= "" then fields[#fields + 1] = "client-fingerprint: " .. q(p.fp) end
	if sec == "reality" then
		local ro = {}
		if p.pbk and p.pbk ~= "" then ro[#ro + 1] = 'public-key: ' .. q(p.pbk) end
		if p.sid and p.sid ~= "" then ro[#ro + 1] = 'short-id: ' .. q(p.sid) end
		if #ro > 0 then fields[#fields + 1] = "reality-opts: {" .. table.concat(ro, ", ") .. "}" end
	end
	if p.allowinsecure == "1" then fields[#fields + 1] = "skip-cert-verify: true" end
end

local function h_ss(link)
	local rest = link:gsub("^ss://", "", 1)
	local remark = ""
	local pos = rest:find("#")
	if pos then remark = api.UrlDecode(rest:sub(pos + 1)); rest = rest:sub(1, pos - 1) end
	local query = ""
	local qm = rest:find("?")
	if qm then query = rest:sub(qm + 1); rest = rest:sub(1, qm - 1) end
	local userinfo, hostport
	if rest:find("@") then
		userinfo, hostport = rest:match("^(.*)@(.*)$")
	else
		local d = api.base64Decode(rest)
		userinfo, hostport = d:match("^(.*)@(.*)$")
	end
	if not hostport then return end
	hostport = hostport:gsub("/.*$", "")
	if userinfo and not userinfo:find(":") then userinfo = api.base64Decode(userinfo) end
	local method = userinfo and userinfo:match("^(.-):") or nil
	local password = userinfo and userinfo:match(":(.*)$") or nil
	if not method or method == "" then return end
	local server, port = split_hostport(hostport)
	if not server or not port then return end
	local fields = {
		"type: ss",
		"server: " .. q(server),
		"port: " .. port,
		"cipher: " .. q(method),
		"password: " .. q(password),
		"udp: true"
	}
	for k, v in query:gmatch("([^&=]+)=([^&]*)") do
		if api.UrlDecode(k) == "plugin" then
			local pv = api.UrlDecode(v)
			local pname = pv:match("^[^;]+")
			if pname == "obfs-local" or pname == "simple-obfs" then
				fields[#fields + 1] = "plugin: obfs"
				local mode, ohost
				for opt in pv:gmatch("[^;]+") do
					local kk, vv = opt:match("^([^=]+)=(.*)$")
					if kk == "obfs" then mode = vv elseif kk == "obfs-host" then ohost = vv end
				end
				local oo = { 'mode: ' .. q(mode or "http") }
				if ohost then oo[#oo + 1] = 'host: ' .. q(ohost) end
				fields[#fields + 1] = "plugin-opts: {" .. table.concat(oo, ", ") .. "}"
			end
		end
	end
	add_proxy((remark ~= "" and remark) or server, fields)
end

local function h_ssr(link)
	local d = api.base64Decode(link:gsub("^ssr://", "", 1))
	local main, querypart = d:match("^([^/?]+)/?(.*)$")
	if not main then return end
	local t = {}
	for w in main:gmatch("[^:]+") do t[#t + 1] = w end
	local n = #t
	if n < 6 then return end
	local pwd_b64, obfs, method, protocol = t[n], t[n - 1], t[n - 2], t[n - 3]
	local port = tonumber(t[n - 4])
	if not port then return end
	local hp = {}
	for i = 1, n - 5 do hp[i] = t[i] end
	local server = table.concat(hp, ":"):gsub("^%[", ""):gsub("%]", "")
	local params = {}
	for k, v in querypart:gmatch("([^&=]+)=([^&]*)") do params[k] = v end
	local fields = {
		"type: ssr",
		"server: " .. q(server),
		"port: " .. port,
		"cipher: " .. q(method),
		"password: " .. q(api.base64Decode(pwd_b64)),
		"udp: true",
		"protocol: " .. q(protocol),
		"protocol-param: " .. q(api.base64Decode(params.protoparam or "")),
		"obfs: " .. q(obfs),
		"obfs-param: " .. q(api.base64Decode(params.obfsparam or ""))
	}
	add_proxy(api.base64Decode(params.remarks or ""), fields)
end

local function h_vmess(link)
	local ok, info = pcall(luci.jsonc.parse, api.base64Decode(link:gsub("^vmess://", "", 1)))
	if not ok or type(info) ~= "table" then return end
	local server = info.add or ""
	local port = tonumber(info.port) or 0
	if server == "" or port == 0 then return end
	local fields = {
		"type: vmess",
		"server: " .. q(server),
		"port: " .. port,
		"uuid: " .. q(info.id or ""),
		"alterId: " .. (tonumber(info.aid) or 0),
		"cipher: " .. q(info.scy or "auto"),
		"udp: true"
	}
	local net = info.net or "tcp"
	if net == "tcp" then
		if info.type == "http" then
			local ho = { 'method: GET', 'path: [' .. q(info.path or "/") .. ']' }
			if info.host and info.host ~= "" then ho[#ho + 1] = 'headers: {Host: [' .. q(info.host) .. ']}' end
			fields[#fields + 1] = "network: http"
			fields[#fields + 1] = "http-opts: {" .. table.concat(ho, ", ") .. "}"
		end
	elseif net == "ws" then
		fields[#fields + 1] = "network: ws"
		fields[#fields + 1] = ws_opts(info.path, info.host)
	elseif net == "grpc" then
		fields[#fields + 1] = "network: grpc"
		fields[#fields + 1] = "grpc-opts: {grpc-service-name: " .. q(info.path or "") .. "}"
	elseif net == "h2" or net == "http" then
		fields[#fields + 1] = "network: h2"
		fields[#fields + 1] = h2_opts(info.host, info.path)
	else
		return
	end
	if info.tls == "tls" then
		fields[#fields + 1] = "tls: true"
		if info.sni and info.sni ~= "" then fields[#fields + 1] = "servername: " .. q(info.sni) end
		local a = alpn_flow(info.alpn)
		if a then fields[#fields + 1] = "alpn: " .. a end
		if info.fp and info.fp ~= "" then fields[#fields + 1] = "client-fingerprint: " .. q(info.fp) end
		if info.insecure == "1" then fields[#fields + 1] = "skip-cert-verify: true" end
	end
	add_proxy(info.ps or "", fields)
end

local function h_vless(link)
	local u = parse_uri(link)
	if not u.server or not u.port or not u.user or u.user == "" then return end
	local p = u.params
	local fields = {
		"type: vless",
		"server: " .. q(u.server),
		"port: " .. u.port,
		"uuid: " .. q(u.user),
		"udp: true"
	}
	if not apply_transport(fields, p.type, p) then return end
	apply_tls(fields, p.security, p, "servername")
	if p.flow and p.flow ~= "" then fields[#fields + 1] = "flow: " .. q(p.flow) end
	add_proxy(u.frag, fields)
end

local function h_trojan(link)
	local u = parse_uri(link)
	local password = (u.pass and u.pass ~= "" and u.pass) or u.user or ""
	if not u.server or not u.port or password == "" then return end
	local p = u.params
	local fields = {
		"type: trojan",
		"server: " .. q(u.server),
		"port: " .. u.port,
		"password: " .. q(password),
		"udp: true"
	}
	if not apply_transport(fields, p.type, p) then return end
	apply_tls(fields, p.security ~= "" and p.security or "tls", p, "sni")
	add_proxy(u.frag, fields)
end

local function h_hysteria2(link)
	local u = parse_uri(link)
	if not u.server or not u.port then return end
	local auth = (u.pass and u.pass ~= "" and u.pass) or u.user or ""
	local p = u.params
	local fields = {
		"type: hysteria2",
		"server: " .. q(u.server),
		"port: " .. u.port,
		"password: " .. q(auth)
	}
	if p.obfs and p.obfs ~= "" then
		fields[#fields + 1] = "obfs: " .. q(p.obfs)
		if p["obfs-password"] and p["obfs-password"] ~= "" then fields[#fields + 1] = "obfs-password: " .. q(p["obfs-password"]) end
	end
	if p.sni and p.sni ~= "" then fields[#fields + 1] = "sni: " .. q(p.sni) end
	if p.insecure == "1" then fields[#fields + 1] = "skip-cert-verify: true" end
	if p.mport and p.mport ~= "" then fields[#fields + 1] = "ports: " .. q(p.mport) end
	add_proxy(u.frag, fields)
end

local function h_tuic(link)
	local u = parse_uri(link)
	if not u.server or not u.port or not u.user or u.user == "" then return end
	local p = u.params
	local fields = {
		"type: tuic",
		"server: " .. q(u.server),
		"port: " .. u.port,
		"uuid: " .. q(u.user),
		"password: " .. q(u.pass or ""),
		"reduce-rtt: true"
	}
	if p.sni and p.sni ~= "" then fields[#fields + 1] = "sni: " .. q(p.sni) end
	local a = alpn_flow(p.alpn)
	if a then fields[#fields + 1] = "alpn: " .. a end
	if p.congestion_control and p.congestion_control ~= "" then fields[#fields + 1] = "congestion-controller: " .. q(p.congestion_control) end
	if p.udp_relay_mode and p.udp_relay_mode ~= "" then fields[#fields + 1] = "udp-relay-mode: " .. q(p.udp_relay_mode) end
	if p.allowinsecure == "1" then fields[#fields + 1] = "skip-cert-verify: true" end
	add_proxy(u.frag, fields)
end

local function h_anytls(link)
	local u = parse_uri(link)
	local password = (u.pass and u.pass ~= "" and u.pass) or u.user or ""
	if not u.server or not u.port or password == "" then return end
	local p = u.params
	local fields = {
		"type: anytls",
		"server: " .. q(u.server),
		"port: " .. u.port,
		"password: " .. q(password),
		"udp: true"
	}
	apply_tls(fields, p.security ~= "" and p.security or "tls", p, "sni")
	add_proxy(u.frag, fields)
end

local handlers = {
	ss = h_ss,
	ssr = h_ssr,
	vmess = h_vmess,
	vless = h_vless,
	trojan = h_trojan,
	hysteria2 = h_hysteria2,
	hy2 = h_hysteria2,
	tuic = h_tuic,
	anytls = h_anytls
}

for line in content:gmatch("[^\r\n]+") do
	line = line:gsub("^%s+", ""):gsub("%s+$", "")
	local scheme = line:match("^(%w+)://")
	local h = scheme and handlers[scheme]
	if h then pcall(h, line) end
end

if #proxies == 0 then
	os.remove(DST)
	print("ERROR: no valid node converted")
	return
end

local tpl_path = find_template()
if not tpl_path then
	print("ERROR: no template found in " .. TPL_DIR)
	os.remove(DST)
	return
end
local tf = io.open(tpl_path, "r")
if not tf then print("ERROR: cannot open " .. tpl_path); return end
local out = tf:read("*a")
tf:close()

local proxies_block = table.concat(proxies, "\n")
local names_block = table.concat(names_list, "\n")

local function fill_template(out)
	local lines = {}
	local nodes_done, has_proxies_line = false, false
	for line in (out .. "\n"):gmatch("(.-)\n") do
		if line == "NODES" then
			lines[#lines + 1] = proxies_block
			nodes_done = true
		elseif line == "NAMES" then
			lines[#lines + 1] = names_block
		else
			if line:match("^proxies:%s*$") then has_proxies_line = true end
			lines[#lines + 1] = line
		end
	end
	if not nodes_done then
		if has_proxies_line then
			for i, l in ipairs(lines) do
				if l:match("^proxies:%s*$") then
					table.insert(lines, i + 1, proxies_block)
					break
				end
			end
		else
			table.insert(lines, 1, "")
			table.insert(lines, 1, proxies_block)
			table.insert(lines, 1, "proxies:")
		end
	end
	return table.concat(lines, "\n")
end

out = fill_template(out)

local wf = io.open(DST, "w")
if wf then
	wf:write(out)
	wf:close()
	print("OK: " .. #proxies .. " nodes -> " .. DST .. " (template: " .. tpl_path .. ")")
else
	print("ERROR: cannot write " .. DST)
end
