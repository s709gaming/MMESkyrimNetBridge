# Structured Shorthand Markdown

## General

- **Goal:** Instructions that humans and AI can scan quickly.
- **Style:** Short main instructions with supporting details underneath.

## Structure

- **Hierarchy:** `#` Title → `##` Section → `###` Subsection when needed.
- **Headers:** Keep headings short and descriptive.
  - Leave space between sections.
- **Bullets:** Use separate bullets for distinct instructions, rules or categories.
- **Labels:** Begin main bullets with a bold label and colon.
  - Use plain text for supporting bullets.
  - Add nested labels only when they identify distinct categories.
- **Nesting:** Group details beneath the instruction they support.
  - Use for steps, conditions, examples and exceptions.
  - Prefer one nested level; go deeper only when necessary.
- **Context:** Add a short opening Context bullet when the purpose needs explanation.

## Writing Rules

- **Length:** Keep one main idea per bullet.
  - Prefer one short sentence.
  - Use sibling bullets for separate instructions; nest supporting details.
- **Brevity:** Remove filler and repetition.
  - Preserve useful context, safeguards and exceptions.
  - Keep wording clear; avoid cryptic shorthand.
- **Grammar:** Sentence fragments are acceptable when clear.
- **Tone:** Direct and instructional.
- **Emphasis:** Bold labels and essential warnings.
  - Avoid bolding whole sentences.
- **Judgment:** Use structure to clarify relationships.
  - Avoid unnecessary labels, headings and nesting.

## Example

### Implementation

- **Context:** Multiple agents share the repository.
- **Concurrency:** Claim work before editing.
  - Record the task in `TASK.md`.
  - Review recent commits and local changes.
- **Compatibility:** Preserve existing behavior unless explicitly changed.
  - Reuse existing functions and calculations.
  - Check dependencies before changing shared code.
- **Verification:** Check the affected behavior.
  - Report passed, failed and untested checks.
