module("luci.nodepool.api", package.seeall)
appname = "nodepool"
s_config = "nodepool_server"
c_config = "nodepool"
local com = require "luci.nodepool.com"
nixio = require "nixio"
fs = require "nixio.fs"
sys = require "luci.sys"
uci = require "luci.model.uci".cursor()
util = require "luci.util"
datatypes = require "luci.cbi.datatypes"
jsonc = require "luci.jsonc"
i18n = require "luci.i18n"

curl_args = { "-skfL", "--connect-timeout 3", "--retry 3" }
command_timeout = 300
OPENWRT_ARCH = nil
DISTRIB_ARCH = nil
OPENWRT_BOARD = nil

LOCK_PREFIX = "/tmp/lock/" .. c_config
LOG_FILE = "/tmp/log/" .. c_config .. ".log"
TMP_PATH = "/tmp/etc/" .. c_config
CACHE_PATH = TMP_PATH .. "_tmp"
S_TMP_PATH = "/tmp/etc/" .. s_config
TMP_IFACE_PATH = TMP_PATH .. "/iface"

function log(...)
	local result = os.date("%Y-%m-%d %H:%M:%S: ") .. table.concat({...}, " ")
	local f, err = io.open(LOG_FILE, "a")
	if f and err == nil then
		f:write(result .. "\n")
		f:close()
	end
end

function is_old_uci()
	return sys.call("grep -E 'require[ \t]*\"uci\"' /usr/lib/lua/luci/model/uci.lua >/dev/null 2>&1") == 0
end

function uci_del(config, section, option)
	if option then
		return uci:delete(config, section, option)
	else
		return uci:delete(config, section)
	end
end

function uci_get(config, section, option)
	if not section then
		return uci:get_all(config)
	elseif option then
		return uci:get(config, section, option) or nil
	else
		return uci:get_all(config, section)
	end
end

function uci_set(config, section, option, value)
	if type(value) == "number" then
		value = value .. ""
	end
	if #value > 0 then
		if option then
			if type(value) == "table" then
				return uci:set_list(config, section, option, value)
			else
				return uci:set(config, section, option, value)
			end
		else
			return uci:set(config, section, value)
		end
	else
		return uci_del(config, section, option)
	end
end

function uci_del_c(section, option)
	return uci_del(c_config, section, option)
end

function uci_foreach_c(stype, func)
	uci:foreach(c_config, stype, func)
end

function uci_get_c(section, option)
	return uci_get(c_config, section, option)
end

function uci_set_c(section, option, value)
	return uci_set(c_config, section, option, value)
end

function uci_save_c(commit, apply)
	return uci_save(uci, c_config, commit, apply)
end

function uci_del_s(section, option)
	return uci_del(s_config, section, option)
end

function uci_foreach_s(stype, func)
	uci:foreach(s_config, stype, func)
end

function uci_get_s(section, option)
	return uci_get(s_config, section, option)
end

function uci_set_s(section, option, value)
	return uci_set(s_config, section, option, value)
end

function uci_save_s(commit, apply)
	return uci_save(uci, s_config, commit, apply)
end

function uci_save(cursor, config, commit, apply)
	if not cursor then cursor = uci end
	if is_old_uci() then
		cursor:save(config)
		if commit then
			cursor:commit(config)
			if apply then
				sys.call("/etc/init.d/" .. config .. " reload > /dev/null 2>&1 &")
			end
		end
	else
		commit = true
		if commit then
			if apply then
				cursor:commit(config)
			else
				sh_uci_commit(config)
			end
		end
	end
end

function sh_uci_get(config, section, option)
	local _, val = exec_call(string.format("uci -q get %s.%s.%s", config, section, option))
	return val
end

function sh_uci_set(config, section, option, val, commit)
	exec_call(string.format("uci -q set %s.%s.%s=\"%s\"", config, section, option, val))
	if commit then sh_uci_commit(config) end
end

function sh_uci_del(config, section, option, commit)
	exec_call(string.format("uci -q delete %s.%s.%s", config, section, option))
	if commit then sh_uci_commit(config) end
end

function sh_uci_add_list(config, section, option, val, commit)
	exec_call(string.format("uci -q del_list %s.%s.%s=\"%s\"", config, section, option, val))
	exec_call(string.format("uci -q add_list %s.%s.%s=\"%s\"", config, section, option, val))
	if commit then sh_uci_commit(config) end
end

function sh_uci_commit(config)
	exec_call(string.format("uci -q commit %s", config))
end

function set_cache_var(key, val)
	sys.call(string.format('. /usr/share/nodepool/utils.sh ; set_cache_var %s "%s"', key, val))
end

function get_cache_var(key)
	local val = sys.exec(string.format('. /usr/share/nodepool/utils.sh ; echo -n $(get_cache_var %s)', key))
	if val == "" then val = nil end
	return val
end

function get_new_port()
	local cmd_format = ". /usr/share/nodepool/utils.sh ; echo -n $(get_new_port %s tcp,udp)"
	return tonumber(sys.exec(string.format(cmd_format, "auto")))
end

function exec_call(cmd)
	math.randomseed(os.time())
	local tag = "\x01__RC__" .. tostring(math.random(100000, 999999)) .. "\x01"
	local f = io.popen('(' .. cmd .. '); printf "\\n' .. tag .. '%d" "$?"')
	local out = f:read("*a") or ""
	f:close()
	local rc = out:match(tag .. "(%d+)%s*$")
	if not rc then
		return 255, trim(out)
	end
	out = out:gsub("\n?" .. tag .. "%d+%s*$", "")
	return tonumber(rc), trim(out)
end

function base64Decode(text)
	if not text then return '' end
	local encoded = text:gsub("%z", ""):gsub("%c", ""):gsub("_", "/"):gsub("-", "+")
	local mod4 = #encoded % 4
	encoded = encoded .. string.sub('====', mod4 + 1)
	local result = nixio.bin.b64decode(encoded)
	if result then
		return result:gsub("%z", "")
	else
		return text
	end
end

function base64Encode(text)
	if not text then return nil end
	return nixio.bin.b64encode(text)
end

function UrlEncode(szText)
	if type(szText) ~= "string" then return "" end
	return szText:gsub("([^%w%-_%.%~])", function(c)
		return string.format("%%%02X", string.byte(c))
	end)
end

function UrlDecode(szText)
	if type(szText) ~= "string" then return "" end
	return szText and szText:gsub("%+", " "):gsub("%%(%x%x)", function(h)
		return string.char(tonumber(h, 16))
	end) or nil
end

--提取URL中的域名和端口(no ip)
function get_domain_port_from_url(url)
	local scheme, domain, port = string.match(url, "^(https?)://([%w%.%-]+):?(%d*)")
	if not domain then
		scheme, domain, port = string.match(url, "^(https?)://(%b[])([^:/]*)/?")
	end
	if not domain then return nil, nil end
	if domain:sub(1, 1) == "[" then domain = domain:sub(2, -2) end
	port = port ~= "" and tonumber(port) or (scheme == "https" and 443 or 80)
	if datatypes.ipaddr(domain) or datatypes.ip6addr(domain) then return nil, nil end
	return domain, port
end

--解析域名
function domainToIPv4(domain, dns)
	local Dns = dns or "223.5.5.5"
	local IPs = luci.sys.exec('nslookup %s %s | awk \'/^Name:/{getline; if ($1 == "Address:") print $2}\'' % { domain, Dns })
	for IP in string.gmatch(IPs, "%S+") do
		if datatypes.ipaddr(IP) and not datatypes.ip6addr(IP) then return IP end
	end
	return nil
end

function curl_base(url, file, args)
	if not args then args = {} end
	if file then
		args[#args + 1] = "-o " .. file
	end
	local cmd = string.format('curl %s "%s"', table_join(args), url)
	return exec_call(cmd)
end

function curl_proxy(url, file, args)
	--使用代理
	local socks_server = get_cache_var("GLOBAL_TCP_SOCKS_server")
	if socks_server and socks_server ~= "" then
		if not args then args = {} end
		local tmp_args = clone(args)
		tmp_args[#tmp_args + 1] = "-x socks5h://" .. socks_server
		return curl_base(url, file, tmp_args)
	end
	return nil, nil
end

function curl_logic(url, file, args)
	local return_code, result = curl_proxy(url, file, args)
	if not return_code or return_code ~= 0 then
		return_code, result = curl_base(url, file, args)
	end
	return return_code, result
end

function curl_direct(url, file, args)
	--直连访问
	local chn_list = uci_get_c("@global[0]", "chn_list") or "direct"
	local Dns = (chn_list == "proxy") and "1.1.1.1" or "223.5.5.5"
	if not args then args = {} end
	local tmp_args = clone(args)
	local domain, port = get_domain_port_from_url(url)
	if domain then
		local ip = domainToIPv4(domain, Dns)
		if ip then
			tmp_args[#tmp_args + 1] = "--resolve " .. domain .. ":" .. port .. ":" .. ip
		end
	end
	return curl_base(url, file, tmp_args)
end

function curl_auto(url, file, args)
	local localhost_proxy = uci_get_c("@global[0]", "localhost_proxy") or "1"
	if localhost_proxy == "1" then
		return curl_base(url, file, args) -- 当路由器本机开启代理时，采用nodepool规则进行访问
	else
		local return_code, result = curl_proxy(url, file, args)
		if not return_code or return_code ~= 0 then
			return_code, result = curl_direct(url, file, args)
		end
		return return_code, result
	end
end

function url(...)
	local url = string.format("admin/services/%s", appname)
	local args = { ... }
	for i, v in pairs(args) do
		if v ~= "" then
			url = url .. "/" .. v
		end
	end
	return require "luci.dispatcher".build_url(url)
end

function trim(s)
	if type(s) ~= "string" then return "" end
	local i, j = 1, #s
	while i <= j and s:byte(i) <= 32 do i = i + 1 end
	while j >= i and s:byte(j) <= 32 do j = j - 1 end
	if i > j then return "" end
	return s:sub(i, j)
end

-- 分割字符串
function split(full, sep)
	if full then
		full = full:gsub("%z", "") -- 这里不是很清楚 有时候结尾带个\0
		local off, result = 1, {}
		while true do
			local nStart, nEnd = full:find(sep, off)
			if not nEnd then
				local res = string.sub(full, off, string.len(full))
				if #res > 0 then -- 过滤掉 \0
					table.insert(result, res)
				end
				break
			else
				table.insert(result, string.sub(full, off, nStart - 1))
				off = nEnd + 1
			end
		end
		return result
	end
	return {}
end

function is_exist(table, value)
	for index, k in ipairs(table) do
		if k == value then
			return true
		end
	end
	return false
end

function repeat_exist(table, value)
	local count = 0
	for index, k in ipairs(table) do
		if k:find("-") and k == value then
			count = count + 1
		end
	end
	if count > 1 then
		return true
	end
	return false
end

function remove(...)
	for index, value in ipairs({...}) do
		if value and #value > 0 and value ~= "/" then
			sys.call(string.format("rm -rf %s", value))
		end
	end
end

function is_install(package)
	if package and #package > 0 then
		local file_path = "/usr/lib/opkg/info"
		local file_ext = ".control"
		local has = sys.call("[ -d " .. file_path .. " ]")
		if has ~= 0 then
			file_path = "/lib/apk/packages"
			file_ext = ".list"
		end
		return sys.call(string.format('[ -s "%s/%s%s" ]', file_path, package, file_ext)) == 0
	end
	return false
end

function get_args(arg)
	local var = {}
	for i, arg_k in pairs(arg) do
		if i > 0 then
			local v = arg[i + 1]
			if v then
				if repeat_exist(arg, v) == false then
					var[arg_k] = v
				end
			end
		end
	end
	return var
end

function get_function_args(arg)
	local var = nil
	if arg and #arg > 1 then
		local param = {}
		for i = 2, #arg do
			param[#param + 1] = arg[i]
		end
		var = get_args(param)
	end
	return var
end

function strToTable(str)
	if str == nil or type(str) ~= "string" then
		return {}
	end

	return loadstring("return " .. str)()
end

function is_json(str)
	if str and jsonc.parse(str) then
		return true
	end
	return false
end
datatypes.json = is_json

function is_timehhmm(str)
	local hour, minute = string.match(str, "^(%d?%d):(%d%d)$")
	if hour and minute then
		hour = tonumber(hour)
		minute = tonumber(minute)
		if hour >= 0 and hour <= 23 and minute >= 0 and minute <= 59 then
			return true
		end
	end
	return false
end
datatypes.timehhmm = is_timehhmm

function is_uuid(str)
	local pattern = "^%x%x%x%x%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%x%x%x%x%x%x%x%x$"
	return string.match(str, pattern) ~= nil
end
datatypes.uuid = is_uuid

function is_normal_node(e)
	if e and e.type and e.protocol and (e.protocol == "_balancing" or e.protocol == "_shunt" or e.protocol == "_iface" or e.protocol == "_urltest") then
		return false
	end
	return true
end

function is_special_node(e)
	return is_normal_node(e) == false
end

function is_ip(val)
	val = trim(val):lower()
	local str = val:match("%[(.-)%]") or val
	return datatypes.ipaddr(str) or false
end

function is_ipv6(val)
	val = trim(val):lower()
	local str = val:match("%[(.-)%]") or val
	return datatypes.ip6addr(str) or false
end

function is_local_ip(ip)
	ip = trim(ip):lower()
	ip = ip:gsub("^[%w%d]+://", "")   -- 去掉协议头
		:gsub("/.*$", "")          -- 去掉路径
		:gsub("^%[", ""):gsub("%]$", "") -- 去掉IPv6方括号
		:gsub(":%d+$", "")         -- 去掉端口
	return ip:match("^127%.") or ip:match("^10%.") or
		ip:match("^172%.1[6-9]%.") or ip:match("^172%.2[0-9]%.") or
		ip:match("^172%.3[0-1]%.") or ip:match("^192%.168%.") or
		ip == "::1" or ip:match("^f[cd]") or ip:match("^fe[89ab]")
end

function is_ipv6addrport(val)
	local address, port = val:match("%[(.-)%]:([0-9]+)$")
	if address and datatypes.ip6addr(address) and datatypes.port(port) then
		return true
	end
	return false
end

function get_ipv6_only(val)
	local result = ""
	local inner = val:match("%[(.-)%]") or val
	if datatypes.ip6addr(inner) then
		result = inner
	end
	return result
end

function get_ipv6_full(val)
	local result = ""
	if is_ipv6(val) then
		result = val
		if not val:match("%[.-%]") then
			result = "[" .. result .. "]"
		end
	end
	return result
end

function get_ip_type(val)
	if is_ipv6(val) then
		return "6"
	elseif datatypes.ip4addr(val) then
		return "4"
	end
	return ""
end

function is_mac(val)
	return datatypes.macaddr(val)
end

function ip_or_mac(val)
	if val then
		if get_ip_type(val) == "4" then
			return "ip"
		end
		if is_mac(val) then
			return "mac"
		end
	end
	return ""
end

function iprange(val)
	if val then
		local ipStart, ipEnd = val:match("^([^/]+)-([^/]+)$")
		if (ipStart and datatypes.ip4addr(ipStart)) and (ipEnd and datatypes.ip4addr(ipEnd)) then
			return true
		end
	end
	return false
end

function get_domain_from_url(url)
	local domain = string.match(url, "//([^/]+)")
	if domain then
		return domain
	end
	return url
end

function get_valid_nodes()
	local show_node_info = uci_get_c("@global_other[0]", "show_node_info") or "0"
	local nodes = {}
	local default_nodes = {}
	local other_nodes = {}
	uci_foreach_c("nodes", function(e)
		e.id = e[".name"]
		if e.type and e.remarks then
			local type_name = e.type
			if e.type == "sing-box" then type_name = "Sing-Box" end
			if e.protocol and (e.protocol == "_balancing" or e.protocol == "_shunt" or e.protocol == "_iface" or e.protocol == "_urltest") then
				e["remark"] = trim("%s：[%s]" % {type_name .. " " .. i18n.translatef(e.protocol), e.remarks})
				e["node_type"] = "special"
				if not e.group or e.group == "" then
					default_nodes[#default_nodes + 1] = e
				else
					other_nodes[#other_nodes + 1] = e
				end
			end
			local port = e.port or e.hysteria_hop or e.hysteria2_hop
			local is_realm = (e.type == "Hysteria2" or e.protocol == 'hysteria2') and e.hysteria2_realms or nil
			if (port and e.address) or is_realm then
				local address = e.address
				if is_ip(address) or datatypes.hostname(address) or is_realm then
					if (e.type == "sing-box" or e.type == "Xray") and e.protocol then
						local protocol = e.protocol
						if protocol == "vmess" then
							protocol = "VMess"
						elseif protocol == "vless" then
							protocol = "VLESS"
						elseif protocol == "shadowsocks" then
							protocol = "SS"
						elseif protocol == "shadowsocksr" then
							protocol = "SSR"
						elseif protocol == "wireguard" then
							protocol = "WG"
						elseif protocol == "hysteria" then
							protocol = "HY"
						elseif protocol == "hysteria2" then
							protocol = "HY2"
						elseif protocol == "anytls" then
							protocol = "AnyTLS"
						elseif protocol == "ssh" then
							protocol = "SSH"
						else
							protocol = protocol:gsub("^%l",string.upper)
						end
						type_name = type_name .. " " .. protocol
					end
					if is_ipv6(address) then address = get_ipv6_full(address) end
					type_name = is_realm and type_name .. " Realm" or type_name
					e["remark"] = trim("%s：[%s]" % {type_name, e.remarks})
					if show_node_info == "1" then
						port = (port or ""):gsub(":", "-")
						if not is_realm then
							e["remark"] = trim("%s：[%s] %s:%s" % {type_name, e.remarks, address, port})
						end
					end
					e.node_type = "normal"
					if not e.group or e.group == "" then
						default_nodes[#default_nodes + 1] = e
					else
						other_nodes[#other_nodes + 1] = e
					end
				end
			end
		end
	end)
	for i = 1, #default_nodes do nodes[#nodes + 1] = default_nodes[i] end
	for i = 1, #other_nodes do nodes[#nodes + 1] = other_nodes[i] end
	return nodes
end

function get_node_list()
	local node_list = {
		socks_list = {},
		normal_list = {},
	}
	uci_foreach_c("socks", function(s)
		if s.enabled == "1" and s.node then
			node_list.socks_list[#node_list.socks_list + 1] = {
				id = s[".name"],
				remark = i18n.translate("Socks Config") .. " [" .. s.port .. i18n.translate("Port") .. "]",
				group = "Socks"
			}
		end
	end)
	for k, e in ipairs(get_valid_nodes()) do
		if e.node_type == "normal" then
			node_list.normal_list[#node_list.normal_list + 1] = {
				id = e[".name"],
				remark = e["remark"],
				type = e["type"],
				chain_proxy = e["chain_proxy"],
				group = e["group"]
			}
		end
		if e.protocol and e.protocol:find("^_") then
			local proto = e.protocol:sub(2)
			if not node_list[proto .. "_list"] then
				node_list[proto .. "_list"] = {}
			end
			node_list[proto .. "_list"][#node_list[proto .. "_list"] + 1] = {
				id = e[".name"],
				remark = e["remark"],
				group = e["group"],
				o = e,
			}
		end
	end
	return node_list
end

function get_node_remarks(n)
	local remarks = ""
	if n then
		local type_name = n.type
		if n.type == "sing-box" then type_name = "Sing-Box" end
		if n.protocol and (n.protocol == "_balancing" or n.protocol == "_shunt" or n.protocol == "_iface" or n.protocol == "_urltest") then
			remarks = trim("%s：[%s]" % {type_name .. " " .. i18n.translatef(n.protocol), n.remarks})
		else
			if (n.type == "sing-box" or n.type == "Xray") and n.protocol then
				local protocol = n.protocol
				if protocol == "vmess" then
					protocol = "VMess"
				elseif protocol == "vless" then
					protocol = "VLESS"
				elseif protocol == "shadowsocks" then
					protocol = "SS"
				elseif protocol == "shadowsocksr" then
					protocol = "SSR"
				elseif protocol == "wireguard" then
					protocol = "WG"
				elseif protocol == "hysteria" then
					protocol = "HY"
				elseif protocol == "hysteria2" then
					protocol = "HY2"
				elseif protocol == "anytls" then
					protocol = "AnyTLS"
				elseif protocol == "ssh" then
					protocol = "SSH"
				else
					protocol = protocol:gsub("^%l",string.upper)
				end
				type_name = type_name .. " " .. protocol
			end
			if (n.type == "Hysteria2" or n.protocol == 'hysteria2') and n.hysteria2_realms then
				type_name = type_name .. " Realm"
			end
			remarks = trim("%s：[%s]" % {type_name, n.remarks})
		end
	end
	return remarks
end

function get_full_node_remarks(n)
	local remarks = get_node_remarks(n)
	if #remarks > 0 then
		local port = n.port or n.hysteria_hop or n.hysteria2_hop
		if n.address and port then
			port = port:gsub(":", "-")
			remarks = remarks .. " " .. n.address .. ":" .. port
		end
	end
	return remarks
end

function get_random_normal_node(exclude_id)
	local exclude_id_lookup = {}
	if type(exclude_id) == "table" then
		for i, v in ipairs(exclude_id) do
			exclude_id_lookup[v] = true
		end
	elseif type(exclude_id) == "string" then
		exclude_id_lookup[exclude_id] = true
	end
	local normal_list = {}
	for k, e in ipairs(get_valid_nodes()) do
		if e.node_type == "normal" and not exclude_id_lookup[e[".name"]] then
			normal_list[#normal_list + 1] = e
		end
	end
	if #normal_list > 0 then
		math.randomseed(os.time())
		local num = math.random(1, #normal_list)
		return normal_list[num]
	end
	return nil
end

function gen_uuid()
	local uuid = sys.exec("echo -n $(cat /proc/sys/kernel/random/uuid)")
	return uuid
end

function gen_random_char(length)
	if not length then length = 8 end
	return sys.exec("echo -n $(head /dev/urandom | tr -dc A-Za-z0-9 | head -c %s)" % length)
end

function chmod_755(file)
	if file and file ~= "" then
		if not fs.access(file, "rwx", "rx", "rx") then
			fs.chmod(file, 755)
		end
	end
end

function get_customed_path(e)
	return uci_get_c("@global_app[0]", e .. "_file")
end

function finded_com(e)
	local bin = get_app_path(e)
	if not bin then return end
	local s = luci.sys.exec('echo -n $(type -t -p "%s" | head -n1)' % { bin })
	if s == "" then
		s = nil
	end
	return s
end

function finded(e)
	return luci.sys.exec('echo -n $(type -t -p "/bin/%s" -p "/usr/bin/%s" "%s" | head -n1)' % {e, e, e})
end

function is_finded(e)
	return finded(e) ~= "" and true or false
end

function clone(org)
	local function copy(org, res)
		for k,v in pairs(org) do
			if type(v) ~= "table" then
				res[k] = v;
			else
				res[k] = {};
				copy(v, res[k])
			end
		end
	end

	local res = {}
	copy(org, res)
	return res
end

function get_bin_version_cache(file, cmd)
	sys.call("mkdir -p " .. CACHE_PATH)
	if fs.access(file) then
		chmod_755(file)
		local md5 = sys.exec("echo -n $(md5sum " .. file .. " | awk '{print $1}')")
		if fs.access(CACHE_PATH .. "/" .. md5) then
			return sys.exec("echo -n $(cat %s)" % { CACHE_PATH .. "/" .. md5 })
		else
			local version = sys.exec(string.format("echo -n $(%s %s)", file, cmd))
			if version and version ~= "" then
				sys.call("echo '%s' > %s"  % { version, CACHE_PATH .. "/" .. md5})
				return version
			end
		end
	end
	return ""
end

function get_app_path(app_name)
	if com[app_name] then
		local def_path = com[app_name].default_path
		local path = uci_get_c("@global_app[0]", app_name:gsub("%-","_") .. "_file")
		path = path and (#path>0 and path or def_path) or def_path
		return path
	end
end

function get_app_version(app_name, file)
	if file == nil then file = get_app_path(app_name) end
	return get_bin_version_cache(file, com[app_name].cmd_version)
end

local function is_file(path)
	if path and #path > 1 then
		if sys.exec('[ -f "%s" ] && echo -n 1' % path) == "1" then
			return true
		end
	end
	return nil
end

local function is_dir(path)
	if path and #path > 1 then
		if sys.exec('[ -d "%s" ] && echo -n 1' % path) == "1" then
			return true
		end
	end
	return nil
end

local function get_final_dir(path)
	if is_dir(path) then
		return path
	else
		return get_final_dir(fs.dirname(path))
	end
end

local function get_free_space(dir)
	if dir == nil then dir = "/" end
	if sys.call("df -k " .. dir .. " >/dev/null 2>&1") == 0 then
		return tonumber(sys.exec("echo -n $(df -k " .. dir .. " | awk 'NR>1' | awk '{print $4}')"))
	end
	return 0
end

local function get_file_space(file)
	if file == nil then return 0 end
	if fs.access(file) then
		return tonumber(sys.exec("echo -n $(du -k " .. file .. " | awk '{print $1}')"))
	end
	return 0
end

function _unpack(t, i)
	i = i or 1
	if t[i] ~= nil then return t[i], _unpack(t, i + 1) end
end

function table_join(t, s)
	if not s then
		s = " "
	end
	local str = ""
	for index, value in ipairs(t) do
		str = str .. t[index] .. (index == #t and "" or s)
	end
	return str
end

local function exec(cmd, args, writer, timeout)
	local os = require "os"
	local nixio = require "nixio"

	local fdi, fdo = nixio.pipe()
	local pid = nixio.fork()

	if pid > 0 then
		fdo:close()

		if writer or timeout then
			local starttime = os.time()
			while true do
				if timeout and os.difftime(os.time(), starttime) >= timeout then
					nixio.kill(pid, nixio.const.SIGTERM)
					return 1
				end

				if writer then
					local buffer = fdi:read(2048)
					if buffer and #buffer > 0 then
						writer(buffer)
					end
				end

				local wpid, stat, code = nixio.waitpid(pid, "nohang")

				if wpid and stat == "exited" then return code end

				if not writer and timeout then nixio.nanosleep(1) end
			end
		else
			local wpid, stat, code = nixio.waitpid(pid)
			return wpid and stat == "exited" and code
		end
	elseif pid == 0 then
		nixio.dup(fdo, nixio.stdout)
		fdi:close()
		fdo:close()
		nixio.exece(cmd, args, nil)
		nixio.stdout:close()
		os.exit(1)
	end
end

function compare_versions(ver1, comp, ver2)
	local table = table

	if not ver1 then ver1 = "" end
	if not ver2 then ver2 = "" end

	local av1 = util.split(ver1, "[%.%-]", nil, true)
	local av2 = util.split(ver2, "[%.%-]", nil, true)

	local max = table.getn(av1)
	local n2 = table.getn(av2)
	if (max < n2) then max = n2 end

	for i = 1, max, 1 do
		local s1 = tonumber(av1[i] or 0) or 0
		local s2 = tonumber(av2[i] or 0) or 0

		if comp == "~=" and (s1 ~= s2) then return true end
		if (comp == "<" or comp == "<=") and (s1 < s2) then return true end
		if (comp == ">" or comp == ">=") and (s1 > s2) then return true end
		if (s1 ~= s2) then return false end
	end

	return not (comp == "<" or comp == ">")
end

local function auto_get_arch()
	local arch = nixio.uname().machine or ""
	if not OPENWRT_ARCH and fs.access("/usr/lib/os-release") then
		OPENWRT_ARCH = sys.exec("echo -n $(grep 'OPENWRT_ARCH' /usr/lib/os-release | awk -F '[\\042\\047]' '{print $2}')")
		OPENWRT_BOARD = sys.exec("echo -n $(grep 'OPENWRT_BOARD' /usr/lib/os-release | awk -F '[\\042\\047]' '{print $2}')")
		if OPENWRT_ARCH == "" then OPENWRT_ARCH = nil end
		if OPENWRT_BOARD == "" then OPENWRT_BOARD = nil end
	end
	if not DISTRIB_ARCH and fs.access("/etc/openwrt_release") then
		DISTRIB_ARCH = sys.exec("echo -n $(grep 'DISTRIB_ARCH' /etc/openwrt_release | awk -F '[\\042\\047]' '{print $2}')")
		if DISTRIB_ARCH == "" then DISTRIB_ARCH = nil end
	end

	if arch:match("^i[%d]86$") then
		arch = "x86"
	elseif arch:match("armv5") then  -- armv5l
		arch = "armv5"
	elseif arch:match("armv6") then
		arch = "armv6"
	elseif arch:match("armv7") then  -- armv7l
		arch = "armv7"
	end

	if OPENWRT_ARCH or DISTRIB_ARCH then
		if arch == "mips" then
			if OPENWRT_ARCH and OPENWRT_ARCH:match("mipsel") == "mipsel"
			or DISTRIB_ARCH and DISTRIB_ARCH:match("mipsel") == "mipsel" then
				arch = "mipsel"
			end
		elseif arch == "armv7" then
			if OPENWRT_ARCH and not OPENWRT_ARCH:match("vfp") and not OPENWRT_ARCH:match("neon")
			or DISTRIB_ARCH and not DISTRIB_ARCH:match("vfp") and not DISTRIB_ARCH:match("neon") then
				arch = "armv5"
			end
		end
	end

	if arch == "aarch64" and OPENWRT_BOARD and OPENWRT_BOARD:match("rockchip") ~= nil then
		arch = "rockchip"
	end

	return trim(arch)
end

function parseURL(url_str)
	local res = {}

	-- 1. Get Scheme (http://)
	local rest = url_str
	local scheme, s_rest = url_str:match("^([%w%.%-%+]+)://(.+)$")
	if scheme then
		res.protocol = scheme
		rest = s_rest
	end

	-- 2. Get Authority (user:pass@host:port) and Path
	local authority, path = rest:match("^([^/]+)(.*)$")
	if path and path ~= "" then
		res.pathname = path:match("^([^?#]*)")
	end

	-- 3. Process Auth info (user:pass@)
	-- Use [^@]+ to match the content before the leftmost @.
	local user_info, host_port = authority:match("^([^@]+)@(.+)$")
	if user_info then
		local u, p = user_info:match("^([^:]+):?(.*)$")
		res.username = u or ""
		res.password = p or ""
	else
		host_port = authority
	end

	-- 4. Handles Host and Port (IPv6 compatible)
	-- First look for square brackets [], if not found, then look for regular colons.
	local ipv6_host, ipv6_port = host_port:match("^%[(.+)%]:(%d+)$")
	if ipv6_host then
		res.hostname = ipv6_host
		res.port = tonumber(ipv6_port)
	else
		-- Check if it's an IPv6 address with parentheses but no port number: [2001:db8::1]
		local pure_ipv6 = host_port:match("^%[(.+)%]$")
		if pure_ipv6 then
			res.hostname = pure_ipv6
		else
			-- IPv4 or hostname match
			local h, p = host_port:match("^([^:]+):(%d+)$")
			if h and p then
				res.hostname = h
				res.port = tonumber(p)
			else
				res.hostname = host_port
			end
		end
	end

	res.host = host_