//
//  GHGameClient.m
//  GovHack2014
//
//  Created by Jon Manning on 12/07/2014.
//  Copyright (c) 2014 Secret Lab. All rights reserved.
//

#import "GHGameClient.h"

@implementation GHGameClient

- (id)init {
    self = [super init];
    if (self) {
        self.state = GHGameStateWaitingForMissions;
    }
    
    return self;
}

- (void)processReceivedMessage:(NSDictionary *)dict {
    
    if ([dict[@"messageType"] isEqualToString:@"state"]) {
        
        self.state = [dict[@"state"] integerValue];
        
    }
    
    if ([dict[@"messageType"] isEqualToString:@"mission"]) {
        self.missionName = dict[@"missionName"];
    }
    
    if ([dict[@"messageType"] isEqualToString:@"progress"]) {
        float progress = [dict[@"progress"] floatValue];
        if (isnan(progress)) {
            progress = 0.0;
        }
        self.progress = progress;
        
    }
    
    if ([dict[@"messageType"] isEqualToString:@"time"]) {
        self.timeAvailable = [dict[@"timeAvailable"] floatValue];
        self.timeRemaining = [dict[@"timeRemaining"] floatValue];
    }
    
    if ([dict[@"messageType"] isEqualToString:@"minions"]) {
        self.people = [dict[@"minions"] copy];
    }
    
    if ([dict[@"messageType"] isEqualToString:@"endGameReport"]) {
        
        self.missionsSucceeded = [dict[@"missionsSucceeded"] unsignedIntegerValue];
        self.minionsUsed = [dict[@"minionsUsed"] unsignedIntegerValue];
        self.moneySpent = [dict[@"moneySpent"] unsignedIntegerValue];

    }
    
    if ([dict[@"messageType"] isEqualToString:@"failedMission"]) {
        [self.delegate missionDidNotSucceed];
    }
    
    if ([dict[@"messageType"] isEqualToString:@"completedMission"]) {
        [self.delegate missionSucceeded];
    }
    
    
    
    
}

@end
