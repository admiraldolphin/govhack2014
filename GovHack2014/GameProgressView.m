//
//  GameProgressView.m
//  GovHack2014
//
//  Created by Jon Manning on 13/07/2014.
//  Copyright (c) 2014 Secret Lab. All rights reserved.
//

#import "GameProgressView.h"

@import QuartzCore;

@implementation GameProgressView {
    CAShapeLayer* _maskLayer;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

- (void)setProgress:(float)progress {
    
    _progress = progress;
    
    CGRect rect = self.bounds;
    rect.size.width *= 1.0 - progress;
    
    UIBezierPath* path = [UIBezierPath bezierPathWithRoundedRect:rect cornerRadius:rect.size.height / 2.0];
    
    _maskLayer.path = path.CGPath;
    
}

- (void)awakeFromNib {
    
    _maskLayer = [[CAShapeLayer alloc] init];
    
    self.layer.mask = _maskLayer;
    
}

@end
