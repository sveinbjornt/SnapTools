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

static void PrintHelp(void);

static const char optstring[] = "nfvh";

static struct option long_options[] = {
    {"new",                     no_argument,            0,  'n'},
    {"force",                   no_argument,            0,  'f'},
    {"version",                 no_argument,            0,  'v'},
    {"help",                    no_argument,            0,  'h'},
    {0,                         0,                      0,    0}
};

int main(int argc, const char * argv[]) { @autoreleasepool {
    int optch;
    int long_index = 0;
    
    BOOL inNewViewer = NO;
    BOOL force = NO;
    
    // parse getopt
    while ((optch = getopt_long(argc, (char *const *)argv, optstring, long_options, &long_index)) != -1) {
        switch (optch) {
            
            // open in new viewer
            case 'n':
                inNewViewer = YES;
                break;
            
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
        NSPrintErr(@"Unable to show file in Finder: Finder not running.");
        exit(EX_UNAVAILABLE);
    }
    
    // Check if number of files exceeds limit
    if (([filePaths count] > DANGEROUS_FILE_LIMIT) && !force) {
        NSPrintErr(@"File count exceeds safety limit of %d. Use -f flag to override.",
                   DANGEROUS_FILE_LIMIT);
        exit(EX_USAGE);
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
        
        if (inNewViewer) {
            [[NSWorkspace sharedWorkspace] openFile:parentDirectoryPath withApplication:@"Finder"];
        }
        
        [[NSWorkspace sharedWorkspace] selectFile:path inFileViewerRootedAtPath:rootFullPath];
    }
    
    return EX_OK;
}}

#pragma mark -

static void PrintHelp(void) {
    NSPrint(@"usage: %@ [file1 file2 ...]", [[NSProcessInfo processInfo] processName]);
}
