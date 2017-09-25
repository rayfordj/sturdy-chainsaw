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

# Script to relocate to volume post-installation completion
COPY relocate-foreman.sh /root/relocate-foreman.sh
RUN chmod 0755 /root/relocate-foreman.sh

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
# package name change in centos base 
        ## /usr/share/foreman-installer/modules/foreman_proxy/manifests/tftp.pp
    sed -i.orig -e "s/'grub2-efi'/'grub2-efi-x64'/" -e "s/'grub2-efi-modules'/'grub2-efi-x64-modules'/" -e "s/'shim'/'shim-x64'/" /usr/share/foreman-installer/modules/foreman_proxy/manifests/tftp.pp && \
# Foreman Discovery Image - latest
    mkdir -p /var/foreman-vol/var/lib/tftpboot/boot && \
    wget http://downloads.theforeman.org/discovery/releases/3.0/fdi-image-latest.tar   -O - | tar x --overwrite -C /var/foreman-vol/var/lib/tftpboot/boot && \
    yum clean all 

STOPSIGNAL SIGRTMIN+3
RUN MASK_JOBS="sys-fs-fuse-connections.mount getty.target systemd-initctl.socket ipmievd.service" && \
    systemctl mask ${MASK_JOBS} && \
    for i in ${MASK_JOBS}; do find /usr/lib/systemd/ -iname $i | grep ".wants" | xargs rm -f; done && \
    rm -f /etc/fstab && \
    systemctl set-default multi-user.target


# RUN foreman-installer --scenario katello # --foreman-admin-password  "${ADMINPASSWORD}" 

CMD [ "/sbin/init" ]