//
//  AppDelegate.m
//  ArabChat
//
//  Created by Osama Rabie on 3/7/15.
//  Copyright (c) 2015 Osama Rabie. All rights reserved.
//

#import "AppDelegate.h"
#import "AGPushNoteView.h"
#import "DatabaseController.h"
#import <AudioToolbox/AudioToolbox.h>

@interface AppDelegate ()

@end

@implementation AppDelegate
{
    DatabaseController* dbController;
}


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    
    if ([application respondsToSelector:@selector(registerUserNotificationSettings:)]) {
        UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:(UIRemoteNotificationTypeBadge
                                                                                             |UIRemoteNotificationTypeSound
                                                                                             |UIRemoteNotificationTypeAlert
                                                                                             | UIUserNotificationTypeAlert
                                                                                             |UIUserNotificationTypeBadge
                                                                                             |UIUserNotificationTypeSound) categories:nil];
        
        [application registerUserNotificationSettings:settings];
       
    } else {
        UIRemoteNotificationType myTypes = UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeSound |UIUserNotificationTypeAlert
        |UIUserNotificationTypeBadge
        |UIUserNotificationTypeSound;
        [application registerForRemoteNotificationTypes:myTypes];
    }

    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    // Saves changes in the application's managed object context before the application terminates.
    [self saveContext];
}


- (void)application:(UIApplication*)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData*)deviceToken
{
    //NSLog(@"My token is: %@", deviceToken);
    NSMutableString *string = [[NSMutableString alloc]init];
    int length = (int)[deviceToken length];
    char const *bytes = [deviceToken bytes];
    for (int i=0; i< length; i++) {
        [string appendString:[NSString stringWithFormat:@"%02.2hhx",bytes[i]]];
    }
    
    NSUserDefaults * standardUserDefaults = [NSUserDefaults standardUserDefaults];
    [standardUserDefaults setObject:string forKey:@"deviceToken"];
}

#ifdef __IPHONE_8_0
- (void)application:(UIApplication *)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings
{
    NSLog(@"%@",@"OSAMA");
    //register to receive notifications
    [application registerForRemoteNotifications];
}

- (void)application:(UIApplication *)application handleActionWithIdentifier:(NSString *)identifier forRemoteNotification:(NSDictionary *)userInfo completionHandler:(void(^)())completionHandler
{
    NSLog(@"%@",@"OSAMA");
}
#endif

- (void)application:(UIApplication*)application didFailToRegisterForRemoteNotificationsWithError:(NSError*)error
{
    //NSLog(@"فشل في الحصول على رمز، الخطأ: %@", error);
}


- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
{
    if([[userInfo objectForKey:@"aps"]objectForKey:@"i"])
    {
        if([[[userInfo objectForKey:@"aps"]objectForKey:@"i"] intValue] == 1)
        {
            dbController = [[DatabaseController alloc]init];
            
            [dbController createDatabaseIfNotExists];
            
            NSString *post = [NSString stringWithFormat:@"userID=%@",[[[[NSUserDefaults standardUserDefaults] objectForKey:@"currentUser"] objectForKey:@"0"] objectForKey:@"userID"]];
            
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
                    
                    
                    SystemSoundID completeSound;
                    NSURL *audioPath = [[NSBundle mainBundle] URLForResource:@"water" withExtension:@"aiff"];
                    AudioServicesCreateSystemSoundID((__bridge CFURLRef)audioPath, &completeSound);
                    AudioServicesPlaySystemSound (completeSound);
                    
                    
                    [AGPushNoteView showWithNotificationMessage:[[userInfo objectForKey:@"aps"] objectForKey:@"alert"] photo:[[userInfo objectForKey:@"aps"] objectForKey:@"p"]];
                    
                    if([[NSUserDefaults standardUserDefaults] objectForKey:@"newMessages"])
                    {
                        [[NSUserDefaults standardUserDefaults]setObject:[NSString stringWithFormat:@"%i",[[[NSUserDefaults standardUserDefaults] objectForKey:@"newMessages"]intValue] + (int)messages.count] forKey:@"newMessages"];
                        [[NSUserDefaults standardUserDefaults]synchronize];
                    }else
                    {
                        [[NSUserDefaults standardUserDefaults]setObject:[NSString stringWithFormat:@"%i",(int)messages.count] forKey:@"newMessages"];
                        [[NSUserDefaults standardUserDefaults]synchronize];
                    }

                    
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"newMessage" object:nil];

                });
            });
        }
    }
}

#pragma mark - Core Data stack

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

- (NSURL *)applicationDocumentsDirectory {
    // The directory the application uses to store the Core Data store file. This code uses a directory named "arabdevs.ArabChat" in the application's documents directory.
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

- (NSManagedObjectModel *)managedObjectModel {
    // The managed object model for the application. It is a fatal error for the application not to be able to find and load its model.
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"ArabChat" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    // The persistent store coordinator for the application. This implementation creates and return a coordinator, having added the store for the application to it.
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    // Create the coordinator and store
    
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"ArabChat.sqlite"];
    NSError *error = nil;
    NSString *failureReason = @"There was an error creating or loading the application's saved data.";
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
        // Report any error we got.
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        dict[NSLocalizedDescriptionKey] = @"Failed to initialize the application's saved data";
        dict[NSLocalizedFailureReasonErrorKey] = failureReason;
        dict[NSUnderlyingErrorKey] = error;
        error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:9999 userInfo:dict];
        // Replace this with code to handle the error appropriately.
        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    return _persistentStoreCoordinator;
}


- (NSManagedObjectContext *)managedObjectContext {
    // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.)
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (!coordinator) {
        return nil;
    }
    _managedObjectContext = [[NSManagedObjectContext alloc] init];
    [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    return _managedObjectContext;
}

#pragma mark - Core Data Saving support

- (void)saveContext {
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil) {
        NSError *error = nil;
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
}

@end
