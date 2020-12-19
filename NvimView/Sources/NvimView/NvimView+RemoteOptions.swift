/**
 * Renee Koecher -  @shirk
 * See LICENSE
 */

import Cocoa
import MessagePack
import RxSwift

extension NvimView {
  enum RemoteOption {
    // list of currently handled remote options
    case guifont(fontSpec: String)
    case guifontWide(fontSpec: String)

    static func fromValuePair(_ option: (key: MessagePackValue, value: MessagePackValue)) -> RemoteOption? {
      switch option.key.stringValue ?? "" {
      case "guifont": return RemoteOption.guifont(fontSpec: option.value.stringValue ?? "")
      case "guifontwide": return RemoteOption.guifontWide(fontSpec: option.value.stringValue ?? "")

      default: return nil
      }
    }

    // convenience methods
    static func fromFont(_ font: NSFont, forWideFont isWide: Bool = false) -> RemoteOption? {
      guard let fontSpec = FontUtils.vimFontSpec(forFont: font) else {
        return nil
      }

      if isWide {
        return RemoteOption.guifontWide(fontSpec: fontSpec)
      }
      return RemoteOption.guifont(fontSpec: fontSpec)
    }
  }

  final func handleRemoteOptions(_ options: [MessagePackValue: MessagePackValue]) {
    for kvPair in options {
      guard let option = RemoteOption.fromValuePair(kvPair) else {
        self.bridgeLogger.debug("Could not handle RemoteOption \(kvPair)")
        continue
      }

      switch option {
        // fixme: currently this treats gft and gfw the as the same
        case .guifont(let fontSpec): handleGuifontSet(fontSpec)
        case .guifontWide(let fontSpec): handleGuifontSet(fontSpec, forWideFont: true)
      }
    }
  }

  final func signalRemoteOptionChange(_ option: RemoteOption) {
    var command: Completable? = nil

    switch option {
    case .guifont(let fontSpec):
        command = self.api.setOption(name: "guifont", value: .string(fontSpec))

    case .guifontWide(let fontSpec):
        command = self.api.setOption(name: "guifontwide", value: .string(fontSpec))
    }

    command?.subscribe().disposed(by: self.disposeBag)
  }

  public final func signalError(code: Int, message: String) {
      self.api.errWriteln(str: "E\(code): \(message)")
              .subscribe()
              .disposed(by: self.disposeBag)
  }

  private func handleGuifontSet(_ fontSpec: String, forWideFont wideFlag: Bool = false) {
    if fontSpec.isEmpty {
      // this happens on connect - signal the current value
      signalRemoteOptionChange(RemoteOption.fromFont(self.font, forWideFont: wideFlag)!)
      return
    }

    // stop if we would set the same font again

    if let currentSpec = FontUtils.vimFontSpec(forFont: font) {
      let escapedFontSpec = fontSpec.components(separatedBy: " ").joined(separator: "_")

      if currentSpec == escapedFontSpec {
        return
      }
    }

    let fontParams = fontSpec.components(separatedBy: ":")

    guard fontParams.count == 2 else {
      self.bridgeLogger.debug("Invalid specification for guifont '\(fontSpec)'")

      signalError(code: 596, message: "Invalid font(s): gufont=\(fontSpec)")
      signalRemoteOptionChange(RemoteOption.fromFont(self.font, forWideFont: wideFlag)!)
      return
    }

    let fontName = fontParams[0].components(separatedBy: "_").joined(separator: " ")
    var fontSize = NvimView.defaultFont.pointSize // use a sane fallback

    if fontParams[1].hasPrefix("h") && fontParams[1].count >= 2 {
      let sizeSpec = fontParams[1].dropFirst()
      if let parsed = Float(sizeSpec)?.rounded() {
        fontSize = CGFloat(parsed)

        if fontSize < NvimView.minFontSize || fontSize > NvimView.maxFontSize {
          fontSize = NvimView.defaultFont.pointSize
        }
      }
    }

    if let newFont = NSFont(name: fontName, size: CGFloat(fontSize)) {
      gui.async {
        self.font = newFont
        self.markForRenderWholeView()
        self.eventsSubject.onNext(.guifontChanged(newFont))
      }
    } else {
      self.bridgeLogger.debug("No valid font for name=\(fontName) size=\(fontSize)")

      signalError(code: 596, message: "Invalid font(s): gufont=\(fontSpec)")
      signalRemoteOptionChange(RemoteOption.fromFont(self.font, forWideFont: wideFlag)!)
    }
  }
}

private let gui = DispatchQueue.main
