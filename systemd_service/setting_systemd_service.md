# systemd 서비스 등록 가이드

> systemd 서비스는 부팅 시 실행되므로 사용자 로그인 전에 구동된다.
> `~/.profile`, `~/.bash_profile` 등의 환경 변수가 로드되기 전에 실행되므로, 실행할 프로그램(셸 스크립트 포함)에서 명령어를 환경 변수가 아닌 **절대 경로**로 표기해야 한다.

## 1. 서비스 파일 작성

```bash
sudo vim /etc/systemd/system/my_logger.service
```

```ini
[Unit]
Description=My Go Logger Service
After=network.target

[Service]
ExecStart=/path/to/my_program
Restart=always                                    # 프로그램이 죽었을 때 자동 재시작
User=myuser
WorkingDirectory=/path/to/
StandardOutput=append:/var/log/my_logger.log
StandardError=append:/var/log/my_logger_error.log

[Install]
WantedBy=multi-user.target
```

## 2. 서비스 등록 및 실행

```bash
sudo systemctl daemon-reload
sudo systemctl enable my_logger.service    # 부팅 시 자동 실행
sudo systemctl start my_logger.service     # 서비스 시작
```

## 3. 실행 상태 확인

```bash
sudo systemctl status my_logger.service
```
