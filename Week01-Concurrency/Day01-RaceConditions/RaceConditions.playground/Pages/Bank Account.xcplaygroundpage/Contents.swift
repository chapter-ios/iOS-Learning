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
            "You \(account) don't have enough amount of money"
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
    /// - Throws: invalidAmount jika amount <= 0
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
    
    func lihatsaldo() -> String {
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
                try? await accountRahmat.transfer(to: accountMarko, amount: 200)
            }
            
            group.addTask {
                try? await accountMarko.transfer(to: accountRahmat, amount: 200)
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
