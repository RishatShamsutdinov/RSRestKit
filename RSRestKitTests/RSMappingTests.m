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
#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "RSRestMappingProvider.h"
#import "NSObject+RSRestMapping.h"

@interface RSMappingTests : XCTestCase

@end

@interface TestRelObject : NSObject

@property (nonatomic) NSString *name;

@end

@interface TestObject : NSObject

@property (nonatomic) NSString *str;
@property (nonatomic) NSNumber *num;
@property (nonatomic) NSDictionary *dict;
@property (nonatomic) NSArray *array;
@property (nonatomic) TestRelObject *relObj;
@property (nonatomic) NSArray *relsObj;
@property (nonatomic) NSString *deepStr;
@property (nonatomic) NSOrderedSet *relObjOrderedSet;
@property (nonatomic) NSDate *date;
@property (nonatomic) NSNumber *boolNum;

@end

static NSString * const kStrKey = @"strKey";
static NSString * const kNumKey = @"numKey";
static NSString * const kDictKey = @"dictKey";
static NSString * const kArrayKey = @"arrayKey";
static NSString * const kRelKey = @"rel";
static NSString * const kRelsKey = @"rels";
static NSString * const kNameKey = @"name";
static NSString * const kDeepStrLevel1Key = @"level1";
static NSString * const kDeepStrLevel2Key = @"level2";
static NSString * const kRelsForSetKey = @"relsForSet";
static NSString * const kBoolNumKey = @"boolKey";

@implementation TestRelObject

+ (NSDictionary *)rs_mappingDictionary {
    return @{kNameKey: RS_PROPERTY(name)};
}

@end

@implementation TestObject

+ (NSDictionary *)rs_mappingDictionary {
    return @{kStrKey: RS_PROPERTY(str),
             kNumKey: RS_PROPERTY(num),
             kDictKey: RS_PROPERTY(dict),
             kArrayKey: RS_PROPERTY(array),
             kRelKey: RS_PROPERTY(relObj),
             kRelsKey: RS_RELATIONSHIP(relsObj, [TestRelObject class]),
             [NSString stringWithFormat:@"%@.%@", kDeepStrLevel1Key, kDeepStrLevel2Key]: RS_PROPERTY(deepStr),
             kRelsForSetKey: RS_RELATIONSHIP(relObjOrderedSet, [TestRelObject class]),
             kBoolNumKey: RS_BOOL_NUM_PROPERTY(boolNum)};
}

@end

@implementation RSMappingTests

- (void)testMapDictToObj {
    NSDictionary * const dict = @{kStrKey: @"",
                                  kNumKey: @0,
                                  kDictKey: @{},
                                  kArrayKey: @[],
                                  kRelKey: @{kNameKey: @"d1"},
                                  kRelsKey: @[@{kNameKey: @"a1"}, @{kNameKey: @"a2"}],
                                  kDeepStrLevel1Key: @{kDeepStrLevel2Key: @"deep"},
                                  kRelsForSetKey: @[@{kNameKey: @"a1"}, @{kNameKey: @"a2"}],
                                  kBoolNumKey: @(YES)};

    TestObject *obj = [RSRestMappingProvider mapDictionary:dict
                                           toObjectOfClass:[TestObject class]];

    XCTAssertEqualObjects(dict[kStrKey], obj.str);
    XCTAssertEqualObjects(dict[kNumKey], obj.num);
    XCTAssertEqualObjects(dict[kDictKey], obj.dict);
    XCTAssertEqualObjects(dict[kArrayKey], obj.array);
    XCTAssertEqualObjects(dict[kRelKey][kNameKey], obj.relObj.name);

    [dict[kRelsKey] enumerateObjectsUsingBlock:^(id rel, NSUInteger idx, BOOL *stop) {
        XCTAssertEqualObjects(rel[kNameKey], [obj.relsObj[idx] name]);
    }];

    [dict[kRelsForSetKey] enumerateObjectsUsingBlock:^(id rel, NSUInteger idx, BOOL *stop) {
        XCTAssertEqualObjects(rel[kNameKey], [obj.relObjOrderedSet[idx] name]);
    }];

    XCTAssertEqualObjects(dict[kDeepStrLevel1Key][kDeepStrLevel2Key], obj.deepStr);
    XCTAssertTrue([obj.relObjOrderedSet isKindOfClass:[NSOrderedSet class]]);
    XCTAssertEqual(dict[kBoolNumKey], obj.boolNum);
}

- (void)testMapObjToDict {
    TestObject *obj = [TestObject new];
    TestRelObject *relObjD1 = [TestRelObject new];
    TestRelObject *relObjA1 = [TestRelObject new];
    TestRelObject *relObjA2 = [TestRelObject new];

    relObjD1.name = @"d1";
    relObjA1.name = @"a1";
    relObjA2.name = @"a2";

    obj.str = @"";
    obj.num = @0;
    obj.dict = @{};
    obj.array = @[];
    obj.relObj = relObjD1;
    obj.relsObj = @[relObjA1, relObjA2];
    obj.deepStr = @"deep";
    obj.relObjOrderedSet = [NSOrderedSet orderedSetWithArray:@[relObjA1, relObjA2]];
    obj.boolNum = @(YES);

    NSDictionary *dict = [RSRestMappingProvider mapObjectToDictionary:obj];

    XCTAssertEqualObjects(dict[kStrKey], obj.str);
    XCTAssertEqualObjects(dict[kNumKey], obj.num);
    XCTAssertEqualObjects(dict[kDictKey], obj.dict);
    XCTAssertEqualObjects(dict[kArrayKey], obj.array);
    XCTAssertEqualObjects(dict[kRelKey][kNameKey], obj.relObj.name);

    [dict[kRelsKey] enumerateObjectsUsingBlock:^(id rel, NSUInteger idx, BOOL *stop) {
        XCTAssertEqualObjects(rel[kNameKey], [obj.relsObj[idx] name]);
    }];

    [dict[kRelsForSetKey] enumerateObjectsUsingBlock:^(id rel, NSUInteger idx, BOOL *stop) {
        XCTAssertEqualObjects(rel[kNameKey], [obj.relObjOrderedSet[idx] name]);
    }];

    XCTAssertEqual(dict.count, [[obj class] rs_mappingDictionary].count);
    XCTAssertEqualObjects(dict[kDeepStrLevel1Key][kDeepStrLevel2Key], obj.deepStr);
    XCTAssertEqual(dict[kBoolNumKey], obj.boolNum);
}

@end
