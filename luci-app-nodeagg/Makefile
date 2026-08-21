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
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/view/nodeagg
	$(INSTALL_DIR) $(1)/usr/share/luci/menu.d
	$(INSTALL_DIR) $(1)/usr/share/rpcd/acl.d

	$(INSTALL_DATA) ./luasrc/controller/nodeagg.lua $(1)/usr/lib/lua/luci/controller/nodeagg.lua
	$(INSTALL_DATA) ./luasrc/model/cbi/nodeagg/settings.lua $(1)/usr/lib/lua/luci/model/cbi/nodeagg/settings.lua
	$(INSTALL_DATA) ./luasrc/model/cbi/nodeagg/node_list.lua $(1)/usr/lib/lua/luci/model/cbi/nodeagg/node_list.lua
	$(INSTALL_DATA) ./luasrc/model/cbi/nodeagg/subscribe.lua $(1)/usr/lib/lua/luci/model/cbi/nodeagg/subscribe.lua
	$(INSTALL_DATA) ./luasrc/model/cbi/nodeagg/subscribe_edit.lua $(1)/usr/lib/lua/luci/model/cbi/nodeagg/subscribe_edit.lua
	$(INSTALL_DATA) ./luasrc/view/nodeagg/heading.htm $(1)/usr/lib/lua/luci/view/nodeagg/heading.htm
	$(INSTALL_DATA) ./root/usr/share/luci/menu.d/luci-app-nodeagg.json $(1)/usr/share/luci/menu.d/luci-app-nodeagg.json
	$(INSTALL_DATA) ./root/usr/share/rpcd/acl.d/luci-app-nodeagg.json $(1)/usr/share/rpcd/acl.d/luci-app-nodeagg.json
endef

$(eval $(call BuildPackage,luci-app-nodeagg))
