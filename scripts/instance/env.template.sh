# shellcheck shell=bash
# Copy on the GPU instance: cp scripts/instance/env.template.sh ~/bench.env && nano ~/bench.env && source ~/bench.env

export CUDA_VISIBLE_DEVICES="${CUDA_VISIBLE_DEVICES:-0}"

# CrowdHuman source (official layout): Images/*.jpg + annotation_val.odgt
export CROWDHUMAN_ROOT="${CROWDHUMAN_ROOT:-/workspace/data/crowdhuman}"

# Bridge tree built by freeyolo_prepare_crowdhuman.py (contains annotations/val.json + symlink to Images)
export FREEYOLO_CH_BRIDGE="${FREEYOLO_CH_BRIDGE:-/workspace/group_b/freeyolo_crowdhuman_bridge}"

export VAL_JSON="${VAL_JSON:-$FREEYOLO_CH_BRIDGE/CrowdHuman/annotations/val.json}"

# Cloned repos on instance (adjust paths)
export CROWDDET_ROOT="${CROWDDET_ROOT:-/workspace/repos/CrowdDet}"
export PEDESTRON_ROOT="${PEDESTRON_ROOT:-/workspace/repos/Pedestron}"

# Main study repo (eval script location)
export STUDY_REPO="${STUDY_REPO:-/workspace/repos/real-time-detection-and-tracking-on-edge}"

export OUT_DIR="${OUT_DIR:-/workspace/artifacts/group_b}"
mkdir -p "$OUT_DIR"
