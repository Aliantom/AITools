<!-- Generated from the Obsidian vault (Machine/Research/Quantization). Edit the vault note, not this file: mirror_research.py overwrites it. -->

# Quantization sources

> **TL;DR:** Every paper, doc and post behind the quantization notes, with URL, date and an evidence label: 50 sources read through search summaries or fetch, plus the from-memory papers that still need their IDs checked before citing.
> **Source:** Source register for the 2026-11-04 quantization research session (Claude Code, web search and fetch)  ·  **Project:** finetune-lab  ·  **Updated:** 2026-11-04

Evidence labels:
- **FETCHED**: the page was fetched and summarized by a tool in the session; wording checked against the summary, not the full text.
- **SUMMARY**: a search tool returned an excerpt or summary of the page; the primary text was not read in full.
- **TITLE**: only the title and URL were seen.
- **MEMORY**: from general knowledge; the arXiv id and claims should be verified before citing.
- **SECONDARY**: a blog or explainer about a primary source.

Ids (S1, S2, ...) are what the other notes cite.

## Read in the 2026-11-04 session

| Id | Source | Type | Date | Used for | Label |
|---|---|---|---|---|---|
| S1 | [Benchmarking Post-Training Quantization in LLMs: Comprehensive Taxonomy, Unified Evaluation, and Comparative Analysis (arXiv 2502.13178)](https://arxiv.org/html/2502.13178v1) | paper | Feb 2025 | GPTQ and QuIP consistent; AWQ collapses at 2-bit; QuaRot+GPTQ at 2-bit | SUMMARY |
| S2 | [Art and Science of Quantizing Large-Scale Models: A Comprehensive Overview (arXiv 2409.11650)](https://arxiv.org/pdf/2409.11650) | overview | Sep 2024 | Pointer only | TITLE |
| S3 | [SignRoundV2 (arXiv 2512.04746)](https://arxiv.org/pdf/2512.04746) | paper | Dec 2025 | AutoRound lineage, extreme low-bit PTQ | SUMMARY |
| S4 | [D²Quant (arXiv 2602.02546)](https://arxiv.org/pdf/2602.02546) | paper | Feb 2026 | Newer weight-only method | TITLE |
| S5 | [WINDQuant: global mixed-precision (arXiv 2605.26660)](https://arxiv.org/pdf/2605.26660) | paper | May 2026 | Mixed precision across layers | TITLE |
| S6 | [ReQuant (arXiv 2608.07019)](https://arxiv.org/pdf/2608.07019) | paper | Aug 2026 | Newer PTQ refinement | TITLE |
| S7 | [Qift: W2A4/KV4 on rotated models (arXiv 2606.02823)](https://arxiv.org/pdf/2606.02823) | paper | Jun 2026 | References GPTAQ, FlatQuant; W2 on rotated models | SUMMARY |
| S8 | [Provable PTQ: OPTQ and Qronos (arXiv 2508.04853)](https://arxiv.org/pdf/2508.04853) | paper | Aug 2025 | Theory for GPTQ | TITLE |
| S9 | [Quantization-Aware Training in TorchAO (II)](https://pytorch.org/blog/quantization-aware-training-in-torchao-ii/) | blog | 2025/26 | NVFP4 QAT numbers (Qwen3-8B), Blackwell requirement, prepare/convert | SUMMARY |
| S10 | [QAT for LLMs with PyTorch](https://pytorch.org/blog/quantization-aware-training/) | blog | 2024 | 96% recovery on HellaSwag | SUMMARY |
| S11 | [TorchAO: PyTorch-Native Training-to-Serving Model Optimization (arXiv 2507.16099)](https://arxiv.org/pdf/2507.16099) | paper | Jul 2025 | Pipeline; cites ParetoQ | SUMMARY |
| S12 | [QATFactory (arXiv 2609.39223)](https://arxiv.org/html/2609.39223v2) | paper | Sep 2026 | W4A16 vs W4A4 training guidance; BF16 simulation of NVFP4/MXFP4/Q4_K | SUMMARY |
| S13 | [Unsloth: Quantization-Aware Training](https://unsloth.ai/docs/blog/quantization-aware-training-qat) | docs | 2025 | QAT in Unsloth | TITLE |
| S14 | [NVIDIA: Fine-tuning gpt-oss with QAT](https://developer.nvidia.com/blog/fine-tuning-gpt-oss-for-accuracy-and-performance-with-quantization-aware-training/) | blog | 2025 | MXFP4 vs NVFP4 convergence; upcast first | SUMMARY |
| S15 | [torchao RFC: MoE QAT (pytorch/ao #4408)](https://github.com/pytorch/ao/issues/4408) | issue | 2026 | MoE expert QAT; DeepSeek-V4 MXFP4 QAT mention | SUMMARY |
| S16 | [QAT vs PTQ: When Retraining Pays Off (MyAIHardware)](https://www.myaihardware.com/deep-dive/quantization-aware-training-vs-post-training-quant) | blog | 2025/26 | Background | SECONDARY |
| S17 | [Unsloth Dynamic 2.0 GGUFs (docs)](https://docs.unsloth.ai/basics/unsloth-dynamic-2.0-ggufs) | docs | 2025 | Per-layer selection, chat calibration set, KL methodology | SUMMARY |
| S18 | [Unsloth Dynamic v2.0 blog](https://unsloth.ai/blog/dynamic-v2) | blog | Apr 2025 | Calibration_v3/v5 note | SUMMARY |
| S19 | [GGUF quantizations overview, Mistral-7B KL table (Artefact2 gist)](https://gist.github.com/Artefact2/b5f810600771265fc1e39442288e8ec9) | gist | 2024 | Median KL per quant | SUMMARY |
| S20 | [Quantizing Models: llama.cpp docs (mirror)](https://mintlify.com/ggml-org/llama.cpp/models/quantizing-models) | docs | 2026 | Q8_0 +0.003 ppl; imatrix 10 to 30% | SUMMARY |
| S21 | [GGUF quantization guide (Toni Sagristà Sellés)](https://tonisagrista.com/blog/2026/quantization/) | blog | 2026 | K-quant vs I-quant naming | SUMMARY |
| S22 | [Best Quantization Methods for llama.cpp (Sesame Disk)](https://sesamedisk.com/best-quantization-methods-for-llama-cpp/) | blog | 2025/26 | IQ4_XS vs Q4_K_M; I-quant speed caveat | SUMMARY |
| S23 | [GGUF Quantization Explained (Logeshwaran)](https://www.logeshwaran.org/2026/10/gguf-quantization-types-explained.html) | blog | Oct 2026 | Background | TITLE |
| S24 | [LLM Quantization Explained (llamabuilds)](https://www.llamabuilds.ai/guides/llm-quantization-explained) | guide | 2026 | Background | TITLE |
| S25 | [llama.cpp Quantization Benchmark (markaicode)](https://markaicode.com/benchmarks/llamacpp-inference-benchmark/) | benchmark | 2026 | Perplexity deltas differ by source | SUMMARY |
| S26 | [bartowski imatrix GGUFs (example repo)](https://huggingface.co/bartowski/Meta-Llama-3-120B-Instruct-GGUF) | model repo | 2024 | Where imatrix quants come from | TITLE |
| S27 | [Qualcomm: Exploring AIMET's PTQ methods](https://www.qualcomm.com/developer/blog/2022/01/exploring-aimet-s-post-training-quantization-methods) | blog | Jan 2022 | AdaRound, CLE, bias correction, DFQ, BN stats | SUMMARY |
| S28 | [AIMET AdaRound user guide](https://quic.github.io/aimet-pages/AimetDocs/user_guide/adaround.html) | docs | current | Recommended order BNF, CLE, AdaRound; no BC with AdaRound | SUMMARY |
| S29 | [BRECQ (arXiv 2102.05426)](https://arxiv.org/abs/2102.05426v1) | paper | Feb 2021 | Block reconstruction, INT2 on CNNs | SUMMARY |
| S30 | [Bit-by-Bit: Progressive QAT with Outlier Channel Splitting (arXiv 2604.07888)](https://arxiv.org/pdf/2604.07888) | paper | Apr 2026 | OCS revived in QAT | SUMMARY |
| S31 | [PolarQuant (arXiv 2603.29078)](https://arxiv.org/abs/2603.29078) | paper | Mar 2026 | Rotation gives 98% of the gain | SUMMARY |
| S32 | [HARP (EMNLP 2026)](https://aclanthology.org/2026.emnlp-main.1773/) | paper | 2026 | Learnable orthogonal processor | SUMMARY |
| S33 | [Leech Lattice Vector Quantization (arXiv 2603.11021)](https://arxiv.org/pdf/2603.11021) | paper | Mar 2026 | Lattice VQ; Spherical GPTQ | SUMMARY |
| S34 | [Any Orthogonal Transform Will Do (arXiv 2601.21069)](https://arxiv.org/pdf/2601.21069) | paper | Jan 2026 | Range reduction explains rotation | SUMMARY |
| S35 | [HadaCore (arXiv 2412.08832)](https://arxiv.org/pdf/2412.08832) | paper | Dec 2024 | Tensor-core Hadamard kernel | TITLE |
| S36 | [Transforms for LLM Quantization: The Great Inversion and Format Co-Design (arXiv 2608.25188)](https://arxiv.org/pdf/2608.25188) | paper | Aug 2026 | List of learned-rotation methods | SUMMARY |
| S37 | [QAM-W (arXiv 2605.26339)](https://arxiv.org/html/2605.26339) | paper | May 2026 | 2D codebook with Hadamard | SUMMARY |
| S38 | [LLM Quantisation: A Field Guide for 2026 (TensorFoundry, Thushan Fernando)](https://tensorfoundry.io/blog/llm-quantisation-field-guide) | guide | 19 Jun 2026 | Bit-width recommendations, formats, Gemma QAT sizes, KV numbers | FETCHED |
| S39 | [QTIP (arXiv 2406.11235)](https://arxiv.org/html/2406.11235v3) | paper | 2024, v3 Jun 2025 | 2-bit perplexity vs QuIP#, AQLM; throughput | SUMMARY |
| S40 | [ExLlamaV3 documentation](https://docsearch.algolia.com/mcp/docs/repo/turboderp-org/exllamav3) | docs | 2025 | EXL3 as a QTIP variant; compare_q.py | SUMMARY |
| S41 | [Google TurboQuant overview (morphllm)](https://www.morphllm.com/turboquant) | explainer | 2026 | KV bits, vLLM presets, llama.cpp PR status, KIVI comparison | SUMMARY |
| S42 | [OnlyTerp/turboquant (GitHub)](https://github.com/OnlyTerp/turboquant) | repo | 2026 | Unofficial implementation | SUMMARY |
| S43 | [TurboQuant on InfoQ](https://www.infoq.com/news/2026/04/turboquant-compression-kv-cache/) | news | Apr 2026 | 6× KV reduction claim | SUMMARY |
| S44 | [TurboQuant for developers (dev.to)](https://dev.to/arshtechpro/turboquant-what-developers-need-to-know-about-googles-kv-cache-compression-eeg) | explainer | 2026 | Background | SECONDARY |
| S45 | [TurboQuant (Wikipedia)](https://en.wikipedia.org/wiki/TurboQuant) | encyclopedia | 2026 | Background | TITLE |
| S46 | [TurboQuant: PolarQuant + QJL (decodethefuture)](https://decodethefuture.org/en/turboquant-vector-quantization-kv-cache/) | explainer | 2026 | Mechanism summary | SECONDARY |
| S47 | [SVDQuant (arXiv 2411.05007)](https://arxiv.org/abs/2411.05007) | paper | Nov 2024, ICLR 2025 | Low-rank outlier branch; FLUX numbers | SUMMARY |
| S48 | [SVDQuant / Nunchaku (MIT HAN Lab blog)](https://hanlab.mit.edu/blog/svdquant) | blog | 2024/25 | Engine, checkpoints, INT4 on 4090 | SUMMARY |
| S49 | [deepcompressor-toolkit (PyPI)](https://pypi.org/project/deepcompressor-toolkit/) | package | 2025 | Quantizer package | TITLE |
| S50 | [QTIP literature review (themoonlight)](https://www.themoonlight.io/review/qtip-quantization-with-trellises-and-incoherence-processing) | review | 2025 | Throughput claim | SECONDARY |

## Cited from memory (verify ids before quoting)

| Source | What it is | Used for | Label |
|---|---|---|---|
| GPTQ, Frantar et al. (arXiv 2210.17323) | Hessian-based one-shot weight quantization | Mechanism | MEMORY |
| AWQ, Lin et al. (arXiv 2306.00978) | Activation-aware weight quantization | Salient channels | MEMORY |
| SmoothQuant, Xiao et al. (arXiv 2211.10438) | Activation outlier migration for W8A8 | CLE descendant | MEMORY |
| LLM.int8(), Dettmers et al. (arXiv 2208.07339) | Outlier features; mixed int8 | Outlier emergence | MEMORY |
| QLoRA, Dettmers et al. (arXiv 2305.14314) | NF4, double quantization, paged optimizers | Fine-tuning path | MEMORY |
| QuaRot, Ashkboos et al. (arXiv 2404.00456) | Hadamard rotation for W4A4KV4 | Rotation | MEMORY |
| SpinQuant, Liu et al. (arXiv 2405.16406) | Learned rotations | Rotation | MEMORY |
| FlatQuant (arXiv 2410.09426) | Learned affine transforms | Rotation | MEMORY |
| QuIP (arXiv 2307.13304), QuIP# (arXiv 2402.04396) | Incoherence + lattice codebooks | Sub-4-bit | MEMORY |
| AQLM (arXiv 2401.06118), PV-Tuning (arXiv 2405.14852) | Additive codebooks; fine-tuning for extreme compression | Sub-4-bit | MEMORY |
| HQQ (Mobius Labs blog, 2023) | Calibration-free quantizer | PTQ | MEMORY |
| SignRound, Cheng et al. (arXiv 2309.05516) | Signed-gradient rounding (AutoRound) | AdaRound descendant | MEMORY |
| OmniQuant (arXiv 2308.13137), SqueezeLLM (arXiv 2306.07629) | Learnable clipping; sensitivity codebook with sparse outliers | PTQ | MEMORY |
| AdaRound, Nagel et al. (arXiv 2004.10568) | Learned rounding | Glossary | MEMORY |
| DFQ, Nagel et al. (arXiv 1906.04721) | CLE and bias correction | Glossary | MEMORY |
| OCS, Zhao et al. (arXiv 1901.09504) | Outlier channel splitting | Glossary | MEMORY |
| LSQ, Esser et al. (arXiv 1902.08153); PACT (arXiv 1805.06085) | Learned step size; learned activation clip | QAT | MEMORY |
| White Paper on Neural Network Quantization, Nagel et al. (arXiv 2106.08295) | The canonical PTQ/QAT primer | Background | MEMORY |
| Jacob et al. 2018 (arXiv 1712.05877) | Integer-only inference; BN folding; fake quant | Glossary | MEMORY |
| HAWQ (arXiv 1905.03696) | Hessian-aware mixed precision | Mixed precision | MEMORY |
| LLM-QAT (arXiv 2305.17888) | Data-free QAT with teacher-generated data | QAT | MEMORY |
| EfficientQAT (arXiv 2407.11062) | Two-stage efficient QAT | QAT | MEMORY |
| ParetoQ (arXiv 2502.02631) | Scaling laws for extremely low-bit QAT | QAT | MEMORY |
| BitNet b1.58 (arXiv 2402.17764) | Native ternary LLMs | QAT | MEMORY |
| KIVI (arXiv 2402.02750) | 2-bit asymmetric KV cache | KV cache | MEMORY |
| Accuracy is Not All You Need (arXiv 2407.09141) | KL divergence and flip rate as the right metrics | Evaluation | MEMORY |
| Marlin kernel (arXiv 2408.11743) | Fast INT4×FP16 GEMM on Ampere | Serving path | MEMORY |
| Gemma 3 QAT (Google blog, Apr 2025); gpt-oss model card (Aug 2025) | Vendor QAT checkpoints; MXFP4 release format | QAT, formats | MEMORY |
| Repos: ggml-org/llama.cpp, ModelCloud/GPTQModel, vllm-project/llm-compressor, pytorch/ao, quic/aimet, NVIDIA/TensorRT-Model-Optimizer, intel/auto-round, mobiusml/hqq, turboderp-org/exllamav3, bitsandbytes-foundation/bitsandbytes, unslothai/unsloth, mit-han-lab/nunchaku, mit-han-lab/deepcompressor, spcl/QuaRot, facebookresearch/SpinQuant, EleutherAI/lm-evaluation-harness | Tooling | Tools note | MEMORY |

## Second pass, 2026-11-04 evening (deep dives, KL experiment setup)

| Id | Source | Type | Date | Used for | Label |
|---|---|---|---|---|---|
| S51 | [An Empirical Study of Qwen3 Quantization (arXiv 2505.02214; Springer 2026)](https://arxiv.org/html/2505.02214v1) | paper | 2025/26 | Per-size degradation, 3-bit cliff, Qwen3 vs LLaMA-3 | SUMMARY |
| S52 | [Quantization Hurts Reasoning? (arXiv 2504.04823 v2)](https://arxiv.org/html/2504.04823v2) | paper | Aug 2025 | W4A16/W8A8 lossless, 3-bit risky, output length, KV4, AWQ over GPTQ | SUMMARY |
| S53 | [Quantized Reasoning Models Think They Need to Think Longer, but They Do Not (arXiv 2606.00206)](https://arxiv.org/pdf/2606.00206) | paper | Jun 2026 | Title only | TITLE |
| S54 | [QuantLRM (arXiv 2602.02581)](https://arxiv.org/pdf/2602.02581) | paper | Feb 2026 | Title only | TITLE |
| S55 | [Preserving LLM Capabilities through Calibration Data Curation (arXiv 2510.10618)](https://arxiv.org/pdf/2510.10618) | paper | Oct 2025 | Sample count, length, curation | SUMMARY |
| S56 | [GPTQ as Babai's Nearest Plane Algorithm (arXiv 2507.18553)](https://arxiv.org/pdf/2507.18553) | paper | Jul 2025 | GPTQ theory | TITLE |
| S57 | [NeUQI (arXiv 2505.17595)](https://arxiv.org/pdf/2505.17595) | paper | 2025 | Grid initialization | TITLE |
| S58 | [LLMC benchmark toolkit (arXiv 2405.06001)](https://arxiv.org/pdf/2405.06001) | paper | 2024 | Calibration domain effect | SUMMARY |
| S59 | [Calibration-data study (arXiv 2409.11055 v6)](https://arxiv.org/pdf/2409.11055) | paper | Jun 2025 | 128-sample plateau, degradation under 64 | SUMMARY |
| S60 | [Hands-on GPTQ (apxml course)](https://apxml.com/courses/practical-llm-quantization/chapter-3-advanced-ptq-techniques/practice-gptq) | course | 2025 | Defaults | SECONDARY |
| S61 | [CoopQ / SPQE (arXiv 2509.15455; ACL 2026 Findings)](https://arxiv.org/pdf/2509.15455) | paper | 2025/26 | Shapley sensitivity, sub-4-bit failure of scalar metrics | SUMMARY |
| S62 | [CASA: activation-aware mixed precision with cross-layer refinement (arXiv 2609.25916)](https://arxiv.org/abs/2609.25916v1) | paper | Sep 2026 | Knapsack formulation, scalar-proxy critique | SUMMARY |
| S63 | [KVTuner (ICML 2025)](https://icml.cc/virtual/2025/poster/43487) | paper | 2025 | 3.25-bit mixed KV | SUMMARY |
| S64 | [MXSens (arXiv 2607.17733)](https://arxiv.org/html/2607.17733v1) | paper | Jul 2026 | Early-layer sensitivity, per-column bits | SUMMARY |
| S65 | [Beyond Outliers: data-free layer-wise mixed precision, NSDS (arXiv 2603.17354)](https://arxiv.org/pdf/2603.17354) | paper | Mar 2026 | Calibration-free sensitivity | SUMMARY |
| S66 | [MixLLM (MLSys 2026 oral)](https://mlsys.org/virtual/2026/oral/3805) | paper | 2026 | Global per-output-feature precision | SUMMARY |
| S67 | [ParetoQ (arXiv 2502.02631)](https://arxiv.org/abs/2502.02631) and [facebookresearch/ParetoQ](https://github.com/facebookresearch/ParetoQ) | paper, repo | 2025 | 2-to-3-bit transition, QAT budget law, 1.58-bit result | SUMMARY |
| S68 | [Low-Bit Quantization Favors Undertrained LLMs (arXiv 2411.17691)](https://arxiv.org/pdf/2411.17691) | paper | Nov 2024 | Over-training makes quantization harder | TITLE |
| S69 | [Statistically-Lossless Quantization of LLMs (arXiv 2605.02404)](https://arxiv.org/pdf/2605.02404) | paper | May 2026 | Title only | TITLE |
| S70 | [ParetoQ summary (hychiang)](https://hychiang.info/blog/2025/paretoq-summary/) | blog | 2025 | Cross-check | SECONDARY |
| S71 | [Kai-Liu001/Awesome-Model-Quantization](https://github.com/Kai-Liu001/Awesome-Model-Quantization) | list | 2026 | 2020 to 2026 top-venue papers with code | SUMMARY |
| S72 | [JunHoo-Lee/Awesome-Model-Quantization](https://github.com/JunHoo-Lee/Awesome-Model-Quantization) | list | 2026 | Toolkits table, 2026 section | SUMMARY |
| S73 | [LumosJiang/Awesome-On-Device-LLMs](https://github.com/LumosJiang/Awesome-On-Device-LLMs) | list | 2026 | On-device compression | SUMMARY |
| S74 | [pprp/Awesome-LLM-Quantization](https://github.com/pprp/Awesome-LLM-Quantization) | list | 2024/25 | Older list | TITLE |
| S75 | [ziniv/Awesome-Efficient-LLM](https://github.com/ziniv/Awesome-Efficient-LLM) | list | 2025 | Broader efficiency | TITLE |
| S76 | [BitDistiller (ACL 2024; arXiv 2402.10631)](https://arxiv.org/pdf/2402.10631) and [DD-DuDa/BitDistiller](https://github.com/DD-DuDa/BitDistiller) | paper, repo | 2024 | Self-distillation QAT, 2-bit MMLU figure (third-party) | SUMMARY |
| S77 | [UPQ: block-wise PTQ then distillation QAT to INT2 (arXiv 2506.09104)](https://arxiv.org/pdf/2506.09104) | paper | Jun 2025 | Two-stage recipe | SUMMARY |
| S78 | [EdgeRazor (arXiv 2605.04062)](https://arxiv.org/pdf/2605.04062) | paper | May 2026 | Title only | TITLE |
| S79 | [A Survey of Low-bit LLMs: Basics, Systems, and Algorithms (arXiv 2409.16694)](https://arxiv.org/pdf/2409.16694) | survey | 2024/25 | The Neural Networks survey, located | TITLE |
| S80 | [LoftQ (arXiv 2310.08659)](https://arxiv.org/html/2310.08659) | paper | 2023 | Init, 2-bit result; summaries also cover QA-LoRA, LQ-LoRA | SUMMARY |
| S81 | [Scale-QLoRA: code-invariant adapter merging for MXFP4 (arXiv 2609.04526)](https://arxiv.org/pdf/2609.04526) | paper | Sep 2026 | Merge loss numbers | SUMMARY |
| S82 | [LQER (arXiv 2402.02446)](https://arxiv.org/pdf/2402.02446) | paper | 2024 | Low-rank error reconstruction | TITLE |
| S83 | [LoRA comprehensive review (arXiv 2501.00365)](https://arxiv.org/pdf/2501.00365) | review | 2025 | Background | TITLE |
| S84 | [Low-Rank Adaptation Redux (arXiv 2604.21905)](https://arxiv.org/pdf/2604.21905) | paper | Apr 2026 | Background | TITLE |
| S85 | [GEMQ: global expert-level mixed precision for MoE (arXiv 2605.23078)](https://arxiv.org/pdf/2605.23078) | paper | May 2026 | Qwen3-30B-A3B architecture, allocation | SUMMARY |
| S86 | [BitsMoE (arXiv 2606.00079)](https://arxiv.org/pdf/2606.00079) | paper | Jun 2026 | 2-bit ablation 47% vs 25% | SUMMARY |
| S87 | [TileQ (arXiv 2605.09281)](https://arxiv.org/pdf/2605.09281) | paper | May 2026 | Low-rank overhead | SUMMARY |
| S88 | [MODE: modality-decomposed expert-level quantization (arXiv 2606.17118)](https://arxiv.org/pdf/2606.17118) | paper | Jun 2026 | Multimodal MoE | SUMMARY |
| S89 | [llama-quantize(1) manpage](https://manpages.debian.org/unstable/llama.cpp-tools/llama-quantize.1.en.html) | docs | 2026 | --tensor-type, --tensor-type-file | SUMMARY |
| S90 | [llama.cpp discussion #12741: custom quants with --tensor-type](https://github.com/ggml-org/llama.cpp/discussions/12741) | discussion | 2025 | Mixed recipes, MSD threshold about 0.1 | SUMMARY |
| S91 | [llama.cpp issue #22544: --tensor-type ignored when equal to global type](https://github.com/ggml-org/llama.cpp/issues/22544) | issue | 2026 | Known bug | SUMMARY |
| S92 | [llama.cpp KV cache quantization guide, measured (sotaaz)](https://sotaaz.com/post/llamacpp-kv-cache-quantization-guide-en) | blog | 2026 | q8_0 perplexity delta, speed cost | SUMMARY |
| S93 | [KV cache Q4 vs Q8 in llama.cpp (bmdpat)](https://bmdpat.com/blog/kv-cache-q4-vs-q8-in-llama-cpp-explained-2026) | blog | 2026 | Background | SECONDARY |
| S94 | [Qwen 3.5 27B GGUF quality benchmark: five uploaders by KL (localbench)](https://localbench.substack.com/p/qwen-3-5-27b-gguf-quality-benchmark) | benchmark | 2026 | Uploaders within 6% at same type | SUMMARY |
| S95 | [Hacker News thread on Unsloth Dynamic 2.0 vs bartowski](https://news.ycombinator.com/item?id=47192505) | thread | 2026 | Q4_K_M 0.0192 vs 0.0182; XL 0.0137 | SUMMARY |
| S96 | [ubergarm: early exllamav3 EXL3 quants (gist)](https://gist.github.com/ubergarm/9d560bab80241b90dac802e91b656743) | gist | 2025 | EXL3 practice | SUMMARY |
| S97 | [ExLlamaV3 vs llama.cpp with a 27B on 16 GB (efraingaray)](https://efraingaray.com/en/blog/exllamav3-vs-llamacpp-16gb/) | blog | 2026 | KL at 3 and 3.5 bpw vs GGUF | SUMMARY |
| S98 | [EXL3 vs GGUF: quality, speed and VRAM (atomic.chat)](https://atomic.chat/blog/guides/exl3-vs-gguf) | guide | 2026 | 4.0 bpw KL comparison, effective bpw | SUMMARY |
| S99 | [ParoQuant (ICLR 2026; arXiv 2511.10645)](https://arxiv.org/pdf/2511.10645) and [z-lab/paroquant](https://github.com/z-lab/paroquant) | paper, repo | 2025/26 | Pairwise rotations, +2.4% over AWQ | SUMMARY |
| S100 | [AnyBCQ (ICLR 2026)](https://mlanthology.org/iclr/2026/park2026iclr-anybcq/) | paper | 2026 | Multi-precision binary-coded | SUMMARY |
| S101 | [SINQ: Sinkhorn-normalized calibration-free quantization (arXiv 2509.22944)](https://arxiv.org/abs/2509.22944) | paper | Sep 2025 | Dual-axis scales | SUMMARY |
| S102 | [Speculative Decoding Meets Quantization (arXiv 2505.22179)](https://arxiv.org/pdf/2505.22179) | paper | May 2025 | Compatibility, hierarchical design | SUMMARY |
| S103 | [SD2: Self-Distilled Sparse Drafters (arXiv 2504.08838)](https://arxiv.org/html/2504.08838v2) | paper | 2025 | 2:4 vs unstructured drafts | SUMMARY |
| S104 | [Quasar: quantized self-speculative acceleration (arXiv 2603.01399)](https://www.alphaxiv.org/abs/2603.01399.md) | paper | Mar 2026 | Quantized verification | SUMMARY |
| S105 | [ML-SpecQD (arXiv 2503.13565)](https://arxiv.org/abs/2503.13565v1) | paper | 2025 | MXFP4 drafts 2.72× | SUMMARY |
| S106 | [KV cache quantization in Ollama and llama.cpp (llmhardware)](https://llmhardware.io/guides/kv-cache-quantization-ollama-llama-cpp) and [smcleod: bringing K/V quantisation to Ollama](https://smcleod.net/2024/12/bringing-k/v-context-quantisation-to-ollama/) | guides | 2024/26 | Env vars, fallbacks, flash-attention default from 0.30 | SUMMARY |
| S107 | [bartowski/gemma-4-12B-it-GGUF](https://huggingface.co/bartowski/gemma-4-12B-it-GGUF) | model repo | 2026 | imatrix on calibration_datav3 | SUMMARY |
| S108 | [unsloth/gemma-4-12b-it-GGUF](https://huggingface.co/unsloth/gemma-4-12b-it-GGUF) and [unsloth/gemma-4-12B-it-qat-GGUF](https://huggingface.co/unsloth/gemma-4-12B-it-qat-GGUF) | model repos | 2026 | File list and sizes read through the HF API on this PC | LOCAL |
| S109 | [TuneQn: sensitivity-driven selective ONNX quantization (arXiv 2507.12196)](https://arxiv.org/pdf/2507.12196) and [onnx-analyzer](https://gh.r-mj.com/dwithchenna/onnx-analyzer) | paper, tool | 2025 | Per-layer error visualization | SUMMARY |
| S110 | [AI-Efficiency/Qwen3-Quantization-Toolkit](https://github.com/AI-Efficiency/Qwen3-Quantization-Toolkit) | repo | 2025 | Published tables | SUMMARY |
| S111 | [Unsloth: Gemma 4, how to run locally](https://unsloth.ai/docs/models/gemma-4) | docs | 2026 | Recommended UD quant | SUMMARY |
