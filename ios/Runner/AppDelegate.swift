import UIKit
import Flutter
import FirebaseCore
import FirebaseMessaging
import flutter_local_notifications

@main
@objc class AppDelegate: FlutterAppDelegate {

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    GeneratedPluginRegistrant.register(with: self)

    let launched = super.application(
      application,
      didFinishLaunchingWithOptions: launchOptions
    )
    NSLog(
      "[PushDiagnostics] App launched. Firebase configured=%@",
      FirebaseApp.app() == nil ? "false" : "true"
    )
    return launched
  }

  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    Messaging.messaging().apnsToken = deviceToken
    let tokenSuffix = deviceToken
      .map { String(format: "%02x", $0) }
      .joined()
      .suffix(8)
    NSLog(
      "[PushDiagnostics] didRegisterForRemoteNotificationsWithDeviceToken "
        + "called. APNs token suffix=...%@",
      String(tokenSuffix)
    )
    super.application(
      application,
      didRegisterForRemoteNotificationsWithDeviceToken: deviceToken
    )
  }

  override func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    NSLog(
      "[PushDiagnostics] APNs registration failed: %@",
      error.localizedDescription
    )
    super.application(
      application,
      didFailToRegisterForRemoteNotificationsWithError: error
    )
  }
}
