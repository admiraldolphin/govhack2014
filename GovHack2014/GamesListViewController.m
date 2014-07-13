//
//  ViewController.m
//  GovHack2014
//
//  Created by Jon Manning on 11/07/2014.
//  Copyright (c) 2014 Secret Lab. All rights reserved.
//

#import "GamesListViewController.h"
#import "GHNetworking.h"
#import "GHGameViewCell.h"

@interface GamesListViewController () <GHNetworkingPeerDiscoveryDelegate>

@end

@implementation GamesListViewController

- (IBAction)startGame:(id)sender {
    [[GHNetworking sharedNetworking] createGame];
    [self performSegueWithIdentifier:@"ShowGame" sender:nil];
}

- (void)viewDidLoad {
    [GHNetworking sharedNetworking].peerDiscoveryDelegate = self;
}

- (void) viewDidAppear:(BOOL)animated {
    [[GHNetworking sharedNetworking] startFindingPeers];
    [GHNetworking sharedNetworking].peerDiscoveryDelegate = self;
}

- (void)viewWillDisappear:(BOOL)animated {
    [[GHNetworking sharedNetworking] stopFindingPeers];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [GHNetworking sharedNetworking].nearbyPeers.count;
}

- (UITableViewCell*) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    GHGameViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"PeerCell" forIndexPath:indexPath];
    
    MCPeerID* peer = [GHNetworking sharedNetworking].nearbyPeers[indexPath.row];
    
    cell.gameNameLabel.text = peer.displayName;
    
    return cell;
}

- (void)networkingDidJoinSession:(MCPeerID*)peerID {

    [self performSegueWithIdentifier:@"ShowGame" sender:peerID];

}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    MCPeerID* peerID = [GHNetworking sharedNetworking].nearbyPeers[indexPath.row];
    
    [[GHNetworking sharedNetworking] joinPeer:peerID];
    
}

- (void)networkingDidDiscoverPeer:(MCPeerID *)peerID {
    [self.tableView reloadData];
}

- (void)networkingDidLosePeer:(MCPeerID *)peerID {
    [self.tableView reloadData];
}

@end
