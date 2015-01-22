//
//  CommentPopoverViewController.m
//  quill
//
//  Created by Alex Costantini on 1/15/15.
//  Copyright (c) 2015 chalk. All rights reserved.
//

#import "CommentPopoverViewController.h"
#import "ProjectDetailViewController.h"

@implementation CommentPopoverViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    options = @[ @"Leave a comment",
                 @"Hide comments"
                ];
    
    self.preferredContentSize = CGSizeMake(175, 18+options.count*45);
    ProjectDetailViewController *projectVC = (ProjectDetailViewController *)[UIApplication sharedApplication].delegate.window.rootViewController;
    
    for (int i=0; i<options.count; i++) {
        
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.frame = CGRectMake(0, 12+i*45, 50, 50);
        if (i==1 && !projectVC.currentBoardView.hideComments) [button setTitle:@"Show comments" forState:UIControlStateNormal];
        else [button setTitle:options[i] forState:UIControlStateNormal];
        button.titleLabel.font = [UIFont fontWithName:@"SourceSansPro-Regular" size:18];
        [button setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [button sizeToFit];
        button.center = CGPointMake(self.preferredContentSize.width/2, button.center.y);
        [button addTarget:self action:@selector(buttonTapped:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:button];
        button.tag = i;
    }
}

-(void)buttonTapped:(id)sender {
    
    UIButton *button = (UIButton *)sender;
    ProjectDetailViewController *projectVC = (ProjectDetailViewController *)[UIApplication sharedApplication].delegate.window.rootViewController;
    
    if (button.tag == 0) {
        
        for (int i=5; i<=8; i++) {
            
            if (i==7) continue;
            
            UIView *button = [projectVC.view viewWithTag:i];
            if (i==8) [button viewWithTag:50].hidden = false;
            else [button viewWithTag:50].hidden = true;
        }
        
        [projectVC.currentBoardView layoutComments];
        projectVC.currentBoardView.hideComments = true;
        
        projectVC.currentBoardView.commenting = true;
    }
    
    if (button.tag == 1) {
        
        for (CommentButton *comment in projectVC.currentBoardView.commentButtons) comment.hidden = projectVC.currentBoardView.hideComments;
        
        projectVC.currentBoardView.hideComments = !projectVC.currentBoardView.hideComments;
    }
    
    [self dismissViewControllerAnimated:NO completion:nil];
}

@end
