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
#import "STBubbleTableViewCellDemoViewController.h"
#import "ChatThreadViewController.h"

@interface UserGalleryTableViewController ()<NSURLConnectionDataDelegate,NSURLConnectionDelegate,UIImagePickerControllerDelegate,UINavigationControllerDelegate,UIActionSheetDelegate>

@property (weak, nonatomic) IBOutlet UIBarButtonItem *rightBarButton;

@end

@implementation UserGalleryTableViewController
{
    MZLoadingCircle *loadingCircle;
    NSMutableData* responseData;
    NSMutableArray* dataSource;
    NSURLConnection* getImagesConnection;
    UIImagePickerController *imagePicker;
    UIImage* addedImage;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setTitle:[NSString stringWithFormat:@"%@ %@",@"صور",self.userName]];
    
    
        if([[[[[NSUserDefaults standardUserDefaults] objectForKey:@"currentUser"] objectForKey:@"0"] objectForKey:@"userID"]isEqualToString:self.userID])
        {
            [self.rightBarButton setTitle:@"صورة جديدة"];
            [self.tableView setEditing:YES animated:YES];
        }
    
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

-(BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [[[[[NSUserDefaults standardUserDefaults] objectForKey:@"currentUser"] objectForKey:@"0"] objectForKey:@"userID"]isEqualToString:self.userID];
}


- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        
        [self showLoadingMode];
        
        NSString *post = [NSString stringWithFormat:@"userID=%@&photo=%@",self.userID,[[dataSource objectAtIndex:indexPath.row] objectForKey:@"photo"]];
        
        NSData *postData = [post dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:NO];
        NSString *postLength = [NSString stringWithFormat:@"%lu", (unsigned long)[post length]];
        
        NSURL *url = [NSURL URLWithString:@"http://moh2013.com/arabDevs/arabchat/deletePhoto.php"];
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:90.0];
        [request setHTTPMethod:@"POST"];
        
        [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
        
        [request setHTTPBody:postData];
    
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil];
            dispatch_async(dispatch_get_main_queue(), ^(void) {
                [self hideLoadingMode];
                [self hideLoadingMode];
                [dataSource removeObjectAtIndex:indexPath.row];
                [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
                [self.tableView setEditing:YES animated:YES];
            });
        });

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
-(void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    if(connection == getImagesConnection)
    {
        [self hideLoadingMode];
        
        NSError* error;
        dataSource = [[NSMutableArray alloc]initWithArray:[NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingAllowFragments error:&error]];
        
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

- (IBAction)rightBarButtonClicked:(id)sender {
    if([[[[[NSUserDefaults standardUserDefaults] objectForKey:@"currentUser"] objectForKey:@"0"] objectForKey:@"userID"]isEqualToString:self.userID])
    {
        UIActionSheet* sheet = [[UIActionSheet alloc]initWithTitle:@"خيارات الصورة" delegate:self cancelButtonTitle:@"إلغاء" destructiveButtonTitle:nil otherButtonTitles:@"الكاميرا",@"معرض الصور", nil];
        [sheet setTag:1];
    
        [sheet showInView:self.view];
    }else
    {
        UIImage* image = [(NZCircularImageView*)[[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:dataSource.count-1 inSection:0]] viewWithTag:1] image];
        
        ChatThreadViewController *demoViewController = [ChatThreadViewController new];
        demoViewController.FRDID = self.userID;
        demoViewController.FRDIMG = image;
        demoViewController.FRDNAME = self.userName;
        demoViewController.FRDPIC = [[dataSource lastObject]objectForKey:@"photo"];
        [self.navigationController pushViewController:demoViewController animated:YES];
    }

}



#pragma mark action sheet delegate
-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if(actionSheet.tag == 1 && actionSheet.cancelButtonIndex != buttonIndex)
    {
        if(buttonIndex == 0)
        {
            imagePicker=[[UIImagePickerController alloc]init];
            imagePicker.sourceType=UIImagePickerControllerSourceTypeCamera;
            imagePicker.showsCameraControls=YES;
            imagePicker.allowsEditing=YES;
            imagePicker.delegate=self;
            [self presentViewController:imagePicker animated:YES completion:nil];
        }else if(buttonIndex == 1)
        {
            imagePicker=[[UIImagePickerController alloc]init];
            imagePicker.sourceType=UIImagePickerControllerSourceTypePhotoLibrary;
            imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
            imagePicker.allowsEditing=YES;
            imagePicker.delegate=self;
            [self presentViewController:imagePicker animated:YES completion:nil];
        }
    }
        
}

- (void)imagePickerController:(UIImagePickerController *)picker  didFinishPickingMediaWithInfo:(NSDictionary *)info {
    [picker dismissViewControllerAnimated:YES completion:nil];
    
    UIImage *originalImage=[info objectForKey:UIImagePickerControllerOriginalImage];
    
    //Do whatever with your image
    NSData *dataImage = UIImageJPEGRepresentation (originalImage,0.1);
    addedImage=[UIImage imageWithData:dataImage];
    
    [self uploadImage:dataImage userID:self.userID];
}



-(void)uploadImage:(NSData*)imageData userID:(NSString*)userID{
    
    [self.tableView setEditing:NO animated:YES];
    [self showLoadingMode];
    NSString *urlString = @"http://moh2013.com/arabDevs/arabchat/uploadImageForUserGallery.php";
    NSString* username = [NSString stringWithFormat:@"%@",userID];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setURL:[NSURL URLWithString:urlString]];
    [request setHTTPMethod:@"POST"];
    
    NSString *boundary = @"---------------------------14737809831466499882746641449";
    NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@",boundary];
    [request addValue:contentType forHTTPHeaderField: @"Content-Type"];
    
    NSMutableData *body = [NSMutableData data];
    [body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"uploadedfile\"; filename=\"%@.png\"\r\n",username] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[@"Content-Type: application/octet-stream\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[NSData dataWithData:imageData]];
    [body appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [request setHTTPBody:body];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        NSData *printData=[NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil];
        NSString* filePath = [[NSString alloc] initWithData:printData encoding:NSUTF8StringEncoding];
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            [self hideLoadingMode];
            [self hideLoadingMode];
            [dataSource addObject:[[NSDictionary alloc] initWithObjects:@[filePath] forKeys:@[@"photo"]]];
            [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:self->dataSource.count - 1 inSection:0]] withRowAnimation:UITableViewRowAnimationLeft];
            [self.tableView setEditing:YES animated:YES];
        });
    });
}

@end
