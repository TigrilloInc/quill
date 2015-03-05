//
//  AppDelegate.m
//  Quill
//
//  Created by Alex Costantini on 7/2/14.
//  Copyright (c) 2014 Tigrillo. All rights reserved.
//

#import "AppDelegate.h"
#import <Firebase/Firebase.h>
#import "FirebaseHelper.h"
#import <Instabug/Instabug.h>

@implementation AppDelegate

-(BOOL) application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    [FirebaseHelper sharedHelper];
    
    [Instabug startWithToken:@"9a674b675e5dd033bc995a4d7a4a231f" captureSource:IBGCaptureSourceUIKit invocationEvent:IBGInvocationEventNone];
    [Instabug setEmailIsRequired:NO];
    [Instabug setWillShowFeedbackSentAlert:NO];
    
    NSSetUncaughtExceptionHandler(&uncaughtExceptionHandler);
    signal(SIGABRT, signalHandler);
    signal(SIGILL, signalHandler);
    signal(SIGSEGV, signalHandler);
    signal(SIGFPE, signalHandler);
    signal(SIGBUS, signalHandler);
    signal(SIGPIPE, signalHandler);
    
    [[FirebaseHelper sharedHelper] testConnection];
    
    return YES;
}

void uncaughtExceptionHandler(NSException *exception) {
    
    if (![FirebaseHelper sharedHelper].uid) return;
    
    NSString *userString = [NSString stringWithFormat:@"https://chalkto.firebaseio.com/users/%@/", [FirebaseHelper sharedHelper].uid];
    Firebase *userRef = [[Firebase alloc] initWithUrl:userString];
    [[userRef childByAppendingPath:@"inProject"] setValue:@"none"];
    [[userRef childByAppendingPath:@"inBoard"] setValue:@"none"];
}

void signalHandler(int signal) {
    
    if (![FirebaseHelper sharedHelper].uid) return;
    
    NSString *userString = [NSString stringWithFormat:@"https://chalkto.firebaseio.com/users/%@/", [FirebaseHelper sharedHelper].uid];
    Firebase *userRef = [[Firebase alloc] initWithUrl:userString];
    [[userRef childByAppendingPath:@"inProject"] setValue:@"none"];
    [[userRef childByAppendingPath:@"inBoard"] setValue:@"none"];
}

-(void) removeUserPresence {

    if (![FirebaseHelper sharedHelper].uid) return;
    
    [[FirebaseHelper sharedHelper] setInBoard:@"none"];
    [[FirebaseHelper sharedHelper] setInProject:@"none"];
}

-(void) addUserPresence {
    
    if ([FirebaseHelper sharedHelper].currentProjectID) [[FirebaseHelper sharedHelper] setInProject:[FirebaseHelper sharedHelper].currentProjectID];
    if ([FirebaseHelper sharedHelper].projectVC.activeBoardID) [[FirebaseHelper sharedHelper] setInBoard:[FirebaseHelper sharedHelper].projectVC.activeBoardID];
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    
    [FirebaseHelper sharedHelper].inviteURL = url;
    [[FirebaseHelper sharedHelper] createUser];
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    [self removeUserPresence];
    
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    [self removeUserPresence];
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    [self addUserPresence];
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    [self removeUserPresence];
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
