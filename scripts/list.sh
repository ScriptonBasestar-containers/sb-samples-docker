#!/bin/bash

# 사용 가능한 서비스 목록 출력

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "=========================================="
echo " 사용 가능한 Docker 서비스 목록"
echo "=========================================="
echo ""

# 서비스 디렉토리 찾기
SERVICES=()

for dir in "$PROJECT_ROOT"/*/ ; do
    SERVICE_NAME=$(basename "$dir")

    # 특수 디렉토리 제외
    if [[ "$SERVICE_NAME" == "scripts" ]] || [[ "$SERVICE_NAME" == ".git" ]]; then
        continue
    fi

    # docker-compose.yml 또는 dc-*.yml 파일 찾기
    if [ -f "$dir/docker-compose.yml" ] || compgen -G "$dir/dc-*.yml" > /dev/null; then
        SERVICES+=("$SERVICE_NAME")
    fi
done

# 서비스 목록 출력
echo "📦 CMS & 블로그 플랫폼:"
for service in wordpress joomla drupal; do
    if [[ " ${SERVICES[@]} " =~ " ${service} " ]]; then
        echo "  - $service"
    fi
done

echo ""
echo "📚 위키 시스템:"
for service in dokuwiki mediawiki phabricator; do
    if [[ " ${SERVICES[@]} " =~ " ${service} " ]]; then
        echo "  - $service"
    fi
done

echo ""
echo "💬 포럼 & 커뮤니티:"
for service in flarum; do
    if [[ " ${SERVICES[@]} " =~ " ${service} " ]]; then
        echo "  - $service"
    fi
done

echo ""
echo "☁️  클라우드 스토리지:"
for service in nextcloud; do
    if [[ " ${SERVICES[@]} " =~ " ${service} " ]]; then
        echo "  - $service"
    fi
done

echo ""
echo "⚡ 캐시 & 데이터베이스:"
for service in redis memcached ignite; do
    if [[ " ${SERVICES[@]} " =~ " ${service} " ]]; then
        echo "  - $service"
    fi
done

echo ""
echo "=========================================="
echo "총 ${#SERVICES[@]}개 서비스 사용 가능"
echo ""
echo "사용법:"
echo "  ./scripts/start.sh <서비스명>"
echo "  ./scripts/stop.sh <서비스명>"
echo "  ./scripts/ports.sh"
echo "=========================================="
