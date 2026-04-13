# Feature Discussion: [Feature Name]

> **Feature ID:** F[XXX]
> **Status:** Discussion
> **Started:** YYYY-MM-DD

---

## Claude's Understanding

**What I understand you want:**
[Claude will fill this after reading idea.md]

**Key objectives:**
-
-
-

**Success looks like:**
-
-

---

## Clarifying Questions

[Claude asks questions to understand requirements better]

### Q1: [Claude's question]
**Your Answer:**

### Q2: [Claude's question]
**Your Answer:**

### Q3: [Claude's question]
**Your Answer:**

---

## Entity Analysis (Claude's Proposal)

[Claude identifies which entities this feature will create/modify]

### Existing Entities to Modify:

#### Module: [Name]
- **Location:** `libs/domain/[name]`
- **Changes needed:**
  - Database: [field changes]
  - Service: [method changes]
  - API: [endpoint changes]

#### Service: [Name]
- **Location:** `libs/backend/[name]`
- **Changes needed:**
  - [What needs to change]

### New Entities to Create:

#### Module: [Name] (NEW)
- **Type:** Module
- **Purpose:** [What it does]
- **Will contain:**
  - Database models: [list]
  - Services: [list]
  - API endpoints: [list]
  - Frontend pages: [list]

#### SubModule: [Name] (NEW)
- **Type:** SubModule
- **Parent:** [Parent module]
- **Purpose:** [What it does]
- **Will contain:**
  - [Components/services]

#### Service: [Name] (NEW)
- **Type:** Service
- **Purpose:** [What it does]
- **Responsibilities:**
  - [What it handles]

#### Processor: [Name] (NEW)
- **Type:** Processor
- **Purpose:** [Pure function - what transformation]
- **Input:** [Data type]
- **Output:** [Data type]

### Integration Points

**External Services:**
- [Service name] - For [purpose]

**Internal Services:**
- [Module/Service] - For [purpose]

---

## Alternative Approaches

[Claude proposes different ways to implement this]

### Approach A: [Name]
**How it works:**
[Description]

**Pros:**
-
-

**Cons:**
-
-

**When to use:**
[Scenario]

---

### Approach B: [Name]
**How it works:**
[Description]

**Pros:**
-
-

**Cons:**
-
-

**When to use:**
[Scenario]

---

## Your Decision

**Chosen Approach:** [A/B/Hybrid/Custom]

**Reasoning:**
[Why you chose this approach]

**Custom modifications:**
[Any adjustments to the proposed approach]

---

## Scope Refinement

**Confirmed in scope:**
-
-

**Confirmed out of scope:**
-
-

**Deferred to future:**
-
-

---

## Technical Decisions Made

[Key technical decisions agreed upon]

1. **[Decision topic]:** [Decision made] - Reason: [why]
2. **[Decision topic]:** [Decision made] - Reason: [why]
3. **[Decision topic]:** [Decision made] - Reason: [why]

---

## Risk Assessment

### Risk Register

| Risk | Probability | Impact | Mitigation Strategy | Owner |
|------|-------------|--------|---------------------|-------|
| [Describe risk] | Low/Medium/High | Low/Medium/High/Critical | [How to mitigate] | [Entity/Team] |
| [Example: OAuth API rate limits] | Medium | High | Implement exponential backoff, cache tokens | Backend |
| [Example: User links wrong account] | Low | Medium | Show account confirmation screen | UX |

**Risk Scoring:**
- **Critical Impact:** Feature completely fails
- **High Impact:** Major functionality broken
- **Medium Impact:** Partial functionality affected
- **Low Impact:** Minor inconvenience

**Overall Risk Level:** [Low/Medium/High]

**Assumptions:**
- [What we're assuming is true]
- [What we're assuming is true]

**Dependencies & Blockers:**
- [External dependency that could cause issues]
- [Internal blocker that might delay work]

---

## Agreements Reached

[Summary of all agreements]

- ✅ [Agreement 1]
- ✅ [Agreement 2]
- ✅ [Agreement 3]

---

**Status:** Discussion Complete ✅
**Next Step:** Generate specification using `/generate-spec [name]`
