## Story Template

Create `docs/story-template.md` for consistent story format:

```markdown
# [Epic.Story] Story Title

**Status:** Draft | Approved | InProgress | Review | Done
**Priority:** Critical | High | Medium | Low
**Estimate:** X days

---

## User Story

As a [type of user]
I want [goal/desire]
So that [benefit/value]

---

## Acceptance Criteria

- [ ] AC1: [Specific, testable criterion]
- [ ] AC2: [Specific, testable criterion]
- [ ] AC3: [Specific, testable criterion]

---

## Tasks

- [ ] Task 1: [Action] at [file path]
- [ ] Task 2: [Action] at [file path]
- [ ] Task 3: Write tests for [component]
- [ ] Task 4: Update [documentation/types]

---

## Dev Notes

### File Paths
**Create:**
- `path/to/NewComponent.tsx`
- `path/to/NewComponent.test.tsx`

**Modify:**
- `path/to/existing.ts`

### Technical Requirements
- [Pattern to follow]
- [Library to use]
- [Standard to apply]

### API Contracts (if applicable)
```
Endpoint: METHOD /api/path
Request: { field: type }
Response: { data: type }
```

### Database Changes (if applicable)
```bash
npx prisma migrate dev --name migration-name
```

---

## Testing Requirements

- [ ] Unit tests for [components]
- [ ] Integration tests for [API routes]
- [ ] Edge cases: [list]

---

## Dependencies

- Depends on: [Story X.Y]
- Blocks: [Story X.Y]

---

## Dev Agent Record
<!-- Filled by developer agent after implementation -->

---

## QA Results
<!-- Filled by QA agent after review -->
