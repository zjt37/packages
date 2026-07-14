include $(TOPDIR)/rules.mk

PKG_NAME:=custom-settings
PKG_VERSION:=1.0
PKG_RELEASE:=1

include $(INCLUDE_DIR)/package.mk

define Package/custom-settings
  SECTION:=custom
  CATEGORY:=Extra packages
  TITLE:=Custom gateway and DNS settings for bypass router
  PKGARCH:=all
endef

define Package/custom-settings/description
  Sets default gateway to 192.168.2.2 and DNS to 223.5.5.5
  for bypass router (旁路由) configuration.
endef

define Build/Compile
endef

define Package/custom-settings/install
	$(INSTALL_DIR) $(1)/etc/uci-defaults
	$(INSTALL_BIN) ./root/etc/uci-defaults/99-custom-gateway $(1)/etc/uci-defaults/
endef

$(eval $(call BuildPackage,custom-settings))
