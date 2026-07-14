local m, s, o

m = Map("systemupdate", translate("系统更新"),
	translate("从 GitHub 在线更新固件"))

s = m:section(TypedSection, "systemupdate")
s.anonymous = true
s.addremove = false

o = s:option(ListValue, "install_mode", translate("安装模式"))
o:value("fresh", translate("全新安装（不保留配置）"))
o:value("keep", translate("保留配置更新"))
o.default = "fresh"

o = s:option(Button, "_check", translate("检查更新"))
o.inputstyle = "apply"

o = s:option(Button, "_update", translate("开始更新"))
o.inputstyle = "reset"

return m
