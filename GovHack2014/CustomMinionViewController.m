//
//  CustomMinionViewController.m
//  GovHack2014
//
//  Created by Timothy Rodney Nugent on 13/07/2014.
//  Copyright (c) 2014 Secret Lab. All rights reserved.
//

#import "CustomMinionViewController.h"
#import "UIImage+MinionImage.h"

@interface CustomMinionViewController ()
@property (weak, nonatomic) IBOutlet UIImageView *minionView;

@end

@implementation CustomMinionViewController

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    self.minionView.image = [UIImage randomMinionImage];
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)generateMinion:(id)sender
{
    int roll = arc4random_uniform(10);
    if (roll == 0)
        self.minionView.image = [UIImage randomGenderlessMinionImage];
    else
        self.minionView.image = [UIImage randomMinionImage];
}
- (IBAction)goBack:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}
- (IBAction)shareMinion:(id)sender
{
    NSURL *site = [NSURL URLWithString:@"http://www.secretlab.com.au/govhack2014"];
    NSString *tweet = [NSString stringWithFormat:@"What is Gov? #GovHack #GovHackTas %@",site];
    UIActivityViewController *activity = [[UIActivityViewController alloc] initWithActivityItems:@[tweet,self.minionView.image] applicationActivities:nil];
    [self presentViewController:activity
                       animated:YES
                     completion:nil];
}

@end
