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
    - jika ya:
        - withdraw dari current account
        - deposit dari account yg dituju -> account.deposit
        - print hasil
    - else:
        - throw transfer error

### Edge Cases Handled
1. balance < amount
2. 

## Questions / Uncertainties

[List anything you're still confused about]
- why in real worl projects, mvvm and singleton not using actors

## Code Quality Checklist
- [ ] No force unwraps
- [ ] No force try
- [ ] All errors properly handled
- [ ] Comments explain WHY, not WHAT
- [ ] Tests cover edge cases
