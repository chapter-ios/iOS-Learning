
import Foundation
import PlaygroundSupport

PlaygroundPage.current.needsIndefiniteExecution = true


// Implementing safe counter using actor, actor can only be accessed one by one from the other thread, so they wont berebutan when try to access the increment
actor SafeCounter {
    var value = 0
    
    func increment() {
        value += 1
    }
    
    func restart() {
        value = 0
    }
}
    
// PART 1: UNSAFE COUNTER
class UnsafeCounter: @unchecked Sendable {
    var value = 0
    
    func increment() {
        value += 1
    }
    
    func restart() {
        value = 0
    }
}

func testUnsafeCounter() async {
    let counter = UnsafeCounter()
    let iterations = 1000
    
    // TODO: Run 10 concurrent tasks, each incrementing 1000 times
    // Expected total: 10,000
    // Print actual result
    // Run this test 5 times and document results
    
    // YOUR CODE HERE
    await benchMark("unsafe Counter ") {
        for run in 1...5 {
            print("start run ke \(run)")
            await withTaskGroup(of: Int.self) { group in
                for _ in 0...9 {
                    for count in 0..<iterations {
                        group.addTask {
                            
                            counter.increment()
                            return counter.value
                        }
                    }
                    
                }
            }
            print("finish run ke \(run), final result ->>> \( counter.value)")
            counter.restart()
        }
    }
  
}

func testSafeCounter() async {
    let counter = SafeCounter()
    let iterations = 1000
    
    // TODO: Run 10 concurrent tasks, each incrementing 1000 times
    // Expected total: 10,000
    // Print actual result
    // Run this test 5 times and document results
    
    // YOUR CODE HERE
    await benchMark("safe counter") {
        for run in 1...5 {
            print("start run ke \(run)")
            await withTaskGroup(of: Int.self) { group in
                for _ in 0...9 {
                    for count in 0..<iterations {
                        group.addTask {
                            
                            await counter.increment()
                            return await counter.value
                        }
                    }
                    
                }
            }
            print("finish run ke \(run), final result ->>> \(await counter.value)")
            await counter.restart()
        }
    }
    
}

// Run the test
Task {
    await testUnsafeCounter()
    await testSafeCounter()
}

//Benchmark
func benchMark(
    _ label: String,
    block: () async -> Void
) async {
    let clock = ContinuousClock()
    let start = clock.now
    await block()
    let duration = clock.now.duration(to: start)
    print("\(label): \(duration)")
}
