import Cocoa
import FlutterMacOS
import UniformTypeIdentifiers

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)
    configureAttachmentChannel(flutterViewController)

    super.awakeFromNib()
  }

  private func configureAttachmentChannel(_ flutterViewController: FlutterViewController) {
    let channel = FlutterMethodChannel(
      name: "circul/attachments",
      binaryMessenger: flutterViewController.engine.binaryMessenger
    )

    channel.setMethodCallHandler { [weak self] call, result in
      switch call.method {
      case "openImageChooser":
        self?.openImageChooser(result)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private func openImageChooser(_ result: @escaping FlutterResult) {
    let panel = NSOpenPanel()
    panel.title = "Pilih gambar"
    panel.prompt = "Pilih"
    panel.allowsMultipleSelection = true
    panel.canChooseDirectories = false
    panel.canChooseFiles = true
    if #available(macOS 11.0, *) {
      panel.allowedContentTypes = [.image]
    } else {
      panel.allowedFileTypes = ["jpg", "jpeg", "png", "gif", "webp", "heic", "bmp", "tiff"]
    }

    panel.beginSheetModal(for: self) { [weak self] response in
      guard response == .OK else {
        result([])
        return
      }
      let paths = panel.urls.compactMap { url -> String? in
        self?.copyToAppContainer(url)
      }
      result(paths)
    }
  }

  private func copyToAppContainer(_ sourceURL: URL) -> String? {
    guard sourceURL.startAccessingSecurityScopedResource() else { return nil }
    defer { sourceURL.stopAccessingSecurityScopedResource() }

    let fm = FileManager.default
    guard let appSupport = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
      return nil
    }
    let imagesDir = appSupport.appendingPathComponent("circul_images", isDirectory: true)

    do {
      try fm.createDirectory(at: imagesDir, withIntermediateDirectories: true)
      let ext = sourceURL.pathExtension.isEmpty ? "jpg" : sourceURL.pathExtension
      let dest = imagesDir.appendingPathComponent(
        "circul_image_\(Int(Date().timeIntervalSince1970 * 1000))_\(UUID().uuidString.prefix(8)).\(ext)"
      )
      try fm.copyItem(at: sourceURL, to: dest)
      return dest.path
    } catch {
      return nil
    }
  }
}
