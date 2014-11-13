//
//  SplitViewController.h
//  Quill
//
//  Created by Alex Costantini on 8/11/14.
//  Copyright (c) 2014 Tigrillo. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DrawView.h"

@interface SplitViewController : UISplitViewController

@property (strong, nonatomic) DrawView *drawView;

@end
