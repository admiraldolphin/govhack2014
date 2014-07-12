//
//  GHNetworking.h
//  GovHack2014
//
//  Created by Jon Manning on 11/07/2014.
//  Copyright (c) 2014 Secret Lab. All rights reserved.
//

#import <Foundation/Foundation.h>
@import MultipeerConnectivity;

typedef enum : NSInteger {
    GHNetworkingMessageShutdown,
    GHNetworkingMessageData,
    GHNetworkingMessageGameBeginning,
} GHNetworkingMessage;

extern NSString* GHNetworkingDidChangeStateNotification;

typedef void(^GameCreationCompletionBlock)(BOOL success);

@protocol GHNetworkingPeerDiscoveryDelegate <NSObject>

- (void) networkingDidDiscoverPeer:(MCPeerID*)peerID;
- (void) networkingDidLosePeer:(MCPeerID*)peerID;
- (void) networkingDidJoinSession:(MCPeerID*)peerID;

@end

@protocol GHNetworkingSessionDelegate <NSObject>

- (void) networkingWillBeginSession;
- (void) networkingPlayerDidJoinSession:(MCPeerID*)peerID;
- (void) networkingPlayerDidLeaveSession:(MCPeerID*)peerID;
- (void) networkingDidReceiveMessage:(GHNetworkingMessage)message data:(NSData*)data;
- (void) networkingDidTerminateSession;

@end

@protocol GHNetworkingDataDeliveryDelegate <NSObject>

@end

@interface GHNetworking : NSObject

+ (GHNetworking*) sharedNetworking;

@property (readonly) NSArray* nearbyPeers;
@property (readonly) NSArray* connectedPeers;

@property (weak) id<GHNetworkingPeerDiscoveryDelegate> peerDiscoveryDelegate;
@property (weak) id<GHNetworkingSessionDelegate> sessionDelegate;
@property (weak) id<GHNetworkingDataDeliveryDelegate> dataDeliveryDelegate;

// invites all peers
- (void) createGame;
- (void) joinPeer:(MCPeerID*)peerID;

// terminates the game if you're the server, or leaves the game if we're a peer
- (void) leaveGame;

// Begins the game, stops advertising, and disallows all incoming connections
- (void) beginGame;

- (void) sendMessage:(GHNetworkingMessage)message data:(NSData*)data;

@property (readonly) BOOL isHost;

- (void) startFindingPeers;
- (void) stopFindingPeers;

@end
