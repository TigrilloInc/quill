//
//  AddUserViewController.m
//  Quill
//
//  Created by Alex Costantini on 10/9/14.
//  Copyright (c) 2014 Tigrillo. All rights reserved.
//

#import "AddUserViewController.h"
#import "FirebaseHelper.h"

@implementation AddUserViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    
    }
    
    return self;
}

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    self.selectedUsers = [NSMutableArray array];
    
    projectVC = (ProjectDetailViewController *)[UIApplication sharedApplication].delegate.window.rootViewController;
    
    NSMutableDictionary *usersDict = (NSMutableDictionary *)CFBridgingRelease(CFPropertyListCreateDeepCopy(kCFAllocatorDefault, (CFDictionaryRef)[[FirebaseHelper sharedHelper].team objectForKey:@"users"], kCFPropertyListMutableContainers));
    for (NSString *userID in usersDict.allKeys) {
        
        if ([projectVC.roles.allKeys containsObject:userID]) [usersDict removeObjectForKey:userID];
    }
    self.availableUsersDict = usersDict;
    
    self.usersTable.scrollEnabled = NO;
    
    if (projectVC.userRole == 0) {
        self.roleSwitch.on = true;
        self.roleSwitch.enabled = false;
        self.roleSwitch.alpha = 0.3;
    }
    else [self.roleSwitch setOn:NO animated:NO];
    
}

- (void) viewDidAppear:(BOOL)animated
{
    
    outsideTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tappedOutside)];
    
    [outsideTapRecognizer setNumberOfTapsRequired:1];
    outsideTapRecognizer.cancelsTouchesInView = NO;
    [self.view.window addGestureRecognizer:outsideTapRecognizer];
}

-(void) tappedOutside
{
    
    if (outsideTapRecognizer.state == UIGestureRecognizerStateEnded)
    {
        CGPoint location = [outsideTapRecognizer locationInView:nil];
        
        if (![self.view pointInside:[self.view convertPoint:location fromView:self.view.window] withEvent:nil]){
            
            [self.view.window removeGestureRecognizer:outsideTapRecognizer];
            [self dismissViewControllerAnimated:YES completion:nil];
        }
    }
}

- (IBAction)addUserTapped:(id)sender {

    NSString *projectString = [NSString stringWithFormat:@"https://chalkto.firebaseio.com/projects/%@/info/roles", [FirebaseHelper sharedHelper].currentProjectID];
    Firebase *ref = [[Firebase alloc] initWithUrl:projectString];
    
    for (NSString *userID in self.selectedUsers) {
        
        if (self.roleSwitch.on) [projectVC.roles setObject:@0 forKey:userID];
        else [projectVC.roles setObject:@1 forKey:userID];
    }

    [ref updateChildValues:projectVC.roles withCompletionBlock:^(NSError *error, Firebase *ref) {
        
        [self.view.window removeGestureRecognizer:outsideTapRecognizer];
        [self dismissViewControllerAnimated:YES completion:nil];
        [projectVC updateDetails];
    }];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    return self.availableUsersDict.allKeys.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"UserCell" forIndexPath:indexPath];
    
    NSString *userID = self.availableUsersDict.allKeys[indexPath.row];
    
    cell.textLabel.text = [[self.availableUsersDict objectForKey:userID] objectForKey:@"name"];
    //cell.textLabel.font = [UIFont fontWithName:@"ZemestroStd-Bk" size:20];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.imageView.image = [UIImage imageNamed:@"user.png"];

    if ([self.selectedUsers containsObject:userID]) cell.accessoryType = UITableViewCellAccessoryCheckmark;
    else cell.accessoryType = UITableViewCellAccessoryNone;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *userID = self.availableUsersDict.allKeys[indexPath.row];

    if ([self.selectedUsers containsObject:userID]) [self.selectedUsers removeObject:userID];
    else [self.selectedUsers addObject:userID];
    
    [tableView reloadData];
}

@end
