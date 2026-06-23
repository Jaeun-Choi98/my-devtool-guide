# Ubuntu 24.04 LTS 서버 설치 가이드
### Dell PowerEdge (PERC H755 RAID 컨트롤러 기준)

---

## 1. 제조사별 BIOS / 부팅 메뉴 진입 키

| 제조사 | 부팅 메뉴 (1회용) | BIOS 진입 | 비고 |
|--------|------------------|-----------|------|
| **Dell** | F12 | F2 | Lifecycle Controller: F10 |
| **HP / HPE** | F9 | F10 | |
| **Lenovo** | F12 | F1 / F2 | |
| **ASUS** | F8 | Del / F2 | |
| **Gigabyte** | F12 | Del | |
| **MSI** | F11 | Del | |
| **ASRock** | F11 | F2 / Del | |
| **SuperMicro** | F11 | Del | |

> **팁:** 부팅 직후 화면 하단에 키 안내가 잠깐 표시되니 놓쳤다면 그 화면 참고

---

## 2. USB 부팅 디스크 준비

### 권장 도구: Rufus

| 항목 | 설정값 |
|------|--------|
| 파티션 구성 | GPT (UEFI 서버) 또는 MBR (Legacy BIOS) |
| 대상 시스템 | UEFI (CSM 없음) |
| 파일 시스템 | FAT32 |

> **주의:** 최신 서버는 대부분 UEFI → GPT 권장  
> UEFI 부팅이 안 되거나 오류 발생 시 MBR로 재시도

### Ubuntu 부팅 메뉴 항목 설명

| 항목 | 설명 |
|------|------|
| Try or Install Ubuntu | 일반 설치 진입 (기본 선택) |
| Ubuntu Server with the HWE kernel | 최신 하드웨어 지원 커널 (신형 서버 권장) |
| Boot from next volume | USB 외 다른 디스크로 부팅 |
| UEFI Firmware Settings | BIOS/UEFI 설정 진입 |

---

## 3. RAID 구성 (Dell PERC H755 기준)

Ubuntu 설치 전 반드시 RAID Virtual Drive를 먼저 생성해야 OS가 디스크를 인식한다.

### 3-1. Lifecycle Controller 진입

1. 서버 전원 ON
2. POST 화면에서 **F10** 키 입력
3. 네트워크 설정 오류(SWC0001) 팝업이 뜨면 **OK** 클릭 (무시해도 됨)

### 3-2. RAID 구성 절차

```
Lifecycle Controller
  └─ Hardware Configuration
       └─ Configuration Wizards
            └─ RAID Configuration
```

**Step 1: Controller 선택**
- RAID Controller: `PERC H755 Front in SL.3` 선택
- RAID Type: Windows RAID 선택 (Linux RAID 선택 불가한 경우 그대로 진행)
- **Next** 클릭

**Step 2: RAID 레벨 선택**

| RAID 레벨 | 특징 | 디스크 2개 기준 |
|-----------|------|----------------|
| RAID 0 | 용량 합산, 백업 없음, 성능 좋음 | 디스크 용량 × 2 |
| RAID 1 | 미러링, 한쪽 고장 시 데이터 보존 | 디스크 용량 × 1 (절반은 백업) |

> 데이터 안전성이 중요하면 **RAID 1**, 용량/성능이 중요하면 **RAID 0**

- 원하는 RAID 레벨 선택 후 **Next**

**Step 3: Physical Disk 선택**
- 사용 가능한 디스크 목록 표시 (예: Physical Disk 0:1:0, 0:1:1)
- **Select All** 체크 → **Next**

**Step 4: Virtual Disk Attributes**
- Virtual Disk Name: 임의 입력 (예: `VD0`)
- 나머지 기본값 유지
- **Next**

**Step 5: Summary 확인 → Finish**

---

## 4. Ubuntu 설치

RAID 구성 완료 후 재부팅 → USB로 부팅

### 설치 중 디스크 인식 확인 (Shell에서)

설치 도중 `Launch a shell` 또는 `Ctrl+Alt+F2`로 쉘 진입 후:

```bash
# 디스크 목록 확인
lsblk

# RAID 컨트롤러 확인
lspci | grep -i raid

# SATA 컨트롤러 확인
lspci | grep -i sata
```

RAID Virtual Drive 생성 후에는 `sda` (또는 `sdb`)로 디스크가 잡혀야 정상

### 주요 설치 단계 요약

1. 언어 선택
2. 네트워크 설정 (설치 후 변경 가능, 스킵 가능)
3. 미러 설정 (Proxy 설정은 선택사항, 국내 서버면 기본값 유지)
4. 디스크 선택 → RAID Virtual Drive 선택
5. 파티션 설정 (자동 권장)
6. 사용자 계정 설정
7. SSH 서버 설치 여부 선택 (서버용이면 체크)
8. 설치 완료 → 재부팅

---

## 5. 트러블슈팅

| 증상 | 원인 | 해결 |
|------|------|------|
| Block probing did not discover any disks | RAID Virtual Drive 미생성 | Lifecycle Controller에서 RAID 구성 먼저 |
| 부팅 메뉴에 USB 없음 | 부팅 순서 문제 | One-shot UEFI Boot Menu에서 USB 선택 |
| SATA 모드 문제 | BIOS에서 RAID 모드로 설정됨 | BIOS → Storage → SATA Mode → AHCI 변경 |
