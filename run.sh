#!/bin/bash

MYSQL_ROOT_PASSWORD="opensips"
HOST_IP=$(ip route get 8.8.8.8 | head -n +1 | tr -s " " | cut -d " " -f 7)
GW_IP=$(ip route get 8.8.8.8|head -1|awk -F " " '{print $3}')

sed -i "s/listen=.*/listen=udp:${HOST_IP}:5060/g" /usr/local/etc/opensips/opensips.cfg
sed -i "s/192.168.1.10/${GW_IP}/g" /usr/local/etc/opensips/opensips.cfg

# Install Cron Job
/etc/init.d/cron start
/usr/bin/crontab /usr/src/cron.list

# Syslog Service
service rsyslog start

# Mysql Server
/etc/init.d/mysql start
sleep 2;
/usr/bin/mysqladmin -u root password $MYSQL_ROOT_PASSWORD
/usr/bin/mysqladmin -u root --password=$MYSQL_ROOT_PASSWORD create opensips
/usr/bin/mysql -u root --password=$MYSQL_ROOT_PASSWORD opensips < /usr/src/opensips-2.2.6/scripts/mysql/standard-create.sql 
/usr/bin/mysql -u root --password=$MYSQL_ROOT_PASSWORD opensips < /usr/src/opensips-2.2.6/scripts/mysql/drouting-create.sql
/usr/bin/mysql -u root --password=$MYSQL_ROOT_PASSWORD opensips < /usr/local/etc/opensips/prefixes.sql

# Redis
/etc/init.d/redis-server start
sleep 2;
# Insert demo numbers to Redis DB
/bin/echo "HSET NUMBER 2101234567 590" | redis-cli -n 0 --pipe 
/bin/echo "HSET NUMBER 2132234567 582" | redis-cli -n 0 --pipe
/bin/echo "HSET NUMBER 2142345678 589" | redis-cli -n 0 --pipe
/bin/echo "HSET NUMBER 2150231224 587" | redis-cli -n 0 --pipe
/bin/echo "HSET NUMBER 2101234567 590" | redis-cli -n 1 --pipe
/bin/echo "HSET NUMBER 2132234567 582" | redis-cli -n 1 --pipe
/bin/echo "HSET NUMBER 2142345678 589" | redis-cli -n 1 --pipe
/bin/echo "HSET NUMBER 2150231224 587" | redis-cli -n 1 --pipe

# Memcached
/etc/init.d/memcached start

# Prometheus
/usr/bin/prometheus --config.file=/etc/prometheus.yml &

# Node Exporter
mkdir -p /root/scripts/calls/
chmod 755 /etc/init.d/node_exporter
service node_exporter start

# OpenSIPS
/usr/local/sbin/opensipsctl start

# Grafana
/etc/init.d/grafana-server start

/bin/sleep 10

# Add Prometheus Data Source
/usr/bin/curl --user admin:admin 'http://localhost:3000/api/datasources' -X POST -H 'Content-Type: application/json;charset=UTF-8' --data-binary '{"name":"Prometheus","type":"prometheus","url":"http://localhost:9090","access":"proxy","basicAuth":false}'

# show logs while attached
tail -f /var/log/opensips.log


