# Model Registry (Single Source of Truth)

This file defines allowed AI models, capabilities, and routing rules for `devine`.

## Registry Contract

Each model entry must include:

- `model_name`
- `model_version`
- `modalities`
- `supports_structured_output`
- `supports_function_calling`
- `max_context_tokens`
- `default_temperature_by_workflow`
- `latency_targets_ms`
- `status` (`active`, `canary`, `disabled`)

## Initial Entries

### Primary

- model_name: `gemini-3-pro`
- model_version: `current`
- modalities: `text,image`
- supports_structured_output: `true`
- supports_function_calling: `true`
- status: `active`

### Fallback Placeholder

- model_name: `gemini-3-pro-fallback`
- model_version: `current`
- modalities: `text,image`
- supports_structured_output: `true`
- supports_function_calling: `true`
- status: `disabled`

## Routing Policy

- All workflows default to active primary model.
- Canary rollout path for upgrades:
  - 1% -> 5% -> 25% -> 100%
- Roll back immediately if:
  - schema pass rate drops below threshold
  - latency exceeds target for sustained window
  - safety violation rate increases

## Capability Gate

A candidate model cannot ship unless all are true:

- structured output support is verified
- function calling support is verified
- golden test suite passes
- schema validation pass rate meets threshold
- safety policy tests pass

## Observability Minimum

Track per workflow:

- request count
- p50/p95 latency
- schema validation pass/fail
- repair loop invocation rate
- fallback response rate
- user completion outcome (downstream)
