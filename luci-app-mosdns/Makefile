include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-mosdns
PKG_VERSION:=1.5.23
PKG_RELEASE:=2

LUCI_TITLE:=LuCI Support for MosDNS with Panel
LUCI_PKGARCH:=all
LUCI_DESCRIPTION:=MosDNS LuCI configuration interface with integrated dashboard panel
LUCI_DEPENDS:=+luci-base +mosdns

include $(TOPDIR)/feeds/luci/luci.mk

# Package/Install defines
define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/etc/init.d/mosdns $(1)/etc/init.d/mosdns

	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_CONF) ./files/etc/config/mosdns $(1)/etc/config/mosdns

	$(INSTALL_DIR) $(1)/etc/uci-defaults
	$(INSTALL_BIN) ./files/etc/uci-defaults/mosdns $(1)/etc/uci-defaults/99-mosdns

	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/controller
	$(INSTALL_DATA) ./files/usr/lib/lua/luci/controller/mosdns.lua $(1)/usr/lib/lua/luci/controller/mosdns.lua
	$(INSTALL_DATA) ./files/usr/lib/lua/luci/controller/mosdns_panel.lua $(1)/usr/lib/lua/luci/controller/mosdns_panel.lua

	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/model/cbi/mosdns
	$(INSTALL_DATA) ./files/usr/lib/lua/luci/model/cbi/mosdns/basic.lua $(1)/usr/lib/lua/luci/model/cbi/mosdns/basic.lua
	$(INSTALL_DATA) ./files/usr/lib/lua/luci/model/cbi/mosdns/log.lua $(1)/usr/lib/lua/luci/model/cbi/mosdns/log.lua
	$(INSTALL_DATA) ./files/usr/lib/lua/luci/model/cbi/mosdns/rule_list.lua $(1)/usr/lib/lua/luci/model/cbi/mosdns/rule_list.lua
	$(INSTALL_DATA) ./files/usr/lib/lua/luci/model/cbi/mosdns/update.lua $(1)/usr/lib/lua/luci/model/cbi/mosdns/update.lua

	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/view/mosdns
	$(INSTALL_DATA) ./files/usr/lib/lua/luci/view/mosdns/*.htm $(1)/usr/lib/lua/luci/view/mosdns/

	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/i18n
	$(INSTALL_DATA) ./files/usr/lib/lua/luci/i18n/mosdns.zh-cn.lmo $(1)/usr/lib/lua/luci/i18n/

	$(INSTALL_DIR) $(1)/usr/share/mosdns
	$(INSTALL_BIN) ./files/usr/share/mosdns/mosdns.sh $(1)/usr/share/mosdns/mosdns.sh

	$(INSTALL_DIR) $(1)/www/luci-static/resources/mosdns/addon/fold
	$(INSTALL_DATA) ./files/www/luci-static/resources/mosdns/addon/fold/*.js $(1)/www/luci-static/resources/mosdns/addon/fold/
	$(INSTALL_DATA) ./files/www/luci-static/resources/mosdns/addon/fold/*.css $(1)/www/luci-static/resources/mosdns/addon/fold/

	$(INSTALL_DIR) $(1)/www/luci-static/resources/mosdns/lib
	$(INSTALL_DATA) ./files/www/luci-static/resources/mosdns/lib/*.js $(1)/www/luci-static/resources/mosdns/lib/
	$(INSTALL_DATA) ./files/www/luci-static/resources/mosdns/lib/*.css $(1)/www/luci-static/resources/mosdns/lib/

	$(INSTALL_DIR) $(1)/www/luci-static/resources/mosdns/mode/yaml
	$(INSTALL_DATA) ./files/www/luci-static/resources/mosdns/mode/yaml/*.js $(1)/www/luci-static/resources/mosdns/mode/yaml/

	$(INSTALL_DIR) $(1)/www/luci-static/resources/mosdns/theme
	$(INSTALL_DATA) ./files/www/luci-static/resources/mosdns/theme/*.css $(1)/www/luci-static/resources/mosdns/theme/

	$(INSTALL_DIR) $(1)/www/luci-static/resources/mosdns-panel
	$(INSTALL_DATA) ./files/www/luci-static/resources/mosdns-panel/index.html $(1)/www/luci-static/resources/mosdns-panel/

	$(INSTALL_DIR) $(1)/www/luci-static/resources/mosdns-panel/lib
	$(INSTALL_DATA) ./files/www/luci-static/resources/mosdns-panel/lib/all.min.css $(1)/www/luci-static/resources/mosdns-panel/lib/

	$(INSTALL_DIR) $(1)/www/luci-static/resources/mosdns-panel/lib/webfonts
	$(INSTALL_DATA) ./files/www/luci-static/resources/mosdns-panel/lib/webfonts/*.woff2 $(1)/www/luci-static/resources/mosdns-panel/lib/webfonts/
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
