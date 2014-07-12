//
//  GHMessage.m
//  GovHack2014
//
//  Created by Jon Manning on 12/07/2014.
//  Copyright (c) 2014 Secret Lab. All rights reserved.
//

#import "GHMessage.h"

@interface GHMessage ()

@end

@implementation GHMessage

- (id) initWithMessage:(GHNetworkingMessage)message data:(NSDictionary*)data {
    self = [super init];
    
    if (self) {
        _message = message;
        _data = [data mutableCopy];
        
        if (_data == nil)
            _data = [NSMutableDictionary dictionary];
    }
    
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    
    self = [self init];
    
    _message = [aDecoder decodeIntegerForKey:@"message"];
    _data = [[aDecoder decodeObjectForKey:@"data"] mutableCopy];
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeInteger:self.message forKey:@"message"];
    [aCoder encodeObject:self.data forKey:@"data"];
}

@end

