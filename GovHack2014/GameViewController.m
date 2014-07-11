//
//  GameViewController.m
//  GovHack2014
//
//  Created by Jon Manning on 11/07/2014.
//  Copyright (c) 2014 Secret Lab. All rights reserved.
//

#import "GameViewController.h"
#import "GHNetworking.h"

@interface GameViewController () <GHNetworkingSessionDelegate>
@property (weak, nonatomic) IBOutlet UITextField *chatField;
@property (weak, nonatomic) IBOutlet UILabel *peerTypeLabel;

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

- (IBAction)sendChat:(id)sender {
    NSData* dataToSend = [self.chatField.text dataUsingEncoding:NSUTF8StringEncoding];
    [[GHNetworking sharedNetworking] sendMessage:GHNetworkingMessageData data:dataToSend];
    self.chatField.text = @"";
}

- (void)networkingDidReceiveMessage:(GHNetworkingMessage)message data:(NSData *)data {
    NSString* string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    [[[UIAlertView alloc] initWithTitle:@"Message" message:string delegate:nil cancelButtonTitle:@"Close" otherButtonTitles:nil] show];
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
    } else {
        self.peerTypeLabel.text = @"You are a client";
    }
    
    // Do any additional setup after loading the view.
}

- (void)networkingWillBeginSession {
    
}

- (void)networkingDidTerminateSession {    
    [self.navigationController popToRootViewControllerAnimated:YES];
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
