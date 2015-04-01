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



#import "RSRestManager.h"
#import "RSRestClient.h"
#import "NSObject+ClassOfProperty.h"
#import <objc/runtime.h>

typedef void(^RSRestManagerOperationBlock)(RSRestManagerOperation *operation);

#pragma mark - interface RSRestManagerOperation

@interface RSRestManagerOperation () {
    RSRestManagerOperationBlock _block;
    dispatch_queue_t _readySerialQueue;

    NSOperation *_lockOperation;
}

@property (nonatomic, readonly) RSRestManagerOperationSuccessBlock successBlock;
@property (nonatomic, readonly) RSRestManagerOperationFailureBlock failureBlock;

- (instancetype)initWithBlock:(RSRestManagerOperationBlock)block;

@end

#pragma mark - RSRestManager -

@interface RSRestManager () {
    NSOperationQueue *_operationQueue;

    id<RSRestManagerConfiguration> _configuration;
    dispatch_once_t _configurationOnceToken;
}

@end

@implementation RSRestManager

+ (instancetype)sharedManager {
    static RSRestManager *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [RSRestManager new];
    });

    return manager;
}

- (instancetype)init {
    if (self = [super init]) {
        _operationQueue = [NSOperationQueue new];
    }

    return self;
}

- (void)configureWithConfiguration:(id<RSRestManagerConfiguration>)configuration {
    dispatch_once(&_configurationOnceToken, ^{
        _configuration = configuration;
    });
}

- (Class<RSRestPathProvider>)pathProviderForClass:(Class)aClass {
    if (!aClass) {
        @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                       reason:[NSString stringWithFormat:@"No provider found for class: %@",
                                               NSStringFromClass(aClass)]
                                     userInfo:nil];
    }

    Class<RSRestPathProvider> provider = [_configuration pathProviderForClass:aClass];

    if (!provider) {
        return [self pathProviderForClass:[aClass superclass]];
    }

    return provider;
}

#pragma mark - Relative URLs generation

- (NSURL *)URL:(NSURL *)relativeURL relativeToURLFromContext:(RSRestPathContext *)context {
    if (context) {
        NSURL *contextRelativeURL = [self relativeURLForObjectClass:context.objectClass withId:context.objectID
                                                          inContext:context.parentContext];

        return [contextRelativeURL rs_URLByAppendingRelativeURL:relativeURL];
    }

    return relativeURL;
}

- (NSURL *)relativeURLForObjectClass:(Class)aClass withId:(NSString *)objectID inContext:(RSRestPathContext *)context {
    Class<RSRestPathProvider> provider = [self pathProviderForClass:aClass];

    NSURL *objectRelativeURL = [provider relativeURL];

    if (objectID || !context) {
        objectRelativeURL = [objectRelativeURL rs_URLByAppendingObjectID:objectID];
    }

    if (!objectRelativeURL) {
        @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                       reason:[NSString stringWithFormat:@"nil relative URL for object class %@",
                                               NSStringFromClass(aClass)]
                                     userInfo:nil];
    }

    return [self URL:objectRelativeURL relativeToURLFromContext:context];
}

- (NSURL *)relativeURLForObject:(id)anObject inContext:(RSRestPathContext *)context {
    if (!anObject) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException
                                       reason:@"anObject must be not nil"
                                     userInfo:nil];
    }

    Class<RSRestPathProvider> provider = [self pathProviderForClass:[anObject class]];

    SEL relativeURLForObjectSelector = @selector(relativeURLForObject:);

    if (class_getClassMethod(provider, relativeURLForObjectSelector) == NULL) {
        @throw [NSException
                exceptionWithName:NSInternalInconsistencyException
                reason:[NSString stringWithFormat:@"Method %@ isn't implemented for path provider of %@",
                        NSStringFromSelector(relativeURLForObjectSelector),
                        NSStringFromClass([anObject class])]
                userInfo:nil];
    }

    NSURL *objectRelativeURL = [provider relativeURLForObject:anObject];

    if (!objectRelativeURL) {
        @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                       reason:[NSString stringWithFormat:@"nil relative URL for object %@", anObject]
                                     userInfo:nil];
    }

    return [self URL:objectRelativeURL relativeToURLFromContext:context];
}

#pragma mark - Request sending

- (RSRestManagerOperation *)sendRequestWithMethod:(RSRestClientMethod)method relativeURL:(NSURL *)relativeURL
                                           object:(id)anObject objectClass:(Class)objectClass {

    NSDictionary *body;

    if (anObject) {
        body = [[_configuration mappingProvider] mapObjectToDictionary:anObject];
    }

    RSRestManagerOperation *op = [[RSRestManagerOperation alloc] initWithBlock:^(RSRestManagerOperation *operation) {
        NSError *error;
        NSDictionary *response = [[_configuration client] sendSynchronousRequestWithMethod:method relativeURL:relativeURL
                                                                                      body:body error:&error];

        if (error) {
            RSRestManagerOperationFailureBlock failureBlock = operation.failureBlock;

            if (!(failureBlock && failureBlock(error))) {
                [[_configuration defaultErrorHandler] restManagerOperation:operation didFailWithError:error];
            }
        } else {
            RSRestManagerOperationSuccessBlock successBlock = operation.successBlock;

            if (successBlock) {
                id<RSRestMappingProvider> mappingProvider = [_configuration mappingProvider];

                id successObject = [mappingProvider mapDictionary:response toObjectOfClass:objectClass];

                successBlock(successObject);
            }
        }
    }];

    [_operationQueue addOperation:op];

    return op;
}

- (RSRestManagerOperation *)sendRequestWithMethod:(RSRestClientMethod)method forObjectClass:(Class)aClass
                                           withId:(NSString *)objectID inContext:(RSRestPathContext *)context {

    return [self sendRequestWithMethod:method relativeURL:[self relativeURLForObjectClass:aClass withId:objectID
                                                                         inContext:context]
                                object:nil objectClass:aClass];
}

- (RSRestManagerOperation *)sendRequestWithMethod:(RSRestClientMethod)method forObject:(id)anObject
                                        inContext:(RSRestPathContext *)context {

    return [self sendRequestWithMethod:method relativeURL:[self relativeURLForObject:anObject inContext:context]
                                object:anObject objectClass:[anObject class]];
}

#pragma mark - REST methods

- (RSRestManagerOperation *)getObjectForClass:(Class)aClass byId:(NSString *)objectID {
    return [self getObjectForClass:aClass byId:objectID inContext:nil];
}

- (RSRestManagerOperation *)getObjectForClass:(Class)aClass inContext:(RSRestPathContext *)context {
    return [self getObjectForClass:aClass byId:nil inContext:context];
}

- (RSRestManagerOperation *)getObjectForClass:(Class)aClass byId:(NSString *)objectID
                                    inContext:(RSRestPathContext *)context {

    return [self sendRequestWithMethod:RSRestClientMethodGet forObjectClass:aClass withId:objectID inContext:context];
}

- (RSRestManagerOperation *)getObjectForClass:(Class)aClass byRelativeURL:(NSURL *)relativeURL {
    return [self sendRequestWithMethod:RSRestClientMethodGet relativeURL:relativeURL object:nil objectClass:aClass];
}

- (RSRestManagerOperation *)postObject:(id)anObject {
    return [self postObject:anObject inContext:nil];
}

- (RSRestManagerOperation *)postObject:(id)anObject inContext:(RSRestPathContext *)context {
    return [self sendRequestWithMethod:RSRestClientMethodPost forObject:anObject inContext:context];
}

- (RSRestManagerOperation *)putObject:(id)anObject {
    return [self putObject:anObject inContext:nil];
}

- (RSRestManagerOperation *)putObject:(id)anObject inContext:(RSRestPathContext *)context {
    return [self sendRequestWithMethod:RSRestClientMethodPut forObject:anObject inContext:context];
}

- (RSRestManagerOperation *)patchObject:(id)anObject {
    return [self patchObject:anObject inContext:nil];
}

- (RSRestManagerOperation *)patchObject:(id)anObject inContext:(RSRestPathContext *)context {
    return [self sendRequestWithMethod:RSRestClientMethodPatch forObject:anObject inContext:context];
}

- (RSRestManagerOperation *)deleteObject:(id)anObject {
    return [self deleteObject:anObject inContext:nil];
}

- (RSRestManagerOperation *)deleteObject:(id)anObject inContext:(RSRestPathContext *)context {
    return [self sendRequestWithMethod:RSRestClientMethodDelete forObject:anObject inContext:context];
}

- (RSRestManagerOperation *)deleteObjectForClass:(Class)aClass byId:(NSString *)objectID {
    return [self deleteObjectForClass:aClass byId:objectID inContext:nil];
}

- (RSRestManagerOperation *)deleteObjectForClass:(Class)aClass byId:(NSString *)objectID
                                       inContext:(RSRestPathContext *)context {

    return [self sendRequestWithMethod:RSRestClientMethodDelete forObjectClass:aClass
                                withId:objectID inContext:context];
}

@end

#pragma mark - implementation RSRestManagerOperation -

@implementation RSRestManagerOperation

- (instancetype)init {
    if (self = [super init]) {
        _readySerialQueue = dispatch_queue_create("ru.rees.rest-manager-operation.ready", DISPATCH_QUEUE_SERIAL);

        _lockOperation = [NSOperation new];

        [self addDependency:_lockOperation];
    }

    return self;
}

- (instancetype)initWithBlock:(RSRestManagerOperationBlock)block {
    if (self = [self init]) {
        _block = block;
    }

    return self;
}

- (void)main {
    _block(self);
}

- (void)removeDependency:(NSOperation *)op {
    if (op != _lockOperation) {
        [super removeDependency:op];
    }
}

- (void)readyWithSuccessBlock:(RSRestManagerOperationSuccessBlock)successBlock
                 failureBlock:(RSRestManagerOperationFailureBlock)failureBlock {

    dispatch_async(_readySerialQueue, ^{
        if (!_lockOperation) {
            @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                           reason:@"The operation is already ready"
                                         userInfo:nil];
        }

        _successBlock = successBlock;
        _failureBlock = failureBlock;

        [super removeDependency:_lockOperation];
        
        _lockOperation = nil;
    });
}

- (void)readyWithSuccessBlock:(RSRestManagerOperationSuccessBlock)successBlock {
    [self readyWithSuccessBlock:successBlock failureBlock:nil];
}

- (void)readyWithFailureBlock:(RSRestManagerOperationFailureBlock)failureBlock {
    [self readyWithSuccessBlock:nil failureBlock:failureBlock];
}

@end
