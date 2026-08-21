module("luci.controller.nodeagg", package.seeall)

function index()
	entry({"admin", "services", "nodeagg"}, template("nodeagg/main"), _("节点聚合"), 60)
end
