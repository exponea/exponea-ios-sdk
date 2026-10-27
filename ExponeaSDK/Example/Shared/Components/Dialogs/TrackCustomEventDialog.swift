import SwiftUI

private struct InAppMessagePreset: Identifiable {
    let id = UUID()
    let label: String
    let category: String
    let eventName: String
    let properties: [String: String]
}

private let customPresetLabel = "(custom)"

private let inAppMessagePresets: [InAppMessagePreset] = [
    InAppMessagePreset(label: "Control Group", category: "Core rendering", eventName: "event_name", properties: ["property": "test_msg_control_group"]),
    InAppMessagePreset(label: "Alert Rich", category: "Core rendering", eventName: "event_name", properties: ["property": "test_msg_alert_rich"]),
    InAppMessagePreset(label: "Alert Legacy", category: "Core rendering", eventName: "event_name", properties: ["property": "test_msg_alert_legacy"]),
    InAppMessagePreset(label: "Slide-in", category: "Core rendering", eventName: "event_name", properties: ["property": "test_msg_slidein"]),
    InAppMessagePreset(label: "Modal", category: "Core rendering", eventName: "event_name", properties: ["property": "test_msg_modal"]),
    InAppMessagePreset(label: "Fullscreen", category: "Core rendering", eventName: "event_name", properties: ["property": "test_msg_fullscreen"]),
    InAppMessagePreset(label: "HTML", category: "Core rendering", eventName: "event_name", properties: ["property": "test_msg_html"]),
    InAppMessagePreset(label: "HTML No Close", category: "Core rendering", eventName: "event_name", properties: ["property": "test_msg_html_noclose"]),
    InAppMessagePreset(label: "Data Link External", category: "Core rendering", eventName: "event_name", properties: ["property": "test_msg_datalink"]),
    InAppMessagePreset(label: "UL Data Link + HTML Attr", category: "Core rendering", eventName: "event_name", properties: ["property": "test_msg_datalink_html_attr"]),
    InAppMessagePreset(label: "Auto Close 5s", category: "Behaviour", eventName: "event_name", properties: ["property": "test_msg_autoclose"]),
    InAppMessagePreset(label: "Stop SDK", category: "Behaviour", eventName: "event_name", properties: ["property": "test_msg_stop_sdk"]),
    InAppMessagePreset(label: "Stop And Restart", category: "Behaviour", eventName: "event_name", properties: ["property": "test_msg_stop_restart"]),
    InAppMessagePreset(label: "GDPR Dialog", category: "GDPR", eventName: "event_name", properties: ["property": "test_msg_gdpr"]),
    InAppMessagePreset(label: "GDPR No Consents Customer", category: "GDPR", eventName: "event_name", properties: ["property": "test_msg_gdpr_no_consents"]),
    InAppMessagePreset(label: "AB Variant A", category: "A/B testing", eventName: "event_name", properties: ["property": "test_msg_ab_variant_a"]),
    InAppMessagePreset(label: "AB Variant B", category: "A/B testing", eventName: "event_name", properties: ["property": "test_msg_ab_variant_b"])
]

struct TrackCustomEventDialog: View {

    @Binding var isPresented: Bool
    let onConfirm: (_ eventName: String, _ properties: [String: String]) -> Void

    @State private var selectedPresetLabel: String = customPresetLabel
    @State private var eventName: String = "custom_event"
    @State private var attrName: String = ""
    @State private var attrValue: String = ""
    @State private var properties: [String: String] = [:]

    private var isCustomPreset: Bool { selectedPresetLabel == customPresetLabel }
    private var propertiesJson: String { formatAttributesJson(properties) }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Picker("Preset", selection: $selectedPresetLabel) {
                        Text(customPresetLabel).tag(customPresetLabel)
                        ForEach(inAppMessagePresets) { preset in
                            Text(preset.label).tag(preset.label)
                        }
                    }
                    .pickerStyle(.menu)
                    .accessibilityIdentifier(A11yID.tracking.inappPreset)
                    .onChange(of: selectedPresetLabel) { newValue in
                        applyPreset(label: newValue)
                    }

                    authField(
                        placeholder: "Event name",
                        text: $eventName,
                        accessibilityId: A11yID.tracking.eventName,
                        disabled: !isCustomPreset
                    )

                    authField(
                        placeholder: "Attribute name",
                        text: $attrName,
                        accessibilityId: A11yID.tracking.eventAttrName
                    )

                    authField(
                        placeholder: "Attribute value",
                        text: $attrValue,
                        accessibilityId: A11yID.tracking.eventAttrValue
                    )

                    ExampleOutlinedButton(title: "Add") {
                        let name = attrName.trimmingCharacters(in: .whitespacesAndNewlines)
                        let value = attrValue.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !name.isEmpty, !value.isEmpty else { return }
                        properties[name] = value
                        attrName = ""
                        attrValue = ""
                    }
                    .accessibilityIdentifier(A11yID.tracking.eventAddAttr)

                    ExampleMonospacePanel(text: propertiesJson)
                        .accessibilityIdentifier(A11yID.tracking.eventPropsJson)

                    ExamplePrimaryButton(title: "Track") {
                        let name = eventName.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !name.isEmpty else { return }
                        onConfirm(name, properties)
                        isPresented = false
                    }
                    .accessibilityIdentifier(A11yID.tracking.trackEvent)
                }
                .padding()
            }
            .background(BrandColors.grey100)
            .navigationTitle(NSLocalizedString("dialog.customEvent.title", comment: ""))
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
    }

    private func authField(
        placeholder: String,
        text: Binding<String>,
        accessibilityId: String,
        disabled: Bool = false
    ) -> some View {
        TextField(placeholder, text: text)
            .exampleInputStyle()
            .autocapitalization(.none)
            .disableAutocorrection(true)
            .disabled(disabled)
            .accessibilityIdentifier(accessibilityId)
    }

    private func applyPreset(label: String) {
        guard label != customPresetLabel,
              let preset = inAppMessagePresets.first(where: { $0.label == label }) else {
            return
        }
        eventName = preset.eventName
        properties = preset.properties
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
