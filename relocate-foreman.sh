#!/bin/bash

set -x

### foreman/katello directories and files
FK_DEST="/var/foreman-vol"

FK_DIRS=" \
/etc/candlepin \
/etc/dhcp \
/etc/foreman \
/etc/foreman-installer \
/etc/foreman-proxy \
/etc/hammer \
/etc/httpd/conf \
/etc/httpd/conf.d \
/etc/named \
/etc/pki/katello \
/etc/pki/katello-certs-tools \
/etc/pki/pulp \
/etc/pulp \
/etc/puppet \
/etc/puppetlabs \
/etc/qpid \
/etc/qpid-dispatch \
/etc/squid \
/etc/tomcat \
/opt/puppetlabs/puppet/cache/foreman_cache_data \
/opt/puppetlabs/puppet/ssl \
/root/ssl-build \
/usr/share/foreman \
/usr/share/foreman-installer \
/usr/share/foreman-installer-katello \
/usr/share/foreman-proxy \
/usr/share/xml/scap \
/var/lib/candlepin \
/var/lib/dhcpd \
/var/lib/mongodb \
/var/lib/pgsql/data \
/var/lib/puppet/foreman_cache_data \
/var/lib/puppet/ssl \
/var/lib/tftpboot \
/var/named \
/var/www/html/pub \
"

FK_FILES=" \
/etc/named.conf \
/etc/named.iscdlv.key \
/etc/named.rfc1912.zones \
/etc/named.root.key \
/etc/sysconfig/tomcat \
"

#Stop services
katello-service stop
systemctl stop dhcpd named puppet xinetd 


if [[ ! -f "${FK_DEST}"/PERSISTED ]] && [[ ! -h /etc/foreman-installer ]]; then 
#Shuffle data
for d in ${FK_DIRS} ; do 
        mkdir -p "${FK_DEST}""${d}" &&  \
        if [ -d "${d}" ]; then 
                cp -av "${d}" "$(dirname "${FK_DEST}""${d}")" && \
                rm -rfv "${d}" ; fi && \
        ln -vTsf "${FK_DEST}""${d}" "${d}" ; done

for f in ${FK_FILES} ; do 
        cp -av "${f}" "${FK_DEST}""${f}" && \
        rm -fv "${f}" || \
        (mkdir -p "${FK_DEST}""$(dirname "${f}")" && \
        touch "${FK_DEST}""${f}")  && \
        ln -vTsf "${FK_DEST}""${f}" "${f}" ; done

touch "${FK_DEST}"/PERSISTED
fi


if [[ -f "${FK_DEST}"/PERSISTED ]] && [[  ! -h /etc/foreman-installer ]]; then 
#Persisted, not setup
for d in ${FK_DIRS} ; do 
        if [ ! -h "${d}" ]; then 
                rm -rfv "${d}" ; fi && \
        ln -vTsf "${FK_DEST}""${d}" "${d}" ; done

for f in ${FK_FILES} ; do 
        if [ ! -h "${f}" ]; then 
                rm -fv "${f}" ; fi && \
        ln -vTsf "${FK_DEST}""${f}" "${f}" ; done

fi
#Start services
systemctl start dhcpd named puppet xinetd 
katello-service start

