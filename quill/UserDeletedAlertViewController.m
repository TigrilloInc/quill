//
//  UserDeletedAlertViewController.m
//  quill
//
//  Created by Alex Costantini on 2/24/15.
//  Copyright (c) 2015 chalk. All rights reserved.
//

#import "UserDeletedAlertViewController.h"
#import "SignInViewController.h"
#import "ProjectDetailViewController.h"
#import "FirebaseHelper.h"

@implementation UserDeletedAlertViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = @"User Deleted";
    
    self.okButton.layer.borderWidth = 1;
    self.okButton.layer.cornerRadius = 10;
    self.okButton.layer.borderColor = [UIColor grayColor].CGColor;
}

- (void)viewWillAppear:(BOOL)animated {

    UIFont *nameFont = [UIFont fontWithName:@"SourceSansPro-Semibold" size:20];
    UIFont *labelFont = [UIFont fontWithName:@"SourceSansPro-Regular" size:20];
    
    NSDictionary *nameAttrs = [NSDictionary dictionaryWithObjectsAndKeys: nameFont, NSFontAttributeName, nil];
    NSDictionary *labelAttrs = [NSDictionary dictionaryWithObjectsAndKeys: labelFont, NSFontAttributeName, nil];
    NSRange emailRange = NSMakeRange(35,[FirebaseHelper sharedHelper].email.length);
    NSRange teamRange = NSMakeRange(58+[FirebaseHelper sharedHelper].email.length,[FirebaseHelper sharedHelper].teamName.length);
    
    NSString *labelString = [NSString stringWithFormat:@"The account with the email address %@ has been removed from %@.", [FirebaseHelper sharedHelper].email,[FirebaseHelper sharedHelper].teamName];
    NSMutableAttributedString *attrString = [[NSMutableAttributedString alloc] initWithString:labelString attributes:labelAttrs];
    [attrString setAttributes:nameAttrs range:emailRange];
    [attrString setAttributes:nameAttrs range:teamRange];
    
    [self.nameLabel setAttributedText:attrString];
}

- (IBAction)okTapped:(id)sender {
    
    SignInViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"SignIn"];
    
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    nav.modalPresentationStyle = UIModalPresentationFormSheet;
    nav.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    nav.navigationBar.barTintColor = [UIColor whiteColor];
    nav.navigationBar.tintColor = [UIColor blackColor];
    [[UINavigationBar appearance] setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys: [UIFont fontWithName:@"SourceSansPro-Light" size:24.0], NSFontAttributeName, nil]];
    [[UINavigationBar appearance] setTitleVerticalPositionAdjustment:5 forBarMetrics:UIBarMetricsDefault];
    
    UIImageView *logoImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Logo.png"]];
    logoImageView.frame = CGRectMake(155, 8, 32, 32);
    logoImageView.tag = 800;
    [nav.navigationBar addSubview:logoImageView];
    
    ProjectDetailViewController *projectVC = (ProjectDetailViewController *)[UIApplication sharedApplication].delegate.window.rootViewController;
    
    [self dismissViewControllerAnimated:YES completion:^{
        
        [projectVC presentViewController:nav animated:YES completion:nil];
    }];
}

@end
