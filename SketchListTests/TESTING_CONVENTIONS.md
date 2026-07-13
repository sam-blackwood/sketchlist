---
name: sketchlist-test-conventions
description: Conventions for writing unit tests in SketchList (Swift Testing). Apply whenever creating or editing test files — enforces descriptive @Test names and context strings on every #expect/#require.
---

# SketchList Unit Test Conventions

These rules apply to all tests in the SketchList test targets. They exist so that a
failing test reads like a sentence: *what was being tested* and *what specifically went
wrong* should both be obvious from the failure output, without opening the source.

## Rule 1 — Every `@Test` has a description string

Use Swift Testing's display-name form. The string states, in plain language, the
behavior under test. Do not rely on the function name alone.

```swift
// ✗ Avoid
@Test func testWrappingFrom12To1MajorKey() throws { ... }

// ✓ Prefer
@Test("Compatible keys wrap from 12B down to 1B on the major wheel")
func wrapsFrom12To1Major() throws { ... }
```

The function name can stay terse; the description carries the meaning and is what shows
up in the test navigator and reports.

## Rule 2 — Every `#expect` (and `#require`) has a context string

Every assertion passes a trailing `Comment` explaining what is being verified and/or
what a failure implies. No bare assertions.

```swift
// ✗ Avoid
#expect(recommendations.count == limit)

// ✓ Prefer
#expect(recommendations.count == limit,
        "Should return exactly `limit` recommendations when enough candidates exist")
```

On failure, Swift Testing prints the comment alongside the evaluated expression, turning
a red ✗ into a self-explaining diagnostic. This applies to `#require` as well.

## Notes

- These are conventions for *tests*, not production code.
- When multiple assertions in one test check facets of the same behavior, each still gets
  its own context string.
- To make this auto-apply as a Cowork skill, add it via Settings → Capabilities (this file
  is already in `SKILL.md` format).
