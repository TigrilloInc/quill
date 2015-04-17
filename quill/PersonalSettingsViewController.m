//
//  PersonalSettingsViewController.m
//  Quill
//
//  Created by Alex Costantini on 7/16/14.
//  Copyright (c) 2014 Tigrillo. All rights reserved.
//

#import "PersonalSettingsViewController.h"
#import <Firebase/Firebase.h>
#import <FirebaseSimpleLogin/FirebaseSimpleLogin.h>
#import "FirebaseHelper.h"
#import "AvatarButton.h"
#import "ChangePasswordViewController.h"
#import "SignInViewController.h"
#import "PhotosCollectionViewController.h"

@implementation PersonalSettingsViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    self.navigationItem.title = @"Personal Settings";
    
    logoImage = (UIImageView *)[self.navigationController.navigationBar viewWithTag:800];
    
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc]
                                   initWithTitle: @"Settings"
                                   style: UIBarButtonItemStylePlain
                                   target: nil action: nil];
    [self.navigationItem setBackBarButtonItem: backButton];
    
    self.avatarButton = [AvatarButton buttonWithType:UIButtonTypeCustom];
    [self.avatarButton addTarget:self action:@selector(avatarTapped) forControlEvents:UIControlEventTouchUpInside];
    self.avatarButton.userID = [FirebaseHelper sharedHelper].uid;
    [self.avatarButton generateIdenticonWithShadow:true];
    self.avatarButton.frame = CGRectMake(0, 0, self.avatarButton.userImage.size.width, self.avatarButton.userImage.size.height);
    [self.view addSubview:self.avatarButton];
    
    self.avatarShadow = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"userbuttonmask3.png"]];
    self.avatarShadow.frame = CGRectMake(116, 86, 62, 62);
    [self.view addSubview:self.avatarShadow];
    
    self.avatarEdit = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"editavatar.png"]];
    self.avatarEdit.frame = CGRectMake(129, 98, 36, 36);
    self.avatarEdit.alpha = .4;
    [self.view addSubview:self.avatarEdit];
    
    self.nameTextField.text = [FirebaseHelper sharedHelper].userName;
    self.emailTextField.text = [[[[FirebaseHelper sharedHelper].team objectForKey:@"users"] objectForKey:[FirebaseHelper sharedHelper].uid] objectForKey:@"email"];
    
    CGRect nameRect = [self.nameTextField.text boundingRectWithSize:CGSizeMake(1000,NSUIntegerMax) options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) attributes:@{NSFontAttributeName: [UIFont fontWithName:@"SourceSansPro-Semibold" size:18]} context:nil];
    CGRect emailRect = [self.emailTextField.text boundingRectWithSize:CGSizeMake(1000,NSUIntegerMax) options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) attributes:@{NSFontAttributeName: [UIFont fontWithName:@"SourceSansPro-Regular" size:18]} context:nil];
    
    self.passwordTextField.secureTextEntry = true;
    
    UIView *spacerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
    [self.passwordTextField setLeftViewMode:UITextFieldViewModeAlways];
    [self.passwordTextField setLeftView:spacerView];
    self.passwordTextField.layer.borderColor = [UIColor groupTableViewBackgroundColor].CGColor;
    self.passwordTextField.layer.borderWidth = 1;
    self.passwordTextField.layer.cornerRadius = 10;
    
    self.nameButton.center = CGPointMake(nameRect.size.width+218, self.nameButton.center.y);
    self.emailButton.center = CGPointMake(emailRect.size.width+218, self.emailButton.center.y);
    
    self.passwordButton.layer.borderWidth = 1;
    self.passwordButton.layer.cornerRadius = 10;
    self.passwordButton.layer.borderColor = [UIColor lightGrayColor].CGColor;
    
    self.applyButton.layer.borderWidth = 1;
    self.applyButton.layer.cornerRadius = 10;
    self.applyButton.layer.borderColor = [UIColor grayColor].CGColor;
    
    UIBarButtonItem *signOutButton = [[UIBarButtonItem alloc]
                                   initWithTitle: @"Sign Out"
                                   style: UIBarButtonItemStylePlain
                                   target: self action: @selector(signOutTapped)];
    [self.navigationItem setRightBarButtonItems:@[signOutButton] animated:NO];
    
    teamEmails = [NSMutableArray array];
    
    for (NSString *userID in [[[FirebaseHelper sharedHelper].team objectForKey:@"users"] allKeys]) {
        
        NSString *userEmail = [[[[FirebaseHelper sharedHelper].team objectForKey:@"users"] objectForKey:userID] objectForKey:@"email"];
        if (![userEmail isEqualToString:[FirebaseHelper sharedHelper].email]) [teamEmails addObject:userEmail];
    }
    
    teamNames = [NSMutableArray array];
    
    for (NSString *userID in [[[FirebaseHelper sharedHelper].team objectForKey:@"users"] allKeys]) {
        
        NSString *userName = [[[[FirebaseHelper sharedHelper].team objectForKey:@"users"] objectForKey:userID] objectForKey:@"name"];
        if (![userName isEqualToString:[FirebaseHelper sharedHelper].userName]) [teamNames addObject:userName];
    }
}

-(void) viewWillAppear:(BOOL)animated {
    
    if (self.avatarImage == nil) {
        
        self.avatarShadow.hidden = true;
        self.avatarButton.center = CGPointMake(147, 117);
        [self.avatarButton generateIdenticonWithShadow:true];
        self.avatarButton.transform = CGAffineTransformMakeScale(.25,.25);
    }
    else {

        self.avatarShadow.hidden = false;
        self.avatarButton.center = CGPointMake(147, 115);
        self.avatarButton.identiconView.hidden = true;
        [self.avatarButton setImage:self.avatarImage forState:UIControlStateNormal];
        self.avatarButton.transform = CGAffineTransformMakeScale(.86*64/self.avatarImage.size.width, .86*64/self.avatarImage.size.width);
        self.avatarButton.imageView.layer.cornerRadius = self.avatarImage.size.width/2;
        self.avatarButton.imageView.layer.masksToBounds = YES;
    }
    
    if (![self.avatarImage isEqual:[FirebaseHelper sharedHelper].avatarImage]) [self.applyButton setTitle:@"Apply Changes" forState:UIControlStateNormal];
    else [self.applyButton setTitle:@"Done" forState:UIControlStateNormal];

    [super viewWillAppear:animated];
}

-(void) viewDidAppear:(BOOL)animated {
    
    [super viewDidAppear:animated];
    
    outsideTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tappedOutside)];
    
    [outsideTapRecognizer setDelegate:self];
    [outsideTapRecognizer setNumberOfTapsRequired:1];
    outsideTapRecognizer.cancelsTouchesInView = NO;
    [self.view.window addGestureRecognizer:outsideTapRecognizer];
    
    self.passwordTextField.delegate = self;
    self.nameTextField.delegate = self;
    self.emailTextField.delegate = self;
}

-(void) viewWillDisappear:(BOOL)animated {
    
    [super viewWillDisappear:animated];
    
    outsideTapRecognizer.delegate = nil;
    [self.view.window removeGestureRecognizer:outsideTapRecognizer];
    
    self.passwordTextField.delegate = nil;
    self.nameTextField.delegate = nil;
    self.emailTextField.delegate = nil;

}

-(void) signOutTapped {

    [[FirebaseHelper sharedHelper] signOut];
    
    [self dismissViewControllerAnimated:YES completion:nil];
    
    SignInViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"SignIn"];
    
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    nav.modalPresentationStyle = UIModalPresentationFormSheet;
    nav.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
 
    UIImageView *logoImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Logo.png"]];
    logoImageView.frame = CGRectMake(155, 8, 32, 32);
    logoImageView.tag = 800;
    [nav.navigationBar addSubview:logoImageView];
    
    [[UIApplication sharedApplication].delegate.window.rootViewController presentViewController:nav animated:YES completion:nil];
}

-(void) avatarTapped {
    
    PhotosCollectionViewController *photosVC = [self.storyboard instantiateViewControllerWithIdentifier:@"Photos"];
    PHFetchOptions *options = [[PHFetchOptions alloc] init];
    options.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:NO]];
    photosVC.assetsFetchResults = [PHAsset fetchAssetsWithOptions:options];
    
    logoImage.hidden = true;
    logoImage.frame = CGRectMake(175, 8, 32, 32);
    
    [self performSelector:@selector(showLogo) withObject:nil afterDelay:.3];
    
    [self.navigationController pushViewController:photosVC animated:YES];
}

- (IBAction)nameTapped:(id)sender {
    
    self.nameButton.hidden = true;
    self.nameTextField.userInteractionEnabled = true;
    [self.nameTextField becomeFirstResponder];
}

- (IBAction)emailTapped:(id)sender {

    self.emailButton.hidden = true;
    self.emailTextField.userInteractionEnabled = true;
    [self.emailTextField becomeFirstResponder];
}

- (IBAction)changePasswordTapped:(id)sender {

    ChangePasswordViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"ChangePassword"];
    
    logoImage.hidden = true;
    logoImage.frame = CGRectMake(155, 8, 32, 32);
    
    [self performSelector:@selector(showLogo) withObject:nil afterDelay:.3];
    
    [self.navigationController pushViewController:vc animated:YES];
}

- (IBAction)applyTapped:(id)sender {
    
    if ([self.nameTextField isFirstResponder]) [self.nameTextField resignFirstResponder];
    if ([self.emailTextField isFirstResponder]) [self.emailTextField resignFirstResponder];
    
    if ([self.nameTextField.text rangeOfCharacterFromSet:[NSCharacterSet whitespaceCharacterSet]].location != NSNotFound || [self.nameTextField.text rangeOfCharacterFromSet:[NSCharacterSet decimalDigitCharacterSet]].location != NSNotFound || [self.nameTextField.text rangeOfCharacterFromSet:[[NSCharacterSet alphanumericCharacterSet] invertedSet]].location != NSNotFound) {
        
        self.settingsLabel.text = @"Names cannot contain spaces, numbers, or special characters.";
        return;
    }
    
    if (self.nameTextField.text.length == 1) {
        
        self.settingsLabel.text = @"Names must be at least 2 letters long.";
        return;
    }
    
    if ([teamNames containsObject:self.nameTextField.text]) {
        
        self.settingsLabel.text = @"That name is already in use by a teammate.";
        return;
    }
    
    NSString *emailRegEx = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}";
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegEx];
    
    if ([emailTest evaluateWithObject:self.emailTextField.text] != true) {
        
        self.settingsLabel.text = @"Please enter a valid email.";
        return;
    }
    
    if ([teamEmails containsObject:self.emailTextField.text]) {
        
        self.settingsLabel.text = @"That email is already in use by a teammate.";
        return;
    }
    
    nameChanged = false;
    emailChanged = false;

    if (![self.emailTextField.text isEqualToString:[FirebaseHelper sharedHelper].email] && self.passwordTextField.text.length > 0) emailChanged = true;
    if (![self.nameTextField.text isEqualToString:[FirebaseHelper sharedHelper].userName]) nameChanged = true;
    
    if (!nameChanged && !emailChanged) [self dismissViewControllerAnimated:YES completion:nil];
    else if (emailChanged && nameChanged) {
        
        __block BOOL emailReady = false;
        __block BOOL nameReady = false;
        
        self.settingsLabel.text = @"";
        
        NSString *infoString = [NSString stringWithFormat:@"https://%@.firebaseio.com/users/%@/info/", [FirebaseHelper sharedHelper].db, [FirebaseHelper sharedHelper].uid];
        Firebase *ref = [[Firebase alloc] initWithUrl:infoString];
        [ref changeEmailForUser:[FirebaseHelper sharedHelper].uid password:self.passwordTextField.text toNewEmail:self.emailTextField.text withCompletionBlock:^(NSError *error) {
            
            if (error) self.settingsLabel.text = @"Something went wrong.";
            else {
            
                [FirebaseHelper sharedHelper].email = self.emailTextField.text;
                [[[[FirebaseHelper sharedHelper].team objectForKey:@"users"] objectForKey:[FirebaseHelper sharedHelper].uid] setObject:[FirebaseHelper sharedHelper].email forKey:@"email"];
                
                [[ref childByAppendingPath:@"email"] setValue:self.emailTextField.text withCompletionBlock:^(NSError *error, Firebase *ref) {
                    
                    emailReady = true;
                    [FirebaseHelper sharedHelper].email = self.emailTextField.text;
                    if (nameReady) {
                        self.settingsLabel.text = @"Name and email updated!";
                        [self performSelector:@selector(infoUpdated) withObject:nil afterDelay:.5];
                    }
                }];
            }
        }];
        
        [[ref childByAppendingPath:@"name"] setValue:self.nameTextField.text withCompletionBlock:^(NSError *error, Firebase *ref) {
            
            if (error) self.settingsLabel.text = @"Something went wrong - try again.";
            else {
                
                nameReady = true;
                [FirebaseHelper sharedHelper].userName = self.nameTextField.text;
                [[[[FirebaseHelper sharedHelper].team objectForKey:@"users"] objectForKey:[FirebaseHelper sharedHelper].uid] setObject:self.nameTextField.text forKey:@"name"];
                if (emailReady) {
                    self.settingsLabel.text = @"Name and email updated!";
                    [self performSelector:@selector(infoUpdated) withObject:nil afterDelay:.5];
                }
            }
        }];
    }
    else if (emailChanged) {
        
        NSString *emailString = [NSString stringWithFormat:@"https://%@.firebaseio.com/users/%@/info/email", [FirebaseHelper sharedHelper].db, [FirebaseHelper sharedHelper].uid];
        Firebase *ref = [[Firebase alloc] initWithUrl:emailString];
        [ref changeEmailForUser:[FirebaseHelper sharedHelper].uid password:self.passwordTextField.text toNewEmail:self.emailTextField.text withCompletionBlock:^(NSError *error) {
            
            if (error) self.settingsLabel.text = @"Something went wrong - try again.";
            else {
                
                [FirebaseHelper sharedHelper].email = self.emailTextField.text;
                [[[[FirebaseHelper sharedHelper].team objectForKey:@"users"] objectForKey:[FirebaseHelper sharedHelper].uid] setObject:[FirebaseHelper sharedHelper].email forKey:@"email"];
                
                [ref setValue:self.emailTextField.text withCompletionBlock:^(NSError *error, Firebase *ref) {
                    
                    [FirebaseHelper sharedHelper].email = self.emailTextField.text;
                    self.settingsLabel.text = @"Email updated!";
                    [self performSelector:@selector(infoUpdated) withObject:nil afterDelay:.5];
                }];
            }
        }];
    }
    else if (nameChanged) {
        
        NSString *nameString = [NSString stringWithFormat:@"https://%@.firebaseio.com/users/%@/info/name", [FirebaseHelper sharedHelper].db, [FirebaseHelper sharedHelper].uid];
        Firebase *ref = [[Firebase alloc] initWithUrl:nameString];
        [ref setValue:self.nameTextField.text withCompletionBlock:^(NSError *error, Firebase *ref) {
            
            if (error) self.settingsLabel.text = @"Something went wrong - try again.";
            else {
                
                [FirebaseHelper sharedHelper].userName = self.nameTextField.text;
                [[[[FirebaseHelper sharedHelper].team objectForKey:@"users"] objectForKey:[FirebaseHelper sharedHelper].uid] setObject:self.nameTextField.text forKey:@"name"];
                self.settingsLabel.text = @"Name updated!";
                [self performSelector:@selector(infoUpdated) withObject:nil afterDelay:.5];
            }
        }];
    }
    

    if ([FirebaseHelper sharedHelper].avatarImage == nil && self.avatarImage == nil) return;
    
    else if (self.avatarChanged) {

        
        [FirebaseHelper sharedHelper].avatarImage = self.avatarImage;
        
        NSMutableDictionary *userDict = [[[FirebaseHelper sharedHelper].team objectForKey:@"users"] objectForKey:[FirebaseHelper sharedHelper].uid];
        
        if (self.avatarImage == nil) [userDict setObject:@"none" forKey:@"avatar"];
        else [userDict setObject:self.avatarImage forKey:@"avatar"];
        
        NSString *avatarString = [NSString stringWithFormat:@"https://%@.firebaseio.com/users/%@/avatar", [FirebaseHelper sharedHelper].db, [FirebaseHelper sharedHelper].uid];
        Firebase *ref = [[Firebase alloc] initWithUrl:avatarString];
        
        if (self.avatarImage != nil) {
            
            NSData *data = UIImageJPEGRepresentation(self.avatarImage, 1.0);
            NSString *base64String = [data base64EncodedStringWithOptions:0];
            [ref setValue:base64String];
        }
        else [ref setValue:@"none"];
        
        if (!nameChanged && !emailChanged) [self infoUpdated];
    }
}

-(void) tappedOutside {
    
    if (outsideTapRecognizer.state == UIGestureRecognizerStateEnded) {
        
        CGPoint location = [outsideTapRecognizer locationInView:nil];
        CGPoint converted = [self.view convertPoint:CGPointMake(1024-location.y,location.x) fromView:self.view.window];
        
        if (!CGRectContainsPoint(self.view.frame, converted)){
            
            [outsideTapRecognizer setDelegate:nil];
            //[self.view.window removeGestureRecognizer:outsideTapRecognizer];
            [self dismissViewControllerAnimated:YES completion:nil];
        }
    }
}

-(void)infoUpdated {
    
    ProjectDetailViewController *projectVC = (ProjectDetailViewController *)[UIApplication sharedApplication].delegate.window.rootViewController;
    
    if (nameChanged) {
        
        [projectVC.masterView.nameButton setTitle:[FirebaseHelper sharedHelper].userName forState:UIControlStateNormal];
        projectVC.masterView.nameButton.center = CGPointMake(projectVC.masterView.nameButton.center.x, 107-60/projectVC.masterView.nameButton.titleLabel.font.pointSize);
        [projectVC.masterView.nameButton layoutIfNeeded];
    }
    
    else if (self.avatarChanged) {
        
        [[FirebaseHelper sharedHelper] updateMasterView];
        
        if ([FirebaseHelper sharedHelper].currentProjectID) [projectVC layoutAvatars];
    }
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)showLogo {
    
    logoImage.alpha = 0;
    logoImage.hidden = false;
    
    [UIView animateWithDuration:.3 animations:^{
        logoImage.alpha = 1;
    }];
}

- (void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    
    [self textFieldShouldReturn:nil];
    [super touchesBegan:touches withEvent:event];
}

#pragma mark - Text field handling

- (BOOL)textFieldShouldReturn:(UITextField*)textField {
 
    if ([self.nameTextField isFirstResponder]) [self.nameTextField resignFirstResponder];
    if ([self.emailTextField isFirstResponder]) [self.emailTextField resignFirstResponder];
    
    return NO;
}

-(void)textFieldDidEndEditing:(UITextField *)textField {
    
    NSString *oldEmail = [[[[FirebaseHelper sharedHelper].team objectForKey:@"users"] objectForKey:[FirebaseHelper sharedHelper].uid] objectForKey:@"email"];
    
    if ([textField isEqual:self.nameTextField]) {
    
        if (textField.text.length == 0) textField.text = [FirebaseHelper sharedHelper].userName;
        
        CGRect nameRect;
        
        if (textField.text.length > 0) {
            nameRect = [self.nameTextField.text boundingRectWithSize:CGSizeMake(1000,NSUIntegerMax) options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) attributes:@{NSFontAttributeName: [UIFont fontWithName:@"SourceSansPro-Semibold" size:18]} context:nil];
            
            if (textField.text.length < 2) textField.textColor = [UIColor redColor];
            else textField.textColor = [UIColor blackColor];
        }
        else {
            nameRect = [@"Name" boundingRectWithSize:CGSizeMake(1000,NSUIntegerMax) options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) attributes:@{NSFontAttributeName: [UIFont fontWithName:@"SourceSansPro-Semibold" size:18]} context:nil];
        }
        
        self.nameButton.center = CGPointMake(nameRect.size.width+218, self.nameButton.center.y);
        self.nameButton.hidden = false;
        self.nameTextField.userInteractionEnabled = false;
    }
    else if ([textField isEqual:self.emailTextField]) {
    
        if (textField.text.length == 0) textField.text = oldEmail;
        
        CGRect emailRect;
        
        if (textField.text.length > 0) {
            emailRect = [self.emailTextField.text boundingRectWithSize:CGSizeMake(1000,NSUIntegerMax) options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) attributes:@{NSFontAttributeName: [UIFont fontWithName:@"SourceSansPro-Regular" size:18]} context:nil];
        }
        else {
            emailRect = [@"Email" boundingRectWithSize:CGSizeMake(1000,NSUIntegerMax) options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) attributes:@{NSFontAttributeName: [UIFont fontWithName:@"SourceSansPro-Regular" size:18]} context:nil];
        }
    
        self.emailButton.center = CGPointMake(emailRect.size.width+218, self.emailButton.center.y);
        self.emailButton.hidden = false;
        self.emailTextField.userInteractionEnabled = false;
    }
    
    BOOL changesMade = false;
    
    if (![self.nameTextField.text isEqualToString:[FirebaseHelper sharedHelper].userName]) {
        
        changesMade = true;
        
        if ([self.nameTextField.text rangeOfCharacterFromSet:[NSCharacterSet whitespaceCharacterSet]].location != NSNotFound || [self.nameTextField.text rangeOfCharacterFromSet:[NSCharacterSet decimalDigitCharacterSet]].location != NSNotFound || [self.nameTextField.text rangeOfCharacterFromSet:[[NSCharacterSet alphanumericCharacterSet] invertedSet]].location != NSNotFound || self.nameTextField.text.length == 1 || [teamNames containsObject:self.nameTextField.text]) {
            
            self.nameTextField.textColor = [UIColor redColor];
            return;
        }
        else self.nameTextField.textColor = [UIColor blackColor];
    }

    if (![self.emailTextField.text isEqualToString:oldEmail]) {
        
        changesMade = true;
        
        self.passwordTextField.hidden = false;
        self.settingsLabel.frame = CGRectMake(0, 216, 540, 21);
        self.avatarButton.center = CGPointMake(147, 97);
        self.avatarShadow.frame = CGRectMake(116, 66, 62, 62);
        self.avatarEdit.frame = CGRectMake(129, 78, 36, 36);
        self.nameTextField.frame = CGRectMake(200, 66, 340, 30);
        self.emailTextField.frame = CGRectMake(200, 96, 340, 30);
        self.nameButton.frame = CGRectMake(self.nameButton.frame.origin.x, 58, 40, 40);
        self.emailButton.frame = CGRectMake(self.emailButton.frame.origin.x, 88, 40, 40);
        self.passwordButton.frame = CGRectMake(115, 146, 310, 50);
        
        NSString *emailRegEx = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}";
        NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegEx];
        if ([textField isEqual:self.emailTextField] && textField.text.length > 0 && (![emailTest evaluateWithObject:textField.text] || [teamEmails containsObject:textField.text])) textField.textColor = [UIColor redColor];
        else textField.textColor = [UIColor blackColor];
    }
    else {
        
        self.passwordTextField.hidden = true;
        self.settingsLabel.frame = CGRectMake(0, 271, 540, 21);
        self.avatarButton.center = CGPointMake(147, 117);
        self.avatarShadow.frame = CGRectMake(116, 86, 62, 62);
        self.avatarEdit.frame = CGRectMake(129, 98, 36, 36);
        self.nameTextField.frame = CGRectMake(200, 86, 340, 30);
        self.emailTextField.frame = CGRectMake(200, 116, 340, 30);
        self.nameButton.frame = CGRectMake(self.nameButton.frame.origin.x, 78, 40, 40);
        self.emailButton.frame = CGRectMake(self.emailButton.frame.origin.x, 108, 40, 40);
        self.passwordButton.frame = CGRectMake(115, 186, 310, 50);
    }
    
    if (changesMade) [self.applyButton setTitle:@"Apply Changes" forState:UIControlStateNormal];
    else [self.applyButton setTitle:@"Done" forState:UIControlStateNormal];
    
}

-(void) textFieldDidBeginEditing:(UITextField *)textField {
    
    textField.textColor = [UIColor blackColor];
}


- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    
    if ([textField isEqual:self.emailTextField]) {
        
        NSString *oldEmail = [[[[FirebaseHelper sharedHelper].team objectForKey:@"users"] objectForKey:[FirebaseHelper sharedHelper].uid] objectForKey:@"email"];
        
        if (![self.emailTextField.text isEqualToString:oldEmail]) {
            
            self.passwordTextField.hidden = false;
            self.settingsLabel.frame = CGRectMake(0, 216, 540, 21);
            self.avatarButton.center = CGPointMake(147, 97);
            self.avatarShadow.frame = CGRectMake(116, 66, 62, 62);
            self.avatarEdit.frame = CGRectMake(129, 78, 36, 36);
            self.nameTextField.frame = CGRectMake(200, 66, 340, 30);
            self.emailTextField.frame = CGRectMake(200, 96, 340, 30);
            self.nameButton.frame = CGRectMake(self.nameButton.frame.origin.x, 58, 40, 40);
            self.emailButton.frame = CGRectMake(self.emailButton.frame.origin.x, 88, 40, 40);
            self.passwordButton.frame = CGRectMake(115, 146, 310, 50);
        }
        else {
            
            self.passwordTextField.hidden = true;
            self.settingsLabel.frame = CGRectMake(0, 271, 540, 21);
            self.avatarButton.center = CGPointMake(147, 117);
            self.avatarShadow.frame = CGRectMake(116, 86, 62, 62);
            self.avatarEdit.frame = CGRectMake(129, 98, 36, 36);
            self.nameTextField.frame = CGRectMake(200, 86, 340, 30);
            self.emailTextField.frame = CGRectMake(200, 116, 340, 30);
            self.nameButton.frame = CGRectMake(self.nameButton.frame.origin.x, 78, 40, 40);
            self.emailButton.frame = CGRectMake(self.emailButton.frame.origin.x, 108, 40, 40);
            self.passwordButton.frame = CGRectMake(115, 186, 310, 50);
        }
        
        return YES;
    }
    else {
        
        if(range.length + range.location > textField.text.length) return NO;
        
        NSUInteger newLength = [textField.text length] + [string length] - range.length;
        
        if (newLength > 16) return NO;
        else return YES;
    }
}

#pragma mark - Gesture recognizer

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
