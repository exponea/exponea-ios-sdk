//
//  mock_notification_response.h
//  ExponeaSDK
//
//  Created by Panaxeo on 08/11/2019.
//  Copyright © 2019 Exponea. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UserNotifications/UserNotifications.h>

// It's not possible to create mock UUNotificationResponse in swift, we have to do it in objc
UNNotificationResponse * mock_notification_response(NSDictionary * userInfo);
