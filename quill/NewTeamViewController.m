//
//  NewTeamViewController.m
//  Quill
//
//  Created by Alex Costantini on 7/7/14.
//  Copyright (c) 2014 Tigrillo. All rights reserved.
//

#import "NewTeamViewController.h"
#import <Firebase/Firebase.h>
#import "FirebaseHelper.h"


@implementation NewTeamViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.nameField.placeholder = @"Your Name";
    self.teamField.placeholder = @"Team Name";
    
    self.nameField.delegate = self;
    self.teamField.delegate = self;

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    
    
}

- (IBAction)createTeamTapped:(id)sender {
    
    NSString *name = self.nameField.text;
    NSString *team = self.teamField.text;
    
    if (name.length > 0 && team.length > 0) {
        
        Firebase *ref = [[Firebase alloc] initWithUrl:@"https://chalkto.firebaseio.com/"];
        
        NSDictionary *newTeamValues = @{ team :
                                             @{ @"users" :
                                                    @{ [FirebaseHelper sharedHelper].uid : @1 }
                                                }
                                         };
        
        [[ref childByAppendingPath:@"teams"] updateChildValues:newTeamValues];
        
        NSString *userPath = [NSString stringWithFormat:@"users/%@", [FirebaseHelper sharedHelper].uid];
        
        [[ref childByAppendingPath:userPath] updateChildValues:@{ @"name" : name,
                                                                  @"team" : team  }];
        
        [self dismissViewControllerAnimated:YES completion:nil];
        
        [[FirebaseHelper sharedHelper] observeLocalUser];
    }
}

- (void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    
    [self.view endEditing:YES];
    [super touchesBegan:touches withEvent:event];
}

@end
