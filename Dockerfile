FROM docker.io/centos:7
MAINTAINER RayfordJ <rjohnson@redhat.com>

ENV LANG=en_US.utf8 \
    container=oci

EXPOSE 53 67 68 69 80 443 3000 3306 5910-5930 5432 8140 8443

### Atomic/OpenShift Labels - https://github.com/projectatomic/ContainerApplicationGenericLabels
LABEL name="RHsyseng/foreman" \
      vendor="Acme Corp" \
      version="0.1" \
      release="1" \
      summary="Acme Corp's Foreman/Katello app" \
      description="Foreman/Katello app will do ....." \
### Required labels above - recommended below
      url="https://www.acme.io" 

### foreman/katello directories and files
ENV FK_DEST="/var/foreman-vol"

ENV FK_DIRS=" \
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
/usr/share/xml/scap \
/var/lib/candlepin \
/var/lib/dhcpd \
/var/lib/mongodb \
/var/lib/pgsql/data \
/var/lib/pulp \
/var/lib/puppet/foreman_cache_data \
/var/lib/puppet/ssl \
/var/lib/tftpboot \
/var/named \
/var/www/html/pub \
"

ENV FK_FILES=" \
/etc/named.conf \
/etc/named.iscdlv.key \
/etc/named.rfc1912.zones \
/etc/named.root.key \
/etc/sysconfig/tomcat \
"


RUN yum -y update-minimal --security --sec-severity=Important --sec-severity=Critical --setopt=tsflags=nodocs && \
    yum -y install epel-release centos-release-scl && \
    yum -y install https://yum.puppetlabs.com/puppetlabs-release-el-7.noarch.rpm && \
    yum -y install https://yum.theforeman.org/releases/latest/el7/x86_64/foreman-release.rpm && \
    yum -y install http://fedorapeople.org/groups/katello/releases/yum/3.4/katello/el7/x86_64/katello-repos-latest.rpm && \
## katello/foreman installer packages
    yum -y install --setopt=tsflags=nodocs \
      foreman \
      foreman-cli \
      foreman-debug	\
      foreman-installer	\
      foreman-libvirt \
      foreman-ovirt \
      foreman-postgresql \
      foreman-proxy	\
      foreman-selinux  \
      katello \
      rubygem-smart_proxy_discovery \
      tfm-rubygem-foreman_discovery \
      tfm-rubygem-foreman_remote_execution \
      rubygem-smart_proxy_remote_execution_ssh && \
# VERSION is missing even though sclo-ror42 package claims it...
# `foreman-installer` fails without its existence...
    mkdir -p /opt/rh/sclo-ror42/root/usr/share/gems/gems/mail-2.6.1 && \
    touch /opt/rh/sclo-ror42/root/usr/share/gems/gems/mail-2.6.1/VERSION  && \
# Foreman Discovery Image - latest
    mkdir -p /var/lib/tftpboot/boot && \
    wget http://downloads.theforeman.org/discovery/releases/3.0/fdi-image-latest.tar   -O - | tar x --overwrite -C /var/lib/tftpboot/boot && \
    yum clean all 

STOPSIGNAL SIGRTMIN+3
RUN MASK_JOBS="sys-fs-fuse-connections.mount getty.target systemd-initctl.socket ipmievd.service" && \
    systemctl mask ${MASK_JOBS} && \
    for i in ${MASK_JOBS}; do find /usr/lib/systemd/ -iname $i | grep ".wants" | xargs rm -f; done && \
    rm -f /etc/fstab && \
    systemctl set-default multi-user.target

RUN for d in ${FK_DIRS} ; do mkdir -p "${d}" "${FK_DEST}""${d}" && cp -av "${d}" "$(dirname "${FK_DEST}""${d}")" && rm -rfv "${d}" && ln -vTsf "${FK_DEST}""${d}" "${d}" ; done

#RUN for f in ${FK_FILES} ; do if [ -f "${f}" ] ; then cp -v "${f}" "${FK_DEST}""${f}" && rm -fv "${f}" ; else mkdir -p "${FK_DEST}""$(dirname "${f}")" && touch "${FK_DEST}""${f}" ; fi && ln -vTsf "${FK_DEST}""${f}" "${f}" ; done
RUN for f in ${FK_FILES} ; do cp -v "${f}" "${FK_DEST}""${f}" && rm -fv "${f}" || (mkdir -p "${FK_DEST}""$(dirname "${f}")" && touch "${FK_DEST}""${f}")  && ln -vTsf "${FK_DEST}""${f}" "${f}" ; done

RUN tar --selinux --acls --xattrs -czvf /foreman-katello.tgz "${FK_DEST}" && rm -rfv "${FK_DEST}"/* && touch "${FK_DEST}"/NOT_A_VOLUME

# RUN foreman-installer --scenario katello # --foreman-admin-password  "${ADMINPASSWORD}" 

CMD [ "/sbin/init" ]