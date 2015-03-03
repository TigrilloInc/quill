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


@implementation PersonalSettingsViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    self.navigationItem.title = @"Personal Settings";
    
    logoImage = (UIImageView *)[self.navigationController.navigationBar viewWithTag:800];
    
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc]
                                   initWithTitle: @"Settings"
                                   style: UIBarButtonItemStyleBordered
                                   target: nil action: nil];
    [backButton setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                        [UIFont fontWithName:@"SourceSansPro-Semibold" size:16],NSFontAttributeName,
                                        nil] forState:UIControlStateNormal];
    [self.navigationItem setBackBarButtonItem: backButton];
    
    self.avatarButton = [AvatarButton buttonWithType:UIButtonTypeCustom];
    [self.avatarButton addTarget:self action:@selector(avatarTapped) forControlEvents:UIControlEventTouchUpInside];
    self.avatarButton.userID = [FirebaseHelper sharedHelper].uid;
    [self.avatarButton generateIdenticonWithShadow:false];
    self.avatarButton.frame = CGRectMake(0, 0, self.avatarButton.userImage.size.width, self.avatarButton.userImage.size.height);
    self.avatarButton.transform = CGAffineTransformMakeScale(.25, .25);
    self.avatarButton.center = CGPointMake(147, 117);
    [self.view addSubview:self.avatarButton];
    
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
                                   style: UIBarButtonItemStyleBordered
                                   target: self action: @selector(signOutTapped)];
    [signOutButton setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                        [UIFont fontWithName:@"SourceSansPro-Semibold" size:16],NSFontAttributeName,
                                        nil] forState:UIControlStateNormal];
    [self.navigationItem setRightBarButtonItems:@[signOutButton] animated:NO];
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
    
    ProjectDetailViewController *projectVC = (ProjectDetailViewController *)[UIApplication sharedApplication].delegate.window.rootViewController;
    [projectVC hideAll];
    projectVC.masterView.teamButton.hidden = true;
    projectVC.masterView.teamMenuButton.hidden = true;
    projectVC.masterView.nameButton.hidden = true;
    projectVC.masterView.avatarButton.hidden = true;
    
    Firebase *ref = [[Firebase alloc] initWithUrl:@"https://chalkto.firebaseio.com/"];
    FirebaseSimpleLogin *authClient = [[FirebaseSimpleLogin alloc] initWithRef:ref];
    
    [authClient logout];
    [FirebaseHelper sharedHelper].loggedIn = false;
    
    [[FirebaseHelper sharedHelper] clearData];
    
    [self dismissViewControllerAnimated:YES completion:nil];
    [self.view.window removeGestureRecognizer:outsideTapRecognizer];
    
    SignInViewController *vc = [projectVC.storyboard instantiateViewControllerWithIdentifier:@"SignIn"];
    
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    nav.modalPresentationStyle = UIModalPresentationFormSheet;
    nav.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    nav.navigationBar.barTintColor = [UIColor whiteColor];
    nav.navigationBar.tintColor = [UIColor blackColor];
    [[UINavigationBar appearance] setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys: [UIFont fontWithName:@"SourceSansPro-Light" size:24.0], NSFontAttributeName, nil]];
    [[UINavigationBar appearance] setTitleVerticalPositionAdjustment:5 forBarMetrics:UIBarMetricsDefault];
    
    UIImageView *logoImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Logo.png"]];
    logoImageView.frame = CGRectMake(155, 8, 32, 32);
    logoImageView.tag = 800;
    [nav.navigationBar addSubview:logoImageView];
    
    [projectVC presentViewController:nav animated:YES completion:nil];
}

-(void) avatarTapped {
    
    
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

    ProjectDetailViewController *projectVC = (ProjectDetailViewController *)[UIApplication sharedApplication].delegate.window.rootViewController;
    ChangePasswordViewController *vc = [projectVC.storyboard instantiateViewControllerWithIdentifier:@"ChangePassword"];
    
    logoImage.hidden = true;
    logoImage.frame = CGRectMake(155, 8, 32, 32);
    
    [self performSelector:@selector(showLogo) withObject:nil afterDelay:.3];
    
    [self.navigationController pushViewController:vc animated:YES];
}

- (IBAction)applyTapped:(id)sender {
    
    if ([self.nameTextField isFirstResponder]) [self.nameTextField resignFirstResponder];
    if ([self.emailTextField isFirstResponder]) [self.emailTextField resignFirstResponder];
    
    BOOL nameChanged = false;
    BOOL emailChanged = false;
    BOOL nameError = false;
    BOOL emailError = false;
    
    NSString *oldEmail = [[[[FirebaseHelper sharedHelper].team objectForKey:@"users"] objectForKey:[FirebaseHelper sharedHelper].uid] objectForKey:@"email"];
    
    NSString *emailRegEx = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}";
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegEx];
    
    if (![self.emailTextField.text isEqualToString:oldEmail]) {
        
        if (![emailTest evaluateWithObject:self.emailTextField.text] || self.emailTextField.text.length == 0) emailError = true;
        else if (self.passwordTextField.text.length > 0) emailChanged = true;
    }
    
    if (![self.nameTextField.text isEqualToString:[FirebaseHelper sharedHelper].userName]) {
        
        if (self.nameTextField.text.length == 0) nameError = true;
        else if (self.passwordTextField.text.length > 0) emailChanged = true;
    }
    
    if (nameError && emailError) self.settingsLabel.text = @"Please fix your name and email.";
    else if (nameError) self.settingsLabel.text = @"Please fix your name.";
    else if (emailError) self.settingsLabel.text = @"Please fix your email.";
    else if (!nameChanged && !emailChanged) [self dismissViewControllerAnimated:YES completion:nil];
    else if (emailChanged && nameChanged) {
        
        __block BOOL emailReady = false;
        __block BOOL nameReady = false;
        
        self.settingsLabel.text = @"";
        Firebase *ref = [[Firebase alloc] initWithUrl:@"https://chalkto.firebaseio.com"];
        [ref changeEmailForUser:[FirebaseHelper sharedHelper].uid password:self.passwordTextField.text toNewEmail:self.emailTextField.text withCompletionBlock:^(NSError *error) {
            
            if (error) self.settingsLabel.text = @"Something went wrong - try again.";
            else {
                
                emailReady = true;
                [FirebaseHelper sharedHelper].email = self.emailTextField.text;
                if (nameReady) {
                    self.settingsLabel.text = @"Name and email updated!";
                    [self performSelector:@selector(infoUpdated) withObject:nil afterDelay:.5];
                }
            }
        }];
        
        NSString *nameString = [NSString stringWithFormat:@"/users/%@/name", [FirebaseHelper sharedHelper].uid];
        [[ref childByAppendingPath:nameString] setValue:self.nameTextField.text withCompletionBlock:^(NSError *error, Firebase *ref) {
            
            if (error) self.settingsLabel.text = @"Something went wrong - try again.";
            else {
                
                nameReady = true;
                [FirebaseHelper sharedHelper].userName = self.nameTextField.text;
                if (emailReady) {
                    self.settingsLabel.text = @"Name and email updated!";
                    [self performSelector:@selector(infoUpdated) withObject:nil afterDelay:.5];
                }
            }
        }];
    }
    else if (emailChanged) {
        
        Firebase *ref = [[Firebase alloc] initWithUrl:@"https://chalkto.firebaseio.com"];
        [ref changeEmailForUser:[FirebaseHelper sharedHelper].uid password:self.passwordTextField.text toNewEmail:self.emailTextField.text withCompletionBlock:^(NSError *error) {
            
            if (error) self.settingsLabel.text = @"Something went wrong - try again.";
            else {
                
                [FirebaseHelper sharedHelper].email = self.emailTextField.text;
                self.settingsLabel.text = @"Email updated!";
                [self performSelector:@selector(infoUpdated) withObject:nil afterDelay:.5];
            }
        }];
    }
    else if (nameChanged) {
        
        NSString *nameString = [NSString stringWithFormat:@"https://chalkto.firebaseio.com/users/%@/name", [FirebaseHelper sharedHelper].uid];
        Firebase *ref = [[Firebase alloc] initWithUrl:nameString];
        [ref setValue:self.nameTextField.text withCompletionBlock:^(NSError *error, Firebase *ref) {
            
            if (error) self.settingsLabel.text = @"Something went wrong - try again.";
            else {
                
                [FirebaseHelper sharedHelper].userName = self.nameTextField.text;
                self.settingsLabel.text = @"Name updated!";
                [self performSelector:@selector(infoUpdated) withObject:nil afterDelay:.5];
            }
        }];
    }
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

-(void)infoUpdated {
    
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
    
    if (![self.nameTextField.text isEqualToString:[FirebaseHelper sharedHelper].userName]) changesMade = true;

    if (![self.emailTextField.text isEqualToString:oldEmail]) {
        
        changesMade = true;
        
        self.passwordTextField.hidden = false;
        self.settingsLabel.frame = CGRectMake(0, 216, 540, 21);
        self.avatarButton.center = CGPointMake(147, 97);
        self.nameTextField.frame = CGRectMake(200, 66, 340, 30);
        self.emailTextField.frame = CGRectMake(200, 96, 340, 30);
        self.nameButton.frame = CGRectMake(self.nameButton.frame.origin.x, 68, 20, 20);
        self.emailButton.frame = CGRectMake(self.emailButton.frame.origin.x, 98, 20, 20);
        self.passwordButton.frame = CGRectMake(115, 146, 310, 50);
        
        NSString *emailRegEx = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}";
        NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegEx];
        if ([textField isEqual:self.emailTextField] && textField.text.length > 0 && ![emailTest evaluateWithObject:textField.text]) textField.textColor = [UIColor redColor];
        else textField.textColor = [UIColor blackColor];
    }
    else {
        
        self.passwordTextField.hidden = true;
        self.settingsLabel.frame = CGRectMake(0, 271, 540, 21);
        self.avatarButton.center = CGPointMake(147, 117);
        self.nameTextField.frame = CGRectMake(200, 86, 340, 30);
        self.emailTextField.frame = CGRectMake(200, 116, 340, 30);
        self.nameButton.frame = CGRectMake(self.nameButton.frame.origin.x, 88, 20, 20);
        self.emailButton.frame = CGRectMake(self.emailButton.frame.origin.x, 118, 20, 20);
        self.passwordButton.frame = CGRectMake(115, 186, 310, 50);
    }
    
    if (changesMade) [self.applyButton setTitle:@"Apply" forState:UIControlStateNormal];
    else [self.applyButton setTitle:@"Done" forState:UIControlStateNormal];
    
}

-(void) textFieldDidBeginEditing:(UITextField *)textField {
    
    textField.textColor = [UIColor blackColor];
}

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
