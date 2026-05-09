#!/usr/bin/env python3
"""Emit CrowdHuman ID -> COCO image_id table from bridge val.json (for debugging on instances).

Example:
  python3 scripts/coco_dt/dump_gt_id_table.py \\
    --val-json /abs/bridge/CrowdHuman/annotations/val.json \\
    --out-tsv /tmp/ch_id_to_image_id.tsv
"""
from __future__ import annotations

import argparse
import csv
import json
from pathlib import Path


def main() -> None:
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--val-json", type=Path, required=True)
    p.add_argument("--out-tsv", type=Path, default=None, help="Optional TSV: crowdhuman_id\\timage_id\\tfile_name")
    args = p.parse_args()

    data = json.loads(args.val_json.read_text(encoding="utf-8"))
    rows: list[tuple[str, int, str]] = []
    for im in data.get("images") or []:
        fn = im.get("file_name")
        iid = im.get("id")
        if not isinstance(fn, str) or not isinstance(iid, int):
            continue
        if not fn.endswith(".jpg"):
            raise SystemExit(f"Unexpected file_name (expected *.jpg): {fn!r}")
        ch_id = fn[:-4]
        rows.append((ch_id, iid, fn))

    rows.sort(key=lambda r: r[1])
    print(json.dumps({"images": len(rows), "val_json": str(args.val_json.resolve())}, indent=2))

    if args.out_tsv:
        args.out_tsv.parent.mkdir(parents=True, exist_ok=True)
        with args.out_tsv.open("w", encoding="utf-8", newline="") as f:
            w = csv.writer(f, delimiter="\t")
            w.writerow(["crowdhuman_id", "coco_image_id", "file_name"])
            for ch_id, iid, fn in rows:
                w.writerow([ch_id, iid, fn])
        print(f"wrote {args.out_tsv}")


if __name__ == "__main__":
    main()
