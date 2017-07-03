//
//  PrefsWindowController.m
//  SnapDart
//
//  Created by Sveinbjorn Thordarson on 03/07/2017.
//
//

#import "PrefsWindowController.h"

@interface PrefsWindowController ()
{
    IBOutlet NSTableView *tableView;
    IBOutlet NSButton *installButton;
    IBOutlet NSButton *installAllButton;
    
    NSArray *toolItems;
}
@end

@implementation PrefsWindowController

- (instancetype)init {
    if ((self = [super init])) {
        toolItems = @[@"snap", @"label", @"paths", @"show", @"copy", @"getinfo", @"move", @"trash"];
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
}

- (IBAction)showHelp:(id)sender {

}

#pragma mark - Table View

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification {
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView {
    return [toolItems count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
    return @"Hello";
    return toolItems[rowIndex];
}

- (CGFloat)tableView:(NSTableView *)theTableView heightOfRow:(NSInteger)row {
    return 20;
}

@end
