# Docker 모니터링 가이드 (cAdvisor)

## cAdvisor 컨테이너 실행

```bash
sudo docker run \
  --volume=/:/rootfs:ro \
  --volume=/var/run:/var/run:ro \
  --volume=/sys:/sys:ro \
  --volume=/var/lib/docker/:/var/lib/docker:ro \
  --volume=/dev/disk/:/dev/disk:ro \
  --volume=/sys/fs/cgroup:/sys/fs/cgroup:ro \
  --publish=8000:8080 \
  --detach=true \
  --name=cadvisor \
  --privileged \
  gcr.io/cadvisor/cadvisor:latest
```

---

## 모니터링 지표 해석

### Memory

1. 메모리 사용량이 **계단식으로 상승**한다면 메모리 누수를 확인해야 함
2. **Total** = 사용 중인 메모리 + 캐시 + 버퍼 등 / **Hot** = 최근에 접근되고 활발히 사용된 메모리
   - Hot 메모리가 높다 → 프로그램이 많은 메모리를 활발히 사용 중
   - Total은 높지만 Hot이 낮다 → 캐시나 비활성 메모리가 많음
3. 메모리 누수 관점에서는 **Hot 메모리의 지속적 증가가 더 심각한 신호**
   - Total만 증가하고 Hot이 안정적이면 캐시 문제일 가능성이 높음
   - Hot도 같이 증가하면 실제 메모리 누수

### CPU

1. 사용량의 비율을 나타냄
2. **Usage Breakdown:**
   - **User space**: 애플리케이션 코드 실행 시간 (비즈니스 로직, 데이터 처리, 계산 작업, 라이브러리 호출)
   - **Kernel space**: 운영체제 커널 처리 시간 (시스템 콜, 네트워크 I/O, 파일 I/O)
