import Cocoa
import FlutterMacOS

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
    panel.allowsMultipleSelection = false
    panel.canChooseDirectories = false
    panel.canChooseFiles = true
    panel.allowedFileTypes = ["public.image"]

    panel.beginSheetModal(for: self) { response in
      if response == .OK {
        result(nil)
      } else {
        result(nil)
      }
    }
  }
}
