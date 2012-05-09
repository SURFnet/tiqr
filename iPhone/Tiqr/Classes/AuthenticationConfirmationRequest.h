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

#import "AuthenticationChallenge.h"

/**
 * Error domain.
 */
extern NSString *const TIQRACRErrorDomain;

/**
 * Authentication attempts left (NSNumber).
 * 0 means the account is blocked.
 */
extern NSString *const TIQRACRAttemptsLeftErrorKey;  


enum {
    TIQRACRUnknownError = 101,    
    TIQRACRConnectionError = 201,
    TIQRACRInvalidChallengeError = 301,
    TIQRACRInvalidRequestError = 302,
    TIQRACRInvalidResponseError = 303,
    TIQRACRInvalidUserError = 304,
    TIQRACRAccountBlockedError = 305
};

@class AuthenticationConfirmationRequest;

@protocol AuthenticationConfirmationRequestDelegate <NSObject>

@required
- (void)authenticationConfirmationRequestDidFinish:(AuthenticationConfirmationRequest *)request;
- (void)authenticationConfirmationRequest:(AuthenticationConfirmationRequest *)request didFailWithError:(NSError *)error;

@end

@interface AuthenticationConfirmationRequest : NSObject {
    
}

@property (nonatomic, assign) id<AuthenticationConfirmationRequestDelegate> delegate;

- (id)initWithAuthenticationChallenge:(AuthenticationChallenge *)challenge response:(NSString *)response;
- (void)send;

@end