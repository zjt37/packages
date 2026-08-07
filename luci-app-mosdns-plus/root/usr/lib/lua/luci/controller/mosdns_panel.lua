module("luci.controller.mosdns_panel", package.seeall)

function index()
    entry({"admin", "services", "mosdns", "panel"}, template("mosdns/panel"), _("面板"), 99).leaf = true
    entry({"admin", "mosdns_panel"}, alias("admin", "services", "mosdns"))
    entry({"admin", "mosdns_panel", "api"}, call("action_api_root"), nil).dependent = false
    entry({"admin", "mosdns_panel", "api", "status"}, call("action_status"), nil).dependent = false
    entry({"admin", "mosdns_panel", "api", "background_status"}, call("action_bg_status"), nil).dependent = false
    entry({"admin", "mosdns_panel", "api", "upload_background"}, call("action_upload_background"), nil).dependent = false
    entry({"admin", "mosdns_panel", "api", "remove_background"}, call("action_remove_background"), nil).dependent = false
    entry({"admin", "mosdns_panel", "api", "restart"}, call("action_restart"), nil).dependent = false
    entry({"admin", "mosdns_panel", "api", "get_log"}, call("action_get_log"), nil).dependent = false
    entry({"admin", "mosdns_panel", "api", "clear_log"}, call("action_clear_log"), nil).dependent = false
    local e = entry({"admin", "mosdns_panel", "api", "restore_dump"}, call("action_restore_dump"), nil)
    e.dependent = false
    e.leaf = true
    entry({"admin", "mosdns_panel", "plugins"}, call("action_plugins")).leaf = true
end

function action_api_root()
    luci.http.prepare_content("application/json")
    luci.http.write('{"status":"ok"}')
end

local function parse_metrics(metrics_text)
    local data = {
        caches = {},
        system = {
            go_version = "N/A"
        }
    }
    
    if not metrics_text then return data end

    local latency_sum = 0
    local latency_count = 0

    for line in metrics_text:gmatch("[^\r\n]+") do
        local metric, tag, value = line:match("^(mosdns_cache_[%w_]+){tag=\"([^\"]+)\"}%s+([%d%.eE+-]+)")
        if metric then
            if not data.caches[tag] then data.caches[tag] = {} end
            local key = metric:match("^mosdns_cache_(.+)")
            if key then
                data.caches[tag][key] = tonumber(value)
            end
        else
            local l_sum = line:match("^mosdns_metrics_collector_response_latency_millisecond_sum{name=\"metrics\"}%s+([%d%.eE+-]+)")
            if l_sum then latency_sum = tonumber(l_sum) end
            
            local l_count = line:match("^mosdns_metrics_collector_response_latency_millisecond_count{name=\"metrics\"}%s+([%d%.eE+-]+)")
            if l_count then latency_count = tonumber(l_count) end

            local sys_key, sys_val = line:match("^([%w_]+)%s+([%d%.eE+-]+)")
            if sys_key then
                if sys_key == "process_start_time_seconds" then data.system.start_time = tonumber(sys_val)
                elseif sys_key == "process_cpu_seconds_total" then data.system.cpu_time = tonumber(sys_val)
                elseif sys_key == "process_resident_memory_bytes" then data.system.resident_memory = tonumber(sys_val)
                elseif sys_key == "go_memstats_heap_idle_bytes" then data.system.heap_idle_memory = tonumber(sys_val)
                elseif sys_key == "go_threads" then data.system.threads = tonumber(sys_val)
                elseif sys_key == "process_open_fds" then data.system.open_fds = tonumber(sys_val)
                end
            else
                 local ver = line:match('^go_info{version="([^"]+)"}')
                 if ver then data.system.go_version = ver end
            end
        end
    end

    if latency_count > 0 then
        data.system.avg_latency = latency_sum / latency_count
    else
        data.system.avg_latency = 0
    end

    for tag, metrics in pairs(data.caches) do
        local query_total = metrics.query_total or 0
        local hit_total = metrics.hit_total or 0
        local lazy_hit_total = metrics.lazy_hit_total or 0
        
        metrics.hit_rate = (query_total > 0) and string.format("%.2f%%", (hit_total / query_total * 100)) or "0.00%"
        metrics.lazy_hit_rate = (query_total > 0) and string.format("%.2f%%", (lazy_hit_total / query_total * 100)) or "0.00%"
    end

    return data
end

function action_status()
    local sys = require "luci.sys"
    local http = require "luci.http"
    local jsonc = require "luci.jsonc"
    
    local metrics = sys.exec("curl -s --max-time 2 http://127.0.0.1:9091/metrics")
    
    local data = parse_metrics(metrics)
    
    http.prepare_content("application/json")
    http.write(jsonc.stringify(data))
end

function action_bg_status()
    local http = require "luci.http"
    local jsonc = require "luci.jsonc"
    http.prepare_content("application/json")
    http.write(jsonc.stringify({status="default"}))
end

function action_upload_background()
    local http = require "luci.http"
    local jsonc = require "luci.jsonc"
    http.prepare_content("application/json")
    http.write(jsonc.stringify({success=false, error="Feature not supported in LuCI panel version"}))
end

function action_remove_background()
    local http = require "luci.http"
    local jsonc = require "luci.jsonc"
    http.prepare_content("application/json")
    http.write(jsonc.stringify({success=false, error="Feature not supported in LuCI panel version"}))
end

function action_restart()
    local sys = require "luci.sys"
    local http = require "luci.http"
    local jsonc = require "luci.jsonc"
    
    local result = sys.call("/etc/init.d/mosdns restart")
    
    http.prepare_content("application/json")
    if result == 0 then
        http.write(jsonc.stringify({success=true}))
    else
        http.write(jsonc.stringify({success=false, error="Restart failed with exit code " .. tostring(result)}))
    end
end

function action_restore_dump(plugin_name)
    local sys = require "luci.sys"
    local http = require "luci.http"
    local jsonc = require "luci.jsonc"
    
    http.prepare_content("application/json")

    if not plugin_name then
        http.write(jsonc.stringify({success=false, error="Plugin name is required"}))
        return
    end

    plugin_name = plugin_name:gsub("[^%w_%-]", "")

    local port = "9091"
    if sys.call("curl -s --max-time 1 http://127.0.0.1:9091/metrics >/dev/null 2>&1") ~= 0 then
        port = "9099"
    end

    local dump_file = nil

    -- look for dump_file in JSON config
    local jf = io.open("/var/etc/mosdns.json", "r")
    if jf then
        local jc = jf:read("*a")
        jf:close()
        if jc then
            local df = jc:match('"tag"%s*:%s*"' .. plugin_name .. '"[^}]*"dump_file"%s*:%s*"([^"]+)"')
            if df then dump_file = df:gsub("\\/", "/") end
        end
    end

    if not dump_file then
        dump_file = "/etc/mosdns/" .. plugin_name .. ".dump"
    end

    if sys.call("test -f " .. dump_file) ~= 0 then
        http.write(jsonc.stringify({success=false, error="未找到本地缓存文件: " .. dump_file}))
        return
    end

    local cmd = string.format("curl -s -X POST http://127.0.0.1:%s/plugins/%s/load_dump -H 'Content-Type: application/octet-stream' --data-binary '@%s'", port, plugin_name, dump_file)
    local exit_code = sys.call(cmd)

    if exit_code == 0 then
        http.write(jsonc.stringify({success=true, message="已恢复缓存规则", file=dump_file}))
    else
        http.write(jsonc.stringify({success=false, error="Curl execution failed", code=exit_code}))
    end
end

function action_plugins(...)
    local sys = require "luci.sys"
    local http = require "luci.http"
    local table = require "table"
    
    local args = {...}
    local path = table.concat(args, "/")
    
    local port = "9091"
    local check = sys.exec("curl -s --max-time 1 http://127.0.0.1:9091/metrics | head -n 1")
    if not check or check == "" then
        port = "9099"
    end
    
    if args[#args] == "dump" then
        local cmd
        if path == "cache_all/dump" then
            cmd = string.format("(curl -s --max-time 10 'http://127.0.0.1:%s/plugins/cache_cn/dump' | gunzip -c | grep -aoE '([a-zA-Z0-9-]+\\.)+[a-zA-Z]{2,}\\.?'; curl -s --max-time 10 'http://127.0.0.1:%s/plugins/cache_nocn/dump' | gunzip -c | grep -aoE '([a-zA-Z0-9-]+\\.)+[a-zA-Z]{2,}\\.?'; curl -s --max-time 10 'http://127.0.0.1:%s/plugins/lazy_cache/dump' | gunzip -c | grep -aoE '([a-zA-Z0-9-]+\\.)+[a-zA-Z]{2,}\\.?')", port, port, port)
        else
            cmd = string.format("curl -s --max-time 10 'http://127.0.0.1:%s/plugins/%s' | gunzip -c | grep -aoE '([a-zA-Z0-9-]+\\.)+[a-zA-Z]{2,}\\.?'", port, path)
        end
        
        local content = sys.exec(cmd)
        
        http.prepare_content("text/html; charset=utf-8")
        local nameMap = { cache_all = "全部缓存", cache_cn = "国内缓存", cache_nocn = "国外缓存", lazy_cache = "乐观缓存" }
        local pathKey = path:match("([^/]+)")
        local displayName = nameMap[pathKey] or path
        http.write("<!DOCTYPE html><html><head><meta charset='utf-8'><title>" .. displayName .. " - 缓存查看</title>")
        http.write("<style>body{font-family:'Segoe UI',Roboto,Helvetica,Arial,sans-serif;padding:2rem;line-height:1.6;background-color:#f7f9fd;color:#2c3e50;max-width:1200px;margin:0 auto;}")
        http.write(".container{background:#ffffff;padding:2rem;border-radius:0.8rem;box-shadow:0 6px 18px rgba(0,0,0,0.08);border:1px solid #e0e6ec;}")
        http.write("h1{font-size:1.5rem;margin-top:0;margin-bottom:1rem;color:#2c3e50;border-bottom:2px solid #f0f4f7;padding-bottom:0.5rem;}")
        http.write(".count-badge{display:inline-block;background-color:#4a90e2;color:#fff;padding:0.2rem 0.6rem;border-radius:1rem;font-size:0.9rem;font-weight:bold;margin-left:0.5rem;vertical-align:middle;}")
        http.write("pre{background-color:#f8f9fa;padding:1rem;border-radius:0.5rem;border:1px solid #e9ecef;overflow-x:auto;font-family:Consolas,Monaco,'Courier New',monospace;font-size:0.9rem;color:#495057;white-space:pre-wrap;word-break:break-all;}")
        http.write("</style></head><body>")
        
        local _, count = content:gsub('\n', '\n')
        if content ~= "" and content:sub(-1) ~= "\n" then count = count + 1 end
        if content == "" then count = 0 end

        http.write("<div class='container'>")
        http.write("<h1>" .. displayName .. "<span class='count-badge'>" .. count .. " items</span></h1>")
        
        if content == "" then
             http.write("<div style='color:#7f8c8d;font-style:italic;'>No content found or empty dump.</div>")
        else
             http.write("<pre>" .. content .. "</pre>")
        end
        
        http.write("</div></body></html>")
    else
        local content = sys.exec("curl -s --max-time 10 http://127.0.0.1:" .. port .. "/plugins/" .. path)
        local jsonc = require "luci.jsonc"
        http.prepare_content("application/json")
        if content and content ~= "" then
            local err = content:gsub("%s+$", "")
            http.write(jsonc.stringify({success = false, error = err}))
        else
            http.write(jsonc.stringify({success = true, message = "ok"}))
        end
    end
end

function action_get_log()
    local sys = require "luci.sys"
    local http = require "luci.http"
    local jsonc = require "luci.jsonc"

    http.prepare_content("application/json")

    local log_file = "/var/log/mosdns.log"
    
    if sys.call("test -f " .. log_file) ~= 0 then
        local config_dir = "/etc/mosdns/"
        local yamls = sys.exec("ls " .. config_dir .. "*.yaml 2>/dev/null")
        local found = false
        if yamls then
            for filename in yamls:gmatch("[^\r\n]+") do
                local file = io.open(filename, "r")
                if file then
                    local content = file:read("*a")
                    file:close()
                    local f = content:match("file:%s*[\"']?([^\"'\r\n]+%.log)[\"']?")
                    if f then
                        log_file = f
                        found = true
                        break
                    end
                end
            end
        end
        
        if not found and sys.call("test -f " .. log_file) ~= 0 then
            http.write(jsonc.stringify({success=false, error="Log file not found at " .. log_file}))
            return
        end
    end

    local limit = tonumber(http.formvalue("limit")) or 1000
    if limit > 10000 then limit = 10000 end
    if limit < 100 then limit = 100 end

    local content = sys.exec("tail -n " .. limit .. " " .. log_file)
    
    http.write(jsonc.stringify({success=true, content=content, file=log_file}))
end

function action_clear_log()
    local sys = require "luci.sys"
    local http = require "luci.http"
    local jsonc = require "luci.jsonc"

    local log_file = "/var/log/mosdns.log"
    local code = sys.call(": > " .. log_file)
    
    http.prepare_content("application/json")
    if code == 0 then
        http.write(jsonc.stringify({success=true}))
    else
        http.write(jsonc.stringify({success=false, error="Failed to clear log file"}))
    end
end
