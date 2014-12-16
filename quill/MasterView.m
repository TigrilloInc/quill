
//
//  MasterView.m
//  Quill
//
//  Created by Alex Costantini on 7/9/14.
//  Copyright (c) 2014 Tigrillo. All rights reserved.
//

#import "MasterView.h"
#import <Firebase/Firebase.h>
#import <FirebaseSimpleLogin/FirebaseSimpleLogin.h>
#import "FirebaseHelper.h"
#import "SignInViewController.h"
#import "SignUpFromInviteViewController.h"
#import "SettingsViewController.h"
#import "InviteViewController.h"
#import "NewProjectViewController.h"
#import "DrawView.h"
#import "NSDate+ServerDate.h"
#import "ProjectDetailViewController.h"
#import "ProjectsTableViewCell.h"

@interface MasterView ()

@end

@implementation MasterView

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    
    if (self) {
        
        self.defaultRow = [NSIndexPath indexPathForRow:0 inSection:0];
        
        projectVC = (ProjectDetailViewController *)[UIApplication sharedApplication].delegate.window.rootViewController;
    }
    
    return self;
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    
    if (self) {
        
        self.defaultRow = [NSIndexPath indexPathForRow:0 inSection:0];
        
        projectVC = (ProjectDetailViewController *)[UIApplication sharedApplication].delegate.window.rootViewController;
    }
    
    return self;
}

-(void)updateProjects {
    
    NSMutableArray *projectNames = [NSMutableArray array];
    
    for (NSString *projectID in [FirebaseHelper sharedHelper].visibleProjectIDs) {
        
        NSString *projectName = [(NSDictionary *)[[FirebaseHelper sharedHelper].projects objectForKey:projectID] objectForKey:@"name"];
        [projectNames addObject:projectName];
    }
    
    self.orderedProjectNames = [projectNames sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return @"Projects";
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 30.0f;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [FirebaseHelper sharedHelper].visibleProjectIDs.count+1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ProjectsTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MasterCell" forIndexPath:indexPath];
    cell.backgroundColor = tableView.backgroundColor;
    
    [self updateProjects];
    
    if (indexPath.row == [FirebaseHelper sharedHelper].visibleProjectIDs.count) {
        
        cell.textLabel.text = @" +   NEW PROJECT";
        return cell;
    }
    
    if (self.orderedProjectNames.count > indexPath.row)  {
        
        cell.textLabel.text = self.orderedProjectNames[indexPath.row];
        
        NSString *projectID;
        
        for (NSString *pID in [FirebaseHelper sharedHelper].visibleProjectIDs) {
            
            NSString *name = [[[FirebaseHelper sharedHelper].projects objectForKey:pID] objectForKey:@"name"];
            if ([name isEqualToString:self.orderedProjectNames[indexPath.row]]) projectID = pID;
        }
        
        NSString *updatedAtString = [[[FirebaseHelper sharedHelper].projects objectForKey:projectID] objectForKey:@"updatedAt"];
        NSString *viewedAtString = [[[[FirebaseHelper sharedHelper].projects objectForKey:projectID] objectForKey:@"viewedAt"] objectForKey:[FirebaseHelper sharedHelper].uid];
        
        if ([updatedAtString doubleValue] > [viewedAtString doubleValue] && !cell.selected)
            cell.textLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:20];
        
        cell.selectedBackgroundView.backgroundColor = [UIColor colorWithRed:.9176 green:.9176 blue:.8863 alpha:1];
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.row == [FirebaseHelper sharedHelper].visibleProjectIDs.count) {
        
        [self newProjectTapped];
        [tableView selectRowAtIndexPath:self.defaultRow animated:NO scrollPosition:UITableViewScrollPositionNone];
        return;
    }
    
    ProjectsTableViewCell *cell = (ProjectsTableViewCell *)[tableView cellForRowAtIndexPath:indexPath];
    
    NSString *projectName = cell.textLabel.text;
    NSString *projectID;
    
    for (NSString *pID in [FirebaseHelper sharedHelper].projects.allKeys) {
        
        if ([[[[FirebaseHelper sharedHelper].projects objectForKey:pID] objectForKey:@"name"] isEqualToString:projectName])
            projectID = pID;
    }
    
    if (projectID) {
        
        self.defaultRow = indexPath;
        
        NSDictionary *projectDict = [[FirebaseHelper sharedHelper].projects objectForKey:projectID];
        
        projectVC.projectName = projectName;
        projectVC.chatID = (NSString *)[projectDict objectForKey:@"chatID"];
        projectVC.boardIDs = (NSMutableArray *)[projectDict objectForKey:@"boards"];
        projectVC.roles = [projectDict objectForKey:@"roles"];
        projectVC.userRole = [[projectVC.roles objectForKey:[FirebaseHelper sharedHelper].uid] intValue];
        projectVC.boardNameLabel.text = nil;
        projectVC.chatViewed = false;
        projectVC.viewedBoardIDs = [NSMutableArray array];
        
        [[FirebaseHelper sharedHelper] setProjectViewedAt];
        [FirebaseHelper sharedHelper].currentProjectID = projectID;
        [[FirebaseHelper sharedHelper] setInProject:projectID];
        [[FirebaseHelper sharedHelper] observeCurrentProjectBoards];
        
        [projectVC updateDetails];
        [projectVC cancelTapped:nil];
        if ([projectVC.chatTextField isFirstResponder]) [projectVC.chatTextField resignFirstResponder];
        if (projectVC.activeBoardID == nil) [projectVC.carousel scrollToItemAtIndex:projectVC.carousel.numberOfItems-1 duration:0];
    }
    
    [self.projectsTable reloadData];
    [self.projectsTable selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
    
}

- (IBAction)settingsTapped:(id)sender {
    
    SettingsViewController *vc = [projectVC.storyboard instantiateViewControllerWithIdentifier:@"Settings"];
    
    vc.modalPresentationStyle = UIModalPresentationFormSheet;
    vc.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    [projectVC presentViewController:vc animated:YES completion:nil];
}

- (IBAction)teamTapped:(id)sender {

    InviteViewController *vc = [projectVC.storyboard instantiateViewControllerWithIdentifier:@"Invite"];
    
    vc.modalPresentationStyle = UIModalPresentationFormSheet;
    vc.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    [projectVC presentViewController:vc animated:YES completion:nil];
}

- (void)newProjectTapped {
    
    NewProjectViewController *vc = [projectVC.storyboard instantiateViewControllerWithIdentifier:@"NewProject"];
    
    vc.modalPresentationStyle = UIModalPresentationFormSheet;
    vc.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    [projectVC presentViewController:vc animated:YES completion:nil];
}

@end
