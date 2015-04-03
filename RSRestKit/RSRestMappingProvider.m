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


#import "RSRestMappingProvider.h"
#import "NSObject+ClassOfProperty.h"
#import "NSString+KeyPathComponents.h"
#import "NSObject+RSRestMapping.h"

@interface NSObject (HasMapping)

+ (BOOL)rs_hasMapping;

@end


@implementation RSRestMappingProvider

+ (id)mapDictionary:(NSDictionary *)dictionary toObjectOfClass:(Class)aClass {
    id anObject = [aClass new];

    [self mapDictionary:dictionary toObject:anObject];

    return anObject;
}

+ (void)mapDictionary:(NSDictionary *)dictionary toObject:(id)anObject {
    if (!anObject) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException
                                       reason:@"anObject must be not nil"
                                     userInfo:nil];
    }

    NSDictionary* mapping = [[anObject class] rs_mappingDictionary];

    [mapping enumerateKeysAndObjectsUsingBlock:^(NSString *dictKeyPath, RSRestPropertyInfo *propertyInfo, BOOL *stop) {
        id __block value = dictionary;

        NSArray *dictKeyPathComponents = [dictKeyPath rs_keyPathComponents];
        NSUInteger dictKeyPathComponentsCount = dictKeyPathComponents.count;

        [dictKeyPathComponents enumerateObjectsUsingBlock:^(NSString *key, NSUInteger idx, BOOL *stop) {
            value = value[key];

            if (![value isKindOfClass:[NSDictionary class]] && idx != dictKeyPathComponentsCount - 1) {
                *stop = YES;

                value = nil;
            }
         }];

        Class propertyClass = [[anObject class] rs_classOfPropertyNamed:propertyInfo.propertyName];

        if ([value isKindOfClass:[NSDictionary class]]) {
            Class propertyClassForMapping = propertyInfo.propertyClass;

            if (!propertyClassForMapping) {
                propertyClassForMapping = propertyClass;
            }

            if ([propertyClassForMapping rs_hasMapping]) {
                value = [self mapDictionary:value toObjectOfClass:propertyClassForMapping];
            }
        } else if ([value isKindOfClass:[NSArray class]] && propertyInfo.propertyClass) {
            NSArray *originalValue = value;

            value = [NSMutableArray arrayWithCapacity:[originalValue count]];

            [originalValue enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                if ([obj isKindOfClass:[NSDictionary class]]) {
                    [value addObject:[self mapDictionary:obj toObjectOfClass:propertyInfo.propertyClass]];
                } else {
                    *stop = YES;

                    value = nil;
                }
            }];

            if ([propertyClass isSubclassOfClass:[NSOrderedSet class]]) {
                value = [NSOrderedSet orderedSetWithArray:value];
            }
        }

        if (value == [NSNull null]) {
            [anObject setValue:nil forKey:propertyInfo.propertyName];
        } else if (value && (!propertyClass || [value isKindOfClass:propertyClass])) {
            [anObject setValue:value forKey:propertyInfo.propertyName];
        }
    }];
}

+ (NSDictionary *)mapObjectToDictionary:(id)anObject {
    NSMutableDictionary *dict = [NSMutableDictionary new];

    [self mapObject:anObject toDictionary:dict];

    return dict;
}

+ (void)mapObject:(id)anObject toDictionary:(NSMutableDictionary *)dictionary {
    if (!anObject) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException
                                       reason:@"anObject must be not nil"
                                     userInfo:nil];
    }

    NSDictionary *mapping = [[anObject class] rs_mappingDictionary];

    [mapping enumerateKeysAndObjectsUsingBlock:^(NSString *dictKeyPath, RSRestPropertyInfo *propertyInfo, BOOL *stop) {
        id __block value = [anObject valueForKey:propertyInfo.propertyName];

        if ([[value class] rs_hasMapping]) {
            value = [self mapObjectToDictionary:value];
        } else if ([value isKindOfClass:[NSArray class]] || [value isKindOfClass:[NSOrderedSet class]]) {
            NSArray *originalValue = value;

            value = [NSMutableArray arrayWithCapacity:originalValue.count];

            [originalValue enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                if ([[obj class] rs_hasMapping]) {
                    value[idx] = [self mapObjectToDictionary:obj];
                } else {
                    *stop = YES;

                    value = nil;
                }
            }];
        } else if ([propertyInfo.propertyClass isSubclassOfClass:[RSRestBoolean class]] && value) {
            value = [NSNumber numberWithBool:[value boolValue]];
        }

        NSArray *keyPathComponents = [dictKeyPath rs_keyPathComponents];
        NSUInteger keyPathComponentsCount = keyPathComponents.count;

        NSMutableDictionary __block *currentDictionary = dictionary;

        [keyPathComponents enumerateObjectsUsingBlock:^(NSString *key, NSUInteger idx, BOOL *stop) {
            if (idx == keyPathComponentsCount - 1) {
                [currentDictionary setValue:(value ? value : [NSNull null]) forKey:key];
            } else if (!currentDictionary[key]) {
                NSMutableDictionary *dict = [NSMutableDictionary new];

                [currentDictionary setValue:dict forKey:key];

                currentDictionary = dict;
            }
        }];
    }];
}

@end

@implementation RSRestPropertyInfo

+ (instancetype)infoWithName:(NSString *)name class:(Class)aClass {
    return [[self alloc] initWithName:name class:aClass];
}

- (instancetype)initWithName:(NSString *)name class:(Class)aClass {
    if (aClass && ![aClass rs_hasMapping] && aClass != [RSRestBoolean class]) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException
                                       reason:@"aClass doesn't have mapping"
                                     userInfo:nil];
    }

    if (self = [self init]) {
        _propertyName = name;
        _propertyClass = aClass;
    }

    return self;
}

@end

@implementation NSObject (HasMapping)

+ (BOOL)rs_hasMapping {
    return ([self rs_mappingDictionary] != nil);
}

@end
