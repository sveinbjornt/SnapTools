/*
 Copyright (c) 2017, Sveinbjorn Thordarson <sveinbjornt@gmail.com>
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

#import <Cocoa/Cocoa.h>

#import <unistd.h>
#import <stdio.h>
#import <sysexits.h>
#import <getopt.h>

#import "Common.h"
#import "PathParser.h"

static NSMutableSet *ReadDirectoryContents(NSString *dirPath);

static NSString *ReadStandardInput();

static BOOL SendOpenDocumentAppleEvent(NSSet *paths);
static void PrintVersion(void);
static void PrintHelp(void);

static void NSPrintErr(NSString *format, ...);
static void NSPrint(NSString *format, ...);

static const char optstring[] = "apvh";

static struct option long_options[] = {
    {"all",                     no_argument,            0,  'a'},
    {"print",                   no_argument,            0,  'p'},
    {"version",                 no_argument,            0,  'v'},
    {"help",                    no_argument,            0,  'h'},
    {0,                         0,                      0,    0}
};

#pragma mark -

int main(int argc, const char * argv[]) { @autoreleasepool {
    
    BOOL printOnly = NO;
    BOOL showAll = NO;
    
    int optch;
    int long_index = 0;
    
    // parse getopt
    while ((optch = getopt_long(argc, (char *const *)argv, optstring, long_options, &long_index)) != -1) {
        switch (optch) {
            
            // show all hidden files except . and ..
            case 'a':
                showAll = YES;
                break;
            
            // only print found paths
            case 'p':
                printOnly = YES;
                break;
                
            // print version
            case 'v':
            {
                PrintVersion();
                exit(EX_OK);
            }
                break;
                
            // print help with list of options
            case 'h':
            default:
            {
                PrintHelp();
                exit(EX_OK);
            }
                break;
        }
    }
    
    // read remaining args
    NSMutableArray *remainingArgs = [NSMutableArray array];
    while (optind < argc) {
        NSString *argStr = @(argv[optind]);
        [remainingArgs addObject:argStr];
        optind += 1;
    }
    
    NSMutableSet *paths = [NSMutableSet set];
    
    // read standard input if no file args
    if ([remainingArgs count] == 0) {
        
        NSString *standardInput = ReadStandardInput();
        if (!standardInput) {
            return EX_NOINPUT;
        }
        paths = [PathParser parse:standardInput];
        
    } else {
        
        // process file args
        for (NSString *filePath in remainingArgs) {
            NSString *f = [PathParser makeAbsolutePath:filePath];
            if ([FILEMGR fileExistsAtPath:f]) {
                [paths addObject:f];
            } else {
                NSPrint(@"No such file or directory: %@", f);
            }
        }
    }
    
    // a single directory as arg means we should list contents
    if ([paths count] == 1) {
        NSString *p = [paths anyObject];
        BOOL isDir = NO;
        if ([FILEMGR fileExistsAtPath:p isDirectory:&isDir] && isDir) {
            paths = ReadDirectoryContents(p);
        }
    }
    
    // Sort alphabetically
    NSArray *finalPaths = [paths allObjects];
    finalPaths = [finalPaths sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
    
    // Hand paths over to SnapDart app via Apple Event
    if ([paths count]) {
        
        if (printOnly) {
            for (NSString *p in finalPaths) {
                NSPrint(@"%@", p);
            }
        }
        else {
            BOOL success = SendOpenDocumentAppleEvent(paths);
            if (!success) {
                NSPrintErr(@"Error launching SnapDart app");
                exit(EX_UNAVAILABLE);
            }
        }

    } else {
        NSPrintErr(@"No paths provided");
        exit(EX_USAGE);
    }
    
    return EX_OK;
} }

#pragma mark -

static NSMutableSet *ReadDirectoryContents(NSString *dirPath) {
    NSMutableSet *pathSet = [NSMutableSet set];
    NSArray *dirContents = [FILEMGR contentsOfDirectoryAtPath:dirPath error:nil];
    for (NSString *item in dirContents) {
        NSString *fpath = [dirPath stringByAppendingPathComponent:item];
        [pathSet addObject:fpath];
    }
    return pathSet;
}

static BOOL SendOpenDocumentAppleEvent(NSSet *paths) {
    
    // convert path strings to url objects
    NSMutableArray *urls = [NSMutableArray array];
    for (NSString *p in paths) {
        [urls addObject:[NSURL fileURLWithPath:p]];
    }
    
    NSPrintErr(@"Sending AEvent to open %d URLs", [urls count]);
    
    return [[NSWorkspace sharedWorkspace] openURLs:urls
                           withAppBundleIdentifier:PROGRAM_BUNDLE_IDENTIFIER
                                           options:NSWorkspaceLaunchAsync | NSWorkspaceLaunchWithErrorPresentation
             additionalEventParamDescriptor:nil
                          launchIdentifiers:NULL];
}

static NSString *ReadStandardInput() {
    NSData *inData = [[NSFileHandle fileHandleWithStandardInput] readDataToEndOfFile];
    if (!inData) {
        return nil;
    }
    return [[NSString alloc] initWithData:inData encoding:NSUTF8StringEncoding];
}

#pragma mark -

static void PrintVersion(void) {
    NSPrint(@"snap version %@", PROGRAM_VERSION);
}

static void PrintHelp(void) {
    NSPrint(@"usage: snap [args ...]");
}

#pragma mark -

// print to stdout
static void NSPrint(NSString *format, ...) {
    va_list args;
    
    va_start(args, format);
    NSString *string  = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    
    fprintf(stdout, "%s\n", [string UTF8String]);
}

// print to stderr
static void NSPrintErr(NSString *format, ...) {
    va_list args;
    
    va_start(args, format);
    NSString *string  = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    
    fprintf(stderr, "%s\n", [string UTF8String]);
}
