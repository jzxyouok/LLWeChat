//
//  LLError.m
//  LLWeChat
//
//  Created by GYJZH on 8/16/16.
//  Copyright © 2016 GYJZH. All rights reserved.
//

#import "LLError.h"

@implementation LLError

+ (instancetype)errorWithEMError:(EMError *)error {
    LLError *_error = [[LLError alloc] initWithDescription:error.errorDescription code:(LLErrorCode)error.code];
    return _error;
}

- (instancetype)initWithDescription:(NSString *)aDescription code:(LLErrorCode)aCode {
    self = [super init];
    if (self) {
        self.errorDescription = aDescription;
        self.errorCode = aCode;
    }
    
    return self;
}

+ (instancetype)errorWithDescription:(NSString *)aDescription code:(LLErrorCode)aCode {
    LLError *error = [[LLError alloc] initWithDescription:aDescription code:aCode];
    return error;
}

@end
