//
//  Message.m
//  STBubbleTableViewCellDemo
//
//  Created by Cedric Vandendriessche on 24/08/13.
//  Copyright 2013 FreshCreations. All rights reserved.
//

#import "Message.h"

@implementation Message

+ (instancetype)messageWithString:(NSString *)message
{
	return [Message messageWithString:message image:nil SENT:0];
}

+ (instancetype)messageWithString:(NSString *)message image:(UIImage *)image SENT:(int)SENT
{
	return [[Message alloc] initWithString:message image:image SENT:SENT];
}

+ (instancetype)messageWithString:(NSString *)message imagePath:(NSString *)imagePath
{
    return [[Message alloc] initWithString:message imagePath:imagePath];
}

- (instancetype)initWithString:(NSString *)message
{
	return [self initWithString:message image:nil SENT:0];
}

- (instancetype)initWithString:(NSString *)message image:(UIImage *)image SENT:(int)SENT
{
	self = [super init];
	if(self)
	{
		_message = message;
		_avatar = image;
        _SENT = SENT;
	}
	return self;
}


- (instancetype)initWithString:(NSString *)message imagePath:(NSString *)imagePath;
{
    self = [super init];
    if(self)
    {
        _message = message;
        _photoPath = imagePath;
    }
    return self;
}

@end
