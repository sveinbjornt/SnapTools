//
//  ResultItem.m
//  SnapDragon
//
//  Created by Sveinbjorn Thordarson on 1/29/12.
//  Copyright 2012 Sveinbjorn Thordarson. All rights reserved.
//

#import "ResultItem.h"
#import "NSFileManager+FileOrFolderSize.m"
#import "NSTask+Description.m"

@implementation ResultItem
@synthesize isDirectory;
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
        isDirectory = [FILEMGR isFolder: path];
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
    if ([attr objectForKey: key] == nil)
        [self calcAttr: key];
    
    return [attr objectForKey: key];
}

- (NSString *)path
{
    return [attr objectForKey: @"Path"];
}

- (UInt64)size
{
    [self _stat];
    return statInfo.st_size;
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
            [self setAttr: icon forKey: theAttribute];
        }
    }
    // size
    else if ([theAttribute isEqualToString: @"Size"])
    {
        if (isDirectory)
        {
//            if ([DEFAULTS objectForKey: @"CalculateFolderSizes"])
//                [self setAttr: [FILEMGR fileOrFolderSizeAsHumanReadable: [self path]] forKey: @"Size"];
//            else
                [self setAttr: @"-" forKey: theAttribute];
        }
        else    
        {
            [self _stat];
            
            NSString *sizeStr;
            if ([[DEFAULTS objectForKey: @"UseHumanReadableSizes"] boolValue])
                sizeStr = [FILEMGR sizeAsHumanReadable: statInfo.st_size];
            else
                sizeStr = [NSString stringWithFormat: @"%d", statInfo.st_size, nil];
            [self setAttr: sizeStr forKey: theAttribute];
        }
    }
    // created 
    else if ([theAttribute isEqualToString: @"Date Created"])
    {
        [self _stat];
        NSDate *date = [NSDate dateWithTimeIntervalSince1970: statInfo.st_birthtime];
        [self setAttr: [date description] forKey: theAttribute];
    }
    // accessed 
    else if ([theAttribute isEqualToString: @"Date Accessed"])
    {
        [self _stat];
        NSDate *date = [NSDate dateWithTimeIntervalSince1970: statInfo.st_atime];
        [self setAttr: [date description] forKey: theAttribute];
    }
    // modified 
    else if ([theAttribute isEqualToString: @"Date Modified"])
    {
        [self _stat];
        NSDate *date = [NSDate dateWithTimeIntervalSince1970: statInfo.st_mtime];
        [self setAttr: [date description] forKey: theAttribute];
    }
    // kind
    else if ([theAttribute isEqualToString: @"Kind"])
    {
        NSURL *url = [NSURL fileURLWithPath: [self path]];
        CFStringRef kindStr = nil;
        LSCopyKindStringForURL((CFURLRef)url, &kindStr);
        if (kindStr !=  nil)
        {
            [self setAttr: [NSString stringWithString: (NSString*)kindStr] forKey: theAttribute];
            CFRelease(kindStr);
        }
        else
            [self setAttr: @"Unknown" forKey: theAttribute];
    }
    else if ([theAttribute isEqualToString: @"Permissions"])
    {
        [self _stat];
        char buf[20];
        strmode(statInfo.st_mode, (char *)&buf);
        [self setAttr: [NSString stringWithCString: (char *)&buf encoding: NSUTF8StringEncoding] forKey: theAttribute];
    }
    else if ([theAttribute isEqualToString: @"User:Group"])
    {
        [self _stat];
        const char *u, *g;
        u = user_from_uid(statInfo.st_uid, 0);
        g = group_from_gid(statInfo.st_gid, 0);
        NSString *user = [NSString stringWithCString: u encoding: NSUTF8StringEncoding];
        NSString *group = [NSString stringWithCString: g encoding: NSUTF8StringEncoding];
        NSString *ugStr = [NSString stringWithFormat: @"%@:%@", user, group, nil];
        [self setAttr: ugStr forKey: theAttribute];
    }
    else if ([theAttribute isEqualToString: @"UTI"])
    {
        NSString *type = [[NSWorkspace sharedWorkspace] typeOfFile: [self path] error: nil];
        NSString *uti = (type == nil) ? @"" : type;
        [self setAttr: uti forKey: theAttribute];
    }
    return [attr objectForKey: theAttribute];
}

#pragma mark - Actions

-(void)openInFinder
{
    [[NSWorkspace sharedWorkspace] openFile: [self path]];
}

-(void)openWithApplication: (NSString *)appName
{
    
}

- (void)showInFinder
{
    [[NSWorkspace sharedWorkspace] selectFile: [self path] inFileViewerRootedAtPath: nil];
}

-(void)openContainingFolder
{
    //[[self path] parent
}

-(void)getInfo
{
	NSString *type = (isDirectory && ![[self path] hasSuffix: @".app"]) ? @"folder" : @"file";    
	NSString *osaScript = [NSString stringWithFormat: 
                           @"tell application \"Finder\"\n\
                           \tactivate\n\
                           \topen the information window of %@ POSIX file \"%@\"\n\
                           end tell", type, [self path], nil];
	
	NSTask	*theTask = [[NSTask alloc] init];
	
	//initialize task -- we launch the AppleScript via the 'osascript' CLI program
	[theTask setLaunchPath: @"/usr/bin/osascript"];
	[theTask setArguments: [NSArray arrayWithObjects: @"-e", osaScript, nil]];
	[theTask launch];
    [theTask retain];
    //NSLog([theTask fullDescription]);
    //[theTask waitUntilExit];
    //[theTask release];
}

-(void)quickLook
{
	NSTask	*theTask = [[[NSTask alloc] init] autorelease];
	
	//initialize task -- we launch the AppleScript via the 'osascript' CLI program
	[theTask setLaunchPath: @"/usr/bin/qlmanage"];
	[theTask setArguments: [NSArray arrayWithObjects: @"-p", [self path], nil]];
	[theTask launch];
}

-(void)labelSelected: (id)sender
{
	//[[NSWorkspace sharedWorkspace] setLabel: [sender tag] forFile: [self path]];
}

-(void)moveToTrash
{
    NSString *trashPath = [[NSString stringWithFormat: @"~/.Trash/%@", [[self path] lastPathComponent]] stringByExpandingTildeInPath];
    while ([FILEMGR fileExistsAtPath: trashPath])
        [trashPath stringByAppendingString: @" copy"];
    
    [FILEMGR moveItemAtPath: [self path] toPath: trashPath error: nil];
    [self setAttr: trashPath forKey: @"Path"];
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
