include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-n1update
PKG_VERSION:=1.0
PKG_RELEASE:=1

include $(INCLUDE_DIR)/package.mk

define Package/luci-app-n1update
  SECTION:=luci
  CATEGORY:=LuCI
  SUBMENU:=3. Applications
  TITLE:=N1 System Update
  DEPENDS:=+curl +jq +btrfs-progs
  PKGARCH:=all
endef

define Package/luci-app-n1update/description
  Online system update from GitHub releases.
endef

define Build/Compile
endef

define Package/luci-app-n1update/install
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/controller
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/model/cbi/n1update
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/view/n1update
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_DIR) $(1)/etc/uci-defaults

	$(INSTALL_BIN) ./files/usr/bin/n1update $(1)/usr/bin/n1update
	$(INSTALL_BIN) ./files/etc/init.d/n1update $(1)/etc/init.d/n1update
	$(INSTALL_DATA) ./files/etc/uci-defaults/99-n1update $(1)/etc/uci-defaults/99-n1update
	$(INSTALL_DATA) ./luasrc/controller/n1update.lua $(1)/usr/lib/lua/luci/controller/n1update.lua
	$(INSTALL_DATA) ./luasrc/model/cbi/n1update/update.lua $(1)/usr/lib/lua/luci/model/cbi/n1update/update.lua
	$(INSTALL_DATA) ./luasrc/view/n1update/update.htm $(1)/usr/lib/lua/luci/view/n1update/update.htm
endef

define Package/luci-app-n1update/postinst
#!/bin/sh
[ -n "$${IPKG_INSTROOT}" ] || {
	/etc/init.d/n1update enable
	uci -q set luci.languages.zh_Hans=1
	uci commit luci
}
endef

$(eval $(call BuildPackage,luci-app-n1update))
