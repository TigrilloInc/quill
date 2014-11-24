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
    
    self.avatars = [NSMutableArray array];
    
    for (int i=0; i<8; i++) {
        
        NSString *imageString = [NSString stringWithFormat:@"user%i.png", i+1];
        UIImage *image = [UIImage imageNamed:imageString];
        AvatarButton *avatar = [AvatarButton buttonWithType:UIButtonTypeCustom];
        if (i<4) avatar.frame = CGRectMake((i*100), 50, avatar.userImage.size.width, avatar.userImage.size.height);
        else avatar.frame = CGRectMake(((i-4)*100), 150, avatar.userImage.size.width, avatar.userImage.size.height);
        CGAffineTransform tr = CGAffineTransformScale(avatar.transform, .25, .25);
        avatar.transform = tr;
        [avatar setImage:image forState:UIControlStateNormal];
        avatar.tag = i+1;
        [avatar addTarget:self action:@selector(avatarTapped:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:avatar];
        [self.avatars addObject:avatar];
    }
}

- (void) viewDidAppear:(BOOL)animated
{
    
    outsideTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tappedOutside)];
    
    [outsideTapRecognizer setDelegate:self];
    [outsideTapRecognizer setNumberOfTapsRequired:1];
    outsideTapRecognizer.cancelsTouchesInView = NO;
    [self.view.window addGestureRecognizer:outsideTapRecognizer];
}

-(void)avatarTapped:(id)sender {
    
    AvatarButton *avatar = (AvatarButton *)sender;
    
    for (AvatarButton *avtr in self.avatars) {
        
        avtr.highlightedImage.hidden = true;
    }
    
    avatar.highlightedImage.hidden = false;
    self.selectedAvatar = (int)avatar.tag;
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
    
    NSString *avatarString = [NSString stringWithFormat:@"https://chalkto.firebaseio.com/users/%@/avatar", [FirebaseHelper sharedHelper].uid];
    Firebase *ref = [[Firebase alloc] initWithUrl:avatarString];
    [ref setValue:@(self.selectedAvatar)];
    
    [[[[FirebaseHelper sharedHelper].team objectForKey:@"users"] objectForKey:[FirebaseHelper sharedHelper].uid] setObject:@(self.selectedAvatar) forKey:@"avatar"];
    
    ProjectDetailViewController *projectVC = (ProjectDetailViewController *)[UIApplication sharedApplication].delegate.window.rootViewController;
    UIImage *image = [UIImage imageNamed:[NSString stringWithFormat:@"user%i.png",self.selectedAvatar]];
    [projectVC.masterView.avatarButton setImage:image forState:UIControlStateNormal];
    [projectVC.chatAvatar setImage:image forState:UIControlStateNormal];
    [projectVC layoutAvatars];
    
    for (int i=0; i<projectVC.boardIDs.count; i++){
        
        DrawView *drawView = (DrawView *)[projectVC.carousel itemViewAtIndex:i];
        [drawView layoutComments];
    }
    
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
