/*
 * Copyright (c) 2010-2011 SURFnet bv
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. Neither the name of SURFnet bv nor the names of its contributors 
 *    may be used to endorse or promote products derived from this 
 *    software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE
 * GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER
 * IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
 * OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN
 * IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "AuthenticationPINViewController.h"
#import "AuthenticationSummaryViewController.h"
#import "AuthenticationFallbackViewController.h"
#import "OCRAWrapper.h"
#import "SecretStore.h"
#import "MBProgressHUD.h"
#import "Identity+Utils.h"
#import "ErrorViewController.h"

@interface AuthenticationPINViewController ()

@property (nonatomic, retain) AuthenticationChallenge *challenge;
@property (nonatomic, copy) NSString *response;

@end

@implementation AuthenticationPINViewController

@synthesize managedObjectContext=managedObjectContext_;
@synthesize challenge=challenge_;
@synthesize response=response_;

- (id)initWithAuthenticationChallenge:(AuthenticationChallenge *)challenge {
    self = [super init];
    if (self != nil) {
        self.challenge = challenge;
        self.delegate = self;
    }
	
	return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = NSLocalizedString(@"Login", @"Login title");
    self.navigationItem.backBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Enter PIN", @"Enrollment PIN back button title") style:UIBarButtonItemStyleBordered target:nil action:nil] autorelease];        
    self.subtitle = NSLocalizedString(@"Enter your PIN", @"Authentication PIN title");
    self.description = NSLocalizedString(@"You need to enter your 4-digit PIN to login.", @"Authentication PIN description"); 
}

- (void)showFallback {
    AuthenticationFallbackViewController *viewController = [[AuthenticationFallbackViewController alloc] initWithAuthenticationChallenge:self.challenge response:self.response];
    viewController.managedObjectContext = self.managedObjectContext;
    [self.navigationController pushViewController:viewController animated:YES];
    [viewController release]; 
}

- (void)authenticationConfirmationRequestDidFinish:(AuthenticationConfirmationRequest *)request {
	[MBProgressHUD hideHUDForView:self.navigationController.view animated:YES];    
    [request release];
    AuthenticationSummaryViewController *viewController = [[AuthenticationSummaryViewController alloc] initWithAuthenticationChallenge:self.challenge];
    viewController.managedObjectContext = self.managedObjectContext;
    [self.navigationController pushViewController:viewController animated:YES];
    [viewController release];    
}

- (void)authenticationConfirmationRequest:(AuthenticationConfirmationRequest *)request didFailWithError:(NSError *)error {
	[MBProgressHUD hideHUDForView:self.navigationController.view animated:YES];    
    [request release];
    
    switch ([error code]) {
        case TIQRACRConnectionError:
            [self showFallback];
            break;
        case TIQRACRAccountBlockedError: {
            self.challenge.identity.blocked = [NSNumber numberWithBool:YES];
            [self.managedObjectContext save:nil];
            UIViewController *viewController = [[ErrorViewController alloc] initWithTitle:self.title errorTitle:[error localizedDescription] errorMessage:[error localizedFailureReason]];
            [self.navigationController pushViewController:viewController animated:YES];
            [viewController release];
            break;
        }            
        case TIQRACRInvalidResponseError: {
            NSNumber *attemptsLeft = [[error userInfo] objectForKey:TIQRACRAttemptsLeftErrorKey];
            if ([attemptsLeft intValue] == 0) {
                [Identity blockAllIdentitiesInManagedObjectContext:self.managedObjectContext];
                [self.managedObjectContext save:nil];
                UIViewController *viewController = [[ErrorViewController alloc] initWithTitle:self.title errorTitle:[error localizedDescription] errorMessage:[error localizedFailureReason]];
                [self.navigationController pushViewController:viewController animated:YES];
                [viewController release];
            } else {
                [self clear];
                [self showErrorWithTitle:[error localizedDescription] message:[error localizedFailureReason]];
            }
            break;
        }
        default: {
            UIViewController *viewController = [[ErrorViewController alloc] initWithTitle:self.title errorTitle:[error localizedDescription] errorMessage:[error localizedFailureReason]];
            [self.navigationController pushViewController:viewController animated:YES];
            [viewController release];
        }
    }
}

- (NSString *)calculateOTPResponseForPIN:(NSString *)PIN {
	SecretStore *store = [SecretStore secretStoreForIdentity:self.challenge.identity.identifier identityProvider:self.challenge.identityProvider.identifier];
    
    NSError *error = nil;
    NSString *response = [OCRAWrapper generateOCRA:self.challenge.identityProvider.ocraSuite secret:[store secretForPIN:PIN] challenge:self.challenge.challenge sessionKey:self.challenge.sessionKey error:&error];
    if (response == nil) {
        [MBProgressHUD hideHUDForView:self.navigationController.view animated:YES];
        UIViewController *viewController = [[ErrorViewController alloc] 
                                            initWithTitle:@"Error" 
                                            errorTitle:[error localizedDescription] 
                                            errorMessage:[error localizedFailureReason]];
        [self.navigationController pushViewController:viewController animated:YES];
        [viewController release];
    }

    return response;
}

- (void)PINViewController:(PINViewController *)pinViewController didFinishWithPIN:(NSString *)PIN {
    self.response = [self calculateOTPResponseForPIN:PIN];
    if (self.response == nil) {
        return;
    }

	[MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];    
    AuthenticationConfirmationRequest *request = [[AuthenticationConfirmationRequest alloc] initWithAuthenticationChallenge:self.challenge response:self.response];
    request.delegate = self;
    [request send];
}

- (void)dealloc {
    self.challenge = nil;
    self.response = nil;
    self.managedObjectContext = nil;
    [super dealloc];
}

@end