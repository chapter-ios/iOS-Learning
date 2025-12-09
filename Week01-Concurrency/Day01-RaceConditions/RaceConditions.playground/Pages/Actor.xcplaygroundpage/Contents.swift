
import Foundation
import PlaygroundSupport

PlaygroundPage.current.needsIndefiniteExecution = true

/// Thread-safe counter using Actor isolation.
/// Actor ensures serial execution of all methods, preventing
/// race conditions during concurrent read-modify-write operations.

actor SafeCounter {
    /// Current count value.
    /// Access is synchronized through the actor's serial executor.

    private(set)var value = 0
    
    /// Increments counter by 1.
    /// This operation is atomic because the actor serializes all access.
    /// Multiple concurrent calls will execute sequentially, not in parallel.
    func increment() {
        value += 1
    }
    
    //restarting element each time it finish incrementing
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
    let numberOfTask = 10
    let runCount = 5
    let expectedTotal = numberOfTask * iterations
    
    // TODO: Run 10 concurrent tasks, each incrementing 1000 times
    // Expected total: 10,000
    // Print actual result
    // Run this test 5 times and document results
    
    // YOUR CODE HERE
    await benchMark("unsafe Counter ") {
        for run in 0..<runCount {
            print("start unsafesafecounter run number \(run)")
            await withTaskGroup(of: Int.self) { group in
                for _ in 0..<numberOfTask {
                    for count in 0..<iterations {
                        group.addTask {
                            
                            counter.increment()
                            return counter.value
                        }
                    }
                    
                }
            }
            print("finish unsafecounter run number \(run), Result ->>> \(counter.value), expected \(expectedTotal)")
            counter.restart()
        }
    }
  
}

func testSafeCounter() async {
    let counter = SafeCounter()
    let iterations = 1000
    let numberOfTask = 10
    let runCount = 5
    let expectedTotal = numberOfTask * iterations
    
    // TODO: Run 10 concurrent tasks, each incrementing 1000 times
    // Expected total: 10,000
    // Print actual result
    // Run this test 5 times and document results
    
    // YOUR CODE HERE
    await benchMark("safe counter") {
        for run in 0..<runCount {
            print("start safecounter run number \(run)")
            await withTaskGroup(of: Int.self) { group in
                for _ in 0..<numberOfTask {
                    for count in 0..<iterations {
                        group.addTask {
                            
                            await counter.increment()
                            return await counter.value
                        }
                    }
                    
                }
            }
            print("finish safecounter run number \(run), Result ->>> \(await counter.value), expected \(expectedTotal)")
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
