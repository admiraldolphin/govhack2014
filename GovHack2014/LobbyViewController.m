//
//  GameViewController.m
//  GovHack2014
//
//  Created by Jon Manning on 11/07/2014.
//  Copyright (c) 2014 Secret Lab. All rights reserved.
//

#import "LobbyViewController.h"
#import "GHNetworking.h"

@interface LobbyViewController () <GHNetworkingSessionDelegate>
@property (weak, nonatomic) IBOutlet UITextField *chatField;
@property (weak, nonatomic) IBOutlet UILabel *peerTypeLabel;

@property (weak, nonatomic) IBOutlet UILabel *playersLabel;
@property (weak, nonatomic) IBOutlet UIButton *startGameButton;
@end

@implementation LobbyViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (IBAction)sendChat:(id)sender {
    NSDictionary* dataToSend = @{@"text": [self.chatField.text dataUsingEncoding:NSUTF8StringEncoding]};
    
    [[GHNetworking sharedNetworking] sendMessage:GHNetworkingMessageData data:dataToSend];
    self.chatField.text = @"";
}

- (void)networkingDidReceiveMessage:(GHNetworkingMessage)message data:(NSDictionary *)data {
    NSString* string = [data objectForKey:@"text"];
    
    [[[UIAlertView alloc] initWithTitle:@"Message" message:string delegate:nil cancelButtonTitle:@"Close" otherButtonTitles:nil] show];
}

- (void) updatePlayerCount {
    
    // +1 to include ourself
    NSUInteger playerCount = [GHNetworking sharedNetworking].connectedPeers.count + 1;
    
    NSString* playerCountString = [NSString stringWithFormat:@"%lu", (unsigned long)playerCount];
    
    self.playersLabel.text = playerCountString;
}

- (void)networkingPlayerDidJoinSession:(MCPeerID *)peerID {
    [self updatePlayerCount];
}

- (void)networkingPlayerDidLeaveSession:(MCPeerID *)peerID {
    [self updatePlayerCount];
}

- (IBAction)startGame:(id)sender {
    [[GHNetworking sharedNetworking] sendMessage:GHNetworkingMessageGameBeginning data:nil];
    [self performSegueWithIdentifier:@"BeginGame" sender:nil];
}

- (IBAction)leaveGame:(id)sender {
    [[GHNetworking sharedNetworking] leaveGame];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [GHNetworking sharedNetworking].sessionDelegate = self;
    
    if ([GHNetworking sharedNetworking].isHost) {
        self.peerTypeLabel.text = @"You are the server";
        
        self.startGameButton.enabled = YES;
    } else {
        self.peerTypeLabel.text = @"You are a client";
        
        self.startGameButton.enabled = NO;
    }
    
    [self updatePlayerCount];
    
    // Do any additional setup after loading the view.
}

- (void)networkingWillBeginGame {
    [self performSegueWithIdentifier:@"BeginGame" sender:nil];
}

- (void)networkingDidTerminateSession {    
    [self.navigationController popToRootViewControllerAnimated:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)prefersStatusBarHidden {
    return YES;
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
