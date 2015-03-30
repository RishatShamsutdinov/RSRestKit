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

#import "RSGitHubClient.h"
#import "RSRestJSONDateFormatter.h"
#import "NSURL+RSRestPath.h"

static NSTimeInterval const kTimeoutInterval = 30;

@interface RSGitHubClient () {
    NSURL *_baseURL;
}

@end

@implementation RSGitHubClient

- (instancetype)init {
    if (self = [super init]) {
        _baseURL = [NSURL URLWithString:@"https://api.github.com"];

        [self addJSONFormatter:[RSRestJSONDateFormatter formatterWithDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZ"]];
    }

    return self;
}

- (NSMutableURLRequest *)requestForRelativeURL:(NSURL *)relativeURL {
    NSURL *URL = [_baseURL rs_URLByAppendingRelativeURL:relativeURL];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL
                                                           cachePolicy:NSURLRequestReloadIgnoringCacheData
                                                       timeoutInterval:kTimeoutInterval];

    [request addValue:@"application/vnd.github.v3+json" forHTTPHeaderField:@"Accept"];

    return request;
}

@end
