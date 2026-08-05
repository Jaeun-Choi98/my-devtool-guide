#!/bin/bash
set -e

ssh-keygen -A          # ssh host key 없으면 생성
service ssh start
#service vsftpd start

exec "$@"
