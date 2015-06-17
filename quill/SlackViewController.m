//
//  SlackViewController.m
//  quill
//
//  Created by Alex Costantini on 6/16/15.
//  Copyright (c) 2015 chalk. All rights reserved.
//

#import "SlackViewController.h"
#import "SlackChannelTableViewController.h"
#import "ProjectDetailViewController.h"
#import "ShareHelper.h"

@implementation SlackViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    self.navigationItem.title = @"Send to Slack";
    [self.navigationItem setHidesBackButton:YES];
    
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc]
                                   initWithTitle: @"Back"
                                   style: UIBarButtonItemStylePlain
                                   target:nil action:nil];
    [self.navigationItem setBackBarButtonItem: backButton];    
    
    self.postButton.layer.borderWidth = 1;
    self.postButton.layer.cornerRadius = 10;
    self.postButton.layer.borderColor = [UIColor grayColor].CGColor;
    
    ProjectDetailViewController *projectVC = (ProjectDetailViewController *)[UIApplication sharedApplication].delegate.window.rootViewController;
    
    BoardView *boardView;
    
    if (projectVC.versioning) boardView = (BoardView *)projectVC.versionsCarousel.currentItemView;
    else boardView = (BoardView *)projectVC.carousel.currentItemView;
    
    UIImage *boardImage = [boardView generateImage:YES];
    
    self.boardNameLabel.text = projectVC.boardNameLabel.text;
    
    [self.boardImageView setImage:boardImage];
    self.boardImageView.layer.borderWidth = 1;
    self.boardImageView.layer.borderColor = [UIColor lightGrayColor].CGColor;
    
}

- (void) viewWillAppear:(BOOL)animated {
    
    if ([ShareHelper sharedHelper].slackToken) {
    
        if (self.selectedChannelID) {
            
            NSString *channelName;
            
            for (NSDictionary *channelDict in [ShareHelper sharedHelper].slackChannels) {
                
                NSString *channelID = channelDict.allKeys[0];
                if ([channelID isEqualToString:self.selectedChannelID]) channelName = [channelDict objectForKey:channelID];
            }

            [self.channelButton setTitle:channelName forState:UIControlStateNormal];
            [self.channelButton sizeToFit];
            self.channelButton.frame = CGRectMake(525-self.channelButton.frame.size.width, 274, self.channelButton.frame.size.width, self.channelButton.frame.size.height);
        }
        else {
            
            NSString *channelsURL = [NSString stringWithFormat:@"https://slack.com/api/channels.list?token=%@&exclude_archived=1", [ShareHelper sharedHelper].slackToken];
            NSURLRequest *channelsRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:channelsURL]];
            
            NSURLConnection *channelsConnection =[[NSURLConnection alloc] initWithRequest:channelsRequest delegate:self];
        }
    }
    else {
        
        NSString *codeURL = [NSString stringWithFormat:@"https://slack.com/api/oauth.access?client_id=2420812446.6437258849&client_secret=7eac4229c79538b6cefb8bd1e60c489c&code=%@", self.code];
        NSURLRequest *tokenRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:codeURL]];
        
        NSURLConnection *tokenConnection =[[NSURLConnection alloc] initWithRequest:tokenRequest delegate:self];
    }
}

- (void) viewDidAppear:(BOOL)animated {
    
    outsideTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tappedOutside)];
    
    [outsideTapRecognizer setDelegate:self];
    [outsideTapRecognizer setNumberOfTapsRequired:1];
    outsideTapRecognizer.cancelsTouchesInView = NO;
    [self.view.window addGestureRecognizer:outsideTapRecognizer];
}

- (void)viewWillDisappear:(BOOL)animated {
    
    [super viewWillDisappear:animated];
    
    [self.commentTextView resignFirstResponder];
    
    [outsideTapRecognizer setDelegate:nil];
    [self.view.window removeGestureRecognizer:outsideTapRecognizer];
    
}

- (IBAction)channelTapped:(id)sender {

    SlackChannelTableViewController *channelsVC = [[SlackChannelTableViewController alloc] init];
    
    UIImageView *logoImage = (UIImageView *)[self.navigationController.navigationBar viewWithTag:800];
    
    logoImage.hidden = true;
    logoImage.frame = CGRectMake(160, 8, 32, 32);
    
    [self performSelector:@selector(showLogo) withObject:nil afterDelay:.3];
    
    [self.navigationController pushViewController:channelsVC animated:YES];
}

-(void)showLogo {
    
    UIImageView *logoImage = (UIImageView *)[self.navigationController.navigationBar viewWithTag:800];
    logoImage.alpha = 0;
    logoImage.hidden = false;
    
    [UIView animateWithDuration:.3 animations:^{
        logoImage.alpha = 1;
    }];
}

-(void) tappedOutside {
    
    if (outsideTapRecognizer.state == UIGestureRecognizerStateEnded) {
        
        CGPoint location = [outsideTapRecognizer locationInView:nil];
        CGPoint converted = [self.view convertPoint:CGPointMake(1024-location.y,location.x) fromView:self.view.window];
        
        if (!CGRectContainsPoint(self.view.frame, converted)){
            
            [outsideTapRecognizer setDelegate:nil];
            [self.view.window removeGestureRecognizer:outsideTapRecognizer];
            [self dismissViewControllerAnimated:YES completion:nil];
        }
    }
}

#pragma mark - NSURLConnection Data Delegate

-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
    
    if (![ShareHelper sharedHelper].slackToken && [json objectForKey:@"access_token"]) {
        
        [ShareHelper sharedHelper].slackToken = [json objectForKey:@"access_token"];
        
        NSString *channelsURL = [NSString stringWithFormat:@"https://slack.com/api/channels.list?token=%@&exclude_archived=1", [ShareHelper sharedHelper].slackToken];
        NSURLRequest *channelsRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:channelsURL]];
        
        NSURLConnection *channelsConnection =[[NSURLConnection alloc] initWithRequest:channelsRequest delegate:self];
    }
    else if ([json objectForKey:@"channels"]) {
        
        NSMutableArray *channels = [[json objectForKey:@"channels"] mutableCopy];

        NSMutableArray *unsortedNames = [NSMutableArray array];

        for (NSDictionary *channel in channels) {

            if ([[channel objectForKey:@"is_member"] integerValue] == 1) [unsortedNames addObject:[channel objectForKey:@"name"]];
        }
        
        NSArray *sortedNames = [unsortedNames sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
        
        for (int i=0; i<sortedNames.count; i++) {
            
            NSString *channelID;
            
            for (NSDictionary *channel in channels) {
                
                if ([channel.allValues containsObject:sortedNames[i]]) {
                    channelID = [channel objectForKey:@"id"];
                    break;
                }
            }
            
            NSDictionary *channelDict = @{ channelID : sortedNames[i] };
            
            [[ShareHelper sharedHelper].slackChannels addObject:channelDict];
        }
        
        self.loadingLabel.hidden = true;
        self.commentTextView.hidden = false;
        self.boardImageView.hidden = false;
        self.channelLabel.hidden = false;
        self.channelButton.hidden = false;
        self.postButton.hidden = false;
        self.commentArrowImage.hidden = false;
        self.boardNameLabel.hidden = false;
        
        NSDictionary *channelDict = [ShareHelper sharedHelper].slackChannels[0];
        
        NSString *channelName = [channelDict objectForKey:channelDict.allKeys[0]];
        self.selectedChannelID = channelDict.allKeys[0];
        
        [self.channelButton setTitle:channelName forState:UIControlStateNormal];
        [self.channelButton sizeToFit];
        self.channelButton.frame = CGRectMake(525-self.channelButton.frame.size.width, 274, self.channelButton.frame.size.width, self.channelButton.frame.size.height);
    }
}

#pragma mark - UITextView Delegate

-(void) textViewDidBeginEditing:(UITextView *)textView {
    
    textView.alpha = 1;
    if ([textView.text isEqualToString:@"Add a comment..."]) textView.text = @"";
}

-(void) textViewDidEndEditing:(UITextView *)textView {
    
    if (textView.text.length == 0) {
        
        textView.text = @"Add a comment...";
        textView.alpha = .3;
    }
}


#pragma mark - UIGestureRecognizer Delegate

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    return YES;
}

@end
