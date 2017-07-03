//
//  PrefsWindowController.m
//  SnapDart
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
    
    NSArray *toolItems;
    NSImage *genericExecutableIcon;
}
@end

@implementation PrefsWindowController

- (instancetype)init {
    if ((self = [super init])) {
        toolItems = @[@"snap", @"label", @"paths", @"show", @"copy", @"getinfo", @"move", @"trash"];
        genericExecutableIcon = [[NSImage alloc] initWithContentsOfFile:GENERIC_EXEC_ICON_PATH];
    }
    return self;
}

- (void)windowDidLoad {
    [super windowDidLoad];
}

- (IBAction)install:(id)sender {
    
}

- (IBAction)installAll:(id)sender {
    
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

#pragma mark - Table View

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification {
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView {
    return [toolItems count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
    NSString *ident = [aTableColumn identifier];
    if ([ident isEqualToString:@"Icon"] || [ident isEqualToString:@"Install"]) {
        return genericExecutableIcon;
    }
    
    return toolItems[rowIndex];
}

- (CGFloat)tableView:(NSTableView *)theTableView heightOfRow:(NSInteger)row {
    return 20;
}

@end
