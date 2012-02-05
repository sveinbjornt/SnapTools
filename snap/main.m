//
//  main.m
//  snap
//
//  Created by Sveinbjorn Thordarson on 2/5/12.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <unistd.h>
#import <stdio.h>
#import "Common.h"


static NSString* MakeRandomTempFile (void);
static NSString* MakeAbsolutePath (NSString *path);
static void NSPrintErr (NSString *format, ...);
static void NSPrint (NSString *format, ...);

int main (int argc, const char * argv[])
{
    NSAutoreleasePool   *pool = [[NSAutoreleasePool alloc] init];
    NSMutableArray      *args = [NSMutableArray arrayWithCapacity: ARG_MAX];

    // create nsarray of args
    int i;
    for (i = 1; i < argc; i++)
    {
        NSString *path = MakeAbsolutePath([NSString stringWithCString: argv[i] encoding: NSUTF8StringEncoding]);
        [args addObject: path];
    }
    
    // if a single arg
    if ([args count] == 1)
    {
        NSString *path = [args objectAtIndex: 0];
        if (![FILEMGR fileExistsAtPath: path])
        {
            NSPrintErr(@"File does not exist: %@", path, nil);
            exit(1);
        }
        
        [[NSWorkspace sharedWorkspace] openFile: path withApplication: @"SnapDragon"];
        exit(0);
    }
    
    NSString *tmpFile = MakeRandomTempFile();;
    
    // if zero args, we read from stdin
    if ([args count] == 0)
    {
        // read data
        NSData *inData = [[NSFileHandle fileHandleWithStandardInput] readDataToEndOfFile];
        if (!inData)
        {
            NSPrintErr(@"Empty buffer, aborting.");
            exit(1);
        }
        
        // conver to string
        NSString *inStr = [[NSString alloc] initWithData: inData encoding: NSUTF8StringEncoding];
        if (!inStr)
        {
            NSPrintErr(@"Cannot handle non-text data.");
            exit(1);
        }
        NSArray *paths = [inStr componentsSeparatedByString: @"\n"];
        NSString *outStr = @"";
        for (NSString *path in paths)
        {
            if (![path isEqualToString: @""])
            {
                NSString *absPath   = MakeAbsolutePath(path);
                NSString *fmt       = (path == [paths lastObject]) ? @"%@" : @"%@\n";
                
                outStr = [outStr stringByAppendingFormat: fmt, absPath, nil];
            }
        }
        
        // write to temp file
        [outStr writeToFile: tmpFile  atomically: NO encoding: NSUTF8StringEncoding error: nil];
    }
    else
    {
        NSString *str = @"";
        
        for (NSString *path in args)
            str = [str stringByAppendingFormat: @"%@\n", path, nil];
        
        [str writeToFile: tmpFile atomically: NO encoding: NSUTF8StringEncoding error: nil];
    }
    
    // make sure file was created
    if (![FILEMGR fileExistsAtPath: tmpFile])
    {
        NSPrintErr(@"Error creating file %@", tmpFile, nil);
        exit(1);
    }
    
    // open file w. SnapDragon app
    [[NSWorkspace sharedWorkspace] openFile: tmpFile withApplication: @"SnapDragon"];
         
    [pool drain];
    return 0;
}

static NSString* MakeAbsolutePath (NSString *path)
{
    path = [path stringByExpandingTildeInPath];
    if ([path isAbsolutePath] == NO)
        path = [[FILEMGR currentDirectoryPath] stringByAppendingPathComponent: path];
    return [path stringByStandardizingPath];
}

static NSString* MakeRandomTempFile (void)
{
    // generate path for tmp file
    NSString *tempFileTemplate = [SNAP_TMP_DIR stringByAppendingPathComponent: TMP_SCRIPT_TEMPLATE];
    const char *tempFileTemplateCString = [tempFileTemplate fileSystemRepresentation];
    char *tempFileNameCString = (char *)malloc(strlen(tempFileTemplateCString) + 1);
    strcpy(tempFileNameCString, tempFileTemplateCString);
    
    // use mkstemp to expand template
    int fileDescriptor = mkstemp(tempFileNameCString);
    if (fileDescriptor == -1)
        return nil;
    close(fileDescriptor);
    
    // create nsstring from the c-string temp path
    NSString *tempScriptPath = [FILEMGR stringWithFileSystemRepresentation:tempFileNameCString length:strlen(tempFileNameCString)];
    free(tempFileNameCString);
    
    return tempScriptPath;
}

#pragma mark -

static void NSPrint (NSString *format, ...)
{
    va_list args;
	
    va_start (args, format);
	
    NSString *string;
	
    string = [[NSString alloc] initWithFormat: format  arguments: args];
	
    va_end (args);
	
	fprintf(stdout, "%s\n", [string UTF8String]);
	
    [string release];	
}

static void NSPrintErr (NSString *format, ...)
{
    va_list args;
	
    va_start (args, format);
	
    NSString *string;
	
    string = [[NSString alloc] initWithFormat: format  arguments: args];
	
    va_end (args);
	
    fprintf(stderr, "%s\n", [string UTF8String]);
	
    [string release];
	
} 



