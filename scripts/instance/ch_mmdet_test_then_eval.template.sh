#!/usr/bin/env bash
# shellcheck disable=SC2016,SC2034
set -euo pipefail
#
# Order: (1) MMDetection tools/test.py must produce a COCO-style bbox JSON
#         (list of {image_id, category_id, bbox, score} or mmcv dump).
#        (2) scripts/eval_coco_predictions.py (via run_eval_remote.sh).
#
# Copy on the GPU box, fill CONFIG / CKPT / paths, chmod +x, run.
# Docs: https://mmdetection.readthedocs.io/en/v3.3.0/user_guides/test.html
#       (CocoMetric format_only + outfile_prefix → *.bbox.json)

: "${MMDET_ROOT:=/workspace/repos/mmdetection}"
: "${PYTHON:=/workspace/venv-mmlab/bin/python3}"
: "${VAL_JSON:=/workspace/data/crowdhuman_bridge/CrowdHuman/annotations/val.json}"
: "${CH_IMG_PREFIX:=/workspace/data/crowdhuman_bridge/CrowdHuman/CrowdHuman_val/Images/}"
: "${WORKDIR:=/workspace/artifacts/mmdet_ch_work}"
: "${OUT_PREFIX:=/workspace/artifacts/ch_val_dump}"
: "${CV_MMDETECT:=/workspace/repos/CV-MMdetect}"
: "${EVAL_TAG:=ssd300_ch}"

# --- set these ---
CONFIG="${CONFIG:?export CONFIG=/path/to/mmdetection/configs/.../*.py}"
CKPT="${CKPT:?export CKPT=/path/to/weights.pth}"

mkdir -p "$WORKDIR" "$(dirname "$OUT_PREFIX")"

echo "== Step 1: MMDet test (dump COCO bbox JSON) =="
cd "$MMDET_ROOT"
"$PYTHON" tools/test.py "$CONFIG" "$CKPT" \
  --work-dir "$WORKDIR" \
  --cfg-options \
  test_dataloader.dataset.data_root="" \
  test_dataloader.dataset.ann_file="$VAL_JSON" \
  test_dataloader.dataset.data_prefix.img="${CH_IMG_PREFIX}/" \
  val_dataloader.dataset.data_root="" \
  val_dataloader.dataset.ann_file="$VAL_JSON" \
  val_dataloader.dataset.data_prefix.img="${CH_IMG_PREFIX}/" \
  test_evaluator.type=CocoMetric \
  test_evaluator.format_only=True \
  test_evaluator.outfile_prefix="$OUT_PREFIX" \
  val_evaluator.type=CocoMetric \
  val_evaluator.format_only=True \
  val_evaluator.outfile_prefix="$OUT_PREFIX"

# MMDet usually writes "${OUT_PREFIX}.bbox.json" (and .segm.json if instance seg).
DT_JSON="${OUT_PREFIX}.bbox.json"
if [[ ! -f "$DT_JSON" ]]; then
  echo "Expected DT at: $DT_JSON — not found. Search:" >&2
  find "$WORKDIR" "$MMDET_ROOT/work_dirs" "$(dirname "$OUT_PREFIX")" \
    -name '*.bbox.json' 2>/dev/null | head -20 >&2 || true
  exit 1
fi

echo "== Step 2: study-style eval (CV-MMdetect) =="
export VAL_JSON OUT_DIR="${OUT_DIR:-/workspace/artifacts}"
mkdir -p "$OUT_DIR"
bash "$CV_MMDETECT/scripts/instance/run_eval_remote.sh" "$DT_JSON" "$EVAL_TAG"

echo "Done. DT=$DT_JSON"
