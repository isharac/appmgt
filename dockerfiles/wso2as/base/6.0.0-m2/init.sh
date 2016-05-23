#!/usr/bin/env bash

if [ -z ${ADMIN_PASSWORD+x} ]; then 
    echo "ADMIN_PASSWORD is not set.";
    echo "Genarating admin password.";
    ADMIN_PASSWORD=${ADMIN_PASS:-$(pwgen -s 12 1)}
    echo "========================================================================="
    echo "Credentials for the instance:"
    echo
    echo "    user name: admin"
    echo "    password : $ADMIN_PASSWORD"
    echo "========================================================================="
else
    echo "ADMIN_PASSWORD set by user.";
fi

cat >/opt/wso2as-${WSO2_AS_VERSION}-m2/conf/tomcat-users.xml <<EOL
<?xml version="1.0" encoding="utf-8"?>
<tomcat-users>
  <role rolename="admin-gui"/>
  <role rolename="admin-script"/>
  <role rolename="manager-gui"/>
  <role rolename="manager-status"/>
  <role rolename="manager-script"/>
  <user name="admin" password="$ADMIN_PASSWORD"
    roles="admin-gui,admin-script,manager-gui,manager-status,manager-script"/>
</tomcat-users>
EOL

# If the webapps directory is empty (the user has specified a volume), copy the
# contents from the folder in tmp (which is created when the image was built).
WEBAPPS_HOME="/opt/tomcat/webapps"
WEBAPPS_TMP="/tmp/webapps"

if [ ! "$(ls -A $WEBAPPS_HOME)" ]; then
    cp -r $WEBAPPS_TMP/* $WEBAPPS_HOME
fi

CERT_PASSWORD="wso2carbon"

# Uncomment SSL section in server.xml
# and insert SSL certificate information
sed -i '$!N;s/<!--\s*\n\s*<Connector port="8443"/<Connector port="8443" keyAlias="wso2carbon" \
               keystoreFile="\/wso2carbon.jks" keystorePass="'$CERT_PASSWORD'"/g;P;D' \
               /opt/wso2as-${WSO2_AS_VERSION}-m2/conf/server.xml

sed -i '$!N;s/clientAuth="false" sslProtocol="TLS" \/>\n\s*-->/clientAuth="false" sslProtocol="TLS" \/>/g;P;D' \
/opt/wso2as-${WSO2_AS_VERSION}-m2/conf/server.xml

sed -i "s/unpackWARs=\"true\"/unpackWARs=\"false\"/g" /opt/wso2as-${WSO2_AS_VERSION}-m2/conf/server.xml

sed -i "/\/Host/i  \\\t<Context path=\"""\" docBase=\"$APP_WAR\" debug=\"0\" reloadable=\"true\"></Context>" /opt/wso2as-${WSO2_AS_VERSION}-m2/conf/server.xml

sed -i '/<Context>/a <JarScanner scanClassPath="false" />' /opt/wso2as-${WSO2_AS_VERSION}-m2/conf/context.xml

/opt/tomcat/bin/catalina.sh run
