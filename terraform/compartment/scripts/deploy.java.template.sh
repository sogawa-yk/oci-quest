#!/bin/bash -x
# Copyright (c) 2019-2021 Oracle and/or its affiliates. All rights reserved.
# Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.
#
#
# Description: Sets up Mushop Basic with Java-based Catalogue service
# Return codes: 0 =
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
#

ME=$(basename $0)

get_object() {
    out_file=$1
    os_uri=$2
    success=1
    for i in $(seq 1 9); do
        echo "trying ($i) $2"
        http_status=$(curl -w '%%{http_code}' -L -s -o $1 $2)
        if [ "$http_status" -eq "200" ]; then
            success=0
            echo "saved to $1"
            break 
        else
             sleep 15
        fi
    done
    return $success
}

get_media_pars() {
    input_file=$1
    field=1
    success=1
    count=`sed 's/[^,]//g' $input_file | wc -c`; let "count+=1"
    while [ "$field" -lt "$count" ]; do
            par_url=`cat $input_file | cut -d, -f$field`
            printf "."
            curl -OLs --retry 9 $par_url
            let "field+=1"
    done
    return $success
}

# get artifacts from object storage
get_object /root/wallet.64 ${wallet_par}
# Setup ATP wallet files
base64 --decode /root/wallet.64 > /root/wallet.zip
mkdir -p /app/catalogue/wallet
unzip -o /root/wallet.zip -d /app/catalogue/wallet

############### Java用 追加 ##################

# Init DB (using catalogue service's embedded schema initialization)
export CATALOGUE_DATABASE_URL="jdbc:oracle:thin:@${db_name}_tp?TNS_ADMIN=/app/catalogue/wallet"
export CATALOGUE_DATABASE_USER="ADMIN"
export CATALOGUE_DATABASE_PASSWORD="${atp_pw}"
export 

# Run schema initialization using the Java application
echo "Initializing database schema..."
/usr/bin/java -Dspring.profiles.active=schema-init -jar /app/catalogue/catalogue-1.0.0.jar

# Install Java 21
echo "Installing Java 21..."
if ! dnf -y install java-21-openjdk-headless; then
    echo "Failed to install Java 21"
    exit 1
fi

# Verify Java installation
java_version=$(java -version 2>&1 | head -n 1)
if [[ ! $java_version =~ "21" ]]; then
    echo "Java 21 installation failed"
    exit 1
fi

# Get Java application JAR
get_object /root/catalogue-1.0.0.jar ${mushop_app_par}
mkdir -p /app/catalogue
mv /root/catalogue-1.0.0.jar /app/catalogue/

# Create service user and directories
useradd -r -s /bin/false catalogue
mkdir -p /app/catalogue /var/log/catalogue
chown -R catalogue:catalogue /app/catalogue /var/log/catalogue

# Setup systemd service for Catalogue
cat << EOF > /etc/systemd/system/catalogue.service
[Unit]
Description=MuShop Catalogue Service
After=network.target

[Service]
Environment="CATALOGUE_DATABASE_URL=jdbc:oracle:thin:@${db_name}_tp?TNS_ADMIN=/app/catalogue/wallet"
Environment="CATALOGUE_DATABASE_USER=catalogue"
Environment="CATALOGUE_DATABASE_PASSWORD=${atp_pw}"
Environment="LOGGING_LEVEL_COM_MUSHOP=INFO"
Environment="LOGGING_FILE_PATH=/var/log/catalogue/catalogue.log"
Environment="JAVA_OPTS=-Xms256m -Xmx512m -XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=/var/log/catalogue"
Type=simple
User=catalogue
WorkingDirectory=/app/catalogue
ExecStart=/usr/bin/java \$JAVA_OPTS -jar catalogue-1.0.0.jar
Restart=always
StandardOutput=append:/var/log/catalogue/catalogue.out.log
StandardError=append:/var/log/catalogue/catalogue.err.log

[Install]
WantedBy=multi-user.target
EOF

# Configure SELinux context for the service
semanage fcontext -a -t bin_t "/app/catalogue(/.*)?"
restorecon -R /app/catalogue
semanage fcontext -a -t var_log_t "/var/log/catalogue(/.*)?"
restorecon -R /var/log/catalogue

# Start Catalogue service
systemctl daemon-reload
systemctl enable catalogue
systemctl start catalogue

# Monitor service startup
echo "Waiting for Catalogue service to start..."
for i in {1..30}; do
    if systemctl is-active --quiet catalogue; then
        echo "Catalogue service started successfully"
        break
    fi
    if [ $i -eq 30 ]; then
        echo "Catalogue service failed to start"
        journalctl -u catalogue -n 50
        exit 1
    fi
    sleep 2
done

############### Java用 追加 ##################

# Allow httpd access to storefront
chcon -R -t httpd_sys_content_t /app/storefront/

# If visibility set to private, get MuShop Media Assets
MUSHOP_MEDIA_VISIBILITY=${mushop_media_visibility}
if [[ "$MUSHOP_MEDIA_VISIBILITY" == Private ]]; then
        echo "MuShop Media Private Visibility selected"
        mkdir -p /images
        cd /images        
        echo "Loading MuShop Media Images to Catalogue..."
        get_media_pars /root/mushop_media_pars_list.txt
        echo "Images loaded"
fi

# If enabled, configure storefront to load ODA's web-sdk
ODA_ENABLED=${oda_enabled}
if [[ "$ODA_ENABLED" = true ]]; then
    WWW_DIR=/app/storefront
    ODA_SCRIPTS_DIR=$WWW_DIR/scripts/oda

    export ODA_URI=${oda_uri}
    export ODA_CHANNEL_ID=${oda_channel_id}
    export ODA_SECRET=${oda_secret}
    export ODA_USER_INIT_MESSAGE=${oda_user_init_message}

    echo "$ME: Preparing index.html to enable Oracle Digital Assistant"
    storefrontindex="$WWW_DIR/index.html"
    [ -w $WWW_DIR ] && echo "$ME: Enabling ODA SDK..." || (echo "$ME: File System Not Writable. Exiting..." && exit 0)
    sed -i -e 's|<!-- head placeholder 1 -->|<script src="scripts/oda/settings.js"></script>|g' "$storefrontindex" || (echo "$ME: *** Failed to enable ODA SDK. Exiting..." && exit 0)
    sed -i -e 's|<!-- head placeholder 2 -->|<script src="scripts/oda/web-sdk.js" onload="initSdk('$(echo -e "")'Bots'$(echo -e "")')"></script>|g' "$storefrontindex" || (echo "$ME: *** Failed to enable ODA SDK. Exiting..." && exit 0)

    echo "$ME: Setting ODA variables"
    odasettingsfile="$ODA_SCRIPTS_DIR/settings.js"
    [ -w $odasettingsfile ] && echo "$ME: Running envsubst to update ODA settings.js" || (echo "$ME: settings.js Not Writable. Exiting..." && exit 0)
    (tmpfile=$(mktemp) && \
    (cp -a $odasettingsfile $tmpfile) && \
    (cat $odasettingsfile | envsubst > $tmpfile && mv $tmpfile $odasettingsfile)) || (echo "$ME: *** Failed to update settings.js. Exiting..." && exit 0)
fi
