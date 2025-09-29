import UIKit
import React
import React_RCTAppDelegate
import ReactAppDependencyProvider
import BackgroundTasks
import UserNotifications

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
  var window: UIWindow?

  var reactNativeDelegate: ReactNativeDelegate?
  var reactNativeFactory: RCTReactNativeFactory?
  
  private let backgroundTaskIdentifier = "com.backgroundpoc.websocket"

  func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
  ) -> Bool {
    let delegate = ReactNativeDelegate()
    let factory = RCTReactNativeFactory(delegate: delegate)
    delegate.dependencyProvider = RCTAppDependencyProvider()

    reactNativeDelegate = delegate
    reactNativeFactory = factory

    window = UIWindow(frame: UIScreen.main.bounds)

    factory.startReactNative(
      withModuleName: "BackgroundPOC",
      in: window,
      launchOptions: launchOptions
    )
    
    // Register background task
    registerBackgroundTask()
    
    // Request notification permissions
    requestNotificationPermissions()

    return true
  }
  
  private func registerBackgroundTask() {
    BGTaskScheduler.shared.register(forTaskWithIdentifier: backgroundTaskIdentifier, using: nil) { task in
      self.handleBackgroundTask(task: task as! BGAppRefreshTask)
    }
  }
  
  private func handleBackgroundTask(task: BGAppRefreshTask) {
    print("Background task started")
    
    task.expirationHandler = {
      print("Background task expired")
      task.setTaskCompleted(success: false)
    }
    
    // Schedule the next background task
    scheduleBackgroundTask()
    
    // Perform your background work here
    // For WebSocket, the URLSession background configuration handles this
    
    task.setTaskCompleted(success: true)
  }
  
  private func scheduleBackgroundTask() {
    let request = BGAppRefreshTaskRequest(identifier: backgroundTaskIdentifier)
    request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60) // 15 minutes
    
    do {
      try BGTaskScheduler.shared.submit(request)
      print("Background task scheduled")
    } catch {
      print("Could not schedule background task: \(error)")
    }
  }
  
  private func requestNotificationPermissions() {
    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
      if let error = error {
        print("Notification permission error: \(error)")
      } else {
        print("Notification permission granted: \(granted)")
      }
    }
  }
  
  func applicationDidEnterBackground(_ application: UIApplication) {
    print("App entered background")
    scheduleBackgroundTask()
  }
  
  func applicationWillEnterForeground(_ application: UIApplication) {
    print("App entering foreground")
  }
}

class ReactNativeDelegate: RCTDefaultReactNativeFactoryDelegate {
  override func sourceURL(for bridge: RCTBridge) -> URL? {
    self.bundleURL()
  }

  override func bundleURL() -> URL? {
#if DEBUG
    RCTBundleURLProvider.sharedSettings().jsBundleURL(forBundleRoot: "index")
#else
    Bundle.main.url(forResource: "main", withExtension: "jsbundle")
#endif
  }
}
