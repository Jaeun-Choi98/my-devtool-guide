# 디스크 파티션 및 마운트 가이드

## 장치 확인

```bash
lsblk          # 블록 장치 확인
fdisk -l       # 연결된 모든 디스크 확인
```

---

## OS 설치 시 파티션 설정

### fdisk (MBR 방식)

```bash
sudo fdisk /dev/sdb
```

**fdisk 내부 명령어:**

| 명령 | 설명 |
|------|------|
| `o` | DOS/MBR 파티션 테이블 생성 |
| `n` | 새 파티션 생성 |
| `p` | primary(주) 파티션 선택 |
| `e` | extended(확장) 파티션 선택 |
| `l` | logical(논리) 파티션 선택 |
| `t` | 파티션 타입 변경 |
| `w` | 변경사항 저장 및 종료 |
| `q` | 저장하지 않고 종료 |
| `p` | 현재 파티션 테이블 출력 |

**MBR 예시 (7개 파티션 구성):**

```
o                              # MBR 파티션 테이블 생성

# 1. swap (32GB, 주파티션)
n → p → 1 → Enter → +32G
t → 1 → 82                    # Linux swap 타입

# 2. /boot (1GB, 주파티션)
n → p → 2 → Enter → +1G

# 3. / (root, 200GB, 주파티션)
n → p → 3 → Enter → +200G

# 4. 확장파티션 (나머지 전체)
n → e → 4 → Enter → Enter

# 5-8. 논리파티션들 (확장파티션 내부)
n → Enter → +10G              # /var (논리파티션 5)
n → Enter → +10G              # /tmp (논리파티션 6)
n → Enter → +150G             # /home (논리파티션 7)
n → Enter → Enter             # /data (논리파티션 8, 나머지 전체)

p                              # 파티션 확인
w                              # 저장 및 종료
```

### fdisk (GPT 방식, 권장)

```bash
sudo fdisk /dev/sdb
```

```
g                              # GPT 파티션 테이블 생성

# 1. swap (32GB)
n → 1 → Enter → +32G
t → 1 → 19                    # Linux swap (GPT: 타입 19)

# 2. /boot (1GB)
n → 2 → Enter → +1G

# 3. /var (10GB)
n → 3 → Enter → +10G

# 4. /tmp (10GB)
n → 4 → Enter → +10G

# 5. / (root, 200GB)
n → 5 → Enter → +200G

# 6. /home (150GB)
n → 6 → Enter → +150G

# 7. /data (나머지 전체)
n → 7 → Enter → Enter

p                              # 파티션 확인
w                              # 저장 및 종료
```

**주요 파티션 타입 코드:**

| 방식 | swap | Linux filesystem |
|------|------|-----------------|
| MBR (DOS) | 82 | 83 (기본값) |
| GPT | 19 | 20 (기본값) |

---

## 스왑 설정

```bash
sudo mkswap /dev/sda1
sudo swapon /dev/sda1
```

## 파일시스템 포맷

```bash
sudo mkfs.ext4 /dev/sda2
sudo mkfs.ext4 /dev/sda3
# ...

# 다른 파일시스템 옵션:
# sudo mkfs.xfs /dev/sdb1
# sudo mkfs.btrfs /dev/sdb1
# sudo mkfs.ntfs /dev/sdb1
```

## 영구 마운트 (/etc/fstab)

```bash
# UUID 확인
blkid

# /etc/fstab 편집
sudo nano /etc/fstab
```

```
UUID=a1b2c3d4-e5f6-7890-abcd-ef1234567890  /boot  ext4  defaults  0 2
UUID=b2c3d4e5-f6g7-8901-bcde-f12345678901  /      ext4  defaults  0 1
```

```bash
# 마운트 확인
df -h
```

---

## VMware 하드디스크 용량 늘리기

- Desktop 

```bash
df -h
sudo apt install gparted
sudo gparted
```

- Server
1. 파티션 확장 (e.g. sda3: 18.2G → 나머지 전부)

```bash
sudo apt install cloud-guest-utils -y
sudo growpart /dev/sda 3
```

2. 확인
   
```bash
lsblk
```
sda3 크기가 약 58G 정도로 늘어났는지 확인.

3. LVM 물리볼륨 확장
   
```bash
sudo pvresize /dev/sda3
```

4. 논리볼륨 확장 (남은 공간 전부)

```bash
sudo lvextend -l +100%FREE /dev/mapper/ubuntu--vg-ubuntu--lv
```

5. 파일시스템 확장

```bash
sudo resize2fs /dev/mapper/ubuntu--vg-ubuntu--lv
```

6. 최종 확인

```bash
df -h /
```

---

## 하드 디스크 추가

### 1. 디스크 인식 확인

```bash
lsblk
fdisk -l
```

### 2. 파일시스템 포맷

```bash
sudo mkfs.ext4 /dev/sdb1
```

### 3. 마운트 포인트 생성

```bash
sudo mkdir /mnt/newdisk
```

### 4. 마운트

**임시 마운트:**

```bash
sudo mount /dev/sdb1 /mnt/newdisk
df -h
lsblk
```

**영구 마운트:**

```bash
# UUID 확인
sudo blkid /dev/sdb1

# /etc/fstab에 추가
sudo nano /etc/fstab
# UUID=[your-uuid-here] /mnt/newdisk ext4 defaults 0 2

# fstab 기반으로 마운트 테스트
sudo mount -a
df -h
```

### 5. 권한 설정

```bash
sudo chown $USER:$USER /mnt/newdisk
sudo chmod 755 /mnt/newdisk
```
