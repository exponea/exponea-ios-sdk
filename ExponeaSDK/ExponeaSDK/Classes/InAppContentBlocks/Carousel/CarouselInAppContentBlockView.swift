//
//  InAppContentBlockCarouselView.swift
//  ExponeaSDK
//
//  Created by Ankmara on 28.05.2024.
//  Copyright © 2024 Exponea. All rights reserved.
//

import WebKit
import UIKit
import Combine
#if canImport(ExponeaSDKShared)
import ExponeaSDKShared
#endif

open class CarouselInAppContentBlockView: UIView {

    var isFirstCellLoaded = false
    private var height: NSLayoutConstraint?

    func createCompositionalLayout() -> UICollectionViewLayout {
        UICollectionViewCompositionalLayout { [weak self] _, _ in
            self?.createHorizontalScrollLayoutSection() ?? Self.fallbackEmptyLayoutSection()
        }
    }

    /// Returned only when `self` has already been released and the layout system asks for
    /// a section provider one final time. The collection view will be torn down momentarily;
    /// returning a degenerate empty section is safer than force-unwrapping.
    private static func fallbackEmptyLayoutSection() -> NSCollectionLayoutSection {
        let item = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .fractionalHeight(1.0)
        ))
        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .fractionalHeight(1.0)
            ),
            subitems: [item]
        )
        return NSCollectionLayoutSection(group: group)
    }

    func createHorizontalScrollLayoutSection() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .fractionalHeight(1.0))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .fractionalHeight(1.0))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
        let section = NSCollectionLayoutSection(group: group)
        section.orthogonalScrollingBehavior = .groupPagingCentered
        return section
    }

    private lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: createCompositionalLayout())
        collectionView.delegate = self
        collectionView.backgroundColor = .clear
        collectionView.dataSource = self
        collectionView.register(CarouselContentBlockViewCell.self, reuseIdentifier: "cell")
        collectionView.register(UICollectionViewCell.self, reuseIdentifier: "UICollectionViewCell")
        return collectionView
    }()

    @Published var state: InAppCarouselStateType = .idle
    @Published var currentIndex: Int = 0
    var cancellables: [AnyCancellable] = []
    private let defaultRefreshInterval: TimeInterval
    // Created on first use, so no WKWebView exists before there is content to measure.
    lazy var calculator: WKWebViewHeightCalculator = makeCalculator()
    var lastScrollTimestamp: TimeInterval = Date().timeIntervalSince1970
    private var timer: AnyCancellable?
    private lazy var inAppContentBlocksManager = InAppContentBlocksManager.manager
    private let maxMessagesCount: Int
    private var customHeight: CGFloat?
    private var currentMessage: StaticReturnData?
    private var alreadyShowedMessages: [String] = []
    private let defaultBehaviourCallback: DefaultContentBlockCarouselCallback!
    private var behaviourCallback: InAppContentBlockCallbackType = DefaultInAppContentBlockCallback()
    private var pendingScrollMessageId: String?
    private var didNotifyNoMessage = false
    private var hasStartedCarousel = false
    private var reloadToken = UUID()
    private var pendingInitialApplyWorkItem: DispatchWorkItem?
    private let carouselStartDelay: TimeInterval = 0.5
    private let carouselInitialApplyDelay: TimeInterval = 0.1

    @Atomic private var messages: [StaticReturnData] = []
    @Atomic private var data: [StaticReturnData] = []
    private var savedTimer: TimeInterval?
    private let placeholder: String
    private(set) var isCalculatorCreated = false

    public init(
        placeholder: String,
        maxMessagesCount: Int = 0,
        customHeight: CGFloat? = nil,
        scrollDelay: TimeInterval = 3,
        behaviourCallback: DefaultContentBlockCarouselCallback? = nil
    ) {
        self.placeholder = placeholder
        self.maxMessagesCount = maxMessagesCount
        self.customHeight = customHeight
        self.defaultRefreshInterval = scrollDelay
        defaultBehaviourCallback = ContentBlockCarouselCallback(behaviourCallback: behaviourCallback)
        super.init(frame: .zero)

        listenToState()

        NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
            .sink { [weak self] _ in
                self?.startTimer()
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)
            .sink { [weak self] _ in
                self?.saveCurrentTimer()
            }
            .store(in: &cancellables)

        IntegrationManager.shared.onIntegrationStoppedCallbacks.append { [weak self] in
            guard let self else { return }
            self.height?.constant = 0
            self.stopTimer()
            self.layoutIfNeeded()
        }

        redrawWithNewHeight(inputView: self, loadedInAppContentBlocksView: collectionView, height: 1)
    }

    private func makeCalculator() -> WKWebViewHeightCalculator {
        let calculator = ContentBlockWebViewFactory.makeHeightCalculator()
        isCalculatorCreated = true
        calculator.heightUpdate = { [weak self] height in
            guard let self else { return }
            let height = self.customHeight ?? height.height
            self.redrawWithNewHeight(inputView: self, loadedInAppContentBlocksView: collectionView, height: height)
            defaultBehaviourCallback.onHeightUpdate(placeholderId: placeholder, height: height)
        }
        return calculator
    }

    open func filterContentBlocks(placeholder: String, continueCallback: TypeBlock<[InAppContentBlockResponse]>?, expiredCompletion: EmptyBlock?) {
        inAppContentBlocksManager.filterCarouselData(placeholder: placeholder, continueCallback: continueCallback, expiredCompletion: expiredCompletion)
    }

    open func sortContentBlocks(data: [StaticReturnData]) -> [StaticReturnData] {
        var priorityData: [Int: [StaticReturnData]] = [:]
        let dataToSort = data.sorted { lhs, rhs in
            lhs.message?.loadPriority ?? 0 > rhs.message?.loadPriority ?? 0
        }
        dataToSort.forEach { staticData in
            if priorityData[staticData.message?.loadPriority ?? 0] == nil {
                priorityData[staticData.message?.loadPriority ?? 0] = [staticData]
            } else {
                priorityData[staticData.message?.loadPriority ?? 0]?.append(staticData)
            }
        }
        var toReturn: [StaticReturnData] = []
        priorityData.sorted(by: { $0.key > $1.key }).forEach { _, value in
            toReturn.append(contentsOf: value.sorted(by: { $0.message?.name ?? "" < $1.message?.name ?? "" }))
        }
        return toReturn
    }

    open func reload(isTriggered: Bool = false) {
        // Public surface (`open` on a `public` class): host apps and subclasses may call
        // `reload` from any thread. The main-queue hop below is mandatory — `performReload`
        // mutates view state that must be touched only on main.
        onMain { [weak self] in
            guard let self else { return }
            self.performReload(isTriggered: isTriggered)
        }
    }

    /// Main-queue-only body of `reload`. Kept non-overridable so subclasses can still override
    /// the public `reload(isTriggered:)` entry point, but the thread-sensitive state transitions
    /// here are guaranteed to run on main.
    private func performReload(isTriggered: Bool) {
        alreadyShowedMessages.removeAll()
        savedTimer = nil
        state = .stopTimer
        didNotifyNoMessage = false
        hasStartedCarousel = false
        pendingScrollMessageId = nil
        pendingInitialApplyWorkItem?.cancel()
        pendingInitialApplyWorkItem = nil
        reloadToken = UUID()
        guard !IntegrationManager.shared.isStopped else {
            Exponea.logger.log(.error, message: "In-app reload failed: SDK is stopping")
            return
        }
        let token = reloadToken
        inAppContentBlocksManager.loadMessagesForCarousel(
            placeholder: placeholder,
            initialCompletion: { [weak self] in
                onMain {
                    guard let self, self.reloadToken == token else { return }
                    let workItem = DispatchWorkItem { [weak self] in
                        guard let self, self.reloadToken == token else { return }
                        self.pendingInitialApplyWorkItem = nil
                        self.applyCarouselData(isTriggered: true, phase: .initial)
                    }
                    self.pendingInitialApplyWorkItem?.cancel()
                    self.pendingInitialApplyWorkItem = workItem
                    DispatchQueue.main.asyncAfter(deadline: .now() + self.carouselInitialApplyDelay, execute: workItem)
                }
            },
            completion: { [weak self] in
                onMain {
                    guard let self, self.reloadToken == token else { return }
                    if let pendingInitialApplyWorkItem = self.pendingInitialApplyWorkItem {
                        pendingInitialApplyWorkItem.cancel()
                        self.pendingInitialApplyWorkItem = nil
                    }
                    self.applyCarouselData(isTriggered: true, phase: .full)
                }
            }
        )
    }

    internal func makeDuplicate(input: [StaticReturnData]) -> [StaticReturnData] {
        let multiplier: Int
        switch true {
        case input.count == 1:
            multiplier = 1
        case input.count <= 2:
            multiplier = 100
        case input.count <= 5:
            multiplier = 50
        case input.count <= 10:
            multiplier = 25
        default:
            multiplier = 10
        }
        var copy: [StaticReturnData] = []
        for _ in 0..<multiplier {
            let updatedInput = input.map { data in
                var beforeUpdate = data
                beforeUpdate.id = UUID()
                return beforeUpdate
            }
            copy.append(contentsOf: updatedInput)
        }
        return copy
    }

    private enum CarouselLoadPhase {
        case initial
        case full
    }

    private func applyCarouselData(isTriggered: Bool, phase: CarouselLoadPhase) {
        dispatchPrecondition(condition: .onQueue(.main))
        if phase == .full {
            reportCorruptedImages()
        }
        let token = reloadToken
        filterContentBlocks(placeholder: placeholder) { [weak self] data in
            // Called off main when the catalog had to be reloaded first; the apply creates a WKWebView.
            onMain {
                guard let self, self.reloadToken == token else { return }
                self.applyFilteredCarouselData(data, phase: phase)
            }
        } expiredCompletion: { [weak self] in
            guard let self else { return }
            if !isTriggered {
                self.reload(isTriggered: true)
            }
        }
    }

    private func applyFilteredCarouselData(_ data: [InAppContentBlockResponse], phase: CarouselLoadPhase) {
        dispatchPrecondition(condition: .onQueue(.main))
        guard !data.isEmpty else {
            if phase == .full {
                self.notifyNoMessageFound()
            }
            return
        }
        let toReturn = data.compactMap { response in
            self.inAppContentBlocksManager.prepareCarouselStaticData(messages: response)
        }
        let sortedMessages = self.sortContentBlocks(data: toReturn)
        let input = self.maxMessagesCount > 0 ? Array(sortedMessages.prefix(self.maxMessagesCount)) : sortedMessages
        guard !input.isEmpty else {
            if phase == .full {
                self.notifyNoMessageFound()
            }
            return
        }
        let currentMessageId = self.currentMessage?.message?.id
        let newFiltered = input.filter { $0.message != nil }
        if phase == .full {
            // Eligible set unchanged from the initial phase: skip the rebuild,
            // the second WKWebView load, and the collection-view refresh to avoid
            // the visible flicker / scroll-jump on the cold-render path.
            let previousIds = self.messages.compactMap { $0.message?.id }
            let nextIds = newFiltered.compactMap { $0.message?.id }
            if previousIds == nextIds, !previousIds.isEmpty {
                return
            }
        }
        self.messages = newFiltered
        self.pendingScrollMessageId = currentMessageId
        self._data.changeValue(with: { $0 = self.makeDuplicate(input: input) })
        if let first = self.data.first?.html {
            InAppContentBlockRenderHistory.shared.recordRender()
            self.calculator.loadHtml(placedholderId: self.placeholder, html: first)
        }
        self.state = .refresh
        if !self.hasStartedCarousel {
            self.hasStartedCarousel = true
            DispatchQueue.main.asyncAfter(deadline: .now() + carouselStartDelay) { [weak self] in
                self?.startCarouseling()
            }
        }
    }

    private func notifyNoMessageFound() {
        guard !didNotifyNoMessage else { return }
        didNotifyNoMessage = true
        defaultBehaviourCallback.onNoMessageFound(placeholderId: placeholder)
    }

    private func reportCorruptedImages() {
        inAppContentBlocksManager
            .inAppContentBlockMessages
            .filter { $0.placeholders.contains(placeholder) }
            .filter { $0.personalizedMessage?.isCorruptedImage == true }
            .forEach { message in
                defaultBehaviourCallback.onError(
                    placeholderId: message.id,
                    contentBlock: message,
                    errorMessage: "Corrupted image for \(message.id)"
                )
            }
    }

    private func indexForMessageId(_ messageId: String) -> Int? {
        guard !data.isEmpty else { return nil }
        let middleIndex = data.count / 2
        if let index = data[middleIndex...].firstIndex(where: { $0.message?.id == messageId }) {
            return index
        }
        if let index = data[..<middleIndex].firstIndex(where: { $0.message?.id == messageId }) {
            return index
        }
        return nil
    }

    private func scrollToPendingMessageOrCenter() {
        guard !data.isEmpty else { return }
        let targetIndex: Int = {
            if let messageId = pendingScrollMessageId,
               let index = indexForMessageId(messageId) {
                return index
            }
            return data.count / 2
        }()
        pendingScrollMessageId = nil
        collectionView.scrollToItem(at: IndexPath(item: targetIndex, section: 0), at: .centeredHorizontally, animated: false)
    }

    public func checkMessage(message: StaticReturnData, shouldBeReloaded: Bool = false) {
        guard let messageResponse = message.message else { return }
        inAppContentBlocksManager.isMessageValid(message: messageResponse) { [weak self] isValid in
            guard let self else { return }
            if !isValid {
                self._data.changeValue(with: { $0.removeAll(where: { $0.message?.id == message.message?.id }) })
                self.state = .refresh
            }
            if shouldBeReloaded {
                self.state = .shouldReload
            }
        } refreshCallback: { [weak self] in
            guard let self else { return }
            self.inAppContentBlocksManager.refreshMessage(message: messageResponse) { message in
                if let newData = self.inAppContentBlocksManager.prepareCarouselStaticData(messages: message) {
                    var indexes: [Int] = []
                    for message in self.data.filter({ $0.message?.id == message.id }) {
                        if let index = self.data.firstIndex(where: { $0.id == message.id }) {
                            indexes.append(index)
                        }
                    }
                    indexes.forEach { index in
                        if self.data[safeIndex: index] != nil {
                            self._data.changeValue(with: { $0[index] = newData })
                        }
                    }
                }
            }
        }
    }

    public func continueWithTimer() {
        guard timer != nil else { return }
        startCarouseling()
    }

    private func startCarouseling() {
        startTimer()
    }

    private func saveCurrentTimer() {
        savedTimer = Date().timeIntervalSince1970 - lastScrollTimestamp
        stopTimer()
    }

    private func startTimer() {
        guard defaultRefreshInterval > 0 else { return }
        stopTimer()
        var every: TimeInterval = defaultRefreshInterval
        if let savedTimer {
            self.savedTimer = nil
            every -= savedTimer
        }
        timer = Timer.publish(every: every, on: .main, in: .common)
            .autoconnect()
            .sink(receiveValue: { [weak self] _ in
                guard let self else { return }
                if every < self.defaultRefreshInterval {
                    self.state = .restart
                    self.state = .shouldReload
                } else {
                    self.state = .shouldReload
                }
            })
    }

    public func release() {
        removeFromSuperview()
        stopTimer()
        pendingInitialApplyWorkItem?.cancel()
        pendingInitialApplyWorkItem = nil
        // The foreground/background observers are Combine `publisher(for:).sink`
        // subscriptions stored in `cancellables`, not selector-based observers.
        // Dropping the cancellables is what actually unsubscribes them. This also
        // tears down the `$state` listener (`listenToState()`), which is the
        // intended behavior on release — the view is no longer in the hierarchy.
        cancellables.removeAll()
    }

    deinit {
        release()
    }

    func stopTimer() {
        timer?.cancel()
    }

    public func getShownContentBlock() -> StaticReturnData? {
        currentMessage
    }

    public func getShownIndex() -> Int {
        data.firstIndex(where: { $0.message?.id == currentMessage?.message?.id }) ?? -1
    }

    public func getShownCount() -> Int {
        let data = data.filter { $0.message?.status?.displayed != nil }
        var messages: Set<StaticReturnData> = .init()
        data.forEach { item in
            messages.insert(item)
        }
        return messages.count
    }

    private func refreshContent() {
        if let visibleCell = collectionView.visibleCells.first, let indexPath = collectionView.indexPath(for: visibleCell) {
            if indexPath.row < data.count - 1 {
                let newIndexPath = indexPath.row + 1
                guard newIndexPath < data.count else { return }
                let nextIndexPath: IndexPath = .init(row: newIndexPath, section: indexPath.section)
                collectionView.scrollToItem(at: nextIndexPath, at: .right, animated: true)
            } else {
                collectionView.scrollToItem(at: .init(row: 0, section: 0), at: .left, animated: false)
                if let firstMessage = data.first?.html {
                    calculator.loadHtml(placedholderId: "", html: firstMessage)
                    state = .startTimer
                }
            }
        }
    }

    private func listenToState() {
        $state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                guard let self else { return }
                guard !IntegrationManager.shared.isStopped else {
                    Exponea.logger.log(.error, message: "In-app content blocks fetch failed: SDK is stopping")
                    stopTimer()
                    return
                }
                switch state {
                case .restart:
                    self.savedTimer = nil
                    self.stopTimer()
                    self.startTimer()
                case .shouldReload:
                    self.refreshContent()
                case .stopTimer:
                    self.stopTimer()
                case .idle: break
                case .refresh:
                    defaultBehaviourCallback.onMessagesChanged(count: self.messages.count, messages: self.messages.map { $0.message! })
                    self.collectionView.reloadData()
                    self.scrollToPendingMessageOrCenter()
                case .startTimer:
                    self.startTimer()
                }
            }
            .store(in: &cancellables)
    }

    @MainActor
    private func redrawWithNewHeight(
        inputView: UIView,
        loadedInAppContentBlocksView: UIView,
        height: CGFloat
    ) {
        if !inputView.subviews.contains(loadedInAppContentBlocksView) {
            loadedInAppContentBlocksView.constraints.forEach { cons in
                self.removeConstraint(cons)
            }
            loadedInAppContentBlocksView.removeFromSuperview()
            inputView.addSubview(loadedInAppContentBlocksView)
            loadedInAppContentBlocksView.translatesAutoresizingMaskIntoConstraints = false
            loadedInAppContentBlocksView.topAnchor.constraint(equalTo: inputView.topAnchor).isActive = true
            loadedInAppContentBlocksView.leadingAnchor.constraint(equalTo: inputView.leadingAnchor).isActive = true
            loadedInAppContentBlocksView.trailingAnchor.constraint(equalTo: inputView.trailingAnchor).isActive = true
            loadedInAppContentBlocksView.bottomAnchor.constraint(equalTo: inputView.bottomAnchor).isActive = true
            self.height = loadedInAppContentBlocksView.heightAnchor.constraint(equalToConstant: height)
            self.height?.isActive = true
        } else {
            self.height?.constant = height
        }
        loadedInAppContentBlocksView.layoutIfNeeded()
        loadedInAppContentBlocksView.sizeToFit()
    }

    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension CarouselInAppContentBlockView: UICollectionViewDelegateFlowLayout {
    public func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let message = data[safeIndex: indexPath.row], let messageResponse = message.message, let id = message.message?.id else {
            currentMessage = nil
            return
        }
        currentMessage = message
        if !alreadyShowedMessages.contains(id) {
            alreadyShowedMessages.append(id)
            Exponea.shared.telemetryManager?.report(
                eventWithType: .contentBlockShown,
                properties: [
                    "type": (messageResponse.content == nil ? "personal" : "static"),
                    "messageId": id,
                    "placeholders": TelemetryUtility.toJson(messageResponse.placeholders)
                ]
            )
        }
        inAppContentBlocksManager.updateDisplayedState(for: id)
        if let index = messages.firstIndex(where: { $0.message?.id == messageResponse.id }) {
            defaultBehaviourCallback.onMessageShown(placeholderId: placeholder, contentBlock: messageResponse, index: index, count: messages.count)
        } else {
            Exponea.logger.log(.error, message: "Error while calling onMessageShown callback, index of message not found")
        }
        let maxLimitSeconds: Double = defaultRefreshInterval
        let tolerant: Double = 0.3
        let currentTimeStampWithLimit = lastScrollTimestamp + (maxLimitSeconds - tolerant)
        let current = Date().timeIntervalSince1970
        if current > currentTimeStampWithLimit {
            calculator.loadHtml(placedholderId: placeholder, html: message.html)
        } else {
            state = .stopTimer
            calculator.loadHtml(placedholderId: placeholder, html: message.html)
        }
    }

    public func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard data[safeIndex: indexPath.row] != nil else { return }
        ensureBackground { [weak self] in
            if let message = self?.data[safeIndex: indexPath.row] {
                self?.checkMessage(message: message)
            }
        }
        if state == .stopTimer {
            state = .startTimer
        } else {
            lastScrollTimestamp = Date().timeIntervalSince1970
        }
    }
}

// MARK: - DataSource
extension CarouselInAppContentBlockView: UICollectionViewDataSource {
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        data.count
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let message = data[safeIndex: indexPath.row] else { return collectionView.dequeueReusableCell(withReuseIdentifier: "UICollectionViewCell", for: indexPath) }
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! CarouselContentBlockViewCell
        cell.contentBlockCarouselCallback = defaultBehaviourCallback
        cell.actionClicked = { [weak self] in
            guard let message = self?.data[safeIndex: indexPath.row] else { return }
            let isMessageWithAlwayFrequency = message.message?.frequency == .always
            self?.checkMessage(message: message, shouldBeReloaded: !isMessageWithAlwayFrequency)
            if isMessageWithAlwayFrequency {
                self?.saveCurrentTimer()
            }
        }
        cell.closeClicked = { [weak self] in
            self?.state = .restart
            if let message = self?.data[safeIndex: indexPath.row] {
                self?.checkMessage(message: message, shouldBeReloaded: true)
            }
        }
        cell.touchCallback = { [weak self] in self?.saveCurrentTimer() }
        cell.releaseCallback = { [weak self] in self?.startTimer() }
        cell.loadHtml(
            html: message.html,
            assignedMessage: message.message,
            placeholder: placeholder
        )
        return cell
    }
}

#if DEBUG
// MARK: - Internal helpers for unit tests
//
// These exist solely so XCTest specs can exercise the
// `UICollectionViewDataSource.collectionView(_:cellForItemAt:)` path without
// going through the async `loadMessagesForCarousel` pipeline. They are NOT
// part of the public SDK surface, are compiled out of Release builds, and
// must not be called from host applications.
extension CarouselInAppContentBlockView {
    /// Test-only: synchronously seeds the carousel's internal data buffers so
    /// the data source can vend cells. Does NOT trigger any layout, refresh,
    /// or HTML loading — purely a state injection for unit tests.
    internal func _testOnly_seedData(_ entries: [StaticReturnData]) {
        self._data.changeValue { $0 = entries }
        self.messages = entries
    }

    /// Test-only: runs the final carousel data apply (filter, then render) directly, without
    /// waiting for `loadMessagesForCarousel`. Must be called on the main thread.
    internal func _testOnly_applyCarouselData() {
        applyCarouselData(isTriggered: true, phase: .full)
    }

    /// Test-only: drives `collectionView(_:cellForItemAt:)` on the view's own
    /// (private, lazy) `collectionView` so the cell is retained by the same
    /// stored property the production code path uses. This is what lets
    /// retain-cycle regression tests actually pin the
    /// `self -> collectionView -> cell -> closure -> self` cycle.
    /// Returns the dequeued cell (caller may discard it).
    @discardableResult
    internal func _testOnly_vendCellAtFirstIndex() -> UICollectionViewCell {
        return self.collectionView(
            self.collectionView,
            cellForItemAt: IndexPath(item: 0, section: 0)
        )
    }
}
#endif
