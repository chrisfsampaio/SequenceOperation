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

class SequenceOperationTests: XCTestCase {

    func testRunSequence() {
        
        var ranFirstOperation = false
        var ranSecondOperation = false
        
        let firstOperation = SequenceOperation { operation in
            ranFirstOperation = true
            sleep(1) //menezes
            operation.moveOn()
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
            sleep(1) //menezes
            ranFirstOperation = true
            operation.moveOn()
        }
        
        let secondOperation = SequenceOperation { operation in
            expect(ranFirstOperation).to(beTruthy())
            ranSecondOperation = true
            operation.moveOn()
        }
        
        firstOperation --> secondOperation
        
        let queue = NSOperationQueue()
        queue.addOperation(secondOperation)
        queue.addOperation(firstOperation)
        
        expect(ranSecondOperation).toEventually(beTruthy(), timeout: 2)
    }
    
    func testChainingWithRunSequence() {
        var ranFirstOperation = false
        var ranSecondOperation = false
        
        let firstOperation = SequenceOperation { operation in
            sleep(1) //menezes
            ranFirstOperation = true
            operation.moveOn()
        }
        
        let secondOperation = SequenceOperation { operation in
            expect(ranFirstOperation).to(beTruthy())
            ranSecondOperation = true
            operation.moveOn()
        }
        
        firstOperation --> secondOperation
        
        runOperations([secondOperation, firstOperation])
        
        expect(ranSecondOperation).toEventually(beTruthy(), timeout: 2)
    }
    
    func testErrorPropagation() {
        var ranFirstOperation = false
        var ranSecondOperation = false
        var ranThirdOperation = false
        
        let firstOperation = SequenceOperation { operation in
            sleep(1) //menezes
            ranFirstOperation = true
            operation.moveOn()
        }
        
        let secondOperation = SequenceOperation { operation in
            sleep(1) //menezes
            expect(ranFirstOperation).to(beTruthy())
            ranSecondOperation = true
            operation.cancel()
        }
        
        let thirdOperation = SequenceOperation { operation in
            ranThirdOperation = true
            expect(ranThirdOperation).to(raiseException(named: "shouldn't had ran this operation"))
            operation.moveOn()
        }
        
        thirdOperation.movedOnBlock = {
            expect(ranFirstOperation).to(beTruthy())
            expect(ranSecondOperation).to(beTruthy())
            expect(ranThirdOperation).to(beFalsy())
        }
        
        firstOperation --> secondOperation --> thirdOperation
        
        runOperations([secondOperation, firstOperation, thirdOperation], asynchronously: false)
        
        expect(ranFirstOperation).to(beTruthy())
        expect(ranSecondOperation).to(beTruthy())
        expect(ranThirdOperation).to(beFalsy())
    }

}
