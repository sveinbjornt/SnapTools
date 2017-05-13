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

#import "CmdWindowController.h"
#import "Common.h"
#import "SnapDartAppDelegate.h"
#import "PathParser.h"

@interface CmdWindowController ()
{
    IBOutlet NSTextField *cmdTextField;
    IBOutlet NSButton *runButton;
    IBOutlet NSTextField *itemCountTextField;
    IBOutlet NSProgressIndicator *progressIndicator;
    
    NSTask          *task;
    NSTimer         *checkStatusTimer;
    NSPipe          *outputPipe;
    NSFileHandle    *readHandle;
    BOOL            isTaskRunning;
    BOOL            outputEmpty;
    NSMutableString *outputString;
}
@end

@implementation CmdWindowController

- (void)windowDidLoad {
    [super windowDidLoad];
    
    NSString *notificationName = NSTaskDidTerminateNotification;
//    if (execStyle == PlatypusExecStyle_Authenticated) {
//        notificationName = STPrivilegedTaskDidTerminateNotification;
//    }
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(taskFinished:)
                                                 name:notificationName
                                               object:nil];

}

- (IBAction)runButtonPressed:(id)sender {
    [self runCommand:[cmdTextField stringValue]];
}

#pragma mark - Task

- (void)runCommand:(NSString *)cmd {
    
    outputString = [NSMutableString string];
    
    //initalize task
    task = [[NSTask alloc] init];
    
    //apply settings for task
    [task setLaunchPath:@"/bin/bash"];
    
    // construct arguments list
    NSMutableArray *args = [[NSMutableArray alloc] initWithCapacity:10];
    [args addObject:@"-l"];
    [args addObject:@"-c"];
    [args addObject:cmd];
    [task setArguments:args];
    
    [task setCurrentDirectoryPath:[@"~/" stringByExpandingTildeInPath]];
    
    // set output to file handle and start monitoring it if script provides feedback
    outputPipe = [NSPipe pipe];
    [task setStandardOutput:outputPipe];
    readHandle = [outputPipe fileHandleForReading];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(getOutputData:) name:NSFileHandleReadCompletionNotification object:readHandle];
    [readHandle readInBackgroundAndNotify];
    
    //set it off
    isTaskRunning = YES;
    NSLog(@"Executing %@", [task description]);
    [task launch];
    
    [progressIndicator setUsesThreadedAnimation:YES];
    [progressIndicator startAnimation:self];
}

// read from the file handle and append it to the text window
- (void)getOutputData:(NSNotification *)aNotification {
    //get the data from notification
    NSData *data = [aNotification userInfo][NSFileHandleNotificationDataItem];
    
    //make sure there's actual data
    if ([data length]) {
        NSString *str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        if (str) {
            // append
            [outputString appendString:str];
        }
        // schedule to go and read more data in the background again.
        [[aNotification object] readInBackgroundAndNotify];
    }
}

// OK, called when we receive notification that task is finished
// Some cleaning up to do, controls need to be adjusted, etc.
- (void)taskFinished:(NSNotification *)aNotification {
    
    // stop and dispose of task
    if (task != nil) {
        task = nil;
    }
    isTaskRunning = NO;
    
    // clear filehandle of any remaining data
    NSData *data;
    while ((data = [readHandle availableData]) && [data length]) {
        [outputString appendString:[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]];
    }
    
    [progressIndicator stopAnimation:self];
    
    NSMutableSet *paths = [PathParser parse:outputString];
    
    SnapDartAppDelegate *del = (SnapDartAppDelegate *)[[NSApplication sharedApplication] delegate];
    
    NSLog(@"Output: %@", outputString);
    NSLog(@"%@", [paths description]);
    
    if ([paths count]) {
        [del newSnapWindowWithPaths:[paths allObjects]];
    } else {
        NSBeep();
    }
}

@end
