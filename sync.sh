cp -r "${HOME}/.config/niri" ./config

# remove whatever is not used
rm ./config/niri/dms/alttab.kdl
rm ./config/niri/dms/layout.kdl
rm ./config/niri/dms/outputs.kdl
rm ./config/niri/dms/wpblur.kdl
rm ./config/niri/config.kdl.backup*
rm -r ./config/niri/dms/profiles