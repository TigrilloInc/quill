//
//  ShapePopoverViewController.m
//  quill
//
//  Created by Alex Costantini on 7/8/15.
//  Copyright (c) 2015 chalk. All rights reserved.
//

#import "ShapePopoverViewController.h"
#import "ProjectDetailViewController.h"
#import "BoardView.h"

@implementation ShapePopoverViewController

-(void)viewDidLoad {
    [super viewDidLoad];
    
    shapes = @[ @"shape.png",
                @"ellipse.png",
                @"line.png"
              ];
    
    for (int i=0; i<3; i++) {
        
        UIButton *shapeButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [shapeButton setImage:[UIImage imageNamed:shapes[i]] forState:UIControlStateNormal];
        shapeButton.frame = CGRectMake(15, 18+i*70, 50, 50);
        [shapeButton addTarget:self action:@selector(shapeTapped:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:shapeButton];
        shapeButton.tag = i+1;
    }
    
    self.preferredContentSize = CGSizeMake(80, 18+shapes.count*70);
}

-(void)shapeTapped:(id)sender {
    
    UIButton *shapeButton = (UIButton *)sender;
    ProjectDetailViewController *projectVC = (ProjectDetailViewController *)[UIApplication sharedApplication].delegate.window.rootViewController;
    
    NSString *imageName = shapes[shapeButton.tag-1];
    projectVC.currentBoardView.shapeType = shapeButton.tag;
    [(UIButton *)[projectVC.view viewWithTag:5] setBackgroundImage:[UIImage imageNamed:imageName] forState:UIControlStateNormal];
    
    [self dismissViewControllerAnimated:NO completion:nil];
}


@end
