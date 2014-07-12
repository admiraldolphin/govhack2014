//
//  UIImage+MinionImage.m
//  GovHack2014
//
//  Created by Timothy Rodney Nugent on 12/07/2014.
//  Copyright (c) 2014 Secret Lab. All rights reserved.
//

#import "UIImage+MinionImage.h"

@implementation UIImage (MinionImage)

+ (UIImage *)imageWithMinionString:(NSString *)minionImageIdentString
{
    // the string fully defines what the image will look like
    // m/f gender
    NSString *gender;
    if ([[minionImageIdentString substringWithRange:NSMakeRange(0, 1)] isEqualToString:@"m"])
        gender = @"Male";
    else
        gender = @"Female";
    
    NSMutableArray *imageArray = [NSMutableArray array];
    
    // 1-6 Hair
    [imageArray addObject:[UIImage imageNamed:[NSString stringWithFormat:@"%@Hair%@",gender,[minionImageIdentString substringWithRange:NSMakeRange(1, 1)]]]];
    // 1-6 Eyebrow
    [imageArray addObject:[UIImage imageNamed:[NSString stringWithFormat:@"%@Eyebrow%@",gender,[minionImageIdentString substringWithRange:NSMakeRange(2, 1)]]]];
    // 1-6 Mouth
    [imageArray addObject:[UIImage imageNamed:[NSString stringWithFormat:@"%@Mouth%@",gender,[minionImageIdentString substringWithRange:NSMakeRange(3, 1)]]]];
    // 1-6 Eyes
    [imageArray addObject:[UIImage imageNamed:[NSString stringWithFormat:@"%@Eyes%@",gender,[minionImageIdentString substringWithRange:NSMakeRange(4, 1)]]]];
    // 1-6 Nose
    [imageArray addObject:[UIImage imageNamed:[NSString stringWithFormat:@"%@Nose%@",gender,[minionImageIdentString substringWithRange:NSMakeRange(5, 1)]]]];
    // 1-6 Head
    [imageArray addObject:[UIImage imageNamed:[NSString stringWithFormat:@"%@Head%@",gender,[minionImageIdentString substringWithRange:NSMakeRange(6, 1)]]]];
    // 1-6 accessories (none currently supported...)
    
    UIImage *image = imageArray[0];
    UIGraphicsBeginImageContext(image.size);
    
    for (UIImage *image in [imageArray reverseObjectEnumerator].allObjects)
    {
        [image drawAtPoint:CGPointMake(0, 0)];
    }
    UIImage *minion = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return minion;
}

@end