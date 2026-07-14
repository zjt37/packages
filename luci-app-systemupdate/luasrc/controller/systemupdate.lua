module("luci.controller.systemupdate", package.seeall)

function index()
	entry({"admin", "system", "systemupdate"}, template("systemupdate/update"), _("系统更新"), 80)
end
