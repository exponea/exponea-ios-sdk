//
//  MessageItemCell.swift
//  ExponeaSDK
//
//  Created by Adam Mihalik on 07/10/2022.
//  Copyright © 2022 Exponea. All rights reserved.
//

import UIKit

public class MessageItemCell: UITableViewCell {

    // MARK: - Properties
    public let readFlag = UIView()
    public let receivedTime = UILabel()
    public let titleLabel = UILabel()
    public let messageImage = UIImageView()
    public let messageLabel = UILabel()
    public let infoStackView = UIStackView()
    public let statusView = UIStackView()
    public let contentStackView = UIStackView()

    // MARK: - Life-cycle
    public override func prepareForReuse() {
        super.prepareForReuse()

        receivedTime.text = nil
        titleLabel.text = nil
        messageImage.image = nil
        messageLabel.text = nil
    }

    public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        addContent()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}

// MARK: - Private Methods
private extension MessageItemCell {
    func convertToDarkIfNeeded() {
        guard Exponea.shared.isDarkMode else { return }
        if #available(iOS 13.0, *) {
            contentView.backgroundColor = .systemBackground
            titleLabel.textColor = .label
            receivedTime.textColor = .secondaryLabel
            readFlag.backgroundColor = .systemBlue
        }
    }

    func setupElements() {
        contentStackView.axis = .horizontal
        contentStackView.alignment = .top
        contentStackView.distribution = .fillProportionally
        contentStackView.spacing = 16

        infoStackView.axis = .vertical
        infoStackView.alignment = .top
        infoStackView.distribution = .fill

        statusView.distribution = .fill
        statusView.spacing = 8
        statusView.axis = .horizontal
        statusView.alignment = .center

        readFlag.backgroundColor = UIColor(red: 0.15, green: 0.15, blue: 0.15, alpha: 1)
        readFlag.layer.cornerRadius = 4

        receivedTime.font = .systemFont(ofSize: 12)
        receivedTime.textColor = UIColor(red: 0.4, green: 0.4, blue: 0.4, alpha: 1)
        receivedTime.numberOfLines = 1
        receivedTime.lineBreakMode = .byTruncatingTail

        titleLabel.font = .boldSystemFont(ofSize: 16)
        titleLabel.textColor = UIColor(red: 0.15, green: 0.15, blue: 0.15, alpha: 1)
        titleLabel.numberOfLines = 1
        titleLabel.lineBreakMode = .byTruncatingTail

        messageLabel.font = .systemFont(ofSize: 14)
        messageLabel.textColor = UIColor(red: 0.4, green: 0.4, blue: 0.4, alpha: 1)
        messageLabel.numberOfLines = 2
        messageLabel.lineBreakMode = .byTruncatingTail

        messageImage.layer.backgroundColor = UIColor(red: 0.961, green: 0.961, blue: 0.961, alpha: 1).cgColor
        messageImage.layer.cornerRadius = 4
        messageImage.clipsToBounds = true
        messageImage.contentMode = UIView.ContentMode.scaleAspectFill

        convertToDarkIfNeeded()
    }

    func addElementsToView() {
        contentView.addSubview(contentStackView)
        contentStackView.addArrangedSubview(infoStackView)
        contentStackView.addArrangedSubview(messageImage)
        [readFlag, receivedTime].forEach(statusView.addArrangedSubview(_:))
        [statusView, titleLabel, messageLabel].forEach(infoStackView.addArrangedSubview(_:))
    }

    func setupLayout() {
        statusView
            .frame(height: 20)
        contentStackView
            .padding(.leading, .top, .trailing, .bottom, constant: 16)
        readFlag
            .frame(width: 8, height: 8)
        messageImage
            .frame(width: 80, height: 80)
    }

    func addContent() {
        defer { setupLayout() }
        setupElements()
        addElementsToView()
    }
}

// MARK: - Methods
public extension MessageItemCell {
    func showData(_ source: MessageItem) {
        readFlag.isHidden = source.read
        addTextToLabel(receivedTime, translateReceivedTime(source.receivedTime), 1.14)
        addTextToLabel(titleLabel, source.content?.title, 1.26)
        addTextToLabel(messageLabel, source.content?.message ?? "", 1.2)
        if let imageUrl = source.content?.imageUrl {
            messageImage.isHidden = false
            DispatchQueue.global().async { [weak self] in
                guard let self = self else { return }
                guard let imageData = ImageUtils.tryDownloadImage(imageUrl),
                    let image = ImageUtils.createImage(imageData: imageData, maxDimensionInPixels: 80) else {
                    Exponea.logger.log(.error, message: "Image cannot be shown correctly")
                    onMain {
                        self.messageImage.isHidden = true
                    }
                    return
                }
                onMain(self.messageImage.image = image)
            }
        } else {
            messageImage.isHidden = true
        }
    }

    private func addTextToLabel(_ target: UILabel, _ text: String?, _ lineHeightMultiple: CGFloat) {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = lineHeightMultiple
        let attributedString = NSMutableAttributedString(string: text ?? "")
        attributedString.addAttribute(
            NSAttributedString.Key.paragraphStyle,
            value: paragraphStyle,
            range: NSMakeRange(0, attributedString.length)
        )
        target.attributedText = attributedString
    }

    func translateReceivedTime(_ source: Date) -> String {
        if #available(iOS 13.0, *) {
            let formatter = RelativeDateTimeFormatter()
            formatter.unitsStyle = .full
            return formatter.localizedString(for: source, relativeTo: Date())
        } else {
            let formatter = DateFormatter()
            formatter.timeStyle = .long
            formatter.dateStyle = .long
            formatter.doesRelativeDateFormatting = true
            return formatter.string(from: source)
        }
    }
}
