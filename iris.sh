#!/bin/sh

set -e
set -x

 sudo yum -y update
 sudo yum -y install epel python python-devel python-virtualenv \
    mariadb-server openldap-devel libssl-devel libxml2-devel git \
    wget
sudo yum -y groupinstall "Development tools"

cd /tmp
wget https://bin.equinox.io/c/ekMN3bCZFUn/forego-stable-linux-amd64.tgz
sudo tar xvf forego-stable-linux-amd64.tgz -C /usr/local/bin

sudo systemctl enable mariadb
sudo systemctl start mariadb

cd $HOME
test -d $HOME/iris && rm -rf $HOME/iris
git clone https://github.com/linkedin/iris
cd $HOME/iris

mysql -u root < ./db/schema_0.sql
mysql -u root -o iris < ./db/dummy_data.sql

virtualenv venv
source venv/bin/activate
pip install --upgrade pip || true
pip install -e '.[dev]' || true

sudo tee /etc/systemd/system/iris.service <<EOF
[Unit]
Description=Iris
After=network.target

[Service]
Type=simple
User=vagrant
Group=vagrant
ExecStart=/bin/sh -c 'cd /home/vagrant/iris && source venv/bin/activate && forego start'
Restart=always

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable iris
sudo systemctl start iris
