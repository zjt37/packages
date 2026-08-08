include $(TOPDIR)/rules.mk

PKG_NAME:=custom-settings
PKG_VERSION:=1.0
PKG_RELEASE:=2

include $(INCLUDE_DIR)/package.mk

define Package/custom-settings
  SECTION:=custom
  CATEGORY:=Extra packages
  TITLE:=Custom gateway and DNS settings for bypass router
  DEPENDS:=+parted +f2fs-tools +losetup
  PKGARCH:=all
endef

define Package/custom-settings/description
  Sets default gateway to 192.168.2.2 and DNS to 223.5.5.5
  for bypass router (旁路由) configuration.
  Automatically expands the overlay filesystem on first boot.
endef

define Build/Compile
endef

define Package/custom-settings/install
	$(INSTALL_DIR) $(1)/etc/uci-defaults
	$(INSTALL_BIN) ./root/etc/uci-defaults/98-custom-gateway $(1)/etc/uci-defaults/
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./root/etc/init.d/zz-custom-reboot $(1)/etc/init.d/
endef

$(eval $(call BuildPackage,custom-settings))
