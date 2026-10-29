import Flutter
import UIKit
import workmanager_apple

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if #available(iOS 13.0, *) {
      WorkmanagerPlugin.registerPeriodicTask(
        withIdentifier: "moti-widget-refresh",
        frequency: nil
      )
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    let channel = FlutterMethodChannel(
      name: "motiscroll/share",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    channel.setMethodCallHandler { call, result in
      ShareChannel.handle(call, result: result)
    }
  }
}

private enum ShareChannel {
  static func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "installedApps":
      result([
        "instagram": canOpen("instagram://"),
        "facebook": canOpen("fb://"),
        "facebookLite": canOpen("fb-lite://"),
        "whatsapp": canOpen("whatsapp://"),
        "whatsappBusiness": false,
      ])
    case "shareInstagramStory":
      let args = call.arguments as? [String: String] ?? [:]
      result(shareInstagramStory(path: args["path"], appId: args["appId"]))
    case "shareFacebookStory":
      let args = call.arguments as? [String: String] ?? [:]
      result(shareFacebookStory(path: args["path"], appId: args["appId"]))
    case "shareWhatsApp":
      result(false)
    case "encodeJpeg":
      result(encodeJpeg(call.arguments))
    case "openSettings":
      if let url = URL(string: UIApplication.openSettingsURLString) {
        UIApplication.shared.open(url)
      }
      result(true)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  static func canOpen(_ scheme: String) -> Bool {
    guard let url = URL(string: scheme) else { return false }
    return UIApplication.shared.canOpenURL(url)
  }

  static func shareInstagramStory(path: String?, appId: String?) -> Bool {
    guard let path, let appId, !appId.isEmpty else { return false }
    guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)) else { return false }
    guard let url = URL(string: "instagram-stories://share?source_application=\(appId)") else {
      return false
    }
    guard UIApplication.shared.canOpenURL(url) else { return false }
    UIPasteboard.general.setItems(
      [["com.instagram.sharedSticker.backgroundImage": data]],
      options: [
        .expirationDate: Date().addingTimeInterval(60 * 5),
        .localOnly: true,
      ]
    )
    UIApplication.shared.open(url)
    return true
  }

  static func shareFacebookStory(path: String?, appId: String?) -> Bool {
    guard let path, let appId, !appId.isEmpty else { return false }
    guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)) else { return false }
    guard let url = URL(string: "facebook-stories://share?source_application=\(appId)") else {
      return false
    }
    guard UIApplication.shared.canOpenURL(url) else { return false }
    UIPasteboard.general.setItems(
      [[
        "com.facebook.sharedSticker.backgroundImage": data,
        "com.facebook.sharedSticker.appID": appId,
      ]],
      options: [
        .expirationDate: Date().addingTimeInterval(60 * 5),
        .localOnly: true,
      ]
    )
    UIApplication.shared.open(url)
    return true
  }

  static func encodeJpeg(_ raw: Any?) -> FlutterStandardTypedData? {
    let data: Data
    if let typed = raw as? FlutterStandardTypedData {
      data = typed.data
    } else if let bytes = raw as? Data {
      data = bytes
    } else {
      return nil
    }
    guard let image = UIImage(data: data),
          let jpeg = image.jpegData(compressionQuality: 0.92) else {
      return nil
    }
    return FlutterStandardTypedData(bytes: jpeg)
  }
}
