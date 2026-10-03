#!/bin/bash

set -e

echo "=== TP08 - Verificación del stack ==="

echo
echo "1. Contenedores:"
docker compose ps

echo
echo "2. Prometheus:"
curl -fsS http://localhost:9090/-/healthy
echo

echo
echo "3. Aplicación:"
curl -fsS http://localhost:8080/health
echo

echo
echo "4. Métricas:"
curl -fsS http://localhost:8080/metrics | grep -E '^app_(requests_total|notes_total|request_duration_seconds|db_errors_total|info)' | head -20

echo
echo "5. Targets de Prometheus:"
curl -fsS http://localhost:9090/api/v1/targets \
  | grep -o '"health":"up"' \
  | wc -l

echo
echo "=== Stack OK — verificación completada ==="
