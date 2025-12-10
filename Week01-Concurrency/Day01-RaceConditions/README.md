# Day 1: Race Conditions and Actor Isolation

## What I Learned

[3-4 paragraphs explaining race conditions, why they happen, and how actors solve them]
- Race conditions occur when multiple threads access the same shared resource 
concurrently without proper synchronization. This leads to unpredictable 
outcomes because the final result depends on the timing of thread execution, 
which can vary between runs.

Actors solve this by serializing access to their state. All methods on an 
actor execute one at a time, even when called from multiple concurrent tasks. 
This prevents race conditions without manual locking.
## Results

### Unsafe Counter Test Results
| Run | Expected | Actual | Lost Increments |
|-----|----------|--------|-----------------|
| 1   | 10000    | 9985   | 153             |
| 2   | 10000    | 9991   | 009             |
| 3   | 10000    | 9992   | 008             |
| 4   | 10000    | 9990   | 010             |
| 5   | 10000    | 9991   | 009             |
...

### Performance Comparison
- UnsafeCounter: 0.762113083 seconds
- SafeCounter (Actor): 0.652842834 seconds
- Overhead: Z%

## Bank Account Implementation

### Design Decisions
I implemented the transfer using a **two-phase commit pattern**:

**Phase 1: Withdraw**
- First, withdraw from the source account
- If this fails (insufficient funds), abort immediately
- Track success with `didWithdraw` flag

**Phase 2: Deposit**
- Deposit to the target account
- If this fails, rollback Phase 1 by re-depositing to source

**Why this approach?**
- Ensures atomicity: both operations succeed or both fail
- Prevents money from being lost in the system
- Handles edge cases like deposit failures gracefully

**Alternative considered:** Locking both accounts before starting. Rejected 
because actors already provide serialization, and this could cause deadlocks 
if two transfers happen in opposite directions simultaneously.

### Edge Cases Handled
1. The balance is less than the withdraw -> Insufficient Funds
2. Transaction is less than 1 -> Invalid amount
3. User transfer to its own account -> Self Transfer
4. deposit Failure -> Deposit Failed
5. failed transfer because of lack of amount -> Failed transfer
6. User transfer to unexisting Account -> UnexistingAccount

## Questions / Uncertainties

**Q: Do actors create actual parallel execution, or just concurrent execution?**

A: Actors provide *concurrency* (interleaved execution) but not *parallelism* 
(simultaneous execution). The actor's serial executor ensures only one method 
runs at a time, but the calling tasks can be on different threads. The actor 
serializes their access to its state.

**Q: Why does the unsafe counter lose increments even though += is a single line?**

A: Because `value += 1` is actually three operations:
1. Read current value
2. Add 1
3. Write new value

Multiple threads can interleave these steps, causing lost updates.


## Code Quality Checklist
- [ ] No force unwraps
- [ ] No force try
- [ ] All errors properly handled
- [ ] Comments explain WHY, not WHAT
- [ ] Tests cover edge cases
