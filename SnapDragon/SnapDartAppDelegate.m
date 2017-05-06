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

#import "Common.h"
#import "SnapDartAppDelegate.h"
#import "SnapWindowController.h"

@interface SnapDartAppDelegate ()
{
    IBOutlet SnapWindowController *resultsController;
    CFTimeInterval lastOpenFileEvent;
    NSMutableArray *filesInOpenEvent;
    NSTimer *openFilesTimer;
}
@end

@implementation SnapDartAppDelegate

+ (void)initialize {
    NSString *path = [[NSBundle mainBundle] pathForResource:@"Defaults" ofType:@"plist"];
    NSDictionary *defaults = [NSDictionary dictionaryWithContentsOfFile:path];
    [DEFAULTS registerDefaults:defaults];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // do something
}

-(BOOL)application:(NSApplication *)sender openFile:(NSString *)filename{
    return YES;
}

- (void)application:(NSApplication *)theApplication openFiles:(NSArray *)filenames {
    // This is really hackish but Apple Events are stupid. A single open event
    // can result in multiple invocations of this method for the files, even
    // though it was all part of the same user interface action. We need to collect
    // the files from each event and then process them after a small delay.
    
    if (!filesInOpenEvent) {
        filesInOpenEvent = [NSMutableArray array];
    }
    
    if (openFilesTimer) {
        [openFilesTimer invalidate];
    }

    [filesInOpenEvent addObjectsFromArray:filenames];
    openFilesTimer = [NSTimer scheduledTimerWithTimeInterval:0.25f
                                                      target:self
                                                    selector:@selector(processOpenFiles)
                                                    userInfo:nil
                                                     repeats:NO];
    
    [theApplication replyToOpenOrPrint:NSApplicationDelegateReplySuccess];
}

- (void)processOpenFiles {
    NSArray *filesToOpen = [filesInOpenEvent copy];
    [openFilesTimer invalidate];
    openFilesTimer = nil;
    [filesInOpenEvent removeAllObjects];
    
    filesToOpen = [filesToOpen sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
    [resultsController clear];
    [resultsController addPaths:filesToOpen];
    
    NSLog(@"Opening %lu files", (unsigned long)[filesToOpen count]);
}

@end
