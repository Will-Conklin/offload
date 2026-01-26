---
id: research-on-device-ai-feasibility
type: research
status: completed
owners:
  - Will-Conklin
applies_to:
  - ai
  - research
last_updated: 2026-01-25
related:
  - prd-0001-product-requirements
  - prd-0007-smart-task-breakdown
  - prd-0008-brain-dump-compiler
  - prd-0010-tone-assistant
  - prd-0011-executive-function-prompts
  - prd-0012-decision-fatigue-reducer
depends_on:
  - docs/prds/prd-0001-product-requirements.md
supersedes: []
accepted_by: null
accepted_at: null
related_issues: []
structure_notes:
  - "Section order: Summary; Findings; Recommendations; Sources."
---

# Research: On-Device AI Feasibility for Offload

## Summary

Assess feasibility and constraints for on-device AI to support Offload features
like breakdowns, compilation, tone transformation, and prompts.

## Findings

### Finding 1

Apple’s machine learning platform emphasizes on-device execution, including
offline-capable experiences and private inference. This supports Offload’s
offline-first and privacy goals, but implies constraints on model size and
latency.

### Finding 2

Core ML is the primary integration path for on-device models on Apple
platforms. It is suitable for packaging smaller models and running inference
locally, but large language models may need aggressive optimization or a cloud
fallback.

### Finding 3

On-device AI implies device variability (older devices, memory constraints)
and a need for clear performance budgets per feature (latency, memory, and
battery).

## Recommendations

- Define target device classes and budgets for model size and latency per
  feature before committing to on-device-only AI.
- Plan for a hybrid approach: on-device first, with optional cloud fallback for
  larger contexts or higher quality.
- Build benchmarking harnesses for representative tasks (short prompts vs long
  brain dumps) across a low-end device and a current flagship.

## Sources

- <https://developer.apple.com/machine-learning/>
- <https://developer.apple.com/documentation/coreml>
