#
# Copyright (C) 2008-2014 The LuCI Team <luci@lists.subsignal.org>
#
# This is free software, licensed under the Apache License, Version 2.0 .
#
# Modified theme for Kwrt: cascading fixes (tabs, dropdowns, ifacebox,
# edit modal, firewall page, mobile interaction), custom fonts and logo.
#

include $(TOPDIR)/rules.mk

LUCI_TITLE:=AtMaterial Theme
LUCI_DEPENDS:=+luci-base

PKG_LICENSE:=Apache-2.0

define Package/luci-theme-atmaterial/postrm
#!/bin/sh
[ -n "$${IPKG_INSTROOT}" ] || {
	uci -q delete luci.themes.AtMaterial
	uci commit luci
}
endef

include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildroot signature
