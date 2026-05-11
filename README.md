# CV-MMdetect

Utilities and reproducible scripts for running MMDetection detectors on CrowdHuman val,
evaluating with the study-compatible protocol, and preparing merge-ready artifacts for
the edge benchmark repository.

## Scope

This repository contains:

- `scripts/eval_coco_predictions.py` - study-compatible evaluation (`AP25/AP50/AP75/AP50-95`,
  `recall`, `coco_*`, `precision_iou*`, `recall_iou*`, `fdr*`, `precision`, `fdr`)
- `scripts/instance/ch_mmdet_test_then_eval.template.sh` - end-to-end instance pipeline
  (SSD + FCOS dump -> eval -> patch/metrics artifacts)
- `scripts/instance/run_eval_remote.sh` - single-run wrapper for eval
- `results/runs/*.json` - canonical run templates for bench merge
- `results/packs/crowdhuman_val_2026-05-11/` - saved `patch_*` and `metrics_*` artifacts
- `results/logs/crowdhuman_val_run_2026-05-11.log` - captured terminal run log
- docs with benchmark summary and handoff checklist

## Quick Start (Instance)

Run SSD + FCOS and produce eval artifacts:

```bash
source /workspace/venv-mmlab/bin/activate
git -C /workspace/repos/CV-MMdetect pull
export SSD_CONFIG=/workspace/repos/mmdetection/configs/ssd/ssd300_coco.py
export FCOS_CONFIG=/workspace/repos/mmdetection/configs/fcos/fcos_r50-caffe_fpn_gn-head_1x_coco.py
export VAL_JSON=/workspace/data/crowdhuman_bridge/CrowdHuman/annotations/val.json
export CH_IMG_PREFIX=/workspace/data/crowdhuman_bridge/CrowdHuman/CrowdHuman_val/Images/
export OUT_DIR=/workspace/artifacts
bash /workspace/repos/CV-MMdetect/scripts/instance/ch_mmdet_test_then_eval.template.sh
```

Expected outputs under `OUT_DIR`:

- `ssd_crowdhuman_val_dt.json`
- `fcos_crowdhuman_val_dt.json`
- `metrics_ssd_crowdhuman_val.json`
- `metrics_fcos_crowdhuman_val.json`
- `patch_ssd_crowdhuman_val.json`
- `patch_fcos_crowdhuman_val.json`

## Bench Merge (Edge Repo)

In the edge benchmark repository:

```bash
python3 scripts/bench_runner.py --merge-json results/runs/ssd300_crowdhuman.json --patch-json /path/to/patch_ssd_crowdhuman_val.json
python3 scripts/bench_runner.py --merge-json results/runs/fcos_r50_crowdhuman.json --patch-json /path/to/patch_fcos_crowdhuman_val.json
```

## Notes

- The two large DT JSON files are intentionally not committed to GitHub due to size limits.
- Patch and metrics artifacts are committed under `results/packs/crowdhuman_val_2026-05-11/`.
- See `docs/crowdhuman_val_benchmark_2026-05-11.md` for reported metrics.
