//
//  SingleValueSubjectTests.swift
//
//
//  Created by Tyler Thompson on 11/10/23.
//

import Afluent
import Foundation
import XCTest

final class SingleValueSubjectTests: XCTestCase {
    func testSingleValueSubjectEmittingValueBeforeTaskRuns() async throws {
        let expected = Int.random(in: 1 ... 1000)
        let exp = expectation(description: "task executed")
        let subject = SingleValueSubject<Int>()
        let unitOfWork = subject.map {
            exp.fulfill()
            return $0
        }

        try subject.send(expected)

        let actual = try await unitOfWork.execute()
        await fulfillment(of: [exp], timeout: 0)
        XCTAssertEqual(actual, expected)
    }

    func testSingleValueSubjectEmittingValueAfterTaskRuns() async throws {
        let expected = Int.random(in: 1 ... 1000)
        let exp = expectation(description: "task executed")
        let subject = SingleValueSubject<Int>()
        subject.map {
            exp.fulfill()
            XCTAssertEqual($0, expected)
            return $0
        }.run() // task started

        try subject.send(expected)

        await fulfillment(of: [exp], timeout: 0.1)
    }

    func testSingleValueSubjectEmittingErrorBeforeTaskRuns() async throws {
        enum Err: Error { case e1 }
        let subject = SingleValueSubject<Int>()

        try subject.send(error: Err.e1)

        let actualResult = try await subject.result
        XCTAssertThrowsError(try actualResult.get()) { error in
            XCTAssertEqual(error as? Err, .e1)
        }
    }

    func testSingleValueSubjectEmittingErrorAfterTaskRuns() async throws {
        try XCTSkipIf(ProcessInfo.processInfo.environment["CI"] == "true")

        enum Err: Error { case e1 }
        let exp = expectation(description: "task executed")
        let subject = SingleValueSubject<Int>()
        let unitOfWork = subject
            .materialize()
            .map {
                exp.fulfill()
                return $0
            }

        Task {
            try await Task.sleep(nanoseconds: UInt64(Measurement<UnitDuration>.milliseconds(10).converted(to: .nanoseconds).value))
            try subject.send(error: Err.e1)
        }

        let actualResult = try await unitOfWork.execute()
        XCTAssertThrowsError(try actualResult.get()) { error in
            XCTAssertEqual(error as? Err, .e1)
        }

        await fulfillment(of: [exp], timeout: 0.01)
    }

    func testSingleValueSubjectOnlyEmitsValueOnce() async throws {
        let expected = Int.random(in: 1 ... 1000)
        let exp = expectation(description: "task executed")
        let subject = SingleValueSubject<Int>()
        subject.map {
            exp.fulfill()
            XCTAssertEqual($0, expected)
            return $0
        }.run() // task started

        try subject.send(expected)
        XCTAssertThrowsError(try subject.send(expected))

        await fulfillment(of: [exp], timeout: 0.01)
    }

    func testSingleValueSubjectOnlyEmitsErrorOnce() async throws {
        try XCTSkipIf(ProcessInfo.processInfo.environment["CI"] == "true")

        enum Err: Error { case e1 }
        let exp = expectation(description: "task executed")
        let exp1 = expectation(description: "Subject error sent")
        let subject = SingleValueSubject<Int>()
        let unitOfWork = subject
            .materialize()
            .map {
                exp.fulfill()
                return $0
            }

        Task {
            try await Task.sleep(nanoseconds: UInt64(Measurement<UnitDuration>.milliseconds(10).converted(to: .nanoseconds).value))
            try subject.send(error: Err.e1)
            XCTAssertThrowsError(try subject.send(error: Err.e1))
            exp1.fulfill()
        }

        let actualResult = try await unitOfWork.execute()
        XCTAssertThrowsError(try actualResult.get()) { error in
            XCTAssertEqual(error as? Err, .e1)
        }

        await fulfillment(of: [exp, exp1], timeout: 0.01)
    }

    func testVoidSingleValueSubjectEmittingValueBeforeTaskRuns() async throws {
        let exp = expectation(description: "task executed")
        let subject = SingleValueSubject<Void>()
        let unitOfWork = subject.map {
            exp.fulfill()
        }

        try subject.send()

        try await unitOfWork.execute()

        await fulfillment(of: [exp], timeout: 0)
    }

    func testVoidSingleValueSubjectEmittingValueAfterTaskRuns() async throws {
        let exp = expectation(description: "task executed")
        let subject = SingleValueSubject<Void>()
        subject.map {
            exp.fulfill()
        }.run() // task started

        try subject.send()

        await fulfillment(of: [exp], timeout: 0.01)
    }

    func testSingleValueSubjectEmittingValueConcurrentlyWithExecute() async throws {
        let expected = Int.random(in: 1 ... 1000)
        let exp = expectation(description: "task executed")
        let subject = SingleValueSubject<Int>()
        let unitOfWork = subject.map {
            exp.fulfill()
            return $0
        }

        let sendUnitOfWork = DeferredTask {
            try subject.send(expected)
        }

        async let _actual = unitOfWork.execute()
        sendUnitOfWork.run()

        let actual = try await _actual
        await fulfillment(of: [exp], timeout: 0.01)
        XCTAssertEqual(actual, expected)
    }

    func testSingleValueSubjectEmittingErrorConcurrentlyWithExecute() async throws {
        enum Err: Error { case e1 }
        let exp = expectation(description: "task executed")
        let subject = SingleValueSubject<Int>()
        let unitOfWork = subject
            .materialize()
            .map {
                exp.fulfill()
                return $0
            }

        let sendUnitOfWork = DeferredTask {
            try subject.send(error: Err.e1)
        }

        async let _actual = unitOfWork.execute()
        sendUnitOfWork.run()

        let actual = try await _actual
        XCTAssertThrowsError(try actual.get()) { error in
            XCTAssertEqual(error as? Err, .e1)
        }

        await fulfillment(of: [exp], timeout: 0.01)
    }
}
