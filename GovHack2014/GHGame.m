//
//  GHGame.m
//  GovHack2014
//
//  Created by Jon Manning on 12/07/2014.
//  Copyright (c) 2014 Secret Lab. All rights reserved.
//

#import "GHGame.h"
#import "GHNetworking.h"

// agents are people who can complete missions; each player has multiple agents
@interface GHAgent : NSObject

// Display name of the agent
@property (strong) NSString* name;

// Array of strings
@property (strong) NSArray* functionTypes;

// Amount of money deducted when this agent is used
@property (assign) NSUInteger costToUse;

@end

// missions are tasks that must be completed by an agent
@interface GHMission : NSObject

// The name of the mission, selected
@property (strong) NSString* title;

// Array of strings; an agent with one of these valid types must be selected to
// complete the mission
@property (strong) NSArray* functionsRequired;

// Amount of time the mission must be completed in
@property (assign) float time;

// Amount of time remaining to complete the mission
@property (assign) float timeRemaining;

// number of points awarded on mission success (always positive)
@property (assign) NSInteger successPoints;

// number of points deducted on mission failure (always negative)
@property (assign) NSInteger failurePoints;

@end



@implementation GHMission

// replace this with the actual data source
+ (NSArray*) TEMPmissionNames {
    return @[@"Perform the action", @"Complete the task", @"Integrate the function"];
}

// create and prepare a new mission
+ (GHMission*) mission {
    GHMission* mission = [[GHMission alloc] init];
    
    mission.title = [[self TEMPmissionNames] objectAtIndex:arc4random_uniform([self TEMPmissionNames].count)];
    
    mission.time = arc4random_uniform(10) + 10;
    mission.timeRemaining = mission.time;
    
    return mission;
}

@end

@interface GHGame ()

// number of points currently
@property (nonatomic, assign) NSInteger points;

// number of points needed to win the round
@property (assign) NSInteger pointsSuccessThreshold;

// game will end if points reaches this point
@property (assign) NSInteger pointsFailureThreshold;

// amount of money
@property (assign) NSUInteger money;

@end

@implementation GHGame {
    // maps peerIDs to missions
    NSMutableDictionary* _missions;
}

- (id)init {
    self = [super init];
    
    if (self) {
        _missions = [NSMutableDictionary dictionary];
        
        self.points = 0;
        self.pointsFailureThreshold = 10;
        self.pointsSuccessThreshold = -10;
    }
    
    return self;
}

- (void) beginRound {
    self.gameState = GHGameStateWaitingForMissions;
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(self.waitingForMissionsDelay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        self.gameState = GHGameStatePerformingMissions;
        
        // create a mission for all peers
        
        for (MCPeerID* peer in [GHNetworking sharedNetworking].connectedPeers) {
            [self createMissionForPeer:peer];
        }
    });
    
}


- (void) peer:(MCPeerID*)peer usedAgent:(GHAgent*)agent {
    
    // can we afford this agent? cancel if not
    if (self.money < agent.costToUse) {
        return;
    }
    
    self.money -= agent.costToUse;
    // TODO: send updated money to peers
    
    
    // did activating this agent successfully complete a mission?
    NSArray* missions = [_missions.allValues copy];
    
    for (GHMission* mission in missions) {
        
        for (NSString* type in agent.functionTypes) {
            if ([mission.functionsRequired containsObject:type]) {
                [self missionCompleted:mission successfully:YES];
                break;
            }
        }
    }
    
}

// Called when a mission succeeds or fails
- (void) missionCompleted:(GHMission*)mission successfully:(BOOL)successfully {
    
    // Generate and send a new mission
    
    MCPeerID* peer = [self peerForMission:mission];
    
    if (successfully) {
        self.points += mission.successPoints;
    } else {
        // we use a +, but this value is always negative
        self.points += mission.failurePoints;
    }
    
    // make a new mission for this peer and send it out
    [self createMissionForPeer:peer];
}

// Update points, and end the round or game if appropriate
- (void)setPoints:(NSInteger)points {
    _points = points;
    
    if (points <= self.pointsFailureThreshold) {
        // TODO: fail game
    }
    
    if (points >= self.pointsSuccessThreshold) {
        // TODO: succeed round
    }
    
    // TODO: send updated points
}

- (void) gameOver {
    self.gameState = GHGameStateGameOver;
    
    // TODO: inform clients
}

- (void) timerUpdated:(NSTimeInterval)deltaTime {
    if (self.gameState != GHGameStatePerformingMissions) {
        // timer doesn't apply unless we're performing missions
        
        return;
    }
    
    // Update all missions; fail any mission that is now out of time
    
    NSArray* missions = [_missions allValues];
    
    for (GHMission* mission in missions) {
        mission.timeRemaining -= deltaTime;
        
        if (mission.timeRemaining <= 0.0) {
            [self missionCompleted:mission successfully:NO];
        }
        
        // Send update mission data to relevant peer
    }
    
    
}

- (void) roundSucceeded {
    // Indicate to clients that we're now viewing game report
    self.gameState = GHGameStateViewingGameReport;
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(self.endOfRoundReportDelay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self beginRound];
        
    });
    
    // TODO: inform clients
}

- (GHMission*) missionForPeer:(MCPeerID*)peer {
    return [_missions objectForKey:peer];
}

- (MCPeerID*) peerForMission:(GHMission*)mission {
    
    // return the peer that's been assigned this mission
    NSSet* peers = [_missions keysOfEntriesPassingTest:^BOOL(MCPeerID* key, GHMission* obj, BOOL *stop) {
        return obj == mission;
    }];
    
    return [peers anyObject];
}

- (GHMission*) createMissionForPeer:(MCPeerID*)peer {
    
    // make a new mission and send it out
    
    GHMission* mission = [GHMission mission];
    
    [_missions setObject:mission forKey:peer];
    
    // TODO: send mission to this peer
    
    return mission;
}

@end
