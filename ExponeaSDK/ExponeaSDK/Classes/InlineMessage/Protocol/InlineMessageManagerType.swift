//
//  InlineMessageManagerType.swift
//  ExponeaSDK
//
//  Created by Ankmara on 17.05.2023.
//  Copyright © 2023 Exponea. All rights reserved.
//

import UIKit
import WebKit
import Foundation

public protocol InlineMessageManagerType {
    var contentRuleList: WKContentRuleList? { get set }

    func prepareInlineView(placeholderId: String, indexPath: IndexPath) -> UIView
    func prefetchPlaceholdersWithIds(ids: [String])
    func loadInlinePlaceholders(completion: EmptyBlock?)
    func loadPersonalizedInlineMessage(for placeholderId: String, tag: Int, completion: EmptyBlock?)
    func getFilteredMessage(message: InlineMessageResponse) -> Bool
    func prefetchPlaceholdersWithIds(input: [InlineMessageResponse], ids: [String]) -> [InlineMessageResponse]
    func checkTTLForMessage()
    func anonymize()
    func initBlocker()
    func filterPriority(input: [InlineMessageResponse]) -> [Int: [InlineMessageResponse]]
    func getUsedInline(placeholder: String, indexPath: IndexPath) -> UsedInline?
    func prepareInlineStaticView(placeholderId: String) -> StaticReturnData
    func refreshStaticViewContent(staticQueueData: StaticQueueData)
}
