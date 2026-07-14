module("luci.controller.systemupdate", package.seeall)

function index()
	entry({"admin", "system", "systemupdate"}, cbi("systemupdate/update"), _("系统更新"), 90)
end
