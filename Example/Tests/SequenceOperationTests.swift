//
//  SequenceOperationTests.swift
//  SequenceOperation
//
//  Created by Christian Sampaio on 6/2/15.
//  Copyright (c) 2015 CocoaPods. All rights reserved.
//

import UIKit
import XCTest
import Nimble
import SequenceOperation

func after(seconds: NSTimeInterval, completion: () -> Void) {
    let interval = Int64(seconds * Double(NSEC_PER_SEC))
    let when = dispatch_time(DISPATCH_TIME_NOW, interval)
    dispatch_after(when, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, .allZeros), completion)
}

class SequenceOperationTests: XCTestCase {

    func testRunOperations() {
        
        var ranFirstOperation = false
        var ranSecondOperation = false
        
        let firstOperation = SequenceOperation { operation in
            after(1) {
                ranFirstOperation = true
                operation.moveOn()
            }
        }
        
        let secondOperation = SequenceOperation { operation in
            ranSecondOperation = true
            operation.moveOn()
        }
        
        runOperations([firstOperation, secondOperation])
        
        expect(ranFirstOperation).toEventually(beTruthy(), timeout: 2)
        expect(ranSecondOperation).toEventually(beTruthy(), timeout: 2)
    }
    
    func testChaining() {
        
        var ranFirstOperation = false
        var ranSecondOperation = false
        
        let firstOperation = SequenceOperation { operation in
            
            expect(ranFirstOperation).to(beFalsy())
            expect(ranSecondOperation).to(beFalsy())
            
            after(1) {
                expect(ranFirstOperation).to(beFalsy())
                expect(ranSecondOperation).to(beFalsy())
                ranFirstOperation = true
                operation.moveOn()
            }
        }
        
        let secondOperation = SequenceOperation { operation in
            expect(ranFirstOperation).to(beTruthy())
            expect(ranSecondOperation).to(beFalsy())
            ranSecondOperation = true
            operation.moveOn()
        }
        
        firstOperation --> secondOperation
        
        let queue = NSOperationQueue()
        queue.addOperation(secondOperation)
        queue.addOperation(firstOperation)
        
        expect(ranFirstOperation).toEventually(beTruthy(), timeout: 2)
        expect(ranSecondOperation).toEventually(beTruthy(), timeout: 2)
    }
    
    func testChainingWithRunOperations() {
        var ranFirstOperation = false
        var ranSecondOperation = false
        
        let firstOperation = SequenceOperation { operation in
            
            expect(ranFirstOperation).to(beFalsy())
            expect(ranSecondOperation).to(beFalsy())
            
            after(1) {
                expect(ranFirstOperation).to(beFalsy())
                expect(ranSecondOperation).to(beFalsy())
                ranFirstOperation = true
                operation.moveOn()
            }
        }
        
        let secondOperation = SequenceOperation { operation in
            expect(ranFirstOperation).to(beTruthy())
            expect(ranSecondOperation).to(beFalsy())
            ranSecondOperation = true
            operation.moveOn()
        }
        
        secondOperation.movedOnBlock = { finished, operation, error in
            expect(finished).to(beTruthy())
            expect(operation).to(beNil())
            expect(error).to(beNil())
            expect(ranFirstOperation).to(beTruthy())
            expect(ranSecondOperation).to(beTruthy())
        }
        
        firstOperation --> secondOperation
        runOperations([secondOperation, firstOperation])
        
        expect(ranFirstOperation).toEventually(beTruthy(), timeout: 2)
        expect(ranSecondOperation).toEventually(beTruthy(), timeout: 2)
    }
    
    func testErrorPropagation() {
        var ranFirstOperation = false
        var ranSecondOperation = false
        var ranThirdOperation = false
        
        let expectedError = NSError(domain: "", code: 1, userInfo: nil)
        
        let firstOperation = SequenceOperation { operation in
            after(1) {
                ranFirstOperation = true
                operation.cancel(expectedError)
            }
        }
        firstOperation.name = "A"
        
        let secondOperation = SequenceOperation { operation in
            expect(ranFirstOperation).to(beTruthy())

            after(1) {
                ranSecondOperation = true
                operation.moveOn()
            }
        }
        secondOperation.name = "B"
        secondOperation.movedOnBlock = { finished, operation, error in
            expect(finished).to(beFalsy())
            expect(operation).to(beIdenticalTo(firstOperation))
            expect(error).to(beIdenticalTo(expectedError))
            expect(ranFirstOperation).to(beTruthy())
            expect(ranSecondOperation).to(beFalsy())
            expect(ranThirdOperation).to(beFalsy())
        }
        
        let thirdOperation = SequenceOperation { operation in
            ranThirdOperation = true
            expect(ranThirdOperation).to(raiseException(named: "shouldn't had ran this operation"))
            operation.moveOn()
        }
        
        thirdOperation.movedOnBlock = { finished, operation, error in
            expect(finished).to(beFalsy())
            expect(operation).to(beIdenticalTo(firstOperation))
            expect(error).to(beIdenticalTo(expectedError))
            expect(ranFirstOperation).to(beTruthy())
            expect(ranSecondOperation).to(beFalsy())
            expect(ranThirdOperation).to(beFalsy())
        }
        thirdOperation.name = "C"
        
        firstOperation --> secondOperation --> thirdOperation
        
        runOperations([secondOperation, firstOperation, thirdOperation], asynchronously: false)
        
        expect(ranFirstOperation).to(beTruthy())
        expect(ranSecondOperation).to(beFalsy())
        expect(ranThirdOperation).to(beFalsy())
    }

}
