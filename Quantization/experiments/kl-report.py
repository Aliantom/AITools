"""Turn llama-perplexity --kl-divergence logs into one Markdown table (stdout) for the experiment note.
Run: python3 -I kl_report.py <results dir> <quants dir> <models dir> <ollama blob path>
"""
import pathlib, re, sys

FIELDS = [("Mean PPL(Q)", r"Mean PPL\(Q\)\s*:\s*([\d.]+)"), ("Mean KLD", r"Mean\s+KLD:\s*([\d.]+)"),
          ("Median KLD", r"Median\s+KLD:\s*([\d.]+)"), ("KLD 99%", r"KLD_99\s*:\s*([\d.]+)"),
          ("Same top p", r"Same top p:\s*([\d.]+)"), ("Max KLD", r"Maximum KLD:\s*([\d.]+)")]


def size_gib(name: str, quants: pathlib.Path, models: pathlib.Path, blob: str) -> str:
    cands = {"UD-Q4_K_XL": models / "gemma-4-12b-it-UD-Q4_K_XL.gguf", "QAT-UD-Q4_K_XL": models / "gemma-4-12B-it-qat-UD-Q4_K_XL.gguf",
             "ollama-Q4_K_M": pathlib.Path(blob)}
    p = cands.get(name) or next(iter(quants.glob(f"gemma4-12b-{name}.gguf")), None)
    return f"{p.stat().st_size / 2**30:.2f}" if p and p.exists() else "?"


def main() -> None:
    results, quants, models, blob = (pathlib.Path(sys.argv[1]), pathlib.Path(sys.argv[2]), pathlib.Path(sys.argv[3]), sys.argv[4])
    rows = []
    for log in sorted(results.glob("kl-*.log")):
        name = log.stem[3:]
        text = log.read_text(errors="ignore")
        vals = [(re.search(rx, text).group(1) if re.search(rx, text) else "-") for _, rx in FIELDS]
        rows.append((name, size_gib(name.split("-kv")[0], quants, models, blob), vals))
    rows.sort(key=lambda r: float(r[2][1]) if r[2][1] != "-" else 9e9)
    print("| Quant | GiB | " + " | ".join(f for f, _ in FIELDS) + " |")
    print("|---|---|" + "---|" * len(FIELDS))
    for name, size, vals in rows:
        print(f"| {name} | {size} | " + " | ".join(vals) + " |")


if __name__ == "__main__":
    main()
