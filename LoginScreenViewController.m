//
//  LoginScreenViewController.m
//  ArabChat
//
//  Created by Osama Rabie on 3/8/15.
//  Copyright (c) 2015 Osama Rabie. All rights reserved.
//

#import "LoginScreenViewController.h"
#import "MZLoadingCircle.h"
#import "Reachability.h"
#import "UIView+Toast.h"

@interface LoginScreenViewController ()<NSURLConnectionDataDelegate,NSURLConnectionDelegate>

@property (weak, nonatomic) IBOutlet UITextField *userNameTextField;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;

@end

@implementation LoginScreenViewController
{
    MZLoadingCircle *loadingCircle;
    NSURLConnection* loginConnection;
}

- (void)viewDidLoad {
    [super viewDidLoad];

}


- (void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [[self view] endEditing:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (IBAction)loginClicked:(id)sender {
    [[self view] endEditing:YES];
    
    if(![ Reachability isConnected])
    {
        [self.view makeToast:@"عذراً. يجب أن تكون متصلاً بالإنترنت" duration:5.0 position:@"bottom"];
    }else if(self.userNameTextField.text.length < 1 || self.passwordTextField.text.length < 1)
    {
        [self.view makeToast:@"عذراً. كل البيانات مطلوبة" duration:5.0 position:@"bottom"];
    }else
    {
        [self showLoadingMode];
        NSString *post = [NSString stringWithFormat:@"username=%@&password=%@",self.userNameTextField.text,self.passwordTextField.text];
        
        NSData *postData = [post dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:NO];
        NSString *postLength = [NSString stringWithFormat:@"%lu", (unsigned long)[post length]];
        
        NSURL *url = [NSURL URLWithString:@"http://moh2013.com/arabDevs/arabchat/loginUser.php"];
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:90.0];
        [request setHTTPMethod:@"POST"];
        
        [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
        
        [request setHTTPBody:postData];
        
        loginConnection = [[NSURLConnection alloc]initWithRequest:request delegate:self    startImmediately:NO];
        
        [loginConnection scheduleInRunLoop:[NSRunLoop mainRunLoop]
                                         forMode:NSDefaultRunLoopMode];
        [loginConnection start];

    }
}



#pragma mark-
#pragma mark-MDProgress HUD
-(void)showLoadingMode {
    if (!loadingCircle) {
        loadingCircle = [[MZLoadingCircle alloc]initWithNibName:nil bundle:nil];
        loadingCircle.view.backgroundColor = [UIColor clearColor];
        
        //Colors for layers
        loadingCircle.colorCustomLayer = [UIColor colorWithRed:1 green:0.4 blue:0 alpha:1];
        loadingCircle.colorCustomLayer2 = [UIColor colorWithRed:0 green:0.4 blue:1 alpha:0.65];
        loadingCircle.colorCustomLayer3 = [UIColor colorWithRed:0 green:0.4 blue:0 alpha:0.4];
        
        int size = 100;
        
        CGRect frame = loadingCircle.view.frame;
        frame.size.width = size ;
        frame.size.height = size;
        frame.origin.x = self.view.frame.size.width / 2 - frame.size.width / 2;
        frame.origin.y = self.view.frame.size.height / 2 - frame.size.height / 2;
        loadingCircle.view.frame = frame;
        loadingCircle.view.layer.zPosition = MAXFLOAT;
        [self.view addSubview: loadingCircle.view];
    }
}

-(void)hideLoadingMode {
    if (loadingCircle) {
        [loadingCircle.view removeFromSuperview];
        loadingCircle = nil;
    }
}

#pragma mark Connection Delegate
-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    if(connection == loginConnection)
    {
        [self hideLoadingMode];
        NSError* error;
        NSDictionary* responseDict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&error];
        
        if([[responseDict objectForKey:@"result"] objectForKey:@"error"])
        {
            [self.view makeToast:[[responseDict objectForKey:@"result"] objectForKey:@"message"] duration:5.0 position:@"bottom"];
        }else
        {
            NSDictionary* userDict = [[responseDict objectForKey:@"result"] objectForKey:@"user"];
            [[NSUserDefaults standardUserDefaults]setObject:userDict forKey:@"currentUser"];
            [[NSUserDefaults standardUserDefaults]synchronize];
        }
    }
}


#pragma mark keyboard delegate
- (void)viewWillAppear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

- (void)keyboardWillShow:(NSNotification *)notification
{
    CGSize keyboardSize = [[[notification userInfo] objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    
    [UIView animateWithDuration:0.3 animations:^{
        CGRect f = self.view.frame;
        f.origin.y = -keyboardSize.height;
        self.view.frame = f;
    }];
}

-(void)keyboardWillHide:(NSNotification *)notification
{
    [UIView animateWithDuration:0.3 animations:^{
        CGRect f = self.view.frame;
        f.origin.y = 0.0f;
        self.view.frame = f;
    }];
}
@end
