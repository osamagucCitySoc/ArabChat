//
//  HomeViewController.m
//  ArabChat
//
//  Created by Osama Rabie on 3/8/15.
//  Copyright (c) 2015 Osama Rabie. All rights reserved.
//

#import "HomeViewController.h"
#import "MZLoadingCircle.h"
#import "Reachability.h"
#import "UIView+Toast.h"

@interface HomeViewController ()<UIPickerViewDataSource,UIPickerViewDelegate,NSURLConnectionDataDelegate,NSURLConnectionDelegate>

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIButton *registerButton;
@property (weak, nonatomic) IBOutlet UIPickerView *countryCityPickerView;
@property (weak, nonatomic) IBOutlet UIDatePicker *datePicker;
@property (weak, nonatomic) IBOutlet UISwitch *girlSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *boySwitch;
@property (weak, nonatomic) IBOutlet UITextField *usernameTextField;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;
@property (weak, nonatomic) IBOutlet UITextField *passwordTwoTextField;
@end

@implementation HomeViewController
{
    MZLoadingCircle *loadingCircle;
    NSURLConnection* getCountriesCitiesConnection;
    NSMutableData* responseData;
    NSDictionary* countriesCitiesDataSource;
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
    
    if([ Reachability isConnected])
    {
        [self showLoadingMode];
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
        
        [self hideLoadingMode];
    }
}
-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    if(connection == getCountriesCitiesConnection)
    {
        [responseData appendData:data];
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
