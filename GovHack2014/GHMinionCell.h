//
//  GHMinionCell.h
//  GovHack2014
//
//  Created by Jon Manning on 12/07/2014.
//  Copyright (c) 2014 Secret Lab. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GHMinionCell : UICollectionViewCell
@property (weak, nonatomic) IBOutlet UIImageView *frameImage;

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@end
