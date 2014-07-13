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
#import "GHMinionCell.h"
#import "UIImage+MinionImage.h"
#import "GameProgressView.h"

@interface GameViewController () <GHNetworkingSessionDelegate, UICollectionViewDataSource, UICollectionViewDelegate, GHGameClientDelegate>

@property (strong) GHGame* game;
@property (strong) GHGameClient* gameClient;

@property (weak, nonatomic) IBOutlet UILabel *missionNameLabel;
@property (weak, nonatomic) IBOutlet UIProgressView *missionTimeProgress;
@property (weak, nonatomic) IBOutlet UILabel *gameStateLabel;
@property (weak, nonatomic) IBOutlet UILabel *pointsLabel;
@property (weak, nonatomic) IBOutlet UICollectionView *minionsCollectionView;


@property (weak, nonatomic) IBOutlet UIView *waitingForMissionsView;
@property (weak, nonatomic) IBOutlet UIView *gameOverView;
@property (weak, nonatomic) IBOutlet UIView *endGameReportView;

@property (weak, nonatomic) IBOutlet UILabel *endGameReportLabel;

@property (weak, nonatomic) IBOutlet GameProgressView *progressView;

@property (strong) UIView* feedbackView;

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
    self.gameClient.delegate = self;
    
    // If I'm the server, create the game and start it off
    if ([GHNetworking sharedNetworking].isHost) {
        self.game = [[GHGame alloc] initWithLocalClient:self.gameClient];
    }
    
    self.feedbackView = [[UIView alloc] initWithFrame:self.view.bounds];
    self.feedbackView.backgroundColor = [UIColor greenColor];
    self.feedbackView.userInteractionEnabled = NO;
    self.feedbackView.alpha = 0.0;
    [self.view addSubview:self.feedbackView];
    
    
    
    [self.gameClient addObserver:self forKeyPath:@"missionName" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial context:nil];
    
    [self.gameClient addObserver:self forKeyPath:@"timeRemaining" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial context:nil];
    
    [self.gameClient addObserver:self forKeyPath:@"timeAvailable" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial context:nil];
    
    [self.gameClient addObserver:self forKeyPath:@"state" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial context:nil];
    
    [self.gameClient addObserver:self forKeyPath:@"progress" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial context:nil];
    
    [self.gameClient addObserver:self forKeyPath:@"people" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial context:nil];
    
    
    
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
    
    if ([keyPath isEqualToString:@"progress"]) {
        [self updatePoints];
    }
    
    if ([keyPath isEqualToString:@"people"]) {
        [self updatePeople];
    }
    
}

- (void)updatePeople {
    NSLog(@"NEW PEOPLE:\n%@", self.gameClient.people);
    [self.minionsCollectionView reloadData];
}

- (void) updatePoints {
    self.progressView.progress = self.gameClient.progress;
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
    
    self.waitingForMissionsView.hidden = YES;
    self.gameOverView.hidden = YES;
    self.endGameReportView.hidden = YES;
    
    switch (self.gameClient.state) {
        case GHGameStateWaitingForMissions:
        {
            string = @"Waiting for missions";
            self.waitingForMissionsView.hidden = NO;
        }
            break;
        case GHGameStatePerformingMissions:
        {
            string = @"Performing missions";
        }
            break;
        case GHGameStateGameOver:
        {
            string = @"Game over";
            self.gameOverView.hidden = NO;
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [[GHNetworking sharedNetworking] leaveGame];
            });
            
        }
            break;
        case GHGameStateViewingGameReport:
        {
            string = @"Viewing game report";
            self.endGameReportView.hidden = NO;
        }
            break;
    }
    
    self.gameStateLabel.text = string;
    
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)networkingWillBeginGame {
    
}

- (void)networkingPlayerDidJoinSession:(MCPeerID *)peerID {
    
}

- (void)networkingPlayerDidLeaveSession:(MCPeerID *)peerID {
    
}

- (void)networkingDidTerminateSession {
    [self.navigationController popToRootViewControllerAnimated:YES];
    
}

- (void)networkingDidReceiveMessage:(GHNetworkingMessage)message data:(NSDictionary *)data {
    
    if ([GHNetworking sharedNetworking].isHost) {
        if ([data[@"messageType"] isEqualToString:@"selectedMinion"]) {
            [self.game peerUsedMinionWithIdentifier:data[@"identifier"]];
        }
    }
    
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

#pragma mark - Collection view

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.gameClient.people.count;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    GHMinionCell* cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"PersonCell" forIndexPath:indexPath];
    
    NSDictionary* person = self.gameClient.people[indexPath.item];
    
    cell.imageView.image = [UIImage imageWithMinionString:person[@"appearance"]];
    cell.nameLabel.text = person[@"name"];
    
    return cell;
    
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    
    NSDictionary* minion = self.gameClient.people[indexPath.item];
    
    if ([[GHNetworking sharedNetworking] isHost]) {
        // tell the server directly
        [self.game peerUsedMinionWithIdentifier:minion[@"identifier"]];
    } else {
        // send a message to the server
        
        NSDictionary* messageDict = @{@"messageType": @"selectedMinion", @"identifier":minion[@"identifier"]};
        
        [[GHNetworking sharedNetworking] sendMessage:GHNetworkingMessageData data:messageDict toPeer:[GHNetworking sharedNetworking].hostPeerID deliveryMode:MCSessionSendDataReliable];
        
    }
    
}

- (void)missionDidNotSucceed {
    self.feedbackView.backgroundColor = [UIColor redColor];
    self.feedbackView.alpha = 0.25;
    
    [UIView animateWithDuration:0.5 animations:^{
        self.feedbackView.alpha = 0.0;
    }];
}

- (void)missionSucceeded {
    self.feedbackView.backgroundColor = [UIColor greenColor];
    self.feedbackView.alpha = 0.25;
    
    [UIView animateWithDuration:0.5 animations:^{
        self.feedbackView.alpha = 0.0;
    }];
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
