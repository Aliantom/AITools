#!/bin/bash
# KL-divergence test of gemma-4-12b-it quantizations on the RTX 3080 (experiment 001).
# Pre-registration and results: "Quantization KL experiment 001 (gemma4 12b).md" next to this script.
#
# Needs: llama.cpp built with CUDA at $BIN (llama-quantize, llama-imatrix, llama-perplexity),
#        the Unsloth BF16 GGUF and the two UD-Q4_K_XL files in $MODELS, eval/calib text from prep_eval_data.py.
# Usage: bash kl_gemma4_12b.sh [all|prep|quant|imatrix|ref|eval|kv|report]
# Holds ~/.night-shift.lock for the GPU parts (vault rule: one GPU job at a time).
set -euo pipefail
BIN=${BIN:-/mnt/ai-storage/tools/llama.cpp-main/build/bin}
MODELS=${MODELS:-/mnt/ai-storage/models/gguf/gemma-4-12b-it}
WORK=${WORK:-/mnt/ai-storage/quant-eval/gemma-4-12b-it}
OLLAMA_BLOB=${OLLAMA_BLOB:-$(python3 -c "import json;d=json.load(open('/mnt/ai-storage/models/ollama/manifests/registry.ollama.ai/library/gemma4/12b'));print('/mnt/ai-storage/models/ollama/blobs/'+[l for l in d['layers'] if l['mediaType'].endswith('.model')][0]['digest'].replace(':','-'))")}
BF16=$MODELS/gemma-4-12b-it-BF16.gguf
CTX=2048            # perplexity context; same for every run
NGL_REF=${NGL_REF:-30}   # Q8_0 (11.8 GB) does not fit 10 GB: partial offload for the reference and imatrix runs
THREADS=${THREADS:-6}
mkdir -p "$WORK/quants" "$WORK/results"
step=${1:-all}
log() { echo "[$(date '+%H:%M:%S')] $*"; }

run_gpu() { flock ~/.night-shift.lock "$@"; }

if [[ $step == all || $step == prep ]]; then
  log "prep: eval/calib text"
  ~/ai-lab/.venv/bin/python -I "$(dirname "$0")/prep_eval_data.py" --data /mnt/ai-storage/quant-eval/data \
    --code-eval /mnt/ai-storage/tools/llama.cpp-b11530/src/gguf-py --code-calib /mnt/ai-storage/tools/llama.cpp-b11530/src/conversion --out "$WORK"
fi

if [[ $step == all || $step == quant ]]; then
  for q in Q8_0 Q6_K Q5_K_M Q4_K_M Q3_K_M; do
    out="$WORK/quants/gemma4-12b-$q.gguf"
    [[ -s $out ]] || { log "quantize $q (no imatrix)"; "$BIN/llama-quantize" "$BF16" "$out" "$q" "$THREADS" > "$WORK/results/quantize-$q.log" 2>&1; }
  done
fi

if [[ $step == all || $step == imatrix ]]; then
  if [[ ! -s $WORK/imatrix.gguf ]]; then
    log "imatrix from Q8_0 over calib.txt"
    run_gpu "$BIN/llama-imatrix" -m "$WORK/quants/gemma4-12b-Q8_0.gguf" -f "$WORK/calib.txt" -o "$WORK/imatrix.gguf" \
      -c $CTX -ngl $NGL_REF -t $THREADS > "$WORK/results/imatrix.log" 2>&1
  fi
  for q in Q4_K_M IQ4_XS Q3_K_M IQ3_M; do
    out="$WORK/quants/gemma4-12b-$q-imat.gguf"
    [[ -s $out ]] || { log "quantize $q (imatrix)"; "$BIN/llama-quantize" --imatrix "$WORK/imatrix.gguf" "$BF16" "$out" "$q" "$THREADS" > "$WORK/results/quantize-$q-imat.log" 2>&1; }
  done
fi

if [[ $step == all || $step == ref ]]; then
  if [[ ! -s $WORK/ref.kld ]]; then
    log "reference logits from Q8_0 (partial offload)"
    run_gpu "$BIN/llama-perplexity" -m "$WORK/quants/gemma4-12b-Q8_0.gguf" -f "$WORK/eval.txt" --kl-divergence-base "$WORK/ref.kld" \
      -c $CTX -ngl $NGL_REF -t $THREADS > "$WORK/results/ref-Q8_0.log" 2>&1
  fi
fi

declare -A CAND=(
  [Q6_K]="$WORK/quants/gemma4-12b-Q6_K.gguf"
  [Q5_K_M]="$WORK/quants/gemma4-12b-Q5_K_M.gguf"
  [Q4_K_M]="$WORK/quants/gemma4-12b-Q4_K_M.gguf"
  [Q4_K_M-imat]="$WORK/quants/gemma4-12b-Q4_K_M-imat.gguf"
  [IQ4_XS-imat]="$WORK/quants/gemma4-12b-IQ4_XS-imat.gguf"
  [Q3_K_M]="$WORK/quants/gemma4-12b-Q3_K_M.gguf"
  [Q3_K_M-imat]="$WORK/quants/gemma4-12b-Q3_K_M-imat.gguf"
  [IQ3_M-imat]="$WORK/quants/gemma4-12b-IQ3_M-imat.gguf"
  [UD-Q4_K_XL]="$MODELS/gemma-4-12b-it-UD-Q4_K_XL.gguf"
  [QAT-UD-Q4_K_XL]="$MODELS/gemma-4-12B-it-qat-UD-Q4_K_XL.gguf"
  [ollama-Q4_K_M]="$OLLAMA_BLOB"
)
if [[ $step == all || $step == eval ]]; then
  for name in "${!CAND[@]}"; do
    f=${CAND[$name]}; out="$WORK/results/kl-$name.log"
    [[ -s $f ]] || { log "missing $name ($f), skipped"; continue; }
    [[ -s $out ]] && grep -q "Mean KLD" "$out" && continue
    log "KL: $name"
    run_gpu "$BIN/llama-perplexity" -m "$f" -f "$WORK/eval.txt" --kl-divergence-base "$WORK/ref.kld" --kl-divergence \
      -c $CTX -ngl 99 -t $THREADS > "$out" 2>&1 || log "FAILED $name (see $out)"
  done
fi

if [[ $step == all || $step == kv ]]; then
  f="$WORK/quants/gemma4-12b-Q4_K_M-imat.gguf"
  for kv in q8_0 q4_0; do
    out="$WORK/results/kl-Q4_K_M-imat-kv$kv.log"
    [[ -s $out ]] && grep -q "Mean KLD" "$out" && continue
    log "KL: Q4_K_M-imat with KV cache $kv"
    run_gpu "$BIN/llama-perplexity" -m "$f" -f "$WORK/eval.txt" --kl-divergence-base "$WORK/ref.kld" --kl-divergence \
      -c $CTX -ngl 99 -t $THREADS -fa on -ctk $kv -ctv $kv > "$out" 2>&1 || log "FAILED kv $kv"
  done
fi

if [[ $step == all || $step == report ]]; then
  python3 -I "$(dirname "$0")/kl_report.py" "$WORK/results" "$WORK/quants" "$MODELS" "$OLLAMA_BLOB"
fi
log "done ($step)"
