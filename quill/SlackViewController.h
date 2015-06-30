//
//  SlackViewController.h
//  quill
//
//  Created by Alex Costantini on 6/16/15.
//  Copyright (c) 2015 chalk. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RoundedButton.h"

@interface SlackViewController : UIViewController <UITextViewDelegate, NSURLConnectionDataDelegate>

@property (strong, nonatomic) NSString *code;
@property (strong, nonatomic) NSString *selectedChannelID;
@property (strong, nonatomic) UIImage *boardImage;
@property (weak, nonatomic) IBOutlet UITextView *commentTextView;
@property (weak, nonatomic) IBOutlet UIImageView *boardImageView;
@property (weak, nonatomic) IBOutlet UILabel *channelLabel;
@property (weak, nonatomic) IBOutlet UIButton *channelButton;
@property (weak, nonatomic) IBOutlet RoundedButton *postButton;
@property (weak, nonatomic) IBOutlet UILabel *loadingLabel;
@property (weak, nonatomic) IBOutlet UIImageView *commentArrowImage;
@property (weak, nonatomic) IBOutlet UILabel *boardNameLabel;


@end
