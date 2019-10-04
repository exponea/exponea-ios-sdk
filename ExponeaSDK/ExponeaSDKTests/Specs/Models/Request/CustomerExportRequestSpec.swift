//
//  CustomerExportRequestSpec.swift
//  ExponeaSDKTests
//
//  Created by Ricardo Tokashiki on 31/07/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation
import Quick
import Nimble

@testable import ExponeaSDK

class CustomerExportRequestSpec: QuickSpec {
    override func spec() {
        describe("A customer export request") {
            context("Defining a list with customer requests") {

                let exportFormat = ExportFormat.csv

                let custRequest = CustomerExportRequest(attributes: nil,
                                                        filter: nil,
                                                        executionTime: nil,
                                                        timezone: nil,
                                                        responseFormat: exportFormat)


                it("Should have export format csv") {
                    expect(custRequest.responseFormat) == ExportFormat.csv
                }
            }
        }
    }
}
