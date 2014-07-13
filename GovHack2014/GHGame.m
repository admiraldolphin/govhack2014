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

// people can complete missions; each player has multiple people
@interface GHMinion : NSObject

// Internal ID of the person; clients send this ID to indicate that it's done
@property (strong) NSString* identifier;

// Display name of the person, like "Bob Bobertson"
@property (strong) NSString* name;

// Array of strings, like "Military", "Finance"
@property (strong) NSArray* functionTypes;

// Amount of money used when this person is used
@property (assign) NSUInteger costToUse;

// The owner of this person
@property (weak) MCPeerID* owner;

// The displayed description (like, 'minister of finance')
@property (strong) NSString* description;

// A dictionary indicating which components get used to build the picture
@property (strong) NSString* appearance;

@end

static NSArray* _minionData = nil;

@implementation GHMinion

- (id)init {
    self = [super init];
    
    if (self) {
        self.appearance = [NSString stringWithFormat:@"%@%i%i%i%i%i%i%i%i",
                                arc4random_uniform(2) == 0 ? @"m" : @"f",
                                arc4random_uniform(6)+1,
                                arc4random_uniform(6)+1,
                                arc4random_uniform(6)+1,
                                arc4random_uniform(6)+1,
                                arc4random_uniform(6)+1,
                                arc4random_uniform(6)+1,
                                arc4random_uniform(6)+1,
                                arc4random_uniform(2)+1
                                ];
        
    }
    
    return self;
}

+ (NSArray*) minionData {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        NSURL* url = [[NSBundle mainBundle] URLForResource:@"minions" withExtension:@"json"];
        NSData* data = [NSData dataWithContentsOfURL:url];
        
        NSError* error = nil;
        _minionData = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
        
        if (_minionData == nil) {
            NSLog(@"Error loading minions! %@", error);
        }
        
    });
    
    return _minionData;
}

+ (GHMinion*) minion {
    // Pick a random minion
    
    NSArray* allMinions = [GHMinion minionData];
    
    
    GHMinion* minion = [[GHMinion alloc] init];
    
    do {
        int index = arc4random_uniform(allMinions.count);
        
        NSDictionary* minionData = allMinions[index];
        
        minion.name = minionData[@"description"];
        minion.description = minion.name;
        minion.functionTypes = [minionData[@"functionTypes"] copy];
        minion.costToUse = [minionData[@"cost"] integerValue];
    } while (minion.description == nil);
    
    return minion;
    
}

@end

#pragma mark -

// missions are tasks that must be completed by a minion
@interface GHMission : NSObject

// The name of the mission, selected
@property (strong) NSString* title;

// Array of strings; a person with one of these valid types must be selected to
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


NSArray* _missionData;

@implementation GHMission

+ (NSArray*) missionData {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        NSURL* url = [[NSBundle mainBundle] URLForResource:@"missions" withExtension:@"json"];
        NSData* data = [NSData dataWithContentsOfURL:url];
        
        NSError* error = nil;
        _missionData = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
        
        if (_missionData == nil) {
            NSLog(@"Error loading missions! %@", error);
        }
        
    });
    
    return _missionData;
}

// replace this with the actual data source
+ (NSArray*) TEMPmissionNames {
    return @[@"Perform the action", @"Complete the task", @"Integrate the function"];
}

// create and prepare a new mission
+ (GHMission*) missionForMinions:(NSArray*)minions difficultyScale:(float)scale {
    
    if (minions.count == 0) {
        NSLog(@"Tried to create a mission but had no minions that could complete it!");
        return nil;
    }
    
    GHMission* mission = [[GHMission alloc] init];
    
    // Randomly pick through the missions list and find one that has requirements that match at least one function owned by at least one of the minions
    
    NSArray* missionData = [GHMission missionData];
    
    NSDictionary* selectedMission = nil;
    
    BOOL hasSuitableMinion = NO;
    do {
        
        int i  = arc4random_uniform(missionData.count);
        
        selectedMission = missionData[i];
        
        
        for (GHMinion* minion in minions) {
            for (NSString* function in minion.functionTypes) {
                if ([selectedMission[@"validFunctions"] containsObject:function]) {
                    hasSuitableMinion = YES;
                    break;
                }
            }
            if (hasSuitableMinion)
                break;
        }
        
        
    } while (hasSuitableMinion == NO);
    
    mission.title = selectedMission[@"title"];
    mission.functionsRequired = [selectedMission[@"validFunctions"] copy];
    mission.time = arc4random_uniform(15) + 5;
    mission.timeRemaining = mission.time;
    mission.failurePoints = -3;
    mission.successPoints = +3;
    
    return mission;
}

@end

#pragma mark - 

@interface GHGame ()

// number of points currently
@property (nonatomic, assign) NSInteger points;

// number of points needed to win the round
@property (assign) NSInteger pointsSuccessThreshold;

// game will end if points reaches this point
@property (assign) NSInteger pointsFailureThreshold;

// amount of money
@property (assign) NSUInteger money;

@property (assign) NSUInteger missionsSucceeded;

@property (assign) NSUInteger minionsUsed;

@end

@implementation GHGame {
    // maps peerIDs to missions
    NSMutableDictionary* _missions;
    
    NSMutableArray* _minions;
    
    NSTimer* _timer;
}

- (id) initWithLocalClient:(GHGameClient*)localClient {
    self = [super init];
    
    if (self) {
        
        _localClient = localClient;
        
        _missions = [NSMutableDictionary dictionary];
        _minions = [NSMutableArray array];
        
        self.pointsFailureThreshold = -10;
        self.pointsSuccessThreshold = 10;
        self.points = 0;
        self.peoplePerPeer = 4;
        
        self.endOfRoundReportDelay = 3.0;
        self.waitingForMissionsDelay = 3.0;
        
        [self beginRound];
        
        _timer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(timerUpdated:) userInfo:nil repeats:YES];
        
    }
    
    return self;
}

- (void) beginRound {
    
    self.points = 0;
    
    self.gameState = GHGameStateWaitingForMissions;
    
    // Delete all agents
    [_minions removeAllObjects];
    
    // create a mission for all peers
    
    for (MCPeerID* peer in [GHNetworking sharedNetworking].connectedPeers) {
        [self setupMinionsForPeer:peer];
    }
    [self setupMinionsForPeer:[GHNetworking sharedNetworking].peerID];

    for (MCPeerID* peer in [GHNetworking sharedNetworking].connectedPeers) {
        [self createMissionForPeer:peer];
    }
    
    [self createMissionForPeer:[GHNetworking sharedNetworking].peerID];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(self.waitingForMissionsDelay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        self.gameState = GHGameStatePerformingMissions;
        
    });
    
}

- (GHMinion*) personWithIdentifier:(NSString*)identifier {
    
    NSUInteger i = [_minions indexOfObjectPassingTest:^BOOL(GHMinion* obj, NSUInteger idx, BOOL *stop) {
        return [obj.identifier isEqualToString:identifier];
    }];
    
    if (i == NSNotFound)
        return nil;
    
    return _minions[i];
    
}

- (void) setupMinionsForPeer:(MCPeerID*)peerID {
    
    NSMutableArray* newPeople = [NSMutableArray array];
    
    for (int i = 0; i < self.peoplePerPeer; i++) {
        GHMinion* person = [GHMinion minion];
        
        do {
            person.identifier = [NSString stringWithFormat:@"%06i", arc4random_uniform(1000000)];
        } while ([self personWithIdentifier:person.identifier] != NULL);
        
        person.owner = peerID;
        
        [_minions addObject:person];
        
        NSDictionary* descriptionDict = @{@"name": person.name,
                                          @"description": person.description,
                                          @"identifier": person.identifier,
                                          @"appearance": person.appearance};
        
        [newPeople addObject:descriptionDict];
        
    }
    
    [self sendMessageNamed:@"minions" data:@{@"minions":newPeople} toPeer:peerID mode:MCSessionSendDataReliable];
    
}

- (void) peerUsedMinionWithIdentifier:(NSString *)identifier {
    
    GHMinion* agent = [self personWithIdentifier:identifier];
    
    self.money += agent.costToUse;
    
    // did activating this agent successfully complete a mission?
    NSArray* missions = [_missions.allValues copy];
    
    for (GHMission* mission in missions) {
        
        for (NSString* type in agent.functionTypes) {
            if ([mission.functionsRequired containsObject:type]) {
                [self missionCompleted:mission successfully:YES];
                return;
            }
        }
    }
    
    // Tell the peer that they did a bad thing
    [self sendMessageNamed:@"failedMission" data:@{} toPeer:agent.owner mode:MCSessionSendDataUnreliable];
    
    
}

// Called when a mission succeeds or fails
- (void) missionCompleted:(GHMission*)mission successfully:(BOOL)successfully {
    
    // Generate and send a new mission
    
    MCPeerID* peer = [self peerForMission:mission];
    
    if (successfully) {
        
        // Tell the peer that they did a good thing
        [self sendMessageNamed:@"completedMission" data:@{} toPeer:peer mode:MCSessionSendDataUnreliable];
        
        self.points += mission.successPoints;
        self.missionsSucceeded++;
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
    
    if (self.gameState == GHGameStatePerformingMissions) {
        if (points <= self.pointsFailureThreshold) {
            [self gameOver];
        }
        
        if (points >= self.pointsSuccessThreshold) {
            [self roundSucceeded];
        }
    }
    
    float scaledPoints = self.points + (abs(self.pointsFailureThreshold));
    float scaledMax = abs(self.pointsFailureThreshold) + abs(self.pointsSuccessThreshold);
    
    float progress = scaledPoints / scaledMax;
    
    
    [self sendMessageNamed:@"progress" data:@{@"progress":@(progress)} mode:MCSessionSendDataUnreliable];
}

#pragma mark - Round management

- (void) roundSucceeded {
    
    // Send a game report
    
    NSDictionary* dict = @{@"missionsSucceeded": @(self.missionsSucceeded),
                           @"minionsUsed": @(self.minionsUsed),
                           @"moneySpent": @(self.money)};
    
    [self sendMessageNamed:@"endGameReport" data:dict mode:MCSessionSendDataReliable];
    
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
    
    NSArray* filteredMinions = nil;
    
    
    
    
    if ([GHNetworking sharedNetworking].connectedPeers.count == 0) {
        filteredMinions = _minions;
    } else {
        // Get the list of minions that are NOT owned by this peer
        filteredMinions = [_minions filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(GHMinion* evaluatedObject, NSDictionary *bindings) {
            
            return evaluatedObject.owner != peer;
            
        }]];
        
    }
    
    GHMission* mission = [GHMission missionForMinions:filteredMinions difficultyScale:1.0];
    
    if (mission == nil)
        return nil;
    
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
    
    if (peer == [GHNetworking sharedNetworking].peerID) {
        [self.localClient processReceivedMessage:dataToSend];
    } else {
        [[GHNetworking sharedNetworking] sendMessage:GHNetworkingMessageData data:dataToSend toPeer:peer deliveryMode:mode];
    }
    
}

- (void) sendMessageNamed:(NSString*)messageName data:(NSDictionary*)data mode:(MCSessionSendDataMode)mode {
    
    NSMutableDictionary * dataToSend = [self prepareMessageWithName:messageName data:data];
    
    [[GHNetworking sharedNetworking] sendMessage:GHNetworkingMessageData data:dataToSend];
    
    [self.localClient processReceivedMessage:dataToSend];
    
}


- (void)setGameState:(GHGameState)gameState {
    _gameState = gameState;
    
    [self sendMessageNamed:@"state" data:@{@"state":@(_gameState)} mode:MCSessionSendDataReliable];
    
}

@end
