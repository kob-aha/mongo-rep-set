#!/bin/bash

set -e

printf "\n[-] Installing base OS dependencies...\n\n"

# base
yum update
yum install -y ca-certificates openssl numactl wget


# Gosu
# https://github.com/tianon/gosu
dpkgArch="amd64"
wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch"
wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch.asc"
export GNUPGHOME="$(mktemp -d)"
gpg --keyserver ha.pool.sks-keyservers.net --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4
gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu
rm -r "$GNUPGHOME" /usr/local/bin/gosu.asc
chmod +x /usr/local/bin/gosu
gosu nobody true


# generate a key file for the replica set
# https://docs.mongodb.com/v3.4/tutorial/enforce-keyfile-access-control-in-existing-replica-set
printf "\n[-] Generating a replica set keyfile...\n\n"
openssl rand -base64 741 > $MONGO_KEYFILE
chown mongodb:mongodb $MONGO_KEYFILE
chmod 400 $MONGO_KEYFILE


# install Mongo
printf "\n[-] Installing MongoDB ${MONGO_VERSION}...\n\n"

#apt-key adv --keyserver ha.pool.sks-keyservers.net --recv-keys 0C49F3730359A14518585931BC711F9BA15703C6

#echo "deb http://repo.mongodb.org/apt/debian jessie/mongodb-org/$MONGO_MAJOR main" > /etc/apt/sources.list.d/mongodb-org.list

cat << EOF > /etc/yum.repos.d/mongodb-org-${MONGO_MAJOR}.repo
[mongodb-org-3.4]
name=MongoDB 3.4 Repository
baseurl=https://repo.mongodb.org/yum/redhat/\$releasever/mongodb-org/${MONGO_MAJOR}/x86_64/
gpgcheck=0
enabled=1
EOF

yum update

yum install -y mongodb-org

# cleanup
printf "\n[-] Cleaning up...\n\n"

yum clean all
rm -rf /var/lib/mongodb
mv /etc/mongod.conf /etc/mongod.conf.orig