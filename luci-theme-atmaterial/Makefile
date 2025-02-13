include $(TOPDIR)/rules.mk

LUCI_TITLE:=LuCI Atmaterial theme
LUCI_DEPENDS:=+luci-base

define Package/luci-theme-Atmaterial/postrm
#!/bin/sh
[ -n "$${IPKG_INSTROOT}" ] || {
	uci -q delete luci.themes.Atmaterial
	uci commit luci
}
endef

include ../../luci.mk