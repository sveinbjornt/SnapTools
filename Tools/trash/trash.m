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

#import "CLI.h"
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
                PrintProgramVersion();
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
    
    NSMutableArray *args = ReadRemainingArgs(argc, argv);
    BOOL readStdin = ([args count] == 0);
    
    NSMutableArray *filePaths = [NSMutableArray array];
    
    if (readStdin) {
        filePaths = ReadPathsFromStandardInput(NO);
    } else {
        filePaths = ValidPathsInArguments(args);
        if ([filePaths count] < 1) {
            PrintHelp();
            exit(EX_USAGE);
        }
    }
    
    // Make sure Finder is running
    if ([[NSWorkspace sharedWorkspace] isFinderRunning] == NO) {
        NSPrintErr(@"Unable to trash files. Finder not running.");
        exit(EX_UNAVAILABLE);
    }
    
    // Check if number of files exceeds limit
    if (([filePaths count] > DANGEROUS_FILE_LIMIT) && !force) {
        NSPrintErr(@"File count exceeds safety limit of %d. Use -f flag to override.",
                   DANGEROUS_FILE_LIMIT);
        exit(EX_USAGE);
    }
    
    unsigned long trashed = 0;
    for (NSString *path in filePaths) {
        if ([[NSWorkspace sharedWorkspace] moveFileToTrash:path]) {
            trashed += 1;
        }
    }
    
    if (trashed) {
        NSPrint(@"%d file%@ moved to the Trash", trashed, trashed > 1 ? @"s" : @"");
    }
    
    return EX_OK;
}}

#pragma mark -



static void PrintHelp(void) {
    NSPrint(@"usage: %@ [file1 file2 ...]", [[NSProcessInfo processInfo] processName]);
}
