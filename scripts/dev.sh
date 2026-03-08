#!/usr/bin/env bash
# dev.sh — Development environment orchestrator
# Usage: bash scripts/dev.sh [start|stop|restart|status|logs]

set -euo pipefail

ACTION="${1:-start}"
PROJECT_NAME="YOUR_APP_NAME"  # replaced by /setup-project

case "$ACTION" in
  start)
    echo "Starting $PROJECT_NAME development environment..."
    echo ""

    # Start infrastructure
    echo "Starting Docker infrastructure..."
    docker compose up -d
    echo "  ✓ PostgreSQL running on :5442"
    echo "  ✓ PostgreSQL test DB running on :5443"
    echo "  ✓ Redis running on :6379"
    echo ""

    # Wait for DB to be ready
    echo "Waiting for PostgreSQL to be ready..."
    timeout 30 bash -c 'until docker compose exec postgres pg_isready -U postgres -q; do sleep 1; done'
    echo "  ✓ PostgreSQL ready"
    echo ""

    echo "Start your apps in separate terminals:"
    echo "  pnpm nx serve api      → http://localhost:3333"
    echo "  pnpm nx serve client   → http://localhost:4200"
    echo ""
    echo "Or run a health check: curl http://localhost:3333/api/v1/health"
    ;;

  stop)
    echo "Stopping Docker infrastructure..."
    docker compose down
    echo "  ✓ Stopped"
    ;;

  restart)
    bash "$0" stop
    bash "$0" start
    ;;

  status)
    echo "Docker infrastructure status:"
    docker compose ps
    ;;

  logs)
    SERVICE="${2:-}"
    if [[ -n "$SERVICE" ]]; then
      docker compose logs -f "$SERVICE"
    else
      docker compose logs -f
    fi
    ;;

  *)
    echo "Usage: $0 [start|stop|restart|status|logs [service]]"
    exit 1
    ;;
esac
