//
//  GHGame.m
//  GovHack2014
//
//  Created by Jon Manning on 12/07/2014.
//  Copyright (c) 2014 Secret Lab. All rights reserved.
//

#import "GHGame.h"
#import "GHNetworking.h"
#import "GHGameClient.h"

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
    
    mission.time = arc4random_uniform(10) + 1;
    mission.timeRemaining = mission.time;
    mission.failurePoints = -3;
    mission.successPoints = +3;
    
    
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
    
    NSTimer* _timer;
}

- (id)init {
    self = [super init];
    
    if (self) {
        _missions = [NSMutableDictionary dictionary];
        
        self.points = 0;
        self.pointsFailureThreshold = 10;
        self.pointsSuccessThreshold = -10;
        
        [self beginRound];
        
        _timer = [NSTimer scheduledTimerWithTimeInterval:0.05 target:self selector:@selector(timerUpdated:) userInfo:nil repeats:YES];
        
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
        
        [self createMissionForPeer:[GHNetworking sharedNetworking].localPeer];
    });
    
}


- (void) peer:(MCPeerID*)peer usedAgent:(GHAgent*)agent {
    
    self.money += agent.costToUse;
    
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
        [self gameOver];
    }
    
    if (points >= self.pointsSuccessThreshold) {
        [self roundSucceeded];
    }
    
    [self sendMessageNamed:@"points" data:@{@"points":@(self.points)}];
}

#pragma mark - Round management

- (void) roundSucceeded {
    // Indicate to clients that we're now viewing game report
    self.gameState = GHGameStateViewingGameReport;
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(self.endOfRoundReportDelay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self beginRound];
        
    });
}

- (void) gameOver {
    self.gameState = GHGameStateGameOver;
    
}

- (void) timerUpdated:(NSTimer*)timer {
    
    float deltaTime = timer.timeInterval;
    
    if (self.gameState != GHGameStatePerformingMissions) {
        // timer doesn't apply unless we're performing missions
        
        return;
    }
    
    // Update all missions; fail any mission that is now out of time
    
    NSArray* missions = [_missions allValues];
    
    for (GHMission* mission in missions) {
        mission.timeRemaining -= deltaTime;
        
        NSDictionary* data = @{@"timeRemaining":@(mission.timeRemaining), @"timeAvailable":@(mission.time)};
        
        [self sendMessageNamed:@"time" data:data toPeer:[self peerForMission:mission] mode:MCSessionSendDataUnreliable];
        
        if (mission.timeRemaining <= 0.0) {
            [self missionCompleted:mission successfully:NO];
        }
        
    }
    
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
    
    [self sendMessageNamed:@"mission" data:@{@"missionName": mission.title} toPeer:peer mode:MCSessionSendDataReliable];
    
    return mission;
}

- (NSMutableDictionary *)prepareMessageWithName:(NSString *)messageName data:(NSDictionary *)data {
    // Alert all peers
    NSDictionary* messageNameDict = @{@"messageType": messageName};
    
    NSMutableDictionary* dataToSend = [data mutableCopy];
    [dataToSend addEntriesFromDictionary:messageNameDict];
    return dataToSend;
}

- (void) sendMessageNamed:(NSString*)messageName data:(NSDictionary*)data toPeer:(MCPeerID*)peer mode:(MCSessionSendDataMode)mode {
    
    NSMutableDictionary * dataToSend = [self prepareMessageWithName:messageName data:data];
    
    if (peer == [GHNetworking sharedNetworking].localPeer) {
        [self.localClient processReceivedMessage:dataToSend];
    } else {
        [[GHNetworking sharedNetworking] sendMessage:GHNetworkingMessageData data:dataToSend toPeer:peer deliveryMode:mode];
    }
    
}

- (void) sendMessageNamed:(NSString*)messageName data:(NSDictionary*)data {
    
    NSMutableDictionary * dataToSend = [self prepareMessageWithName:messageName data:data];
    
    [[GHNetworking sharedNetworking] sendMessage:GHNetworkingMessageData data:dataToSend];
    
    [self.localClient processReceivedMessage:dataToSend];
    
}


- (void)setGameState:(GHGameState)gameState {
    _gameState = gameState;
    
    [self sendMessageNamed:@"state" data:@{@"state":@(_gameState)}];
    
}

@end
