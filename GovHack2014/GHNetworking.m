//
//  GHNetworking.m
//  GovHack2014
//
//  Created by Jon Manning on 11/07/2014.
//  Copyright (c) 2014 Secret Lab. All rights reserved.
//

#import "GHNetworking.h"
#import "GHMessage.h"

#define SERVICE_TYPE @"govhack14"


typedef enum : NSUInteger {
    GHNetworkingPeerTypeUndefined,
    GHNetworkingPeerTypeClient,
    GHNetworkingPeerTypeHost,
} GHNetworkingPeerType;

// Notifications
NSString* GHNetworkingDidChangeStateNotification = @"GHNetworkingDidChangeStateNotification";


static GHNetworking* _sharedInstance;

@interface GHNetworking () <MCNearbyServiceAdvertiserDelegate, MCNearbyServiceBrowserDelegate, MCSessionDelegate> {
    NSMutableArray* _nearbyPeers;
}

@property MCSession* session;


@property (nonatomic, strong) MCNearbyServiceAdvertiser* advertiser;
@property (nonatomic, strong) MCNearbyServiceBrowser* browser;

@property (nonatomic, assign) GHNetworkingState state;
@property (assign) GHNetworkingPeerType peerType;

@property (copy) GameCreationCompletionBlock creationCompletionBlock;

@end

@implementation GHNetworking

@synthesize peerID = _peerID;

@synthesize nearbyPeers = _nearbyPeers;

+ (GHNetworking *)sharedNetworking {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[GHNetworking alloc] init];
    });
    return _sharedInstance;
}

- (MCPeerID *)peerID {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _peerID = [[MCPeerID alloc] initWithDisplayName:[UIDevice currentDevice].name];
    });
    
    return _peerID;
}

- (MCNearbyServiceAdvertiser *)advertiser {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _advertiser = [[MCNearbyServiceAdvertiser alloc] initWithPeer:self.peerID discoveryInfo:nil serviceType:SERVICE_TYPE];
        _advertiser.delegate = self;
    });
    
    return _advertiser;
}

- (MCNearbyServiceBrowser *)browser {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _browser = [[MCNearbyServiceBrowser alloc] initWithPeer:self.peerID serviceType:SERVICE_TYPE];
        _browser.delegate = self;
    });
    return _browser;
}

- (id)init {
    self = [super init];
    
    if (self) {
        _nearbyPeers = [NSMutableArray array];
        self.state = GHNetworkingStateLobby;
        self.peerType = GHNetworkingPeerTypeUndefined;
    }
    
    return self;
}

- (void) startFindingPeers {
    [self.browser startBrowsingForPeers];
}

- (void) stopFindingPeers {
    [self.browser stopBrowsingForPeers];
}

// Called when an invite is received - we're a server, and the peer wants to connect
- (void)advertiser:(MCNearbyServiceAdvertiser *)advertiser didReceiveInvitationFromPeer:(MCPeerID *)peerID withContext:(NSData *)context invitationHandler:(void(^)(BOOL accept, MCSession *session))invitationHandler {
    
    if (self.peerType != GHNetworkingPeerTypeHost) {
        
        // we are not the host, don't let people join us
        invitationHandler(NO, nil);
        return;
    } else {
        
        // If we are in the lobby, we can accept people
        if (self.state == GHNetworkingStateLobby)
            invitationHandler(YES, self.session);
    }
    
}

- (void) createSession {
    self.session = [[MCSession alloc] initWithPeer:self.peerID];
    self.session.delegate = self;
}

- (void)joinPeer:(MCPeerID *)peerID {
    
    [self createSession];
    
    self.state = GHNetworkingStateJoiningGame;
    self.peerType = GHNetworkingPeerTypeClient;
    
    [self.browser invitePeer:peerID toSession:self.session withContext:nil timeout:0];
    
}

- (void) createGame {
    [self createSession];
    self.state = GHNetworkingStateLobby;
    self.peerType = GHNetworkingPeerTypeHost;
    [self.advertiser startAdvertisingPeer];
    
}

- (void) sendMessage:(GHNetworkingMessage)message data:(NSDictionary*)data {
    GHMessage* messageObject = [[GHMessage alloc] initWithMessage:message data:data];
    
    NSData* messageData = [NSKeyedArchiver archivedDataWithRootObject:messageObject];
    
    [self.session sendData:messageData toPeers:self.session.connectedPeers withMode:MCSessionSendDataReliable error:nil];
}

- (void)sendMessage:(GHNetworkingMessage)message data:(NSDictionary *)data toPeer:(MCPeerID *)peer deliveryMode:(MCSessionSendDataMode)mode{
    
    GHMessage* messageObject = [[GHMessage alloc] initWithMessage:message data:data];
    
    NSData* messageData = [NSKeyedArchiver archivedDataWithRootObject:messageObject];
    
    [self.session sendData:messageData toPeers:@[peer] withMode:mode error:nil];

}

- (void)leaveGame {
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [self.sessionDelegate networkingDidTerminateSession];
    }];
    self.peerType = GHNetworkingPeerTypeUndefined;
    
    [self sendMessage:GHNetworkingMessageShutdown data:nil];
    
    [self.advertiser stopAdvertisingPeer];
    [self.session disconnect];
}

// Found a nearby advertising peer
- (void)browser:(MCNearbyServiceBrowser *)browser foundPeer:(MCPeerID *)peerID withDiscoveryInfo:(NSDictionary *)info {
    [_nearbyPeers addObject:peerID];
    
    // Re-sort the array
    [_nearbyPeers sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"displayName" ascending:YES]]];
    
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [self.peerDiscoveryDelegate networkingDidDiscoverPeer:peerID];

    }];
}

// A nearby peer has stopped advertising
- (void)browser:(MCNearbyServiceBrowser *)browser lostPeer:(MCPeerID *)peerID {
    [_nearbyPeers removeObject:peerID];
    
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [self.peerDiscoveryDelegate networkingDidLosePeer:peerID];
    }];
}

- (void)session:(MCSession *)session peer:(MCPeerID *)peerID didChangeState:(MCSessionState)state {
    
    if (state == MCSessionStateConnecting || state == MCSessionStateConnected) {
        if (self.peerType == GHNetworkingPeerTypeClient && self.state == GHNetworkingStateJoiningGame) {
            
            self.hostPeerID = peerID;
            self.state = GHNetworkingStateLobby;
            
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                [self.peerDiscoveryDelegate networkingDidJoinSession: peerID];

            }];
        }
    }
    
    if (self.state == GHNetworkingStateLobby) {
        if (state == MCSessionStateConnected) {
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                [self.sessionDelegate networkingPlayerDidJoinSession:peerID];
            }];
        }
        if (state == MCSessionStateNotConnected) {
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                [self.sessionDelegate networkingPlayerDidLeaveSession:peerID];
            }];
            
            // If we're the client and the host leaves, bail out
            if (self.peerType == GHNetworkingPeerTypeClient && peerID == self.hostPeerID) {
                [self leaveGame];
            }
        }
        
    }
    
    if (self.state == GHNetworkingStateInGame) {
        // if we lose a peer, bail out to the start
        if (state == MCSessionStateNotConnected) {
            [self leaveGame];
        }
    }
    
    

}

- (void)session:(MCSession *)session didReceiveData:(NSData *)data fromPeer:(MCPeerID *)peerID {
    
    GHMessage* message = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    
    switch (message.message) {
        case GHNetworkingMessageShutdown:
        {
            [self leaveGame];
        }
            break;
        case GHNetworkingMessageGameBeginning:
        {
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                [self.sessionDelegate networkingWillBeginGame];
            }];
        }
            break;
        default:
        {
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                [self.sessionDelegate networkingDidReceiveMessage:message.message data:message.data];
            }];
        }
            break;
    }
    
}

- (void)beginGame {
    self.state = GHNetworkingStateInGame;
    [self.advertiser stopAdvertisingPeer];
    
    [self sendMessage:GHNetworkingMessageGameBeginning data:nil];
}

- (void)session:(MCSession *)session didFinishReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID atURL:(NSURL *)localURL withError:(NSError *)error {
    
}

- (void)session:(MCSession *)session didStartReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID withProgress:(NSProgress *)progress {
    
}

- (void)session:(MCSession *)session didReceiveStream:(NSInputStream *)stream withName:(NSString *)streamName fromPeer:(MCPeerID *)peerID {
    
}

- (BOOL)isHost {
    return self.peerType == GHNetworkingPeerTypeHost;
}

- (NSArray *)connectedPeers {
    return self.session.connectedPeers;
}

- (void)setState:(GHNetworkingState)state {
    GHNetworkingState oldState = _state;
    _state = state;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:GHNetworkingDidChangeStateNotification object:self userInfo:@{@"oldState": @(oldState), @"newState" : @(_state)}];
}

- (MCPeerID *)localPeer {
    return self.peerID;
}

@end
