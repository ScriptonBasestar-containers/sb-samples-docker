# sb-samples-websolution

도커 기반 웹 솔루션 샘플 모음집

필요할 때 빠르게 사용할 수 있도록 정리한 Docker Compose 설정 모음입니다.

## 목차

- [개요](#개요)
- [포함된 서비스](#포함된-서비스)
- [포트 맵](#포트-맵)
- [빠른 시작](#빠른-시작)
- [주의사항](#주의사항)
- [디렉토리 구조](#디렉토리-구조)

## 개요

이 저장소는 다양한 웹 애플리케이션과 백엔드 서비스를 Docker로 빠르게 실행할 수 있도록 사전 구성된 설정을 제공합니다.

각 서비스는 독립된 디렉토리에 `docker-compose.yml` 파일과 함께 제공되며, 서비스별 README에서 상세한 사용법을 확인할 수 있습니다.

## 포함된 서비스

### CMS & 블로그 플랫폼
| 서비스 | 설명 | 디렉토리 |
|--------|------|----------|
| WordPress | 가장 인기 있는 블로그/CMS 플랫폼 | [wordpress/](wordpress/) |
| Joomla | 강력한 오픈소스 CMS | [joomla/](joomla/) |
| Drupal | 엔터프라이즈급 CMS | [drupal/](drupal/) |

### 위키 시스템
| 서비스 | 설명 | 디렉토리 |
|--------|------|----------|
| DokuWiki | 간단하고 사용하기 쉬운 위키 | [dokuwiki/](dokuwiki/) |
| MediaWiki | 위키피디아 엔진 | [mediawiki/](mediawiki/) |
| Phabricator | 협업 플랫폼 (위키 포함) | [phabricator/](phabricator/) |

### 포럼 & 커뮤니티
| 서비스 | 설명 | 디렉토리 |
|--------|------|----------|
| Flarum | 현대적인 포럼 소프트웨어 | [flarum/](flarum/) |

### 클라우드 스토리지
| 서비스 | 설명 | 디렉토리 |
|--------|------|----------|
| Nextcloud | 개인 클라우드 스토리지 | [nextcloud/](nextcloud/) |

### 캐시 & 데이터베이스
| 서비스 | 설명 | 디렉토리 |
|--------|------|----------|
| Redis | 인메모리 데이터 저장소 (단일/복제/Sentinel) | [redis/](redis/) |
| Memcached | 분산 메모리 캐싱 시스템 | [memcached/](memcached/) |
| Apache Ignite | 분산 인메모리 데이터 그리드 | [ignite/](ignite/) |

## 포트 맵

### 웹 애플리케이션 포트

⚠️ **주의**: 대부분의 웹 애플리케이션이 **8080** 포트를 사용합니다. 동시에 여러 서비스를 실행할 경우 포트 충돌이 발생하므로, docker-compose.yml에서 포트를 수정하거나 한 번에 하나씩 실행하세요.

| 서비스 | 웹 포트 | DB 포트 | 기타 포트 | 비고 |
|--------|---------|---------|-----------|------|
| DokuWiki | 8080, 8081 | - | - | 8081은 설치용 |
| Drupal | 8080 | 3306 | - | MariaDB 사용 |
| Flarum | 8888 | 3306 | - | 포트 충돌 없음 |
| Joomla | 8080 | 3306 | - | MariaDB 사용 |
| WordPress | 8080 | 3306 | - | MariaDB 사용 |
| MediaWiki | 8080 | 3306 | - | MariaDB 사용 |
| Nextcloud | 8080 | 3306 | 6379 (Redis) | MariaDB + Redis |
| Phabricator | 8080 | 3306 | - | MariaDB 사용 |

### 캐시 & 데이터베이스 포트

| 서비스 | 포트 | 비고 |
|--------|------|------|
| Redis | 6003 | TLS/SSL 지원 |
| Memcached | 11211, 11212, 11213 | 3개 이미지 비교용 |
| Apache Ignite | 11211, 47500-47509 | 클러스터 통신 |

## 빠른 시작

### 기본 사용법

1. 원하는 서비스 디렉토리로 이동:
```bash
cd wordpress
```

2. Docker Compose로 서비스 시작:
```bash
docker-compose up -d
```

3. 브라우저에서 접속:
```
http://localhost:8080
```

4. 서비스 중지:
```bash
docker-compose down
```

### 예제: WordPress 실행

```bash
# WordPress 디렉토리로 이동
cd wordpress

# 서비스 시작 (백그라운드)
docker-compose up -d

# 로그 확인
docker-compose logs -f

# 서비스 중지
docker-compose down

# 볼륨까지 완전 삭제
docker-compose down -v
```

### 포트 충돌 해결 방법

여러 서비스를 동시에 실행하려면 `docker-compose.yml`에서 포트를 수정하세요:

```yaml
services:
  wordpress:
    ports:
      - 8081:8080  # 8080 대신 8081 사용
```

또는 환경 변수를 사용하여 포트를 커스터마이징할 수 있습니다 (향후 .env 파일 지원 예정).

## 주의사항

### 볼륨 설정

volume은 `/bitnami`나 `/var/www/html`처럼 범위가 과도하게 넓게 잡힌 경우가 있습니다.
제대로 파악이 안되어서 그냥 넓게 잡아놨으니, 실제 사용할 때는 필요한 부분만 선택해서 줄여서 사용하세요.

일반적으로 다음 항목들이 필요합니다:
- `plugins` - 플러그인
- `config` - 설정 파일
- `contents` - 컨텐츠
- `uploads` - 업로드 파일
- `themes` - 테마

### Bitnami 이미지 관련

Bitnami 이미지는 초기 구성이 쉬운 경향이 있지만, 이미지에 따라서 백업/리스토어 할 때 초기화 스크립트 때문에 오류가 나는 경우가 종종 있습니다.

프로덕션 환경에서는 공식 이미지를 사용하거나, Bitnami 이미지의 초기화 동작을 충분히 테스트한 후 사용하세요.

### 데이터베이스 기본 설정

대부분의 서비스가 개발 편의를 위해 `ALLOW_EMPTY_PASSWORD=yes`를 사용합니다.
**프로덕션 환경에서는 반드시 안전한 비밀번호를 설정하세요.**

### 알려진 이슈

- **Nextcloud (MySQL)**: transaction isolation 이슈가 있어 PostgreSQL 사용 권장
- **Phabricator**: HTTPS 자동 리다이렉트 이슈, 프록시 설정 필요
- **Redis**: TLS/SSL 인증서 생성 필요 (상세 가이드는 [redis/README.md](redis/README.md) 참조)

## 디렉토리 구조

```
sb-samples-docker/
├── dokuwiki/          # DokuWiki 위키
├── drupal/            # Drupal CMS
├── flarum/            # Flarum 포럼
├── ignite/            # Apache Ignite
├── joomla/            # Joomla CMS
├── mediawiki/         # MediaWiki
├── memcached/         # Memcached (3가지 이미지 비교)
├── nextcloud/         # Nextcloud 클라우드
├── phabricator/       # Phabricator 협업 플랫폼
├── redis/             # Redis (단일/복제/Sentinel)
└── wordpress/         # WordPress 블로그/CMS
```

각 디렉토리에는 다음이 포함됩니다:
- `docker-compose.yml` - Docker Compose 설정
- `README.md` - 서비스별 상세 가이드
- 추가 설정 파일 (서비스에 따라 다름)

## 기여하기

개선 사항이나 추가할 서비스가 있다면 Issue나 Pull Request를 환영합니다!

## 라이센스

MIT License - 자세한 내용은 [LICENSE](LICENSE) 파일을 참조하세요.

---

**참고**: 이 저장소는 개발 및 테스트 목적으로 만들어졌습니다. 프로덕션 환경에서 사용하기 전에 보안 설정을 반드시 검토하세요.
