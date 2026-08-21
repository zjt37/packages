module("luci.controller.nodeagg", package.seeall)

function index()
	entry({"admin", "services", "nodeagg"}, alias("admin", "services", "nodeagg", "settings"), _("节点聚合"), 60).dependent = true

	entry({"admin", "services", "nodeagg", "settings"}, cbi("nodeagg/settings"), _("节点聚合"), 1).dependent = true
	entry({"admin", "services", "nodeagg", "node_list"}, cbi("nodeagg/node_list"), _("节点列表"), 2).dependent = true
	entry({"admin", "services", "nodeagg", "subscribe"}, cbi("nodeagg/subscribe"), _("节点订阅"), 3).dependent = true
end
