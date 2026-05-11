# CrowdHuman val (MMDet FCOS + SSD) → study-совместимый eval → edge-репо

## Цель (одним абзацем)

Прогнать на **CrowdHuman val** два детектора — **FCOS** и **SSD** (MMDetection), получить метрики в том же протоколе, что **`real-time-people-detection-and-tracking-on-edge`** на **`main`** (`scripts/eval_coco_predictions.py`), и передать артефакты владельцу edge-репо, чтобы там можно было закоммитить записи в **`results/runs/*.json`** (и при необходимости логи в **`results/logs/`**).

Путь к каноническому **`val.json`** и детали бенча согласовать с владельцем edge-репо (**README**, **`benchmark_unified_cocoeval.md`** и т.п.).

## Что считается «сделано»

1. **Один общий GT** — тот же **`val.json`** (COCO instances), что использует study (тот же `images[].id`, что в DT).
2. **Два дампа предсказаний** (или один архив), канонические имена:
   - `fcos_crowdhuman_val_dt.json`
   - `ssd_crowdhuman_val_dt.json`  
   Формат: JSON-массив **или** `{"annotations":[...]}`. Каждая детекция: **`image_id`**, **`category_id`**, **`bbox`** `[x,y,w,h]` (xywh, пиксели), **`score`**.
3. **Два прогона eval** тем же скриптом и флагами, что в study (логика **`main`**, без альтернативных «eval»):

```bash
python3 scripts/eval_coco_predictions.py \
  --gt-json …/val.json \
  --dt-json …/fcos_crowdhuman_val_dt.json \
  --strict \
  --out-metrics-json …/metrics_fcos_crowdhuman_val.json \
  --out-patch-json …/patch_fcos_crowdhuman_val.json

python3 scripts/eval_coco_predictions.py \
  --gt-json …/val.json \
  --dt-json …/ssd_crowdhuman_val_dt.json \
  --strict \
  --out-metrics-json …/metrics_ssd_crowdhuman_val.json \
  --out-patch-json …/patch_ssd_crowdhuman_val.json
```

При необходимости повторяй **`--patch-note`** (см. `--help`): конфиг, чекпоинт, пороги score/NMS, точная команда дампа, опционально FPS (eval его не считает).

В **`patch.json`** должны быть **`metrics`** с ключами как у study: **`AP25`**, **`AP50`**, **`AP75`**, **`AP50-95`**, **`recall`**, **`coco_*`**, **`precision_iou*`**, **`recall_iou*`**, **`fdr_iou*`**, **`precision`**, **`fdr`**, и осмысленные **`notes`**.

**Не путать:** цифры только из **`tools/test.py`** / встроенного COCOeval в MMDet **без** нашего **`eval_coco_predictions.py`** с таблицей study **могут расходиться** — для бенча нужен именно этот скрипт.

## Что прислать владельцу edge-репо (минимум)

- оба **`…_patch.json`** (или один **zip**);
- в сообщении: **команды** дампа + eval и **версии** (`torch`, `mmdet`, `mmcv`, `pycocotools`), например:

```bash
source /path/to/venv/bin/activate
python -c "import torch; print('torch', torch.__version__)"
pip show mmdet mmcv | sed -n '1,6p'
python -c "import pycocotools; print('pycocotools', getattr(pycocotools, '__version__', 'n/a'))"
```

- по желанию сами **DT JSON** (часто тяжёлые) — ссылка на облако / не коммитить в git, достаточно метрик в patch.

## Что сделает владелец в edge-репо

Для каждой модели завести или обновить **`results/runs/<slug>.json`** (`backend: mmdet`, `model`, weights, …) и выполнить:

```bash
python3 scripts/bench_runner.py --merge-json results/runs/<slug>.json \
  --patch-json /path/to/patch_<model>_crowdhuman_val.json
```

затем **commit** + **push**.

## Автоматизация в CV-MMdetect

Шаблон пайплайна (инстанс с GPU): **`scripts/instance/ch_mmdet_test_then_eval.template.sh`** — дамп MMDet → копии в **`ssd_crowdhuman_val_dt.json` / `fcos_crowdhuman_val_dt.json`** → eval → **`patch_*_crowdhuman_val.json`** в **`OUT_DIR`**.
