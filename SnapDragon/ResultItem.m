/*
 Copyright (c) 2012-2017, Sveinbjorn Thordarson <sveinbjornt@gmail.com>
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification,
 are permitted provided that the following conditions are met:
 
 1. Redistributions of source code must retain the above copyright notice, this
 list of conditions and the following disclaimer.
 
 2. Redistributions in binary form must reproduce the above copyright notice, this
 list of conditions and the following disclaimer in the documentation and/or other
 materials provided with the distribution.
 
 3. Neither the name of the copyright holder nor the names of its contributors may
 be used to endorse or promote products derived from this software without specific
 prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
 IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
 NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
*/

#import <sys/stat.h>
#include <pwd.h>
#include <grp.h>

#import "ResultItem.h"

#import "Common.h"
#import "NSFileManager+FileOrFolderSize.m"
#import "NSWorkspaceExtensions.h"
#import "NSFileManager+FileOrFolderSize.m"

@interface ResultItem()
{
    struct stat statInfo;
    BOOL statLoaded;
    
    NSMutableDictionary *attr;
}

- (void)setAttr:(id)obj forKey:(NSString *)key;
- (BOOL)hasAttr:(NSString *)attr;
- (id)calcAttr:(NSString *)attr;

@end

@implementation ResultItem

#pragma mark - Initialization

- (instancetype)init {
    if ((self = [super init])) {
        attr = [[NSMutableDictionary alloc] initWithCapacity:12];
        statLoaded = FALSE;
    }
    return self;
}

- (instancetype)initWithPath:(NSString *)path {
    if ((self = [self init])) {
        [self setAttr:path forKey:@"Path"];
        _isDirectory = [FILEMGR isFolder:path];
    }
    return self;
}

+ (instancetype)itemWithPath:(NSString *)path {
    return [[ResultItem alloc] initWithPath:path];
}

#pragma mark - Attributes

- (void)setAttr:(id)obj forKey:(NSString *)key {
    attr[key] = obj;
}

- (BOOL)hasAttr:(NSString *)key {
    return (attr[key] != nil);
}

- (id)attr:(NSString *)key {
    if ([self hasAttr:key] == NO) {
        [self calcAttr:key];
    }
    return attr[key];
}

- (NSString *)path {
    return attr[@"Path"];
}

- (UInt64)size {
    [self _stat];
    return statInfo.st_size;
}

- (id)calcAttr:(NSString *)theAttribute {
    // icon
    if ([theAttribute isEqualToString:@"Icon"]) {
        // icon
        NSImage *icon = [[NSWorkspace sharedWorkspace] iconForFile:[self path]];
        if (icon) {
            [icon setSize:NSMakeSize(16,16)];
            [self setAttr:icon forKey:theAttribute];
        }
    }
    // size
    else if ([theAttribute isEqualToString:@"Size"]) {
        if (self.isDirectory) {
//            if ([DEFAULTS objectforKey:@"CalculateFolderSizes"])
//                [self setAttr:[FILEMGR fileOrFolderSizeAsHumanReadable:[self path]] forKey:@"Size"];
//            else
            [self setAttr:@"-" forKey:theAttribute];
        }
        else {
            [self _stat];
            
            NSString *sizeStr;
            if ([[DEFAULTS objectForKey:@"UseHumanReadableSizes"] boolValue]) {
                sizeStr = [FILEMGR sizeAsHumanReadable:statInfo.st_size];
            } else {
                sizeStr = [NSString stringWithFormat:@"%lld", statInfo.st_size, nil];
            }
            [self setAttr:sizeStr forKey:theAttribute];
        }
    }
    // created 
    else if ([theAttribute isEqualToString:@"Date Created"]) {
        [self _stat];
        NSDate *date = [NSDate dateWithTimeIntervalSince1970:statInfo.st_birthtime];
        [self setAttr:[date description] forKey:theAttribute];
    }
    // accessed 
    else if ([theAttribute isEqualToString:@"Date Accessed"]) {
        [self _stat];
        NSDate *date = [NSDate dateWithTimeIntervalSince1970:statInfo.st_atime];
        [self setAttr:[date description] forKey:theAttribute];
    }
    // modified 
    else if ([theAttribute isEqualToString:@"Date Modified"]) {
        [self _stat];
        NSDate *date = [NSDate dateWithTimeIntervalSince1970:statInfo.st_mtime];
        [self setAttr:[date description] forKey:theAttribute];
    }
    // kind
    else if ([theAttribute isEqualToString:@"Kind"])
    {
        NSURL *url = [NSURL fileURLWithPath:[self path]];
        CFStringRef kindStr = nil;
        LSCopyKindStringForURL((__bridge CFURLRef)url, &kindStr);
        if (kindStr !=  nil) {
            [self setAttr:[NSString stringWithString:(__bridge NSString*)kindStr] forKey:theAttribute];
            CFRelease(kindStr);
        } else {
            [self setAttr:@"Unknown" forKey:theAttribute];
        }
    }
    else if ([theAttribute isEqualToString:@"Permissions"]) {
        [self _stat];
        char buf[20];
        strmode(statInfo.st_mode, (char *)&buf);
        [self setAttr:@((char *)&buf) forKey:theAttribute];
    }
    else if ([theAttribute isEqualToString:@"User:Group"]) {
        [self _stat];
        const char *u, *g;
        u = user_from_uid(statInfo.st_uid, 0);
        g = group_from_gid(statInfo.st_gid, 0);
        NSString *user = @(u);
        NSString *group = @(g);
        NSString *ugStr = [NSString stringWithFormat:@"%@:%@", user, group, nil];
        [self setAttr:ugStr forKey:theAttribute];
    }
    else if ([theAttribute isEqualToString:@"UTI"]) {
        NSString *type = [[NSWorkspace sharedWorkspace] typeOfFile:[self path] error:nil];
        NSString *uti = (type == nil) ? @"" : type;
        [self setAttr:uti forKey:theAttribute];
    }
    else if ([theAttribute isEqualToString:@"HandlerApps"]) {
        NSMutableArray *apps = [NSMutableArray arrayWithCapacity:255];
        
        // first, get default app
        NSString *defaultApp = [[NSWorkspace sharedWorkspace] defaultApplicationForFile:[self path]];
        if (defaultApp)
            [apps addObject:defaultApp];
        
        // then, add other apps, excluding any duplicates of the default app, which is first
        NSArray *appsForFile = [[NSWorkspace sharedWorkspace] applicationsForFile:[self path]];
        for (NSString *app in appsForFile) {
            if (!(defaultApp && [app isEqualToString:defaultApp])) {
                [apps addObject:app];
            }
        }
        
        [self setAttr:apps forKey:theAttribute];
    }
    
    return attr[theAttribute];
}

#pragma mark - Actions

- (void)openInFinder {
    [[NSWorkspace sharedWorkspace] openFile:[self path]];
}

- (void)openWithApplication:(NSString *)appName {
    [[NSWorkspace sharedWorkspace] openFile:[self path] withApplication:appName];
}

- (void)showInFinder {
    [[NSWorkspace sharedWorkspace] selectFile:[self path] inFileViewerRootedAtPath:[self path]];
}

- (void)openContainingFolder {
    //[[self path] parent
}

- (void)getInfo {
	NSString *type = (self.isDirectory && ![[self path] hasSuffix:@".app"]) ? @"folder" : @"file";
	NSString *osaScript = [NSString stringWithFormat:
                           @"tell application \"Finder\"\n\
                           \tactivate\n\
                           \topen the information window of %@ POSIX file \"%@\"\n\
                           end tell", type, [self path], nil];
	
	NSTask	*theTask = [[NSTask alloc] init];
	
	//initialize task -- we launch the AppleScript via the 'osascript' CLI program
	[theTask setLaunchPath:@"/usr/bin/osascript"];
	[theTask setArguments:@[@"-e", osaScript]];
	[theTask launch];
    //NSLog([theTask fullDescription]);
    //[theTask waitUntilExit];
    //[theTask release];
}

- (void)quickLook {
	NSTask	*theTask = [[NSTask alloc] init];
    [theTask setLaunchPath:@"/usr/bin/qlmanage"];
	[theTask setArguments:@[@"-p", [self path]]];
	[theTask launch];
}

- (void)labelSelected:(id)sender {
	//[[NSWorkspace sharedWorkspace] setLabel:[sender tag] forFile:[self path]];
}

- (void)moveToTrash {
    NSString *trashPath = [[NSString stringWithFormat:@"~/.Trash/%@", [[self path] lastPathComponent]] stringByExpandingTildeInPath];
    while ([FILEMGR fileExistsAtPath:trashPath])
        [trashPath stringByAppendingString:@" copy"];
    
    [FILEMGR moveItemAtPath:[self path] toPath:trashPath error:nil];
    [self setAttr:trashPath forKey:@"Path"];
}

#pragma mark - Stat

- (void)_stat {
    if (statLoaded) {
        return;
    }
    stat([[self path] fileSystemRepresentation], &statInfo);
    statLoaded = TRUE;
}

#pragma mark - Debug

- (NSString *)description {
    return [attr description];
}

@end
