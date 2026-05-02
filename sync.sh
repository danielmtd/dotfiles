cp -r "${HOME}/.config/niri" ./config
cp -r "${HOME}/.config/kitty" ./config

# remove whatever is not used
rm ./config/niri/dms/alttab.kdl
rm ./config/niri/dms/layout.kdl
rm ./config/niri/dms/outputs.kdl
rm ./config/niri/dms/wpblur.kdl
rm -r ./config/niri/dms/profiles

# remove backups, no need of them
rm ./config/niri/config.kdl.backup*
rm ./config/kitty/kitty.conf.bak*