import Flutter
import Intents
import Photos
import UIKit
import UserNotifications
import workmanager_apple

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Own the notification center before plugins register. Otherwise Firebase
    // Messaging becomes the delegate and presents local banners as nothing
    // while the app is open. Android still shows those heads-up.
    UNUserNotificationCenter.current().delegate = self
    if #available(iOS 13.0, *) {
      WorkmanagerPlugin.registerPeriodicTask(
        withIdentifier: "moti-widget-refresh",
        frequency: nil
      )
    }
    let launched = super.application(application, didFinishLaunchingWithOptions: launchOptions)
    UNUserNotificationCenter.current().delegate = self
    return launched
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    UNUserNotificationCenter.current().delegate = self
    let channel = FlutterMethodChannel(
      name: "motiscroll/share",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    channel.setMethodCallHandler { call, result in
      ShareChannel.handle(call, result: result)
    }
    let notify = FlutterMethodChannel(
      name: "motiscroll/notify",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    notify.setMethodCallHandler { call, result in
      NotifyChannel.handle(call, result: result)
    }
  }

  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    if notification.request.content.userInfo["NotificationId"] != nil {
      completionHandler([.banner, .list, .sound])
      return
    }
    super.userNotificationCenter(
      center,
      willPresent: notification,
      withCompletionHandler: completionHandler
    )
  }
}

private enum NotifyChannel {
  static func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard call.method == "show" else {
      result(FlutterMethodNotImplemented)
      return
    }
    let args = call.arguments as? [String: Any] ?? [:]
    let id = (args["id"] as? NSNumber)?.intValue ?? 0
    let title = args["title"] as? String ?? ""
    let body = args["body"] as? String ?? ""
    let payload = args["payload"] as? String ?? ""
    let fireAt = (args["fireAtMillis"] as? NSNumber)?.doubleValue
    let content = UNMutableNotificationContent()
    content.title = title
    content.body = body
    content.sound = .default
    content.userInfo = [
      "NotificationId": id,
      "presentAlert": true,
      "presentSound": true,
      "presentBadge": false,
      "presentBanner": true,
      "presentList": true,
      "payload": payload,
    ]
    let branded = brandedContent(content, title: title, body: body)
    let trigger = triggerFor(fireAtMillis: fireAt)
    let request = UNNotificationRequest(
      identifier: "\(id)",
      content: branded,
      trigger: trigger
    )
    UNUserNotificationCenter.current().add(request) { error in
      DispatchQueue.main.async {
        if let error = error as NSError?, error.domain != UNErrorDomain {
          result(
            FlutterError(
              code: "notify",
              message: error.localizedDescription,
              details: nil
            )
          )
        } else {
          result(nil)
        }
      }
    }
  }

  static func triggerFor(fireAtMillis: Double?) -> UNNotificationTrigger? {
    guard let fireAtMillis else { return nil }
    let date = Date(timeIntervalSince1970: fireAtMillis / 1000)
    guard date.timeIntervalSinceNow > 1 else { return nil }
    let parts = Calendar.current.dateComponents(
      [.year, .month, .day, .hour, .minute, .second],
      from: date
    )
    return UNCalendarNotificationTrigger(dateMatching: parts, repeats: false)
  }

  /// iOS draws the app icon on the banner. A stale install can keep the
  /// Flutter logo there, so the quote carries the Moti mark as its avatar.
  static func brandedContent(
    _ content: UNMutableNotificationContent,
    title: String,
    body: String
  ) -> UNNotificationContent {
    guard #available(iOS 15.0, *),
          let data = iconData()
    else { return content }
    let avatar = INImage(imageData: data)
    let sender = INPerson(
      personHandle: INPersonHandle(value: "motiscroll", type: .unknown),
      nameComponents: nil,
      displayName: title,
      image: avatar,
      contactIdentifier: nil,
      customIdentifier: "motiscroll",
      isMe: false
    )
    let intent = INSendMessageIntent(
      recipients: nil,
      outgoingMessageType: .outgoingMessageText,
      content: body,
      speakableGroupName: nil,
      conversationIdentifier: "motiscroll.quotes",
      serviceName: nil,
      sender: sender,
      attachments: nil
    )
    intent.setImage(avatar, forParameterNamed: \.sender)
    let interaction = INInteraction(intent: intent, response: nil)
    interaction.direction = .incoming
    interaction.donate(completion: nil)
    guard let updated = try? content.updating(from: intent) else { return content }
    return updated
  }

  static func iconData() -> Data? {
    let names = ["AppIcon60x60@3x", "AppIcon60x60@2x", "AppIcon60x60"]
    for name in names {
      if let path = Bundle.main.path(forResource: name, ofType: "png"),
         let data = try? Data(contentsOf: URL(fileURLWithPath: path)) {
        return data
      }
    }
    return nil
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
        "whatsapp": canOpen("whatsapp://send") || canOpen("whatsapp://"),
        "whatsappBusiness": canOpen("whatsapp-business://send") ||
          canOpen("whatsapp-business://"),
      ])
    case "shareInstagramStory":
      let args = call.arguments as? [String: String] ?? [:]
      result(shareInstagramStory(path: args["path"], appId: args["appId"]))
    case "shareFacebookStory":
      let args = call.arguments as? [String: String] ?? [:]
      result(shareFacebookStory(path: args["path"], appId: args["appId"]))
    case "shareWhatsApp":
      result(false)
    case "shareSystem":
      let args = call.arguments as? [String: String] ?? [:]
      shareSystem(path: args["path"], caption: args["caption"] ?? "", result: result)
    case "saveImage":
      let args = call.arguments as? [String: String] ?? [:]
      saveImage(path: args["path"], result: result)
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

  static func shareSystem(
    path: String?,
    caption: String,
    result: @escaping FlutterResult
  ) {
    guard let path else {
      result(false)
      return
    }
    var items: [Any] = [URL(fileURLWithPath: path)]
    if !caption.isEmpty {
      items.append(caption)
    }
    guard !items.isEmpty, let presenter = topViewController() else {
      result(false)
      return
    }
    let activity = UIActivityViewController(
      activityItems: items,
      applicationActivities: nil
    )
    if UIDevice.current.userInterfaceIdiom == .pad,
       let popover = activity.popoverPresentationController {
      popover.sourceView = presenter.view
      let bounds = presenter.view.bounds
      popover.sourceRect = CGRect(
        x: bounds.midX - 1,
        y: bounds.midY - 1,
        width: 2,
        height: 2
      )
      popover.permittedArrowDirections = []
    }
    DispatchQueue.main.async {
      presenter.present(activity, animated: true) {
        result(true)
      }
    }
  }

  static func saveImage(path: String?, result: @escaping FlutterResult) {
    guard let path,
          let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
          let image = UIImage(data: data)
    else {
      result(false)
      return
    }
    if #available(iOS 14, *) {
      PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
        guard status == .authorized || status == .limited else {
          DispatchQueue.main.async { result(false) }
          return
        }
        PHPhotoLibrary.shared().performChanges({
          PHAssetChangeRequest.creationRequestForAsset(from: image)
        }) { ok, _ in
          DispatchQueue.main.async { result(ok) }
        }
      }
      return
    }
    PHPhotoLibrary.requestAuthorization { status in
      guard status == .authorized else {
        DispatchQueue.main.async { result(false) }
        return
      }
      PHPhotoLibrary.shared().performChanges({
        PHAssetChangeRequest.creationRequestForAsset(from: image)
      }) { ok, _ in
        DispatchQueue.main.async { result(ok) }
      }
    }
  }

  static func topViewController() -> UIViewController? {
    let scenes = UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .sorted { left, right in
        let rank: (UIScene.ActivationState) -> Int = { state in
          state == .foregroundActive ? 0 : 1
        }
        return rank(left.activationState) < rank(right.activationState)
      }
    for scene in scenes {
      let windows = scene.windows.sorted { left, right in
        left.isKeyWindow && !right.isKeyWindow
      }
      for window in windows {
        guard var top = window.rootViewController else { continue }
        while let presented = top.presentedViewController {
          top = presented
        }
        if top.viewIfLoaded?.window != nil {
          return top
        }
      }
    }
    return nil
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
          let jpeg = image.jpegData(compressionQuality: 0.95) else {
      return nil
    }
    return FlutterStandardTypedData(bytes: jpeg)
  }
}
