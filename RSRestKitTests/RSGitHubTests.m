/**
 *
 * Copyright 2015 Rishat Shamsutdinov
 * 
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 * 
 *     http://www.apache.org/licenses/LICENSE-2.0
 * 
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 */

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "RSRestKit.h"
#import "RSGitHubClient.h"
#import "RSGitHubUsersProvider.h"
#import "RSGitHubUser.h"

@interface RSGitHubTests : XCTestCase

@end

@implementation RSGitHubTests

- (void)setUp {
    [super setUp];

    RSRestManagerConfiguration *config = [RSRestManagerConfiguration
                                          configurationWithClient:[RSGitHubClient new]
                                          defaultErrorHandler:nil
                                          mappingProvider:[RSRestMappingProvider class]];

    [config setPathProvider:[RSGitHubUsersProvider class] forClass:[RSGitHubUser class]];

    [[RSRestManager sharedManager] configureWithConfiguration:config];
}

- (void)testGetUser {
    NSString * const login = @"RishatShamsutdinov";

    RSRestManagerOperation *op = [[RSRestManager sharedManager] getObjectForClass:[RSGitHubUser class] byId:login];

    dispatch_group_t group = dispatch_group_create();

    dispatch_group_enter(group);

    [op readyWithSuccessBlock:^(RSGitHubUser *user) {
        XCTAssertEqualObjects(user.login, login);
        XCTAssertEqual([user.creationDate timeIntervalSince1970], 1336995947);
    } failureBlock:^BOOL(NSError *error) {
        XCTFail(@"Error occured: %@", error);

        return YES;
    }];

    [op setCompletionBlock:^{
        dispatch_group_leave(group);
    }];

    dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
}

@end
