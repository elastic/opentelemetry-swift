// Copyright 2020, OpenTelemetry Authors
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import OpenTelemetryApi
import XCTest

private let key = EntryKey(name: "key")!
private let value = EntryValue(string: "value")!

class TestCorrelationContext: CorrelationContext {
    static func contextBuilder() -> CorrelationContextBuilder {
        EmptyCorrelationContextBuilder()
    }

    func getEntries() -> [Entry] {
        return [Entry(key: key, value: value, entryMetadata: EntryMetadata(entryTtl: .unlimitedPropagation))]
    }

    func getEntryValue(key: EntryKey) -> EntryValue? {
        return value
    }
}

class DefaultCorrelationContextManagerTests: XCTestCase {
    let defaultCorrelationContextManager = DefaultCorrelationContextManager.instance
    let correlationContext = TestCorrelationContext()

    func testBuilderMethod() {
        let builder = defaultCorrelationContextManager.contextBuilder()
        XCTAssertEqual(builder.build().getEntries().count, 0)
    }

    func testGetCurrentContext_DefaultContext() {
        XCTAssertTrue(defaultCorrelationContextManager.getCurrentContext() === EmptyCorrelationContext.instance)
    }

    func testGetCurrentContext_ContextSetToNil() {
        let correlationContext = defaultCorrelationContextManager.getCurrentContext()
        XCTAssertNotNil(correlationContext)
        XCTAssertEqual(correlationContext.getEntries().count, 0)
    }

    func testWithContext() {
        XCTAssertTrue(defaultCorrelationContextManager.getCurrentContext() === EmptyCorrelationContext.instance)
        var wtm = defaultCorrelationContextManager.withContext(correlationContext: correlationContext)
        XCTAssertTrue(defaultCorrelationContextManager.getCurrentContext() === correlationContext)
        wtm.close()
        XCTAssertTrue(defaultCorrelationContextManager.getCurrentContext() === EmptyCorrelationContext.instance)
    }

    func testWithContextUsingWrap() {
        let expec = expectation(description: "testWithContextUsingWrap")
        var wtm = defaultCorrelationContextManager.withContext(correlationContext: correlationContext)
        XCTAssertTrue(defaultCorrelationContextManager.getCurrentContext() === correlationContext)
        let semaphore = DispatchSemaphore(value: 0)
        DispatchQueue.global().async {
            semaphore.wait()
            XCTAssertTrue(self.defaultCorrelationContextManager.getCurrentContext() === self.correlationContext)
            expec.fulfill()
        }
        wtm.close()
        XCTAssertTrue(defaultCorrelationContextManager.getCurrentContext() === EmptyCorrelationContext.instance)
        semaphore.signal()
        waitForExpectations(timeout: 30) { error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
            }
        }
    }
}
