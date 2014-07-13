//
//  GHGameViewCell.m
//  GovHack2014
//
//  Created by Jon Manning on 13/07/2014.
//  Copyright (c) 2014 Secret Lab. All rights reserved.
//

#import "GHGameViewCell.h"

@implementation GHGameViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)awakeFromNib
{
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
