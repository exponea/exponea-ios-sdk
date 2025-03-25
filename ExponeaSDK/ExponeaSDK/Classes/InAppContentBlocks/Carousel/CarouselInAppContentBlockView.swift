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

open class CarouselInAppContentBlockView: UIView {

    var isFirstCellLoaded = false
    private var height: NSLayoutConstraint?

    func createCompositionalLayout() -> UICollectionViewLayout {
        UICollectionViewCompositionalLayout { _, _ in
            self.createHorizontalScrollLayoutSection()
        }
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
    lazy var calculator: WKWebViewHeightCalculator = .init()
    var lastScrollTimestamp: TimeInterval = Date().timeIntervalSince1970
    private var timer: AnyCancellable?
    private lazy var inAppContentBlocksManager = InAppContentBlocksManager.manager
    private let maxMessagesCount: Int
    public var onMessageShown: TypeBlock<CarouselOnShowMessageData>?
    public var onMessageChanged: TypeBlock<CarouselOnChangeData>?
    private var customHeight: CGFloat?
    private var currentMessage: StaticReturnData?
    private var alreadyShowedMessages: [String] = []
    private let defaultBehaviourCallback: DefaultContentBlockCarouselCallback!
    private var behaviourCallback: InAppContentBlockCallbackType = DefaultInAppContentBlockCallback()
    private var shouSkipCollectionReload = false
    private var didSet = false

    @Atomic private var data: [StaticReturnData] = [] {
        didSet {
            if data.count > 1 && !didSet {
                didSet = true
                _data.changeValue(with: { $0.insert(data.last!, at: 0) })
                _data.changeValue(with: { $0.append(data[1]) })
            }
            guard !shouSkipCollectionReload else { return }
            onMain {
                self.collectionView.reloadData()
                self.collectionView.scrollToItem(at: IndexPath(item: self.data.count / 2, section: 0), at: .centeredHorizontally, animated: false)
            }
        }
    }
    private var savedTimer: TimeInterval?
    private let placeholder: String

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
            .sink { _ in
                self.startTimer()
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)
            .sink { _ in
                self.saveCurrentTimer()
            }
            .store(in: &cancellables)

        redrawWithNewHeight(inputView: self, loadedInAppContentBlocksView: collectionView, height: 1)

        calculator.heightUpdate = { [weak self] height in
            guard let self else { return }
            let height = self.customHeight ?? height.height
            self.redrawWithNewHeight(inputView: self, loadedInAppContentBlocksView: collectionView, height: height)
            defaultBehaviourCallback.onHeightUpdate(placeholderId: placeholder, height: height)
        }
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
        alreadyShowedMessages.removeAll()
        savedTimer = nil
        state = .stopTimer
        inAppContentBlocksManager.loadMessagesForCarousel(placeholder: placeholder) { [weak self] in
            guard let self else { return }
            self.inAppContentBlocksManager
                .inAppContentBlockMessages
                .filter { $0.placeholders.contains(self.placeholder) }
                .filter { $0.personalizedMessage?.isCorruptedImage == true }
                .forEach { message in
                    self.defaultBehaviourCallback.onError(
                        placeholderId: message.id,
                        contentBlock: message,
                        errorMessage: "Corrupted image for \(message.id)"
                    )
                }
            self.filterContentBlocks(placeholder: self.placeholder) { data in
                guard !data.isEmpty else {
                    self.defaultBehaviourCallback.onNoMessageFound(placeholderId: self.placeholder)
                    return
                }
                let toReturn = data
                    .compactMap { response in
                        self.inAppContentBlocksManager.prepareCarouselStaticData(messages: response)
                    }
                let sortedMessages = self.sortContentBlocks(data: toReturn)
                let input = self.maxMessagesCount > 0 ? Array(sortedMessages.prefix(self.maxMessagesCount)) : sortedMessages
                self._data.changeValue(with: { $0 = self.makeDuplicate(input: input) })
                self.state = .refresh
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.startCarouseling()
                }
            } expiredCompletion: { [weak self] in
                if !isTriggered {
                    self?.reload(isTriggered: true)
                }
            }
        }
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
                            self.shouSkipCollectionReload = true
                            self._data.changeValue(with: { $0[index] = newData })
                            self.shouSkipCollectionReload = false
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
        NotificationCenter.default.removeObserver(self, name: UIApplication.willEnterForegroundNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIApplication.didEnterBackgroundNotification, object: nil)
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
        data.filter { $0.message?.status?.displayed != nil }.count
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
                    self.onMessageChanged?(.init(count: self.data.count, messages: self.data))
                    self.collectionView.reloadData()
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
        guard let message = data[safeIndex: indexPath.row], let id = message.message?.id else {
            currentMessage = nil
            return
        }
        currentMessage = message
        if !alreadyShowedMessages.contains(id), let messageResponse = message.message {
            alreadyShowedMessages.append(id)
            defaultBehaviourCallback.onMessageShown(placeholderId: placeholder, contentBlock: messageResponse)
            Exponea.shared.telemetryManager?.report(
                eventWithType: .showInAppMessage,
                properties: ["messageType": InAppContentBlockType.carouselContentBlock.type]
            )
        }
        inAppContentBlocksManager.updateDisplayedState(for: id)
        onMessageShown?(.init(placeholderId: placeholder, contentBlock: message, index: indexPath.row, count: data.count))
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
        cell.touchCallback = saveCurrentTimer
        cell.releaseCallback = startTimer
        cell.loadHtml(
            html: message.html,
            assignedMessage: message.message,
            placeholder: placeholder
        )
        return cell
    }
}
