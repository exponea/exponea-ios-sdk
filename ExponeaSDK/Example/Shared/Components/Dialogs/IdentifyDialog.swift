import SwiftUI

struct IdentifyDialog: View {

    @Binding var isPresented: Bool
    let isStreamMode: Bool
    let isCustomerIdentified: Bool
    let savedRegisteredId: String
    let onConfirm: (_ customerIds: [String: String], _ properties: [String: String], _ withToken: Bool) -> Void

    @State private var registeredId: String = ""
    @State private var attrName: String = ""
    @State private var attrValue: String = ""
    @State private var attributes: [String: String] = [:]

    private var registeredLabel: String {
        let trimmed = savedRegisteredId.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "<not set>" : trimmed
    }

    private var attributesJson: String {
        formatAttributesJson(attributes)
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    if isCustomerIdentified {
                        ExampleMonospacePanel(text: "registered: \(registeredLabel)")
                            .accessibilityIdentifier(A11yID.tracking.registeredIdLabel)
                    } else {
                        authField(
                            placeholder: "Registered ID (email)",
                            text: $registeredId,
                            accessibilityId: A11yID.tracking.registeredId
                        )
                    }

                    authField(
                        placeholder: "Attribute name",
                        text: $attrName,
                        accessibilityId: A11yID.tracking.identifyAttrName
                    )

                    authField(
                        placeholder: "Attribute value",
                        text: $attrValue,
                        accessibilityId: A11yID.tracking.identifyAttrValue
                    )

                    ExampleOutlinedButton(title: "Add") {
                        let name = attrName.trimmingCharacters(in: .whitespacesAndNewlines)
                        let value = attrValue.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !name.isEmpty, !value.isEmpty else { return }
                        attributes[name] = value
                        attrName = ""
                        attrValue = ""
                    }
                    .accessibilityIdentifier(A11yID.tracking.identifyAddAttr)

                    ExampleMonospacePanel(text: attributesJson)
                        .accessibilityIdentifier(A11yID.tracking.identifyAttrsJson)

                    ExamplePrimaryButton(title: "Identify") {
                        submit(withToken: false)
                    }
                    .accessibilityIdentifier(A11yID.tracking.identify)

                    if isStreamMode {
                        ExampleOutlinedButton(title: "Identify with auth token") {
                            submit(withToken: true)
                        }
                        .accessibilityIdentifier(A11yID.tracking.identifyAuth)
                    }
                }
                .padding()
            }
            .background(BrandColors.grey100)
            .navigationTitle(NSLocalizedString("dialog.identify.title", comment: ""))
            .navigationBarTitleDisplayMode(.inline)
            .exampleSheetNavigationBar()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                        .foregroundColor(BrandColors.white)
                }
            }
        }
        .navigationViewStyle(.stack)
        .onAppear {
            registeredId = savedRegisteredId
        }
    }

    private func authField(
        placeholder: String,
        text: Binding<String>,
        accessibilityId: String
    ) -> some View {
        TextField(placeholder, text: text)
            .exampleInputStyle()
            .autocapitalization(.none)
            .disableAutocorrection(true)
            .accessibilityIdentifier(accessibilityId)
    }

    private func submit(withToken: Bool) {
        var ids: [String: String] = [:]
        let rid = isCustomerIdentified
            ? savedRegisteredId.trimmingCharacters(in: .whitespacesAndNewlines)
            : registeredId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !rid.isEmpty else { return }
        ids["registered"] = rid
        onConfirm(ids, attributes, withToken)
        isPresented = false
    }

    // The braces below are JSON text inside string literals, not code blocks.
    // swiftlint:disable open_brace_spacing close_brace_spacing
    private func formatAttributesJson(_ attributes: [String: String]) -> String {
        if attributes.isEmpty { return "{\n\n}" }
        let lines = attributes.map { "\t \($0.key): \($0.value)" }
        return "{\n" + lines.joined(separator: ",\n") + "\n}"
    }
    // swiftlint:enable open_brace_spacing close_brace_spacing
}
