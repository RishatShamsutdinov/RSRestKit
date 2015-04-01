# Requirements

> iOS 7.1+

# Usage

###### Create Client

```Objective-C
#import "RSBaseRestClient.h"

@interface RSGitHubClient : RSBaseRestClient
@end
```

```Objective-C
#import "RSGitHubClient.h"
#import "RSRestJSONDateFormatter.h"
#import "NSURL+RSRestPath.h"

static NSTimeInterval const kTimeoutInterval = 30;

@interface RSGitHubClient () {
    NSURL *_baseURL;
}

@end

@implementation RSGitHubClient

- (instancetype)init {
    if (self = [super init]) {
        _baseURL = [NSURL URLWithString:@"https://api.github.com"];

        [self addJSONFormatter:[RSRestJSONDateFormatter formatterWithDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZ"]];
    }

    return self;
}

- (NSMutableURLRequest *)requestForRelativeURL:(NSURL *)relativeURL {
    NSURL *URL = [_baseURL rs_URLByAppendingRelativeURL:relativeURL];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL
                                                           cachePolicy:NSURLRequestReloadIgnoringCacheData
                                                       timeoutInterval:kTimeoutInterval];

    [request addValue:@"application/vnd.github.v3+json" forHTTPHeaderField:@"Accept"];

    return request;
}

@end
```

###### Create Path Provider for Model

```Objective-C
#import "RSRestPathProvider.h"
#import "RSRestMappingProvider.h"

@interface RSGitHubUsersProvider : NSObject <RSRestPathProvider>
@end
```

```Objective-C
#import "RSGitHubUsersProvider.h"
#import "RSGitHubUser.h"

@implementation RSGitHubUsersProvider

+ (NSURL *)relativeURL {
    return [NSURL URLWithString:@"users"];
}

+ (NSURL *)relativeURLForObject:(RSGitHubUser *)anObject {
    return [[self relativeURL] rs_URLByAppendingObjectID:anObject.login];
}

@end
```

###### Configure Rest Manager

```Objective-C
RSRestManagerConfiguration *config = [RSRestManagerConfiguration
                                      configurationWithClient:[RSGitHubClient new]
                                      defaultErrorHandler:nil
                                      mappingProvider:[RSRestMappingProvider class]];

[config setPathProvider:[RSGitHubUsersProvider class] forClass:[RSGitHubUser class]];

[[RSRestManager sharedManager] configureWithConfiguration:config];
```

###### Create Model

```Objective-C
@interface RSGitHubUser : NSObject

@property (nonatomic) NSString *login;
@property (nonatomic) NSDate *creationDate;

@end
```

###### Create Mapping for Model

```Objective-C
#import "RSGitHubUser+Mapping.h"
#import "RSRestMappingProvider.h"

@implementation RSGitHubUser (Mapping)

+ (NSDictionary *)rs_mappingDictionary {
    return @{@"login": RS_PROPERTY(login),
             @"created_at": RS_PROPERTY(creationDate)};
}

@end
```

###### Get User by Login

```Objective-C
RSRestManagerOperation *op = [[RSRestManager sharedManager] getObjectForClass:[RSGitHubUser class] byId:@"RishatShamsutdinov"];

[op readyWithSuccessBlock:^(RSGitHubUser *user) {
    NSLog(@"Login: %@, Creation Date: %@", user.login, user.creationDate);
} failureBlock:^BOOL(NSError *error) {
    NSLog(@"Error occured: %@", error);

    return YES;
}];
```

# Context of Path

For example, you want to get followers of user with some id. All that you need is:
###### 1. Create model & mapping for followers response
###### 2. Create path provider for followers response
```Objective-C
+ (NSURL *)relativeURL {
    return [NSURL URLWithString:@"followers"];
}
```

###### 3. Get followers using rest manager

```Objective-C
NSString *userId = @"some id here";
RSRestPathContext *context = [RSRestPathContext contextWithObjectClass:[User class] objectID:userId
                                                         parentContext:nil];

RSRestManagerOperation *op = [[RSRestManager sharedManager] getObjectForClass:[FollowersResponse class]
                                                                    inContext:context];

[op readyWithSuccessBlock:^(FollowersResponse *followers) {
    // do something
} failureBlock:^BOOL(NSError *error) {
    NSLog(@"Error occured: %@", error);

    return YES;
}];
```

# Examples
Soon.
