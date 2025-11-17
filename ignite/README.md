# Apache Ignite

Apache Ignite는 인메모리 컴퓨팅 플랫폼입니다. 분산 데이터베이스, 캐싱, 스트림 처리, 컴퓨팅 그리드 기능을 통합 제공합니다.

## 개요

- **공식 사이트**: https://ignite.apache.org
- **Docker Hub**: https://hub.docker.com/r/apacheignite/ignite
- **GitHub**: https://github.com/apache/ignite
- **기본 포트**:
  - 11211: Memcache 프로토콜
  - 47500-47509: Discovery 및 통신 포트
- **사용 사례**: 분산 캐시, In-Memory 데이터베이스, 스트림 처리, 분산 컴퓨팅

## 빠른 시작

```bash
# 서비스 시작
cd ignite
docker-compose up -d

# 로그 확인
docker-compose logs -f db
```

### 헬퍼 스크립트 사용

```bash
./scripts/start.sh ignite
./scripts/stop.sh ignite
```

## 환경 변수

| 변수명 | 기본값 | 설명 |
|--------|--------|------|
| IGNITE_WORK_DIR | /persistence | 작업 디렉토리 |
| CONFIG_URI | file:/config/ignite-config.xml | 설정 파일 경로 |
| IGNITE_QUIET | false | Quiet 모드 |
| OPTION_LIBS | - | 추가 라이브러리 (쉼표로 구분) |
| JVM_OPTS | - | JVM 옵션 |

## JVM 옵션 (docker-compose.yml)

```yaml
JVM_OPTS: >
  -server
  -Xms1g
  -Xmx1g
  -XX:NewSize=512m
  -XX:SurvivorRatio=6
  -XX:+AlwaysPreTouch
  -XX:+UseG1GC
  -XX:MaxGCPauseMillis=2000
  -XX:GCTimeRatio=4
  -XX:InitiatingHeapOccupancyPercent=30
  -XX:G1HeapRegionSize=8M
  -XX:ConcGCThreads=2
  -XX:G1HeapWastePercent=10
  -XX:+UseTLAB
  -XX:+ScavengeBeforeFullGC
  -XX:+DisableExplicitGC
```

**옵션 설명**:
- **-Xms1g / -Xmx1g**: 최소/최대 힙 메모리 1GB
- **-XX:+UseG1GC**: G1 가비지 컬렉터 사용
- **-XX:MaxGCPauseMillis=2000**: 최대 GC 일시정지 시간 2초
- **-XX:+DisableExplicitGC**: 명시적 GC 호출 비활성화

## 볼륨

- `persistence-volume`: Ignite 데이터 영속성 (`/persistence`)
- `./config`: 설정 파일 디렉토리 (`/config`)

**중요 경로**:
```
/persistence          # 데이터 영속화 경로
/config               # 설정 파일 (ignite-config.xml)
```

## 포트

| 포트 | 프로토콜 | 설명 |
|------|----------|------|
| 11211 | Memcache | Memcache 클라이언트 연결 |
| 47100 | ThinClient | Thin 클라이언트 연결 |
| 47500-47509 | TCP/IP | Discovery 및 노드간 통신 |
| 10800 | SQL | JDBC/ODBC 연결 |
| 8080 | REST | REST API (선택사항) |

## 설정 파일

`./config/ignite-config.xml`에서 Ignite를 설정합니다:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<beans xmlns="http://www.springframework.org/schema/beans"
       xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
       xsi:schemaLocation="
           http://www.springframework.org/schema/beans
           http://www.springframework.org/schema/beans/spring-beans.xsd">

    <bean class="org.apache.ignite.configuration.IgniteConfiguration">
        <!-- Persistence 활성화 -->
        <property name="dataStorageConfiguration">
            <bean class="org.apache.ignite.configuration.DataStorageConfiguration">
                <property name="defaultDataRegionConfiguration">
                    <bean class="org.apache.ignite.configuration.DataRegionConfiguration">
                        <property name="persistenceEnabled" value="true"/>
                        <property name="maxSize" value="#{512L * 1024 * 1024}"/>
                    </bean>
                </property>
            </bean>
        </property>

        <!-- Discovery 설정 -->
        <property name="discoverySpi">
            <bean class="org.apache.ignite.spi.discovery.tcp.TcpDiscoverySpi">
                <property name="ipFinder">
                    <bean class="org.apache.ignite.spi.discovery.tcp.ipfinder.multicast.TcpDiscoveryMulticastIpFinder">
                        <property name="addresses">
                            <list>
                                <value>127.0.0.1:47500..47509</value>
                            </list>
                        </property>
                    </bean>
                </property>
            </bean>
        </property>
    </bean>
</beans>
```

## 사용 예제

### REST API로 캐시 작업

```bash
# 캐시 생성
curl -X GET "http://localhost:8080/ignite?cmd=getorcreate&cacheName=myCache"

# 데이터 저장
curl -X GET "http://localhost:8080/ignite?cmd=put&key=mykey&val=myvalue&cacheName=myCache"

# 데이터 조회
curl -X GET "http://localhost:8080/ignite?cmd=get&key=mykey&cacheName=myCache"

# 데이터 삭제
curl -X GET "http://localhost:8080/ignite?cmd=rmv&key=mykey&cacheName=myCache"

# 캐시 크기 확인
curl -X GET "http://localhost:8080/ignite?cmd=size&cacheName=myCache"
```

### Java 클라이언트

```java
import org.apache.ignite.Ignite;
import org.apache.ignite.Ignition;
import org.apache.ignite.IgniteCache;
import org.apache.ignite.configuration.IgniteConfiguration;

public class IgniteExample {
    public static void main(String[] args) {
        // 클라이언트 모드로 연결
        IgniteConfiguration cfg = new IgniteConfiguration();
        cfg.setClientMode(true);

        try (Ignite ignite = Ignition.start(cfg)) {
            // 캐시 가져오기
            IgniteCache<String, String> cache = ignite.getOrCreateCache("myCache");

            // 데이터 저장
            cache.put("key1", "value1");
            cache.put("key2", "value2");

            // 데이터 조회
            String value = cache.get("key1");
            System.out.println("Value: " + value);

            // 데이터 삭제
            cache.remove("key1");
        }
    }
}
```

### SQL 쿼리

```java
// SQL 스키마가 있는 캐시 생성
CacheConfiguration<Long, Person> cacheCfg = new CacheConfiguration<>("PersonCache");
cacheCfg.setIndexedTypes(Long.class, Person.class);

IgniteCache<Long, Person> cache = ignite.getOrCreateCache(cacheCfg);

// SQL 쿼리 실행
SqlFieldsQuery sql = new SqlFieldsQuery(
    "SELECT name, age FROM Person WHERE age > ?");

List<List<?>> results = cache.query(sql.setArgs(25)).getAll();
```

### Python 클라이언트 (pyignite)

```python
from pyignite import Client

# 연결
client = Client()
client.connect('localhost', 10800)

# 캐시 생성
cache = client.get_or_create_cache('my_cache')

# 데이터 저장
cache.put('key1', 'value1')
cache.put('key2', 'value2')

# 데이터 조회
value = cache.get('key1')
print(f'Value: {value}')

# 데이터 삭제
cache.remove('key1')

# 연결 종료
client.close()
```

## 캐시 모드

### 1. PARTITIONED (분산)

데이터를 노드 간 분산 저장:

```xml
<property name="cacheMode" value="PARTITIONED"/>
<property name="backups" value="1"/>
```

### 2. REPLICATED (복제)

모든 노드에 전체 데이터 복제:

```xml
<property name="cacheMode" value="REPLICATED"/>
```

### 3. LOCAL (로컬)

각 노드에 로컬 데이터만 저장:

```xml
<property name="cacheMode" value="LOCAL"/>
```

## 영속성 (Persistence)

### 영속성 활성화

```xml
<property name="dataStorageConfiguration">
    <bean class="org.apache.ignite.configuration.DataStorageConfiguration">
        <property name="defaultDataRegionConfiguration">
            <bean class="org.apache.ignite.configuration.DataRegionConfiguration">
                <property name="persistenceEnabled" value="true"/>
            </bean>
        </property>
    </bean>
</property>
```

### 영속성 활성화 (클러스터 전체)

```bash
# 컨테이너 접속
docker-compose exec db bash

# Ignite CLI 실행
/opt/ignite/apache-ignite/bin/control.sh --activate

# 비활성화
/opt/ignite/apache-ignite/bin/control.sh --deactivate
```

## 모니터링

### REST API로 상태 확인

```bash
# 클러스터 상태
curl http://localhost:8080/ignite?cmd=top

# 캐시 목록
curl http://localhost:8080/ignite?cmd=cache

# 메트릭
curl http://localhost:8080/ignite?cmd=node
```

### 로그 확인

```bash
# Docker 로그
docker-compose logs -f db

# Ignite 로그 파일
docker-compose exec db cat /opt/ignite/apache-ignite/work/log/ignite.log
```

## 백업 및 복원

### 스냅샷 생성

```bash
# 컨테이너 접속
docker-compose exec db bash

# 스냅샷 생성
/opt/ignite/apache-ignite/bin/control.sh --snapshot create my_snapshot

# 스냅샷 확인
/opt/ignite/apache-ignite/bin/control.sh --snapshot list
```

### 스냅샷 복원

```bash
# 복원
/opt/ignite/apache-ignite/bin/control.sh --snapshot restore my_snapshot
```

### 데이터 파일 백업

```bash
# Persistence 디렉토리 백업
docker cp ignite_db_1:/persistence ./ignite-backup
```

## 성능 튜닝

### 1. 메모리 크기 조정

```yaml
JVM_OPTS: >
  -Xms4g
  -Xmx4g
```

### 2. Off-Heap 메모리 설정

```xml
<property name="dataStorageConfiguration">
    <bean class="org.apache.ignite.configuration.DataStorageConfiguration">
        <property name="defaultDataRegionConfiguration">
            <bean class="org.apache.ignite.configuration.DataRegionConfiguration">
                <property name="maxSize" value="#{2L * 1024 * 1024 * 1024}"/>
            </bean>
        </property>
    </bean>
</property>
```

### 3. Write-Through / Read-Through 캐시

데이터베이스와 동기화:

```xml
<property name="cacheStoreFactory">
    <bean class="javax.cache.configuration.FactoryBuilder" factory-method="factoryOf">
        <constructor-arg value="com.mycompany.MyCacheStore"/>
    </bean>
</property>
<property name="writeThrough" value="true"/>
<property name="readThrough" value="true"/>
```

## 클러스터 구성

### Docker Compose로 다중 노드

```yaml
version: '3.7'
services:
  ignite-node-1:
    image: apacheignite/ignite
    environment:
      - IGNITE_WORK_DIR=/persistence
      - CONFIG_URI=file:/config/ignite-config.xml
    ports:
      - "10800:10800"
    volumes:
      - node1-data:/persistence
      - ./config:/config

  ignite-node-2:
    image: apacheignite/ignite
    environment:
      - IGNITE_WORK_DIR=/persistence
      - CONFIG_URI=file:/config/ignite-config.xml
    volumes:
      - node2-data:/persistence
      - ./config:/config

volumes:
  node1-data:
  node2-data:
```

## 알려진 이슈

### 1. 메모리 부족

**문제**: OutOfMemoryError

**해결**: JVM 힙 메모리 증가
```yaml
JVM_OPTS: "-Xms4g -Xmx4g"
```

### 2. 포트 충돌

**문제**: "Address already in use" 오류

**해결**: 포트 변경 또는 충돌하는 서비스 중지

### 3. Discovery 실패

**문제**: 노드가 클러스터를 찾지 못함

**해결**: IP Finder 설정 확인

## 보안 설정

### 1. SSL/TLS 활성화

```xml
<property name="sslContextFactory">
    <bean class="org.apache.ignite.ssl.SslContextFactory">
        <property name="keyStoreFilePath" value="/path/to/keystore.jks"/>
        <property name="keyStorePassword" value="password"/>
        <property name="trustStoreFilePath" value="/path/to/truststore.jks"/>
        <property name="trustStorePassword" value="password"/>
    </bean>
</property>
```

### 2. 인증 활성화

```xml
<property name="authenticationEnabled" value="true"/>
```

## 참고 링크

- **공식 문서**: https://ignite.apache.org/docs/latest/
- **GitHub**: https://github.com/apache/ignite
- **Examples**: https://github.com/apache/ignite/tree/master/examples
- **SQL Reference**: https://ignite.apache.org/docs/latest/SQL/sql-introduction
- **REST API**: https://ignite.apache.org/docs/latest/restapi

## 프로덕션 체크리스트

- [ ] 적절한 JVM 힙 메모리 설정
- [ ] Persistence 활성화 및 백업 전략
- [ ] 클러스터 Discovery 설정
- [ ] 캐시 모드 선택 (PARTITIONED vs REPLICATED)
- [ ] Off-Heap 메모리 크기 설정
- [ ] 모니터링 및 알림 설정
- [ ] SSL/TLS 활성화
- [ ] 인증 및 권한 관리
- [ ] 네트워크 방화벽 설정
- [ ] 로그 로테이션 설정
- [ ] 정기 스냅샷 생성

## Apache Ignite vs Redis vs Memcached

| 기능 | Apache Ignite | Redis | Memcached |
|------|---------------|-------|-----------|
| 데이터 모델 | Key-Value, SQL | Key-Value | Key-Value |
| SQL 지원 | 완전 지원 | 제한적 | 없음 |
| ACID 트랜잭션 | 지원 | 제한적 | 없음 |
| 영속성 | Native | RDB, AOF | 없음 |
| 분산 컴퓨팅 | 지원 | 없음 | 없음 |
| 스트림 처리 | 지원 | Streams | 없음 |
| 인메모리 | 지원 | 지원 | 지원 |
| 학습 곡선 | 높음 | 중간 | 낮음 |

**사용 사례**:
- **Ignite**: 대규모 분산 컴퓨팅, 인메모리 데이터베이스, 복잡한 쿼리
- **Redis**: 캐싱, 세션 저장, Pub/Sub, 간단한 데이터 구조
- **Memcached**: 단순 캐싱

---

**도움이 필요하신가요?** 프로젝트 루트의 [CONTRIBUTING.md](../CONTRIBUTING.md)를 참조하거나 Issue를 열어주세요.
