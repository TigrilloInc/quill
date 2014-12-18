//
//  WidthPopoverViewController.m
//  quill
//
//  Created by Alex Costantini on 12/17/14.
//  Copyright (c) 2014 chalk. All rights reserved.
//

#import "WidthPopoverViewController.h"
#import "ProjectDetailViewController.h"
#import "DrawView.h"

@interface WidthPopoverViewController ()

@end

@implementation WidthPopoverViewController

-(void)viewDidLoad {
    [super viewDidLoad];
    
    int colorCount = 3;
    
    for (int i=0; i<colorCount; i++) {
        
        UIButton *colorButton = [UIButton buttonWithType:UIButtonTypeSystem];
        colorButton.frame = CGRectMake(0, i*40, 70, 40);
        [colorButton setTitle:[NSString stringWithFormat:@"%i", i+1] forState:UIControlStateNormal];
        [colorButton addTarget:self action:@selector(widthTapped:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:colorButton];
        colorButton.tag = i+3;
    }
    
    self.preferredContentSize = CGSizeMake(70, colorCount*40);
}

-(void)widthTapped:(id)sender {
    
    UIButton *widthButton = (UIButton *)sender;
    
    ProjectDetailViewController *projectVC = (ProjectDetailViewController *)[UIApplication sharedApplication].delegate.window.rootViewController;
    projectVC.currentDrawView.lineWidth = widthButton.tag*widthButton.tag/3;
    
    [self dismissViewControllerAnimated:NO completion:nil];
}


@end
