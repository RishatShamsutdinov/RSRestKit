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

#import "RSRestManagerConfiguration.h"
#import <objc/runtime.h>

#define CLASS_KEY(cl) ([NSString stringWithFormat:@"@class %@", NSStringFromClass(cl)])
#define PROTOCOL_KEY(p) ([NSString stringWithFormat:@"@protocol %@", NSStringFromProtocol(p)])

@interface RSRestManagerConfiguration () {
    NSMutableDictionary *_pathProviders;
}

@end

@implementation RSRestManagerConfiguration

+ (instancetype)configurationWithClient:(id<RSRestClient>)client
                    defaultErrorHandler:(id<RSRestManagerErrorHandler>)defaultErrorHandler
                        mappingProvider:(__unsafe_unretained Class<RSRestMappingProvider>)mappingProvider {

    return [[self alloc] initWithClient:client defaultErrorHandler:defaultErrorHandler mappingProvider:mappingProvider];
}

- (instancetype)init {
    if (self = [super init]) {
        _pathProviders = [NSMutableDictionary new];
    }

    return self;
}

- (instancetype)initWithClient:(id<RSRestClient>)client
           defaultErrorHandler:(id<RSRestManagerErrorHandler>)defaultErrorHandler
               mappingProvider:(__unsafe_unretained Class<RSRestMappingProvider>)mappingProvider {

    if (self = [self init]) {
        _client = client;
        _defaultErrorHandler = defaultErrorHandler;
        _mappingProvider = mappingProvider;
    }

    return self;
}

- (void)setPathProvider:(Class<RSRestPathProvider>)pathProvider forClass:(Class)aClass {
    _pathProviders[CLASS_KEY(aClass)] = pathProvider;
}

- (void)setPathProvider:(Class<RSRestPathProvider>)pathProvider forProtocol:(Protocol *)aProtocol {
    if (!protocol_conformsToProtocol(aProtocol, @protocol(RSRestObject))) {
        @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                       reason:[NSString stringWithFormat:@"aProtocol %@ does not conforms to %@",
                                               NSStringFromProtocol(aProtocol),
                                               NSStringFromProtocol(@protocol(RSRestObject))]
                                     userInfo:nil];
    }

    _pathProviders[PROTOCOL_KEY(aProtocol)] = pathProvider;
}

- (Class<RSRestPathProvider>)pathProviderForClass:(Class)aClass {
    return _pathProviders[CLASS_KEY(aClass)];
}

- (Class<RSRestPathProvider>)pathProviderForProtocol:(Protocol *)aProtocol {
    return _pathProviders[PROTOCOL_KEY(aProtocol)];
}

@end
