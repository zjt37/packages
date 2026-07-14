include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-systemupdate
PKG_VERSION:=1.0
PKG_RELEASE:=1

include $(INCLUDE_DIR)/package.mk

define Package/luci-app-systemupdate
  SECTION:=luci
  CATEGORY:=LuCI
  SUBMENU:=3. Applications
  TITLE:=System Update for OpenWrt
  DEPENDS:=+curl +jq
  PKGARCH:=all
endef

define Package/luci-app-systemupdate/description
  Online system update from GitHub releases.
endef

define Build/Compile
endef

define Package/luci-app-systemupdate/install
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/controller
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/model/cbi/systemupdate
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/view/systemupdate
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_DIR) $(1)/etc/uci-defaults

	$(INSTALL_BIN) ./files/usr/bin/systemupdate $(1)/usr/bin/systemupdate
	$(INSTALL_BIN) ./files/etc/init.d/systemupdate $(1)/etc/init.d/systemupdate
	$(INSTALL_DATA) ./files/etc/uci-defaults/99-systemupdate $(1)/etc/uci-defaults/99-systemupdate
	$(INSTALL_DATA) ./luasrc/controller/systemupdate.lua $(1)/usr/lib/lua/luci/controller/systemupdate.lua
	$(INSTALL_DATA) ./luasrc/model/cbi/systemupdate/update.lua $(1)/usr/lib/lua/luci/model/cbi/systemupdate/update.lua
	$(INSTALL_DATA) ./luasrc/view/systemupdate/update.htm $(1)/usr/lib/lua/luci/view/systemupdate/update.htm
endef

define Package/luci-app-systemupdate/postinst
#!/bin/sh
[ -n "$${IPKG_INSTROOT}" ] || {
	/etc/init.d/systemupdate enable
	uci -q set luci.languages.zh_Hans=1
	uci commit luci
}
endef

$(eval $(call BuildPackage,luci-app-systemupdate))
