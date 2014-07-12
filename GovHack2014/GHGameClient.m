//
//  GHGameClient.m
//  GovHack2014
//
//  Created by Jon Manning on 12/07/2014.
//  Copyright (c) 2014 Secret Lab. All rights reserved.
//

#import "GHGameClient.h"

@implementation GHGameClient

- (void)processReceivedMessage:(NSDictionary *)dict {
    
    if ([dict[@"messageType"] isEqualToString:@"state"]) {
        
        self.state = [dict[@"state"] integerValue];
        
    }
    
    if ([dict[@"messageType"] isEqualToString:@"mission"]) {
        self.missionName = dict[@"missionName"];
    }
    
    if ([dict[@"messageType"] isEqualToString:@"points"]) {
        self.points = [dict[@"points"] integerValue];
    }
    
    if ([dict[@"messageType"] isEqualToString:@"time"]) {
        self.timeAvailable = [dict[@"timeAvailable"] floatValue];
        self.timeRemaining = [dict[@"timeRemaining"] floatValue];
    }
    
}

@end
