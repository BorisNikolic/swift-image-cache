---
name: run-tests
description: Run unit tests for RoundsImageKit
disable-model-invocation: true
argument-hint: "[optional-specific-test-class]"
---

Run unit tests for: $ARGUMENTS

## Workflow

1. **Determine what to test**:
   - If `$ARGUMENTS` specifies a test class, use that directly
   - Otherwise, run all tests
2. **Run tests**:
   ```bash
   xcodebuild test -scheme RoundsImageKitTests \
     -destination 'platform=iOS Simulator,name=iPhone SE (3rd generation),OS=18.6' \
     2>&1 | grep -E "Test case|passed|failed|error:"
   ```
3. **Report results**: List passed/failed tests with details
