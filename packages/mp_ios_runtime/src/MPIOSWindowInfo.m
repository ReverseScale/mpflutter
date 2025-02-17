//
//  MPIOSWindowInfo.m
//  mp_ios_runtime
//
//  Created by ydt on 12.10.21.
//  Copyright © 2021 MPFlutter. All rights reserved.
//

#import "MPIOSWindowInfo.h"
#import "MPIOSEngine.h"
#import "MPIOSEngine+Private.h"

@implementation MPIOSWindowInfo

- (void)updateWindowInfo {
    [self.engine sendMessage:@{
        @"type": @"window_info",
        @"message": @{
                @"window": @{
                        @"width": @([UIScreen mainScreen].bounds.size.width),
                        @"height": @([UIScreen mainScreen].bounds.size.height),
                        @"padding": @{
                                @"top": @(0),
                                @"bottom": @(0),
                        },
                },
                @"devicePixelRatio": @([UIScreen mainScreen].scale),
        },
    }];
}

@end
