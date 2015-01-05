//
//  ColorPopoverViewController.m
//  quill
//
//  Created by Alex Costantini on 12/17/14.
//  Copyright (c) 2014 chalk. All rights reserved.
//

#import "ColorPopoverViewController.h"
#import "ProjectDetailViewController.h"
#import "BoardView.h"

@interface ColorPopoverViewController ()

@end

@implementation ColorPopoverViewController

-(void)viewDidLoad {
    [super viewDidLoad];

    colors = @[ @"black.png",
                @"blue.png",
                @"red.png",
                @"green.png",
                ];
    
    for (int i=0; i<colors.count; i++) {
        
        UIButton *colorButton = [UIButton buttonWithType:UIButtonTypeSystem];
        colorButton.frame = CGRectMake(15, 18+i*70, 50, 50);
        [colorButton setBackgroundImage:[UIImage imageNamed:colors[i]] forState:UIControlStateNormal];
        [colorButton addTarget:self action:@selector(colorTapped:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:colorButton];
        colorButton.tag = i+1;
    }
    
    self.preferredContentSize = CGSizeMake(80, 18+colors.count*70);
}

-(void)colorTapped:(id)sender {
    
    UIButton *colorButton = (UIButton *)sender;
    
    ProjectDetailViewController *projectVC = (ProjectDetailViewController *)[UIApplication sharedApplication].delegate.window.rootViewController;
    projectVC.currentBoardView.lineColorNumber = @(colorButton.tag);
    
    for (int i=5; i<8; i++) {
        
        if (i==7) continue;
        
        UIView *button = [projectVC.view viewWithTag:i];
        if (i==5) [button viewWithTag:50].hidden = false;
        else [button viewWithTag:50].hidden = true;
    }
    
    NSString *imageName = colors[colorButton.tag-1];
    
    [(UIButton *)[projectVC.view viewWithTag:7] setBackgroundImage:[UIImage imageNamed:imageName] forState:UIControlStateNormal];
    
    [self dismissViewControllerAnimated:NO completion:nil];
}

@end
