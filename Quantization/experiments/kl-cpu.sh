#!/bin/bash
# Run D of experiment 001 (Amendment 3): KL on the CPU path only (-ngl 0, flash attention off), because the CUDA
# flash-attention path diverges from the CPU path for gemma4 (Q8_0 vs itself: mean KL 0.22 with FA on, 0.023 with FA
# off, 0.000 CPU vs CPU). Slices: the model's own answers (self) and code. Eight candidates. Slow but clean.
# Usage: bash kl_cpu.sh     (no GPU; ~10 CPU threads; about 40 minutes)
set -euo pipefail
BIN=${BIN:-/mnt/ai-storage/tools/llama.cpp-main/build/bin}
MODELS=${MODELS:-/mnt/ai-storage/models/gguf/gemma-4-12b-it}
WORK=${WORK:-/mnt/ai-storage/quant-eval/gemma-4-12b-it}
OLLAMA_BLOB=${OLLAMA_BLOB:-$(python3 -c "import json;d=json.load(open('/mnt/ai-storage/models/ollama/manifests/registry.ollama.ai/library/gemma4/12b'));print('/mnt/ai-storage/models/ollama/blobs/'+[l for l in d['layers'] if l['mediaType'].endswith('.model')][0]['digest'].replace(':','-'))")}
CTX=2048; THREADS=${THREADS:-10}
DEVFLAG=${DEVFLAG:--dev none}   # default: no GPU at all (slow, safe beside the night shift); DEVFLAG="" lets ggml use the GPU for matmuls while layers stay on the CPU (4x faster, still deterministic)
log() { echo "[$(date '+%H:%M:%S')] $*"; }
declare -A CAND=(
  [Q6_K]="$WORK/quants/gemma4-12b-Q6_K.gguf" [Q5_K_M]="$WORK/quants/gemma4-12b-Q5_K_M.gguf"
  [Q4_K_M-imat]="$WORK/quants/gemma4-12b-Q4_K_M-imat.gguf" [Q4_K_M]="$WORK/quants/gemma4-12b-Q4_K_M.gguf"
  [IQ4_XS-imat]="$WORK/quants/gemma4-12b-IQ4_XS-imat.gguf" [Q3_K_M-imat]="$WORK/quants/gemma4-12b-Q3_K_M-imat.gguf"
  [UD-Q4_K_XL]="$MODELS/gemma-4-12b-it-UD-Q4_K_XL.gguf" [QAT-UD-Q4_K_XL]="$MODELS/gemma-4-12B-it-qat-UD-Q4_K_XL.gguf"
  [ollama-Q4_K_M]="$OLLAMA_BLOB"
)
ORDER="Q6_K Q5_K_M UD-Q4_K_XL Q4_K_M-imat ollama-Q4_K_M Q4_K_M IQ4_XS-imat Q3_K_M-imat QAT-UD-Q4_K_XL"
for slice in ${SLICES:-self code}; do
  f="$WORK/slice-$slice.txt"; R="$WORK/results-cpu-$slice"; mkdir -p "$R"; ref="$WORK/ref-cpu-$slice.kld"
  if [[ ! -s $ref ]]; then
    log "[$slice] CPU reference logits from Q8_0"
    "$BIN/llama-perplexity" -m "$WORK/quants/gemma4-12b-Q8_0.gguf" -f "$f" --kl-divergence-base "$ref" -c $CTX -ngl 0 $DEVFLAG -fa off -t $THREADS > "$R/ref-Q8_0.log" 2>&1
  fi
  for name in $ORDER; do
    m=${CAND[$name]}; out="$R/kl-$name.log"
    [[ -s $out ]] && grep -q "Mean KLD" "$out" && continue
    log "[$slice] KL (CPU): $name"
    "$BIN/llama-perplexity" -m "$m" -f "$f" --kl-divergence-base "$ref" --kl-divergence -c $CTX -ngl 0 $DEVFLAG -fa off -t $THREADS > "$out" 2>&1 || log "FAILED $slice $name"
  done
  log "[$slice] report"; python3 -I "$(dirname "$0")/kl_report.py" "$R" "$WORK/quants" "$MODELS" "$OLLAMA_BLOB" > "$R/REPORT.md"
done
log "run D done"
