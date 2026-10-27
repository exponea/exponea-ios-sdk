import SwiftUI
import UIKit
import ExponeaSDK

final class ExampleAppInboxProvider: DefaultAppInboxProvider {
    override func getAppInboxButton() -> UIButton {
        let button = super.getAppInboxButton()
        // Same look as ExamplePrimaryButtonStyle.
        button.backgroundColor = .brYellow
        button.layer.cornerRadius = 8
        button.clipsToBounds = true
        button.setTitleColor(.brBlack, for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14.0)
        return button
    }

    override func getAppInboxListViewController() -> UIViewController {
        let listController = super.getAppInboxListViewController()
        if let typedListController = listController as? AppInboxListViewController {
            typedListController.loadViewIfNeeded()
            typedListController.statusErrorTitle.textColor = .red
        }
        return listController
    }

    override func getAppInboxDetailViewController(_ messageId: String) -> UIViewController {
        let detailController = super.getAppInboxDetailViewController(messageId)
        if let typedDetailController = detailController as? AppInboxDetailViewController {
            typedDetailController.loadViewIfNeeded()
            typedDetailController.messageTitle.font = .systemFont(ofSize: 32)
            stylizeActionButton(typedDetailController.actionMain)
            stylizeActionButton(typedDetailController.action1)
            stylizeActionButton(typedDetailController.action2)
            stylizeActionButton(typedDetailController.action3)
            stylizeActionButton(typedDetailController.action4)
        }
        return detailController
    }

    private func stylizeActionButton(_ button: UIButton) {
        button.setTitleColor(.brBlack, for: .normal)
        button.layer.cornerRadius = 8
        button.clipsToBounds = true
        button.backgroundColor = .brYellow
    }
}

struct AppInboxButtonRepresentable: UIViewRepresentable {

    var onOpenInbox: () -> Void = {}

    func makeUIView(context: Context) -> UIView {
        let button = Exponea.shared.getAppInboxButton()
        button.removeTarget(nil, action: nil, for: .allEvents)
        button.addAction(UIAction { _ in onOpenInbox() }, for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false

        let container = UIView()
        container.addSubview(button)
        NSLayoutConstraint.activate([
            button.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            button.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            button.topAnchor.constraint(equalTo: container.topAnchor),
            button.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
        return container
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}

struct AppInboxListRepresentable: UIViewControllerRepresentable {

    let onMessageSelected: (String) -> Void

    func makeUIViewController(context: Context) -> UIViewController {
        let controller = Exponea.shared.getAppInboxListViewController { message, _ in
            DispatchQueue.main.async {
                onMessageSelected(message.id)
            }
        }
        controller.view.accessibilityIdentifier = A11yID.appInbox.list
        return controller
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}

struct AppInboxDetailRepresentable: UIViewControllerRepresentable {

    let messageId: String

    func makeUIViewController(context: Context) -> UIViewController {
        let controller = Exponea.shared.getAppInboxDetailViewController(messageId)
        controller.view.accessibilityIdentifier = A11yID.appInbox.detailView
        return controller
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}
