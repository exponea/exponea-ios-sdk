//
//  mock_notification_request.m
//  ExponeaSDKTests
//
//  Created by Panaxeo on 10/03/2020.
//  Copyright © 2020 Exponea. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UserNotifications/UserNotifications.h>

UNNotificationRequest * mock_notification_request(NSDictionary * userInfo) {
    UNNotificationContent *content = [UNNotificationContent alloc];
    [content setValue:userInfo forKey:@"userInfo"];

    UNNotificationRequest *request = [UNNotificationRequest alloc];
    [request setValue:content forKeyPath:@"content"];
    [request setValue:[UNPushNotificationTrigger alloc] forKey:@"trigger"];
    return request;
}
