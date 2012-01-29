//
//  NSTask+Description.m
//  SnapDragon
//
//  Created by Sveinbjorn Thordarson on 1/28/12.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSTask (Description)
- (NSString *)fullDescription;
@end

@implementation NSTask (Description)

- (NSString *)fullDescription 
{
    NSString *str = [NSString stringWithFormat: @"%@ ", [self launchPath]];
    for (NSString *arg in [self arguments])
        str = [str stringByAppendingFormat: @"%@ ", arg];
    return str;
}

@end