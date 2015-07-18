//
//  CommentPopoverViewController.m
//  quill
//
//  Created by Alex Costantini on 1/15/15.
//  Copyright (c) 2015 Tigrillo. All rights reserved.
//

#import "CommentPopoverViewController.h"
#import "ProjectDetailViewController.h"

@implementation CommentPopoverViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    options = @[ @"leavecomment",
                 @"hidecomments"
                ];
    
    self.preferredContentSize = CGSizeMake(170, 10+options.count*50);
    ProjectDetailViewController *projectVC = (ProjectDetailViewController *)[UIApplication sharedApplication].delegate.window.rootViewController;
    
    for (int i=0; i<options.count; i++) {
        
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.frame = CGRectMake(0, 5+i*50, 170, 50);
        if (i==1 && !projectVC.currentBoardView.hideComments) {
            [button setImage:[UIImage imageNamed:@"showcomments.png"] forState:UIControlStateNormal];
            [button setImage:[UIImage imageNamed:@"showcomments-highlighted.png"] forState:UIControlStateHighlighted];
        }
        else {
            NSString *imageString = [NSString stringWithFormat:@"%@.png", options[i]];
            [button setImage:[UIImage imageNamed:imageString] forState:UIControlStateNormal];
            NSString *highlightedString = [NSString stringWithFormat:@"%@-highlighted.png", options[i]];
            [button setImage:[UIImage imageNamed:imageString] forState:UIControlStateNormal];
            [button setImage:[UIImage imageNamed:highlightedString] forState:UIControlStateHighlighted];
        }
        [button addTarget:self action:@selector(buttonTapped:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:button];
        button.tag = i;
    }
}

-(void)buttonTapped:(id)sender {
    
    UIButton *button = (UIButton *)sender;
    ProjectDetailViewController *projectVC = (ProjectDetailViewController *)[UIApplication sharedApplication].delegate.window.rootViewController;
    
    if (button.tag == 0) {
        
        for (int i=6; i<=10; i++) {
            
            if (i==8) continue;
            
            UIView *button = [projectVC.view viewWithTag:i];
            if (i==10) [button viewWithTag:50].hidden = false;
            else [button viewWithTag:50].hidden = true;
        }
        
        [projectVC.currentBoardView layoutComments];
        projectVC.currentBoardView.hideComments = true;
        
        projectVC.currentBoardView.commenting = true;
        
        [projectVC.currentBoardView bringSubviewToFront:projectVC.currentBoardView.fadeView];
        projectVC.currentBoardView.fadeView.hidden = false;
        [projectVC.currentBoardView bringSubviewToFront:projectVC.currentBoardView.leaveCommentLabel];
        projectVC.currentBoardView.leaveCommentLabel.hidden = false;
        
        if (![[NSUserDefaults standardUserDefaults] objectForKey:@"commentTutorial"]) {
            
            projectVC.tutorialView.type = 5;
            [projectVC.view bringSubviewToFront:projectVC.tutorialView];
            [projectVC.tutorialView updateTutorial];
        }
    }
    
    if (button.tag == 1) {
        
        for (CommentButton *comment in projectVC.currentBoardView.commentButtons) comment.hidden = projectVC.currentBoardView.hideComments;
        
        projectVC.currentBoardView.hideComments = !projectVC.currentBoardView.hideComments;
    }
    
    [self dismissViewControllerAnimated:NO completion:nil];
}

@end
