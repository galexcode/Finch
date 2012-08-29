//
//  MacroPreprocessorTest.m
//  Sharit
//
//  Created by Eugene Dorfman on 6/3/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//
#import "Global.h"
#import "MacroPreprocessorTest.h"
#import "MacroPreprocessor.h"
@interface MacroPreprocessorTest() {
    NSDictionary* macroDict;
}
@end

@implementation MacroPreprocessorTest

- (void) doTestTemplate:(NSString*)template expected:(NSString*)expected {
    MacroPreprocessor* preproc = [[MacroPreprocessor alloc] initWithTemplateText:template macroDictionary:macroDict];
    NSString* actual = [preproc process];
    STAssertTrue([actual isEqualToString:expected],@"expected=%@ | actual=%@",expected,actual);
}

- (void) testMain {
    macroDict = [NSDictionary dictionaryWithObjectsAndKeys:
                          @"_trivial_",@"basic_key", 
                          [NSNumber numberWithBool:NO],@"no_key",
                          [NSNumber numberWithBool:YES],@"yes_key",
                          nil];

    [self doTestTemplate:@"basic%basic_key%basic" expected:@"basic_trivial_basic"];
    [self doTestTemplate:@"%if yes_key%%basic_key%%endif%" expected:@"_trivial_"];
    [self doTestTemplate:@"%if no_key%%basic_key%%endif%" expected:@""];
    [self doTestTemplate:@"aa%if yes_key%%if no_key%%basic_key%%endif%%endif%bb" expected:@"aabb"];
    [self doTestTemplate:@"start %if non_existant_key%non_existant%endif% finish" expected:@"start  finish"];
    [self doTestTemplate:@"start %if non_existant_key%%if yes_key%%basic_key%%endif%%endif% finish" expected:@"start  finish"];
}

- (void) testReplacing {
    macroDict = [NSDictionary dictionaryWithObjectsAndKeys:@(75),@"number_key", nil];
    [self doTestTemplate:@"%number_key%" expected:@"75"];
}
@end