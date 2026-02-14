import Flutter
import UIKit
import GoogleMaps
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GMSServices.provideAPIKey("AIzaSyDyh1Hq8VEAWMT9Y_KGDhNmYsDFwaU6pSo") //Enter Your Map Api Key 
    GeneratedPluginRegistrant.register(with: self)

    // Register for push notifications
    UNUserNotificationCenter.current().delegate = self
    application.registerForRemoteNotifications()

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
