/*
Copyright (C) 2015 Apple Inc. All Rights Reserved.
See LICENSE.txt for this sample’s licensing information

Abstract:
Contains the code to manage the visibility of the network activity indicator
*/

import UIKit

/**
    An `OperationObserver` that will cause the network activity indicator to appear
    as long as the `Operation` to which it is attached is executing.
*/
public struct NetworkObserver: OperationObserver {
    // MARK: Initilization

    public init() { }


    // MARK: <OperationObserver>

    public func operationDidStart(_ operation: Operation) {
        DispatchQueue.main.async {
            // increment the network indicator's "retain count"
            NetworkIndicatorController.sharedIndicatorController.networkActivityDidStart()
        }
    }

    public func operation(_ operation: Operation, didProduceOperation newOperation: Foundation.Operation) { }

    public func operationDidFinish(_ operation: Operation, errors: [NSError]) {
        DispatchQueue.main.async {
            // Decrement the network indicator's "reference count".
            NetworkIndicatorController.sharedIndicatorController.networkActivityDidEnd()
        }
    }

}

/// A singleton to manage a visual "reference count" on the network activity indicator.
private class NetworkIndicatorController {
    // MARK: Properties

    static let sharedIndicatorController = NetworkIndicatorController()

    fileprivate var activityCount = 0

    fileprivate var visibilityTimer: Timer?

    // MARK: Methods

    func networkActivityDidStart() {
        assert(Thread.isMainThread, "Altering network activity indicator state can only be done on the main thread.")

        activityCount += 1

        updateIndicatorVisibility()
    }

    func networkActivityDidEnd() {
        assert(Thread.isMainThread, "Altering network activity indicator state can only be done on the main thread.")

        activityCount -= 1

        updateIndicatorVisibility()
    }

    fileprivate func updateIndicatorVisibility() {
        if activityCount > 0 {
            showIndicator()
        } else {
            /*
                To prevent the indicator from flickering on and off, we delay the
                hiding of the indicator by one second. This provides the chance
                to come in and invalidate the timer before it fires.
            */
            visibilityTimer = Timer(interval: 1.0) {
                self.hideIndicator()
            }
        }
    }

    fileprivate func showIndicator() {
        visibilityTimer?.cancel()
        visibilityTimer = nil

        #if os(iOS)
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
        #endif
    }

    fileprivate func hideIndicator() {
        visibilityTimer?.cancel()
        visibilityTimer = nil

        #if os(iOS)
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
        #endif
    }
}

/// Essentially a cancellable `dispatch_after`.
class Timer {
    // MARK: Properties

    fileprivate var isCancelled = false

    // MARK: Initialization

    init(interval: TimeInterval, handler: @escaping ()->()) {
        let when = DispatchTime.now() + Double(Int64(interval * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)

        DispatchQueue.main.asyncAfter(deadline: when) { [weak self] in
            if self?.isCancelled == true {
                handler()
            }
        }
    }

    func cancel() {
        isCancelled = true
    }
}
