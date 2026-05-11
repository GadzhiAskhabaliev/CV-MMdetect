# CrowdHuman Val (MMDet SSD + FCOS) Study-Compatible Deliverable

## Goal

Run **SSD** and **FCOS** on **CrowdHuman val**, evaluate with the same protocol as
`real-time-people-detection-and-tracking-on-edge` (`scripts/eval_coco_predictions.py` on
`main`), and hand over artifacts that can be merged into edge repo run files under
`results/runs/*.json` (optionally with raw logs in `results/logs/`).

Use the same canonical GT `val.json` as the study benchmark.

## Done Criteria

1. One shared GT file (`val.json`, COCO instances) with consistent `images[].id`.
2. Two detection dumps:
   - `fcos_crowdhuman_val_dt.json`
   - `ssd_crowdhuman_val_dt.json`
   Format: JSON list (or `{"annotations":[...]}`), fields:
   `image_id`, `category_id`, `bbox` (`[x,y,w,h]`), `score`.
3. Two eval runs with study-compatible script:

```bash
python3 scripts/eval_coco_predictions.py \
  --gt-json /path/to/val.json \
  --dt-json /path/to/fcos_crowdhuman_val_dt.json \
  --strict \
  --out-metrics-json /path/to/metrics_fcos_crowdhuman_val.json \
  --out-patch-json /path/to/patch_fcos_crowdhuman_val.json

python3 scripts/eval_coco_predictions.py \
  --gt-json /path/to/val.json \
  --dt-json /path/to/ssd_crowdhuman_val_dt.json \
  --strict \
  --out-metrics-json /path/to/metrics_ssd_crowdhuman_val.json \
  --out-patch-json /path/to/patch_ssd_crowdhuman_val.json
```

`patch.json` must include `metrics` keys expected by study:
`AP25`, `AP50`, `AP75`, `AP50-95`, `recall`, `coco_*`, `precision_iou*`,
`recall_iou*`, `fdr_iou*`, `precision`, `fdr`.

Use `--patch-note` as needed for reproducibility (config, checkpoint, thresholds, command, FPS).

## Minimum Handover Package

- `patch_ssd_crowdhuman_val.json`
- `patch_fcos_crowdhuman_val.json`
- command history and version info (`torch`, `mmdet`, `mmcv`, `pycocotools`)
- optional: DT JSON files (or external link if large)

## Merge Step in Edge Repo

```bash
python3 scripts/bench_runner.py --merge-json results/runs/ssd300_crowdhuman.json \
  --patch-json /path/to/patch_ssd_crowdhuman_val.json
python3 scripts/bench_runner.py --merge-json results/runs/fcos_r50_crowdhuman.json \
  --patch-json /path/to/patch_fcos_crowdhuman_val.json
```

Then commit and push.

## Automation in This Repo

Use:

- `scripts/instance/ch_mmdet_test_then_eval.template.sh` (full SSD+FCOS pipeline)
- `scripts/instance/run_eval_remote.sh` (single eval wrapper)
- `docs/crowdhuman_val_benchmark_2026-05-11.md` (captured benchmark summary)
- `results/logs/crowdhuman_val_run_2026-05-11.log` (captured terminal log)

Do not report only `tools/test.py` metrics without `eval_coco_predictions.py` output.
