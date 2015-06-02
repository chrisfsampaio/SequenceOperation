
public class SequenceOperation: NSOperation {
    
    let semaphore: dispatch_semaphore_t
    let work: (SequenceOperation) -> Void
    public var movedOnBlock: (() -> Void)? = nil
    
    public init(block: (SequenceOperation) -> Void) {
        semaphore = dispatch_semaphore_create(0)
        work = block
    }
    
    override public func main() {
        
        assert(NSThread.currentThread().isMainThread == false, "Sequence does not play well on the main thread, you should instantiate a NSOperationQueue so that things can work out.")
        
        let previousOperations = dependencies.map() { $0 as! NSOperation }
        let previouslyCancelled = previousOperations.reduce(false) { before, operation in
            let cancel = before || operation.cancelled
            
            return cancel
        }
        
        if previouslyCancelled {
            cancel()
        }
        
        if !cancelled {
            work(self)
            dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
        } else {
            movedOnBlock?()
        }
    }
    
    public func moveOn() {
        movedOnBlock?()
        dispatch_semaphore_signal(semaphore)
    }
    
    public override func cancel() {
        super.cancel()
        moveOn()
    }
    
    public func chainAfter(#operation: NSOperation) -> Self {
        addDependency(operation)
        
        return self
    }

}

infix operator --> { associativity left precedence 140 }

public func --> (left: SequenceOperation, right: SequenceOperation) -> SequenceOperation {
    return right.chainAfter(operation: left)
}

public func runOperations(operations: [NSOperation], asynchronously: Bool = true) -> NSOperationQueue {
    
    let queue = NSOperationQueue()
    queue.addOperations(operations, waitUntilFinished: !asynchronously)
    
    return queue
}
