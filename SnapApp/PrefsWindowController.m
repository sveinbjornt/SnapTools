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

#import "PrefsWindowController.h"
#import "NSWorkspace+Additions.h"
#import "Common.h"

@interface PrefsWindowController ()
{
    IBOutlet NSTableView *tableView;
    IBOutlet NSButton *installButton;
    IBOutlet NSButton *installAllButton;
    IBOutlet NSPopUpButton *terminalClientPopupButton;
    
    NSDictionary *statusDisplayStrings;
    
    NSArray *toolItems;
}
@end

@implementation PrefsWindowController

- (instancetype)init {
    if ((self = [super init])) {
        toolItems = @[];
        
        NSAttributedString *instString = [[NSAttributedString alloc] initWithString:@"Installed"
                                                                         attributes:@{NSForegroundColorAttributeName: [NSColor grayColor]}];
        NSAttributedString *notInstStr = [[NSAttributedString alloc] initWithString:@"Not Installed"
                                                                         attributes:@{NSForegroundColorAttributeName: [NSColor redColor]}];
        NSAttributedString *oldStr = [[NSAttributedString alloc] initWithString:@"Old Version"
                                                                         attributes:@{NSForegroundColorAttributeName: [NSColor orangeColor]}];
        statusDisplayStrings = @{   @"installed": instString,
                                    @"not_installed": notInstStr,
                                    @"old": oldStr
                                };
        [self updateToolTable];
    }
    return self;
}

- (void)windowDidLoad {
    [super windowDidLoad];
}

- (void)awakeFromNib {
    [self setIconsForTerminalMenu];
}

- (void)setIconsForTerminalMenu {
    for (int i = 0; i < [terminalClientPopupButton numberOfItems]; i++) {
        [self setIconForTerminalMenuItemAtIndex:i];
    }
}

- (void)setIconForTerminalMenuItemAtIndex:(NSInteger)index {
    NSMenuItem *menuItem = [terminalClientPopupButton itemAtIndex:index];
    if ([menuItem image] != nil) {
        return; // already has an icon
    }
    NSSize smallIconSize = { 16, 16 };
    
    if ([[menuItem title] isEqualToString:@"Select..."] == FALSE) {
        NSImage *icon;
        NSString *appPath = [WORKSPACE fullPathForApplication:[menuItem title]];
        if (appPath) {
            icon = [WORKSPACE iconForFile:appPath];
        } else {
            icon = [NSImage imageNamed:@"NSDefaultApplicationIcon"];
        }
        [icon setSize:smallIconSize];
        [menuItem setImage:icon];
    }
}

- (IBAction)apply:(id)sender {
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self.window performClose:self];
}

- (IBAction)revertToDefaults:(id)sender {
    // load Defaults.plist and apply
    NSString *defaultsPath = [[NSBundle mainBundle] pathForResource:@"Defaults" ofType:@"plist"];
    NSDictionary *plist = [NSDictionary dictionaryWithContentsOfFile:defaultsPath];
    for (NSString *key in plist) {
        [[NSUserDefaults standardUserDefaults] setObject:plist[key] forKey:key];
    }
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (IBAction)showHelp:(id)sender {
    [WORKSPACE openPathInDefaultBrowser:[[NSBundle mainBundle] pathForResource:PROGRAM_DOCUMENTATION ofType:nil]];
}

#pragma mark - Tools

- (IBAction)installSelectedItem:(id)sender {
    NSDictionary *selectedTool = toolItems[[tableView selectedRow]];
    if ([[sender title] isEqualToString:@"Install"]) {
        [self installTool:selectedTool];
    } else {
        [self uninstallTool:selectedTool];
    }
    [self updateToolTable];
}

- (BOOL)installTool:(NSDictionary *)tool {
    return [FILEMGR copyItemAtPath:tool[@"path"] toPath:tool[@"install_path"] error:nil];
}

- (BOOL)uninstallTool:(NSDictionary *)tool {
    return [FILEMGR removeItemAtPath:tool[@"install_path"] error:nil];
}

- (IBAction)installAll:(id)sender {
    if ([[sender title] isEqualToString:@"Install All"]) {
        [self installAllTools];
    } else {
        [self uninstallAllTools];
    }
    [self updateToolTable];
}

- (BOOL)installAllTools {
    NSInteger failures = 0;
    for (NSDictionary *tool in toolItems) {
        if ([tool[@"status"] isEqualToString:@"installed"] == YES) {
            continue;
        }
        if (![self installTool:tool]) {
            failures += 1;
        }
    }
    return (failures == 0);
}

- (BOOL)uninstallAllTools {
    NSInteger failures = 0;
    for (NSDictionary *tool in toolItems) {
        if (![self uninstallTool:tool]) {
            failures += 1;
        }
    }
    return (failures == 0);
}

- (void)updateToolTable {
    toolItems = [self toolStatus];
    
    BOOL allInstalled = YES;
    for (NSDictionary *tool in toolItems) {
        if (![FILEMGR fileExistsAtPath:tool[@"install_path"]]) {
            allInstalled = NO;
            break;
        }
    }
    
    NSString *title = allInstalled ? @"Uninstall All" : @"Install All";
    [installAllButton setTitle:title];
    
    [self updateSelection];
    [tableView reloadData];
}

- (NSArray *)toolStatus {
    NSString *resourceDir = [[NSBundle mainBundle] resourcePath];
    NSDirectoryEnumerator *dirEnum = [[NSFileManager defaultManager] enumeratorAtPath:resourceDir];
    
    NSMutableArray *tools = [NSMutableArray array];
    NSImage *icon = [[NSImage alloc] initWithContentsOfFile:GENERIC_EXEC_ICON_PATH];
    
    NSString *filename;
    while ((filename = [dirEnum nextObject])) {
        NSString *path = [NSString stringWithFormat:@"%@/%@", resourceDir, filename];
        NSString *kind = [[NSWorkspace sharedWorkspace] kindStringForFile:path];
        if ([kind isEqualToString:@"Unix executable"]) {
            
            NSString *installPath = [NSString stringWithFormat:@"%@/%@", DEFAULT_TOOL_INSTALL_DIR, filename];
            NSString *status = @"not_installed";
            if ([[NSFileManager defaultManager] fileExistsAtPath:installPath]) {
                status = @"installed";
            }
            
            NSDictionary *t = @{ @"name":   [path lastPathComponent],
                                 @"path":   path,
                                 @"install_path": installPath,
                                 @"icon":   icon,
                                 @"status": status };
            [tools addObject:t];
        }
    }
    
    return tools;
}

#pragma mark - Table View

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification {
    [self updateSelection];
}

- (void)updateSelection {
    NSInteger selected = [tableView selectedRow];
    if (selected == -1) {
        [installButton setEnabled:NO];
        return;
    }
    
    NSDictionary *item = toolItems[selected];
    NSString *title = [item[@"status"] isEqualToString:@"installed"] ? @"Uninstall" : @"Install";
    [installButton setTitle:title];
    [installButton setEnabled:YES];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView {
    return [toolItems count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
    NSString *identifier = [aTableColumn identifier];
    if ([identifier isEqualToString:@"status"]) {
        return statusDisplayStrings[toolItems[rowIndex][identifier]];
    }
    
    return toolItems[rowIndex][identifier];
}

- (CGFloat)tableView:(NSTableView *)theTableView heightOfRow:(NSInteger)row {
    return 20;
}

@end
