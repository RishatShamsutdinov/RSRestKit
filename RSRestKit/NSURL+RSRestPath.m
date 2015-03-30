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
    static NSString * const kQueryPrefix = @"?";
    static NSString * const kQuerySeparator = @"&";

    NSMutableString *queryString = [NSMutableString new];

    [queryDictionary enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        if (obj == [NSNull null]) {
            return;
        }

        if (queryString.length) {
            [queryString appendString:kQuerySeparator];
        }

        id value = obj;

        if ([value isKindOfClass:[NSArray class]]) {
            value = [(NSArray *)value componentsJoinedByString:@","];
        } else if (value == (__bridge NSNumber *)kCFBooleanTrue || value == (__bridge NSNumber *)kCFBooleanFalse) {
            value = [value boolValue] ? @"true" : @"false";
        }

        if ([value isKindOfClass:[NSString class]]) {
            value = [self rs_addPercentEncodingForString:value];
        }

        [queryString appendFormat:@"%@=%@", [self rs_addPercentEncodingForString:key], value];
    }];

    NSMutableString *string = [self.absoluteString mutableCopy];

    if (queryString.length) {
        if (![string hasSuffix:@"/"]) {
            [string appendString:@"/"];
        }

        if (![string hasSuffix:kQueryPrefix]) {
            [string appendString:kQueryPrefix];
        }

        [string appendString:queryString];
    }

    return [NSURL URLWithString:string];
}

- (NSString *)rs_addPercentEncodingForString:(NSString *)string {
    static NSCharacterSet *allowedCharacterSet;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        allowedCharacterSet = [NSCharacterSet characterSetWithCharactersInString:
                               @"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789*-._"];
    });

    return [string stringByAddingPercentEncodingWithAllowedCharacters:allowedCharacterSet];
}

- (instancetype)rs_URLRelativeToHost {
    NSString *host = self.host;

    if (!host.length) {
        return [self copy];
    }

    NSString *path = self.path;
    NSString *query = self.query;
    NSString *fragment = self.fragment;

    if (!path.length) {
        return nil;
    }

    NSMutableString *string = [NSMutableString stringWithString:path];

    if (query.length) {
        [string appendFormat:@"?%@", query];
    }

    if (fragment.length) {
        [string appendFormat:@"#%@", fragment];
    }

    return [NSURL URLWithString:string];
}

@end
