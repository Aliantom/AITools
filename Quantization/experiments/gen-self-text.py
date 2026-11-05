"""Run C of experiment 001: build an in-distribution eval text from the model's own answers.

Asks the running Ollama gemma4:12b (thinking off, temperature 0) 40 ultrachat user questions and writes the
exchanges in Gemma's turn template to slice-self.txt. Scoring the quants on text the model itself produced
measures quantization drift where the model is confident, instead of on Wikipedia text where it is lost.
Run:  ~/ai-lab/.venv/bin/python -I gen_self_text.py --out /mnt/ai-storage/quant-eval/gemma-4-12b-it/slice-self.txt
"""
import argparse, json, pathlib, urllib.request
import pyarrow.parquet as pq

UC = "/mnt/ai-storage/quant-eval/data/data/test_sft-00000-of-00001-f7dfac4afe5b93f4.parquet"


def ask(model: str, question: str, max_tokens: int) -> str:
    body = json.dumps({"model": model, "messages": [{"role": "user", "content": question}], "stream": False,
                       "think": False, "options": {"temperature": 0, "num_predict": max_tokens, "num_ctx": 4096},
                       "keep_alive": "1m"}).encode()
    req = urllib.request.Request("http://127.0.0.1:11434/api/chat", data=body, headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(req, timeout=600) as r:
        return json.load(r)["message"]["content"].strip()


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--model", default="gemma4:12b")
    ap.add_argument("--n", type=int, default=40)
    ap.add_argument("--max-tokens", type=int, default=350)
    ap.add_argument("--start", type=int, default=5000, help="ultrachat test row offset (disjoint from eval and calib rows)")
    ap.add_argument("--out", type=pathlib.Path, required=True)
    a = ap.parse_args()
    rows = pq.read_table(UC).column("messages").to_pylist()[a.start:a.start + a.n]
    out = []
    for i, msgs in enumerate(rows):
        q = next(m["content"].strip() for m in msgs if m["role"] == "user")
        ans = ask(a.model, q, a.max_tokens)
        out.append(f"<start_of_turn>user\n{q}<end_of_turn>\n<start_of_turn>model\n{ans}<end_of_turn>\n")
        print(f"{i + 1}/{len(rows)} {len(ans)} chars", flush=True)
    text = "".join(out)
    a.out.write_text(text, encoding="utf-8")
    print(f"wrote {a.out} ({len(text)} chars)")


if __name__ == "__main__":
    main()
