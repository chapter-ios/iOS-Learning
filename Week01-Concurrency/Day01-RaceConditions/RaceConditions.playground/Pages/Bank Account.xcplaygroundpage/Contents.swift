//: [Previous](@previous)

import Foundation

// PART 3: BANK ACCOUNT SYSTEM
// Build a thread-safe banking system

enum TransferError: Error {
    case insufficientFunds
    case failedTransfer(String)
    
    var localized: String {
        switch self {
        case .insufficientFunds:
            "You have insufficient funds"
        case .failedTransfer(let account):
            "anda \(account) Tidak memiliki dana yg cukup"
        }
    }
}

actor BankAccount {
    let accountNumber: String
    private(set) var balance: Decimal
    
    init(accountNumber: String, initialBalance: Decimal) {
        self.accountNumber = accountNumber
        self.balance = initialBalance
    }
    
    // TODO: Implement these methods
    func deposit(_ amount: Decimal) {
        // Add to balance
        self.balance += amount
    }
    
    func withdraw(_ amount: Decimal) throws {
        // Remove from balance
        // Throw error if insufficient funds
        
        guard balance >= amount else {
            throw TransferError.failedTransfer(accountNumber)
        }
        self.balance -= amount
    }
    
    func transfer(
        to account: BankAccount,
        amount: Decimal) async throws
    {
        // TODO: THIS IS TRICKY!
        // You need to interact with another actor
        // How do you ensure atomicity?
        // What if withdrawal succeeds but deposit fails?
        var accounts = account
        
        if self.balance >= amount {
            do {
                // first, withdraw from your current balance
                try withdraw(amount)
                
                // deposit to targeted account
                await account.deposit(amount)
                
                //create success statement
                await berhasilTransaksi(
                    account,
                    nominal: amount
                )
                
            } catch let error as TransferError {
                throw TransferError.failedTransfer(self.accountNumber)
            }
            
            
        } else {
            throw TransferError.failedTransfer(self.accountNumber)
        }
    }
    
    func lihatsaldo() -> String {
        "Saldo \(self.accountNumber) adalah \(self.balance)"
    }
    
    private func berhasilTransaksi(
        _ account: BankAccount,
        nominal: Decimal
    ) async {
        let komunikasi =
"""
======================================================================
Berhasil melakukan Transaksi ke \(account.accountNumber) sejumlah \(nominal)
Jumlah Saldo Anda \(self.accountNumber) \(self.balance)
Jumlah Saldo \(account.accountNumber) adalah \(await account.balance)
======================================================================
"""
        print(komunikasi)
    }
}

// TODO: Write comprehensive tests
func testBankingSystem() async throws {
    let account1 = BankAccount(accountNumber: "001", initialBalance: 1000)
    let account2 = BankAccount(accountNumber: "002", initialBalance: 500)
    
    // Test 1: Concurrent deposits should all succeed
    // Test 2: Concurrent withdrawals should respect balance
    // Test 3: Concurrent transfers between accounts
    // Test 4: Attempt to overdraw should throw error
    
    // YOUR TESTS HERE

    print("transaksi sejumlah 200 dari akun 1 ke akun 2")
    await sleep()
    async let result2 = await (account1.transfer(to: account2, amount: 200), account1.lihatsaldo(), account2.lihatsaldo())
    print(try await result2)
    
    await sleep()
    print("akan withdraw 300")
    await sleep()
    let result3 = await (try account2.withdraw(300), account2.lihatsaldo())
    print("\(result3.1)")
    
    
    do {
        await sleep()
        print("coba gagal withdraw")
        try await account1.withdraw(1100)
    } catch let error as TransferError {
        print(error.localized)
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
