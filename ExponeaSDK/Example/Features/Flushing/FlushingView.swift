import SwiftUI

struct FlushingView: View {

    @ObservedObject var viewModel: FlushingViewModel

    var body: some View {
        VStack(spacing: 12) {
            tabRow
            tabContent
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .exampleScreenBackground()
        .onAppear { viewModel.onAppear() }
        .overlay {
            if viewModel.isFlushing {
                ProgressView()
                    .tint(BrandColors.brBlack)
                    .padding()
                    .background(.regularMaterial)
                    .cornerRadius(8)
            }
        }
        .overlay(alignment: .bottom) {
            if let message = viewModel.feedback {
                FeedbackBanner(message: message) { viewModel.feedback = nil }
            }
        }
        .alert(viewModel.flushResultTitle, isPresented: $viewModel.showFlushResultDialog) {
            Button("Ok") { viewModel.showFlushResultDialog = false }
                .accessibilityIdentifier(A11yID.flushing.flushResultOk)
        } message: {
            if let detail = viewModel.flushResultMessage {
                Text(detail)
            }
        }
    }

    private var tabRow: some View {
        HStack(spacing: 8) {
            tabButton(title: "Flush Mode", tab: .flushMode, identifier: A11yID.flushing.tabFlushMode)
            tabButton(title: "Flush Period", tab: .flushPeriod, identifier: A11yID.flushing.tabFlushPeriod)
            tabButton(title: "Log Level", tab: .logLevel, identifier: A11yID.flushing.tabLogLevel)
        }
    }

    @ViewBuilder
    private var tabContent: some View {
        switch viewModel.selectedTab {
        case .flushMode:
            flushModeTab
        case .flushPeriod:
            flushPeriodTab
        case .logLevel:
            logLevelTab
        }
    }

    private var flushModeTab: some View {
        ExampleSectionCard(title: "Flush Mode") {
            VStack(alignment: .leading, spacing: 12) {
                actionButton(title: "Get Flush Mode", identifier: A11yID.flushing.getFlushMode) {
                    viewModel.refreshMode(showFeedback: true)
                }
                ExampleStatusBox(
                    text: "Current mode: \(viewModel.currentModeLabel)",
                    identifier: A11yID.flushing.currentFlushMode
                )
                HStack(spacing: 8) {
                    modeButton(title: "IMMEDIATE", identifier: A11yID.flushing.modeImmediate) {
                        viewModel.setFlushModeImmediate()
                    }
                    modeButton(title: "PERIOD", identifier: A11yID.flushing.modePeriod) {
                        viewModel.setFlushModePeriod()
                    }
                }
                HStack(spacing: 8) {
                    modeButton(title: "APP_CLOSE", identifier: A11yID.flushing.modeAppClose) {
                        viewModel.setFlushModeAppClose()
                    }
                    modeButton(title: "MANUAL", identifier: A11yID.flushing.modeManual) {
                        viewModel.setFlushModeManual()
                    }
                }
            }
        }
    }

    private var flushPeriodTab: some View {
        ExampleSectionCard(title: "Flush Period") {
            VStack(alignment: .leading, spacing: 12) {
                actionButton(title: "Get Flush Period", identifier: A11yID.flushing.getFlushPeriod) {
                    viewModel.refreshPeriod(showFeedback: true)
                }
                ExampleStatusBox(
                    text: periodStatusText,
                    identifier: A11yID.flushing.currentFlushPeriod
                )
                HStack(spacing: 8) {
                    modeButton(title: "30 s", identifier: A11yID.flushing.period30) {
                        viewModel.setFlushPeriod30()
                    }
                    modeButton(title: "60 s", identifier: A11yID.flushing.period60) {
                        viewModel.setFlushPeriod60()
                    }
                }
                actionButton(title: "Flush Data", identifier: A11yID.flushing.flushData) {
                    viewModel.flushData()
                }
            }
        }
    }

    private var logLevelTab: some View {
        ExampleSectionCard(title: "Log Level") {
            VStack(alignment: .leading, spacing: 12) {
                actionButton(title: "Get Log Level", identifier: A11yID.flushing.getLogLevel) {
                    viewModel.refreshLogLevel(showFeedback: true)
                }
                ExampleStatusBox(
                    text: "Current log level: \(viewModel.currentLogLevelLabel)",
                    identifier: A11yID.flushing.currentLogLevel
                )
                HStack(spacing: 8) {
                    modeButton(title: "OFF", identifier: A11yID.flushing.logOff) {
                        viewModel.setLogLevelOff()
                    }
                    modeButton(title: "ERROR", identifier: A11yID.flushing.logError) {
                        viewModel.setLogLevelError()
                    }
                    modeButton(title: "WARN", identifier: A11yID.flushing.logWarn) {
                        viewModel.setLogLevelWarn()
                    }
                }
                HStack(spacing: 8) {
                    modeButton(title: "INFO", identifier: A11yID.flushing.logInfo) {
                        viewModel.setLogLevelInfo()
                    }
                    modeButton(title: "DEBUG", identifier: A11yID.flushing.logDebug) {
                        viewModel.setLogLevelDebug()
                    }
                    modeButton(title: "VERBOSE", identifier: A11yID.flushing.logVerbose) {
                        viewModel.setLogLevelVerbose()
                    }
                }
            }
        }
    }

    private var periodStatusText: String {
        if viewModel.currentPeriodLabel == "—" {
            return "Current period: — (requires PERIOD mode)"
        }
        return "Current period: \(viewModel.currentPeriodLabel) seconds"
    }

    private func tabButton(title: String, tab: FlushingScreenTab, identifier: String) -> some View {
        Button(title) {
            viewModel.selectedTab = tab
        }
        .buttonStyle(ExampleSegmentTabButtonStyle(isSelected: viewModel.selectedTab == tab))
        .frame(maxWidth: .infinity)
        .accessibilityIdentifier(identifier)
    }

    private func actionButton(title: String, identifier: String, action: @escaping () -> Void) -> some View {
        ExamplePrimaryButton(title: title, action: action)
            .accessibilityIdentifier(identifier)
    }

    private func modeButton(title: String, identifier: String, action: @escaping () -> Void) -> some View {
        ExamplePrimaryButton(title: title, action: action)
            .accessibilityIdentifier(identifier)
    }
}
