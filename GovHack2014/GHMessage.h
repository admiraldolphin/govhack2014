//
//  GHMessage.h
//  GovHack2014
//
//  Created by Jon Manning on 12/07/2014.
//  Copyright (c) 2014 Secret Lab. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum : NSInteger {
    GHNetworkingMessageShutdown,
    GHNetworkingMessageData,
    GHNetworkingMessageGameBeginning,
} GHNetworkingMessage;

@interface GHMessage : NSObject <NSCoding>

- (id) initWithMessage:(GHNetworkingMessage)message data:(NSDictionary*)data;

@property (readonly) GHNetworkingMessage message;
@property (readonly) NSMutableDictionary* data;

@end
