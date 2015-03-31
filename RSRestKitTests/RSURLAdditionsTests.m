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
#import "NSURL+RSRestPath.h"

@interface RSURLAdditionsTests : XCTestCase

@end

@implementation RSURLAdditionsTests

- (void)testURLByAppendingObjectID {
    NSString *URLString = @"test";
    NSURL *URL = [NSURL URLWithString:URLString];

    XCTAssertEqualObjects([URLString stringByAppendingPathComponent:@"qw"],
                          [URL rs_URLByAppendingObjectID:@"qw"].absoluteString);
    XCTAssertEqualObjects([URLString stringByAppendingPathComponent:@"(null)"],
                          [URL rs_URLByAppendingObjectID:nil].absoluteString);
}

- (void)testURLByAppendingRelativeURL {
    NSURL *baseURL = [NSURL URLWithString:@"/test/" relativeToURL:[NSURL URLWithString:@"https://domain.com/"]];
    NSURL *relativeURL = [[NSURL URLWithString:@"1"] rs_URLByAppendingRelativeURL:[NSURL URLWithString:@"2?k=v"]];

    XCTAssertEqualObjects([NSURL URLWithString:@"1/2?k=v" relativeToURL:baseURL].absoluteURL,
                          [baseURL rs_URLByAppendingRelativeURL:relativeURL].absoluteURL);
}

- (void)testURLByAppendingQueryDictionary {
    NSURL *baseURL = [NSURL URLWithString:@"https://domain.com"];
    NSURL *URL = [NSURL URLWithString:@"https://domain.com?key1=value1&%D0%BA%D0%BB%D1%8E%D1%872=%D0%B7%D0%BD%D0%B0%D1%87%D0%B5%D0%BD%D0%B8%D0%B52"];

    XCTAssertEqualObjects(URL, ([baseURL rs_URLByAppendingQueryDictionary:@{@"key1": @"value1",
                                                                            @"ключ2": @"значение2"}]));
}

- (void)testURLRelativeToHost {
    XCTAssertEqualObjects([NSURL URLWithString:@"/1/2/3?q=v#f"],
                          [[NSURL URLWithString:@"https://user@https:443/1/2/3?q=v#f"] rs_URLRelativeToHost]);
    XCTAssertEqualObjects([NSURL URLWithString:@"/1/2/3?q=v"],
                          [[NSURL URLWithString:@"https://user@https/1/2/3?q=v"] rs_URLRelativeToHost]);
    XCTAssertEqualObjects([NSURL URLWithString:@"/1/2/3?#f"],
                          [[NSURL URLWithString:@"https://user@https/1/2/3?#f"] rs_URLRelativeToHost]);
    XCTAssertEqualObjects([NSURL URLWithString:@"/1/2/3"],
                          [[NSURL URLWithString:@"https://user@https/1/2/3"] rs_URLRelativeToHost]);
}

@end
