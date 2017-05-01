//
//  ExtensionDelegate.swift
//  Watch Extension
//
//  Created by Max on 07/04/2017.
//
//

import WatchKit
import WatchConnectivity

/// no object; call `Verb.sharedVerbs()` to get all shared verbs
let SharedVerbsDidUpdateNotification = Notification.Name("com.lisacintosh.iverb.watch.verbs-updated")


let UserDefaultsWatchSharedVerbsKey = "com.lisacintosh.iverb.watch.shared-verbs"

class ExtensionDelegate: NSObject, WKExtensionDelegate, WCSessionDelegate {
	
    func applicationDidFinishLaunching() {
		let session = WCSession.default()
		session.delegate = self
		session.activate()
    }

    func applicationDidBecomeActive() {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillResignActive() {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, etc.
    }

	@available(watchOSApplicationExtension 3.0, *)
	func handle(_ backgroundTasks: Set<WKRefreshBackgroundTask>) {
        // Sent when the system needs to launch the application in the background to process tasks. Tasks arrive in a set, so loop through and process each one.
        for task in backgroundTasks {
            // Use a switch statement to check the task type
            switch task {
				case let backgroundTask as WKApplicationRefreshBackgroundTask:
					// Be sure to complete the background task once you’re done.
					backgroundTask.setTaskCompleted()
				case let snapshotTask as WKSnapshotRefreshBackgroundTask:
					// Snapshot tasks have a unique completion call, make sure to set your expiration date
					snapshotTask.setTaskCompleted(restoredDefaultState: true,
					                              estimatedSnapshotExpiration: .distantFuture,
					                              userInfo: nil)
				case let connectivityTask as WKWatchConnectivityRefreshBackgroundTask:
					// Be sure to complete the connectivity task once you’re done.
					connectivityTask.setTaskCompleted()
				case let urlSessionTask as WKURLSessionRefreshBackgroundTask:
					// Be sure to complete the URL session task once you’re done.
					urlSessionTask.setTaskCompleted()
				default:
					// make sure to complete unhandled task types
					task.setTaskCompleted()
            }
        }
    }
	
	// MARK: - WCSession delegate
	
	@available(watchOSApplicationExtension 2.2, *)
	func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) { }
	
	func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
		
		if let verbsDict = applicationContext["verbs"] {
			UserDefaults.standard.set(verbsDict, forKey: UserDefaultsWatchSharedVerbsKey)
			NotificationCenter.default.post(name: SharedVerbsDidUpdateNotification, object: nil)
		}
	}
}
