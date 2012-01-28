//
//  NSTask+Description.m
//  SnapDragon
//
//  Created by Sveinbjorn Thordarson on 1/28/12.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSMutableArray (Shuffle)
- (void)shuffle;
@end

@implementation NSMutableArray (Shuffle)

// Knuth shuffle
- (void)shuffle 
{
	for (NSInteger i = [self count]-1; i > 0; --i) 
		[self exchangeObjectAtIndex: arc4random() % (i + 1) withObjectAtIndex: i]; 
}

@end