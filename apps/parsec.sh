wget -O libjpeg-turbo http://security.ubuntu.com/ubuntu/pool/main/libj/libjpeg-turbo/libjpeg-turbo8_2.0.3-0ubuntu1.20.04.3_amd64.deb
wget -O libjpeg8 http://mirrors.kernel.org/ubuntu/pool/main/libj/libjpeg8-empty/libjpeg8_8c-2ubuntu8_amd64.deb
sudo apt install ./libjpeg-turbo.deb
sudo apt install ./libjpeg8.deb
rm -r libjpeg-turbo.dev libjpeg8.deb

wget -O parsec.deb 'https://builds.parsec.app/package/parsec-linux.deb'
sudo apt install ./parsec.deb
rm -r parsec.deb
