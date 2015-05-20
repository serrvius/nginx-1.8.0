#!/bin/bash

#Create by Sergiu Botnarenco
#
#script for complile&install nginx

echo "Init install nginx-1.8.0 script"
echo ""

NGINX_PATH="/etc/nginx"
NGINX_SBIN="/ust/sbin/nginx"
NGINX_PID="/var/run"
NGINX_LOGS="/var/log/nginx"
NGINX_LIBS="/usr/local/nginx/lib"
NGINX_VHOST_PATH="/etc/nginx"

DEPENDENS=(libgd2-xpm-dev checkinstall libssl-dev make openssl automake);


#if [ "dpkg-query -W nginx | awk {'print $1'} = """ ]; then
NGX_INSTALLED_STATUS=$(dpkg -s nginx | grep --regexp='ok installed' | awk {'print $4'});
if [ $NGX_INSTALLED_STATUS == 'installed' ]; then
	echo "Nginx package is already installed, for current version install please remove instaled version"
	echo " ";
	exit;
fi;

if [ ! -d "$NGINX_PATH" ]; then
	echo "Create nginx path [$NGINX_PATH]"
	sudo mkdir -p "$NGINX_PATH"
fi

if [ ! -d "$NGINX_LIBS" ]; then 
	echo "Create nginx lib's path [$NGINX_LIBS]"
	sudo mkdir -p "$NGINX_LIBS"
fi 

if [ ! -d "$NGINX_LOGS" ]; then
	echo "Create nginx log path [$NGINX_LOGS]"
	sudo mkdir -p "$NGINX_LOGS"
fi

echo "Copy extensions to libs path [$NGINX_LIBS]";

sudo cp -R ./libs/* "$NGINX_LIBS"/


echo "Check required dependences:"
NEED_TO_INSTALL='';
for i in "${DEPENDENS[@]}"
do
	dpkg -s "$i" >/dev/null 2>&1 && {
        	echo "$i is installed."
	} || {
		NEED_TO_INSTALL="$NEED_TO_INSTALL $i"
	}
done;

echo "$NEED_TO_INSTALL"

if [ -n "$NEED_TO_INSTALL" ]; then
	echo "Install package dependences: $NEED_TO_INSTALL"
	sudo apt-get install $NEED_TO_INSTALL
fi;

ATMK_VERSION=$(automake --version | grep --regexp='\ [0-9].[0-9]\+$' | awk {'print $4'})
if [ "$ATMK_VERSION" != "1.15" ]; then
	echo "Upgrade automake 1.15";
	cd "./utils/";
	tar -xzf automake-1.15.tar.gz
	cd "automake-1.15/";
	./configure
	make && sudo make install
	cd ".."
	sudo rm -Rf "automake-1.15"
	cd ".."
fi;

cd "./nginx-1.8.0/"
./configure --prefix="$NGINX_PATH" \
	--user=www-data \
	--group=www-data \
	--error-log-path="$NGINX_LOGS"/error.log \
	--pid-path="$NGINX_PID"/nginx.pid \
	--lock-path="$NGINX_PID"/lock/nginx.lock \
	--with-http_ssl_module \
	--with-http_secure_link_module \
	--with-http_image_filter_module \
	--with-zlib="$NGINX_LIBS"/zlib-1.2.8 \
	--with-pcre="$NGINX_LIBS"/pcre-8.37 \
	--add-module="$NGINX_LIBS"/nginx_http_push_module-0.712
sudo make
sudo checkinstall -y --install=yes

cd ..

if [ ! -d "$NGINX_VHOST_PATH/sites-available" ]; then
        echo "Create nginx availbe hosts path [$NGINX_VHOST_PATH/sites-available]"
        sudo mkdir -p "$NGINX_VHOST_PATH/sites-available"
fi

if [ ! -d "$NGINX_VHOST_PATH/sites-enabled" ]; then
        echo "Create nginx enabled hosts path [$NGINX_VHOST_PATH/sites-enabled]"
        sudo mkdir -p "$NGINX_VHOST_PATH/sites-enabled"
fi


echo "Prepare start/strop scripts"
sudo cp ./scripts/nginx.conf.init /etc/init/nginx.conf
sudo ln -sf /lib/init/upstart-job /etc/init.d/nginx
sudo ln -sf /etc/nginx/sbin/nginx /usr/sbin/nginx

sudo cp ./scripts/nginx.conf.srv "$NGINX_PATH"/conf/nginx.conf
INCLUDE_PATH="include $NGINX_PATH/sites-enabled/*;"
RPATH="${INCLUDE_PATH//\//\\/}"
sudo sed -i "s/#ENABLED_HOST_PATH#/${RPATH}/g" "$NGINX_PATH"/conf/nginx.conf

sudo cp ./scripts/default_https "$NGINX_PATH"/sites-available/default_https
sudo cp ./scripts/default "$NGINX_PATH"/sites-available/default

RNPATH="${NGINX_PATH//\//\\/}"
sudo cp ./scripts/nginx_aliases ~/.nginx_aliases
sudo sed -i "s/#NGINX_PATH#/${RNPATH}/g" ~/.nginx_aliases
sudo chmod a+x ~/.nginx_aliases
if grep -Fsq "~/.nginx_aliases" ~/.bashrc
then
	. ~/.bashrc
else
	echo 'if [ -f ~/.nginx_aliases ];  then
		. ~/.nginx_aliases
	fi' >> ~/.bashrc
	. ~/.bashrc
fi

sudo ln -sf $NGINX_PATH/sites-available/default $NGINX_PATH/sites-enabled/default

sudo mkdir -p /var/www/html;
sudo cp -f ./scripts/index.html ./scripts/50x.html -t /var/www/html/;
sudo cp -f ./scripts/index.html ./scripts/50x.html -t /etc/nginx/html/;

sudo service nginx start

sudo update-rc.d nginx defaults

sudo service nginx status


