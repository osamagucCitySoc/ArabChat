//
//  LoginScreenViewController.h
//  ArabChat
//
//  Created by Osama Rabie on 3/8/15.
//  Copyright (c) 2015 Osama Rabie. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LoginScreenViewController : UIViewController
{
    BOOL isRemember;
}

@property (strong, nonatomic) IBOutlet UIButton *rememberButton;

@end
