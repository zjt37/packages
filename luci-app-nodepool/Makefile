# Copyright (C) 2018-2020 L-WRT Team
# Copyright (C) 2021-2025 xiaorouji
# Copyright (C) 2026 Openwrt-Passwall Organization
#
# This is free software, licensed under the GNU General Public License v3.

include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-nodepool
PKG_VERSION:=26.8.24
PKG_RELEASE:=1
PKG_PO_VERSION:=$(PKG_VERSION)

PKG_CONFIG_DEPENDS:= \
	CONFIG_PACKAGE_$(PKG_NAME)_Iptables_Transparent_Proxy \
	CONFIG_PACKAGE_$(PKG_NAME)_Nftables_Transparent_Proxy \
	CONFIG_PACKAGE_$(PKG_NAME)_INCLUDE_SingBox \
	CONFIG_PACKAGE_$(PKG_NAME)_INCLUDE_Xray

LUCI_TITLE:=LuCI support for NodePool
LUCI_PKGARCH:=all
LUCI_DEPENDS:=+coreutils +coreutils-base64 +coreutils-nohup +coreutils-timeout +curl \
	+chinadns-ng +dns2socks +dnsmasq-full +ip-full \
	+libuci-lua +lua +luci-compat +luci-lib-jsonc \
	+microsocks +resolveip +tcping +lyaml

define Package/$(PKG_NAME)/config
menu "Configuration"
	depends on PACKAGE_$(PKG_NAME)

config PACKAGE_$(PKG_NAME)_Iptables_Transparent_Proxy
	bool "Iptables Transparent Proxy"
	select PACKAGE_ipset
	select PACKAGE_ipt2socks
	select PACKAGE_iptables
	select PACKAGE_iptables-zz-legacy
	select PACKAGE_iptables-mod-conntrack-extra
	select PACKAGE_iptables-mod-iprange
	select PACKAGE_iptables-mod-socket
	select PACKAGE_iptables-mod-tproxy
	select PACKAGE_kmod-ipt-nat
	default y if ! PACKAGE_firewall4

config PACKAGE_$(PKG_NAME)_Nftables_Transparent_Proxy
	bool "Nftables Transparent Proxy"
	select PACKAGE_ipt2socks
	select PACKAGE_nftables
	select PACKAGE_kmod-nft-socket
	select PACKAGE_kmod-nft-tproxy
	select PACKAGE_kmod-nft-nat
	select PACKAGE_kmod-nf-reject
	select PACKAGE_kmod-nf-reject6
	default y if PACKAGE_firewall4

config PACKAGE_$(PKG_NAME)_INCLUDE_SingBox
	bool "Include Sing-Box"
	select PACKAGE_sing-box
	default y if aarch64||arm||i386||x86_64

config PACKAGE_$(PKG_NAME)_INCLUDE_Xray
	bool "Include Xray"
	select PACKAGE_xray-core
	select PACKAGE_unzip
	default y if aarch64||arm||i386||x86_64

endmenu
endef

define Package/$(PKG_NAME)/conffiles
/etc/config/nodepool
/usr/share/nodepool/rules/direct_host
/usr/share/nodepool/rules/direct_ip
/usr/share/nodepool/rules/proxy_host
/usr/share/nodepool/rules/proxy_ip
/usr/share/nodepool/rules/block_host
/usr/share/nodepool/rules/block_ip
/usr/share/nodepool/rules/lanlist_ipv4
/usr/share/nodepool/rules/lanlist_ipv6
/usr/share/nodepool/rules/domains_excluded
endef

define Package/$(PKG_NAME)/postrm
#!/bin/sh
rm -f $${IPKG_INSTROOT}/usr/share/nodepool/rules/*.nft
exit 0
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)
	$(CP) $(CURDIR)/etc $(CURDIR)/usr $(CURDIR)/www $(1)/
endef

include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildroot signature
