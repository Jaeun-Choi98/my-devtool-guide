FROM ubuntu:24.04

RUN apt-get update && apt-get install -y \
    sudo build-essential git curl wget vim unzip pkg-config ca-certificates locales \
    openssh-server \
# vsftpd \
    rsync \
    net-tools \
    && rm -rf /var/lib/apt/lists/*

RUN useradd -m -s /bin/bash ju && \
    echo "ju:980324" | chpasswd && \
    usermod -aG sudo ju

# sshd 설정
RUN mkdir -p /var/run/sshd && \
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config

# vsftpd 설정 (익명 접속 막고 로컬 계정 로그인 + 쓰기 허용)
#RUN sed -i 's/anonymous_enable=YES/anonymous_enable=NO/' /etc/vsftpd.conf && \
#    sed -i 's/#write_enable=YES/write_enable=YES/' /etc/vsftpd.conf

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

#EXPOSE 22 21 21100-21110
EXPOSE 22
WORKDIR /home/ju
ENTRYPOINT ["/entrypoint.sh"]
CMD ["bash"]
