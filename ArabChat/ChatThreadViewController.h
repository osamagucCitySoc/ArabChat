//
//  ChatThreadViewController.h
//  ArabChat
//
//  Created by Osama Rabie on 3/13/15.
//  Copyright (c) 2015 Osama Rabie. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ChatThreadViewController : UIViewController

@property (nonatomic, strong) NSMutableArray *messages;
@property (nonatomic, strong) NSString *FRDID;
@property (nonatomic, strong) UIImage *FRDIMG;
@property (nonatomic, strong) NSString* FRDNAME;
@property (nonatomic, strong) NSString* FRDPIC;


@end
