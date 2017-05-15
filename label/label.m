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
#import "NSWorkspace+Additions.h"

static void PrintHelp(void);

static const char optstring[] = "fvh";

static struct option long_options[] = {
    {"force",                   no_argument,            0,  'f'},
    {"version",                 no_argument,            0,  'v'},
    {"help",                    no_argument,            0,  'h'},
    {0,                         0,                      0,    0}
};

int main(int argc, const char * argv[]) { @autoreleasepool {
    int optch;
    int long_index = 0;
    
    BOOL force = NO;
    
    // parse getopt
    while ((optch = getopt_long(argc, (char *const *)argv, optstring, long_options, &long_index)) != -1) {
        switch (optch) {
            
            // ignore file limit
            case 'f':
                force = YES;
                break;
                
            // print version
            case 'v':
            {
                NSPrint(@"labels version %@", PROGRAM_VERSION);
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
        [remainingArgs addObject:argStr];
    }
    
    if (![remainingArgs count]) {
        PrintHelp();
        exit(EX_USAGE);
    }
    
    // First arg is label identifier
    NSString *labelArg = remainingArgs[0];
    [remainingArgs removeObjectAtIndex:0];
    // TODO: Get label ID from label arg
    
    NSMutableArray *filePaths = [NSMutableArray array];
    
    // read from stdin if label identifier is the only arg
    if ([remainingArgs count] == 0) {
        NSString *input = ReadStandardInput();
        NSMutableSet *set = [PathParser parse:input]; // TODO: Do something with absolutePathsOnly
        [filePaths addObjectsFromArray:[set allObjects]];
    }
    else {
        // Interpret remaining args as file paths
        for (NSString *arg in remainingArgs) {
            NSString *absPath = [PathParser makeAbsolutePath:arg];
        
            if ([[NSFileManager defaultManager] fileExistsAtPath:absPath] == NO) {
                NSPrintErr(@"no such file, skipping: %@", absPath);
                continue;
            }
            
            [filePaths addObject:absPath];
        }
    }
    
    // Check if number of files exceeds limit
    int lim = DANGEROUS_FILE_OPERATIONS_LIMIT;
    if (([filePaths count] > lim) && !force) {
        NSPrintErr(@"File count exceeds safety limit of %d. Use -f flag to override.", lim);
        exit(EX_USAGE);
    }
    
    // Set label of the files
    int count = 0;
    for (NSString *path in filePaths) {
        // do label thing
        
        NSURL *fileURL = [NSURL fileURLWithPath:path];
        NSError *err;
        BOOL succ = [fileURL setResourceValue:@6
                                       forKey:NSURLLabelNumberKey
                                        error:&err];
        if (!succ) {
            NSPrint(@"%@", [err localizedDescription]);
            continue;
        }
        [[NSWorkspace sharedWorkspace] notifyFinderFileChangedAtPath:path];
        count += 1;
        //NSPrint(path);
    }
    
    NSPrint(@"Label of %d file%@ set to \"%@\"", count, count > 1 ? @"s" : @"", labelArg);
    
    return EX_OK;
}}

#pragma mark -

static void PrintHelp(void) {
    NSPrint(@"usage: label identifier [file ...]");
}
