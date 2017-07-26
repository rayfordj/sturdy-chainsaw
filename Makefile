VERSION = v0.1
IMAGE_NAME = foreman

all: build
build:
	docker build --pull -t ${IMAGE_NAME}:${VERSION} -t ${IMAGE_NAME} .
	docker run --net=host --privileged -tdi -p 192.168.172.1:53:53/udp -p 192.168.172.1:53:53 -p 192.168.172.1:67-68:67-68/udp -p 192.168.172.1:69:69/udp -p 192.168.172.1:80:80 -p 192.168.172.1:443:443 -p 192.168.172.1:3000:3000 -p 192.168.172.1:3306:3306 -p 192.168.172.1:5432:5432 -p 192.168.172.1:5647:5647 -p 192.168.172.1:5910-5930:5910-5930 -p 192.168.172.1:8140:8140 -p 192.168.172.1:8443:8443 -p 192.168.172.1:9090:9090  --name ${IMAGE_NAME} --hostname="container1.priv.rhcsha.bos.redhat.com" ${IMAGE_NAME}
	docker exec ${IMAGE_NAME} foreman-installer --scenario katello --foreman-admin-password="AdminPassword" --foreman-proxy-dns true --foreman-proxy-dns-interface eth1 --foreman-proxy-dns-zone container1.priv.rhcsha.bos.redhat.com --foreman-proxy-dns-forwarders 10.19.7.248 --foreman-proxy-dns-reverse 172.168.192.in-addr.arpa --foreman-proxy-dhcp true --foreman-proxy-dhcp-interface eth1 --foreman-proxy-dhcp-range "192.168.172.101 192.168.172.199" --foreman-proxy-dhcp-gateway 192.168.172.1 --foreman-proxy-dhcp-nameservers 192.168.172.1 --foreman-proxy-puppet true --foreman-proxy-puppetca true --enable-foreman-plugin-discovery --foreman-plugin-discovery-source-url=http://downloads.theforeman.org/discovery/releases/3.0/ --foreman-plugin-discovery-install-images=true --enable-foreman-plugin-remote-execution --enable-foreman-proxy-plugin-remote-execution-ssh
	@if docker images ${IMAGE_NAME}:${VERSION}; then touch build; fi

lint:
	dockerfile_lint -f Dockerfile

test:
	docker build --pull -t ${IMAGE_NAME}:${VERSION} -t ${IMAGE_NAME} .
	docker run -tdi --name ${IMAGE_NAME} --hostname="localhost.localdomain" ${IMAGE_NAME}
	@sleep 5
	@docker exec ${IMAGE_NAME} foreman-installer --list-scenarios
	@docker exec ${IMAGE_NAME} foreman-installer --scenario katello --help
	@docker rm -f ${IMAGE_NAME}

clean:
	rm -f build