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
#import "RSRestBoolean.h"

@protocol RSRestMappingProvider <NSObject>

+ (id)mapDictionary:(NSDictionary *)dictionary toObjectOfClass:(Class)aClass;

+ (NSDictionary *)mapObjectToDictionary:(id)anObject;

@end

@interface RSRestMappingProvider : NSObject <RSRestMappingProvider>

/**
 * @exception NSInvalidArgumentException if anObject is nil
 */
+ (void)mapDictionary:(NSDictionary *)dictionary toObject:(id)anObject;

/**
 * @exception NSInvalidArgumentException if anObject is nil
 */
+ (void)mapObject:(id)anObject toDictionary:(NSMutableDictionary *)dictionary;

@end

#define RS_PROPERTY(prop) ([RSRestPropertyInfo infoWithName:NSStringFromSelector(@selector(prop)) class:nil])
#define RS_BOOL_NUM_PROPERTY(prop) ([RSRestPropertyInfo infoWithName:NSStringFromSelector(@selector(prop)) \
                                                               class:[RSRestBoolean class]])
#define RS_RELATIONSHIP(prop, cl) ([RSRestPropertyInfo infoWithName:NSStringFromSelector(@selector(prop)) class:(cl)])

@interface RSRestPropertyInfo : NSObject

@property (nonatomic, readonly) NSString *propertyName;
@property (nonatomic, readonly) Class propertyClass;

+ (instancetype)infoWithName:(NSString *)name class:(Class)aClass;

@end
