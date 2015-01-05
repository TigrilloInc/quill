//
//  WidthPopoverViewController.m
//  quill
//
//  Created by Alex Costantini on 12/17/14.
//  Copyright (c) 2014 chalk. All rights reserved.
//

#import "PenTypePopoverViewController.h"
#import "ProjectDetailViewController.h"
#import "BoardView.h"

@implementation PenTypePopoverViewController

-(void)viewDidLoad {
    [super viewDidLoad];
    
    pens = @[ @"pen.png",
              @"marker.png",
              @"highlighter.png"
            ];
    
    for (int i=0; i<3; i++) {
        
        UIButton *penButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [penButton setImage:[UIImage imageNamed:pens[i]] forState:UIControlStateNormal];
        penButton.frame = CGRectMake(15, 18+i*70, 50, 50);
        [penButton addTarget:self action:@selector(penTapped:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:penButton];
        penButton.tag = i+1;
    }
    
    self.preferredContentSize = CGSizeMake(80, 18+pens.count*70);
}

-(void)penTapped:(id)sender {
    
    UIButton *penButton = (UIButton *)sender;
    
    ProjectDetailViewController *projectVC = (ProjectDetailViewController *)[UIApplication sharedApplication].delegate.window.rootViewController;
    
    NSString *imageName = pens[penButton.tag-1];
    
    projectVC.currentBoardView.penType = penButton.tag;
    [(UIButton *)[projectVC.view viewWithTag:5] setBackgroundImage:[UIImage imageNamed:imageName] forState:UIControlStateNormal];
    
    [self dismissViewControllerAnimated:NO completion:nil];
}


@end
