//
//  LoginScreenViewController.m
//  ArabChat
//
//  Created by Osama Rabie on 3/8/15.
//  Copyright (c) 2015 Osama Rabie. All rights reserved.
//

#import "LoginScreenViewController.h"
#import "MBProgressHUD.h"
#import "Reachability.h"
#import "UIView+Toast.h"

@interface LoginScreenViewController ()<MBProgressHUDDelegate>

@property (weak, nonatomic) IBOutlet UITextField *userNameTextField;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;

@end

@implementation LoginScreenViewController
{
    MBProgressHUD *HUD;
}

- (void)viewDidLoad {
    [super viewDidLoad];

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (IBAction)loginClicked:(id)sender {
    
}



#pragma mark-
#pragma mark-MDProgress HUD
-(void)launchHUD{
    HUD = [[MBProgressHUD alloc] initWithView:self.view];
    [self.view addSubview:HUD];
    //    HUD.dimBackground = YES;
    
    HUD.delegate = self;
    HUD.labelText = @"Loading";
    
}
- (void)hideLoader {
    // Do something usefull in here instead of sleeping ...
    [HUD hide:YES afterDelay:1.5];
}
- (void)showLoader{
    [HUD show:YES];
}
@end
