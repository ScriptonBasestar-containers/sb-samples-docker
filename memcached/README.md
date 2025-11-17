# Memcached

Memcached는 고성능 분산 메모리 캐싱 시스템입니다. 데이터베이스 부하를 줄이고 동적 웹 애플리케이션의 속도를 향상시킵니다.

## 개요

- **공식 사이트**: https://memcached.org
- **Docker Hub**:
  - 공식: https://hub.docker.com/_/memcached
  - Bitnami: https://hub.docker.com/r/bitnami/memcached
  - Sameersbn: https://hub.docker.com/r/sameersbn/memcached
- **기본 포트**: 11211
- **프로토콜**: Memcache 텍스트 및 바이너리 프로토콜

## 이미지 비교

이 프로젝트는 3가지 Memcached 이미지를 제공합니다:

### 1. 공식 이미지 (memcached)

**포트**: 11211

**장점**:
- 공식 이미지
- 가볍고 빠름
- 설정 간단

**단점**:
- SASL 인증 설정 복잡

### 2. Bitnami 이미지

**포트**: 11212

**장점**:
- SASL 인증 내장
- 환경 변수로 쉬운 설정
- 정기 업데이트

**단점**:
- 이미지 크기 상대적으로 큼

### 3. Sameersbn 이미지

**포트**: 11213

**장점**:
- 커뮤니티 지원
- 간단한 설정

**단점**:
- 업데이트 빈도 낮음

## 빠른 시작

```bash
# 서비스 시작 (3개 이미지 모두)
cd memcached
docker-compose up -d

# 개별 이미지만 시작
docker-compose up -d memcached          # 공식 이미지만
docker-compose up -d bitnami-memcached  # Bitnami만
docker-compose up -d sameersbn-memcached # Sameersbn만
```

### 헬퍼 스크립트 사용

```bash
./scripts/start.sh memcached
./scripts/stop.sh memcached
```

## 포트

| 포트 | 이미지 | 설명 |
|------|--------|------|
| 11211 | 공식 memcached | 표준 Memcached 포트 |
| 11212 | Bitnami | Bitnami 이미지 포트 |
| 11213 | Sameersbn | Sameersbn 이미지 포트 |

## 볼륨

### 공식 이미지

```
/etc/sysconfig/memcached  # 설정 파일
```

### Bitnami 이미지

```
/opt/bitnami/memcached/conf/memcachedsasldb  # SASL 데이터베이스
```

**참고**: Memcached는 인메모리 캐시이므로 영구 저장소가 필요 없습니다. 재시작 시 모든 데이터가 손실됩니다.

## 사용 예제

### Telnet으로 연결

```bash
# 공식 이미지
telnet localhost 11211

# 데이터 저장
set mykey 0 0 5
hello
STORED

# 데이터 조회
get mykey
VALUE mykey 0 5
hello
END

# 통계 확인
stats
```

### netcat으로 연결

```bash
# 키 설정
echo -e "set testkey 0 0 10\r\nhello world\r\nquit" | nc localhost 11211

# 키 조회
echo -e "get testkey\r\nquit" | nc localhost 11211
```

### Python에서 사용 (pymemcache)

```python
from pymemcache.client import base

# 연결
client = base.Client(('localhost', 11211))

# 데이터 저장
client.set('mykey', 'myvalue')

# 데이터 조회
result = client.get('mykey')
print(result)  # b'myvalue'

# 데이터 삭제
client.delete('mykey')

# 통계
stats = client.stats()
print(stats)
```

### Node.js에서 사용 (memjs)

```javascript
const memjs = require('memjs');

// 연결
const client = memjs.Client.create('localhost:11211');

// 데이터 저장
client.set('mykey', 'myvalue', {}, (err, val) => {
  if (err) console.error(err);
});

// 데이터 조회
client.get('mykey', (err, val) => {
  if (err) console.error(err);
  console.log(val.toString());  // myvalue
});

// 데이터 삭제
client.delete('mykey', (err, success) => {
  if (err) console.error(err);
});
```

### PHP에서 사용 (php-memcached)

```php
<?php
// 연결
$memcached = new Memcached();
$memcached->addServer('localhost', 11211);

// 데이터 저장
$memcached->set('mykey', 'myvalue', 3600);

// 데이터 조회
$result = $memcached->get('mykey');
echo $result;  // myvalue

// 데이터 삭제
$memcached->delete('mykey');

// 통계
$stats = $memcached->getStats();
print_r($stats);
?>
```

## 모니터링

### 통계 확인

```bash
# 전체 통계
echo -e "stats\r\nquit" | nc localhost 11211

# 특정 통계
echo -e "stats items\r\nquit" | nc localhost 11211
echo -e "stats slabs\r\nquit" | nc localhost 11211

# 캐시 히트율 계산
echo -e "stats\r\nquit" | nc localhost 11211 | grep -E "cmd_get|get_hits|get_misses"
```

### 주요 메트릭

- **cmd_get**: GET 요청 수
- **cmd_set**: SET 요청 수
- **get_hits**: 캐시 히트 수
- **get_misses**: 캐시 미스 수
- **evictions**: 메모리 부족으로 삭제된 항목 수
- **curr_connections**: 현재 연결 수
- **bytes_read**: 읽은 바이트 수
- **bytes_written**: 쓴 바이트 수

### 캐시 히트율 계산

```
히트율 = get_hits / (get_hits + get_misses) * 100
```

## 성능 튜닝

### 메모리 크기 조정

```yaml
# docker-compose.yml
services:
  memcached:
    image: memcached
    command: memcached -m 512  # 512MB 할당
```

### 최대 연결 수 조정

```yaml
command: memcached -m 512 -c 1024  # 1024 동시 연결
```

### 스레드 수 조정

```yaml
command: memcached -m 512 -c 1024 -t 4  # 4개 스레드
```

### 최대 아이템 크기 조정

```yaml
command: memcached -m 512 -I 4m  # 최대 4MB 아이템
```

### 전체 설정 예제

```yaml
services:
  memcached:
    image: memcached:alpine
    ports:
      - 11211:11211
    command: >
      memcached
      -m 1024
      -c 2048
      -t 8
      -I 5m
      -v
```

**옵션 설명**:
- `-m 1024`: 1GB 메모리
- `-c 2048`: 최대 2048 동시 연결
- `-t 8`: 8개 스레드
- `-I 5m`: 최대 아이템 크기 5MB
- `-v`: 상세 로그

## SASL 인증 (Bitnami)

Bitnami 이미지는 SASL 인증을 지원합니다:

```yaml
bitnami-memcached:
  image: bitnami/memcached
  environment:
    - MEMCACHED_USERNAME=user
    - MEMCACHED_PASSWORD=password
```

### Python에서 SASL 연결

```python
from pymemcache.client.base import Client

client = Client(
    ('localhost', 11212),
    username='user',
    password='password'
)

client.set('key', 'value')
```

## 캐시 전략

### 1. Cache-Aside (Lazy Loading)

애플리케이션이 캐시를 직접 관리:

```python
def get_user(user_id):
    # 캐시 확인
    user = cache.get(f'user:{user_id}')
    if user:
        return user

    # DB에서 조회
    user = db.query(f"SELECT * FROM users WHERE id={user_id}")

    # 캐시에 저장
    cache.set(f'user:{user_id}', user, ttl=3600)
    return user
```

### 2. Write-Through

데이터 쓰기 시 캐시와 DB 동시 업데이트:

```python
def update_user(user_id, data):
    # DB 업데이트
    db.update(f"users", user_id, data)

    # 캐시 업데이트
    cache.set(f'user:{user_id}', data, ttl=3600)
```

### 3. Write-Behind (Write-Back)

캐시에 먼저 쓰고 나중에 DB 업데이트:

```python
def update_user(user_id, data):
    # 캐시에 쓰기
    cache.set(f'user:{user_id}', data, ttl=3600)

    # 비동기로 DB 업데이트 (큐 사용)
    queue.enqueue(db.update, "users", user_id, data)
```

## 일반적인 사용 사례

### 1. 세션 저장소

```python
# 세션 저장
session_id = "abc123"
session_data = {"user_id": 1, "username": "john"}
cache.set(f'session:{session_id}', json.dumps(session_data), ttl=3600)

# 세션 조회
session_json = cache.get(f'session:{session_id}')
session_data = json.loads(session_json)
```

### 2. 쿼리 결과 캐싱

```python
# 쿼리 결과 캐싱
cache_key = "top_products"
products = cache.get(cache_key)
if not products:
    products = db.query("SELECT * FROM products ORDER BY sales DESC LIMIT 10")
    cache.set(cache_key, products, ttl=300)  # 5분
```

### 3. API 응답 캐싱

```python
# API 응답 캐싱
cache_key = f'api:weather:{city}'
response = cache.get(cache_key)
if not response:
    response = requests.get(f'https://api.weather.com/{city}').json()
    cache.set(cache_key, json.dumps(response), ttl=600)  # 10분
```

## 알려진 이슈

### 1. 메모리 부족

**문제**: Evictions가 너무 많이 발생

**해결**: 메모리 크기 증가
```yaml
command: memcached -m 2048  # 2GB로 증가
```

### 2. 연결 수 초과

**문제**: "Too many open files" 오류

**해결**: 최대 연결 수 증가
```yaml
command: memcached -c 4096
```

### 3. 아이템 크기 제한

**문제**: "object too large for cache" 오류

**해결**: 최대 아이템 크기 증가
```yaml
command: memcached -I 10m  # 10MB
```

## 보안 고려사항

### 1. 외부 접근 차단

```yaml
# 로컬호스트만 접근
ports:
  - 127.0.0.1:11211:11211
```

### 2. 방화벽 설정

프로덕션 환경에서는 방화벽으로 접근 제한

### 3. SASL 인증 사용

Bitnami 이미지로 인증 활성화

## 참고 링크

- **공식 사이트**: https://memcached.org
- **문서**: https://github.com/memcached/memcached/wiki
- **Protocol**: https://github.com/memcached/memcached/blob/master/doc/protocol.txt
- **Bitnami Memcached**: https://github.com/bitnami/bitnami-docker-memcached

## 프로덕션 체크리스트

- [ ] 적절한 메모리 크기 설정 (-m)
- [ ] 최대 연결 수 설정 (-c)
- [ ] 외부 접근 제한 (방화벽 또는 127.0.0.1 바인딩)
- [ ] SASL 인증 활성화 (민감한 데이터 시)
- [ ] 모니터링 설정 (히트율, evictions)
- [ ] 캐시 키 네이밍 규칙 정의
- [ ] TTL 전략 수립
- [ ] 백업 계획 (없음 - 캐시는 휘발성)
- [ ] Failover 전략 (여러 인스턴스 사용 고려)

## Memcached vs Redis

| 기능 | Memcached | Redis |
|------|-----------|-------|
| 데이터 구조 | 문자열만 | 문자열, 리스트, 집합, 해시 등 |
| 영속성 | 없음 | RDB, AOF 지원 |
| 복제 | 없음 (클라이언트 샤딩) | Master-Slave, Cluster |
| 트랜잭션 | 없음 | 지원 |
| Pub/Sub | 없음 | 지원 |
| Lua 스크립팅 | 없음 | 지원 |
| 메모리 효율 | 높음 | 중간 |
| 단순 캐싱 성능 | 매우 빠름 | 빠름 |
| 사용 사례 | 단순 키-값 캐싱 | 복잡한 데이터 구조, 세션, 큐 |

**권장**:
- **단순 캐싱만 필요**: Memcached
- **복잡한 데이터 구조 필요**: Redis
- **영속성 필요**: Redis
- **Pub/Sub 필요**: Redis

---

**도움이 필요하신가요?** 프로젝트 루트의 [CONTRIBUTING.md](../CONTRIBUTING.md)를 참조하거나 Issue를 열어주세요.
