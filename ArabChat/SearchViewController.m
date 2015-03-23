//
//  AboutViewController.m
//  ArabChat
//
//  Created by Housein Jouhar on 3/21/13.
//  Copyright (c) 2015 MacBook. All rights reserved.
//

#import "SearchViewController.h"

@interface SearchViewController ()

@end

@implementation SearchViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [_onlineSwitch setOn:[[NSUserDefaults standardUserDefaults] boolForKey:@"onlineVal"]];
    [_sameCitySwitch setOn:[[NSUserDefaults standardUserDefaults] boolForKey:@"cityVal"]];
    [_sameCountrySwitch setOn:[[NSUserDefaults standardUserDefaults] boolForKey:@"countryVal"]];
    [_menSwitch setOn:[[NSUserDefaults standardUserDefaults] boolForKey:@"menVal"]];
    [_womenSwitch setOn:[[NSUserDefaults standardUserDefaults] boolForKey:@"womenVal"]];
    
    [_scrollView setContentSize:CGSizeMake(self.view.frame.size.width, 504)];
    
    // Do any additional setup after loading the view from its nib.
}

- (IBAction)switchValueChanged:(UISwitch*)sender {
    if ([_onlineSwitch isOn])
    {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"onlineVal"];
    }
    else
    {
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"onlineVal"];
    }
    
    if ([_sameCitySwitch isOn])
    {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"cityVal"];
    }
    else
    {
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"cityVal"];
    }
    
    if ([_sameCountrySwitch isOn])
    {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"countryVal"];
    }
    else
    {
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"countryVal"];
    }
    
    if ([_menSwitch isOn])
    {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"menVal"];
    }
    else
    {
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"menVal"];
    }
    
    if ([_womenSwitch isOn])
    {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"womenVal"];
    }
    else
    {
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"womenVal"];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
