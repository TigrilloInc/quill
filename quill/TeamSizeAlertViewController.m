//
//  TeamSizeAlertViewController.m
//  quill
//
//  Created by Alex Costantini on 7/20/15.
//  Copyright (c) 2015 chalk. All rights reserved.
//

#import "TeamSizeAlertViewController.h"
#import <MessageUI/MessageUI.h>
#import "FirebaseHelper.h"
#import "AddUserViewController.h"

@implementation TeamSizeAlertViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    logoImage = (UIImageView *)[self.navigationController.navigationBar viewWithTag:800];
    
    self.navigationItem.title = @"Team Size Maximum Reached";
    
    self.contactButton.layer.borderWidth = 1;
    self.contactButton.layer.cornerRadius = 10;
    self.contactButton.layer.borderColor = [UIColor grayColor].CGColor;
}

-(void)viewWillDisappear:(BOOL)animated {
    
    if ([self.navigationController.viewControllers indexOfObject:self]==NSNotFound) {
        
        logoImage.hidden = true;
        
        if ([self.navigationController.viewControllers.lastObject isKindOfClass:[AddUserViewController class]]) logoImage.frame = CGRectMake(105, 8, 32, 32);
        else logoImage.frame = CGRectMake(182, 8, 32, 32);
        
        [self performSelector:@selector(showLogo) withObject:nil afterDelay:.3];
    }
    
    [super viewWillDisappear:animated];
}

-(void)showLogo {
    
    logoImage.alpha = 0;
    logoImage.hidden = false;
    
    [UIView animateWithDuration:.3 animations:^{
        logoImage.alpha = 1;
    }];
}

- (IBAction)contactTapped:(id)sender {
    
    [self dismissViewControllerAnimated:YES completion:^{
        
        MFMailComposeViewController *mailVC = [[MFMailComposeViewController alloc] init];
        mailVC.mailComposeDelegate = [FirebaseHelper sharedHelper].projectVC;
        
        [mailVC setToRecipients:@[@"hello@tigrillo.co"]];
        
        NSString *subjectString = [NSString stringWithFormat:@"Expanding the size of %@", [FirebaseHelper sharedHelper].teamName];
        [mailVC setSubject:subjectString];
        
        [[FirebaseHelper sharedHelper].projectVC presentViewController:mailVC animated:YES completion:nil];
    }];
}

@end
