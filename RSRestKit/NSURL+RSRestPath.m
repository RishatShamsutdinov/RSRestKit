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



#import "NSURL+RSRestPath.h"

@implementation NSURL (RSRestPath)

- (instancetype)rs_URLByAppendingObjectID:(NSString *)objectID {
    if (!objectID) {
        objectID = @"(null)";
    }

    return [self URLByAppendingPathComponent:objectID];
}

- (instancetype)rs_resolveRelativeURLs {
    NSURL *baseURL = self.baseURL;

    if (!baseURL) {
        return [self copy];
    }

    if (self.host) {
        return [self absoluteURL];
    }

    NSURL *resolvedBaseURL = [baseURL rs_resolveRelativeURLs];
    NSString *relativeString = self.relativeString;

    NSMutableString *string = [NSMutableString stringWithString:resolvedBaseURL.absoluteString];

    static NSString * const kBaseURLSuffix = @"/";

    if (!([string hasSuffix:kBaseURLSuffix] || [relativeString hasSuffix:kBaseURLSuffix])) {
        [string appendString:kBaseURLSuffix];
    }

    [string appendString:relativeString];

    return [NSURL URLWithString:string];
}

- (instancetype)rs_URLByAppendingRelativeURL:(NSURL *)URL {
    if (self.query) {
        return nil;
    }

    return [NSURL URLWithString:[URL rs_resolveRelativeURLs].relativeString
                  relativeToURL:[self rs_resolveRelativeURLs]];
}

- (instancetype)rs_URLByAppendingQueryDictionary:(NSDictionary *)queryDictionary {
    NSURLComponents *components = [NSURLComponents componentsWithURL:self resolvingAgainstBaseURL:NO];
    NSMutableArray *queryItems = [NSMutableArray arrayWithArray:components.queryItems];

    [queryDictionary enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        if (obj == [NSNull null]) {
            return;
        }

        id value = obj;

        if ([value isKindOfClass:[NSArray class]]) {
            value = [(NSArray *)value componentsJoinedByString:@","];
        } else if (value == (__bridge NSNumber *)kCFBooleanTrue || value == (__bridge NSNumber *)kCFBooleanFalse) {
            value = [value boolValue] ? @"true" : @"false";
        }

        if (![value isKindOfClass:[NSString class]]) {
            value = [value description];
        }

        [queryItems addObject:[NSURLQueryItem queryItemWithName:key value:value]];
    }];

    components.queryItems = queryItems;

    return components.URL;
}

- (instancetype)rs_URLRelativeToHost {
    NSURLComponents *components = [NSURLComponents componentsWithURL:self resolvingAgainstBaseURL:YES];

    components.user = nil;
    components.password = nil;
    components.host = nil;
    components.scheme = nil;
    components.port = nil;

    return components.URL;
}

@end
