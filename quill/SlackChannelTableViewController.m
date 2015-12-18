//
//  SlackChannelTableViewController.m
//  quill
//
//  Created by Alex Costantini on 6/16/15.
//  Copyright (c) 2015 chalk. All rights reserved.
//

#import "SlackChannelTableViewController.h"
#import "SlackViewController.h"
#import "ShareHelper.h"

@implementation SlackChannelTableViewController

-(void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = @"Select a Channel";
    
    logoImage = (UIImageView *)[self.navigationController.navigationBar viewWithTag:800];
}

-(void)viewWillDisappear:(BOOL)animated {
    
    if ([self.navigationController.viewControllers indexOfObject:self]==NSNotFound) {
        
        logoImage.hidden = true;
        logoImage.frame = CGRectMake(175, 8, 32, 32);
        
        [self performSelector:@selector(showLogo) withObject:nil afterDelay:.3];
    }
}

-(void)showLogo {
    
    logoImage.alpha = 0;
    logoImage.hidden = false;
    
    [UIView animateWithDuration:.3 animations:^{
        logoImage.alpha = 1;
    }];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

    return [ShareHelper sharedHelper].slackChannels.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [[UITableViewCell alloc] init];
    
    cell.textLabel.font = [UIFont fontWithName:@"SourceSansPro-Regular" size:20];
    NSDictionary *channelDict = [ShareHelper sharedHelper].slackChannels[indexPath.row];
    cell.textLabel.text = [channelDict objectForKey:channelDict.allKeys[0]];
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    SlackViewController *slackVC = self.navigationController.viewControllers[0];
    NSDictionary *channelDict = [ShareHelper sharedHelper].slackChannels[indexPath.row];

    slackVC.selectedChannelID = channelDict.allKeys[0];
    
    [self.navigationController popViewControllerAnimated:YES];
}

@end
