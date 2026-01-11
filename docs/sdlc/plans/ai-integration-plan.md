<!-- Intent: Outline the phased AI integration scope, dependencies, and
execution order for Offload’s capture → suggestion workflows. -->

# AI Integration Plan

## Agent Navigation
- Overview: Goals + Non-Goals
- Scope: Phase 0-2
- Dependencies: iOS + Backend
- Milestones: Deliverables
- Risks: Open Questions

## Overview

This plan defines a phased approach to integrate AI-assisted organization in
Offload. The goal is to ship a safe, opt-in workflow that supports user control
and minimal friction.

## Goals

- Provide AI suggestions for organizing captures into plans/tasks/lists.
- Keep users in control (no auto-modifications).
- Support offline-first behavior with graceful fallback.

## Non-Goals (for initial integration)

- Complex project management automations.
- Mandatory AI usage.
- Automatic placements without confirmation.

## Scope

### Phase 0: iOS Readiness

- Add AI settings (opt-in, endpoint, privacy copy).
- Ensure capture → hand-off flow is stable.
- Provide UI placeholders for suggestions list + decisions.

### Phase 1: Suggestion Pipeline (Local)

- Define `HandOffRequest` creation trigger.
- Create a local mock suggestion provider for UI testing.
- Wire `CaptureWorkflowService` to generate mock suggestions.

### Phase 2: Backend Integration

- Define API contract (request/response).
- Implement API client calls and error handling.
- Add retry + user-facing error states.

## Dependencies

### iOS

- `CaptureWorkflowService` hand-off endpoints
- `Suggestion` and `SuggestionDecision` views
- Settings toggles and endpoint configuration

### Backend

- API service scaffolding (auth TBD)
- Suggestion generation endpoint
- Observability/logging

## Milestones

1. **UI Wireframe**: Suggestion list + decision UI in Organize
2. **Mock Provider**: Local mock suggestions in iOS
3. **Backend Contract**: API spec + error model
4. **End-to-End**: Capture → hand-off → suggestions → decision

## Open Questions

- Auth model for AI endpoints?
- Should AI run only on demand or auto-trigger per capture?
- How should suggestion confidence be represented?
