FROM ubuntu:18.04
MAINTAINER zq
ENV TZ=Asia/Shanghai
ENV DEBIAN_FRONTEND=noninteractive

ADD binwalk /root/binwalk
ADD yaffshiv /root/yaffshiv
ADD sasquatch /root/sasquatch
ADD jefferson /root/jefferson
ADD cramfs-tools /root/cramfs-tools
ADD ubi_reader /root/ubi_reader
ADD firmadyne /root/firmadyne
ADD firmware-analysis-toolkit /root/firmware-analysis-toolkit

RUN sed -i 's/\:\/\/archive\.ubuntu\.com/\:\/\/mirrors\.tuna\.tsinghua\.edu\.cn/g' /etc/apt/sources.list
RUN apt update \
    && apt -y dist-upgrade  \
    && apt -y install curl openssh-server build-essential iptables sudo locales vim tzdata \
    && locale-gen zh_CN.UTF-8 
	
# FAT依赖项
RUN sudo apt install -y python3-pip python3-pexpect busybox-static fakeroot git dmsetup kpartx netcat-openbsd nmap python3-psycopg2 snmp uml-utilities util-linux vlan qemu-system-arm qemu-system-mips qemu-system-x86 qemu-utils wget tar vim unzip
# 更新pip
RUN pip3 install --no-cache-dir -i https://pypi.tuna.tsinghua.edu.cn/simple --upgrade pip
	
# binwalk依赖项
RUN apt install -y locales build-essential libqt4-opengl mtd-utils gzip bzip2 tar arj lhasa p7zip p7zip-full cabextract cramfsswap squashfs-tools zlib1g-dev liblzma-dev liblzo2-dev sleuthkit default-jdk lzop srecord cpio
# binwalk及依赖包安装
RUN pip3 install --no-cache-dir -i https://pypi.tuna.tsinghua.edu.cn/simple setuptools matplotlib capstone pycryptodome gnupg tk \
	# yaffshiv
	&& cd /root/yaffshiv && python3 ./setup.py install && rm -rf /root/yaffshiv \
    # sasquatch
    && cd /root/sasquatch && ./build.sh && rm -rf /root/sasquatch \
    # jefferson
    && cd /root/jefferson && python3 -mpip install -r requirements.txt && python3 ./setup.py install && rm -rf /root/jefferson \
    # cramfs-tools
    && cd /root/cramfs-tools && make && install mkcramfs /usr/local/bin &&  install cramfsck /usr/local/bin && rm -rf /root/cramfs-tools \
    # ubi_reader
    && cd /root/ubi_reader && python3 ./setup.py install && rm -rf /root/ubi_reader \
    # binwalk
    && cd  /root/binwalk && python3 ./setup.py install
	
RUN sudo -H pip3 install --no-cache-dir -i https://pypi.tuna.tsinghua.edu.cn/simple python-magic jefferson \
    # root ssh
    && echo "PermitRootLogin yes" >> /etc/ssh/sshd_config && echo "root:root" | chpasswd \
    # iptables
    && echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf

# Create firmadyne user
RUN useradd -m firmadyne
RUN echo "firmadyne:firmadyne" | chpasswd && adduser firmadyne sudo

# postgresql安装
RUN sudo apt-get install -y postgresql \
	&& sudo service postgresql start \
	&& sudo -u postgres psql -c "create role firmadyne with login password 'firmadyne';" \
	&& sudo -u postgres createdb -O firmadyne firmware \
	&& sudo -u postgres psql -d firmware < /root/firmadyne/database/schema \
	&& echo "ALTER USER firmadyne PASSWORD 'firmadyne'" | sudo -u postgres psql
	
# Firmadyne安装
# ./download.sh中Downloading binaries已存放在firmadyne/binaries/目录下
# Set FIRMWARE_DIR in firmadyne.config
RUN sed -i "/FIRMWARE_DIR=/c\FIRMWARE_DIR=/root/firmadyne" /root/firmadyne/firmadyne.config
# Change interpreter to python3
RUN sed -i 's/env python/env python3/' /root/firmadyne/sources/extractor/extractor.py  /root/firmadyne/scripts/makeNetwork.py
# Set firmadyne_path in fat.config
RUN sed -i "/firmadyne_path=/c\firmadyne_path=/root/firmadyne" /root/firmware-analysis-toolkit/fat.config
RUN sed -i "/sudo_password=/c\sudo_password=firmadyne" /root/firmware-analysis-toolkit/fat.config
# qemu-builds目录下存放不同版本（2.0.0、2.5.0、3.0.0）的qemu-system-static

RUN echo "Firmware Analysis Toolkit installed successfully!"

	
# clean
RUN apt -y autoremove \
    && rm -rf /var/cache/apk/* \
    && rm -rf /var/lib/apt/lists/*

ENV LANG zh_CN.UTF-8
ENV LANGUAGE zh_CN.UTF-8
ENV LC_ALL zh_CN.UTF-8
ENV USER root
ENV IS_VIRTUAL 1

WORKDIR /root/firmware-analysis-toolkit