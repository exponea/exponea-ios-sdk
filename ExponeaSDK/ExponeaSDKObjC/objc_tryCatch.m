//
//  objcTryCatch.m
//  ExponeaSDK
//
//  Created by Panaxeo on 04/10/2019.
//  Copyright © 2019 Exponea. All rights reserved.
//

#import "objc_tryCatch.h"

NSException * _Nullable objc_tryCatch(void (NS_NOESCAPE ^ _Nonnull block)(void)) {
    @try {
        block();
        return nil;
    } @catch (NSException *exception) {
        return exception;
    }
}
