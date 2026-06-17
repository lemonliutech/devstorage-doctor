# Implement named exception reporting

## Goal

Make failures visible and actionable.

## Acceptance Criteria

- Cleanup and scan failures map to named exception types.
- Report includes path, operation, command, stderr when available, and suggested next action.
- Partial cleanup is represented explicitly.
- Failed items do not hide successful cleanup results.
