#!/usr/bin/env bash
set -euo pipefail
# After converting CrowdDet/Pedestron outputs to predictions_*.json on the instance:
#   source ~/bench.env   # or path to env.template populated copy
#   bash scripts/instance/run_eval_remote.sh \
#     /abs/path/to/predictions_crowddet_val.json \
#     crowddet_rcnn_emd_refine

VAL_JSON="${VAL_JSON:?Set VAL_JSON or source env.template.sh}"
STUDY_REPO="${STUDY_REPO:?Set STUDY_REPO}"
OUT_DIR="${OUT_DIR:-/tmp}"

DT_JSON="$1"
TAG="${2:-model}"

MET="$OUT_DIR/metrics_${TAG}.json"
PATCH="$OUT_DIR/patch_${TAG}.json"

python3 "$STUDY_REPO/scripts/eval_coco_predictions.py" \
  --gt-json "$VAL_JSON" \
  --dt-json "$DT_JSON" \
  --strict \
  --out-metrics-json "$MET" \
  --out-patch-json "$PATCH"

echo "OK metrics -> $MET patch -> $PATCH"
