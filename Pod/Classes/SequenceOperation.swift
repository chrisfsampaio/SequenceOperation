
public class SequenceOperation: NSOperation {
    
    internal let semaphore: dispatch_semaphore_t
    internal let work: (SequenceOperation) -> Void
    public var movedOnBlock: ((Bool, NSOperation?, NSError?) -> Void)? = nil
    
    typealias CancelOperation = (operation: NSOperation, error: NSError?)
    private var cancelledOperation: CancelOperation? = nil
    
    public init(block: (SequenceOperation) -> Void) {
        semaphore = dispatch_semaphore_create(0)
        work = block
    }
    
    override public func main() {
        
        assert(NSThread.currentThread().isMainThread == false, "Sequence does not play well on the main thread, you should instantiate a NSOperationQueue so that things can work out.")
        
        let previouslyCancelled = dependencies.reduce(false) { before, operation in
            let cancel = before || operation.cancelled
            
            return cancel
        }
        
        if previouslyCancelled {
            if let previousOperation = previousCancelledOperation() {
                cancelledOperation = previousOperation
            }
            cancelSilently()
        }
        
        if !cancelled {
            work(self)
            dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
        }
    }
    
    public func moveOn() {
        moveOn(true)
    }
    
    private func moveOn(finished: Bool) {
        
        //arvore não atinge mais de um nível, passar cancelledOperation de um nível para outro ao propagar cancelamento
        let cancelOperation = previousCancelledOperation()
        
        movedOnBlock?(finished, cancelOperation?.operation, cancelOperation?.error)
        dispatch_semaphore_signal(semaphore)
    }
    
    private func previousCancelledOperation() -> CancelOperation? {
        let previousOperations = dependencies.filter() { $0 is SequenceOperation } as! [SequenceOperation]
        let cancelOperation = previousOperations.filter() { $0.cancelledOperation != nil }.first?.cancelledOperation
        
        return cancelOperation
    }
    
    public override func cancel() {
        super.cancel()
        cancelledOperation = (operation: self, error: nil)
        moveOn(false)
    }
    
    private func cancelSilently() {
        super.cancel()
        moveOn(false)
    }
    
    public func cancel(error: NSError?) {
        super.cancel()
        cancelledOperation = (operation: self, error: error)
        moveOn(false)
    }
    
    public func chainAfter(operation operation: NSOperation) -> Self {
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
