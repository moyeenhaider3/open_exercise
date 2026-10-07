import Flutter
import UIKit

public class BackupBookmarkChannel {
  private static var currentlyAccessedURL: URL?

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "com.openexercise/backup_bookmark",
      binaryMessenger: registrar.messenger()
    )
    channel.setMethodCallHandler { call, result in
      handle(call: call, result: result)
    }
  }

  private static func handle(call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "createBookmark":
      guard let args = call.arguments as? [String: Any],
            let path = args["path"] as? String else {
        result(FlutterError(code: "INVALID_ARGUMENT", message: "Path is required", details: nil))
        return
      }
      let url = URL(fileURLWithPath: path)
      let accessed = url.startAccessingSecurityScopedResource()
      defer {
        if accessed {
          url.stopAccessingSecurityScopedResource()
        }
      }
      do {
        let bookmarkData = try url.bookmarkData(
          options: [],
          includingResourceValuesForKeys: nil,
          relativeTo: nil
        )
        result(bookmarkData.base64EncodedString())
      } catch {
        result(FlutterError(code: "BOOKMARK_ERROR", message: error.localizedDescription, details: nil))
      }

    case "resolveBookmark":
      guard let args = call.arguments as? [String: Any],
            let dataString = args["data"] as? String else {
        result(["error": "invalid_argument", "path": NSNull()])
        return
      }
      guard let bookmarkData = Data(base64Encoded: dataString) else {
        result(["error": "invalid_base64", "path": NSNull()])
        return
      }
      var isStale = false
      do {
        let resolvedURL = try URL(
          resolvingBookmarkData: bookmarkData,
          options: [],
          relativeTo: nil,
          bookmarkDataIsStale: &isStale
        )
        if isStale {
          result(["error": "stale", "path": NSNull()])
          return
        }
        if let current = currentlyAccessedURL {
          current.stopAccessingSecurityScopedResource()
          currentlyAccessedURL = nil
        }
        if resolvedURL.startAccessingSecurityScopedResource() {
          currentlyAccessedURL = resolvedURL
          result(["path": resolvedURL.path])
        } else {
          result(["error": "access_denied", "path": NSNull()])
        }
      } catch {
        result(["error": error.localizedDescription, "path": NSNull()])
      }

    case "stopAccessing":
      if let current = currentlyAccessedURL {
        current.stopAccessingSecurityScopedResource()
        currentlyAccessedURL = nil
      }
      result(nil)

    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
