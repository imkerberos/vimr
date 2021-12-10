/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import NvimView
import PureLayout

protocol ThemedView: AnyObject {
  var theme: Theme { get }
  var lastThemeMark: Token { get }
}

class ThemedTableRow: NSTableRowView {
  weak var triangleView: NSButton?
  var themeToken: Token

  init(withIdentifier identifier: String, themedView: ThemedView) {
    self.themedView = themedView
    self.themeToken = themedView.lastThemeMark

    super.init(frame: .zero)

    self.identifier = NSUserInterfaceItemIdentifier(identifier)
  }

  override func didAddSubview(_ subview: NSView) {
    super.didAddSubview(subview)
    if subview.identifier == NSOutlineView.disclosureButtonIdentifier {
      self.triangleView = subview as? NSButton
    }
  }

  override open func drawBackground(in dirtyRect: NSRect) {
    if let cell = self.view(atColumn: 0) as? ThemedTableCell {
      if cell.isDir {
        cell.textField?.textColor
          = self.themedView?.theme.directoryForeground ?? Theme.default.directoryForeground
      } else {
        cell.textField?.textColor = self.themedView?.theme.foreground ?? Theme.default.foreground
      }
    }

    self.themedView?.theme.background.set()
    dirtyRect.fill()
  }

  override func drawSelection(in dirtyRect: NSRect) {
    if let cell = self.view(atColumn: 0) as? ThemedTableCell {
      cell.textField?.textColor
        = self.themedView?.theme.highlightForeground ?? Theme.default.highlightForeground
    }

    self.themedView?.theme.highlightBackground.set()
    dirtyRect.fill()
  }

  private weak var themedView: ThemedView?

  @available(*, unavailable)
  required init?(coder _: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

class ThemedTableCell: NSTableCellView {
  // MARK: - API

  static let font = NSFont(name: "SarasaMonoSCNerd-Nerd", size: 16) ?? NSFont.systemFont(ofSize: 16)
  static let widthWithoutText = (2 + 20 + 4 + 2).cgf

//  static func width(with text: String) -> CGFloat {
//    let attrStr = NSAttributedString(string: text, attributes: [NSAttributedString.Key.font: ThemedTableCell.font])
//
//    return self.widthWithoutText + attrStr.size().width
//  }
//
//  override var intrinsicContentSize: CGSize {
//    return CGSize(width: ThemedTableCell.widthWithoutText + self._textField.intrinsicContentSize.width,
//                  height: max(self._textField.intrinsicContentSize.height, 16))
//  }

  var isDir = false

  var attributedText: NSAttributedString {
    get { self.textField!.attributedStringValue }

    set {
      self.textField?.attributedStringValue = newValue
      self.addTextField()
    }
  }

  var text: String {
    get { self.textField!.stringValue }

    set {
      self.textField?.stringValue = newValue
      self.addTextField()
    }
  }

  var image: NSImage? {
    get { self.imageView?.image }

    set {
      self.imageView?.image = newValue

      self.removeAllSubviews()

      let textField = self._textField
      let imageView = self._imageView

      self.addSubview(textField)
      self.addSubview(imageView)

      imageView.autoPinEdge(toSuperviewEdge: .top, withInset: 2)
      imageView.autoPinEdge(toSuperviewEdge: .left, withInset: 2)
      imageView.autoSetDimension(.width, toSize: 18)
      imageView.autoSetDimension(.height, toSize: 18)

      textField.autoPinEdge(toSuperviewEdge: .top, withInset: 2)
      textField.autoPinEdge(toSuperviewEdge: .right, withInset: 2)
      textField.autoPinEdge(toSuperviewEdge: .bottom, withInset: 2)
      textField.autoPinEdge(.left, to: .right, of: imageView, withOffset: 4)
    }
  }

  init(withIdentifier identifier: String) {
    super.init(frame: .zero)

    self.identifier = NSUserInterfaceItemIdentifier(identifier)

    self.textField = self._textField
    self.imageView = self._imageView

    let textField = self._textField
    textField.font = ThemedTableCell.font
    textField.isBordered = false
    textField.isBezeled = false
    textField.allowsEditingTextAttributes = false
    textField.isEditable = false
    textField.usesSingleLineMode = true
    textField.drawsBackground = false
  }

  func reset() -> ThemedTableCell {
    self.text = ""
    self.image = nil
    self.isDir = false

    self.removeAllSubviews()

    return self
  }

  private func addTextField() {
    let textField = self._textField

    textField.removeFromSuperview()
    self.addSubview(textField)

    textField.autoPinEdgesToSuperviewEdges(with: NSEdgeInsets(top: 2, left: 4, bottom: 2, right: 2))
  }

  private let _textField = NSTextField(forAutoLayout: ())
  private let _imageView = NSImageView(forAutoLayout: ())

  @available(*, unavailable)
  required init?(coder _: NSCoder) { fatalError("init(coder:) has not been implemented") }
}
