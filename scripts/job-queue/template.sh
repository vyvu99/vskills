#!/usr/bin/env bash
# <tên>: <1 dòng mô tả>. Usage: <tên>.sh [--scope <gói|thư mục>] [--help]
# Khuôn chung cho mọi script test/check: chạy qua jobq, nhận scope, 1 dòng PASS/FAIL, exit ≠ 0 khi lỗi.
# Script nặng: tách thành thư mục steps/NN-tên.sh rồi chạy bằng `stepper`, không nhồi vào 1 file.
set -euo pipefail

usage() { sed -n '2p' "$0" | sed 's/^# //'; }
SCOPE=""
while [ $# -gt 0 ]; do
  case "$1" in
    --scope) SCOPE=${2:?thiếu giá trị --scope}; shift 2 ;;
    --help|-h) usage; exit 0 ;;
    *) echo "FAIL: tham số lạ $1" >&2; usage >&2; exit 2 ;;
  esac
done

WORKERS=${JOBQ_WORKERS:-2}   # số worker mặc định, không tự nâng
TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT

# --- việc cần làm: lệnh nặng chạy bằng `jobq run -- <lệnh>`, dùng $WORKERS và $SCOPE ---
# jobq run -- pnpm --filter "${SCOPE:-.}" test --maxWorkers="$WORKERS"

echo "PASS: <tên> (${SCOPE:-all})"
