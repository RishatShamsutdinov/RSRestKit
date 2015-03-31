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
#import "RSRestPathContext.h"
#import "RSRestManagerConfiguration.h"

@class RSRestManagerOperation;

/**
 * All operations returned by the manager are queued. You must mark an operation as ready before releasing it.
 */
@interface RSRestManager : NSObject

+ (instancetype)sharedManager;

/**
 * @abstract Must be called only once
 */
- (void)configureWithConfiguration:(id<RSRestManagerConfiguration>)configuration;

- (RSRestManagerOperation *)getObjectForClass:(Class)aClass byId:(NSString *)objectID;
- (RSRestManagerOperation *)getObjectForClass:(Class)aClass inContext:(RSRestPathContext *)context;
- (RSRestManagerOperation *)getObjectForClass:(Class)aClass byId:(NSString *)objectID
                                    inContext:(RSRestPathContext *)context;
- (RSRestManagerOperation *)getObjectForClass:(Class)aClass byRelativeURL:(NSURL *)relativeURL;

- (RSRestManagerOperation *)postObject:(id)anObject;
- (RSRestManagerOperation *)postObject:(id)anObject inContext:(RSRestPathContext *)context;

- (RSRestManagerOperation *)putObject:(id)anObject;
- (RSRestManagerOperation *)putObject:(id)anObject inContext:(RSRestPathContext *)context;

- (RSRestManagerOperation *)patchObject:(id)anObject;
- (RSRestManagerOperation *)patchObject:(id)anObject inContext:(RSRestPathContext *)context;

- (RSRestManagerOperation *)deleteObject:(id)anObject;
- (RSRestManagerOperation *)deleteObject:(id)anObject inContext:(RSRestPathContext *)context;
- (RSRestManagerOperation *)deleteObjectForClass:(Class)aClass byId:(NSString *)objectID;
- (RSRestManagerOperation *)deleteObjectForClass:(Class)aClass byId:(NSString *)objectID
                                       inContext:(RSRestPathContext *)context;

@end

typedef void(^RSRestManagerOperationSuccessBlock)(id data);
typedef BOOL(^RSRestManagerOperationFailureBlock)(NSError *error);

/**
 * All operations returned by the manager are queued. You must mark an operation as ready before releasing it.
 */
@interface RSRestManagerOperation : NSOperation

/**
 * @param successBlock Optional
 * @param failureBlock Optional. Returns YES if error was handled, otherwise NO.
 * If error was not handled the manager will call default error handler.
 */
- (void)readyWithSuccessBlock:(RSRestManagerOperationSuccessBlock)successBlock
                 failureBlock:(RSRestManagerOperationFailureBlock)failureBlock;

/**
 * @abstract Calls readyWithSuccessBlock:failureBlock: with nil failureBlock
 * @see readyWithSuccessBlock:failureBlock:
 */
- (void)readyWithSuccessBlock:(RSRestManagerOperationSuccessBlock)successBlock;

/**
 * @abstract Calls readyWithSuccessBlock:failureBlock: with nil successBlock
 * @see readyWithSuccessBlock:failureBlock:
 */
- (void)readyWithFailureBlock:(RSRestManagerOperationFailureBlock)failureBlock;

@end
