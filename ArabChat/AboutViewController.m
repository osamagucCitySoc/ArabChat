//
//  AboutViewController.m
//  ArabChat
//
//  Created by Housein Jouhar on 3/21/13.
//  Copyright (c) 2015 MacBook. All rights reserved.
//

#import "AboutViewController.h"

@interface AboutViewController ()

@end

@implementation AboutViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (IBAction)goToApps:(id)sender {
     [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"itms-apps://itunes.apple.com/sa/artist/musaed-alazmi/id662172394"]];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    
    [dateFormatter setDateFormat:@"YYYY"];
    
    _rightsLabel.text = [@"  جميع الحقوق محفوظة للمطورين العرب " stringByAppendingFormat:@"%@",[dateFormatter stringFromDate:[NSDate date]]];
    
    float appVer = [[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"] floatValue];
    
    _verLabel.text = [@"الإصدار:" stringByAppendingFormat:@" %.1f",appVer];
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
