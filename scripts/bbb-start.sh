#!/bin/bash
# Little helper start script for BigBlueButton in a docker container.
# Author: Juan Luis Baptiste <juan.baptiste@gmail.com>
# Maintainer: Erick Almeida <ephillipe@gmail.com>

TOMCAT_VERSION=tomcat7
DEFAULT_BBB_INSTALL_DEMOS="no"

function get_ip {
    /sbin/ifconfig eth0 | grep 'inet addr:' | cut -d: -f2 | awk '{ print $1}'
}

IP=$(get_ip)
echo "Discovered Server IP: $IP"

if [ ! -z $BBB_INSTALL_DEMOS -a "$BBB_INSTALL_DEMOS" == "yes" ]; then
    echo -e "\e[92mInstalling BigBlueButton demo package...\n\e[0m"
    DEBIAN_FRONTEND=noninteractive apt-get install -y bbb-demo
    [ $? -gt 0 ] && echo - "ERROR: Could not intall the demos." && exit 1
    echo -e "\e[92mDone.\e[0m\n"
fi

figlet -f digital -c "Starting BigBlueButton services..."
service redis-server start
service bbb-openoffice-headless start

figlet -f digital -c "Updating BigBlueButton IP address configuration..."
if [ ! -z "$SERVER_NAME" ];then
    echo -e "\n\e[92mUsing $SERVER_NAME as hostname.\e[0m"
    #Add an entry to /etc/hosts pointing the container IP address
    #to $SERVER_NAME
    printf '%s\t%s\n' $IP $SERVER_NAME | cat >> /etc/hosts
    CONTAINER_IP=$IP
    IP=$SERVER_NAME
fi

figlet -f digital -c "Set new Hostmane to BBB"
bbb-conf --setip $IP

#Replace the IP address on the demo web app, it seems
#bbb-conf --setip doesn't do it
echo -e "\n\e[92mChanging IP address in demo API:\e[0m $IP"
sed -ri "s/(.*BigBlueButtonURL *= *\").*/\1http:\/\/$IP\/bigbluebutton\/\";/" /var/lib/$TOMCAT_VERSION/webapps/demo/bbb_api_conf.jsp

#It seems that some times bbb-conf --setsecret doesn't set the secret on the demo api conf file.
sed -ri "s/(.*salt *= *\").*/\1$SERVER_SALT\";/" /var/lib/$TOMCAT_VERSION/webapps/demo/bbb_api_conf.jsp

#Set the mobile salt to enable mobile access
[ ! -z $MOBILE_SALT ] && echo -e "\n\e[92mSetting mobile salt to:\e[0m $MOBILE_SALT"
[ ! -z $MOBILE_SALT ] && sed -ri "s/(.*mobileSalt *= *\").*/\1$MOBILE_SALT\";/" /var/lib/$TOMCAT_VERSION/webapps/demo/mobile_conf.jsp
[ ! -z $SERVER_SALT ] && echo -e "\n\e[92mSetting Salt to:\e[0m $SERVER_SALT" && bbb-conf --setsecret $SERVER_SALT

#Fix permissions when using a volume container
chown -R $TOMCAT_VERSION:$TOMCAT_VERSION /var/bigbluebutton

#For some reason sometimes meetings fail when started from mconf-web
#until we clean the installation
figlet -f digital -c "Cleaning configuration..."
bbb-conf --clean

figlet -f digital -c "Installing HTML5 client to BBB"
apt-get install bbb-html5
bbb-conf --restart

#echo -e "\n\e[92mChecking configuration...\n"
#bbb-conf --check

echo -e "\n\e[92m*******************************************\e[0m"
echo -e "\n\e[0mUse this address to access your \nBigBlueButton container:\e[92m \n\nhttp://$IP\n\e[0m"
echo -e "\n\e[0mThe container's internal IP address \nis:\e[92m $CONTAINER_IP\n\e[0m"
echo -e "\n\e[92m*******************************************\e[0m\n"

#Ugly hack: Infinite loop to maintain the container running
while true;do sleep 100000;done
