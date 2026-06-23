# DevTool Guide

개발 환경 구축 및 인프라 설정 가이드 모음

## 구조

```
db/                         # 데이터베이스
├── permission.md               권한 관리 (MySQL/MariaDB, Oracle)
├── dump.md                     Export / Import
├── mariadb/
│   └── install.md              MariaDB 설치 및 설정
├── oracle/
│   ├── server-install.md       Oracle 서버 설치 (Ubuntu)
│   └── client-install.md       Oracle Instant Client 설치
└── tibero/
    ├── client-linux.md         Tibero Client 설치 (Linux)
    ├── client-windows.md       Tibero Client 설치 (Windows)
    └── unixodbc.md             unixODBC 설정

docker/                     # Docker
├── install.md                  Docker 설치 (Ubuntu, RHEL/CentOS)
├── db.md                       DB 컨테이너 실행 (MySQL, MariaDB, Oracle)
├── registry.md                 사설 Registry 구축 (SSL)
└── monitoring.md               컨테이너 모니터링 (cAdvisor)

jenkins/                    # Jenkins
├── install.md                  Jenkins 설치 (Ubuntu) + GitLab 트리거
└── docker.md                   Docker로 Jenkins 실행

nginx/                      # Nginx
├── install.md                  Nginx 파일 서버 (Ubuntu)
└── docker.md                   Docker로 Nginx 파일 서버

rabbitmq/                   # RabbitMQ
├── install.md                  RabbitMQ 설치 (Ubuntu)
└── docker.md                   Docker로 RabbitMQ 실행

redis/                      # Redis
└── install.md                  Redis 설치 (Ubuntu, Docker)

dnsmasq/                    # DNS
└── install.md                  dnsmasq 설치 및 설정

go/                         # Go
└── install.md                  Go 설치 및 버전 관리 (Linux)

linux/                      # Linux 시스템
├── ubuntu-server-install.md    Ubuntu 서버 설치 (Dell RAID 포함)
├── initial-setup.md            초기 설정 (계정, Samba, FTP, NTP 등)
├── disk.md                     디스크 파티션 및 마운트
├── network.md                  네트워크 설정 (Netplan)
└── systemd-service.md          systemd 서비스 등록
```
