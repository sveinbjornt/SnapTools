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

#import <sysexits.h>
#import <getopt.h>

#import "Common.h"
#import "NSCommandLine.h"
#import "PathParser.h"

static void PrintVersion(void);
static void PrintHelp(void);

static const char optstring[] = "nvh";

static struct option long_options[] = {
    {"new",                     no_argument,            0,  'n'},
    {"version",                 no_argument,            0,  'v'},
    {"help",                    no_argument,            0,  'h'},
    {0,                         0,                      0,    0}
};

int main(int argc, const char * argv[]) { @autoreleasepool {
    int optch;
    int long_index = 0;
    
    BOOL inNewViewer = NO;
    
    // parse getopt
    while ((optch = getopt_long(argc, (char *const *)argv, optstring, long_options, &long_index)) != -1) {
        switch (optch) {
            
            // open in new viewer
            case 'n':
                inNewViewer = YES;
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
        optind += 1;
        
        NSString *absPath = [PathParser makeAbsolutePath:argStr];
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:absPath] == NO) {
            NSPrintErr(@"no such file, skipping: %@", absPath);
            continue;
        }
        
        [remainingArgs addObject:absPath];
    }
    
    BOOL readStdin = (BOOL)[remainingArgs count];
    
    NSMutableArray *filePaths = [NSMutableArray array];
    
    if (readStdin) {
        NSString *input = ReadStandardInput();
        
        NSMutableSet *set = [PathParser parse:input];
        [filePaths addObjectsFromArray:[set allObjects]];
    } else {
        
        // read remaining args
        while (optind < argc) {
            NSString *argStr = @(argv[optind]);
            optind += 1;
            
            NSString *absPath = [PathParser makeAbsolutePath:argStr];
            
            if ([[NSFileManager defaultManager] fileExistsAtPath:absPath] == NO) {
                NSPrintErr(@"no such file, skipping: %@", absPath);
                continue;
            }
            
            [filePaths addObject:absPath];
        }
        
        if ([filePaths count] < 1) {
            PrintHelp();
            exit(EX_USAGE);
        }
    }
    
    for (NSString *path in filePaths) {
        NSString *basename = [path lastPathComponent];
        if ([basename hasPrefix:@"."]) {
            NSPrintErr(@"warning: %@ is hidden and may not be shown", basename);
        }
        
        /* Activate the Finder and open a window selecting the file at the given path.  If fullPath is nil, this will instead open the directory specified by rootFullPath, and not select any file. If rootFullPath is the empty string (@""), the file is selected in the main viewer. Otherwise, a new file viewer is opened.
         */
        NSString *parentDirectoryPath = [path stringByDeletingLastPathComponent];
        NSString *rootFullPath = inNewViewer ? parentDirectoryPath : @"";
        
        if (inNewViewer && parentDirectoryPath != nil) {
            [[NSWorkspace sharedWorkspace] openFile:parentDirectoryPath withApplication:@"Finder"];
        }
        
        [[NSWorkspace sharedWorkspace] selectFile:path inFileViewerRootedAtPath:rootFullPath];
    }
    
    return EX_OK;
}}

#pragma mark -

static void PrintVersion(void) {
    NSPrint(@"show version %@", PROGRAM_VERSION);
}

static void PrintHelp(void) {
    NSPrint(@"usage: show [file2 file2 ...]");
}
