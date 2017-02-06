//
//  NSString+JapaneseExtras.m
//
//  Created by Grace Steven on 3/26/11.
//  Copyright 2011 works5.com All rights reserved.
//
#import <Foundation/Foundation.h>
@interface NSString (NSString_Japanese)

- (NSString*)filterSpecialCharacter;
- (NSString*) defaultString;
- (NSDictionary*)hiraganaReplacementsForStringWithCompareString:(NSString*)compareString;

@end
