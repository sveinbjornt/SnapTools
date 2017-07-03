//
//  PrefsWindowController.m
//  SnapTools
//
//  Created by Sveinbjorn Thordarson on 03/07/2017.
//
//

#import "PrefsWindowController.h"
#import "NSWorkspace+Additions.h"
#import "Common.h"

@interface PrefsWindowController ()
{
    IBOutlet NSTableView *tableView;
    IBOutlet NSButton *installButton;
    IBOutlet NSButton *installAllButton;
    
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

- (IBAction)apply:(id)sender {
    [self.window performClose:self];
}

- (IBAction)revertToDefaults:(id)sender {
    // load registrationDefaults.plist and apply
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
