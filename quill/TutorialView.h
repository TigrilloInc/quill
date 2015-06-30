//
//  TutorialView.h
//  quill
//
//  Created by Alex Costantini on 6/9/15.
//  Copyright (c) 2015 chalk. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RoundedButton.h"

@interface TutorialView : UIImageView

@property int type;
@property (strong, nonatomic) RoundedButton *gotItButton;

-(void)updateTutorial;

@end
