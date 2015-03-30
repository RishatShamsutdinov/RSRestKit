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



#import "RSBaseRestClient.h"
#import "NSError+RSHTTP.h"

@interface RSBaseRestClient () {
    NSMutableArray *_formatters;
}

@end

@implementation RSBaseRestClient

- (instancetype)init {
    if (self = [super init]) {
        _formatters = [NSMutableArray new];
    }

    return self;
}

- (NSString *)HTTPMethodForMethod:(RSRestClientMethod)method {
    switch (method) {
        case RSRestClientMethodGet: return @"GET";
        case RSRestClientMethodPost: return @"POST";
        case RSRestClientMethodPut: return @"PUT";
        case RSRestClientMethodPatch: return @"PATCH";
        case RSRestClientMethodDelete: return @"DELETE";
    }
}

- (NSMutableURLRequest *)requestForRelativeURL:(NSURL *)relativeURL {
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"The method %@ must be overridden",
                                           NSStringFromSelector(_cmd)]
                                 userInfo:nil];
}

- (BOOL)isHTTPStatusCodeSuccess:(NSUInteger)code {
    return (code == RSHTTPStatusCodeOk);
}

- (NSDictionary *)sendSynchronousRequestWithMethod:(RSRestClientMethod)method relativeURL:(NSURL *)relativeURL
                                              body:(NSDictionary *)body error:(NSError *__autoreleasing *)errorOut {

    NSMutableURLRequest *request = [self requestForRelativeURL:relativeURL];

    request.HTTPMethod = [self HTTPMethodForMethod:method];

    if (body) {
        NSDictionary *formattedBody = [self formatLeavesOfDictionary:body];

        request.HTTPBody = [NSJSONSerialization dataWithJSONObject:formattedBody options:kNilOptions error:NULL];
    }

    NSHTTPURLResponse *response;
    NSError *error;

    NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];

    static NSDictionary* URLErrorCodesMapping;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        URLErrorCodesMapping = @{@(NSURLErrorUserCancelledAuthentication): @(RSHTTPStatusCodeUnauthorized),
                                 @(NSURLErrorTimedOut): @(RSHTTPStatusCodeGatewayTimeOut)};
    });

    NSNumber *mappedStatusCode = URLErrorCodesMapping[@(error.code)];

    if ([error.domain isEqualToString:NSURLErrorDomain] && mappedStatusCode) {
        error = [NSError errorWithDomain:RSHTTPErrorDomain code:[mappedStatusCode integerValue]
                                userInfo:@{@"Response data": data}];
    }

    if (response.statusCode && ![self isHTTPStatusCodeSuccess:response.statusCode]) {
        error = [NSError errorWithDomain:RSHTTPErrorDomain code:response.statusCode
                                userInfo:@{@"Response data": data}];
    }

    if (error) {
        *errorOut = error;

        return nil;
    }

    id jsonObject = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:NULL];

    if ([jsonObject isKindOfClass:[NSDictionary class]]) {
        NSDictionary *parsedJsonObject = [self parseLeavesOfDictionary:jsonObject];

        return parsedJsonObject;
    }

    return nil;
}

#pragma mark - JSON Formatting

- (void)addJSONFormatter:(id<RSRestJSONFormatter>)formatter {
    [_formatters addObject:formatter];
}

- (NSDictionary *)mapLeavesOfDictionary:(NSDictionary *)dictionary usingBlock:(id (^)(id obj))block {
    NSMutableDictionary *resultDictionary = [dictionary mutableCopy];

    [resultDictionary enumerateKeysAndObjectsUsingBlock:^(NSString *key, id value, BOOL *stop) {
        id newValue = block(value);

        if (newValue) {
            [resultDictionary setValue:newValue forKey:key];
        } else if ([value isKindOfClass:[NSDictionary class]]) {
            NSMutableDictionary *mutable = [value mutableCopy];

            [resultDictionary setObject:mutable forKey:key];

            [self mapLeavesOfDictionary:mutable usingBlock:block];
        } else if ([value isKindOfClass:[NSArray class]]) {
            NSMutableArray *mutableArray = [value mutableCopy];

            [resultDictionary setObject:mutableArray forKey:key];

            [(NSArray *)value enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                id newArrayElementValue = block(obj);

                if (newArrayElementValue) {
                    [mutableArray replaceObjectAtIndex:idx withObject:newArrayElementValue];
                } else if ([obj isKindOfClass:[NSDictionary class]]) {
                    NSMutableDictionary *mutable = [obj mutableCopy];

                    [mutableArray replaceObjectAtIndex:idx withObject:mutable];

                    [self mapLeavesOfDictionary:mutable usingBlock:block];
                }
            }];
        }
    }];

    return resultDictionary;
}

- (NSDictionary *)formatLeavesOfDictionary:(NSDictionary *)dictionary {
    if (!_formatters.count) {
        return dictionary;
    }

    return [self mapLeavesOfDictionary:dictionary usingBlock:^id(id obj) {
        id __block formattedObj;

        [_formatters enumerateObjectsUsingBlock:^(id<RSRestJSONFormatter> formatter, NSUInteger idx, BOOL *stop) {
            formattedObj = [formatter format:obj];

            *stop = (formattedObj != nil);
        }];

        return formattedObj;
    }];
}

- (NSDictionary *)parseLeavesOfDictionary:(NSDictionary *)dictionary {
    if (!_formatters.count) {
        return dictionary;
    }

    return [self mapLeavesOfDictionary:dictionary usingBlock:^id(id obj) {
        id __block parsedObj;

        [_formatters enumerateObjectsUsingBlock:^(id<RSRestJSONFormatter> formatter, NSUInteger idx, BOOL *stop) {
            parsedObj = [formatter parse:obj];

            *stop = (parsedObj != nil);
        }];

        return parsedObj;
    }];
}

@end
