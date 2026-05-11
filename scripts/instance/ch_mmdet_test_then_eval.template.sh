#!/usr/bin/env bash
# CrowdHuman val: SSD + FCOS (MMDet test.py dump) → canonical DT filenames →
# eval (same protocol as study main eval_coco_predictions.py) → patch/metrics for edge bench.
#
# Deliverable names match docs/crowdhuman_study_deliverable.md
# On GPU: set SSD_* / FCOS_* then:  bash ch_mmdet_test_then_eval.template.sh

set -euo pipefail

: "${MMDET_ROOT:=/workspace/repos/mmdetection}"
: "${PYTHON:=/workspace/venv-mmlab/bin/python3}"
: "${VAL_JSON:=/workspace/data/crowdhuman_bridge/CrowdHuman/annotations/val.json}"
: "${CH_IMG_PREFIX:=/workspace/data/crowdhuman_bridge/CrowdHuman/CrowdHuman_val/Images/}"
: "${WORKDIR:=/workspace/artifacts/mmdet_ch_work}"
: "${CV_MMDETECT:=/workspace/repos/CV-MMdetect}"
: "${OUT_DIR:=/workspace/artifacts}"

SSD_CONFIG="${SSD_CONFIG:?export SSD_CONFIG=.../configs/ssd/....py}"
SSD_CKPT="${SSD_CKPT:?export SSD_CKPT=.../ssd300_*.pth}"
FCOS_CONFIG="${FCOS_CONFIG:?export FCOS_CONFIG=.../configs/fcos/....py}"
FCOS_CKPT="${FCOS_CKPT:?export FCOS_CKPT=.../fcos_*.pth}"

OUT_SSD="${OUT_SSD:-$OUT_DIR/mmdet_dump_prefix_ssd}"
OUT_FCOS="${OUT_FCOS:-$OUT_DIR/mmdet_dump_prefix_fcos}"

export VAL_JSON OUT_DIR

write_patch_notes() {
  local model_name="$1" cfg="$2" ckpt="$3" dt_json="$4" dump_prefix="$5" work_sub="$6"
  cat <<EOF
backend=mmdet model=${model_name} split=CrowdHuman_val
config=${cfg}
checkpoint=${ckpt}
GT_ann=${VAL_JSON}
img_prefix=${CH_IMG_PREFIX}
dt_json=${dt_json}
mmdet_dump_outfile_prefix=${dump_prefix} work_subdir=${work_sub}
EOF
  echo "--- versions ---"
  "$PYTHON" -c "import torch; print('torch', torch.__version__)" 2>/dev/null || echo "torch n/a"
  "$PYTHON" -c "import importlib.metadata as m; print('mmdet', m.version('mmdet'))" 2>/dev/null || echo "mmdet n/a"
  "$PYTHON" -c "import importlib.metadata as m; print('mmcv', m.version('mmcv'))" 2>/dev/null || echo "mmcv n/a"
  "$PYTHON" -c "import importlib.metadata as m; print('pycocotools', m.version('pycocotools'))" 2>/dev/null || echo "pycocotools n/a"
}

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
      test_evaluator.ann_file="$VAL_JSON" \
      test_evaluator.format_only=True \
      test_evaluator.outfile_prefix="$out_prefix" \
      val_evaluator.type=CocoMetric \
      val_evaluator.ann_file="$VAL_JSON" \
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

run_eval_deliverable() {
  local dt_canon="$1" notes_file="$2" metrics_out="$3" patch_out="$4" tag="$5"
  echo "== eval_coco_predictions ($tag) → $(basename "$patch_out") ==" >&2
  mkdir -p "$OUT_DIR"
  export METRICS_JSON="$metrics_out" PATCH_JSON="$patch_out" EVAL_PATCH_NOTE_LINES="$notes_file"
  bash "$CV_MMDETECT/scripts/instance/run_eval_remote.sh" "$dt_canon" "$tag"
  unset METRICS_JSON PATCH_JSON EVAL_PATCH_NOTE_LINES
}

mkdir -p "$OUT_DIR" "$WORKDIR"

# --- SSD ---
DT_SSD_RAW="$(dump_bbox_json "$SSD_CONFIG" "$SSD_CKPT" "$OUT_SSD" ssd_ch_val)"
SSD_CANON="$OUT_DIR/ssd_crowdhuman_val_dt.json"
cp -f "$DT_SSD_RAW" "$SSD_CANON"
write_patch_notes "SSD300" "$SSD_CONFIG" "$SSD_CKPT" "$SSD_CANON" "$OUT_SSD" ssd_ch_val > "$WORKDIR/patch_notes_ssd.txt"
run_eval_deliverable "$SSD_CANON" "$WORKDIR/patch_notes_ssd.txt" \
  "$OUT_DIR/metrics_ssd_crowdhuman_val.json" \
  "$OUT_DIR/patch_ssd_crowdhuman_val.json" \
  ssd_crowdhuman_val

# --- FCOS ---
DT_FCOS_RAW="$(dump_bbox_json "$FCOS_CONFIG" "$FCOS_CKPT" "$OUT_FCOS" fcos_ch_val)"
FCOS_CANON="$OUT_DIR/fcos_crowdhuman_val_dt.json"
cp -f "$DT_FCOS_RAW" "$FCOS_CANON"
write_patch_notes "FCOS" "$FCOS_CONFIG" "$FCOS_CKPT" "$FCOS_CANON" "$OUT_FCOS" fcos_ch_val > "$WORKDIR/patch_notes_fcos.txt"
run_eval_deliverable "$FCOS_CANON" "$WORKDIR/patch_notes_fcos.txt" \
  "$OUT_DIR/metrics_fcos_crowdhuman_val.json" \
  "$OUT_DIR/patch_fcos_crowdhuman_val.json" \
  fcos_crowdhuman_val

echo "Done. Hand off to edge repo owner:" >&2
echo "  DT:       $SSD_CANON" >&2
echo "            $FCOS_CANON" >&2
echo "  patches:  $OUT_DIR/patch_ssd_crowdhuman_val.json" >&2
echo "            $OUT_DIR/patch_fcos_crowdhuman_val.json" >&2
echo "  bench:    python3 scripts/bench_runner.py --merge-json results/runs/<slug>.json --patch-json <path>" >&2
