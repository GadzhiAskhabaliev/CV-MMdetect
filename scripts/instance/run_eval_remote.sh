#!/usr/bin/env bash
set -euo pipefail
# COCOeval: uses CV-MMdetect scripts/eval_coco_predictions.py (pycocotools). No study clone required.
# Inference first: scripts/instance/ch_mmdet_test_then_eval.template.sh
#   runs SSD + FCOS (tools/test.py) then eval for both.
#
#   export VAL_JSON=... OUT_DIR=...
#   bash scripts/instance/run_eval_remote.sh /abs/dt.json tag
#
# Uses PYTHON (default: python3). On Vast, activate venv or set e.g.
#   export PYTHON=/workspace/venv-mmlab/bin/python3
# This script auto-picks that path if it exists and PYTHON is unset.
#
# Optional: EVAL_PY=/path/to/other/eval_coco_predictions.py
# Optional: METRICS_JSON=... PATCH_JSON=... (override default OUT_DIR/metrics_<tag>.json)
# Optional: EVAL_PATCH_NOTE_LINES=/path/to.txt — non-empty, non-# lines → repeated --patch-note
# DT JSON: list of {image_id, category_id, bbox [xywh], score} or {"annotations":[...]}.

VAL_JSON="${VAL_JSON:?Set VAL_JSON or source env.template.sh}"

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CVROOT="$(cd "$HERE/../.." && pwd)"
EVAL_PY="${EVAL_PY:-$CVROOT/scripts/eval_coco_predictions.py}"
if [[ ! -f "$EVAL_PY" ]]; then
  echo "Missing: $EVAL_PY" >&2
  echo "Clone this repo on the GPU box, e.g.:" >&2
  echo "  git clone https://github.com/GadzhiAskhabaliev/CV-MMdetect.git /workspace/repos/CV-MMdetect" >&2
  echo "Then: export EVAL_PY=/workspace/repos/CV-MMdetect/scripts/eval_coco_predictions.py" >&2
  echo "  or run: bash /workspace/repos/CV-MMdetect/scripts/instance/run_eval_remote.sh ..." >&2
  exit 1
fi

OUT_DIR="${OUT_DIR:-/tmp}"

DT_JSON="$1"
TAG="${2:-model}"

MET="${METRICS_JSON:-$OUT_DIR/metrics_${TAG}.json}"
PATCH="${PATCH_JSON:-$OUT_DIR/patch_${TAG}.json}"

ARGS=(
  --gt-json "$VAL_JSON"
  --dt-json "$DT_JSON"
  --strict
  --precision-score-thr "${PRECISION_SCORE_THR:-0.5}"
  --precision-iou-thr "${PRECISION_IOU_THR:-0.5}"
  --out-metrics-json "$MET"
  --out-patch-json "$PATCH"
)

ARGS+=(--greedy-iou-thrs "${GREEDY_IOU_THRS:-0.25,0.5,0.75}" --coco-pr-recall "${COCO_PR_RECALL:-0.5}")

if [[ -n "${EVAL_PATCH_NOTE_LINES:-}" && -f "$EVAL_PATCH_NOTE_LINES" ]]; then
  while IFS= read -r line || [[ -n "${line:-}" ]]; do
    [[ -z "${line// }" ]] && continue
    [[ "$line" =~ ^[[:space:]]*# ]] && continue
    ARGS+=(--patch-note "$line")
  done < "$EVAL_PATCH_NOTE_LINES"
fi

if [[ -z "${PYTHON:-}" ]] && [[ -x /workspace/venv-mmlab/bin/python3 ]]; then
  PYTHON=/workspace/venv-mmlab/bin/python3
fi
PYTHON="${PYTHON:-python3}"
"$PYTHON" "$EVAL_PY" "${ARGS[@]}"

echo "OK metrics -> $MET patch -> $PATCH"
