FROM debian:jessie
MAINTAINER Vasilios Tzanoudakis <vasilios.tzanoudakis@voiceland.gr>

USER root
ENV DEBIAN_FRONTEND noninteractive

WORKDIR /usr/src

RUN apt-get update -qq && apt-get install -y build-essential curl wget libssl-dev vim ngrep \
git apt-utils bison flex m4 pkg-config libncurses5-dev rsyslog \
mariadb-server mariadb-client libmysqlclient-dev memcached libmemcached-dev redis-server libhiredis-dev

COPY files/2.2.6.tar.gz /usr/src/2.2.6.tar.gz
RUN tar xvzf /usr/src/2.2.6.tar.gz 
RUN cd /usr/src/opensips-2.2.6 && make all include_modules="cachedb_memcached cachedb_redis db_mysql" && make install include_modules="cachedb_memcached cachedb_redis db_mysql"

COPY files/node_exporter-0.15.2.linux-amd64.tar.gz /usr/src/node_exporter-0.15.2.linux-amd64.tar.gz
RUN tar -xvf /usr/src/node_exporter-*
RUN cd /usr/src/node_exporter-* && cp node_exporter /usr/bin/
COPY files/node_exporter.init /etc/init.d/node_exporter

COPY files/prometheus-2.2.1.linux-amd64.tar.gz /usr/src/prometheus-2.2.1.linux-amd64.tar.gz
RUN tar -xvf /usr/src/prometheus-2.2.1.linux-amd64.tar.gz
RUN cd /usr/src/prometheus-* && cp prometheus /usr/bin/prometheus
COPY files/prometheus.yml /etc/prometheus.yml 

COPY files/filter_calls.sh /root/scripts/filter_calls.sh
RUN chmod 700 /root/scripts/filter_calls.sh
COPY files/cron.list /usr/src/cron.list

COPY files/grafana_5.0.4_amd64.deb /usr/src/grafana_5.0.4_amd64.deb
RUN apt-get install -y adduser libfontconfig
RUN dpkg -i /usr/src/grafana_5.0.4_amd64.deb

RUN echo "local7.* -/var/log/opensips.log" > /etc/rsyslog.d/opensips.conf
RUN touch /var/log/opensips.log

EXPOSE 5060/udp

COPY run.sh /run.sh
COPY files/opensips.cfg /usr/local/etc/opensips/opensips.cfg
COPY files/prefixes.sql /usr/local/etc/opensips/prefixes.sql
COPY files/redis0.list /usr/local/etc/opensips/redis0.list
COPY files/redis1.list /usr/local/etc/opensips/redis1.list

ENTRYPOINT ["/run.sh"]
