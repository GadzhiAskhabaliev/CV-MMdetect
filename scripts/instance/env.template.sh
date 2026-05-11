# shellcheck shell=bash
# Copy on the GPU instance: cp scripts/instance/env.template.sh ~/bench.env && nano ~/bench.env && source ~/bench.env

export CUDA_VISIBLE_DEVICES="${CUDA_VISIBLE_DEVICES:-0}"

# For eval: use MMDet venv so numpy/pycocotools exist, e.g.
#   source /workspace/venv-mmlab/bin/activate
#   or: export PYTHON=/workspace/venv-mmlab/bin/python3

# CrowdHuman source (official layout): Images/*.jpg + annotation_val.odgt
export CROWDHUMAN_ROOT="${CROWDHUMAN_ROOT:-/workspace/data/crowdhuman}"

# Bridge tree built by freeyolo_prepare_crowdhuman.py (contains annotations/val.json + symlink to Images)
export FREEYOLO_CH_BRIDGE="${FREEYOLO_CH_BRIDGE:-/workspace/data/crowdhuman_bridge}"

export VAL_JSON="${VAL_JSON:-$FREEYOLO_CH_BRIDGE/CrowdHuman/annotations/val.json}"

# Cloned repos on instance (adjust paths)
export CROWDDET_ROOT="${CROWDDET_ROOT:-/workspace/repos/CrowdDet}"
export PEDESTRON_ROOT="${PEDESTRON_ROOT:-/workspace/repos/Pedestron}"

# CV-MMdetect (eval lives here). If missing on the instance:
#   git clone https://github.com/GadzhiAskhabaliev/CV-MMdetect.git /workspace/repos/CV-MMdetect
export CV_MMDETECT="${CV_MMDETECT:-/workspace/repos/CV-MMdetect}"

# Optional: external study repo (not required for eval; CV-MMdetect ships scripts/eval_coco_predictions.py)
export STUDY_REPO="${STUDY_REPO:-/workspace/repos/real-time-people-detection-and-tracking-on-edge}"

export OUT_DIR="${OUT_DIR:-/workspace/artifacts/group_b}"
mkdir -p "$OUT_DIR"
