# CrowdHuman Val Benchmark (MMDet)

Run date: 2026-05-11  
Protocol: `scripts/eval_coco_predictions.py` (study-compatible)  
GT: `/workspace/data/crowdhuman_bridge/CrowdHuman/annotations/val.json`

## Models

- SSD config: `/workspace/repos/mmdetection/configs/ssd/ssd300_coco.py`
- SSD checkpoint: `/workspace/repos/mmdetection/ssd300_coco_20210803_015428-d231a06e.pth`
- FCOS config: `/workspace/repos/mmdetection/configs/fcos/fcos_r50-caffe_fpn_gn-head_1x_coco.py`
- FCOS checkpoint: `/workspace/repos/mmdetection/fcos_r50_caffe_fpn_gn-head_1x_coco-821213aa.pth`

## Main Metrics

### SSD (`ssd_crowdhuman_val`)

- AP25: `0.597575`
- AP50: `0.287404`
- AP75: `0.047252`
- AP50-95: `0.096474`
- recall (COCO AR 0.50:0.95, maxDets=100): `0.180983`
- precision (greedy iou50): `0.713180`
- fdr (greedy iou50): `0.286820`

### FCOS (`fcos_crowdhuman_val`)

- AP25: `0.542478`
- AP50: `0.328401`
- AP75: `0.110847`
- AP50-95: `0.144016`
- recall (COCO AR 0.50:0.95, maxDets=100): `0.293753`
- precision (greedy iou50): `0.771363`
- fdr (greedy iou50): `0.228637`

## Produced Artifacts (on instance)

- DT:
  - `/workspace/artifacts/ssd_crowdhuman_val_dt.json`
  - `/workspace/artifacts/fcos_crowdhuman_val_dt.json`
- eval metrics:
  - `/workspace/artifacts/metrics_ssd_crowdhuman_val.json`
  - `/workspace/artifacts/metrics_fcos_crowdhuman_val.json`
- eval patches:
  - `/workspace/artifacts/patch_ssd_crowdhuman_val.json`
  - `/workspace/artifacts/patch_fcos_crowdhuman_val.json`

## Bench Merge Commands (edge repo)

```bash
python3 scripts/bench_runner.py --merge-json results/runs/ssd300_crowdhuman.json --patch-json /workspace/artifacts/patch_ssd_crowdhuman_val.json
python3 scripts/bench_runner.py --merge-json results/runs/fcos_r50_crowdhuman.json --patch-json /workspace/artifacts/patch_fcos_crowdhuman_val.json
```

## Notes

- SSD and FCOS were both run end-to-end (`tools/test.py` dump + `eval_coco_predictions.py`).
- Full terminal trace is captured in `results/logs/crowdhuman_val_run_2026-05-11.log`.
