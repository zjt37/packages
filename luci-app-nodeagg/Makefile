include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-nodeagg
PKG_VERSION:=1.0
PKG_RELEASE:=1

include $(INCLUDE_DIR)/package.mk

define Package/luci-app-nodeagg
  SECTION:=luci
  CATEGORY:=LuCI
  SUBMENU:=3. Applications
  TITLE:=NodeAgg - Subscription Aggregator
  DEPENDS:=+curl +jq +sing-box +xray-core +hysteria2
  PKGARCH:=all
endef

define Package/luci-app-nodeagg/description
  Node aggregation and subscription conversion tool for OpenWrt.
endef

define Build/Compile
endef

define Package/luci-app-nodeagg/install
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/controller
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/model/cbi/nodeagg
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/nodeagg
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/view/nodeagg
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/view/nodeagg/cbi
	$(INSTALL_DIR) $(1)/usr/share/luci/menu.d
	$(INSTALL_DIR) $(1)/usr/share/rpcd/acl.d
	$(INSTALL_DIR) $(1)/www/luci-static/resources/view/nodeagg

	$(INSTALL_DATA) ./luasrc/controller/nodeagg.lua $(1)/usr/lib/lua/luci/controller/nodeagg.lua
	$(INSTALL_DATA) ./luasrc/model/cbi/nodeagg/settings.lua $(1)/usr/lib/lua/luci/model/cbi/nodeagg/settings.lua
	$(INSTALL_DATA) ./luasrc/model/cbi/nodeagg/node_list.lua $(1)/usr/lib/lua/luci/model/cbi/nodeagg/node_list.lua
	$(INSTALL_DATA) ./luasrc/model/cbi/nodeagg/subscribe.lua $(1)/usr/lib/lua/luci/model/cbi/nodeagg/subscribe.lua
	$(INSTALL_DATA) ./luasrc/model/cbi/nodeagg/subscribe_edit.lua $(1)/usr/lib/lua/luci/model/cbi/nodeagg/subscribe_edit.lua
	$(INSTALL_DATA) ./luasrc/luci/nodeagg/api.lua $(1)/usr/lib/lua/luci/nodeagg/api.lua
	$(INSTALL_DATA) ./luasrc/luci/nodeagg/com.lua $(1)/usr/lib/lua/luci/nodeagg/com.lua
	$(INSTALL_DATA) ./luasrc/view/nodeagg/heading.htm $(1)/usr/lib/lua/luci/view/nodeagg/heading.htm
	$(INSTALL_DATA) ./luasrc/view/nodeagg/subscribe_js.htm $(1)/usr/lib/lua/luci/view/nodeagg/subscribe_js.htm
	$(INSTALL_DATA) ./luasrc/view/nodeagg/cbi/sortable.htm $(1)/usr/lib/lua/luci/view/nodeagg/cbi/sortable.htm
	$(INSTALL_DATA) ./luasrc/view/nodeagg/cbi/nodes_listvalue.htm $(1)/usr/lib/lua/luci/view/nodeagg/cbi/nodes_listvalue.htm
	$(INSTALL_DATA) ./luasrc/view/nodeagg/cbi/nodes_listvalue_com.htm $(1)/usr/lib/lua/luci/view/nodeagg/cbi/nodes_listvalue_com.htm
	$(INSTALL_DATA) ./root/www/luci-static/resources/view/nodeagg/Sortable.min.js $(1)/www/luci-static/resources/view/nodeagg/Sortable.min.js
	$(INSTALL_DATA) ./root/usr/share/luci/menu.d/luci-app-nodeagg.json $(1)/usr/share/luci/menu.d/luci-app-nodeagg.json
	$(INSTALL_DATA) ./root/usr/share/rpcd/acl.d/luci-app-nodeagg.json $(1)/usr/share/rpcd/acl.d/luci-app-nodeagg.json
endef

$(eval $(call BuildPackage,luci-app-nodeagg))
