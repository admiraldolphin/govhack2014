//
//  GHGameClient.h
//  GovHack2014
//
//  Created by Jon Manning on 12/07/2014.
//  Copyright (c) 2014 Secret Lab. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GHGame.h"

@protocol GHGameClientDelegate <NSObject>

- (void) missionSucceeded;
- (void) missionDidNotSucceed;

@end

@interface GHGameClient : NSObject

- (void) processReceivedMessage:(NSDictionary*)dict;

@property (weak) id <GHGameClientDelegate> delegate;

@property (nonatomic, assign) GHGameState state;

@property (assign) NSUInteger missionsSucceeded;
@property (assign) NSUInteger minionsUsed;
@property (assign) NSUInteger moneySpent;

@property (assign) NSTimeInterval timeAvailable;
@property (assign) NSTimeInterval timeRemaining;

@property (strong) NSString* missionName;

@property (assign) float progress;

@property (strong) NSArray* people;

@end
