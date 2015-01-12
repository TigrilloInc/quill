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
#import "AvatarButton.h"
#import "SignInViewController.h"


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
    
    [outsideTapRecognizer setDelegate:self];
    [outsideTapRecognizer setNumberOfTapsRequired:1];
    outsideTapRecognizer.cancelsTouchesInView = NO;
    [self.view.window addGestureRecognizer:outsideTapRecognizer];
}

- (IBAction)signOutTapped:(id)sender {
    
    ProjectDetailViewController *projectVC = (ProjectDetailViewController *)[UIApplication sharedApplication].delegate.window.rootViewController;
    projectVC.masterView.teamButton.hidden = true;
    projectVC.masterView.nameButton.hidden = true;
    projectVC.masterView.avatarButton.hidden = true;
    projectVC.projectNameLabel.hidden = true;
    projectVC.editButton.hidden = true;
    projectVC.carousel.hidden = true;
    projectVC.chatAvatar.hidden = true;
    projectVC.sendMessageButton.hidden = true;
    projectVC.boardNameLabel.hidden = true;
    projectVC.boardNameEditButton.hidden = true;
    projectVC.editBoardNameTextField.hidden = true;
    for (AvatarButton *avatar in projectVC.avatars) avatar.hidden = true;
    projectVC.avatarBackgroundImage.hidden = true;
    projectVC.addUserButton.hidden = true;
    projectVC.chatTextField.hidden = true;
    projectVC.addBoardBackgroundImage.hidden = true;
    projectVC.addBoardButton.hidden = true;
    projectVC.chatOpenButton.hidden = true;
    
    Firebase *ref = [[Firebase alloc] initWithUrl:@"https://chalkto.firebaseio.com/"];
    FirebaseSimpleLogin *authClient = [[FirebaseSimpleLogin alloc] initWithRef:ref];
    
    [authClient logout];
    [FirebaseHelper sharedHelper].loggedIn = false;
    
    [[FirebaseHelper sharedHelper] clearData];
    
    [self dismissViewControllerAnimated:YES completion:nil];
    [self.view.window removeGestureRecognizer:outsideTapRecognizer];
    
    SignInViewController *vc = [projectVC.storyboard instantiateViewControllerWithIdentifier:@"SignIn"];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    
    nav.modalPresentationStyle = UIModalPresentationFormSheet;
    nav.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    [projectVC presentViewController:nav animated:YES completion:nil];
}

- (IBAction)doneTapped:(id)sender {
    
    [self dismissViewControllerAnimated:YES completion:nil];
    [self.view.window removeGestureRecognizer:outsideTapRecognizer];
}

-(void) tappedOutside {
    
    if (outsideTapRecognizer.state == UIGestureRecognizerStateEnded)
    {
        CGPoint location = [outsideTapRecognizer locationInView:nil];
        CGPoint converted = [self.view convertPoint:CGPointMake(1024-location.y,location.x) fromView:self.view.window];
        
        if (!CGRectContainsPoint(self.view.frame, converted)){
            
            [outsideTapRecognizer setDelegate:nil];
            [self.view.window removeGestureRecognizer:outsideTapRecognizer];
            [self dismissViewControllerAnimated:YES completion:nil];
        }
    }
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    return YES;
}

@end
