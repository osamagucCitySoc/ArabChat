//
//  STBubbleTableViewCellDemoViewController.m
//  STBubbleTableViewCellDemo
//
//  Created by Cedric Vandendriessche on 24/08/13.
//  Copyright 2013 FreshCreations. All rights reserved.
//

#import "STBubbleTableViewCellDemoViewController.h"
#import "STBubbleTableViewCell.h"
#import "Message.h"
#import "DatabaseController.h"
#import "THChatInput.h"
#import "Reachability.h"
#import "UIView+Toast.h"

@interface STBubbleTableViewCellDemoViewController () <STBubbleTableViewCellDataSource, STBubbleTableViewCellDelegate,THChatInputDelegate>
@property (strong, nonatomic) THChatInput *chatInput;

@end

@implementation STBubbleTableViewCellDemoViewController
{
    UIImage* image;
    DatabaseController* dbController;
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receiveMessageNotification:)
                                                 name:@"newMessage"
                                               object:nil];
}


- (void) receiveMessageNotification:(NSNotification *) notification
{
    [[NSUserDefaults standardUserDefaults]setObject:@"0" forKey:@"newMessages"];
    [[NSUserDefaults standardUserDefaults]synchronize];
    
    self.messages = [dbController loadThread:self.FRDID image:self.FRDIMG];
    [self.tableView reloadData];
    [self.tableView setNeedsDisplay];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.title = @"Messages";
	
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
    
    
    dbController = [[DatabaseController alloc]init];
    [dbController createDatabaseIfNotExists];
    
    if(!self.FRDNAME || self.FRDNAME.length <= 0)
    {
        NSDictionary* info = [dbController loadFriendInfo:self.FRDID];
        self.FRDNAME = [info objectForKey:@"FRDNAME"];
        self.FRDPIC = [info objectForKey:@"FRDIMG"];
    }
    
    [self setTitle:self.FRDNAME];
    
    UITapGestureRecognizer *tapper = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tappedView:)];
    [self.view addGestureRecognizer:tapper];

    
    self.messages = [dbController loadThread:self.FRDID image:self.FRDIMG];
    
	/*self.messages = [[NSMutableArray alloc] initWithObjects:
				[Message messageWithString:@"How is that bubble component of yours coming along?" image:[UIImage imageNamed:@"jonnotie.png"]],
				[Message messageWithString:@"Great, I just finished avatar support." image:[UIImage imageNamed:@"SkyTrix.png"]],
				[Message messageWithString:@"That is awesome! I hope people will like that addition." image:[UIImage imageNamed:@"jonnotie.png"]],
				[Message messageWithString:@"Now you see me.." image:[UIImage imageNamed:@"SkyTrix.png"]],
				[Message messageWithString:@"And now you don't. :)"],
				nil];*/
	
	self.tableView.backgroundColor = [UIColor colorWithRed:219.0f/255.0f green:226.0f/255.0f blue:237.0f/255.0f alpha:1.0f];
	self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
	
	// Some decoration
	//CGSize screenSize = [[UIScreen mainScreen] applicationFrame].size;
	//UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, screenSize.width, 55.0f)];
	
    //self.tableView.tableHeaderView = headerView;
    _chatInput = [[THChatInput alloc]initWithFrame:CGRectMake(0, self.view.frame.size.height-154, self.tableView.frame.size.width, 44)];
    [_chatInput setDelegate:self];
    
    [self.view addSubview:_chatInput];
    [self.view bringSubviewToFront:_chatInput];
    
    
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)keyboardWillShow:(NSNotification *)notification
{
    CGSize keyboardSize = [[[notification userInfo] objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    
    UIEdgeInsets contentInsets;
    if (UIInterfaceOrientationIsPortrait([[UIApplication sharedApplication] statusBarOrientation])) {
        contentInsets = UIEdgeInsetsMake(0.0, 0.0, (keyboardSize.height), 0.0);
    } else {
        contentInsets = UIEdgeInsetsMake(0.0, 0.0, (keyboardSize.width), 0.0);
    }


    
    self.tableView.contentInset = contentInsets;
    //self.tableView.scrollIndicatorInsets = contentInsets;
    [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:self.messages.count-1 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:YES];
}

- (void)keyboardWillHide:(NSNotification *)notification
{
    self.tableView.contentInset = UIEdgeInsetsMake(0.0, 0.0, 300, 0.0);
    //self.tableView.scrollIndicatorInsets = UIEdgeInsetsMake(0.0, 0.0, 250, 0.0);
}



- (void)tappedView:(UITapGestureRecognizer*)tapper
{
    [_chatInput resignFirstResponder];
}
-(void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGRect newFrame = _chatInput.frame;
    newFrame.origin.x = 0;
    newFrame.origin.y = self.tableView.contentOffset.y+(self.tableView.frame.size.height-44);
    _chatInput.frame = newFrame;
}


#pragma mark - UITableViewDatasource methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.messages count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Bubble Cell";

    STBubbleTableViewCell *cell = (STBubbleTableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil)
    {
        cell = [[STBubbleTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        cell.backgroundColor = self.tableView.backgroundColor;
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

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	Message *message = [self.messages objectAtIndex:indexPath.row];
	
	CGSize size;
	
	if(message.avatar)
    {
        size = [message.message boundingRectWithSize:CGSizeMake(self.tableView.frame.size.width - [self minInsetForCell:nil atIndexPath:indexPath] - STBubbleImageSize - 8.0f - STBubbleWidthOffset, CGFLOAT_MAX)
                                             options:NSStringDrawingUsesLineFragmentOrigin
                                          attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:14.0f]}
                                             context:nil].size;
    }
	else
    {
        size = [message.message boundingRectWithSize:CGSizeMake(self.tableView.frame.size.width - [self minInsetForCell:nil atIndexPath:indexPath] - STBubbleWidthOffset, CGFLOAT_MAX)
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


#pragma mark - THChatInputDelegate

- (void)chat:(THChatInput*)input sendWasPressed:(NSString*)text
{
    
    [input resignFirstResponder];
    
    if(text.length>0)
    {
        if([Reachability isConnected])
        {
            NSString *post = [NSString stringWithFormat:@"senderID=%@&recieverID=%@&senderName=%@&text=%@&whenn=%@&senderImg=%@",[[[[NSUserDefaults standardUserDefaults] objectForKey:@"currentUser"] objectForKey:@"0"] objectForKey:@"userID"],self.FRDID,[[[[NSUserDefaults standardUserDefaults] objectForKey:@"currentUser"] objectForKey:@"0"] objectForKey:@"username"],text,[NSString stringWithFormat:@"%f",NSTimeIntervalSince1970],[[[[NSUserDefaults standardUserDefaults] objectForKey:@"currentUser"] objectForKey:@"0"] objectForKey:@"profilePic"]];
            
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
                    NSLog(@"%@",[[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding]);
                    [_chatInput setText:@""];
                    [dbController insertNewChatRecord:self.FRDID FRDNAME:self.FRDNAME FRDIMG:self.FRDPIC MSG:text SENT:1 STATUS:@"D" WHENN:NSTimeIntervalSince1970 ONLINE:1];
                    self.messages = [dbController loadThread:self.FRDID image:self.FRDIMG];
                    [self.tableView reloadData];
                    [self.tableView setNeedsDisplay];
                    if (self.tableView.contentSize.height > self.tableView.frame.size.height)
                    {
                        CGPoint offset = CGPointMake(0, self.tableView.contentSize.height - self.tableView.frame.size.height);
                        [self.tableView setContentOffset:offset animated:YES];
                    }
                });
            });
        }else
        {
            [self.view makeToast:@"عذراً. يجب أن تكون متصلاً بالإنترنت" duration:5.0 position:@"bottom"];
        }
    }
}

- (void)chatShowEmojiInput:(THChatInput*)input
{
    [_chatInput.textView reloadInputViews];
}

- (void)chatShowAttachInput:(THChatInput*)input
{
    
}


@end
