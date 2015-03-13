//
//  HomeViewController.m
//  ArabChat
//
//  Created by Osama Rabie on 3/8/15.
//  Copyright (c) 2015 Osama Rabie. All rights reserved.
//

#import "MyProfileViewController.h"
#import "MZLoadingCircle.h"
#import "Reachability.h"
#import "UIView+Toast.h"
#import "NZCircularImageView.h"
#import "UserGalleryTableViewController.h"

@interface MyProfileViewController ()<UIPickerViewDataSource,UIPickerViewDelegate,NSURLConnectionDataDelegate,NSURLConnectionDelegate,UIImagePickerControllerDelegate,UINavigationControllerDelegate,UIActionSheetDelegate>

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIButton *registerButton;
@property (weak, nonatomic) IBOutlet UIPickerView *countryCityPickerView;
@property (weak, nonatomic) IBOutlet UIDatePicker *datePicker;
@property (weak, nonatomic) IBOutlet UISwitch *girlSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *boySwitch;
@property (weak, nonatomic) IBOutlet UITextField *statusMessageTextField;
@property (weak, nonatomic) IBOutlet NZCircularImageView *profilePicture;

@end

@implementation MyProfileViewController
{
    MZLoadingCircle *loadingCircle;
    NSURLConnection* getCountriesCitiesConnection;
    NSURLConnection* editConnection;
    NSURLConnection* uploadImageForUserConnection;
    NSMutableData* responseData;
    NSDictionary* countriesCitiesDataSource;
    UIImagePickerController *imagePicker;
    NSDictionary* currentUser;
    NSMutableArray* photos;
}


-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if([[segue identifier]isEqualToString:@"myPicsSeg"])
    {
        UserGalleryTableViewController* dst = (UserGalleryTableViewController*)[segue destinationViewController];
        [dst setUserID:[currentUser objectForKey:@"userID"]];
        [dst setUserName:[currentUser objectForKey:@"username"]];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    countriesCitiesDataSource = [[NSDictionary alloc]init];
    
    [self initUI];
}



-(void)initUI
{
    
    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(singleTapGestureCaptured:)];
    [self.scrollView addGestureRecognizer:singleTap];
   
    currentUser = [[[NSUserDefaults standardUserDefaults]objectForKey:@"currentUser"] objectForKey:@"0"];
    photos = [[NSMutableArray alloc]initWithArray:[[[NSUserDefaults standardUserDefaults] objectForKey:@"currentUser"] objectForKey:@"photos"]];
    
    
    
    if([ Reachability isConnected])
    {
        [self showLoadingMode];
        [self.profilePicture setImageWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@%@",@"http://moh2013.com/arabDevs/arabchat/images/",[currentUser objectForKey:@"profilePic"]]] placeholderImage:[UIImage imageNamed:@"loading.png"] usingActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];

        [self getCountries];
    }else
    {
        [self.view makeToast:@"عذراً. يجب أن تكون متصلاً بالإنترنت" duration:5.0 position:@"bottom"];
    }
}

-(void)getCountries
{
    NSString *post = @"";
    NSData *postData = [post dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:NO];
    NSString *postLength = [NSString stringWithFormat:@"%lu", (unsigned long)[post length]];
    
    NSURL *url = [NSURL URLWithString:@"http://moh2013.com/arabDevs/arabchat/CountriesCities.php"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:90.0];
    [request setHTTPMethod:@"POST"];
    
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    
    [request setHTTPBody:postData];
    
    responseData = [[NSMutableData alloc]init];
    
    getCountriesCitiesConnection = [[NSURLConnection alloc]initWithRequest:request delegate:self    startImmediately:NO];
    
    [getCountriesCitiesConnection scheduleInRunLoop:[NSRunLoop mainRunLoop]
                                            forMode:NSDefaultRunLoopMode];
    [getCountriesCitiesConnection start];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.scrollView setContentSize:CGSizeMake(self.view.frame.size.width, self.registerButton.frame.origin.y+15+self.registerButton.frame.size.height)];
    [self.scrollView setScrollEnabled:YES];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark action outlets
- (IBAction)selectorChanged:(UISwitch*)sender {
    if(!self.girlSwitch.isOn && !self.boySwitch.isOn)
    {
        [sender setOn:YES animated:YES];
    }else
    {
        if(sender == self.boySwitch)
        {
            [self.girlSwitch setOn:NO animated:YES];
        }else
        {
            [self.boySwitch setOn:NO animated:YES];
        }
    }
}
- (IBAction)myPicsClicked:(id)sender {
    [self performSegueWithIdentifier:@"myPicsSeg" sender:self];
}

- (IBAction)registerButtonClicked:(id)sender {
    
    [[self view] endEditing:YES];
    [[self scrollView] endEditing:YES];
    
    if(![ Reachability isConnected])
    {
        [self.view makeToast:@"عذراً. يجب أن تكون متصلاً بالإنترنت" duration:5.0 position:@"bottom"];
    }else if(self.statusMessageTextField.text.length < 1)
    {
        [self.view makeToast:@"عذراً. كل البيانات مطلوبة" duration:5.0 position:@"bottom"];
    }else
    {
        [self showLoadingMode];
        int gender = 1;
        if(self.boySwitch.isOn)
        {
            gender = 1;
        }else
        {
            gender = 2;
        }
        
        NSArray* sortedArray = [[countriesCitiesDataSource allKeys] sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            return [(NSString *)obj1 compare:(NSString *)obj2 options:NSNumericSearch];
        }];
        
        
        
        NSString *post = [NSString stringWithFormat:@"userID=%@&status=%@&gender=%i&birthday=%f&country=%@&city=%@&deviceToken=%@",[currentUser objectForKey:@"userID"],self.statusMessageTextField.text,gender,[[self.datePicker date] timeIntervalSince1970],[sortedArray objectAtIndex:[self.countryCityPickerView selectedRowInComponent:0]],[[countriesCitiesDataSource objectForKey:[sortedArray objectAtIndex:[self.countryCityPickerView selectedRowInComponent:0]]] objectAtIndex:[self.countryCityPickerView selectedRowInComponent:1]],[[NSUserDefaults standardUserDefaults] objectForKey:@"deviceToken"]];
        
        NSData *postData = [post dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:NO];
        NSString *postLength = [NSString stringWithFormat:@"%lu", (unsigned long)[post length]];
        
        NSURL *url = [NSURL URLWithString:@"http://moh2013.com/arabDevs/arabchat/editUser.php"];
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:90.0];
        [request setHTTPMethod:@"POST"];
        
        [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
        
        [request setHTTPBody:postData];
        
        responseData = [[NSMutableData alloc]init];
        
        editConnection = [[NSURLConnection alloc]initWithRequest:request delegate:self    startImmediately:NO];
        
        [editConnection scheduleInRunLoop:[NSRunLoop mainRunLoop]
                                      forMode:NSDefaultRunLoopMode];
        [editConnection start];
        
    }
}


- (IBAction)addProfileImageClicked:(id)sender {
    
    UIActionSheet* sheet = [[UIActionSheet alloc]initWithTitle:@"خيارات الصورة" delegate:self cancelButtonTitle:@"إلغاء" destructiveButtonTitle:nil otherButtonTitles:@"الكاميرا",@"معرض الصور", nil];
    [sheet setTag:1];
    
    [sheet showInView:self.view];
}

- (void)imagePickerController:(UIImagePickerController *)picker  didFinishPickingMediaWithInfo:(NSDictionary *)info {
    [picker dismissViewControllerAnimated:YES completion:nil];
    
    UIImage *originalImage=[info objectForKey:UIImagePickerControllerOriginalImage];
    
    //Do whatever with your image
    NSData *dataImage = UIImageJPEGRepresentation (originalImage,0.1);
    UIImage *image=[UIImage imageWithData:dataImage];
    
    [self.profilePicture setImage:image];
    
    [self uploadImage:dataImage userID:[currentUser objectForKey:@"userID"]];
}

#pragma mark picker view delegate
// returns the number of 'columns' to display.
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 2;
}

// returns the # of rows in each component..
- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    if(component == 0)
    {
        return [[countriesCitiesDataSource allKeys] count];
    }else if(component == 1)
    {
        if([self.countryCityPickerView selectedRowInComponent:0]>=0)
        {
            @try {
                NSArray* sortedArray = [[countriesCitiesDataSource allKeys] sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
                    return [(NSString *)obj1 compare:(NSString *)obj2 options:NSNumericSearch];
                }];
                return [[countriesCitiesDataSource objectForKey:[sortedArray objectAtIndex:[self.countryCityPickerView selectedRowInComponent:0]]] count];
            }
            @catch (NSException *exception) {
                return 0;
            }
        }else
        {
            return 0;
        }
    }else
    {
        return 0;
    }
}



- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    if(component == 0)
    {
        NSArray* sortedArray = [[countriesCitiesDataSource allKeys] sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            return [(NSString *)obj1 compare:(NSString *)obj2 options:NSNumericSearch];
        }];
        return [sortedArray objectAtIndex:row];
    }else if(component == 1)
    {
        NSArray* sortedArray = [[countriesCitiesDataSource allKeys] sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            return [(NSString *)obj1 compare:(NSString *)obj2 options:NSNumericSearch];
        }];
        return [[countriesCitiesDataSource objectForKey:[sortedArray objectAtIndex:[self.countryCityPickerView selectedRowInComponent:0]]] objectAtIndex:row];
    }else
    {
        return @"";
    }
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    if(component == 0)
    {
        [self.countryCityPickerView selectRow:0 inComponent:1 animated:YES];
        [self.countryCityPickerView reloadComponent:1];
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
    if(connection == getCountriesCitiesConnection)
    {
        NSError* error;
        
        countriesCitiesDataSource = [NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingAllowFragments error:&error];
        
        [self.countryCityPickerView reloadAllComponents];
        [self.countryCityPickerView setNeedsDisplay];
        
        
        
        [self.statusMessageTextField setText:[currentUser objectForKey:@"status"]];
        [self.datePicker setDate:[NSDate dateWithTimeIntervalSince1970:[[currentUser objectForKey:@"birthday"] longLongValue]] animated:YES];
      
        if([[currentUser objectForKey:@"gender"] intValue] == 1)
        {
            [self.boySwitch setOn:YES animated:YES];
            [self.girlSwitch setOn:NO animated:YES];
        }else
        {
            [self.boySwitch setOn:NO animated:YES];
            [self.girlSwitch setOn:YES animated:YES];
        }
        
        NSArray* sortedArray = [[countriesCitiesDataSource allKeys] sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            return [(NSString *)obj1 compare:(NSString *)obj2 options:NSNumericSearch];
        }];

        for(int i = 0 ; i < [sortedArray count] ; i++)
        {
            if([[currentUser objectForKey:@"userCountry"] isEqualToString:[sortedArray objectAtIndex:i]])
            {
                [self.countryCityPickerView selectRow:i inComponent:0 animated:YES];
                for(int j = 0 ; j < [[countriesCitiesDataSource objectForKey:[currentUser objectForKey:@"userCountry"]] count]; j++)
                {
                    if([[[countriesCitiesDataSource objectForKey:[currentUser objectForKey:@"userCountry"]] objectAtIndex:j]isEqualToString:[currentUser objectForKey:@"userCity"]])
                    {
                        [self.countryCityPickerView selectRow:j inComponent:1 animated:YES];
                        break;
                    }
                }
                break;
            }
        }
        
        
        
        [self hideLoadingMode];
    }
}
-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    if(connection == getCountriesCitiesConnection)
    {
        [responseData appendData:data];
    }else if(connection == editConnection)
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
            [[NSUserDefaults standardUserDefaults]synchronize];
            [self.view makeToast:@"تم حفظ التعديلات" duration:5.0 position:@"bottom"];
        }

    }
}


-(void)uploadImage:(NSData*)imageData userID:(NSString*)userID{
    
    [self showLoadingMode];
    [[NSUserDefaults standardUserDefaults]setObject:imageData forKey:@"mypic"];
    [[NSUserDefaults standardUserDefaults]synchronize];
    
    NSString *urlString = @"http://moh2013.com/arabDevs/arabchat/uploadImageForUser.php";
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
        NSLog(@"%@",[[NSString alloc] initWithData:printData encoding:NSUTF8StringEncoding]);
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            [self hideLoadingMode];
            [self hideLoadingMode];
        });
    });
}

#pragma mark action sheet delegate
-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if(actionSheet.tag == 1)
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


#pragma mark keyboard delegate

- (void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [[self scrollView] endEditing:YES];
}

- (void)singleTapGestureCaptured:(UITapGestureRecognizer *)gesture
{
    [[self scrollView] endEditing:YES];
    [[self view] endEditing:YES];
}



@end
