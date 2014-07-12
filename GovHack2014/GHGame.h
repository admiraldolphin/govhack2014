//
//  GHGame.h
//  GovHack2014
//
//  Created by Jon Manning on 12/07/2014.
//  Copyright (c) 2014 Secret Lab. All rights reserved.
//

#import <Foundation/Foundation.h>
@class GHGameClient;

typedef enum : NSUInteger {
    GHGameStateWaitingForMissions, // "get ready!"
    GHGameStatePerformingMissions, // main gameplay
    GHGameStateViewingGameReport,  // post-game report
    GHGameStateGameOver            // game ended
} GHGameState;

@interface GHGame : NSObject

@property (nonatomic, assign) GHGameState gameState;

@property (assign) NSUInteger peoplePerPeer;
@property (assign) NSTimeInterval waitingForMissionsDelay;
@property (assign) NSTimeInterval endOfRoundReportDelay;

@property (weak) GHGameClient* localClient;

@end
