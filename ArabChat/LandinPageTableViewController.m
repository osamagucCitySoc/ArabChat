//
//  LandinPageTableViewController.m
//  ArabChat
//
//  Created by Osama Rabie on 3/9/15.
//  Copyright (c) 2015 Osama Rabie. All rights reserved.
//

#import "LandinPageTableViewController.h"
#import "NZCircularImageView.h"
#import "Reachability.h"
#import "UIView+Toast.h"
#import "MZLoadingCircle.h"
#import "UserGalleryTableViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "BBBadgeBarButtonItem.h"

@interface LandinPageTableViewController ()<NSURLConnectionDataDelegate,NSURLConnectionDelegate,UIActionSheetDelegate>

@property (weak, nonatomic) IBOutlet UISwitch *menSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *womenSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *onlineSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *sameCountrySwitch;
@property (weak, nonatomic) IBOutlet UISwitch *sameCitySwitch;
@property (weak, nonatomic) IBOutlet UIView *upperView;

@end

@implementation LandinPageTableViewController
{
    MZLoadingCircle *loadingCircle;
    NSMutableData* responseData;
    NSMutableArray* dataSource;
    NSURLConnection* getUsersConnection;
    NSString* lastRequestConditions;
    NSDictionary* currentUser;
}


-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if([[segue identifier]isEqualToString:@"imagesSeg"])
    {
        UserGalleryTableViewController* dst = (UserGalleryTableViewController*)[segue destinationViewController];
        [dst setUserID:[[dataSource objectAtIndex:[self.tableView.indexPathForSelectedRow row]] objectForKey:@"userID"]];
        [dst setUserName:[[dataSource objectAtIndex:[self.tableView.indexPathForSelectedRow row]] objectForKey:@"username"]];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    dataSource = [[NSMutableArray alloc]init];
    currentUser = [[[NSUserDefaults standardUserDefaults]objectForKey:@"currentUser"] objectForKey:@"0"];
    CGRect frame = [self.upperView frame];
    frame.size.height = 86;
    [self.upperView setFrame:frame];
    
    CGRect frame2 = [self.tableView frame];
    frame2.origin.y = frame.origin.y + frame.size.height;
    [self.tableView setFrame:frame2];
    
    self.refreshControl = [[UIRefreshControl alloc] init];
    self.refreshControl.backgroundColor = [UIColor purpleColor];
    self.refreshControl.tintColor = [UIColor whiteColor];
    [self.refreshControl addTarget:self
                            action:@selector(getUsers)
                  forControlEvents:UIControlEventValueChanged];

    
    [self getUsers];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    // If you want your BarButtonItem to handle touch event and click, use a UIButton as customView
    UIButton *customButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 70, 20)];
    // Add your action to your button
    [customButton addTarget:self action:@selector(showChatHistory:) forControlEvents:UIControlEventTouchUpInside];
    // Customize your button as you want, with an image if you have a pictogram to display for example
    //[customButton setImage:[UIImage imageNamed:@"online-icon.png"] forState:UIControlStateNormal];
    
    [customButton setTitle:@"محادثاتي" forState:UIControlStateNormal];
    [customButton setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    
    BBBadgeBarButtonItem *barButton = [[BBBadgeBarButtonItem alloc] initWithCustomUIButton:customButton];
    // Set a value for the badge
    [barButton setShouldAnimateBadge:YES];
    barButton.badgeValue = @"2";
    
    barButton.badgeOriginX = 63;
    barButton.badgeOriginY = -9;
    
    // Add it as the leftBarButtonItem of the navigation bar
    self.navigationItem.leftBarButtonItem = barButton;

    
}

-(void)getUsers
{
    [self.refreshControl endRefreshing];

    if([ Reachability isConnected])
    {
        [self showLoadingMode];
        
        responseData = [[NSMutableData alloc]init];
        
        NSString *post = [NSString stringWithFormat:@"userID=%@&female=%i&male=%i&sameCountry=%i&sameCity=%i&online=%i&userCountry=%@&userCity=%@",[currentUser objectForKey:@"userID"],self.womenSwitch.isOn,self.menSwitch.isOn,self.sameCountrySwitch.isOn,self.sameCitySwitch.isOn,self.onlineSwitch.isOn,[currentUser objectForKey:@"userCountry"],[currentUser objectForKey:@"userCity"]];
        if([post isEqualToString:lastRequestConditions])
        {

        }else
        {
            
        }
        NSData *postData = [post dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:NO];
        NSString *postLength = [NSString stringWithFormat:@"%lu", (unsigned long)[post length]];
        
        NSURL *url = [NSURL URLWithString:@"http://moh2013.com/arabDevs/arabchat/getUsers.php"];
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:90.0];
        [request setHTTPMethod:@"POST"];
        
        [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
        
        [request setHTTPBody:postData];
        
        getUsersConnection = [[NSURLConnection alloc]initWithRequest:request delegate:self    startImmediately:NO];
        
        [getUsersConnection scheduleInRunLoop:[NSRunLoop mainRunLoop]
                                         forMode:NSDefaultRunLoopMode];
        [getUsersConnection start];
        
    }else
    {
        [self.view makeToast:@"عذراً. يجب أن تكون متصلاً بالإنترنت" duration:5.0 position:@"bottom"];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [dataSource count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString* identifier = @"userCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier forIndexPath:indexPath];
    
    
    if(!cell)
    {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
    }
    
    
    NSDictionary* cellUser = [dataSource objectAtIndex:indexPath.row];
    
    

    if([[cellUser objectForKey:@"online"] intValue] == 1)
    {
        [(UIImageView*)[cell viewWithTag:6] setImage:[UIImage imageNamed:@"online-icon.png"]];
    }else
    {
        [(UIImageView*)[cell viewWithTag:6] setImage:[UIImage imageNamed:@"online-red-icon.png"]];
    }
    

    
    NSDate* currentDate = [NSDate date];
    NSDate* birthDate = [NSDate dateWithTimeIntervalSince1970:[[cellUser objectForKey:@"birthday"] floatValue]];
    NSCalendar* calendar = [NSCalendar currentCalendar];
    unsigned int unitFlags = NSYearCalendarUnit;
    NSDateComponents *conversionInfo = [calendar components:unitFlags fromDate:birthDate   toDate:currentDate  options:0];
    int year = (int)[conversionInfo year];

    
    NSString* gender = ([[cellUser objectForKey:@"gender"] intValue]==1)?@"رجل":@"أنثى";
    
    [(UILabel*)[cell viewWithTag:1] setText:[cellUser objectForKey:@"username"]];
    [(UILabel*)[cell viewWithTag:2] setText:[NSString stringWithFormat:@"%@ : %i",@"العمر",year]];
    [(UILabel*)[cell viewWithTag:3] setText:[NSString stringWithFormat:@"%@ : %@",@"الجنس",gender]];
    [(UILabel*)[cell viewWithTag:4] setText:[NSString stringWithFormat:@"%@ : %@ - %@",@"العنوان",[cellUser objectForKey:@"userCountry"],[cellUser objectForKey:@"userCity"]]];
    [(UITextView*)[cell viewWithTag:7] setText:[NSString stringWithFormat:@"%@ : %@",@"الوصف",[cellUser objectForKey:@"status"]]];
    [(NZCircularImageView*)[cell viewWithTag:5] setImageWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@%@",@"http://moh2013.com/arabDevs/arabchat/images/",[cellUser objectForKey:@"profilePic"]]] placeholderImage:[UIImage imageNamed:@"loading.png"] usingActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    
    return cell;
}


-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UIActionSheet* sheet = [[UIActionSheet alloc] initWithTitle:@"الخيارات" delegate:self cancelButtonTitle:@"إلغاء" destructiveButtonTitle:@"مراسلة" otherButtonTitles:@"الصور", nil];
    [sheet setTag:1];
    
    [sheet showInView:self.view];
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
- (IBAction)switchValueChanged:(UISwitch*)sender {
    
    
    if(!self.menSwitch.isOn && !self.womenSwitch.isOn)
    {
        [sender setOn:YES animated:YES];
    }else if(sender == self.sameCountrySwitch && !self.sameCountrySwitch.isOn)
    {
        [self.sameCitySwitch setOn:NO animated:YES];
    }
    
    [self getUsers];
}


#pragma mark Connection Delegate
-(void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    if(connection == getUsersConnection)
    {
        [self hideLoadingMode];

        NSError* error;
        dataSource = [[NSMutableArray alloc]initWithArray:[NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingAllowFragments error:&error]];
        
        //[dataSource addObjectsFromArray:newUsers];
        
        [self.tableView reloadData];
        [self.tableView setNeedsDisplay];
    }
}


-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    if(connection == getUsersConnection)
    {
        [responseData appendData:data];
    }
}


#pragma mark action sheet delegate
-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if(actionSheet.tag == 1 && actionSheet.cancelButtonIndex != buttonIndex)
    {
        if(buttonIndex == 0)
        {
            
        }else if(buttonIndex == 1)
        {
            [self performSegueWithIdentifier:@"imagesSeg" sender:self];
        }
    }else if(actionSheet.tag == 2 && actionSheet.cancelButtonIndex != buttonIndex)
    {
        if(buttonIndex == 0)
        {
            [self performSegueWithIdentifier:@"myProgileSeg" sender:self];
        }else if(buttonIndex == 1)
        {
            [[NSUserDefaults standardUserDefaults]setBool:NO forKey:@"rememberME"];
            [[NSUserDefaults standardUserDefaults]synchronize];
            [self.navigationController popViewControllerAnimated:YES];
        }
    }
}


#pragma mark action outlet
- (IBAction)optionsButtonSelected:(id)sender {
    UIActionSheet* sheet = [[UIActionSheet alloc]initWithTitle:@"خيارات" delegate:self cancelButtonTitle:@"إلغاء" destructiveButtonTitle:nil otherButtonTitles:@"بروفايلي",@"تسجيل خروج", nil];
    [sheet setTag:2];
    
    [sheet showInView:self.view];
}

- (void)showChatHistory:(UIButton *)sender
{
    NSLog(@"Bar Button Item Pressed");
    
    // Pretend user checked its list, remove badge
    BBBadgeBarButtonItem *barButton = (BBBadgeBarButtonItem *)self.navigationItem.leftBarButtonItem;
    barButton.badgeValue = @"3";
    
    // If you don't want to remove the badge when it's zero just set
    barButton.shouldHideBadgeAtZero = NO;
    // Next time zero should still be displayed
    
    // You can customize the badge further (color, font, background), check BBBadgeBarButtonItem.h ;)
}

@end
