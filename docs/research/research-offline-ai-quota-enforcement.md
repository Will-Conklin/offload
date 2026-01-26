---
id: research-offline-ai-quota-enforcement
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
depends_on:
  - docs/prds/prd-0001-product-requirements.md
supersedes: []
accepted_by: null
accepted_at: null
related_issues: []
structure_notes:
  - "Section order: Summary; Findings; Recommendations; Sources."
---

# Research: Offline AI Quota Enforcement

## Summary

Explore options for enforcing AI usage quotas when the device is offline and
cloud enforcement is unavailable.

## Findings

### Finding 1

Local counters can be stored in app-specific settings (UserDefaults) for
lightweight tracking, but are not tamper-proof and can be cleared or reset.

### Finding 2

Keychain services provide a more secure local store for small pieces of data
and can reduce casual tampering, but they still cannot fully prevent device
level resets.

### Finding 3

DeviceCheck can be used to manage device state and reduce fraudulent usage
when a backend exists, but it requires network interaction and does not solve
offline enforcement by itself.

## Recommendations

- Use a local counter for offline UX (UserDefaults) and a secure mirror in
  Keychain for tamper resistance.
- Reconcile counters with a server when connectivity returns; treat local
  counters as provisional.
- If a backend exists, evaluate DeviceCheck as a defense-in-depth option for
  quota abuse and device integrity signals.

## Sources

- <https://developer.apple.com/documentation/foundation/userdefaults>
- <https://developer.apple.com/documentation/security/keychain-services>
- <https://developer.apple.com/documentation/devicecheck>
