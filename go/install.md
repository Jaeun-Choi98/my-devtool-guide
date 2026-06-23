# Go 설치 가이드 (Linux)

## 환경 변수 정리

| 변수 | 설명 |
|------|------|
| `GOROOT` | Go가 설치된 경로 (tar로 설치 시 보통 `/usr/local/go`) |
| `GOPATH` | 설치된 패키지가 저장되는 위치 |
| `PATH` | `go`, `gofmt` 등 실행 파일이 있는 디렉토리 |

## 환경 변수 파일

| 파일 | 적용 범위 |
|------|-----------|
| `/etc/profile` | 모든 사용자 공통 설정 |
| `~/.profile` | 로그인할 때마다 로드 |
| `~/.bash_profile` | bash로 로그인할 때만 실행 |
| `~/.bashrc` | 인터랙티브 셸(터미널) 시작 시 실행 |

---

## tar.gz 파일로 수동 설치 (권장)

### 삭제 방법

```bash
sudo rm -rf /usr/local/go
```

### 설치 방법 (e.g. go1.22.0)

```bash
# 1. 원하는 버전 다운로드
wget https://go.dev/dl/go1.22.0.linux-amd64.tar.gz

# 2. 압축 해제
sudo tar -C /usr/local -xzf go1.22.0.linux-amd64.tar.gz

# 3. 환경 변수 설정
sudo vim ~/.profile
```

```bash
export GOROOT=/usr/local/go
export PATH=$PATH:$GOROOT/bin
export GOPATH=$HOME/go-pkg   # 패키지 저장 위치 (사용자가 직접 생성 필요)
```

```bash
# 4. 적용
source ~/.profile
```

---

## 여러 Go 버전 관리

`/usr/local/go1.22`, `/usr/local/go1.20` 처럼 버전별로 설치해두고 환경 변수만 바꿔서 사용

```bash
# 1. 원하는 버전 다운로드 후 압축 해제
sudo tar -xzf go1.22.0.linux-amd64.tar.gz -C /usr/local/
sudo mv /usr/local/go /usr/local/go1.22

# 2. ~/.profile 수정
```

```bash
# 이전 GOROOT 경로를 PATH에서 제거한 다음
PATH=$(echo "$PATH" | tr ':' '\n' | grep -v '/usr/local/go' | tr '\n' ':' | sed 's/:$//')

# 새 GOROOT 설정 (버전을 바꾸려면 go1.22 → go1.20 등으로 변경)
export GOROOT=/usr/local/go1.22
export PATH=$GOROOT/bin:$PATH
```

```bash
# 3. 적용
source ~/.profile
```
