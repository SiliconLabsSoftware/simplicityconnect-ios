//
//  SILIOPTester_Test5.swift
//  BlueGecko
//
//  Created by Kamil Czajka on 25.3.2021.
//  Copyright © 2021 SiliconLabs. All rights reserved.
//

import Foundation

class SILIOPTester_Test5 : SILTestScenario {
    var scenarioName: String = "OTA-DFU with ACK"
    var scenarioDescription: String = "Over-the-air Device Firmware Update with acknowledgment."

    var testResults: SILObservable<[SILTestResult]> = SILObservable(initialValue: [])
    var privTestResults: [SILTestResult] = [SILTestResult]()
    var tests: [SILTestCase] = [SILTestCase]()
    var isMandatory: Bool = false
    
    var observableTokens: [SILObservableToken?] = []
    private var disposeBag = SILObservableTokenBag()
    
    init() {
        appendTestCase(testCase: SILOTAAckTestCase())
        testResults.value = privTestResults
    }
    
    func injectParameters(parameters: Dictionary<String, Any>) {
        self.tests[0].injectParameters(parameters: parameters)
    }
    
    func performTestScenario() {
        weak var weakSelf = self
        
        let otaAckTestObserver = self.tests[0].testResult.observe({ testResult in
            guard let testResult = testResult else { return }
            guard let weakSelf = weakSelf else { return }
            weakSelf.privTestResults[0] = testResult
            weakSelf.testResults.value = self.privTestResults
        })
        disposeBag.add(token: otaAckTestObserver)
        observableTokens.append(otaAckTestObserver)
        
        self.tests[0].performTestCase()
    }
    
    func getTestsArtifacts() -> Dictionary<String, Any> {
        return self.tests[0].getTestArtifacts()
    }
}
