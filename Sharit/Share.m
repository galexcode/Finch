//
//  Share.m
//  Sharit
//
//  Created by Eugene Dorfman on 5/14/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Share.h"

@implementation Share
@synthesize isShared;
@synthesize isUpdated;
@synthesize name;
@synthesize path;
@synthesize macroPreprocessor = _macroPreprocessor;

- (NSString*) detailsDescription {
    return nil;
}

- (id) init {
    if ((self = [super init])) {
        self.isShared = YES;
        self.isUpdated = NO;
    }
    return self;
}

- (id) initWithMacroPreprocessor:(MacroPreprocessor *)macroPreprocessor {
    if ((self = [self init])) {
        _macroPreprocessor = macroPreprocessor;
    }
    return self;
}

- (NSMutableDictionary*)macrosDict {
    return nil;
}

- (void) processRequestData:(NSDictionary *)dict {
    
}
@end