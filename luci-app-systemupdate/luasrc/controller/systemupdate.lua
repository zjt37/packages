module("luci.controller.systemupdate", package.seeall)

function index()
	entry({"admin", "system", "systemupdate"}, template("systemupdate/update"), _("系统更新"), 90)
	entry({"admin", "system", "systemupdate", "action"}, call("action_update"), nil).dependent = false
end

function action_update()
	local action = luci.http.formvalue("action")
	local mode = luci.http.formvalue("mode") or "fresh"

	luci.http.prepare_content("text/plain")

	if action == "check" then
		luci.http.write(luci.sys.exec("/usr/bin/systemupdate check"))
	elseif action == "update" then
		if mode == "keep" then
			luci.http.write(luci.sys.exec("/usr/bin/systemupdate keep"))
		else
			luci.http.write(luci.sys.exec("/usr/bin/systemupdate fresh"))
		end
	end
end
