//
//  GHGameClient.h
//  GovHack2014
//
//  Created by Jon Manning on 12/07/2014.
//  Copyright (c) 2014 Secret Lab. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GHGame.h"


@interface GHGameClient : NSObject

- (void) processReceivedMessage:(NSDictionary*)dict;

@property (nonatomic, assign) GHGameState state;

@property (assign) NSTimeInterval timeAvailable;
@property (assign) NSTimeInterval timeRemaining;

@property (strong) NSString* missionName;

@property (assign) NSInteger points;

@property (strong) NSArray* people;

@end
