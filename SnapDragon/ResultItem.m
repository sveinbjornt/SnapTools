//
//  ResultItem.m
//  SnapDragon
//
//  Created by Sveinbjorn Thordarson on 1/29/12.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#import "ResultItem.h"

@implementation ResultItem

#pragma mark - Initialization

- (id)init
{
    if ((self = [super init]))
    {
        attr = [[NSMutableDictionary alloc] initWithCapacity: 12];
        statLoaded = FALSE;
    }
    return self;
}

- (id)initWithPath: (NSString *)path
{
    if ((self = [self init]))
    {
        [self setAttr: path forKey: @"Path"];
    }
    return self;
}

- (void)dealloc
{
    [attr release];
}

#pragma -

+ (ResultItem *)itemWithPath: (NSString *)path
{
    return [[[ResultItem alloc] initWithPath: path] autorelease];
}

#pragma mark - Attributes

- (void)setAttr: (id)obj forKey: (NSString *)key
{
    [attr setObject: obj forKey: key];
}

- (id)attr: (NSString *)key
{
    if (![self hasAttr: key])
        return [self calcAttr: key];
    
    return [attr objectForKey: key];
}

- (BOOL)hasAttr: (NSString *)theAttribute
{
    return !([attr objectForKey: theAttribute] == nil);
}

- (NSString *)path
{
    return [attr objectForKey: @"Path"];
}

- (id)calcAttr: (NSString *)theAttribute
{
    // icon
    if ([theAttribute isEqualToString: @"Icon"])
    {
        // icon
        NSImage *icon = [[NSWorkspace sharedWorkspace] iconForFile: [self path]];
        if (icon)
        {
            [icon setSize: NSMakeSize(16,16)];
            [self setAttr: icon forKey: @"Icon"];
        }
    }
    // size
    else if ([theAttribute isEqualToString: @"Size"])
    {
        [self _stat];
        NSString *sizeStr = [[NSFileManager defaultManager] sizeAsHumanReadable: statInfo.st_size];
        [self setAttr: sizeStr forKey: @"Size"];
    }
    // created 
    else if ([theAttribute isEqualToString: @"CreatedDate"])
    {
        [self _stat];
        statInfo.st_birthtime
        [self setAttr: sizeStr forKey: @"Size"];
    }
    return [self attr: theAttribute];
}

#pragma mark - Stat

- (void)_stat
{
    if (statLoaded)
        return;
    
    stat([[self path] fileSystemRepresentation], &statInfo);
    statLoaded = TRUE;
}

#pragma mark - Debug

- (NSString *)description
{
    return [attr description];
}

@end
