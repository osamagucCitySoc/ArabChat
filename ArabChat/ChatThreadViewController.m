//
//  ChatThreadViewController.m
//  ArabChat
//
//  Created by Osama Rabie on 3/13/15.
//  Copyright (c) 2015 Osama Rabie. All rights reserved.
//

#import "ChatThreadViewController.h"
#import "STBubbleTableViewCell.h"
#import "Message.h"
#import "DatabaseController.h"
#import "THChatInput.h"
#import "Reachability.h"
#import "UIView+Toast.h"
#import "DAKeyboardControl.h"
#import <AudioToolbox/AudioToolbox.h>

@interface ChatThreadViewController ()<STBubbleTableViewCellDataSource, STBubbleTableViewCellDelegate,UITableViewDataSource,UITableViewDelegate>

@end

@implementation ChatThreadViewController

{
    UIImage* image;
    DatabaseController* dbController;
    UITableView* tableView;
    UITextField* messageTextField;
    UIEdgeInsets originalInset;
    UIEdgeInsets scrolInset;
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receiveMessageNotification:)
                                                 name:@"newMessage"
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
}


- (void) receiveMessageNotification:(NSNotification *) notification
{
    [[NSUserDefaults standardUserDefaults]setObject:@"0" forKey:@"newMessages"];
    [[NSUserDefaults standardUserDefaults]synchronize];
    
    self.messages = [dbController loadThread:self.FRDID image:self.FRDIMG];
    [UIView animateWithDuration:0 animations:^{
        [tableView reloadData];
        [tableView setNeedsDisplay];
    } completion:^(BOOL finished) {
        if(self.messages.count>0)
        {
            [tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:self.messages.count-1 inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:NO];
        }
    }];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = @"Messages";
    
    
    UITapGestureRecognizer *tapper = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tappedView:)];
    [self.view addGestureRecognizer:tapper];

    
    tableView = [[UITableView alloc] initWithFrame:CGRectMake(0.0f,
                                                              0.0f,
                                                              self.view.bounds.size.width,
                                                              self.view.bounds.size.height - 40.0f)];
    tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:tableView];
    
    UIToolbar *toolBar = [[UIToolbar alloc] initWithFrame:CGRectMake(0.0f,
                                                                     self.view.bounds.size.height - 40.0f,
                                                                     self.view.bounds.size.width,
                                                                     40.0f)];
    toolBar.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
    [self.view addSubview:toolBar];
    
    messageTextField = [[UITextField alloc] initWithFrame:CGRectMake(10.0f,
                                                                           6.0f,
                                                                           toolBar.bounds.size.width - 20.0f - 68.0f,
                                                                           30.0f)];
    messageTextField.borderStyle = UITextBorderStyleRoundedRect;
    messageTextField.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [toolBar addSubview:messageTextField];
    
    UIButton *sendButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    sendButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    [sendButton setTitle:@"Send" forState:UIControlStateNormal];
    sendButton.frame = CGRectMake(toolBar.bounds.size.width - 68.0f,
                                  6.0f,
                                  58.0f,
                                  29.0f);
    [sendButton addTarget:self action:@selector(sendWasClicked:) forControlEvents:UIControlEventTouchUpInside];
    [toolBar addSubview:sendButton];
    
    
    self.view.keyboardTriggerOffset = toolBar.bounds.size.height;
    
    [self.view addKeyboardPanningWithActionHandler:^(CGRect keyboardFrameInView) {
        /*
         Try not to call "self" inside this block (retain cycle).
         But if you do, make sure to remove DAKeyboardControl
         when you are done with the view controller by calling:
         [self.view removeKeyboardControl];
         */
        
        CGRect toolBarFrame = toolBar.frame;
        toolBarFrame.origin.y = keyboardFrameInView.origin.y - toolBarFrame.size.height;
        toolBar.frame = toolBarFrame;
        
        
    }];

    dbController = [[DatabaseController alloc]init];
    [dbController createDatabaseIfNotExists];
    
    if(!self.FRDNAME || self.FRDNAME.length <= 0)
    {
        NSDictionary* info = [dbController loadFriendInfo:self.FRDID];
        self.FRDNAME = [info objectForKey:@"FRDNAME"];
        self.FRDPIC = [info objectForKey:@"FRDIMG"];
    }
    
    [self setTitle:self.FRDNAME];
    
    self.messages = [dbController loadThread:self.FRDID image:self.FRDIMG];
    
    
    tableView.backgroundColor = [UIColor colorWithRed:219.0f/255.0f green:226.0f/255.0f blue:237.0f/255.0f alpha:1.0f];
    tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    
    [tableView setDataSource:self];
    [tableView setDelegate:self];
    

    CGRect toolBarFrame = toolBar.frame;
    CGRect tableViewFrame = tableView.frame;
    tableViewFrame.size.height = toolBarFrame.origin.y;
    tableView.frame = tableViewFrame;
    
    
    [UIView animateWithDuration:0 animations:^{
        [tableView reloadData];
        [tableView setNeedsDisplay];
    } completion:^(BOOL finished) {
        if(self.messages.count>0)
        {
            [tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:self.messages.count-1 inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:NO];
        }
    }];
    
}

- (void)tappedView:(UITapGestureRecognizer*)tapper
{
    [messageTextField resignFirstResponder];
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.view removeKeyboardControl];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}



- (void)keyboardWillShow:(NSNotification *)notification
{
    CGSize keyboardSize = [[[notification userInfo] objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    
    originalInset = tableView.contentInset;
    scrolInset = tableView.scrollIndicatorInsets;
    
    UIEdgeInsets contentInsets;
    if (UIInterfaceOrientationIsPortrait([[UIApplication sharedApplication] statusBarOrientation])) {
        contentInsets = UIEdgeInsetsMake(0.0, 0.0, (keyboardSize.height), 0.0);
    } else {
        contentInsets = UIEdgeInsetsMake(0.0, 0.0, (keyboardSize.width), 0.0);
    }
    
   tableView.contentInset = contentInsets;
   tableView.scrollIndicatorInsets = contentInsets;
    if(self.messages.count>0)
    {
        [tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:self.messages.count-1 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:YES];
    }
}

- (void)keyboardWillHide:(NSNotification *)notification
{
    tableView.contentInset = originalInset;
    tableView.scrollIndicatorInsets = scrolInset;
}


#pragma mark - UITableViewDatasource methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableVieww numberOfRowsInSection:(NSInteger)section
{
    return [self.messages count];
}

- (UITableViewCell *)tableView:(UITableView *)tableVieww cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Bubble Cell";
    
    STBubbleTableViewCell *cell = (STBubbleTableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil)
    {
        cell = [[STBubbleTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        cell.backgroundColor = tableView.backgroundColor;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        cell.dataSource = self;
        cell.delegate = self;
    }
    
    Message *message = [self.messages objectAtIndex:indexPath.row];
    
    cell.textLabel.font = [UIFont systemFontOfSize:14.0f];
    cell.textLabel.text = message.message;
    cell.imageView.image = message.avatar;
    
    
    // Put your own logic here to determine the author
    if(message.SENT == 1)
    {
        cell.authorType = STBubbleTableViewCellAuthorTypeSelf;
        cell.bubbleColor = STBubbleTableViewCellBubbleColorGreen;
    }
    else
    {
        cell.authorType = STBubbleTableViewCellAuthorTypeOther;
        cell.bubbleColor = STBubbleTableViewCellBubbleColorGray;
    }
   
    return cell;
}

#pragma mark - UITableViewDelegate methods

- (CGFloat)tableView:(UITableView *)tableVieww heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    Message *message = [self.messages objectAtIndex:indexPath.row];
    
    CGSize size;
    
    if(message.avatar)
    {
        size = [message.message boundingRectWithSize:CGSizeMake(tableView.frame.size.width - [self minInsetForCell:nil atIndexPath:indexPath] - STBubbleImageSize - 8.0f - STBubbleWidthOffset, CGFLOAT_MAX)
                                             options:NSStringDrawingUsesLineFragmentOrigin
                                          attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:14.0f]}
                                             context:nil].size;
    }
    else
    {
        size = [message.message boundingRectWithSize:CGSizeMake(tableView.frame.size.width - [self minInsetForCell:nil atIndexPath:indexPath] - STBubbleWidthOffset, CGFLOAT_MAX)
                                             options:NSStringDrawingUsesLineFragmentOrigin
                                          attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:14.0f]}
                                             context:nil].size;
    }
    
    // This makes sure the cell is big enough to hold the avatar
    if(size.height + 15.0f < STBubbleImageSize + 4.0f && message.avatar)
    {
        return STBubbleImageSize + 4.0f;
    }
    
    return size.height + 15.0f;
}

#pragma mark - STBubbleTableViewCellDataSource methods

- (CGFloat)minInsetForCell:(STBubbleTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    if(UIInterfaceOrientationIsLandscape(self.interfaceOrientation))
    {
        return 100.0f;
    }
    
    return 50.0f;
}

#pragma mark - STBubbleTableViewCellDelegate methods

- (void)tappedImageOfCell:(STBubbleTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    Message *message = [self.messages objectAtIndex:indexPath.row];
    NSLog(@"%@", message.message);
}

#pragma mark -

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return toInterfaceOrientation != UIInterfaceOrientationPortraitUpsideDown;
}


-(void)sendWasClicked:(id)sender
{
    [messageTextField resignFirstResponder];

    NSString* text = messageTextField.text;
    
    [messageTextField setText:@""];
    
    if(text.length>0)
    {
        if([Reachability isConnected])
        {
            NSString *post = [NSString stringWithFormat:@"senderID=%@&recieverID=%@&senderName=%@&text=%@&whenn=%@&senderImg=%@",[[[[NSUserDefaults standardUserDefaults] objectForKey:@"currentUser"] objectForKey:@"0"] objectForKey:@"userID"],self.FRDID,[[[[NSUserDefaults standardUserDefaults] objectForKey:@"currentUser"] objectForKey:@"0"] objectForKey:@"username"],text,[NSString stringWithFormat:@"%f",[[NSDate date] timeIntervalSince1970]],[[[[NSUserDefaults standardUserDefaults] objectForKey:@"currentUser"] objectForKey:@"0"] objectForKey:@"profilePic"]];
            
            NSData *postData = [post dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:NO];
            NSString *postLength = [NSString stringWithFormat:@"%lu", (unsigned long)[post length]];
            
            NSURL *url = [NSURL URLWithString:@"http://moh2013.com/arabDevs/arabchat/sendMessage.php"];
            NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:90.0];
            [request setHTTPMethod:@"POST"];
            
            [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
            
            [request setHTTPBody:postData];
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                NSData* data = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil];
                dispatch_async(dispatch_get_main_queue(), ^(void) {
                    
                    SystemSoundID completeSound;
                    NSURL *audioPath = [[NSBundle mainBundle] URLForResource:@"SentMessage" withExtension:@"wav"];
                    AudioServicesCreateSystemSoundID((__bridge CFURLRef)audioPath, &completeSound);
                    AudioServicesPlaySystemSound (completeSound);

                    NSLog(@"%@",[[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding]);
                    [dbController insertNewChatRecord:self.FRDID FRDNAME:self.FRDNAME FRDIMG:self.FRDPIC MSG:text SENT:1 STATUS:@"D" WHENN:[[NSDate date] timeIntervalSince1970] ONLINE:1];
                    self.messages = [dbController loadThread:self.FRDID image:self.FRDIMG];
                    [UIView animateWithDuration:0 animations:^{
                        [tableView reloadData];
                        [tableView setNeedsDisplay];
                    } completion:^(BOOL finished) {
                        if(self.messages.count>0)
                        {
                            [tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:self.messages.count-1 inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:NO];
                        }
                    }];
                });
            });
        }else
        {
            [self.view makeToast:@"عذراً. يجب أن تكون متصلاً بالإنترنت" duration:5.0 position:@"bottom"];
        }
    }
}

@end