module("luci.controller.n1update", package.seeall)

function index()
	entry({"admin", "system", "n1update"}, template("n1update/update"), _("系统更新"), 80)
end
