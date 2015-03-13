//
//  ChatHistoryTableViewController.m
//  ArabChat
//
//  Created by Osama Rabie on 3/10/15.
//  Copyright (c) 2015 Osama Rabie. All rights reserved.
//

#import "ChatHistoryTableViewController.h"
#import "DatabaseController.h"
#import "NZCircularImageView.h"
#import "Reachability.h"
#import "UIView+Toast.h"
#import "MZLoadingCircle.h"
#import "STBubbleTableViewCellDemoViewController.h"
#import "ChatThreadViewController.h"

@interface ChatHistoryTableViewController ()

@end

@implementation ChatHistoryTableViewController
{
    MZLoadingCircle *loadingCircle;
    NSMutableArray* dataSource;
    DatabaseController* dbController;
    NSDictionary* currentUser;
    BOOL photosSynced;
    int running;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    currentUser = [[[NSUserDefaults standardUserDefaults]objectForKey:@"currentUser"]objectForKey:@"0"];
    
    dataSource = [[NSMutableArray alloc]init];
    
    dbController = [[DatabaseController alloc]init];
    
    [dbController createDatabaseIfNotExists];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    dataSource = [dbController loadTopLevelThreads];
    
    [self.tableView reloadData];
    [self.tableView setNeedsDisplay];

    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receiveMessageNotification:)
                                                 name:@"newMessage"
                                               object:nil];

    if([ Reachability isConnected])
    {
        [self showLoadingMode];
        if(!photosSynced)
        {
            photosSynced = YES;
            running = 2;
            [self syncPhotos];
            [self syncMessages];
        }else
        {
            running = 1;
            [self syncMessages];
        }
    }else
    {
        [self.view makeToast:@"عذراً. يجب أن تكون متصلاً بالإنترنت" duration:5.0 position:@"bottom"];
    }

}

- (void) receiveMessageNotification:(NSNotification *) notification
{
    dataSource = [dbController loadTopLevelThreads];
    [self.tableView reloadData];
    [self.tableView setNeedsDisplay];
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void)syncPhotos
{
    
    NSString *post = [NSString stringWithFormat:@"userIDs=%@",[dbController loadUniqueFriendIDs]];
    
    NSData *postData = [post dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:NO];
    NSString *postLength = [NSString stringWithFormat:@"%lu", (unsigned long)[post length]];
    
    NSURL *url = [NSURL URLWithString:@"http://moh2013.com/arabDevs/arabchat/updatePhotos.php"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:90.0];
    [request setHTTPMethod:@"POST"];
    
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    
    [request setHTTPBody:postData];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSData* data = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil];
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            
            NSError* error;
            
            NSArray* photos = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&error];
            
            
            for(NSDictionary* dict in photos)
            {
                [dbController updatePhoto:[dict objectForKey:@"userID"] FRDIMG:[dict objectForKey:@"photo"] FRDONLINE:[[dict objectForKey:@"online"] intValue]];
            }
            
            running--;
            if(running<=0)
            {
                [self hideLoadingMode];
                [self hideLoadingMode];
            }
            
            
        });
    });
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
            
            dataSource = [dbController loadTopLevelThreads];
            
            [self.tableView reloadData];
            [self.tableView setNeedsDisplay];
            running--;
            if(running<=0)
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
    
    static NSString* identifier = @"ChatHistoryCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier forIndexPath:indexPath];
    
    if(!cell)
    {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
    }
    
    
    
    NSDictionary* cellUser = [dataSource objectAtIndex:indexPath.row];
    
    
    [(UILabel*)[cell viewWithTag:1] setText:[cellUser objectForKey:@"FRDNAME"]];
    [(UILabel*)[cell viewWithTag:2] setText:[cellUser objectForKey:@"MSG"]];
    //[(UILabel*)[cell viewWithTag:3] setText:[cellUser objectForKey:@"WHENN"]];
    
    if([[cellUser objectForKey:@"ONLINE"] intValue] == 1)
    {
        [(UIImageView*)[cell viewWithTag:5] setImage:[UIImage imageNamed:@"online-icon.png"]];
    }else
    {
        [(UIImageView*)[cell viewWithTag:5] setImage:[UIImage imageNamed:@"online-red-icon.png"]];
    }
    
    
    [(NZCircularImageView*)[cell viewWithTag:4] setImageWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@%@",@"http://moh2013.com/arabDevs/arabchat/images/",[cellUser objectForKey:@"FRDIMG"]]] placeholderImage:[UIImage imageNamed:@"loading.png"] usingActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    
    return cell;
}


-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UIImage* image = [(NZCircularImageView*)[[tableView cellForRowAtIndexPath:indexPath] viewWithTag:4] image];
    
    ChatThreadViewController *demoViewController = [ChatThreadViewController new];
    demoViewController.FRDID = [[dataSource objectAtIndex:indexPath.row] objectForKey:@"FRDID"];
    demoViewController.FRDIMG = image;
    demoViewController.FRDNAME =[[dataSource objectAtIndex:indexPath.row] objectForKey:@"FRDNAME"];
    demoViewController.FRDPIC = [[dataSource objectAtIndex:indexPath.row] objectForKey:@"FRDIMG"];
    [self.navigationController pushViewController:demoViewController animated:YES];
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


@end
