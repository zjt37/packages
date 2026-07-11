#!/bin/bash
cd ~/packages
rm -rf /tmp/OpenClash
git clone --depth 1 https://github.com/vernesong/OpenClash.git /tmp/OpenClash
rm -rf luci-app-openclash
cp -r /tmp/OpenClash/luci-app-openclash .
rm -rf /tmp/OpenClash
git add luci-app-openclash
git commit -m 
