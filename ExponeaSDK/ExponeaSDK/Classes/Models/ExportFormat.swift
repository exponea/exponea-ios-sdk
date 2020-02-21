//
//  ExportFormat.swift
//  ExponeaSDK
//
//  Created by Dominik Hadl on 29/05/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation

/// The format that is used for data export.
///
/// - csv: Export will be formatted as comma separated values.
/// - tableJSON: Same as CSV, but presented in JSON form.
/// - nativeJSON: Native JSON format, almost the same as table_json, but the column names are not collapsed to strings.
enum ExportFormat: String {
    case csv = "csv"
    case tableJSON = "table_json"
    case nativeJSON = "native_json"
}
