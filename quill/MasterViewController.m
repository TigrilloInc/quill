//
//  MasterViewController.m
//  Quill
//
//  Created by Alex Costantini on 7/9/14.
//  Copyright (c) 2014 Tigrillo. All rights reserved.
//

#import "MasterViewController.h"
#import <Firebase/Firebase.h>
#import <FirebaseSimpleLogin/FirebaseSimpleLogin.h>
#import "FirebaseHelper.h"
#import "SignInViewController.h"
#import "SignUpFromInviteViewController.h"
#import "SettingsViewController.h"
#import "InviteViewController.h"
#import "NewProjectViewController.h"
#import "ProjectDetailViewController.h"
#import "DrawView.h"
#import "NSDate+ServerDate.h"

@interface MasterViewController ()

@end

@implementation MasterViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.defaultRow = [NSIndexPath indexPathForRow:0 inSection:0];
    self.avatarButton.hidden = true;
    //self.teamButton.titleLabel.font = [UIFont fontWithName:@"ZemestroStd-Bk" size:15];
    //self.nameButton.titleLabel.font = [UIFont fontWithName:@"ZemestroStd-Bk" size:20];
    
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
    return [FirebaseHelper sharedHelper].visibleProjectIDs.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MasterCell" forIndexPath:indexPath];
    
    NSMutableArray *projectNames = [NSMutableArray array];
    
    for (NSString *projectID in [FirebaseHelper sharedHelper].visibleProjectIDs) {
        
        NSString *projectName = [(NSDictionary *)[[FirebaseHelper sharedHelper].projects objectForKey:projectID] objectForKey:@"name"];
        [projectNames addObject:projectName];
    }
    
    NSArray *orderedProjectNames = [projectNames sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    
    if (orderedProjectNames.count > indexPath.row)  {
        
        cell.textLabel.text = orderedProjectNames[indexPath.row];
        
        NSString *projectID;
        
        for (NSString *pID in [FirebaseHelper sharedHelper].visibleProjectIDs) {
            
            NSString *name = [[[FirebaseHelper sharedHelper].projects objectForKey:pID] objectForKey:@"name"];
            if ([name isEqualToString:orderedProjectNames[indexPath.row]]) projectID = pID;
        }
        
        NSNumber *updatedAtDate = [[[FirebaseHelper sharedHelper].projects objectForKey:projectID] objectForKey:@"updatedAt"];
        NSNumber *viewedAtDate = [[[[FirebaseHelper sharedHelper].projects objectForKey:projectID] objectForKey:@"viewedAt"] objectForKey:[FirebaseHelper sharedHelper].uid];
        
        if ([updatedAtDate doubleValue] > [viewedAtDate doubleValue] && !cell.selected) {
            NSLog(@"project %@ viewed at %@", projectID, viewedAtDate);
            cell.textLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:20];
        }
        else cell.textLabel.font = [UIFont fontWithName:@"Helvetica" size:20];
        
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    ProjectDetailViewController *projectVC = (ProjectDetailViewController *)[UIApplication sharedApplication].delegate.window.rootViewController;
    NSString *projectName = [tableView cellForRowAtIndexPath:indexPath].textLabel.text;
    
    NSString *projectID;
    
    for (NSString *pID in [FirebaseHelper sharedHelper].projects.allKeys) {
        
        if ([[[[FirebaseHelper sharedHelper].projects objectForKey:pID] objectForKey:@"name"] isEqualToString:projectName])
            projectID = pID;
    }
    
    if (projectID) {
        
        self.defaultRow = indexPath;
        
        [[FirebaseHelper sharedHelper] setProjectViewedAt];
        [[FirebaseHelper sharedHelper] updateCurrentProjectBoards];
        [[FirebaseHelper sharedHelper] removeCurrentProjectBoardObservers];
        [FirebaseHelper sharedHelper].currentProjectID = projectID;
        [[FirebaseHelper sharedHelper] observeCurrentProjectBoards];
        [[FirebaseHelper sharedHelper] setInProject];
        
        NSDictionary *projectDict = [[FirebaseHelper sharedHelper].projects objectForKey:projectID];
        
        projectVC.projectName = projectName;
        projectVC.chatID = (NSString *)[projectDict objectForKey:@"chatID"];
        projectVC.boardIDs = (NSMutableArray *)[projectDict objectForKey:@"boards"];
        projectVC.roles = [projectDict objectForKey:@"roles"];
        projectVC.userRole = [[projectVC.roles objectForKey:[FirebaseHelper sharedHelper].uid] intValue];
        projectVC.boardNameLabel.text = nil;
        projectVC.chatViewed = false;
        projectVC.viewedBoardIDs = [NSMutableArray array];
        
        [projectVC updateDetails];
        [projectVC cancelTapped:nil];
        if ([projectVC.chatTextField isFirstResponder]) [projectVC.chatTextField resignFirstResponder];
        if (projectVC.activeBoardID == nil) [projectVC.carousel scrollToItemAtIndex:projectVC.carousel.numberOfItems-1 duration:0];
        
    }
    
    [self.projectsTable reloadData];
    [self.projectsTable selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
    
}

- (IBAction)settingsTapped:(id)sender {
    
    SettingsViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"Settings"];
    
    vc.modalPresentationStyle = UIModalPresentationFormSheet;
    vc.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    [self.splitViewController presentViewController:vc animated:YES completion:nil];
}

- (IBAction)teamTapped:(id)sender {
    
    InviteViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"Invite"];
    
    vc.modalPresentationStyle = UIModalPresentationFormSheet;
    vc.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    [self.splitViewController presentViewController:vc animated:YES completion:nil];
}

- (IBAction)newProjectTapped:(id)sender {
    
    NewProjectViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"NewProject"];
    
    vc.modalPresentationStyle = UIModalPresentationFormSheet;
    vc.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    [self.splitViewController presentViewController:vc animated:YES completion:nil];
}

@end
