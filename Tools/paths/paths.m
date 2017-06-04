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

static const char optstring[] = "avh";

static struct option long_options[] = {
    {"absolute-only",           no_argument,            0,  'a'},
    {"version",                 no_argument,            0,  'v'},
    {"help",                    no_argument,            0,  'h'},
    {0,                         0,                      0,    0}
};

int main(int argc, const char * argv[]) { @autoreleasepool {
    int optch;
    int long_index = 0;
    
    BOOL absolutePathsOnly = NO;
    
    // parse getopt
    while ((optch = getopt_long(argc, (char *const *)argv, optstring, long_options, &long_index)) != -1) {
        switch (optch) {
            
            // only parse absolute paths
            case 'a':
                absolutePathsOnly = YES;
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
    
    // ignore any remaining command line args and read from stdin
    // TODO: Do something with absolutePathsOnly
    NSMutableArray *filePaths = ReadPathsFromStandardInput(absolutePathsOnly);
    
    for (NSString *path in filePaths) {
        NSPrint(path);
    }
    
    return EX_OK;
}}

#pragma mark -

static void PrintHelp(void) {
    NSPrint(@"usage: %@ [avh]", [[NSProcessInfo processInfo] processName]);
}
