//: [Previous](@previous)

import Foundation

// PART 3: BANK ACCOUNT SYSTEM
// Build a thread-safe banking system

enum TransferError: Error {
    case insufficientFunds
    case failedTransfer(String)
    case invalidAmount
    case selfTransfer
    case depositFailed(reason: String)
    case unexistingAccount
    
    var localized: String {
        switch self {
        case .insufficientFunds:
            "You have insufficient funds"
        case .failedTransfer(let account):
            "Account \(account) has insufficient funds for withdrawal"
        case .invalidAmount:
            "Amount must be bigger than 0"
        case .selfTransfer:
            "Cannot self transfer"
        case .depositFailed(let reason):
            reason
        case .unexistingAccount:
            "The account is not existing"
        }
    }
}

struct Transactions {
    
    let id: String
    let amount: Decimal
    let type: TransactionType
    
    enum TransactionType {
        case deposit
        case withdrawal
        case transferIn(from: String)
        case transferOut(to: String)
    }

}

actor BankAccount {
    // MARK: Stored properties
    let accountNumber: String
    private(set) var balance: Decimal
    private(set) var recordOfTransactions: [Transactions] = []
    
    init(accountNumber: String, initialBalance: Decimal) {
        self.accountNumber = accountNumber
        self.balance = initialBalance
    }
    
    // MARK: Deposit
    /// Menambahkan saldo.
    /// - Throws: invalidAmount if amount <= 0
    func deposit(_ amount: Decimal) async throws {
        // Add to balance
        
        guard amount > 0 else {
            throw TransferError.invalidAmount
        }
        
        self.balance += amount
        self.recordTransaction(type: .deposit, amount: amount)
    }
    
    func withdraw(_ amount: Decimal) async throws {
        // Remove from balance
        // Throw error if insufficient funds
        guard amount > 0 else {
            throw TransferError.invalidAmount
        }
        
        guard balance >= amount else {
            throw TransferError.failedTransfer(accountNumber)
        }
        self.balance -= amount
        self.recordTransaction(type: .withdrawal, amount: amount)
    }
    
    func transfer(
        to account: BankAccount?,
        amount: Decimal) async throws
    {
        ///check if you amount is bigger than 0
        guard amount > 0 else {
            throw TransferError.invalidAmount
        }
        
        guard let account = account else {
            throw TransferError.unexistingAccount
        }

        guard account.accountNumber != self.accountNumber else {
            throw TransferError.selfTransfer
        }
        
        var didWithdraw = false
        do {
            
            // withdraw from source
            try await withdraw(amount)
            
            didWithdraw = true
            // deposit to targeted account
            try await account.deposit(amount)
            
            //create success statement
            self.recordTransaction(type: .transferOut(to: account.accountNumber), amount: amount)
            await account.recordTransaction(type: .transferIn(from: self.accountNumber), amount: amount)
        } catch  {
            
            //if failed, then transfer back to the sender
            if didWithdraw {
                try await self.deposit(amount)
            }
            
            throw TransferError.depositFailed(reason: "Cannot transfer to \(account.accountNumber)")
        }
    }
    
    func getBalanceDescription() -> String {
        "Saldo \(self.accountNumber) adalah \(self.balance)"
    }
    
    private func recordTransaction(
        type: Transactions.TransactionType,
        amount: Decimal
    ) {
        let transaction = Transactions(
            id: self.accountNumber,
            amount: amount,
            type: type
        )
        recordOfTransactions.append(transaction)
        
    }
}

// TODO: Write comprehensive tests
func testBankingSystem() async throws {
    await testConcurrentDeposits()
    await testConcurrentTransfer()
    await testInsufficientFunds()
    await testInvalidOperations()
    await testRollbackTransfer()
}

func testConcurrentDeposits() async {
    print("Test 1: Concurrent Deposits")
    let account = BankAccount(accountNumber: "001", initialBalance: 0)
    
    await withTaskGroup(of: Void.self) { group in
        for i in 1...10 {
            group.addTask {
                do {
                    try await account.deposit(100)
                } catch {
                    print("Deposit failed: \(error)")
                }
                
            }
        }
    }
    
    let finalBalance = await account.balance
    let expected: Decimal = 1000
    
    if finalBalance == expected {
        print("PASS: Final balance = \(finalBalance)")
    } else {
        print("FAIL: Expected \(expected), got \(finalBalance)")
    }
}

func testInsufficientFunds() async {
    print("Test 2: Insufficient funds")
    let account = BankAccount(accountNumber: "100", initialBalance: 100)
    
    do {
        try await account.withdraw(500)
    } catch let error as TransferError {
        print(error.localized)
    } catch {
        print(error)
    }
}

func testConcurrentTransfer() async {
    print("Test 3: Concurrent Transfer")
    let accountRahmat = BankAccount(accountNumber: "007", initialBalance: 1000)
    let accountMarko = BankAccount(accountNumber: "010", initialBalance: 1000)
    
    await withTaskGroup(of: Void.self) { group in
        
        for transfer in 1...5 {
            group.addTask {
                do {
                    try await accountRahmat.transfer(to: accountMarko, amount: 200)
                } catch {
                    print(error)
                }
                
            }
            
            group.addTask {
                do {
                    try await accountMarko.transfer(to: accountRahmat, amount: 200)
                } catch {
                    print(error)
                }
                
            }
        }
    }
    
    let rahmatBalanceAfterTransfer = await accountRahmat.balance
    let markoBalanceAfterTransfer = await accountMarko.balance
    let totalBalance = rahmatBalanceAfterTransfer + markoBalanceAfterTransfer
    let expected: Decimal = 2000
    
    if totalBalance == expected {
        print("Pass the test for Transfer \(totalBalance)")
    } else {
        print("FAIL: Expected \(expected), got \(rahmatBalanceAfterTransfer)")
    }
}

func testInvalidOperations() async {
    print("Test 4: Invalid Operations")
    
    let account = BankAccount(accountNumber: "001", initialBalance: 1000)
    let account2 = BankAccount(accountNumber: "003", initialBalance: 500)
    
    do {
        try await account.transfer(to: account2, amount: 0)
    } catch let error as TransferError {
        print(error.localized)
    } catch {
        print(error.localizedDescription)
    }
    
}

func testRollbackTransfer() async {
    print("Test 5: Rollback Transfer")
    let account = BankAccount(accountNumber: "001", initialBalance: 1000)
    let account2 = BankAccount(accountNumber: "003", initialBalance: 500)
    
    do {
        try await account.transfer(to: account2, amount: 1100)
    } catch let error as TransferError {
        print(error.localized)
    } catch {
        print(error)
    }
}

// Test 6: Transfer to nil account (you handle it but don't test it)
func testTransferToNil() async {
    print("Test 6: Transfer to Nil Account")
    let account = BankAccount(accountNumber: "001", initialBalance: 1000)
    
    do {
        try await account.transfer(to: nil, amount: 100)
        print("FAIL: Should have rejected nil account")
    } catch TransferError.unexistingAccount {
        print("PASS: Rejected nil account transfer")
    } catch {
        print("FAIL: Wrong error type")
    }
}

// Test 7: Negative withdrawal
func testNegativeWithdrawal() async {
    print("Test 7: Negative Withdrawal")
    let account = BankAccount(accountNumber: "001", initialBalance: 1000)
    
    do {
        try await account.withdraw(-100)
        print("FAIL: Should reject negative amount")
    } catch TransferError.invalidAmount {
        print("PASS: Rejected negative withdrawal")
    } catch {
        print("FAIL: Wrong error")
    }
}

// Test 8: Multiple concurrent withdrawals causing overdraft
func testRaceConditionOverdraft() async {
    print("Test 8: Race Condition Overdraft Prevention")
    let account = BankAccount(accountNumber: "001", initialBalance: 500)
    var successCount = 0
    
    await withTaskGroup(of: Bool.self) { group in
        // Try to withdraw 200 five times simultaneously (total 1000 from 500 balance)
        for _ in 0..<5 {
            group.addTask {
                do {
                    try await account.withdraw(200)
                    return true
                } catch {
                    return false
                }
            }
        }
        
        for await success in group {
            if success {
                successCount += 1
            }
        }
    }
    
    let finalBalance = await account.balance
    
    // Should allow 2 withdrawals (400), reject 3
    if successCount == 2 && finalBalance == 100 {
        print("PASS: Correctly prevented overdraft, 2/5 succeeded")
    } else {
        print("FAIL: Expected 2 successes and 100 balance, got \(successCount) successes and \(finalBalance)")
    }
}

func sleep(_ secs: Int = 5) async {
    try? await Task.sleep(for: .seconds(secs))
}

Task {
    do {
           try await testBankingSystem()
       } catch {
           print("MAIN caught error:", error)
       }
}
