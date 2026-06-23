# Docker DB 컨테이너 실행 가이드

## MySQL / MariaDB

```bash
# MySQL 기본 실행
sudo docker search mysql
sudo docker pull mysql
sudo docker run --name mysql-container \
  -e MYSQL_ROOT_PASSWORD=<password> \
  -d -p 3306:3306 \
  mysql:latest

sudo docker exec -it mysql-container bash
```

### 도커 볼륨을 이용한 설정/데이터 분리

설정 파일은 [MariaDB 설치 가이드](../db/mariadb/mariadb_server_client.md) 참고

```bash
sudo docker run -d --name mariadb11 \
  -e MARIADB_ROOT_PASSWORD='2041' \
  -p 3306:3306 \
  -v /home/juchoi/mariadb/volume-data:/var/lib/mysql \
  -v /home/juchoi/mariadb/volume-config/my.cnf:/etc/mysql/my.cnf \
  mariadb:11.4
```

---

## Oracle

### Oracle 23c Free

```bash
# 23c free 버전은 SID: FREE, SERVICE_NAME: FREE 또는 FREEPDB1 로 고정
docker pull container-registry.oracle.com/database/free:latest

docker run --name ${CONTAINER_NAME} -d \
  -p 1521:1521 \
  -p 5500:5500 \
  -e ORACLE_PWD=${ORACLE_PASSWORD} \
  -e ORACLE_CHARACTERSET=AL32UTF8 \
  container-registry.oracle.com/database/free:latest
```

**Enterprise 버전 추가 옵션:**

```bash
-e ORACLE_SID=ORCLCDB \
-e ORACLE_PDB=ORCLPDB1 \
```

**실행 예시 (복사용):**

```bash
docker run --name my-ora23free -d \
  -p 15210:1521 \
  -p 5500:5500 \
  -e ORACLE_PWD=1234 \
  -e ORACLE_CHARACTERSET=AL32UTF8 \
  container-registry.oracle.com/database/free:latest
```

### CDB / PDB 확인 후 FREEPDB1에 계정 생성

```sql
-- 현재 컨테이너 확인 (CDB 여부)
SELECT name, cdb FROM v$database;

-- 기존 PDB 목록 확인
SELECT pdb_name, status FROM cdb_pdbs;

-- 현재 컨테이너 이름 확인
SHOW con_name;

-- PDB 전환 후 계정 생성
ALTER SESSION SET CONTAINER = FREEPDB1;
CREATE USER ...
```
