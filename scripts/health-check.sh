#!/bin/bash

# 서비스 헬스 체크 스크립트

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# 색상 정의
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
GRAY='\033[0;90m'
NC='\033[0m' # No Color

# 사용법 출력
usage() {
    echo "사용법: $0 [서비스명] [옵션]"
    echo ""
    echo "옵션:"
    echo "  -f, --file <파일명>  특정 docker-compose 파일 지정"
    echo "  -a, --all            모든 서비스 확인"
    echo "  -v, --verbose        상세 정보 출력"
    echo "  -h, --help           도움말 출력"
    echo ""
    echo "예제:"
    echo "  $0 wordpress"
    echo "  $0 nextcloud -f dc-pg.yml"
    echo "  $0 --all"
    echo "  $0 wordpress --verbose"
    echo ""
    exit 1
}

# 인자 확인
if [ "$1" == "-h" ] || [ "$1" == "--help" ]; then
    usage
fi

# 옵션 파싱
SERVICE=""
COMPOSE_FILE="docker-compose.yml"
CHECK_ALL=false
VERBOSE=false

# 첫 번째 인자가 옵션이 아니면 서비스명으로 간주
if [ $# -gt 0 ] && [[ ! "$1" =~ ^- ]]; then
    SERVICE=$1
    shift
fi

while [[ $# -gt 0 ]]; do
    case $1 in
        -f|--file)
            COMPOSE_FILE="$2"
            shift 2
            ;;
        -a|--all)
            CHECK_ALL=true
            shift
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -h|--help)
            usage
            ;;
        *)
            echo -e "${RED}알 수 없는 옵션: $1${NC}"
            usage
            ;;
    esac
done

# docker-compose 명령 확인
if command -v docker-compose &> /dev/null; then
    COMPOSE_CMD="docker-compose"
elif command -v docker &> /dev/null && docker compose version &> /dev/null; then
    COMPOSE_CMD="docker compose"
else
    echo -e "${RED}❌ 오류: docker-compose 또는 docker compose를 찾을 수 없습니다.${NC}"
    exit 1
fi

# 컨테이너 상태 확인
check_container() {
    local container=$1
    local status=$(docker inspect --format='{{.State.Status}}' "$container" 2>/dev/null)
    local health=$(docker inspect --format='{{if .State.Health}}{{.State.Health.Status}}{{else}}none{{end}}' "$container" 2>/dev/null)

    if [ -z "$status" ]; then
        echo -e "${GRAY}⚪ 없음${NC}"
        return 2
    elif [ "$status" == "running" ]; then
        if [ "$health" == "healthy" ]; then
            echo -e "${GREEN}✅ 정상${NC}"
            return 0
        elif [ "$health" == "unhealthy" ]; then
            echo -e "${RED}❌ 비정상${NC}"
            return 1
        else
            echo -e "${GREEN}✅ 실행중${NC}"
            return 0
        fi
    else
        echo -e "${RED}❌ 중지됨${NC}"
        return 1
    fi
}

# 서비스 헬스 체크
check_service() {
    local service_name=$1
    local service_dir="$PROJECT_ROOT/$service_name"
    local compose_file=$2

    if [ ! -d "$service_dir" ]; then
        return
    fi

    if [ ! -f "$service_dir/$compose_file" ]; then
        return
    fi

    cd "$service_dir"

    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}📦 $service_name${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    # 컨테이너 목록 가져오기
    local containers=$($COMPOSE_CMD -f "$compose_file" ps -q 2>/dev/null)

    if [ -z "$containers" ]; then
        echo -e "${GRAY}  서비스가 실행되지 않았습니다.${NC}"
        echo ""
        return
    fi

    # 각 컨테이너 상태 확인
    local service_names=$($COMPOSE_CMD -f "$compose_file" ps --services 2>/dev/null)

    for svc in $service_names; do
        local container_id=$($COMPOSE_CMD -f "$compose_file" ps -q $svc 2>/dev/null)

        if [ -n "$container_id" ]; then
            local container_name=$(docker inspect --format='{{.Name}}' "$container_id" 2>/dev/null | sed 's/^\///')
            printf "  %-20s " "$svc:"

            local status=$(check_container "$container_id")
            echo "$status"

            # Verbose 모드
            if [ "$VERBOSE" = true ]; then
                local uptime=$(docker inspect --format='{{.State.StartedAt}}' "$container_id" 2>/dev/null)
                local cpu=$(docker stats --no-stream --format "{{.CPUPerc}}" "$container_id" 2>/dev/null)
                local mem=$(docker stats --no-stream --format "{{.MemUsage}}" "$container_id" 2>/dev/null)

                echo -e "${GRAY}    컨테이너: $container_name${NC}"
                echo -e "${GRAY}    시작 시간: $uptime${NC}"
                echo -e "${GRAY}    CPU: $cpu${NC}"
                echo -e "${GRAY}    메모리: $mem${NC}"
            fi
        fi
    done

    # 포트 정보
    if [ "$VERBOSE" = true ]; then
        echo ""
        echo "  포트 바인딩:"
        $COMPOSE_CMD -f "$compose_file" ps --format "table {{.Service}}\t{{.Ports}}" 2>/dev/null | tail -n +2 | while read line; do
            echo -e "${GRAY}    $line${NC}"
        done
    fi

    echo ""
}

# 메인 로직
echo -e "${BLUE}=========================================="
echo "  🏥 서비스 헬스 체크"
echo "==========================================${NC}"
echo ""

if [ "$CHECK_ALL" = true ]; then
    # 모든 서비스 확인
    for dir in "$PROJECT_ROOT"/*/ ; do
        SERVICE_NAME=$(basename "$dir")

        # 특수 디렉토리 제외
        if [[ "$SERVICE_NAME" == "scripts" ]] || [[ "$SERVICE_NAME" == ".git" ]]; then
            continue
        fi

        # docker-compose.yml 또는 dc-*.yml 파일 찾기
        if [ -f "$dir/docker-compose.yml" ]; then
            check_service "$SERVICE_NAME" "docker-compose.yml"
        elif compgen -G "$dir/dc-*.yml" > /dev/null; then
            # 첫 번째 dc-*.yml 파일 사용
            local first_dc=$(ls "$dir"/dc-*.yml 2>/dev/null | head -1)
            check_service "$SERVICE_NAME" "$(basename "$first_dc")"
        fi
    done
else
    # 단일 서비스 확인
    if [ -z "$SERVICE" ]; then
        echo -e "${RED}❌ 오류: 서비스명을 지정하거나 --all 옵션을 사용하세요.${NC}"
        echo ""
        usage
    fi

    check_service "$SERVICE" "$COMPOSE_FILE"
fi

echo -e "${BLUE}=========================================="
echo "  헬스 체크 완료"
echo "==========================================${NC}"
echo ""

# 도움말 힌트
if [ "$VERBOSE" = false ]; then
    echo -e "${GRAY}💡 상세 정보를 보려면 --verbose 옵션을 사용하세요.${NC}"
    echo ""
fi
