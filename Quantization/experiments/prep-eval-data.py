"""Build the held-out evaluation text and the (disjoint) calibration text for quantization KL tests.

Eval  (eval.txt):  wikitext-2 TEST slice + ultrachat TEST rows 0-149 rendered as plain transcripts + Python from gguf-py (b11530 tree).
Calib (calib.txt): wikitext-2 TRAIN slice + ultrachat TEST rows 2000-2599 + Python from the converter tree (conversion/), disjoint files.
The two never share a row or a file. Sizes are capped in characters so the run stays short.

Run (ai-lab venv has pyarrow):
  ~/ai-lab/.venv/bin/python -I prep_eval_data.py --data /mnt/ai-storage/quant-eval/data \
      --code-eval /mnt/ai-storage/tools/llama.cpp-b11530/src/gguf-py --code-calib /mnt/ai-storage/tools/llama.cpp-b11530/src/conversion \
      --out /mnt/ai-storage/quant-eval/gemma-4-12b-it
"""
import argparse, pathlib, random
import pyarrow.parquet as pq


def wikitext(path: pathlib.Path, chars: int, skip: int = 0) -> str:
    rows = pq.read_table(path).column("text").to_pylist()
    text = "".join(r for r in rows if r.strip())
    return text[skip:skip + chars]


def chats(path: pathlib.Path, start: int, stop: int, chars: int) -> str:
    rows = pq.read_table(path).column("messages").to_pylist()[start:stop]
    out = []
    for msgs in rows:
        out.append("\n".join(f"{m['role'].capitalize()}: {m['content'].strip()}" for m in msgs) + "\n\n")
    return "".join(out)[:chars]


def code(root: pathlib.Path, exts: tuple[str, ...], chars: int, seed: int = 0) -> str:
    files = sorted(p for p in root.rglob("*") if p.suffix in exts and p.is_file())
    random.Random(seed).shuffle(files)
    out, total = [], 0
    for p in files:
        t = p.read_text(encoding="utf-8", errors="ignore")
        out.append(f"# file: {p.name}\n{t}\n\n"); total += len(t)
        if total >= chars:
            break
    return "".join(out)[:chars]


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--data", type=pathlib.Path, required=True)
    ap.add_argument("--code-eval", type=pathlib.Path, required=True)
    ap.add_argument("--code-calib", type=pathlib.Path, required=True)
    ap.add_argument("--out", type=pathlib.Path, required=True)
    a = ap.parse_args()
    a.out.mkdir(parents=True, exist_ok=True)
    wt_test = a.data / "wikitext-2-raw-v1" / "test-00000-of-00001.parquet"
    wt_train = a.data / "wikitext-2-raw-v1" / "train-00000-of-00001.parquet"
    uc = next((a.data / "data").glob("test_sft-*.parquet"))
    # ~ 4 chars per token: 40k + 40k + 25k chars ≈ 26k tokens of eval
    ev = wikitext(wt_test, 40_000) + chats(uc, 0, 150, 40_000) + code(a.code_eval, (".py",), 25_000)
    # calibration ≈ 60k tokens, all disjoint from eval
    cb = wikitext(wt_train, 90_000, skip=10_000) + chats(uc, 2000, 2600, 90_000) + code(a.code_calib, (".py",), 60_000, seed=1)
    (a.out / "eval.txt").write_text(ev, encoding="utf-8")
    (a.out / "calib.txt").write_text(cb, encoding="utf-8")
    print(f"eval.txt {len(ev)} chars, calib.txt {len(cb)} chars -> {a.out}")


if __name__ == "__main__":
    main()
