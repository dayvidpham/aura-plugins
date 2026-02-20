---
title: "Opus vs Sonnet Model Selection — Domain Research"
date: "2026-02-20"
depth: "standard-research"
request: "standalone"
---

## Executive Summary

Claude Opus 4.6 and Sonnet 4.6 have converged dramatically on most benchmarks — Sonnet scores within 1.2 points on SWE-bench Verified (79.6% vs 80.8%) at 1/5th the cost. However, Opus retains decisive advantages in three areas: **expert-level reasoning** (17-point gap on GPQA Diamond), **long-context needle retrieval** (76% vs 18.5% on MRCR v2), and **sustained agentic task execution** (Terminal-Bench 2.0 leader). These are the axes that should drive model selection for the supervisor's worker spawning.

Neither A-Mem nor Prompt Alchemist (MAPS) provide Opus-specific benchmarks — both are model-agnostic frameworks that benefit from stronger foundation models but don't test the Opus/Sonnet boundary specifically.

---

## 1. Benchmark Comparison (4.6 Generation)

### Where Opus Leads

| Benchmark | Opus 4.6 | Sonnet 4.6 | Gap | What it measures |
|-----------|----------|------------|-----|-----------------|
| GPQA Diamond | 91.3% | 74.1% | **+17.2** | PhD-level multi-step scientific reasoning |
| MRCR v2 (8-needle, 1M) | 76% | 18.5%* | **+57.5** | Long-context retrieval across 1M tokens |
| BrowseComp | 84.0% | N/A** | — | Hard-to-find web information retrieval |
| Terminal-Bench 2.0 | 65.4% | N/A** | — | Agentic terminal coding (long-running) |
| Max output tokens | 128K | 64K | **2x** | Extended generation capacity |

\* Sonnet 4.5 score; Sonnet 4.6 likely improved but no published 1M MRCR score yet.
\** Not yet published for Sonnet 4.6.

### Where Sonnet Matches or Leads

| Benchmark | Opus 4.6 | Sonnet 4.6 | Gap | What it measures |
|-----------|----------|------------|-----|-----------------|
| SWE-bench Verified | 80.8% | 79.6% | -1.2 | Real-world software engineering |
| OSWorld-Verified | 72.7% | 72.5% | -0.2 | GUI automation / computer use |
| Finance Agent v1.1 | 60.1% | 63.3% | **Sonnet +3.2** | Agentic financial analysis |
| Math benchmarks | — | 89% | — | Quantitative reasoning (major Sonnet 4.6 leap) |

### Token Efficiency

At highest effort level, Opus 4.5 exceeded Sonnet 4.5 by 4.3 points while using **48% fewer tokens**. On app development tasks, Opus consumed 19.3% fewer total tokens. This means Opus can partially offset its 5x price premium through more efficient solution paths on hard problems.

---

## 2. Expert-Level Reasoning (GPQA Diamond Gap)

The 17-point gap on GPQA Diamond (91.3% vs 74.1%) is the single largest performance difference between the two models. This benchmark tests PhD-level questions requiring chaining multiple expert concepts across physics, chemistry, and biology.

This gap matters for:
- **Architectural decisions** requiring multi-step reasoning about tradeoffs
- **Complex debugging** where you need to trace causality across many components
- **Security analysis** — Opus 4.6 independently discovered 500+ previously unknown high-severity vulnerabilities in open-source code during pre-release testing
- **Scientific/domain-specific** reasoning where precision compounds

Note: Some sources report a smaller gap (91.3% vs 89.9%) depending on evaluation methodology. The true gap may be narrower than 17 points.

---

## 3. Long-Context and Sustained Agentic Performance

### Long-Context Retrieval

On MRCR v2 (8-needle variant at 1M tokens), Opus 4.6 scores 76% compared to Sonnet 4.5's 18.5%. This is described as "a qualitative shift in how much context a model can actually use while maintaining peak performance." This matters for:
- Workers operating on large codebases where many files must be held in context
- Multi-agent coordination where shared context is large
- Tasks requiring cross-file reasoning

### Sustained Agentic Execution

Opus 4.6 sustains focus over longer sessions without performance drift that affected earlier models. Multi-step workflows spanning dozens of tool calls complete more reliably. Both models support compaction for theoretically indefinite sessions, but Opus's deeper reasoning compounds across long chains.

---

## 4. Reinforcement Learning Context

### Training Approach

Claude models use a mix of RLHF (reinforcement learning from human feedback) and RLAIF (RL from AI feedback via Constitutional AI). There are no published benchmarks comparing Opus vs Sonnet specifically on RL-related tasks (e.g., coding RL algorithms, designing reward functions, or RL environment design).

### RL Coding / Experiential RL

No specific benchmarks exist for "RL coding" as a separate evaluation axis. The relevant proxy benchmarks are:
- **SWE-bench Verified** (general coding): Near-parity
- **Terminal-Bench 2.0** (agentic terminal): Opus leads
- **GPQA Diamond** (scientific reasoning): Opus leads significantly

For implementing RL algorithms specifically, the reasoning depth advantage of Opus would likely matter more than raw coding speed — RL implementations involve subtle mathematical reasoning about reward shaping, convergence properties, and exploration/exploitation tradeoffs.

### Agentic RL (Training Claude Itself)

Traditional RLHF alone reduced reward hacking in straightforward chat but did not fully eliminate it in agentic contexts like coding tasks. This is a known area of active research at Anthropic, not a differentiator between Opus and Sonnet from a user perspective.

---

## 5. A-Mem (Agentic Memory)

### What It Is

A-Mem (NeurIPS 2025) is a Zettelkasten-inspired agentic memory system that creates interconnected knowledge networks through atomic notes with contextual descriptions, keywords, and tags. It doubles performance on complex multi-hop reasoning tasks compared to baseline memory approaches.

### Opus Relevance

A-Mem was tested with Claude 3.0 Haiku and Claude 3.5 Haiku, not Opus or Sonnet 4.x. The framework is model-agnostic — stronger foundation models produce better memory notes and retrieval, but no Opus-specific advantage has been demonstrated.

The key insight for model selection: A-Mem requires **multiple LLM calls** during memory processing (note creation, linking, retrieval). This makes it cost-sensitive — using Haiku for the frequent memory operations and Opus for the final reasoning step would be a sensible cost optimization pattern.

### ICLR 2026 Workshop

There is an upcoming ICLR 2026 Workshop on "Memory for LLM-Based Agentic Systems" (MemAgents) that may produce more model-comparative results.

---

## 6. Prompt Alchemist (MAPS)

### What It Is

"The Prompt Alchemist" (MAPS) is an automated prompt optimization framework for test case generation (January 2025). It uses three modules: diversity-guided prompt generation, failure-driven rule induction, and domain contextual knowledge extraction. Optimized prompts achieve 6.19% higher line coverage than static prompts.

### Opus Relevance

MAPS was tested on ChatGPT, Llama-3.1, and Qwen2 — not Claude models. The key finding relevant to model selection: **different LLMs tend to excel in different domains**, and "the importance of building tailored prompts for different LLMs" is a core conclusion.

This supports the general principle that prompt optimization should be model-aware, but doesn't provide specific guidance on Opus vs Sonnet selection.

---

## Summary

| Topic Area | Recommendation | Rationale |
|------------|---------------|-----------|
| Expert reasoning tasks | **Use Opus** | 17-point GPQA Diamond gap; compounds on multi-step problems |
| Long-context (>200K tokens) | **Use Opus** | Qualitative shift in retrieval accuracy at 1M tokens |
| Sustained agentic sessions | **Use Opus** | Less performance drift, better token efficiency on hard problems |
| Standard coding (SWE-bench) | **Use Sonnet** | Within 1.2 points at 1/5th cost; Sonnet 4.6 preferred 59% of time |
| Financial/quantitative | **Use Sonnet** | Sonnet leads Opus by 3.2 points on Finance Agent |
| Multi-agent coordination | **Use Opus** | Anthropic's explicit recommendation; Agent Teams designed for Opus |
| RL algorithm implementation | **Prefer Opus** | Reasoning depth matters for reward design, convergence analysis |
| A-Mem integration | **Model-agnostic** | No Opus-specific benchmarks; use Haiku for memory ops, Opus for reasoning |
| Prompt optimization (MAPS) | **Model-agnostic** | Not tested on Claude; framework is LLM-tailored by design |

## Key Takeaways

### Use Opus When
- Task requires multi-step expert reasoning (architectural decisions, security analysis, debugging complex systems)
- Working with very large context windows (>200K tokens, especially approaching 1M)
- Long-running agentic sessions with many tool calls
- Multi-agent coordination and orchestration
- Extended output generation (128K vs 64K max)

### Use Sonnet When
- Standard software engineering tasks (the gap is negligible)
- Cost-sensitive batch operations
- Latency-sensitive production environments
- Financial/quantitative analysis (Sonnet actually leads)
- Iteration-heavy development workflows

### Hybrid Pattern
The most effective pattern: **Sonnet for development and iteration, Opus for final review and complex reasoning steps**. This yields 60-80% cost savings without sacrificing quality where it counts.
