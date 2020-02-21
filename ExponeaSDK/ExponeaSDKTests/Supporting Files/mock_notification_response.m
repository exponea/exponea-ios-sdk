//
//  mock_notification_response.m
//  ExponeaSDKTests
//
//  Created by Panaxeo on 08/11/2019.
//  Copyright © 2019 Exponea. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UserNotifications/UserNotifications.h>

UNNotificationResponse * mock_notification_response(NSDictionary * userInfo) {
    UNNotificationContent *content = [UNNotificationContent alloc];
    [content setValue:userInfo forKey:@"userInfo"];

    UNNotificationRequest *request = [UNNotificationRequest alloc];
    [request setValue:content forKeyPath:@"content"];
    [request setValue:[UNPushNotificationTrigger alloc] forKey:@"trigger"];

    UNNotification *notification = [UNNotification alloc];
    [notification setValue:request forKeyPath:@"request"];

    UNNotificationResponse *notifResponse = [UNNotificationResponse alloc];
    [notifResponse setValue:@"com.apple.UNNotificationDefaultActionIdentifier" forKeyPath:@"actionIdentifier"];
    [notifResponse setValue:notification forKeyPath:@"notification"];

    return notifResponse;
}
