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



#import "RSRestJSONDateFormatter.h"

@interface RSRestJSONDateFormatter () {
    NSDateFormatter *_dateFormatter;
}

@end

@implementation RSRestJSONDateFormatter

+ (instancetype)formatterWithDateFormat:(NSString *)dateFormat {
    return [[self alloc] initWithDateFormat:dateFormat];
}

- (instancetype)initWithDateFormat:(NSString *)dateFormat {
    if (self = [self init]) {
        _dateFormatter = [NSDateFormatter new];

        [_dateFormatter setDateFormat:dateFormat];
        [_dateFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"GMT"]];
    }

    return self;
}

- (NSString *)format:(id)obj {
    if ([obj isKindOfClass:[NSDate class]]) {
        return [_dateFormatter stringFromDate:obj];
    }

    return nil;
}

- (id)parse:(NSString *)string {
    if ([string isKindOfClass:[NSString class]]) {
        return [_dateFormatter dateFromString:string];
    }
    
    return nil;
}

@end
