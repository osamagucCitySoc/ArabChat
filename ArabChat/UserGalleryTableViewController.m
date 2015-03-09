//
//  UserGalleryTableViewController.m
//  ArabChat
//
//  Created by Osama Rabie on 3/9/15.
//  Copyright (c) 2015 Osama Rabie. All rights reserved.
//

#import "UserGalleryTableViewController.h"
#import "Reachability.h"
#import "NZCircularImageView.h"
#import "UIView+Toast.h"
#import "MZLoadingCircle.h"
#import "AsyncImageView.h"

@interface UserGalleryTableViewController ()<NSURLConnectionDataDelegate,NSURLConnectionDelegate>

@end

@implementation UserGalleryTableViewController
{
    MZLoadingCircle *loadingCircle;
    NSMutableData* responseData;
    NSMutableArray* dataSource;
    NSURLConnection* getImagesConnection;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setTitle:[NSString stringWithFormat:@"%@ %@",@"صور",self.userName]];
    
    [self loadImages];
}



-(void)loadImages
{
    [self.refreshControl endRefreshing];
    
    if([ Reachability isConnected])
    {
        [self showLoadingMode];
        
        responseData = [[NSMutableData alloc]init];
        
        NSString *post = [NSString stringWithFormat:@"userID=%@",self.userID];
        
       
        NSData *postData = [post dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:NO];
        NSString *postLength = [NSString stringWithFormat:@"%lu", (unsigned long)[post length]];
        
        NSURL *url = [NSURL URLWithString:@"http://moh2013.com/arabDevs/arabchat/getUserInfo.php"];
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:90.0];
        [request setHTTPMethod:@"POST"];
        
        [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
        
        [request setHTTPBody:postData];
        
        getImagesConnection = [[NSURLConnection alloc]initWithRequest:request delegate:self    startImmediately:NO];
        
        [getImagesConnection scheduleInRunLoop:[NSRunLoop mainRunLoop]
                                      forMode:NSDefaultRunLoopMode];
        [getImagesConnection start];
        
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

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 400;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString* identifier = @"galleryCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier forIndexPath:indexPath];
    
    if(cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
    }
    

    NSURL* url = [[NSURL alloc] initWithString:[NSString stringWithFormat:@"%@%@",@"http://moh2013.com/arabDevs/arabchat/images/",[[dataSource objectAtIndex:indexPath.row] objectForKey:@"photo"]]];
    
    [(NZCircularImageView*) [cell viewWithTag:1] setImageWithURL:url placeholderImage:[UIImage imageNamed:@"loading.png"] usingActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
   
    return cell;
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
    if(connection == getImagesConnection)
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
    if(connection == getImagesConnection)
    {
        [responseData appendData:data];
    }
}



@end
