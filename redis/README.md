# Redis

Redis는 오픈소스 인메모리 데이터 구조 저장소입니다. 데이터베이스, 캐시, 메시지 브로커로 사용되며, 문자열, 해시, 리스트, 집합 등 다양한 데이터 구조를 지원합니다.

## 개요

- **공식 사이트**: https://redis.io
- **Docker Hub**:
  - 공식: https://hub.docker.com/_/redis
  - Bitnami: https://hub.docker.com/r/bitnami/redis
  - GitHub: https://github.com/bitnami/bitnami-docker-redis
- **기본 포트**: 6379
- **프로토콜**: Redis Serialization Protocol (RESP)

## 설정 파일

이 프로젝트는 3가지 Redis 설정을 제공합니다:

### 1. dc-bitnami-single.yml (권장)

단일 Redis 인스턴스 with TLS/SSL 지원

**기본 포트**: 6003

### 2. dc-bitnami-sentinel.yml

Redis Sentinel을 사용한 고가용성 구성

### 3. dc-bitnami-slave.yml

Master-Slave 복제 구성

## 빠른 시작

### 단일 인스턴스 (TLS 지원)

```bash
# 서비스 시작
cd redis
docker-compose -f dc-bitnami-single.yml up -d

# 연결 테스트 (비밀번호 필요)
docker-compose -f dc-bitnami-single.yml exec redis3 redis-cli -a password ping
# 응답: PONG
```

### 헬퍼 스크립트 사용

```bash
./scripts/start.sh redis -f dc-bitnami-single.yml
./scripts/stop.sh redis -f dc-bitnami-single.yml
```

## 환경 변수

### Bitnami Redis

| 변수명 | 기본값 | 설명 |
|--------|--------|------|
| REDIS_PASSWORD | password | Redis 비밀번호 |
| ALLOW_EMPTY_PASSWORD | yes | 빈 비밀번호 허용 (비권장) |
| DISABLE_COMMANDS | - | 비활성화할 명령어 (예: FLUSHDB,FLUSHALL) |
| REDIS_TLS_ENABLED | yes | TLS/SSL 활성화 |
| REDIS_TLS_CERT_FILE | - | TLS 인증서 파일 경로 |
| REDIS_TLS_KEY_FILE | - | TLS 키 파일 경로 |
| REDIS_TLS_CA_FILE | - | TLS CA 파일 경로 |

## 볼륨

- `db_data`: Redis 데이터 (`/bitnami/redis/data`)
- `./certs`: TLS/SSL 인증서 (`/opt/bitnami/redis/certs`)

**중요 경로**:
```
/bitnami/redis/data                # Redis 데이터 파일
/opt/bitnami/redis/certs           # TLS 인증서 (TLS 사용 시)
/opt/bitnami/redis/mounted-etc     # Redis 설정 파일
```

## TLS/SSL 인증서 생성

### OpenSSL로 자체 서명 인증서 생성

```bash
# Redis 디렉토리로 이동
cd redis

# 인증서 디렉토리 생성
mkdir -p certs
cd certs

# 1. CA 개인 키 생성
openssl genrsa -out rootCA.key 4096

# 2. CA 인증서 생성 (10년 유효)
openssl req -x509 -new -nodes -key rootCA.key -sha256 -days 3650 -out rootCA.crt \
    -subj "/C=KR/ST=Seoul/L=Seoul/O=Test/CN=Redis CA"

# 3. Redis 서버 개인 키 생성
openssl genrsa -out redis.key 2048

# 4. CSR (Certificate Signing Request) 생성
openssl req -new -key redis.key -out redis.csr \
    -subj "/C=KR/ST=Seoul/L=Seoul/O=Test/CN=redis"

# 5. 서버 인증서 생성 (CA로 서명)
openssl x509 -req -in redis.csr -CA rootCA.crt -CAkey rootCA.key -CAcreateserial \
    -out redis.crt -days 3650 -sha256

# 6. 권한 설정 (Redis는 UID 1001로 실행)
chown 1001:1001 -R .

# 7. 정리
rm redis.csr rootCA.srl
```

### 인증서 파일 설명

- **rootCA.crt**: CA 인증서 (클라이언트 검증용)
- **redis.crt**: Redis 서버 인증서
- **redis.key**: Redis 서버 개인 키

## 사용 예제

### Redis CLI 접속

```bash
# 비TLS 연결 (비밀번호 사용)
docker-compose -f dc-bitnami-single.yml exec redis3 redis-cli -a password

# TLS 연결
docker-compose -f dc-bitnami-single.yml exec redis3 redis-cli \
    --tls \
    --cert /opt/bitnami/redis/certs/redis.crt \
    --key /opt/bitnami/redis/certs/redis.key \
    --cacert /opt/bitnami/redis/certs/rootCA.crt \
    -a password
```

### 기본 Redis 명령어

```bash
# 컨테이너 내부 접속
docker-compose -f dc-bitnami-single.yml exec redis3 redis-cli -a password

# 문자열 저장/조회
SET mykey "Hello World"
GET mykey

# 해시 저장/조회
HSET user:1000 name "John Doe"
HSET user:1000 email "john@example.com"
HGETALL user:1000

# 리스트 저장/조회
LPUSH mylist "item1"
LPUSH mylist "item2"
LRANGE mylist 0 -1

# TTL 설정
SETEX session:abc 3600 "session data"
TTL session:abc

# 키 삭제
DEL mykey

# 모든 키 조회 (프로덕션에서 주의!)
KEYS *
```

### 백업

```bash
# RDB 스냅샷 강제 생성
docker-compose -f dc-bitnami-single.yml exec redis3 redis-cli -a password BGSAVE

# 데이터 파일 복사
docker cp redis_redis3_1:/bitnami/redis/data/dump.rdb ./redis-backup.rdb
```

### 복원

```bash
# 1. Redis 중지
docker-compose -f dc-bitnami-single.yml stop redis3

# 2. 백업 파일 복사
docker cp ./redis-backup.rdb redis_redis3_1:/bitnami/redis/data/dump.rdb

# 3. 권한 수정
docker-compose -f dc-bitnami-single.yml run --rm redis3 chown 1001:1001 /bitnami/redis/data/dump.rdb

# 4. Redis 시작
docker-compose -f dc-bitnami-single.yml start redis3
```

### 모니터링

```bash
# 실시간 명령어 모니터링
docker-compose -f dc-bitnami-single.yml exec redis3 redis-cli -a password MONITOR

# 서버 정보 확인
docker-compose -f dc-bitnami-single.yml exec redis3 redis-cli -a password INFO

# 메모리 사용량
docker-compose -f dc-bitnami-single.yml exec redis3 redis-cli -a password INFO memory

# 연결된 클라이언트 수
docker-compose -f dc-bitnami-single.yml exec redis3 redis-cli -a password CLIENT LIST

# 느린 쿼리 로그
docker-compose -f dc-bitnami-single.yml exec redis3 redis-cli -a password SLOWLOG GET 10
```

## 고가용성 구성

### Redis Sentinel

```bash
# Sentinel 설정으로 시작
docker-compose -f dc-bitnami-sentinel.yml up -d

# Sentinel 상태 확인
docker-compose -f dc-bitnami-sentinel.yml exec redis-sentinel redis-cli -p 26379 SENTINEL masters
```

### Master-Slave 복제

```bash
# Slave 노드 시작
docker-compose -f dc-bitnami-slave.yml up -d

# 복제 상태 확인
docker-compose -f dc-bitnami-slave.yml exec redis-master redis-cli -a password INFO replication
docker-compose -f dc-bitnami-slave.yml exec redis-slave redis-cli -a password INFO replication
```

## 프로그래밍 언어별 연결

### Python (redis-py)

```python
import redis

# 기본 연결
r = redis.Redis(
    host='localhost',
    port=6003,
    password='password',
    decode_responses=True
)

# TLS 연결
r = redis.Redis(
    host='localhost',
    port=6003,
    password='password',
    ssl=True,
    ssl_cert_reqs='required',
    ssl_ca_certs='/path/to/rootCA.crt',
    decode_responses=True
)

# 사용 예제
r.set('mykey', 'value')
print(r.get('mykey'))
```

### Node.js (ioredis)

```javascript
const Redis = require('ioredis');

// 기본 연결
const redis = new Redis({
  host: 'localhost',
  port: 6003,
  password: 'password'
});

// TLS 연결
const redis = new Redis({
  host: 'localhost',
  port: 6003,
  password: 'password',
  tls: {
    ca: fs.readFileSync('/path/to/rootCA.crt')
  }
});

// 사용 예제
await redis.set('mykey', 'value');
const value = await redis.get('mykey');
console.log(value);
```

### PHP (phpredis)

```php
<?php
$redis = new Redis();

// 기본 연결
$redis->connect('localhost', 6003);
$redis->auth('password');

// 사용 예제
$redis->set('mykey', 'value');
echo $redis->get('mykey');
?>
```

## 성능 최적화

### 1. 메모리 관리

```bash
# maxmemory 설정
docker-compose -f dc-bitnami-single.yml exec redis3 redis-cli -a password CONFIG SET maxmemory 2gb

# 메모리 정책 설정 (LRU)
docker-compose -f dc-bitnami-single.yml exec redis3 redis-cli -a password CONFIG SET maxmemory-policy allkeys-lru
```

### 2. 영속성 설정

```bash
# RDB 스냅샷 설정 (900초마다 1개 이상 키 변경 시)
CONFIG SET save "900 1 300 10 60 10000"

# AOF (Append-Only File) 활성화
CONFIG SET appendonly yes
CONFIG SET appendfsync everysec
```

### 3. 파이프라이닝

대량 작업 시 파이프라이닝 사용으로 성능 향상

## 보안 설정

### 1. 비밀번호 변경

```yaml
environment:
  - REDIS_PASSWORD=very_secure_password_here
```

### 2. 위험한 명령어 비활성화

```yaml
environment:
  - DISABLE_COMMANDS=FLUSHDB,FLUSHALL,KEYS,CONFIG
```

### 3. TLS/SSL 활성화

이미 `dc-bitnami-single.yml`에 설정되어 있습니다.

### 4. 네트워크 격리

```yaml
# docker-compose.yml
networks:
  redis-network:
    driver: bridge
    internal: true
```

## 알려진 이슈

### 1. 메모리 부족

**문제**: "OOM command not allowed when used memory" 오류

**해결**:
```bash
# maxmemory 증가
docker-compose -f dc-bitnami-single.yml exec redis3 redis-cli -a password CONFIG SET maxmemory 4gb
```

### 2. TLS 인증서 권한 오류

**문제**: "Permission denied" for certificate files

**해결**:
```bash
cd certs
chown 1001:1001 -R .
chmod 600 redis.key
```

### 3. 연결 거부

**문제**: "Connection refused"

**해결**:
```bash
# Redis 컨테이너 상태 확인
docker-compose -f dc-bitnami-single.yml ps

# 로그 확인
docker-compose -f dc-bitnami-single.yml logs redis3
```

## 참고 링크

- **공식 문서**: https://redis.io/documentation
- **Commands Reference**: https://redis.io/commands
- **Bitnami Redis**: https://github.com/bitnami/bitnami-docker-redis
- **Redis Sentinel**: https://redis.io/topics/sentinel
- **TLS Support**: https://redis.io/topics/encryption
- **Security**: https://redis.io/topics/security

## 프로덕션 체크리스트

- [ ] 강력한 비밀번호 설정
- [ ] TLS/SSL 활성화
- [ ] 위험한 명령어 비활성화 (FLUSHDB, FLUSHALL, KEYS 등)
- [ ] maxmemory 및 eviction 정책 설정
- [ ] 정기 백업 (RDB 또는 AOF)
- [ ] 모니터링 설정 (메모리, 연결 수, 느린 쿼리)
- [ ] Redis Sentinel 또는 Cluster 구성 (고가용성)
- [ ] 네트워크 격리 (외부 접근 차단)
- [ ] 로그 로테이션 설정
- [ ] 메모리 스왑 비활성화 (성능)

## 클러스터 구성

Redis Cluster는 수평 확장과 고가용성을 제공합니다:

```yaml
# redis-cluster.yml 예제
version: '3.7'
services:
  redis-node-1:
    image: bitnami/redis-cluster
    environment:
      - REDIS_PASSWORD=password
      - REDIS_NODES=redis-node-1 redis-node-2 redis-node-3
  redis-node-2:
    image: bitnami/redis-cluster
    # ...
  redis-node-3:
    image: bitnami/redis-cluster
    # ...
```

---

**도움이 필요하신가요?** 프로젝트 루트의 [CONTRIBUTING.md](../CONTRIBUTING.md)를 참조하거나 Issue를 열어주세요.
