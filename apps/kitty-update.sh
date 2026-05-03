# install into /opt
curl -L https://sw.kovidgoyal.net/kitty/installer.sh | sudo sh /dev/stdin \
    installer=version-0.46.2 dest=/opt
# symlink the binary
sudo ln -sf /opt/kitty.app/bin/kitty /usr/bin/kitty
sudo ln -sf /opt/kitty.app/bin/kitten /usr/bin/kitten