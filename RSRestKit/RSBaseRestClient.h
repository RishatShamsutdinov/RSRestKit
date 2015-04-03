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


#import <Foundation/Foundation.h>
#import "RSRestClient.h"
#import "RSRestJSONFormatter.h"

/**
 * Format of body in request/response: JSON
 *
 * Methods to override:
 *
 * - requestForPath
 */
@interface RSBaseRestClient : NSObject <RSRestClient>

/**
 * Must be overridden
 */
- (NSMutableURLRequest *)requestForRelativeURL:(NSURL *)relativeURL;

/**
 * @abstract By default, returns YES only for HTTP status code 200
 * @return YES if `code` is success http status code
 */
- (BOOL)isHTTPStatusCodeSuccess:(NSUInteger)code;

- (void)addJSONFormatter:(id<RSRestJSONFormatter>)formatter;

@end
