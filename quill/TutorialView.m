//
//  TutorialView.m
//  quill
//
//  Created by Alex Costantini on 6/9/15.
//  Copyright (c) 2015 chalk. All rights reserved.
//

#import "TutorialView.h"

@implementation TutorialView

-(id)initWithCoder:(NSCoder *)aDecoder {
    
    self = [super initWithCoder:aDecoder];
    if (self) {
        
        self.userInteractionEnabled = YES;
        
        self.gotItButton = [[RoundedButton alloc] initWithFrame:CGRectMake(0, 0, 310, 50)];
        [self addSubview:self.gotItButton];
        
        self.gotItButton.titleLabel.textColor = [UIColor whiteColor];
        self.gotItButton.titleLabel.font = [UIFont fontWithName:@"SourceSansPro-Semibold" size:24];
        
        [self.gotItButton setTitle:@"Got it!" forState:UIControlStateNormal];
        [self.gotItButton addTarget:self action:@selector(gotItTapped) forControlEvents:UIControlEventTouchUpInside];
        
        self.gotItButton.center = self.center;
        self.gotItButton.layer.borderWidth = 1;
        self.gotItButton.layer.cornerRadius = 10;
        self.gotItButton.layer.borderColor = [UIColor whiteColor].CGColor;
    }
    return self;
}

-(void)updateTutorial {
    
    NSString *imageString;
    
    if (self.type == 1) {
        imageString = @"projecttutorial.png";
        self.gotItButton.center = self.center;
    }
    else if (self.type == 2) {
        imageString = @"edittutorial.png";
        self.gotItButton.center = self.center;
    }
    else if (self.type == 3) {
        imageString = @"versionstutorial.png";
        self.gotItButton.center = self.center;
    }
    else if (self.type == 4) {
        imageString = @"boardtutorial.png";
        self.gotItButton.center = self.center;
    }
    else if (self.type == 5) {
        imageString = @"commenttutorial.png";
        self.gotItButton.center = CGPointMake(self.center.x, 540);
    }
    else if (self.type == 6) {
        imageString = @"emptytutorial.png";
        self.gotItButton.center = self.center;
    }
    
    [self setImage:[UIImage imageNamed:imageString]];
    
    self.hidden = false;
}

-(void)gotItTapped {
    
    NSString *tutorialString;
    
    if (self.type == 1) tutorialString = @"projectTutorial";
    else if (self.type == 2) tutorialString = @"editTutorial";
    else if (self.type == 3) tutorialString = @"versionsTutorial";
    else if (self.type == 4) tutorialString = @"boardTutorial";
    else if (self.type == 5) tutorialString = @"commentTutorial";
    else if (self.type == 6) tutorialString = @"emptyTutorial";
    
    [[NSUserDefaults standardUserDefaults] setObject:@1 forKey:tutorialString];
    
    self.hidden = true;
}

@end
