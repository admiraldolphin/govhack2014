//
//  GHGame.h
//  GovHack2014
//
//  Created by Jon Manning on 12/07/2014.
//  Copyright (c) 2014 Secret Lab. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum : NSUInteger {
    GHGameStateWaitingForMissions, // "get ready!"
    GHGameStatePerformingMissions, // main gameplay
    GHGameStateViewingGameReport,  // post-game report
    GHGameStateGameOver            // game ended
} GHGameState;

@interface GHGame : NSObject

@property (assign) GHGameState gameState;

@property (assign) NSTimeInterval waitingForMissionsDelay;

@property (assign) NSTimeInterval endOfRoundReportDelay;

@end
