//
//  UIImage+MinionImage.h
//  GovHack2014
//
//  Created by Timothy Rodney Nugent on 12/07/2014.
//  Copyright (c) 2014 Secret Lab. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (MinionImage)

+ (UIImage *)imageWithMinionString:(NSString *)minionImageIdentString;
+ (UIImage *)randomMinionImage;

@end
