#!/usr/bin/env python3
"""
Convert CrowdDet tools/test.py dump JSONL -> unified DT JSON for eval_coco_predictions.py.

CrowdDet writes json-lines via lib/utils/misc_utils.save_json_lines: each line is one dict with:
  - "ID": CrowdHuman image id string (same as odgt record, files usually "{ID}.jpg")
  - "dtboxes": [{"box": [x, y, w, h], "score": float, ...}, ...]

GT bridge built by freeyolo_prepare_crowdhuman.py uses:
  file_name == f"{ID}.jpg"
  images[].id is sequential (NOT the CrowdHuman string ID).

DT contract:
  {"image_id": int, "category_id": int, "bbox": [x, y, w, h], "score": float}

Example:
  python3 scripts/coco_dt/crowddet_dump_jsonl_to_dt.py \\
    --val-json /abs/bridge/CrowdHuman/annotations/val.json \\
    --crowddet-jsonl /abs/CrowdDet/model/rcnn_emd_refine/outputs/eval_dump/dump-40.json \\
    --out-json /tmp/predictions_crowddet_val.json \\
    --score-thr 0.05

Dump path/name varies (-r resume suffix); pass the concrete dump-*.json path produced by test.py.
"""
from __future__ import annotations

import argparse
import json
from pathlib import Path


def _load_gt_image_ids(val_json: Path) -> dict[str, int]:
    data = json.loads(val_json.read_text(encoding="utf-8"))
    images = data.get("images") or []
    by_fname: dict[str, int] = {}
    for im in images:
        fn = im.get("file_name")
        iid = im.get("id")
        if not isinstance(fn, str) or not isinstance(iid, int):
            continue
        if fn in by_fname and by_fname[fn] != iid:
            raise SystemExit(f"Duplicate file_name with conflicting id: {fn!r}")
        by_fname[fn] = iid
    if not by_fname:
        raise SystemExit("val.json: no images with file_name/id")
    return by_fname


def main() -> None:
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--val-json", type=Path, required=True)
    p.add_argument("--crowddet-jsonl", type=Path, required=True, help="Path to dump-*.json from CrowdDet test.py")
    p.add_argument("--out-json", type=Path, required=True)
    p.add_argument("--category-id", type=int, default=1)
    p.add_argument("--score-thr", type=float, default=0.0, help="Drop dtboxes with score <= thr")
    args = p.parse_args()

    by_fname = _load_gt_image_ids(args.val_json.resolve())

    raw_lines = args.crowddet_jsonl.read_text(encoding="utf-8").splitlines()
    dt: list[dict] = []
    unknown_ids: list[str] = []
    missing_fname = 0

    for li, line in enumerate(raw_lines, start=1):
        line = line.strip()
        if not line:
            continue
        try:
            rec = json.loads(line)
        except json.JSONDecodeError as e:
            raise SystemExit(f"{args.crowddet_jsonl}:{li}: invalid JSON: {e}") from e

        cid_raw = rec.get("ID")
        if cid_raw is None:
            raise SystemExit(f"{args.crowddet_jsonl}:{li}: missing ID field")

        ch_id = str(cid_raw)
        fname_jpg = ch_id if ch_id.endswith(".jpg") else f"{ch_id}.jpg"

        image_id = by_fname.get(fname_jpg)
        if image_id is None:
            unknown_ids.append(ch_id)
            missing_fname += 1
            continue

        for det in rec.get("dtboxes") or []:
            box = det.get("box")
            score = det.get("score")
            if not isinstance(box, (list, tuple)) or len(box) != 4:
                raise SystemExit(f"{args.crowddet_jsonl}:{li}: dtboxes[].box must be length-4 list")
            if not isinstance(score, (int, float)):
                raise SystemExit(f"{args.crowddet_jsonl}:{li}: dtboxes[].score must be numeric")

            if float(score) <= args.score_thr:
                continue

            x, y, w, h = (float(box[0]), float(box[1]), float(box[2]), float(box[3]))
            dt.append(
                {
                    "image_id": int(image_id),
                    "category_id": int(args.category_id),
                    "bbox": [x, y, w, h],
                    "score": float(score),
                }
            )

    args.out_json.parent.mkdir(parents=True, exist_ok=True)
    args.out_json.write_text(json.dumps(dt), encoding="utf-8")

    summary = {
        "lines_read": len([ln for ln in raw_lines if ln.strip()]),
        "predictions": len(dt),
        "skipped_unknown_image_id": missing_fname,
    }
    if unknown_ids:
        summary["unknown_sample"] = unknown_ids[:20]
        summary["unknown_note"] = (
            "IDs not found as file_name in val.json — GT bridge mismatch or wrong dump split."
        )
    print(json.dumps(summary, indent=2))


if __name__ == "__main__":
    main()
