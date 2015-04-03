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


#import "RSRestPathContext.h"

@implementation RSRestPathContext

+ (instancetype)contextWithObjectClass:(Class)objectClass objectID:(NSString *)objectID
                         parentContext:(RSRestPathContext *)parentContext {

    return [[self alloc] initWithObjectClass:objectClass objectID:objectID parentContext:parentContext];
}

- (instancetype)initWithObjectClass:(Class)objectClass objectID:(NSString *)objectID
                      parentContext:(RSRestPathContext *)parentContext {

    if (self = [self init]) {
        _objectClass = objectClass;
        _objectID = objectID;
        _parentContext = parentContext;
    }

    return self;
}

@end
