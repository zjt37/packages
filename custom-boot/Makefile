include $(TOPDIR)/rules.mk

PKG_NAME:=custom-boot
PKG_VERSION:=1.0
PKG_RELEASE:=1

include $(INCLUDE_DIR)/package.mk

define Package/custom-boot
  SECTION:=custom
  CATEGORY:=Extra packages
  TITLE:=Boot-time settings for bypass router
  PKGARCH:=all
  DEPENDS:=
endef

define Package/custom-boot/description
  First-boot script: sets gateway/DNS and disables LAN DHCP
  for bypass router (旁路由) configuration.
endef

define Build/Compile
endef

define Package/custom-boot/install
	$(INSTALL_DIR) $(1)/etc/uci-defaults
	$(INSTALL_BIN) ./root/etc/uci-defaults/98-custom-boot $(1)/etc/uci-defaults/
endef

$(eval $(call BuildPackage,custom-boot))