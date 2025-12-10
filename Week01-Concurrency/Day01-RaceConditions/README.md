# Day 1: Race Conditions and Actor Isolation

## What I Learned

[3-4 paragraphs explaining race conditions, why they happen, and how actors solve them]
- race conditions terjadi ketika beberapa thread mengakses kepada source yg sama dan menyebabkan outcome yg di hasilkan menjadi acak dan tidak terprediksi. actors menjadi solusi karena membuat source tersebut hanya bisa di akses sekali-sekali atau berurutan. sehingga logic tidak tercampur. 

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
[Explain how you handled the transfer method]
- kita bandingkan terlebih dahulu balance >= amount
    - if yes:
        - withdraw dari current account
        - deposit dari account yg dituju -> account.deposit
        - print hasil
    - else:
        - throw transfer error

### Edge Cases Handled
1. The balance is less than the withdraw -> Insufficient Funds
2. Transaction is less than 1 -> Invalid amount
3. User transfer to its own account -> Self Transfer
4. deposit Failure -> Deposit Failed
5. failed transfer because of lack of amount -> Failed transfer
6. User transfer to unexisting Account -> UnexistingAccount

## Questions / Uncertainties

[List anything you're still confused about]
- do actor make thread which call it to be parallel, eventhough it is concurrency

## Code Quality Checklist
- [ ] No force unwraps
- [ ] No force try
- [ ] All errors properly handled
- [ ] Comments explain WHY, not WHAT
- [ ] Tests cover edge cases
