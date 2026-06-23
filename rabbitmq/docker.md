# Docker RabbitMQ 실행 가이드

## 컨테이너 실행

```bash
sudo docker run -d \
  --name rabbitmq \
  --hostname rabbitmq \
  -p 5672:5672 \
  -p 15672:15672 \
  -e RABBITMQ_DEFAULT_USER=admin \
  -e RABBITMQ_DEFAULT_PASS=admin \
  --ulimit nofile=64000:64000 \
  -v rabbitmq-data:/var/lib/rabbitmq \
  -v rabbitmq-log:/var/log/rabbitmq \
  rabbitmq:3-management
```
