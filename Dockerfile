from base/archlinux:latest

MAINTAINER hradec <hradec@hradec.com>

# install needed packages
RUN  	echo -e '\n\n[archlinuxfr]\nSigLevel = Never\nServer = http://repo.archlinux.fr/$arch\n\n' >> /etc/pacman.conf ; \
    	pacman -Syyuu --noconfirm ; \
	pacman -S yaourt sudo net-tools nfs-utils sudo base-devel rsync git zip --noconfirm

# add yaourt user and group
RUN groupadd -r yaourt && \
    useradd -r -g yaourt yaourt
RUN mkdir /tmp/yaourt && \
    chown -R yaourt:yaourt /tmp/yaourt ; \
    echo 'yaourt ALL=(ALL) NOPASSWD: ALL' | EDITOR='tee -a' visudo


# patch aur lizardfs to build the latest git commit - master.zip
USER yaourt

RUN \
    export MAKEFLAGS=" -j $(grep processor /proc/cpuinfo | wc -l) " && \
    cd /tmp/yaourt && \
    curl 'https://aur.archlinux.org/cgit/aur.git/plain/PKGBUILD?h=lizardfs' > ./PKGBUILD &&\
    curl 'https://aur.archlinux.org/cgit/aur.git/plain/cmath.patch?h=lizardfs' > ./cmath.patch &&\
    curl 'https://aur.archlinux.org/cgit/aur.git/plain/lizardfs.install?h=lizardfs' > ./lizardfs.install &&\
    cp ./PKGBUILD ./PKGBUILD.original && \
    cat  ./PKGBUILD.original \
        | sed 's/.http:..github.com.lizardfs.lizardfs.archive....pkgver..tar.gz./lizardfs-master.zip/g' \
        | sed 's/3.11.3/master/' && \
    git clone http://cr.skytechnology.pl:8081/lizardfs lizardfs-master &&\
    zip lizardfs-master.zip ./lizardfs-master &&\
    makepkg . --skipchecksums --install --syncdeps --noconfirm




USER root
RUN pacman -S nano openssh --noconfirm ;\
    pacman -Scc --noconfirm

RUN \
	echo "PermitRootLogin yes" >> /etc/ssh/sshd_config ; \
	echo "root:t" | chpasswd ;\
	/usr/bin/ssh-keygen -A ;\
	cp /etc/mfs/mfsexports.cfg.dist /etc/mfs/mfsexports.cfg ;\
	cp /var/lib/mfs/metadata.mfs.empty /etc/mfs/ ; \
\
	echo "PERSONALITY = master" 	>> /etc/mfs/mfsmaster.cfg ;\
	echo "WORKING_USER = root" 	>> /etc/mfs/mfsmaster.cfg ;\
	echo "WORKING_GROUP = root" 	>> /etc/mfs/mfsmaster.cfg ;\
	echo "AUTO_RECOVERY = 1" 	>> /etc/mfs/mfsmaster.cfg ;\
	echo "EXPORTS_FILENAME = /etc/mfs/mfsexports.cfg" >> /etc/mfs/mfsmaster.cfg ;\
\
	echo "LABEL = _"  		>> /etc/mfs/mfsmaster.cfg ;\
	echo "WORKING_USER = root"  	>> /etc/mfs/mfsmaster.cfg ;\
	echo "WORKING_GROUP = root"  	>> /etc/mfs/mfsmaster.cfg ;\
	echo "ENABLE_LOAD_FACTOR = 1" 	>> /etc/mfs/mfsmaster.cfg ;\
	echo "PERFORM_FSYNC = 0"  	>> /etc/mfs/mfsmaster.cfg ;\
\
    echo "LABEL = _ "  		>> /etc/mfs/mfschunkserver.cfg ;\
    echo "WORKING_USER = root "  	>> /etc/mfs/mfschunkserver.cfg ;\
    echo "WORKING_GROUP = root "  	>> /etc/mfs/mfschunkserver.cfg ;\
    echo "ENABLE_LOAD_FACTOR = 1 "  >> /etc/mfs/mfschunkserver.cfg ;\
    echo "PERFORM_FSYNC = 0 "  	>> /etc/mfs/mfschunkserver.cfg ;\
\
    echo "WORKING_USER = root "  	>> /etc/mfs/mfsmetalogger.cfg ;\
    echo "WORKING_GROUP = root "  	>> /etc/mfs/mfsmetalogger.cfg ;\
\
    rm -rf /tmp/yaourt ;\
    pacman -Scc --noconfirm



ENV MOUNTS=''

ADD run.sh /

EXPOSE 9422


CMD [ "/run.sh" ]
