#!/usr/bin/env bash
# CrowdHuman val: SSD + FCOS → dump COCO bbox JSON (MMDet test.py) → eval (CV-MMdetect).
#
# On the GPU box: copy, set SSD_*/FCOS_* exports, run:
#   bash ch_mmdet_test_then_eval.template.sh
#
# You need: bridge val.json, Images/, mmdetection clone, venv with mmdet+mmcv, checkpoints.
# If --cfg-options fails, align keys with your config (some bases use only val_evaluator).

set -euo pipefail

: "${MMDET_ROOT:=/workspace/repos/mmdetection}"
: "${PYTHON:=/workspace/venv-mmlab/bin/python3}"
: "${VAL_JSON:=/workspace/data/crowdhuman_bridge/CrowdHuman/annotations/val.json}"
: "${CH_IMG_PREFIX:=/workspace/data/crowdhuman_bridge/CrowdHuman/CrowdHuman_val/Images/}"
: "${WORKDIR:=/workspace/artifacts/mmdet_ch_work}"
: "${CV_MMDETECT:=/workspace/repos/CV-MMdetect}"
: "${OUT_DIR:=/workspace/artifacts}"

# --- checkpoints + configs (set on the instance) ---
SSD_CONFIG="${SSD_CONFIG:?export SSD_CONFIG=.../configs/ssd/ssd300_coco.py (or your path)}"
SSD_CKPT="${SSD_CKPT:?export SSD_CKPT=.../ssd300_*.pth}"
FCOS_CONFIG="${FCOS_CONFIG:?export FCOS_CONFIG=.../configs/fcos/fcos_r50_fpn_1x_coco.py (or your path)}"
FCOS_CKPT="${FCOS_CKPT:?export FCOS_CKPT=.../fcos_*.pth}"

OUT_SSD="${OUT_SSD:-$OUT_DIR/dump_ssd300_ch_val}"
OUT_FCOS="${OUT_FCOS:-$OUT_DIR/dump_fcos_ch_val}"

export VAL_JSON OUT_DIR

dump_bbox_json() {
  local config="$1" ckpt="$2" out_prefix="$3" work_sub="$4"
  mkdir -p "$WORKDIR/$work_sub" "$(dirname "$out_prefix")"
  echo "== MMDet test: $work_sub → ${out_prefix}.bbox.json ==" >&2
  ( cd "$MMDET_ROOT" && "$PYTHON" tools/test.py "$config" "$ckpt" \
    --work-dir "$WORKDIR/$work_sub" \
    --cfg-options \
      test_dataloader.dataset.data_root="" \
      test_dataloader.dataset.ann_file="$VAL_JSON" \
      test_dataloader.dataset.data_prefix.img="${CH_IMG_PREFIX}/" \
      val_dataloader.dataset.data_root="" \
      val_dataloader.dataset.ann_file="$VAL_JSON" \
      val_dataloader.dataset.data_prefix.img="${CH_IMG_PREFIX}/" \
      test_evaluator.type=CocoMetric \
      test_evaluator.format_only=True \
      test_evaluator.outfile_prefix="$out_prefix" \
      val_evaluator.type=CocoMetric \
      val_evaluator.format_only=True \
      val_evaluator.outfile_prefix="$out_prefix" )
  local dt="${out_prefix}.bbox.json"
  if [[ ! -f "$dt" ]]; then
    echo "Missing: $dt" >&2
    find "$WORKDIR/$work_sub" "$(dirname "$out_prefix")" -name '*.bbox.json' 2>/dev/null | head -20 >&2 || true
    exit 1
  fi
  echo "$dt"
}

run_eval_tag() {
  local dt_json="$1" tag="$2"
  echo "== eval_coco_predictions ($tag) ==" >&2
  mkdir -p "$OUT_DIR"
  bash "$CV_MMDETECT/scripts/instance/run_eval_remote.sh" "$dt_json" "$tag"
}

mkdir -p "$OUT_DIR" "$WORKDIR"

DT_SSD="$(dump_bbox_json "$SSD_CONFIG" "$SSD_CKPT" "$OUT_SSD" ssd_ch_val)"
run_eval_tag "$DT_SSD" "ssd300_ch"

DT_FCOS="$(dump_bbox_json "$FCOS_CONFIG" "$FCOS_CKPT" "$OUT_FCOS" fcos_ch_val)"
run_eval_tag "$DT_FCOS" "fcos_ch"

echo "All done."
echo "  SSD  DT: $DT_SSD   metrics: $OUT_DIR/metrics_ssd300_ch.json"
echo "  FCOS DT: $DT_FCOS  metrics: $OUT_DIR/metrics_fcos_ch.json"
