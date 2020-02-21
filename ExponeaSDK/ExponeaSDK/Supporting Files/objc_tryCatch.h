//
//  objcTryCatch.h
//  ExponeaSDK
//
//  Created by Panaxeo on 04/10/2019.
//  Copyright © 2019 Exponea. All rights reserved.
//

#import <Foundation/Foundation.h>

/// This method leaks the failing object after catching exception. USE WITH CAUTION!
NSException * _Nullable objc_tryCatch(void (NS_NOESCAPE ^ _Nonnull block)(void));
