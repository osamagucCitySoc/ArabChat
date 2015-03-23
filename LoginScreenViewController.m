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
//@property (weak, nonatomic) IBOutlet UISwitch *rememberMeSwitch;
@property (weak, nonatomic) IBOutlet UILabel *onlineUsersLabel;

@end

@implementation LoginScreenViewController
{
    MZLoadingCircle *loadingCircle;
    NSURLConnection* loginConnection;
    NSURLConnection* onlineCountConnection;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [NSTimer scheduledTimerWithTimeInterval: 1.0 target: self selector:@selector(startAds:) userInfo: nil repeats:NO];
}

-(void)startAds:(NSTimer *)timer
{
    dispatch_queue_t myQueue = dispatch_queue_create("My Queue",NULL);
    dispatch_async(myQueue, ^{
        NSError *theError;
        NSDictionary *json;
        
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"http://osamalogician.com/arabDevs/DefneAdefak/sendComm.php"]
                                                               cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData
                                                           timeoutInterval:10];
        
        [request setHTTPMethod: @"GET"];
        
        NSError *requestError;
        NSURLResponse *urlResponse = nil;
        
        
        NSData *responseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&urlResponse error:&requestError];
        
        
        if (responseData)
        {
            NSMutableArray* dataSource = [[NSMutableArray alloc]initWithArray:[NSJSONSerialization
                                                                               JSONObjectWithData:responseData
                                                                               options:kNilOptions
                                                                               error:&theError]];
            
            if (theError || dataSource.count == 0)return;
            
            json = [dataSource objectAtIndex:0];
            dispatch_async(dispatch_get_main_queue(), ^{
                
                [self openAdWithImage:[json objectForKey:@"pic"] link:[json objectForKey:@"link"] version:[json objectForKey:@"version"]];
                
            });
            
        }
    });
}

-(void)openAdWithImage:(NSString *)img link:(NSString*)theLink version:(NSString*)theVersion
{
    if ([theVersion integerValue] == 0)return;
    
    if ([[NSUserDefaults standardUserDefaults]objectForKey:@"mesa3edAdsVersion"])
    {
        if ([[[NSUserDefaults standardUserDefaults]objectForKey:@"mesa3edAdsVersion"] integerValue] == [theVersion integerValue])return;
        [[NSUserDefaults standardUserDefaults]setObject:theVersion forKey:@"mesa3edAdsVersion"];
        [[NSUserDefaults standardUserDefaults]synchronize];
    }
    else
    {
        [[NSUserDefaults standardUserDefaults]setObject:theVersion forKey:@"mesa3edAdsVersion"];
        [[NSUserDefaults standardUserDefaults]synchronize];
    }
    
    UIView *mainAdView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width, [[UIScreen mainScreen] bounds].size.height)];
    
    [mainAdView setTag:784];
    
    [mainAdView setBackgroundColor:[UIColor colorWithRed:50.0/255 green:50.0/255 blue:50.0/255 alpha:1.0]];
    
    [[[self navigationController] view] addSubview:mainAdView];
    
    UIActivityIndicatorView *activityView = [[UIActivityIndicatorView alloc]init];
    
    [activityView startAnimating];
    
    [mainAdView addSubview:activityView];
    
    [activityView setCenter:mainAdView.center];
    
    NSData * imageData = [NSData dataWithContentsOfURL:[NSURL URLWithString:img]];
    UIImage * image = [UIImage imageWithData:imageData];
    
    UIImageView *adImage = [[UIImageView alloc]initWithImage:image];
    
    [adImage setContentMode:UIViewContentModeScaleAspectFit];
    
    [adImage setFrame:mainAdView.frame];
    
    [mainAdView addSubview:adImage];
    
    [adImage setCenter:mainAdView.center];
    
    UIButton *closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [closeButton addTarget:self action:@selector(closeAds:)forControlEvents:UIControlEventTouchUpInside];
    [mainAdView addSubview:closeButton];
    [closeButton setBackgroundImage:[UIImage imageNamed:@"close-back-b.png"] forState:UIControlStateNormal];
    closeButton.frame = CGRectMake(10, 25, 23, 23);
    
    if ([self isValidUrl:theLink])
    {
        UIButton *adsButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [adsButton addTarget:self action:@selector(openAds:)forControlEvents:UIControlEventTouchUpInside];
        [mainAdView addSubview:adsButton];
        [adsButton setFrame:CGRectMake(0, 80, [[UIScreen mainScreen] bounds].size.width, [[UIScreen mainScreen] bounds].size.height)];
        
        [[NSUserDefaults standardUserDefaults]setObject:theLink forKey:@"mesa3edAdsLink"];
        [[NSUserDefaults standardUserDefaults]synchronize];
        
        NSLog(@"ValidUrl");
    }
    
    [mainAdView setFrame:CGRectMake( 0, [[UIScreen mainScreen] bounds].size.height, [[UIScreen mainScreen] bounds].size.width, [[UIScreen mainScreen] bounds].size.height)];
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.3];
    [mainAdView setFrame:CGRectMake( 0, 0, [[UIScreen mainScreen] bounds].size.width, [[UIScreen mainScreen] bounds].size.height)];
    [UIView commitAnimations];
}

- (IBAction)openAds:(id)sender
{
    [[[[self navigationController] view] viewWithTag:784]removeFromSuperview];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[[NSUserDefaults standardUserDefaults] objectForKey:@"mesa3edAdsLink"]]];
}

- (IBAction)closeAds:(id)sender
{
    [UIView animateWithDuration:0.3 delay:0.0 options:0
                     animations:^{
                         [[[[self navigationController] view] viewWithTag:784] setFrame:CGRectMake( 0, [[UIScreen mainScreen] bounds].size.height, [[UIScreen mainScreen] bounds].size.width, [[UIScreen mainScreen] bounds].size.height)];
                     }
                     completion:^(BOOL finished) {
                         [[[[self navigationController] view] viewWithTag:784]removeFromSuperview];
                         
                     }];
    [UIView commitAnimations];
}

- (BOOL)isValidUrl:(NSString *)urlString{
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:urlString]];
    return [NSURLConnection canHandleRequest:request];
}

-(void)initUI
{
    if([[NSUserDefaults standardUserDefaults]boolForKey:@"rememberME"])
    {
        NSDictionary* userDict = [(NSDictionary*)[[NSUserDefaults standardUserDefaults]objectForKey:@"currentUser"] objectForKey:@"0"];
        [self.userNameTextField setText:[userDict objectForKey:@"username"]];
        [self.passwordTextField setText:[userDict objectForKey:@"password"]];
        //[self.rememberMeSwitch setOn:YES animated:YES];
        isRemember = YES;
        [_rememberButton setBackgroundImage:[UIImage imageNamed:@"check-on.png"] forState:UIControlStateNormal];
    }else
    {
        [self.userNameTextField setText:@""];
        [self.passwordTextField setText:@""];
        //[self.rememberMeSwitch setOn:NO animated:YES];
        isRemember = NO;
        [_rememberButton setBackgroundImage:[UIImage imageNamed:@"check-off.png"] forState:UIControlStateNormal];
    }
    
    
    if([ Reachability isConnected])
    {
        [self showLoadingMode];
        NSString *post = @"";
        NSData *postData = [post dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:NO];
        NSString *postLength = [NSString stringWithFormat:@"%lu", (unsigned long)[post length]];
        
        NSURL *url = [NSURL URLWithString:@"http://moh2013.com/arabDevs/arabchat/onlineCount.php"];
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:90.0];
        [request setHTTPMethod:@"POST"];
        
        [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
        
        [request setHTTPBody:postData];
        
        onlineCountConnection = [[NSURLConnection alloc]initWithRequest:request delegate:self    startImmediately:NO];
        
        [onlineCountConnection scheduleInRunLoop:[NSRunLoop mainRunLoop]
                                   forMode:NSDefaultRunLoopMode];
        [onlineCountConnection start];
        
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}


#pragma mark action outlets
- (IBAction)rememberMeSwitchValueChanged:(id)sender {
    
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

- (IBAction)rememberOnOff:(id)sender {
    if (isRemember)
    {
        isRemember = NO;
        [_rememberButton setBackgroundImage:[UIImage imageNamed:@"check-off.png"] forState:UIControlStateNormal];
    }
    else
    {
        isRemember = YES;
        [_rememberButton setBackgroundImage:[UIImage imageNamed:@"check-on.png"] forState:UIControlStateNormal];
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
        
        if([[[responseDict objectForKey:@"result"] objectForKey:@"error"] intValue] != 0)
        {
            [self.view makeToast:[[responseDict objectForKey:@"result"] objectForKey:@"message"] duration:5.0 position:@"bottom"];
        }else
        {
            NSDictionary* userDict = [[responseDict objectForKey:@"result"] objectForKey:@"user"];
            [[NSUserDefaults standardUserDefaults]setObject:userDict forKey:@"currentUser"];
            [[NSUserDefaults standardUserDefaults]setBool:isRemember forKey:@"rememberME"];
            [[NSUserDefaults standardUserDefaults]synchronize];
            
            dispatch_async(dispatch_get_global_queue(0,0), ^{
                NSData * data = [[NSData alloc] initWithContentsOfURL: [NSURL URLWithString: [NSString stringWithFormat:@"%@%@",@"http://moh2013.com/arabDevs/arabchat/images/",[[userDict objectForKey:@"0"] objectForKey:@"profilePic"]]]];
                if ( data == nil )
                    return;
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[NSUserDefaults standardUserDefaults]setObject:data forKey:@"mypic"];
                    [[NSUserDefaults standardUserDefaults]synchronize];
                });
            });
            
            [self performSegueWithIdentifier:@"landPageSeg" sender:self];
        }
    }else if(connection == onlineCountConnection)
    {
        [self hideLoadingMode];
        NSError* error;
        NSDictionary* responseDict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&error];
        [self.onlineUsersLabel setText:[NSString stringWithFormat:@"%@%@%@",@"إدخل الآن ! ",[[responseDict objectForKey:@"result"] objectForKey:@"online"],@" مستخدم أونلاين"]];
        [self.onlineUsersLabel setNeedsDisplay];
    }
}


#pragma mark keyboard delegate
- (void)viewWillAppear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    [self initUI];
    [_userNameTextField becomeFirstResponder];
}

- (void)viewWillDisappear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

- (void)keyboardWillShow:(NSNotification *)notification
{
//    CGSize keyboardSize = [[[notification userInfo] objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
//    
//    [UIView animateWithDuration:0.3 animations:^{
//        CGRect f = self.view.frame;
//        f.origin.y = -keyboardSize.height;
//        self.view.frame = f;
//    }];
}

-(void)keyboardWillHide:(NSNotification *)notification
{
//    [UIView animateWithDuration:0.3 animations:^{
//        CGRect f = self.view.frame;
//        f.origin.y = 0.0f;
//        self.view.frame = f;
//    }];
}

- (void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [[self view] endEditing:YES];
}

@end
