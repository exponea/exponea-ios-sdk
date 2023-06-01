//
//  AppInboxStyleParser.swift
//  ExponeaSDK
//
//  Created by Adam Mihalik on 19/05/2023.
//  Copyright © 2023 Exponea. All rights reserved.
//

import Foundation

public class AppInboxStyleParser {

    private let source: NSDictionary

    public init(
        _ configMap: NSDictionary
    ) {
        self.source = configMap
    }

    public func parse() throws -> AppInboxStyle {
        return AppInboxStyle(
            appInboxButton: try parseButtonStyle(self.source.getOptionalSafely(property: "appInboxButton")),
            detailView: try parseDetailViewStyle(self.source.getOptionalSafely(property: "detailView")),
            listView: try parseListScreenStyle(self.source.getOptionalSafely(property: "listView"))
        )
    }

    private func parseButtonStyle(_ source: NSDictionary?) throws -> ButtonStyle? {
        guard let source = source else {
            return nil
        }
        return ButtonStyle(
            textOverride: try source.getOptionalSafely(property: "textOverride"),
            textColor: try source.getOptionalSafely(property: "textColor"),
            backgroundColor: try source.getOptionalSafely(property: "backgroundColor"),
            showIcon: try source.getOptionalSafely(property: "showIcon"),
            textSize: try source.getOptionalSafely(property: "textSize"),
            enabled: try source.getOptionalSafely(property: "enabled"),
            borderRadius: try source.getOptionalSafely(property: "borderRadius"),
            textWeight: try source.getOptionalSafely(property: "textWeight")
        )
    }

    private func parseProgressStyle(_ source: NSDictionary?) throws -> ProgressBarStyle? {
        guard let source = source else {
            return nil
        }
        return ProgressBarStyle(
            visible: try source.getOptionalSafely(property: "visible"),
            progressColor: try source.getOptionalSafely(property: "progressColor"),
            backgroundColor: try source.getOptionalSafely(property: "backgroundColor")
        )
    }

    private func parseListViewStyle(_ source: NSDictionary?) throws -> AppInboxListViewStyle? {
        guard let source = source else {
            return nil
        }
        return AppInboxListViewStyle(
            backgroundColor: try source.getOptionalSafely(property: "backgroundColor"),
            item: try parseListItemStyle(source.getOptionalSafely(property: "item"))
        )
    }

    private func parseListItemStyle(_ source: NSDictionary?) throws -> AppInboxListItemStyle? {
        guard let source = source else {
            return nil
        }
        return AppInboxListItemStyle(
            backgroundColor: try source.getOptionalSafely(property: "backgroundColor"),
            readFlag: try parseImageViewStyle(source.getOptionalSafely(property: "readFlag")),
            receivedTime: try parseTextViewStyle(source.getOptionalSafely(property: "receivedTime")),
            title: try parseTextViewStyle(source.getOptionalSafely(property: "title")),
            content: try parseTextViewStyle(source.getOptionalSafely(property: "content")),
            image: try parseImageViewStyle(source.getOptionalSafely(property: "image"))
        )
    }

    private func parseImageViewStyle(_ source: NSDictionary?) throws -> ImageViewStyle? {
        guard let source = source else {
            return nil
        }
        return ImageViewStyle(
            visible: try source.getOptionalSafely(property: "visible"),
            backgroundColor: try source.getOptionalSafely(property: "backgroundColor")
        )
    }

    private func parseTextViewStyle(_ source: NSDictionary?) throws -> TextViewStyle? {
        guard let source = source else {
            return nil
        }
        return TextViewStyle(
            visible: try source.getOptionalSafely(property: "visible"),
            textColor: try source.getOptionalSafely(property: "textColor"),
            textSize: try source.getOptionalSafely(property: "textSize"),
            textWeight: try source.getOptionalSafely(property: "textWeight"),
            textOverride: try source.getOptionalSafely(property: "textOverride")
        )
    }

    private func parseDetailViewStyle(_ source: NSDictionary?) throws -> DetailViewStyle? {
        guard let source = source else {
            return nil
        }
        return DetailViewStyle(
            title: try parseTextViewStyle(source.getOptionalSafely(property: "title")),
            content: try parseTextViewStyle(source.getOptionalSafely(property: "content")),
            receivedTime: try parseTextViewStyle(source.getOptionalSafely(property: "receivedTime")),
            image: try parseImageViewStyle(source.getOptionalSafely(property: "readFlag")),
            button: try parseButtonStyle(source.getOptionalSafely(property: "button"))
        )
    }

    private func parseListScreenStyle(_ source: NSDictionary?) throws -> ListScreenStyle? {
        guard let source = source else {
            return nil
        }
        return ListScreenStyle(
            emptyTitle: try parseTextViewStyle(source.getOptionalSafely(property: "emptyTitle")),
            emptyMessage: try parseTextViewStyle(source.getOptionalSafely(property: "emptyMessage")),
            errorTitle: try parseTextViewStyle(source.getOptionalSafely(property: "errorTitle")),
            errorMessage: try parseTextViewStyle(source.getOptionalSafely(property: "errorMessage")),
            progress: try parseProgressStyle(source.getOptionalSafely(property: "progress")),
            list: try parseListViewStyle(source.getOptionalSafely(property: "list"))
        )
    }

}
