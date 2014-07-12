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
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)generateMinion:(id)sender
{
    NSString *appearanceString = [NSString stringWithFormat:@"%@%i%i%i%i%i%i%i%i",
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

    self.minionView.image = [UIImage imageWithMinionString:appearanceString];
}

@end
