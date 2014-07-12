//
//  GameViewController.m
//  GovHack2014
//
//  Created by Jon Manning on 12/07/2014.
//  Copyright (c) 2014 Secret Lab. All rights reserved.
//

#import "GameViewController.h"
#import "GHNetworking.h"
#import "GHGame.h"
#import "GHGameClient.h"

@interface GameViewController () <GHNetworkingSessionDelegate>

@property (strong) GHGame* game;
@property (strong) GHGameClient* gameClient;

@property (weak, nonatomic) IBOutlet UILabel *missionNameLabel;
@property (weak, nonatomic) IBOutlet UIProgressView *missionTimeProgress;
@property (weak, nonatomic) IBOutlet UILabel *gameStateLabel;
@end

@implementation GameViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(networkingDidChangeState:) name:GHNetworkingDidChangeStateNotification object:nil];
    
    // We want to start receiving game data
    [GHNetworking sharedNetworking].sessionDelegate = self;
    
    // Create a client
    self.gameClient = [[GHGameClient alloc] init];
    
    // If I'm the server, create the game and start it off
    if ([GHNetworking sharedNetworking].isHost) {
        self.game = [[GHGame alloc] init];
        self.game.localClient = self.gameClient;
    }
    
    
    [self.gameClient addObserver:self forKeyPath:@"missionName" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial context:nil];
    
    [self.gameClient addObserver:self forKeyPath:@"timeRemaining" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial context:nil];
    
    [self.gameClient addObserver:self forKeyPath:@"timeAvailable" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial context:nil];
    
    [self.gameClient addObserver:self forKeyPath:@"state" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial context:nil];
    
    
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    
    
    if ([keyPath isEqualToString:@"missionName"]) {
        
        self.missionNameLabel.text = self.gameClient.missionName;
    }
    
    if ([keyPath isEqualToString:@"timeRemaining"]) {
        [self updateProgress];
    }
    
    if ([keyPath isEqualToString:@"timeAvailable"]) {
        [self updateProgress];
    }
    
    if ([keyPath isEqualToString:@"state"]) {
        [self updateState];
    }
    
}

- (void) updateProgress {
    
    if (self.gameClient.timeAvailable <= 0.0) {
        self.gameClient.timeAvailable = 1.0;
        return;
    }
    
    float progress = self.gameClient.timeRemaining / self.gameClient.timeAvailable;
    
    self.missionTimeProgress.progress = progress;
}

- (void) updateState {
    
    NSString* string = nil;
    
    switch (self.gameClient.state) {
        case GHGameStateWaitingForMissions:
            string = @"Waiting for missions";
            break;
        case GHGameStatePerformingMissions:
            string = @"Performing missions";
            break;
        case GHGameStateGameOver:
            string = @"Game over";
            break;
        case GHGameStateViewingGameReport:
            string = @"Viewing game report";
            break;
    }
    
    self.gameStateLabel.text = string;
    
}

- (void)networkingWillBeginGame {
    
}

- (void)networkingPlayerDidJoinSession:(MCPeerID *)peerID {
    
}

- (void)networkingPlayerDidLeaveSession:(MCPeerID *)peerID {
    
}

- (void)networkingDidTerminateSession {
    
}

- (void)networkingDidReceiveMessage:(GHNetworkingMessage)message data:(NSDictionary *)data {
    [self.gameClient processReceivedMessage:data];
}

- (void) networkingDidChangeState:(NSNotification*)notification {
    if ([GHNetworking sharedNetworking].state == GHNetworkingStateNotConnected) {
        [self.navigationController popToRootViewControllerAnimated:YES];
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
