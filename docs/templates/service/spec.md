# Service: [Name]

> **Type:** Service
> **Category:** Integration | Background Job | Coordination | Cache | etc.
> **Status:** Draft

---

## Purpose

[One paragraph: What does this service do and why?]

---

## Use Cases

### Use Case 1: [Name]
**Trigger:** [What causes this service to run]
**Process:**
1. [Step 1]
2. [Step 2]
3. [Step 3]

**Result:** [What changes/happens]

[Repeat for each use case]

---

## Technical Specification

### Dependencies

**External Services:**
- [Service name] - For [purpose]
- [API] - For [purpose]

**Internal Dependencies:**
- `libs/domain/[feature]` - For [purpose]
- `@app/database` - For [data access]

**Infrastructure:**
- Redis - For [caching/queues/etc.]
- S3 - For [storage]
- etc.

### Configuration

**Environment Variables:**
```typescript
SERVICE_API_KEY=xxx
SERVICE_ENDPOINT=https://api.example.com
RETRY_ATTEMPTS=3
TIMEOUT_MS=5000
```

### Methods

```typescript
class [ServiceName]Service {
  /**
   * [Description]
   * @param input - [description]
   * @returns [description]
   * @throws [Error] - When [condition]
   */
  async execute(input: InputType): Promise<OutputType> {
    // Implementation
  }

  /**
   * [Description]
   */
  async retry(operationId: string): Promise<void> {
    // Implementation
  }
}
```

---

## Data Flow

```
[Input Source]
    ↓
[ServiceName]
    ↓ (calls)
[External API / Database / Queue]
    ↓
[Result/Side Effect]
```

---

## Error Handling

**Transient Errors (retry):**
- Network timeouts
- Rate limits
- Temporary service unavailable

**Permanent Errors (fail immediately):**
- Invalid authentication
- Malformed data
- Business rule violation

**Retry Strategy:**
- Max attempts: 3
- Backoff: Exponential (1s, 2s, 4s)
- Dead letter queue: [Yes/No]

---

## Logging & Monitoring

**Log Events:**
- Service started
- External API called
- Retry attempted
- Operation completed
- Operation failed

**Metrics to Track:**
- Success rate
- Average execution time
- Error rate by type
- Queue depth (if applicable)

**Alerts:**
- Error rate > 5% for 5 minutes
- Execution time > 30 seconds
- Queue depth > 1000

---

## Security Considerations

- [ ] API keys stored in environment variables
- [ ] Secrets not logged
- [ ] Rate limiting applied
- [ ] Input validation
- [ ] Output sanitization

---

## Testing Strategy

### Unit Tests
- [ ] Happy path for each method
- [ ] Error handling
- [ ] Retry logic
- [ ] Edge cases

### Integration Tests
- [ ] External API calls (mocked)
- [ ] Database operations
- [ ] Queue operations

### Load Tests (if applicable)
- [ ] Handle X requests per second
- [ ] Graceful degradation under load

---

## Implementation Checklist

### Setup
- [ ] Create service file in `libs/[category]/[service-name]/`
- [ ] Define interfaces and types
- [ ] Setup configuration/env validation

### Core Logic
- [ ] Implement main execution method
- [ ] Implement retry logic
- [ ] Implement error handling
- [ ] Add logging

### Integration
- [ ] Setup external API client
- [ ] Configure authentication
- [ ] Test connectivity

### Testing
- [ ] Write unit tests (70%+ coverage)
- [ ] Write integration tests
- [ ] Manual testing

### Deployment
- [ ] Document environment variables
- [ ] Setup monitoring/alerts
- [ ] Deploy to staging
- [ ] Smoke test
- [ ] Deploy to production

---

## Rollback Plan

**If service fails in production:**
1. [Immediate action]
2. [Fallback behavior]
3. [Data recovery steps]

---

## Performance Considerations

- Caching strategy: [description]
- Rate limiting: [X requests per minute]
- Timeout settings: [Y seconds]
- Concurrency limits: [Z parallel operations]

---

## Future Improvements

- [ ] [Potential enhancement]
- [ ] [Potential enhancement]

---

**Estimated effort:** 1-3 sessions
**Next step:** Review and approve, then implement
