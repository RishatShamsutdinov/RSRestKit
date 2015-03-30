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
#import "RSRestPathProvider.h"
#import "RSRestClient.h"
#import "RSRestManagerErrorHandler.h"
#import "RSRestMappingProvider.h"

@protocol RSRestManagerConfiguration <NSObject>

- (id<RSRestClient>)client;

- (Class<RSRestMappingProvider>)mappingProvider;

- (Class<RSRestPathProvider>)pathProviderForClass:(Class)aClass;

- (id<RSRestManagerErrorHandler>)defaultErrorHandler;

@end


@interface RSRestManagerConfiguration : NSObject <RSRestManagerConfiguration>

@property (nonatomic, readonly, strong) id<RSRestClient> client;
@property (nonatomic, readonly, weak) id<RSRestManagerErrorHandler> defaultErrorHandler;
@property (nonatomic, readonly, strong) Class<RSRestMappingProvider> mappingProvider;

+ (instancetype)configurationWithClient:(id<RSRestClient>)client
                    defaultErrorHandler:(id<RSRestManagerErrorHandler>)defaultErrorHandler
                        mappingProvider:(Class<RSRestMappingProvider>)mappingProvider;

- (instancetype)initWithClient:(id<RSRestClient>)client
           defaultErrorHandler:(id<RSRestManagerErrorHandler>)defaultErrorHandler
               mappingProvider:(Class<RSRestMappingProvider>)mappingProvider;

- (void)setPathProvider:(Class<RSRestPathProvider>)pathProvider forClass:(Class)aClass;

@end
