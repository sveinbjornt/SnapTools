//
//  NSWorkspaceExtensions.h
//  MenuSmith
//
//  Created by Sveinbjorn Thordarson on 9/26/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NSString+CarbonFSRefCreation.h"


@interface NSWorkspace (MSExtensions)

- (NSArray *)applicationsForFile:(NSString *)filePath;
- (NSString *)defaultApplicationForFile: (NSString *)filePath;

- (void)setLabel:(NSUInteger)label forFile:(NSString *)filePath;
- (int)labelNumberForFile: (NSString *)path;
- (NSString *)labelNameForFile: (NSString *)path;
- (NSColor *)labelColorForFile: (NSString *)path;

@end
