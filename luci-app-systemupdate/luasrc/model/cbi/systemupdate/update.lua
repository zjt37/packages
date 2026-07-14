local m, s, o

m = Map("systemupdate", translate("系统更新"),
	translate("从 GitHub 在线更新固件"))

s = m:section(TypedSection, "systemupdate")
s.anonymous = true
s.addremove = false

o = s:option(Button, "_check", translate("检查更新"))
o.inputstyle = "apply"
o.onclick = function(self, section)
	luci.http.redirect(luci.dispatcher.build_url("admin/system/systemupdate") .. "?action=check")
end

o = s:option(Button, "_update", translate("开始更新"))
o.inputstyle = "reset"
o.onclick = function(self, section)
	luci.http.redirect(luci.dispatcher.build_url("admin/system/systemupdate") .. "?action=update")
end

return m
