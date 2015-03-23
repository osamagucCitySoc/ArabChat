//
//  SearchViewController.h
//  ArabChat
//
//  Created by Housein Jouhar on 3/21/13.
//  Copyright (c) 2015 MacBook. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SearchViewController : UIViewController
@property (strong, nonatomic) IBOutlet UISwitch *onlineSwitch;
@property (strong, nonatomic) IBOutlet UISwitch *sameCitySwitch;
@property (strong, nonatomic) IBOutlet UISwitch *sameCountrySwitch;
@property (strong, nonatomic) IBOutlet UISwitch *menSwitch;
@property (strong, nonatomic) IBOutlet UISwitch *womenSwitch;
@property (strong, nonatomic) IBOutlet UIScrollView *scrollView;

@end
