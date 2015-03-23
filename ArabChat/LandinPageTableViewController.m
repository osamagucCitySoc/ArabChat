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
#import "DatabaseController.h"
#import <AudioToolbox/AudioToolbox.h>
#import "STBubbleTableViewCellDemoViewController.h"
#import "ChatThreadViewController.h"

@interface LandinPageTableViewController ()<NSURLConnectionDataDelegate,NSURLConnectionDelegate,UIActionSheetDelegate>

@property (weak, nonatomic) IBOutlet UIView *upperView;

@end

@implementation LandinPageTableViewController
{
    MZLoadingCircle *loadingCircle;
    NSMutableData* responseData;
    NSMutableArray* dataSource;
    NSURLConnection* getUsersConnection;
    NSString* lastRequestConditions;
    DatabaseController* dbController;
    NSDictionary* currentUser;
    BBBadgeBarButtonItem *barButton;
    SystemSoundID mySound;
    int running;
    NSIndexPath* selectedIndex;
}


-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if([[segue identifier]isEqualToString:@"imagesSeg"])
    {
        UserGalleryTableViewController* dst = (UserGalleryTableViewController*)[segue destinationViewController];
        [dst setUserID:[[dataSource objectAtIndex:selectedIndex.row] objectForKey:@"userID"]];
        [dst setUserName:[[dataSource objectAtIndex:selectedIndex.row] objectForKey:@"username"]];
    }
}

-(void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    barButton.badgeValue = @"0";
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receiveMessageNotification:)
                                                 name:@"newMessage"
                                               object:nil];
    if([[NSUserDefaults standardUserDefaults]objectForKey:@"newMessages"])
    {
        barButton.badgeValue = [[NSUserDefaults standardUserDefaults]objectForKey:@"newMessages"];
        [[NSUserDefaults standardUserDefaults]setObject:@"0" forKey:@"newMessages"];
        [[NSUserDefaults standardUserDefaults]synchronize];
    }
}


-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void) receiveMessageNotification:(NSNotification *) notification
{
    barButton.badgeValue = [[NSUserDefaults standardUserDefaults]objectForKey:@"newMessages"];
    [[NSUserDefaults standardUserDefaults]setObject:@"0" forKey:@"newMessages"];
    [[NSUserDefaults standardUserDefaults]synchronize];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    dbController = [[DatabaseController alloc]init];
    
    [dbController createDatabaseIfNotExists];
    
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
    
    
    // If you want your BarButtonItem to handle touch event and click, use a UIButton as customView
    UIButton *customButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 70, 20)];
    // Add your action to your button
    [customButton addTarget:self action:@selector(showChatHistory:) forControlEvents:UIControlEventTouchUpInside];
    // Customize your button as you want, with an image if you have a pictogram to display for example
    //[customButton setImage:[UIImage imageNamed:@"online-icon.png"] forState:UIControlStateNormal];
    
    [customButton setTitle:@"محادثاتي" forState:UIControlStateNormal];
    
    barButton = [[BBBadgeBarButtonItem alloc] initWithCustomUIButton:customButton];
    // Set a value for the badge
    [barButton setShouldAnimateBadge:YES];
    [barButton setShouldHideBadgeAtZero:YES];
    barButton.badgeValue = @"0";
    
    barButton.badgeOriginX = 63;
    barButton.badgeOriginY = -9;
    
    
    [self getUsers];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    
    
    // Add it as the leftBarButtonItem of the navigation bar
    self.navigationItem.leftBarButtonItem = barButton;
    
    
    
}

-(void)getUsers
{
    running = 2;
    [self.refreshControl endRefreshing];
    
    if([ Reachability isConnected])
    {
        [self showLoadingMode];
        
        [self syncMessages];
        
        responseData = [[NSMutableData alloc]init];
        
        NSString *post = [NSString stringWithFormat:@"userID=%@&female=%i&male=%i&sameCountry=%i&sameCity=%i&online=%i&userCountry=%@&userCity=%@",[currentUser objectForKey:@"userID"],[[NSUserDefaults standardUserDefaults] boolForKey:@"womenVal"],[[NSUserDefaults standardUserDefaults] boolForKey:@"menVal"],[[NSUserDefaults standardUserDefaults] boolForKey:@"countryVal"],[[NSUserDefaults standardUserDefaults] boolForKey:@"cityVal"],[[NSUserDefaults standardUserDefaults] boolForKey:@"onlineVal"],[currentUser objectForKey:@"userCountry"],[currentUser objectForKey:@"userCity"]];
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


-(void)syncMessages
{
    NSString *post = [NSString stringWithFormat:@"userID=%@",[currentUser objectForKey:@"userID"]];
    
    NSData *postData = [post dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:NO];
    NSString *postLength = [NSString stringWithFormat:@"%lu", (unsigned long)[post length]];
    
    NSURL *url = [NSURL URLWithString:@"http://moh2013.com/arabDevs/arabchat/getNewMessages.php"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:90.0];
    [request setHTTPMethod:@"POST"];
    
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    
    [request setHTTPBody:postData];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSData* data = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil];
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            
            NSError* error;
            
            NSArray* messages = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&error];
            
            
            for(NSDictionary* dict in messages)
            {
                [dbController insertNewChatRecord:[dict objectForKey:@"FRDID"] FRDNAME:[dict objectForKey:@"FRDNAME"] FRDIMG:[dict objectForKey:@"FRDIMG"] MSG:[dict objectForKey:@"MSG"] SENT:0 STATUS:[dict objectForKey:@"STATUS"] WHENN:[[dict objectForKey:@"WHENN"] doubleValue]ONLINE:[[dict objectForKey:@"ONLINE"] intValue]];
            }
            
            if(messages.count>0)
            {
                SystemSoundID completeSound;
                NSURL *audioPath = [[NSBundle mainBundle] URLForResource:@"water" withExtension:@"aiff"];
                AudioServicesCreateSystemSoundID((__bridge CFURLRef)audioPath, &completeSound);
                AudioServicesPlaySystemSound (completeSound);
            }
            [barButton setShouldAnimateBadge:YES];
            [barButton setShouldHideBadgeAtZero:YES];
            
            
            if([[NSUserDefaults standardUserDefaults] objectForKey:@"newMessages"])
            {
                barButton.badgeValue = [NSString stringWithFormat:@"%i",[[[NSUserDefaults standardUserDefaults] objectForKey:@"newMessages"]intValue] + (int)messages.count];
            }else
            {
                barButton.badgeValue = [NSString stringWithFormat:@"%i",(int)messages.count];
            }
            
            
            [[NSUserDefaults standardUserDefaults]setObject:@"0" forKey:@"newMessages"];
            [[NSUserDefaults standardUserDefaults]synchronize];
            
            running--;
            if(running <= 0)
            {
                [self hideLoadingMode];
                [self hideLoadingMode];
            }
            
        });
    });
    
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
    
    [cell viewWithTag:5].clipsToBounds = YES;
    
    [cell viewWithTag:5].layer.cornerRadius = 44;
    [cell viewWithTag:5].layer.borderWidth = 2;
    
    [cell viewWithTag:10].clipsToBounds = YES;
    
    [cell viewWithTag:10].layer.cornerRadius = 10;
    
    if([[cellUser objectForKey:@"online"] intValue] == 1)
    {
        [(UIImageView*)[cell viewWithTag:6] setImage:[UIImage imageNamed:@"online-icon.png"]];
        [[[cell viewWithTag:5] layer] setBorderColor:[UIColor colorWithRed:72.0/255 green:149.0/255 blue:67.0/255 alpha:1.0].CGColor];
        [(UILabel*)[cell viewWithTag:10] setBackgroundColor:[UIColor colorWithRed:72.0/255 green:149.0/255 blue:67.0/255 alpha:1.0]];
        [(UILabel*)[cell viewWithTag:10] setText: @"        أون لاين"];
    }else
    {
        [(UIImageView*)[cell viewWithTag:6] setImage:[UIImage imageNamed:@"online-red-icon.png"]];
        [[[cell viewWithTag:5] layer] setBorderColor:[UIColor lightGrayColor].CGColor];
        [(UILabel*)[cell viewWithTag:10] setBackgroundColor:[UIColor lightGrayColor]];
        [(UILabel*)[cell viewWithTag:10] setText: @"        أوف لاين"];
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
    
    UIImageView *theBack = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"select-img.png"]];
    theBack.backgroundColor = [UIColor clearColor];
    theBack.opaque = NO;
    cell.selectedBackgroundView = theBack;
    
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

#pragma mark Connection Delegate
-(void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    if(connection == getUsersConnection)
    {
        running--;
        if(running<=0)
        {
            [self hideLoadingMode];
        }
        
        NSError* error;
        dataSource = [[NSMutableArray alloc]initWithArray:[NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingAllowFragments error:&error]];
        
        //[dataSource addObjectsFromArray:newUsers];
        
        [self.tableView reloadData];
        [self.tableView setNeedsDisplay];
        
        if (dataSource.count == 0)
        {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"لايوجد نتائج" delegate:nil cancelButtonTitle:nil otherButtonTitles:@"تم", nil];
            [alert show];
        }
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
    selectedIndex = self.tableView.indexPathForSelectedRow;
    [self.tableView deselectRowAtIndexPath:self.tableView.indexPathForSelectedRow animated:YES];
    if(actionSheet.tag == 1 && actionSheet.cancelButtonIndex != buttonIndex)
    {
        if(buttonIndex == 0)
        {
            UIImage* image = [(NZCircularImageView*)[[self.tableView cellForRowAtIndexPath:self.tableView.indexPathForSelectedRow] viewWithTag:5] image];
            
            ChatThreadViewController *demoViewController = [ChatThreadViewController new];
            demoViewController.FRDID = [[dataSource objectAtIndex:self->selectedIndex.row] objectForKey:@"userID"];
            demoViewController.FRDIMG = image;
            demoViewController.FRDNAME = [[dataSource objectAtIndex:self->selectedIndex.row] objectForKey:@"username"];
            demoViewController.FRDPIC = [[dataSource objectAtIndex:self->selectedIndex.row] objectForKey:@"profilePic"];
            [self.navigationController pushViewController:demoViewController animated:YES];
            
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
            [[self navigationController] popViewControllerAnimated:YES];
        }
        else if (buttonIndex == 2)
        {
            [[NSUserDefaults standardUserDefaults]setBool:NO forKey:@"rememberME"];
            [[NSUserDefaults standardUserDefaults]synchronize];
            [self.navigationController popToRootViewControllerAnimated:YES];
        }
    }
}


#pragma mark action outlet
- (IBAction)optionsButtonSelected:(id)sender {
    UIActionSheet* sheet = [[UIActionSheet alloc]initWithTitle:@"خيارات" delegate:self cancelButtonTitle:@"إلغاء" destructiveButtonTitle:nil otherButtonTitles:@"بروفايلي",@"بحث جديد",@"تسجيل خروج", nil];
    [sheet setTag:2];
    [sheet setDestructiveButtonIndex:2];
    [sheet showInView:self.view];
}

- (void)showChatHistory:(UIButton *)sender
{
    [self performSegueWithIdentifier:@"chatHistorySeg" sender:self];
}

@end
