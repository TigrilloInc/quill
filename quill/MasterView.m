
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
#import "PersonalSettingsViewController.h"
#import "TeamSettingsViewController.h"
#import "NewProjectViewController.h"
#import "BoardView.h"
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
        self.avatarShadow = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"userbuttonmask3.png"]];
        self.avatarShadow.frame = CGRectMake(9, 78, 62, 62);
        self.avatarShadow.hidden = true;
        [self addSubview:self.avatarShadow];
        
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

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    
    return 1;
}

//-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
//{
//    return @"Projects";
//}
//
//
//- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
//{
//    return 30.0f;
//}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    return [FirebaseHelper sharedHelper].visibleProjectIDs.count+1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    ProjectsTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MasterCell" forIndexPath:indexPath];
    cell.backgroundColor = tableView.backgroundColor;
    
    cell.textLabel.text = nil;
    cell.imageView.image = nil;
    
    [self updateProjects];
    
    if (indexPath.row == [FirebaseHelper sharedHelper].visibleProjectIDs.count && [FirebaseHelper sharedHelper].projectsLoaded) {
        
        UIGraphicsBeginImageContextWithOptions(CGSizeMake(28, 28), NO, 0.0);
        UIImage *plusImage = [UIImage imageNamed:@"plus5.png"];
        [plusImage drawInRect:CGRectMake(0,0,28,28)];
        UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        cell.imageView.image = newImage;
        cell.textLabel.text = @"New Project";
        cell.textLabel.font = [UIFont fontWithName:@"SourceSansPro-Regular" size:20];
        cell.textLabel.textColor = self.backgroundColor;
        return cell;
    }
    
    if (self.orderedProjectNames.count > indexPath.row)  {
        
        cell.textLabel.text = self.orderedProjectNames[indexPath.row];
        cell.textLabel.font = [UIFont fontWithName:@"SourceSansPro-Light" size:20];
        cell.textLabel.textColor = [UIColor blackColor];
        cell.imageView.image = nil;
        
        NSString *projectID;
        
        for (NSString *pID in [FirebaseHelper sharedHelper].visibleProjectIDs) {
            
            NSString *name = [[[FirebaseHelper sharedHelper].projects objectForKey:pID] objectForKey:@"name"];
            if ([name isEqualToString:self.orderedProjectNames[indexPath.row]]) projectID = pID;
        }
        
        NSString *updatedAtString = [[[FirebaseHelper sharedHelper].projects objectForKey:projectID] objectForKey:@"updatedAt"];
        NSString *viewedAtString = [[[[FirebaseHelper sharedHelper].projects objectForKey:projectID] objectForKey:@"viewedAt"] objectForKey:[FirebaseHelper sharedHelper].uid];
        
        if ([updatedAtString doubleValue] > [viewedAtString doubleValue] && !cell.selected)
            cell.textLabel.font = [UIFont fontWithName:@"SourceSansPro-Semibold" size:20];
        
        cell.selectedBackgroundView.backgroundColor = [UIColor colorWithRed:.9176 green:.9176 blue:.8863 alpha:1];
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    ProjectsTableViewCell *cell = (ProjectsTableViewCell *)[tableView cellForRowAtIndexPath:indexPath];
    cell.textLabel.font = [UIFont fontWithName:@"SourceSansPro-Light" size:20];
    
    if (indexPath.row == [FirebaseHelper sharedHelper].visibleProjectIDs.count) {
        
        [self newProjectTapped];
        return;
    }
    
    NSString *projectName = cell.textLabel.text;
    NSString *projectID;
    
    for (NSString *pID in [FirebaseHelper sharedHelper].projects.allKeys) {
        
        if ([[[[FirebaseHelper sharedHelper].projects objectForKey:pID] objectForKey:@"name"] isEqualToString:projectName])
            projectID = pID;
    }
    
    //if ([projectID isEqualToString:[FirebaseHelper sharedHelper].currentProjectID]) return;
    
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
        projectVC.editedBoardIDs = [NSMutableArray array];
   
        BOOL differentProject = false;
        if (![[FirebaseHelper sharedHelper].currentProjectID isEqualToString:projectID]) differentProject = true;

        [[FirebaseHelper sharedHelper] setProjectViewedAt];
        [FirebaseHelper sharedHelper].currentProjectID = projectID;
        [[FirebaseHelper sharedHelper] setInProject:projectID];
        [[FirebaseHelper sharedHelper] observeCurrentProjectBoards];
        
        if (projectVC.versioning) [projectVC versionsTapped:nil];
        
        [projectVC updateDetails:differentProject];
        [projectVC cancelTapped:nil];
        if ([projectVC.chatTextField isFirstResponder]) [projectVC.chatTextField resignFirstResponder];
        if (differentProject && projectVC.activeBoardID == nil) [projectVC.carousel scrollToItemAtIndex:projectVC.carousel.numberOfItems-1 duration:0];
    }
    
    [self.projectsTable reloadData];
    [self.projectsTable selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
}

- (IBAction)settingsTapped:(id)sender {
    
    PersonalSettingsViewController *vc = [projectVC.storyboard instantiateViewControllerWithIdentifier:@"Settings"];
    vc.avatarImage = [FirebaseHelper sharedHelper].avatarImage;
    
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    nav.modalPresentationStyle = UIModalPresentationFormSheet;
    nav.modalTransitionStyle = UIModalTransitionStyleCoverVertical;

    UIImageView *logoImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Logo.png"]];
    logoImageView.frame = CGRectMake(156, 8, 32, 32);
    logoImageView.tag = 800;
    [nav.navigationBar addSubview:logoImageView];
    
    [projectVC presentViewController:nav animated:YES completion:nil];
}

- (IBAction)teamTapped:(id)sender {

    TeamSettingsViewController *teamVC = [projectVC.storyboard instantiateViewControllerWithIdentifier:@"TeamSettings"];

    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:teamVC];
    nav.modalPresentationStyle = UIModalPresentationFormSheet;
    nav.modalTransitionStyle = UIModalTransitionStyleCoverVertical;

    UIImageView *logoImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Logo.png"]];
    logoImageView.frame = CGRectMake(173, 8, 32, 32);
    logoImageView.tag = 800;
    [nav.navigationBar addSubview:logoImageView];
    
    [projectVC presentViewController:nav animated:YES completion:nil];
}

- (void)newProjectTapped {
    
    NewProjectViewController *vc = [projectVC.storyboard instantiateViewControllerWithIdentifier:@"NewProject"];
    
    vc.modalPresentationStyle = UIModalPresentationFormSheet;
    vc.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    [projectVC presentViewController:vc animated:YES completion:nil];
}

@end
