# DokuWiki

DokuWiki는 간단하고 사용하기 쉬운 오픈소스 위키 소프트웨어입니다. 데이터베이스가 필요 없으며, 텍스트 파일 기반으로 동작하여 백업과 버전 관리가 쉽습니다.

## 개요

- **공식 사이트**: https://www.dokuwiki.org
- **Docker Hub**:
  - Linuxserver: https://hub.docker.com/r/linuxserver/dokuwiki (권장)
  - Bitnami: https://hub.docker.com/r/bitnami/dokuwiki
  - MPrasil: https://hub.docker.com/r/mprasil/dokuwiki
- **기본 포트**: 8080, 8081
- **데이터베이스**: 불필요 (파일 기반)

## 빠른 시작

### 초기 설치 과정

DokuWiki는 2단계 설치가 필요합니다:

```bash
# 1단계: 설치 컨테이너 실행 (8081 포트)
cd dokuwiki
docker-compose up -d dokuwiki-install

# 브라우저에서 http://localhost:8081 접속하여 초기 설정 완료

# 2단계: 설정 파일을 메인 컨테이너로 복사
docker exec -it dokuwiki_dokuwiki-install_1 cp -r /config/dokuwiki /install/

# 3단계: 메인 컨테이너 실행 (8080 포트)
docker-compose up -d dokuwiki

# 메인 사이트 접속: http://localhost:8080
```

### 헬퍼 스크립트 사용

```bash
# 프로젝트 루트에서
./scripts/start.sh dokuwiki

# 중지
./scripts/stop.sh dokuwiki

# 볼륨까지 삭제
./scripts/stop.sh dokuwiki -v
```

## 환경 변수

| 변수명 | 기본값 | 설명 |
|--------|--------|------|
| TZ | Asia/Seoul | 타임존 |
| PUID | 1000 | 사용자 ID (Linuxserver 이미지) |
| PGID | 1000 | 그룹 ID (Linuxserver 이미지) |
| APP_URL | / | 서브 경로 설정 (예: /dokuwiki) |

## 볼륨

### Linuxserver 이미지 (현재 사용 중)

- `doku-conf`: 설정 파일 (`/config/dokuwiki/conf`)
- `doku-data`: 위키 데이터 (페이지, 미디어) (`/config/dokuwiki/data`)
- `doku-lib`: 플러그인 및 템플릿 (`/config/dokuwiki/lib`)
- `uploads.ini`: PHP 업로드 설정 (호스트 마운트)

**중요 디렉토리**:
```
/config/dokuwiki/conf           # 설정 파일
/config/dokuwiki/data/pages     # 위키 페이지 (평문 텍스트)
/config/dokuwiki/data/media     # 업로드된 미디어 파일
/config/dokuwiki/data/meta      # 페이지 메타데이터
/config/dokuwiki/data/attic     # 페이지 버전 히스토리
/config/dokuwiki/lib/plugins    # 플러그인
/config/dokuwiki/lib/tpl        # 템플릿
```

### Bitnami 이미지

```
/bitnami                        # 모든 DokuWiki 데이터
```

## 포트

| 포트 | 서비스 | 설명 |
|------|--------|------|
| 8080 | dokuwiki | 메인 위키 사이트 |
| 8081 | dokuwiki-install | 초기 설치용 (일시적) |

⚠️ **주의**: 초기 설치 완료 후에는 dokuwiki-install 컨테이너를 중지하고 dokuwiki만 사용하세요.

## 기본 접속 정보

- **URL**: http://localhost:8080
- **관리자 계정**: 초기 설치 시 생성
- **관리 페이지**: http://localhost:8080/doku.php?id=start&do=admin

## 사용 예제

### 백업

DokuWiki는 데이터베이스가 없어 백업이 매우 간단합니다:

```bash
# 전체 데이터 백업 (권장)
docker-compose exec dokuwiki tar czf /tmp/dokuwiki-backup.tar.gz /config/dokuwiki
docker cp dokuwiki_dokuwiki_1:/tmp/dokuwiki-backup.tar.gz ./dokuwiki-backup-$(date +%Y%m%d).tar.gz

# 페이지만 백업
docker-compose exec dokuwiki tar czf /tmp/pages-backup.tar.gz /config/dokuwiki/data/pages
docker cp dokuwiki_dokuwiki_1:/tmp/pages-backup.tar.gz ./pages-backup.tar.gz

# 미디어 파일만 백업
docker-compose exec dokuwiki tar czf /tmp/media-backup.tar.gz /config/dokuwiki/data/media
docker cp dokuwiki_dokuwiki_1:/tmp/media-backup.tar.gz ./media-backup.tar.gz
```

### 복원

```bash
# 전체 복원
docker cp ./dokuwiki-backup-20240117.tar.gz dokuwiki_dokuwiki_1:/tmp/
docker-compose exec dokuwiki tar xzf /tmp/dokuwiki-backup-20240117.tar.gz -C /

# 컨테이너 재시작
docker-compose restart dokuwiki
```

### 로그 확인

```bash
# Docker 로그
docker-compose logs -f dokuwiki

# 웹 서버 로그
docker-compose exec dokuwiki tail -f /config/log/nginx/access.log
docker-compose exec dokuwiki tail -f /config/log/nginx/error.log
```

### 플러그인 설치

**방법 1: 웹 인터페이스 (권장)**
1. 관리자 로그인
2. Admin > Extension Manager
3. 플러그인 검색 및 설치

**방법 2: 수동 설치**
```bash
# 컨테이너 내부 접속
docker-compose exec dokuwiki bash

# 플러그인 디렉토리로 이동
cd /config/dokuwiki/lib/plugins

# Git으로 플러그인 다운로드 (예: wrap plugin)
git clone https://github.com/selfthinker/dokuwiki_plugin_wrap.git wrap
```

## 커스터마이징

### 포트 변경

`.env` 파일 생성:
```bash
DOKUWIKI_PORT=8080
DOKUWIKI_INSTALL_PORT=8081
```

`docker-compose.yml` 수정:
```yaml
services:
  dokuwiki:
    ports:
      - "${DOKUWIKI_PORT:-8080}:80"
  dokuwiki-install:
    ports:
      - "${DOKUWIKI_INSTALL_PORT:-8081}:80"
```

### PHP 업로드 제한 증가

`uploads.ini` 파일 수정:
```ini
upload_max_filesize = 128M
post_max_size = 128M
memory_limit = 256M
```

컨테이너 재시작:
```bash
docker-compose restart dokuwiki
```

### 서브 경로에서 실행

`docker-compose.yml`에서:
```yaml
environment:
  - APP_URL=/wiki
```

nginx 리버스 프록시 설정 필요.

### ACL (접근 제어) 설정

1. Admin > Access Control List Manager
2. 네임스페이스별, 페이지별 권한 설정
3. 사용자 그룹 생성 및 권한 할당

## 알려진 이슈

### 1. 초기 설치 시 볼륨 문제

**문제**: Linuxserver 이미지는 빈 볼륨에서 자동 초기화가 안됨

**해결**: 2단계 설치 프로세스 사용 (위 "빠른 시작" 참조)

### 2. Bitnami 이미지 초기화 스크립트 오류

**문제**: Bitnami 이미지는 컨테이너 재시작 시 초기화 스크립트 실행으로 오류 발생

**해결**: 프로덕션 환경에서는 Linuxserver 이미지 사용 권장

### 3. 파일 퍼미션 문제

**문제**: 페이지 편집 또는 미디어 업로드 시 권한 오류

**해결**:
```bash
docker-compose exec dokuwiki chown -R abc:abc /config/dokuwiki
docker-compose exec dokuwiki chmod -R 755 /config/dokuwiki
```

### 4. URL Rewriting 문제

**문제**: "Nice URLs" 활성화 후 페이지를 찾을 수 없음

**해결**: nginx 설정이 이미 포함되어 있으므로, 관리자 페이지에서 "Nice URLs" 활성화만 하면 됩니다.

## DokuWiki 관리 팁

### 필수 플러그인 추천

- **Wrap**: 고급 텍스트 스타일링
- **Indexmenu**: 개선된 네비게이션
- **PageList**: 페이지 목록 생성
- **Discussion**: 페이지 댓글/토론
- **Tag**: 태그 기능
- **SearchIndex**: 향상된 검색

### 유용한 구문

```
====== 제목 1 ======
===== 제목 2 =====
==== 제목 3 ====

**굵게** //기울임// __밑줄__

  * 목록 항목 1
  * 목록 항목 2

  - 번호 목록 1
  - 번호 목록 2

[[페이지명|링크 텍스트]]
[[http://example.com|외부 링크]]

{{image.png|이미지 설명}}

<code php>
<?php
echo "코드 블록";
?>
</code>
```

### 네임스페이스 구조

효율적인 위키 구조:
```
start                           # 홈페이지
playground:playground           # 테스트 페이지
wiki:syntax                     # 문법 가이드

project:                        # 프로젝트 네임스페이스
  project:overview
  project:requirements
  project:design

docs:                           # 문서 네임스페이스
  docs:user-guide
  docs:api
  docs:faq
```

### 버전 관리

DokuWiki는 자동으로 페이지 히스토리를 저장합니다:

- **Old revisions**: 페이지의 이전 버전 보기
- **Diff**: 버전 간 차이점 비교
- **Revert**: 이전 버전으로 되돌리기

히스토리는 `/config/dokuwiki/data/attic/`에 저장됩니다.

## 성능 최적화

### 1. 캐시 활성화

Admin > Configuration Settings:
- `cachetime`: 3600 (1시간)
- `xhtml_cachetime`: 3600

### 2. 검색 인덱스 최적화

```bash
# 검색 인덱스 재구축
docker-compose exec dokuwiki php /app/dokuwiki/bin/indexer.php -c
```

### 3. 이미지 최적화

- 업로드 전 이미지 크기 조정
- PNG보다 JPEG 사용 (사진의 경우)
- 썸네일 자동 생성 활용

## 대안 설정

### Bitnami 이미지 사용

```yaml
dokuwiki:
  image: bitnami/dokuwiki
  ports:
    - 8080:80
  volumes:
    - dokuwiki_data:/bitnami
```

장점:
- 단일 컨테이너로 간단한 설정

단점:
- 초기화 스크립트 이슈
- 볼륨 구조가 덜 명확

## 참고 링크

- **공식 문서**: https://www.dokuwiki.org/manual
- **Linuxserver DokuWiki**: https://docs.linuxserver.io/images/docker-dokuwiki
- **플러그인**: https://www.dokuwiki.org/plugins
- **템플릿**: https://www.dokuwiki.org/template
- **문법**: https://www.dokuwiki.org/wiki:syntax

## 프로덕션 체크리스트

프로덕션 환경 배포 전 확인사항:

- [ ] 초기 설치 및 관리자 계정 생성 완료
- [ ] dokuwiki-install 컨테이너 중지 또는 제거
- [ ] HTTPS 설정 (리버스 프록시)
- [ ] ACL 설정 (접근 권한)
- [ ] 정기 백업 스크립트 설정
- [ ] 사용자 인증 설정 (LDAP/Active Directory 등)
- [ ] 스팸 방지 설정
- [ ] 업로드 파일 크기 제한 설정
- [ ] 불필요한 플러그인 제거
- [ ] 로그 로테이션 설정
- [ ] 검색 인덱스 최적화
- [ ] 캐시 설정

## 백업 전략

### 자동 백업 스크립트

```bash
#!/bin/bash
# dokuwiki-backup.sh

BACKUP_DIR="/path/to/backups"
DATE=$(date +%Y%m%d_%H%M%S)

docker-compose exec dokuwiki tar czf /tmp/dokuwiki-${DATE}.tar.gz /config/dokuwiki
docker cp dokuwiki_dokuwiki_1:/tmp/dokuwiki-${DATE}.tar.gz ${BACKUP_DIR}/
docker-compose exec dokuwiki rm /tmp/dokuwiki-${DATE}.tar.gz

# 30일 이상 된 백업 삭제
find ${BACKUP_DIR} -name "dokuwiki-*.tar.gz" -mtime +30 -delete
```

Cron 설정:
```cron
0 2 * * * /path/to/dokuwiki-backup.sh
```

## 마이그레이션

### 다른 위키에서 DokuWiki로

대부분의 위키는 마크다운이나 유사한 구문을 사용하므로, 변환 도구 사용:
- MediaWiki → DokuWiki: `mw2doku` 플러그인
- Confluence → DokuWiki: 수동 변환 필요

### DokuWiki 서버 간 이동

```bash
# 1. 현재 서버에서 백업
docker-compose exec dokuwiki tar czf /tmp/dokuwiki-full.tar.gz /config/dokuwiki

# 2. 새 서버로 복사
scp user@old-server:/tmp/dokuwiki-full.tar.gz ./

# 3. 새 서버에서 복원
docker cp ./dokuwiki-full.tar.gz dokuwiki_dokuwiki_1:/tmp/
docker-compose exec dokuwiki tar xzf /tmp/dokuwiki-full.tar.gz -C /
docker-compose restart dokuwiki
```

---

**도움이 필요하신가요?** 프로젝트 루트의 [CONTRIBUTING.md](../CONTRIBUTING.md)를 참조하거나 Issue를 열어주세요.
