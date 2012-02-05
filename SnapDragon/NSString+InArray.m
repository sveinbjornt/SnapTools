//
//  NSString+InArray.m
//  SnapDragon
//
//  Created by Sveinbjorn Thordarson on 2/5/12.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#import "NSString+InArray.h"

@implementation NSString (InArray)

-(BOOL)inArray: (NSArray *)arr
{
    for (id obj in arr)
        if (obj && [obj isKindOfClass: [NSString class]])
            if ([self isEqualToString: (NSString *)obj])
                return YES;
    return NO;
}

@end
