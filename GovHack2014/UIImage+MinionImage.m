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
    
    // 1-2 Shirt
    [imageArray addObject:[UIImage imageNamed:[NSString stringWithFormat:@"Shirt%@",[minionImageIdentString substringWithRange:NSMakeRange(8, 1)]]]];
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
    // 1-5 Accessory
    [imageArray addObject:[UIImage imageNamed:[NSString stringWithFormat:@"Accessory%@",[minionImageIdentString substringWithRange:NSMakeRange(6, 1)]]]];
    // 1-6 Head
    [imageArray addObject:[UIImage imageNamed:[NSString stringWithFormat:@"%@Head%@",gender,[minionImageIdentString substringWithRange:NSMakeRange(7, 1)]]]];
    
    
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

+ (UIImage *)randomMinionImage
{
    return [UIImage imageWithMinionString:[NSString stringWithFormat:@"%@%i%i%i%i%i%i%i%i",
                                           arc4random_uniform(2) == 0 ? @"m" : @"f",
                                           arc4random_uniform(6)+1,
                                           arc4random_uniform(6)+1,
                                           arc4random_uniform(6)+1,
                                           arc4random_uniform(6)+1,
                                           arc4random_uniform(6)+1,
                                           arc4random_uniform(6)+1,
                                           arc4random_uniform(6)+1,
                                           arc4random_uniform(2)+1
                                           ]];
}

+ (UIImage *)randomGenderlessMinionImage
{
    NSMutableArray *imageArray = [NSMutableArray array];
    
    // shirt
    [imageArray addObject:[UIImage imageNamed:[NSString stringWithFormat:@"Shirt%i",arc4random_uniform(2)+1]]];
    // hair
    [imageArray addObject:[UIImage imageNamed:[NSString stringWithFormat:@"%@Hair%i",arc4random_uniform(2) == 0 ? @"Male" : @"Female",arc4random_uniform(6)+1]]];
    // eyebrows
    [imageArray addObject:[UIImage imageNamed:[NSString stringWithFormat:@"%@Eyebrow%i",arc4random_uniform(2) == 0 ? @"Male" : @"Female",arc4random_uniform(6)+1]]];
    // mouth
    [imageArray addObject:[UIImage imageNamed:[NSString stringWithFormat:@"%@Mouth%i",arc4random_uniform(2) == 0 ? @"Male" : @"Female",arc4random_uniform(6)+1]]];
    // eyes
    [imageArray addObject:[UIImage imageNamed:[NSString stringWithFormat:@"%@Eyes%i",arc4random_uniform(2) == 0 ? @"Male" : @"Female",arc4random_uniform(6)+1]]];
    // nose
    [imageArray addObject:[UIImage imageNamed:[NSString stringWithFormat:@"%@Nose%i",arc4random_uniform(2) == 0 ? @"Male" : @"Female",arc4random_uniform(6)+1]]];
    // accessories
    [imageArray addObject:[UIImage imageNamed:[NSString stringWithFormat:@"Accessory%i",arc4random_uniform(5)+1]]];
    // head
    [imageArray addObject:[UIImage imageNamed:[NSString stringWithFormat:@"%@Head%i",arc4random_uniform(2) == 0 ? @"Male" : @"Female",arc4random_uniform(6)+1]]];
    
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
