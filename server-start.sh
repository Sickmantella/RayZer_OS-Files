
#Here is the shell file for installing the webserber on the Raspberry Pi.
#This includes everything needed for Apache and PHP.
#Must be run as the root user
echo "WARNING Are you running as the ROOT user?"
echo "WARNING Did you expand your disk using resize2fs AND cfdisk?"
echo "Your partition may not be big enough for the build. Use 'df -h' to check"
echo "****************************************"
echo "* 1. Build Started. Making Directories *"
echo "****************************************"
mkdir /home/make
cd /home/make
echo "***************************"
echo "* 2. Downloading Sources. *"
echo "***************************"
wget https://archive.apache.org/dist/apr/apr-1.7.0.tar.bz2
wget https://archive.apache.org/dist/apr/apr-util-1.6.1.tar.bz2
wget https://ftp.pcre.org/pub/pcre/pcre-8.44.tar.bz2
wget https://archive.apache.org/dist/httpd/httpd-2.4.46.tar.bz2
wget http://anduin.linuxfromscratch.org/BLFS/blfs-bootscripts/blfs-bootscripts-20200818.tar.xz
wget http://www.linuxfromscratch.org/patches/blfs/10.0/httpd-2.4.46-blfs_layout-1.patch
wget http://xmlsoft.org/sources/libxml2-2.9.10.tar.gz
wget http://www.php.net/distributions/php-7.4.9.tar.xz
wget https://raw.githubusercontent.com/Sickmantella/Rayzer_OS-Files/main/Server/crc32.c
echo "***************************"
echo "* 3. Installing Apr-1.7.0 *"
echo "***************************"
tar -xf apr-1.7.0.tar.bz2
cd apr-1.7.0
./configure --prefix=/usr    \
            --disable-static \
            --with-installbuilddir=/usr/share/apr-1/build &&
make
make install
cd /home/make
rm -rf apr-1.7.0
echo "********************************"
echo "* 4. Installing Apr-Util-1.6.1 *"
echo "********************************"
tar -xf apr-util-1.6.1.tar.bz2
cd apr-util-1.6.1
./configure --prefix=/usr       \
            --with-apr=/usr     \
            --with-gdbm=/usr    \
            --with-openssl=/usr \
            --with-crypto &&
make
make install
cd /home/make
rm -rf apr-util-1.6.1
echo "***************************"
echo "* 5. Installing PCRE-8.44 *"
echo "***************************"
tar -xf pcre-8.44.tar.bz2
cd pcre-8.44
./configure --prefix=/usr                     \
            --docdir=/usr/share/doc/pcre-8.44 \
            --enable-unicode-properties       \
            --enable-pcre16                   \
            --enable-pcre32                   \
            --enable-pcregrep-libz            \
            --enable-pcregrep-libbz2          \
            --enable-pcretest-libreadline     \
            --disable-static                 &&
make
make install                     &&
mv -v /usr/lib/libpcre.so.* /lib &&
ln -sfv ../../lib/$(readlink /usr/lib/libpcre.so) /usr/lib/libpcre.so
cd /home/make
rm -rf pcre-8.44
echo "************************"
echo "* 6. Installing Apache *"
echo "************************"
tar -xf httpd-2.4.46.tar.bz2
cd httpd-2.4.46
groupadd -g 25 apache &&
useradd -c "Apache Server" -d /srv/www -g apache \
        -s /bin/false -u 25 apache
        sed -i 's/lua_resume(a, NULL, b)/lua_resume(a, NULL, b, NULL)/' modules/lua/mod_lua.h
patch -Np1 -i ../httpd-2.4.46-blfs_layout-1.patch             &&

sed '/dir.*CFG_PREFIX/s@^@#@' -i support/apxs.in              &&

./configure --enable-authnz-fcgi                              \
            --enable-layout=BLFS                              \
            --enable-mods-shared="all cgi"                    \
            --enable-mpms-shared=all                          \
            --enable-suexec=shared                            \
            --with-apr=/usr/bin/apr-1-config                  \
            --with-apr-util=/usr/bin/apu-1-config             \
            --with-suexec-bin=/usr/lib/httpd/suexec           \
            --with-suexec-caller=apache                       \
            --with-suexec-docroot=/srv/www                    \
            --with-suexec-logfile=/var/log/httpd/suexec.log   \
            --with-suexec-uidmin=100                          \
            --with-suexec-userdir=public_html                 &&
make
make install  &&

mv -v /usr/sbin/suexec /usr/lib/httpd/suexec &&
chgrp apache           /usr/lib/httpd/suexec &&
chmod 4754             /usr/lib/httpd/suexec &&

chown -v -R apache:apache /srv/www
cd /home/make
rm -rf httpd-2.4.46
cd /home/make
echo "************************"
echo "* 7. Installing libxml *"
echo "************************"
tar -xf libxml2-2.9.10.tar.gz
cd libxml2-2.9.10
./configure --prefix=/usr    \
            --disable-static \
            --with-history   \
            --with-python=/usr/bin/python3 &&
make
make install
cd /home/make
rm -rf libxml2-2.9.10
echo "*********************"
echo "* 7. Installing PHP *"
echo "*********************"
tar -xf php-7.4.9.tar.xz
cd php-7.4.9
rm -rf ext/standard/crc32.c
mv /home/make/crc32.c ext/standard/crc32.c
./configure --prefix=/usr                \
            --sysconfdir=/etc            \
            --localstatedir=/var         \
            --datadir=/usr/share/php     \
            --mandir=/usr/share/man      \
            --without-pear               \
            --enable-fpm                 \
            --with-fpm-user=apache       \
            --with-fpm-group=apache      \
            --with-config-file-path=/etc \
            --with-zlib                  \
            --enable-bcmath              \
            --with-bz2                   \
            --enable-calendar            \
            --enable-dba=shared          \
            --with-gdbm                  \
            --with-gmp                   \
            --enable-ftp                 \
            --with-gettext               \
            --enable-mbstring            \
            --disable-mbregex            \
            --with-readline              &&
make -j4
make install                                     &&
install -v -m644 php.ini-production /etc/php.ini &&

install -v -m755 -d /usr/share/doc/php-7.4.9 &&
install -v -m644    CODING_STANDARDS* EXTENSIONS NEWS README* UPGRADING* \
                    /usr/share/doc/php-7.4.9
if [ -f /etc/php-fpm.conf.default ]; then
  mv -v /etc/php-fpm.conf{.default,} &&
  mv -v /etc/php-fpm.d/www.conf{.default,}
fi
sed -i 's@php/includes"@&\ninclude_path = ".:/usr/lib/php"@' \
    /etc/php.ini
sed -i -e '/proxy_module/s/^#//'      \
       -e '/proxy_fcgi_module/s/^#//' \
       /etc/httpd/httpd.conf
echo \
'ProxyPassMatch ^/(.*\.php)$ fcgi://127.0.0.1:9000/srv/www/$1' >> \
/etc/httpd/httpd.conf
cd /home/make
rm -rf php-7.4.9
echo "***************************************"
echo "* 8. Making Apach & PHP Start on Boot *"
echo "***************************************"
tar -xf blfs-bootscripts-20200818.tar.xz
cd blfs-bootscripts-20200818
make install-httpd
make install-php
cd /home/make
rm -rf blfs-bootscripts-20200818
echo "********"
echo "* Done *"
echo "********"
echo "+----------------------------------------------------------------+"
echo "|  The Server Directory is '/svr/www'                            |"
echo "|  PHP-7.4.9 has been installed                                  |"
echo "|  Please Restart your Raspberry Pi to start the server          |"
echo "+----------------------------------------------------------------+"
