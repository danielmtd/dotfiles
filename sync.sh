cp -r "${HOME}/.config/niri" "./config"

# remove whatever is not used
rm "./config/niri/alttab.kdl"
rm "./config/niri/layout.kdl"
rm "./config/niri/outputs.kdl"
rm "./config/niri/wpblur.kdl"
rm -r "./config/niri/profiles"