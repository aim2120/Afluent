//
//  URLSessionAdditions.swift
//
//
//  Created by Tyler Thompson on 10/29/23.
//

import Foundation

extension URLSession {
    /// Returns a deferred data task that wraps a URL session data task for a given URL.
    public func deferredDataTask(from url: URL) -> some AsynchronousUnitOfWork<(data: Data, response: URLResponse)> {
        DeferredTask {
            try await data(from: url)
        }
    }

    /// Returns a deferred data task that wraps a URL session data task for a given URL.
    public func deferredDataTask(for urlRequest: URLRequest) -> some AsynchronousUnitOfWork<(data: Data, response: URLResponse)> {
        DeferredTask {
            try await data(for: urlRequest)
        }
    }
}
