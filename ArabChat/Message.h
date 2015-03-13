//
//  Message.h
//  STBubbleTableViewCellDemo
//
//  Created by Cedric Vandendriessche on 24/08/13.
//  Copyright 2013 FreshCreations. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NZCircularImageView.h"

@interface Message : NSObject

+ (instancetype)messageWithString:(NSString *)message;
+ (instancetype)messageWithString:(NSString *)message image:(UIImage *)image SENT:(int)SENT;
+ (instancetype)messageWithString:(NSString *)message imagePath:(NSString *)imagePath;

- (instancetype)initWithString:(NSString *)message;
- (instancetype)initWithString:(NSString *)message image:(UIImage *)image SENT:(int)SENT;
- (instancetype)initWithString:(NSString *)message imagePath:(NSString *)imagePath;

@property (nonatomic, copy) NSString *message;
@property (nonatomic) int SENT;
@property (nonatomic, strong) UIImage *avatar;
@property (nonatomic, strong) NSString* photoPath;
@end
