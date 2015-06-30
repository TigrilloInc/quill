//
//  InstabugViewController.m
//  quill
//
//  Created by Alex Costantini on 3/4/15.
//  Copyright (c) 2015 Tigrillo. All rights reserved.
//

#import "InstabugViewController.h"
#import "ProjectDetailViewController.h"
#import <Instabug/Instabug.h>

@implementation InstabugViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = @"Feedback";
    
    self.bugButton.layer.borderWidth = 1;
    self.bugButton.layer.cornerRadius = 10;
    self.bugButton.layer.borderColor = [UIColor lightGrayColor].CGColor;
    
    self.featureButton.layer.borderWidth = 1;
    self.featureButton.layer.cornerRadius = 10;
    self.featureButton.layer.borderColor = [UIColor grayColor].CGColor;
}

-(void) viewDidAppear:(BOOL)animated {
    
    ProjectDetailViewController *projectVC = (ProjectDetailViewController *)[UIApplication sharedApplication].delegate.window.rootViewController;
    projectVC.handleOutsideTaps = true;
}

-(void) viewWillDisappear:(BOOL)animated {
    
    ProjectDetailViewController *projectVC = (ProjectDetailViewController *)[UIApplication sharedApplication].delegate.window.rootViewController;
    projectVC.handleOutsideTaps = false;
}

- (IBAction)reportBugTapped:(id)sender {

    [self dismissViewControllerAnimated:YES completion:^{
        
        [Instabug invokeBugReporter];
    }];
}

- (IBAction)suggestFeatureTapped:(id)sender {

    [self dismissViewControllerAnimated:YES completion:^{
        
        [Instabug invokeFeedbackSender];
    }];
}

@end
