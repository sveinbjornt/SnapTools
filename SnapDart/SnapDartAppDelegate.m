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
#import "CmdWindowController.h"
#import "NSWorkspace+Additions.h"
#import "Alerts.h"

@interface SnapDartAppDelegate ()
{
    IBOutlet NSMenu *mainMenu;
    IBOutlet NSMenu *columnsMenu;
    
    NSStatusItem *statusItem;
    NSMutableArray *filesInOpenEvent;
    NSTimer *openFilesTimer;
    
    CmdWindowController *cmdController;
    NSMutableArray *controllers;
}
@end

@implementation SnapDartAppDelegate

- (void)awakeFromNib {
    controllers = [NSMutableArray array];
    [self createColumnsSubmenu];
    [self createStatusMenuItem];
}

+ (void)initialize {
    NSString *path = [[NSBundle mainBundle] pathForResource:@"Defaults" ofType:@"plist"];
    NSDictionary *defaults = [NSDictionary dictionaryWithContentsOfFile:path];
    [DEFAULTS registerDefaults:defaults];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // created required App Support folders
    BOOL isDir;
    NSError *err;
    for (NSString *dirPath in PROGRAM_REQUIRED_DIRS) {
        BOOL existingDir = ([FILEMGR fileExistsAtPath:dirPath isDirectory:&isDir] && isDir);
        if (!existingDir && ![FILEMGR createDirectoryAtPath:dirPath withIntermediateDirectories:YES attributes:nil error:&err]) {
            [Alerts alert:@"Error" subTextFormat:@"Could not create directory '%@', %@",
             dirPath, [err localizedDescription]];
        }
    }
}

-(BOOL)application:(NSApplication *)sender openFile:(NSString *)filename{
    return YES;
}

- (void)application:(NSApplication *)theApplication openFiles:(NSArray *)filenames {
    // This is really hackish but Apple Events are stupid. A single open event
    // can result in multiple invocations of this method for the files, even
    // though it was all part of the same user interface action. We need to collect
    // the files from each event and then process them after a small delay [!].
    
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
    
    NSLog(@"Opening %lu files", (unsigned long)[filesToOpen count]);
    [self newSnapWindowWithPaths:filesToOpen];
}

- (void)newSnapWindowWithPaths:(NSArray *)paths {
    SnapWindowController *c = [[SnapWindowController alloc] initWithWindowNibName:@"SnapWindow"];
    [[c window] makeKeyWindow];
    [controllers addObject:c];
    [c addPaths:paths];
}

#pragma mark -

- (void)createStatusMenuItem {
    statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    [statusItem setHighlightMode:YES];
    [statusItem setMenu:mainMenu];
    [statusItem setImage:[NSImage imageNamed:@"Status Menu Icon"]];
    
    [[statusItem image] setTemplate:YES];
    [statusItem setEnabled:YES];
}

- (void)createColumnsSubmenu {
    for (NSString *colName in COLUMNS) {
        NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:colName action:nil keyEquivalent:@""];
        [columnsMenu insertItem:item atIndex:0];
        
        NSMutableDictionary *bindingOptions = [NSMutableDictionary dictionary];
        [bindingOptions setObject:@(YES) forKey:NSValidatesImmediatelyBindingOption];
        [item bind:@"value" toObject:[NSUserDefaults standardUserDefaults] withKeyPath:colName options:@{}];
    }
}

#pragma mark - Command Window

- (IBAction)showCmdWindow:(id)sender {
    if (cmdController == nil) {
        cmdController = [[CmdWindowController alloc] initWithWindowNibName:@"CmdWindow"];
    }
    [[cmdController window] center];
    [[cmdController window] makeKeyAndOrderFront:self];
}

#pragma mark - Uninstall

- (IBAction)uninstallProgram:(id)sender {
    
}

#pragma mark - Help/Documentation/Website

// Open Documentation.html file within app bundle
- (IBAction)showHelp:(id)sender {
    [WORKSPACE openPathInDefaultBrowser:[[NSBundle mainBundle] pathForResource:PROGRAM_DOCUMENTATION ofType:nil]];
}

// Open HTML version of snap command line tool's man page
- (IBAction)showManPage:(id)sender {
    [WORKSPACE openPathInDefaultBrowser:[[NSBundle mainBundle] pathForResource:PROGRAM_MANPAGE ofType:nil]];
}

// Open program website
- (IBAction)openWebsite:(id)sender {
    [WORKSPACE openURL:[NSURL URLWithString:PROGRAM_WEBSITE]];
}

// Open program GitHub website
- (IBAction)openGitHubWebsite:(id)sender {
    [WORKSPACE openURL:[NSURL URLWithString:PROGRAM_GITHUB_WEBSITE]];
}

// Open License HTML file
- (IBAction)openLicense:(id)sender {
    [WORKSPACE openPathInDefaultBrowser:[[NSBundle mainBundle] pathForResource:PROGRAM_LICENSE_FILE ofType:nil]];
}

// Open donations website
- (IBAction)openDonations:(id)sender {
    [WORKSPACE openURL:[NSURL URLWithString:PROGRAM_DONATIONS]];
}

@end
