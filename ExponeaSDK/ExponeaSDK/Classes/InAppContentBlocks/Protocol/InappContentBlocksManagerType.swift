//
//  InAppContentBlocksManagerType.swift
//  ExponeaSDK
//
//  Created by Ankmara on 17.05.2023.
//  Copyright © 2023 Exponea. All rights reserved.
//

import UIKit
import WebKit
import Foundation

public protocol InAppContentBlocksManagerType {
    var contentRuleList: WKContentRuleList? { get set }
    var refreshCallback: TypeBlock<IndexPath>? { get set }

    func prepareInAppContentBlockView(placeholderId: String, indexPath: IndexPath) -> UIView
    func prefetchPlaceholdersWithIds(ids: [String])
    func getUsedInAppContentBlocks(placeholder: String, indexPath: IndexPath) -> UsedInAppContentBlocks?
    func anonymize()
    func initBlocker()
    func loadInAppContentBlocksPlaceholders(completion: EmptyBlock?)
    // Test purposes
    func getFilteredMessage(message: InAppContentBlockResponse) -> Bool
    func prefetchPlaceholdersWithIds(input: [InAppContentBlockResponse], ids: [String]) -> [InAppContentBlockResponse]
    func filterPriority(input: [InAppContentBlockResponse]) -> [Int: [InAppContentBlockResponse]]
    func refreshStaticViewContent(staticQueueData: StaticQueueData)
}
