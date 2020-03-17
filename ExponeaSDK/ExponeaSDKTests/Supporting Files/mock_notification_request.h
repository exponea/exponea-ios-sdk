//
//  mock_notification_request.h
//  ExponeaSDK
//
//  Created by Panaxeo on 10/03/2020.
//  Copyright © 2020 Exponea. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UserNotifications/UserNotifications.h>

// It's not possible to create mock UUNotificationRequest in swift, we have to do it in objc
UNNotificationRequest * mock_notification_request(NSDictionary * userInfo);
