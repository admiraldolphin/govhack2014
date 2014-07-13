//
//  GHMinionCell.m
//  GovHack2014
//
//  Created by Jon Manning on 12/07/2014.
//  Copyright (c) 2014 Secret Lab. All rights reserved.
//

#import "GHMinionCell.h"

#define FRAME_COUNT 12

@implementation GHMinionCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)awakeFromNib {
    int frameNumber = arc4random_uniform(12) + 1;
    
    NSString* frameID = [NSString stringWithFormat:@"Frame%i", frameNumber];
    
    UIImage* frame = [UIImage imageNamed:frameID];
    
    self.frameImage.image = frame;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
