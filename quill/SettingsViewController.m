//
//  SettingsViewController.m
//  Quill
//
//  Created by Alex Costantini on 7/16/14.
//  Copyright (c) 2014 Tigrillo. All rights reserved.
//

#import "SettingsViewController.h"
#import <Firebase/Firebase.h>
#import <FirebaseSimpleLogin/FirebaseSimpleLogin.h>
#import "FirebaseHelper.h"

@interface SettingsViewController ()

@end

@implementation SettingsViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    
}

- (void) viewDidAppear:(BOOL)animated
{
    
    outsideTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tappedOutside)];
    
    [outsideTapRecognizer setNumberOfTapsRequired:1];
    outsideTapRecognizer.cancelsTouchesInView = NO;
    [self.view.window addGestureRecognizer:outsideTapRecognizer];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)signOutTapped:(id)sender {

    Firebase *ref = [[Firebase alloc] initWithUrl:@"https://chalkto.firebaseio.com/"];
    FirebaseSimpleLogin *authClient = [[FirebaseSimpleLogin alloc] initWithRef:ref];
    
    [authClient logout];
    
    [[FirebaseHelper sharedHelper] clearData];
    
    [self dismissViewControllerAnimated:YES completion:nil];
    [self.view.window removeGestureRecognizer:outsideTapRecognizer];
}

- (IBAction)doneTapped:(id)sender {
    
    [self dismissViewControllerAnimated:YES completion:nil];
    [self.view.window removeGestureRecognizer:outsideTapRecognizer];
}

-(void) tappedOutside {
    
    if (outsideTapRecognizer.state == UIGestureRecognizerStateEnded)
    {
        CGPoint location = [outsideTapRecognizer locationInView:nil];
        
        if (![self.view pointInside:[self.view convertPoint:location fromView:self.view.window] withEvent:nil]){
            
            [self.view.window removeGestureRecognizer:outsideTapRecognizer];
            [self dismissViewControllerAnimated:YES completion:nil];
        }
    }
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
