<!-- Generated from the Obsidian vault (Machine/Research/Quantization). Edit the vault note, not this file: mirror_research.py overwrites it. -->

# Quantization glossary

> **TL;DR:** Every quantization term with what it is, why it exists, and its modern LLM-era descendant; about half the classic list is CNN-era and has been replaced by group quantization, GPTQ-style rounding, SmoothQuant and rotation.
> **Source:** Owner request 2026-11-04: explain a list of quantization terms (uniform, non-uniform, per-channel, group, mixed precision, calibration, LSQ, AdaRound, bias correction, CLE, OCS, distillation, BN folding) and whether they still apply  ·  **Project:** finetune-lab  ·  **Updated:** 2026-11-04

Each entry says what the term means, why anyone invented it, and what people use today in its place. "Classic" means the 2018 to 2021 era of quantizing convolutional networks for phones (the Qualcomm AIMET and Google TensorFlow Lite lineage). "LLM-era" means 2022 onward. Evidence labels: VERIFIED = read in a source listed in [Quantization sources](quantization-sources.md); MEMORY = from general knowledge, check before relying on an exact number.

## Foundations

**Scale and zero point.** A quantized weight is reconstructed as `w ≈ scale × (q − zero_point)`. The scale says how big one integer step is. The zero point shifts the grid so it can represent asymmetric ranges. Symmetric quantization fixes the zero point at 0 and is cheaper to compute; asymmetric uses a zero point and fits skewed ranges better. (MEMORY)

**Bit-width, W4A16 notation.** "W4A16" means 4-bit weights, 16-bit activations. "W8A8" means both at 8 bits. "W4A4" means both at 4 bits and needs the activation tricks below. Weight-only quantization (W4A16) saves memory and speeds up small-batch inference because decoding is bandwidth-bound. Activation quantization (W8A8, W4A4) is what gives real compute speedups on big batches, and it is much harder because activations have outliers. (MEMORY)

**Bits per weight (bpw).** The true average cost once scales and zero points are counted. A "4-bit" GGUF Q4_K_M is about 4.85 bpw; an AWQ group-128 model is about 4.25 bpw. The TensorFoundry guide puts practical "4-bit" models at about 4.5 bpw. (VERIFIED, S38)

**Outliers.** Transformers above a few billion parameters develop a few hidden dimensions with values a hundred times larger than the rest. LLM.int8() documented this emerging around 6.7B parameters. These dimensions wreck per-tensor activation quantization, which is why SmoothQuant, AWQ and rotation exist. (MEMORY, LLM.int8() paper)

**Straight-through estimator (STE).** Rounding has zero gradient almost everywhere, so training through it is impossible. The STE pretends the rounding function is the identity on the backward pass. Every QAT method relies on it. (MEMORY)

**Fake quantization.** During QAT the weights stay in float but are rounded and de-rounded on the forward pass, so the model experiences the quantization error while gradients still flow in float. The model that deploys is then quantized "for real" with no surprise. (MEMORY; torchao implements this, VERIFIED S9)

**Perplexity vs KL divergence.** Perplexity measures how surprised the model is by real text. It hides quantization damage because errors in different tokens cancel. KL divergence compares the quantized model's full output distribution against the original model's, token by token, and the "flip rate" counts how often the top answer changed. The paper "Accuracy is Not All You Need" made this argument and Unsloth and llama.cpp both report KL now. (VERIFIED S17, S19; paper MEMORY)

## The classic list, decoded

**Uniform quantization.** Levels are evenly spaced; the integer grid is linear. INT8 and INT4 are uniform. It is the default because integer multiply-accumulate hardware is cheap and fast. Everything in GGUF K-quants, GPTQ and AWQ is uniform within a group. (MEMORY)

**Non-uniform quantization.** Levels are not evenly spaced. Three flavours matter today:
- NF4 from QLoRA puts the 16 levels where a normal distribution has equal probability mass, so each level is used equally often. Used for quantized fine-tuning. (MEMORY, QLoRA paper)
- Codebook or vector quantization (QuIP#, AQLM): groups of weights are replaced by an index into a learned table of vectors. Best accuracy per bit at 2 to 3 bits, needs lookup kernels. (VERIFIED S39)
- Trellis quantization (QTIP, EXL3): a sequence of weights is encoded as a path through a trellis, which approximates a very large codebook with little memory. (VERIFIED S39, S40)
Why it is rare in production: the hardware wants uniform integers; non-uniform formats pay for their accuracy with custom kernels.

**Per-tensor vs per-channel.** One scale for a whole weight matrix versus one scale per output channel (row). Per-channel is standard for weights because channels differ in range by orders of magnitude. Activations are usually per-tensor or per-token because the matrix-multiply hardware wants to apply one scale per row of the activation. Cross-layer equalization existed to make per-tensor weights survivable on hardware that could not do per-channel. (MEMORY; AIMET docs VERIFIED S27)

**Group (block) quantization.** One scale (and sometimes a zero point) per block of 16 to 256 weights along the input dimension of a row. This is the trick that made 4-bit LLMs usable: a group of 32 or 128 weights rarely contains an outlier, so the scale stays tight. Group size is a trade: smaller groups cost more bits of overhead but track the values better. Examples: GGUF K-quants use 32-weight sub-blocks inside 256-weight super-blocks with 6-bit scales; GPTQ and AWQ default to groups of 128; MXFP4 uses blocks of 32; NVFP4 uses blocks of 16 with an FP8 scale per block. (VERIFIED S21, S38; GGUF internals MEMORY)

**Mixed-precision quantization.** Different bit-widths for different tensors or layers, chosen by sensitivity. Two meanings:
- Across layers. HAWQ chose bit-widths from Hessian eigenvalues (CNN era). llama.cpp's Q4_K_M keeps the attention value and feed-forward down projections at Q6_K because those tensors hurt most when squeezed. Unsloth Dynamic 2.0 picks a type for every layer per model. WINDQuant (2026) learns a global assignment. (VERIFIED S17, S5; Q4_K_M internals MEMORY)
- Across weights vs activations. W4A16 is itself mixed precision.

**Calibration methods for PTQ.** PTQ needs statistics to set scales. You run a small calibration set (often 128 to 512 sequences of 512 to 2048 tokens) through the model and collect activation ranges or importance. Ways to pick the range: min/max (fragile to outliers), percentile clipping (ignore the top 0.01%), MSE search (pick the clip that minimizes reconstruction error), and entropy or KL calibration (TensorRT's classic method: pick the clip that best preserves the activation distribution). In LLM land calibration also builds importance statistics: the llama.cpp importance matrix (imatrix), the GPTQ Hessian, and the AWQ activation scales. The calibration data must match the use: Unsloth found Wikipedia-only calibration overfits perplexity tests and switched to a 1.5M-token chat set. (VERIFIED S17, S20; TensorRT MEMORY)

**Learned Step-size Quantization (LSQ).** A QAT method (Esser et al., 2019) where the scale of each layer is a trainable parameter with its own gradient, rather than a fixed value from calibration. The step size learns to trade clipping error against rounding error during training. PACT did the same for the activation clipping value a year earlier. Still used inside QAT frameworks; torchao's fake quantizers can learn scales. (MEMORY)

**AdaRound.** Nagel et al., 2020. Round-to-nearest is not the best rounding: for each weight, rounding up or down should be decided by the effect on the layer's output, not by which integer is closer. AdaRound learns a per-weight up/down choice by minimizing the layer's output error on calibration data, with a regularizer that forces the choice to become binary. It made 4-bit CNNs usable post-training. The AIMET docs recommend the order batch-norm folding, then cross-layer equalization, then AdaRound. (VERIFIED S27, S28)
- BRECQ (2021) applied the same reconstruction per residual block rather than per layer, and reached INT2 on ResNets. (VERIFIED S29)
- LLM-era descendants: GPTQ's error-feedback rounding (from Optimal Brain Quantization), and Intel's SignRound / AutoRound, which learns rounding and clipping with signed gradient descent on blocks. SignRoundV2 (2025) pushes this to extreme low bits. (VERIFIED S3; GPTQ lineage MEMORY)

**Bias correction.** Quantizing weights shifts the mean of a layer's output. Measure the expected shift over calibration data (empirical) or compute it from batch-norm statistics (analytical, data-free) and subtract it from the layer's bias. From the Data-Free Quantization paper (Nagel et al., 2019). AIMET says do not combine it with AdaRound, because AdaRound already accounts for the output error. (VERIFIED S27, S28)

**Cross-layer equalization (CLE).** In a network with ReLU, scaling output channel i of layer 1 by 1/s and the matching input channel of layer 2 by s leaves the function unchanged (positive scaling equivariance). CLE exploits that freedom to make all channel ranges similar, so a per-tensor scale wastes less resolution. Data-free. Part of DFQ. (VERIFIED S27)
- LLM-era descendant: SmoothQuant migrates activation outliers into the weights with a per-channel factor, the same equivariance applied to the LayerNorm-to-linear boundary. AWQ's per-channel scaling is a cousin aimed at protecting salient weights. (MEMORY)

**Outlier channel splitting (OCS).** Zhao et al., 2019. Duplicate the channel that holds an outlier and halve both copies. The layer's function is unchanged, the range is halved, the layer is slightly wider. Applied to only a handful of channels. Mostly superseded by rotation methods, which spread outliers across all channels at zero width cost, but a 2026 paper (Bit-by-Bit) uses OCS inside a progressive QAT scheme for low-bit LLMs. (VERIFIED S30)

**Distillation-assisted quantization.** Train the quantized model (student) to match the full-precision model's output distribution (teacher) rather than the hard labels. Teacher probabilities carry far more signal per token, and the quantized model's job is to imitate the original, not to learn the task again. Used in LLM-QAT (teacher also generates the training data), Gemma 3 QAT (trained on the teacher's probabilities), ParetoQ, and QATFactory. (VERIFIED S12, S38; LLM-QAT MEMORY)

**Batch-norm folding.** Fold a batch-norm layer's scale and shift into the preceding convolution's weights and bias before quantizing, so what you simulate is what deploys (there is no separate batch-norm at inference). From Jacob et al., 2018. CNN-only in practice. Transformers use LayerNorm or RMSNorm, which cannot be folded the same way; rotation methods do fold the RMSNorm scale into the next linear layer so the rotation can be applied, which is the nearest analogue. (MEMORY; AIMET order VERIFIED S28)

## LLM-era terms that have no classic equivalent

**Importance matrix (imatrix).** llama.cpp's calibration: run text through the float model and record, per weight, how much the activations that multiply it matter. The quantizer then spends its error budget on unimportant weights. Reported to cut perplexity loss by 10 to 30 percent for free. Required for I-quants, optional and beneficial for K-quants. (VERIFIED S20, S22)

**K-quants and I-quants.** GGUF's two families. K-quants are blockwise uniform with per-block scales (Q4_K_M and friends). I-quants are non-linear, lookup-based formats for aggressive compression (IQ4_XS, IQ3_M, IQ2_XS) that depend on an imatrix. I-quants can be slower on CPUs and old GPUs. (VERIFIED S21, S22)

**Rotation (Hadamard, learned).** Multiply weights and activations by an orthogonal matrix so that each outlier is spread across every channel. The product is mathematically unchanged, and the rotated values are near-Gaussian and easy to quantize. QuaRot and SpinQuant started it; PolarQuant (2026) finds that rotation alone accounts for 98% of the gain in its method. (VERIFIED S31, S34)

**Salient weights.** AWQ's observation that about 1% of weight channels, those multiplied by large activations, carry most of the quality. Scaling them up before quantization protects them. (VERIFIED S38; AWQ paper MEMORY)

**KV cache quantization.** Storing the attention keys and values at 8, 4 or 3 bits. The cache grows with context length and is often bigger than the weights at long context. See [Quantization formats, GGUF and KV cache](quantization-formats-gguf-and-kv-cache.md). (VERIFIED S41, S43)

**Dynamic vs static activation quantization.** Dynamic computes activation scales on the fly per token (accurate, small overhead). Static fixes them at calibration time (fastest, needs good calibration). (VERIFIED S38)
