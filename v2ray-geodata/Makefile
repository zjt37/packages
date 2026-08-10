# SPDX-License-Identifier: GPL-3.0-only

include $(TOPDIR)/rules.mk

PKG_NAME:=v2ray-geodata
PKG_RELEASE:=1

PKG_LICENSE_FILES:=LICENSE

include $(INCLUDE_DIR)/package.mk

define Package/v2ray-geodata/template
  SECTION:=net
  CATEGORY:=Network
  SUBMENU:=IP Addresses and Names
  PKGARCH:=all
endef

define Package/v2ray-geoip
  $(call Package/v2ray-geodata/template)
  TITLE:=GeoIP List for V2Ray (Loyalsoldier)
  PROVIDES:=@v2ray-geodata @xray-geodata @xray-geoip
  VERSION:=20260810-r$(PKG_RELEASE)
  LICENSE:=CC-BY-SA-4.0
endef

define Package/v2ray-geosite
  $(call Package/v2ray-geodata/template)
  TITLE:=Geosite List for V2Ray (Loyalsoldier)
  PROVIDES:=@v2ray-geodata @xray-geodata @xray-geosite
  VERSION:=20260810-r$(PKG_RELEASE)
  LICENSE:=MIT
endef

define Build/Compile
endef

define Package/v2ray-geoip/install
	$(INSTALL_DIR) $(1)/usr/share/v2ray $(1)/usr/share/xray
	$(INSTALL_DATA) $(CURDIR)/root/usr/share/v2ray/geoip.dat $(1)/usr/share/v2ray/geoip.dat
	$(LN) ../v2ray/geoip.dat $(1)/usr/share/xray/geoip.dat
endef

define Package/v2ray-geosite/install
	$(INSTALL_DIR) $(1)/usr/share/v2ray $(1)/usr/share/xray
	$(INSTALL_DATA) $(CURDIR)/root/usr/share/v2ray/geosite.dat $(1)/usr/share/v2ray/geosite.dat
	$(LN) ../v2ray/geosite.dat $(1)/usr/share/xray/geosite.dat
endef

$(eval $(call BuildPackage,v2ray-geoip))
$(eval $(call BuildPackage,v2ray-geosite))
