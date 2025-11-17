# MediaWiki

MediaWiki는 위키피디아를 구동하는 강력한 오픈소스 위키 엔진입니다. 대규모 협업 문서 작성 및 지식 관리에 최적화되어 있습니다.

## 개요

- **공식 사이트**: https://www.mediawiki.org
- **Docker Hub**:
  - 공식: https://hub.docker.com/_/mediawiki
  - Bitnami: https://hub.docker.com/r/bitnami/mediawiki
- **기본 포트**: 8080
- **데이터베이스**: MariaDB 10

## 빠른 시작

```bash
# 서비스 시작
cd mediawiki
docker-compose up -d

# 브라우저에서 접속하여 초기 설정
# http://localhost:8080
```

초기 설정 후 `LocalSettings.php` 파일을 다운로드하여 `/bitnami/mediawiki/` 경로에 업로드해야 합니다.

### 헬퍼 스크립트 사용

```bash
./scripts/start.sh mediawiki
./scripts/stop.sh mediawiki
./scripts/backup.sh mediawiki
```

## 환경 변수

| 변수명 | 기본값 | 설명 |
|--------|--------|------|
| MARIADB_HOST | db | 데이터베이스 호스트 |
| MARIADB_PORT_NUMBER | 3306 | 데이터베이스 포트 |
| MEDIAWIKI_DATABASE_USER | bn_mediawiki | DB 사용자 |
| MEDIAWIKI_DATABASE_NAME | bitnami_mediawiki | DB 이름 |
| ALLOW_EMPTY_PASSWORD | yes | 빈 비밀번호 허용 (개발용) |

## 볼륨

### Bitnami 이미지 (현재 사용 중)

- `db_data`: MariaDB 데이터베이스 데이터
- `web_data`: MediaWiki 애플리케이션 데이터 (`/bitnami`)

**중요 파일/디렉토리**:
```
/bitnami/mediawiki/LocalSettings.php    # 설정 파일 (초기 설치 후 생성)
/bitnami/mediawiki/images                # 업로드된 이미지
/bitnami/mediawiki/extensions            # 확장 기능
/bitnami/mediawiki/skins                 # 스킨
```

### 공식 이미지

```
/var/www/html/images                     # 업로드 이미지
/var/www/html/LocalSettings.php          # 설정 파일
```

## 사용 예제

### 백업

```bash
# 데이터베이스 백업
docker-compose exec db mysqldump -u bn_mediawiki bitnami_mediawiki > backup.sql

# 파일 백업
docker-compose exec mediawiki tar czf /tmp/mediawiki-files.tar.gz /bitnami/mediawiki
docker cp mediawiki_mediawiki_1:/tmp/mediawiki-files.tar.gz ./mediawiki-backup.tar.gz

# 또는 자동화 스크립트 사용
cd /home/user/sb-samples-docker
./scripts/backup.sh mediawiki
```

### 유지보수 스크립트

MediaWiki는 강력한 유지보수 스크립트를 제공합니다:

```bash
# 데이터베이스 업데이트
docker-compose exec mediawiki php /opt/bitnami/mediawiki/maintenance/update.php

# 통계 재생성
docker-compose exec mediawiki php /opt/bitnami/mediawiki/maintenance/initSiteStats.php

# 링크 테이블 재구축
docker-compose exec mediawiki php /opt/bitnami/mediawiki/maintenance/refreshLinks.php

# 사용자 생성
docker-compose exec mediawiki php /opt/bitnami/mediawiki/maintenance/createAndPromote.php --bureaucrat --sysop username password
```

## 확장 기능 및 스킨

### 인기 확장 기능

- **VisualEditor**: WYSIWYG 편집기
- **Cite**: 참조 및 인용 기능
- **ParserFunctions**: 고급 파서 함수
- **Widgets**: HTML/JavaScript 위젯
- **Semantic MediaWiki**: 시맨틱 웹 기능

### 확장 기능 설치

```bash
# 컨테이너 내부 접속
docker-compose exec mediawiki bash

# extensions 디렉토리로 이동
cd /opt/bitnami/mediawiki/extensions

# 확장 다운로드 (예: VisualEditor)
git clone https://gerrit.wikimedia.org/r/mediawiki/extensions/VisualEditor
```

`LocalSettings.php`에 추가:
```php
wfLoadExtension( 'VisualEditor' );
```

## API 사용

MediaWiki는 강력한 API를 제공합니다:

```bash
# API 엔드포인트
http://localhost:8080/api.php

# 예: 페이지 내용 가져오기
curl "http://localhost:8080/api.php?action=parse&page=Main_Page&format=json"
```

## 알려진 이슈

### 1. LocalSettings.php 누락

**문제**: 초기 설치 후 위키 접속 시 설정 페이지로 리다이렉트

**해결**: 웹 인스톨러에서 생성된 `LocalSettings.php` 파일을 `/bitnami/mediawiki/`에 복사

### 2. 이미지 업로드 권한 문제

**문제**: 파일 업로드 시 권한 오류

**해결**:
```bash
docker-compose exec mediawiki chown -R daemon:daemon /bitnami/mediawiki/images
docker-compose exec mediawiki chmod -R 755 /bitnami/mediawiki/images
```

### 3. 확장 기능 로드 실패

**문제**: 확장 기능이 작동하지 않음

**해결**: `update.php` 스크립트 실행
```bash
docker-compose exec mediawiki php /opt/bitnami/mediawiki/maintenance/update.php
```

## 프로덕션 체크리스트

- [ ] 초기 설치 및 LocalSettings.php 구성
- [ ] 데이터베이스 비밀번호 변경
- [ ] HTTPS 설정 (리버스 프록시)
- [ ] 파일 업로드 크기 제한 설정
- [ ] 확장 기능 설치 (VisualEditor 등)
- [ ] 정기 백업 스크립트 설정
- [ ] 사용자 권한 설정
- [ ] 스팸 방지 설정 (CAPTCHA)
- [ ] 로그 로테이션 설정
- [ ] 데이터베이스 최적화

## 참고 링크

- **공식 문서**: https://www.mediawiki.org/wiki/Documentation
- **확장 기능**: https://www.mediawiki.org/wiki/Category:Extensions
- **스킨**: https://www.mediawiki.org/wiki/Category:All_skins
- **API 문서**: https://www.mediawiki.org/wiki/API:Main_page
- **Bitnami MediaWiki**: https://github.com/bitnami/bitnami-docker-mediawiki

---

**도움이 필요하신가요?** 프로젝트 루트의 [CONTRIBUTING.md](../CONTRIBUTING.md)를 참조하거나 Issue를 열어주세요.
