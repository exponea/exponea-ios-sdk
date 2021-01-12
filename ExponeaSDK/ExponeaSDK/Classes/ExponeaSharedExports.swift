//
//  ExponeaSharedExports.swift
//  ExponeaSDK
//
//  Created by Panaxeo on 12/01/2021.
//  Copyright © 2021 Exponea. All rights reserved.
//

import ExponeaSDKShared

/**
 We need to re-export some types from ExponeaSDKShared to general public
 */
public typealias Exponea = ExponeaSDKShared.Exponea
public typealias Constants = ExponeaSDKShared.Constants
public typealias Configuration = ExponeaSDKShared.Configuration
public typealias Logger = ExponeaSDKShared.Logger
public typealias LogLevel = ExponeaSDKShared.LogLevel
public typealias JSONValue = ExponeaSDKShared.JSONValue
public typealias JSONConvertible = ExponeaSDKShared.JSONConvertible
public typealias Authorization = ExponeaSDKShared.Authorization
public typealias ExponeaNotificationAction = ExponeaSDKShared.ExponeaNotificationAction
public typealias ExponeaNotificationActionType = ExponeaSDKShared.ExponeaNotificationActionType
public typealias Result = ExponeaSDKShared.Result
public typealias ExponeaProject = ExponeaSDKShared.ExponeaProject
public typealias ExponeaError = ExponeaSDKShared.ExponeaError
public typealias EventType = ExponeaSDKShared.EventType
public typealias TokenTrackFrequency = ExponeaSDKShared.TokenTrackFrequency
public typealias NotificationData = ExponeaSDKShared.NotificationData

/*
 Instead of including ExponeaSDKShared in every file and having issues with cocoapods, we can do it all here
 */

typealias DataType = ExponeaSDKShared.DataType
typealias TrackingRepository = ExponeaSDKShared.TrackingRepository
typealias EmptyResult = ExponeaSDKShared.EmptyResult
typealias TrackingObject = ExponeaSDKShared.TrackingObject
typealias CampaignData = ExponeaSDKShared.CampaignData
typealias RepositoryError = ExponeaSDKShared.RepositoryError
typealias ServerRepository = ExponeaSDKShared.ServerRepository
typealias EventTrackingObject = ExponeaSDKShared.EventTrackingObject
typealias CustomerTrackingObject = ExponeaSDKShared.CustomerTrackingObject
typealias RequestFactory = ExponeaSDKShared.RequestFactory
typealias RequestParametersType = ExponeaSDKShared.RequestParametersType
