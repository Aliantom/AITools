#!/bin/bash
# Run B of experiment 001 (Amendment 1): per-slice KL for every candidate, with the chat slice in Gemma's template.
# Reuses the quants made by kl_gemma4_12b.sh. Each slice gets its own Q8_0 reference logits and results folder.
# Usage: bash kl_slices.sh            (after kl_gemma4_12b.sh has made the quants)
set -euo pipefail
BIN=${BIN:-/mnt/ai-storage/tools/llama.cpp-main/build/bin}
MODELS=${MODELS:-/mnt/ai-storage/models/gguf/gemma-4-12b-it}
WORK=${WORK:-/mnt/ai-storage/quant-eval/gemma-4-12b-it}
OLLAMA_BLOB=${OLLAMA_BLOB:-$(python3 -c "import json;d=json.load(open('/mnt/ai-storage/models/ollama/manifests/registry.ollama.ai/library/gemma4/12b'));print('/mnt/ai-storage/models/ollama/blobs/'+[l for l in d['layers'] if l['mediaType'].endswith('.model')][0]['digest'].replace(':','-'))")}
CTX=2048; NGL_REF=${NGL_REF:-30}; THREADS=${THREADS:-6}
# files over ~7.5 GB do not fit 10 GB with full offload at 2048 ctx; offload fewer layers (KL is unaffected, only speed)
ngl_for() { echo 30; }   # Amendment 2: every run uses the reference split (-ngl 30); a different split alone gives KL 0.03 on this model
log() { echo "[$(date '+%H:%M:%S')] $*"; }
run_gpu() { flock ~/.night-shift.lock "$@"; }
declare -A CAND=(
  [Q6_K]="$WORK/quants/gemma4-12b-Q6_K.gguf" [Q5_K_M]="$WORK/quants/gemma4-12b-Q5_K_M.gguf"
  [Q4_K_M]="$WORK/quants/gemma4-12b-Q4_K_M.gguf" [Q4_K_M-imat]="$WORK/quants/gemma4-12b-Q4_K_M-imat.gguf"
  [IQ4_XS-imat]="$WORK/quants/gemma4-12b-IQ4_XS-imat.gguf" [Q3_K_M]="$WORK/quants/gemma4-12b-Q3_K_M.gguf"
  [Q3_K_M-imat]="$WORK/quants/gemma4-12b-Q3_K_M-imat.gguf" [IQ3_M-imat]="$WORK/quants/gemma4-12b-IQ3_M-imat.gguf"
  [UD-Q4_K_XL]="$MODELS/gemma-4-12b-it-UD-Q4_K_XL.gguf" [QAT-UD-Q4_K_XL]="$MODELS/gemma-4-12B-it-qat-UD-Q4_K_XL.gguf"
  [ollama-Q4_K_M]="$OLLAMA_BLOB"
)
for slice in chat-template code wiki; do
  f="$WORK/slice-$slice.txt"; R="$WORK/results-$slice"; mkdir -p "$R"; ref="$WORK/ref-$slice.kld"
  if [[ ! -s $ref ]]; then
    log "[$slice] reference logits from Q8_0"
    run_gpu "$BIN/llama-perplexity" -m "$WORK/quants/gemma4-12b-Q8_0.gguf" -f "$f" --kl-divergence-base "$ref" -c $CTX -ngl $NGL_REF -t $THREADS > "$R/ref-Q8_0.log" 2>&1
  fi
  for name in "${!CAND[@]}"; do
    m=${CAND[$name]}; out="$R/kl-$name.log"
    [[ -s $m ]] || { log "[$slice] missing $name, skipped"; continue; }
    [[ -s $out ]] && grep -q "Mean KLD" "$out" && continue
    log "[$slice] KL: $name"
    run_gpu "$BIN/llama-perplexity" -m "$m" -f "$f" --kl-divergence-base "$ref" --kl-divergence -c $CTX -ngl $(ngl_for "$name") -t $THREADS > "$out" 2>&1 || log "FAILED $slice $name"
  done
  for kv in q8_0 q4_0; do
    out="$R/kl-Q4_K_M-imat-kv$kv.log"
    [[ -s $out ]] && grep -q "Mean KLD" "$out" && continue
    log "[$slice] KL: Q4_K_M-imat with KV $kv"
    run_gpu "$BIN/llama-perplexity" -m "$WORK/quants/gemma4-12b-Q4_K_M-imat.gguf" -f "$f" --kl-divergence-base "$ref" --kl-divergence -c $CTX -ngl 30 -t $THREADS -fa on -ctk $kv -ctv $kv > "$out" 2>&1 || log "FAILED $slice kv $kv"
  done
  log "[$slice] report"; python3 -I "$(dirname "$0")/kl_report.py" "$R" "$WORK/quants" "$MODELS" "$OLLAMA_BLOB" > "$R/REPORT.md"
done
log "run B done"
