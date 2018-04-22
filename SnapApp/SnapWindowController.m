/*
 Copyright (c) 2012-2017, Sveinbjorn Thordarson <sveinbjorn@sveinbjorn.org>
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

#import <AppKit/AppKit.h>
#import <Carbon/Carbon.h>
#import <sys/stat.h>

#import "SnapWindowController.h"
#import "SnapAppDelegate.h"

#import "Common.h"
#import "SnapItem.h"
#import "NSWorkspace+Additions.h"

@interface SnapWindowController ()
{
    NSMutableArray  *results;
    
    IBOutlet NSTableView *resultsTableView;
    IBOutlet NSProgressIndicator *progressIndicator;
    IBOutlet NSSearchField *filterTextField;
    IBOutlet NSTextField *numResultsTextField;
    IBOutlet NSMenu *tableColumnContextualMenu;
    IBOutlet NSView *statusBarView;
    IBOutlet NSScrollView *scrollView;
}

- (IBAction)interfaceSizeSelected:(id)sender;
- (IBAction)columnChanged:(id)sender;
- (IBAction)open:(id)sender;
- (IBAction)showInFinder:(id)sender;
- (IBAction)getInfo:(id)sender;
- (IBAction)copyFile:(id)sender;
- (IBAction)quickLook:(id)sender;
- (IBAction)setLabel:(id)sender;
- (IBAction)deleteFile:(id)sender;
- (IBAction)moveToTrash:(id)sender;
- (IBAction)openDirectoryInTerminal:(id)sender;
- (IBAction)runInTerminal:(id)sender;
- (void)updateNumFiles;

@end

@implementation SnapWindowController

- (BOOL)window:(NSWindow *)window shouldPopUpDocumentPathMenu:(NSMenu *)menu {
    // prevent popup menu when window icon/title is cmd-clicked
    return NO;
}

- (BOOL)window:(NSWindow *)window shouldDragDocumentWithEvent:(NSEvent *)event from:(NSPoint)dragImageLocation withPasteboard:(NSPasteboard *)pasteboard {
    // prevent dragging of title bar icon
    return NO;
}

- (void)windowDidLoad {
    [super windowDidLoad];

    results = [NSMutableArray array];

    // put application icon in window title bar
    [[self window] setRepresentedURL:[NSURL URLWithString:PROGRAM_WEBSITE]];
    NSButton *button = [[self window] standardWindowButton:NSWindowDocumentIconButton];
    [button setImage:[NSApp applicationIconImage]];
    
    // table view
    [resultsTableView setTarget:self];
    [resultsTableView setDoubleAction:@selector(open:)];
    [resultsTableView setDraggingSourceOperationMask:NSDragOperationCopy|NSDragOperationMove forLocal:NO];
    [self updateColumns];

    SnapAppDelegate *appDelegate = (SnapAppDelegate *)[[NSApplication sharedApplication] delegate];
    NSMenu *menu = [appDelegate actionMenu];
    [resultsTableView setMenu:menu];
    
    [[[menu itemAtIndex:1] submenu] setDelegate:self];
//    [menu setDelegate:self];
    
    // status bar
    BOOL showStatusBar = [[NSUserDefaults standardUserDefaults] boolForKey:@"ShowStatusBar"];
    [self setStatusBarHidden:!showStatusBar];

    [self setObserveDefaults:YES];
}

- (void)updateColumns {
    for (NSString *attr in COLUMNS) {
        if ([[DEFAULTS objectForKey:attr] boolValue] && [resultsTableView tableColumnWithIdentifier:attr] == nil) {
            NSTableColumn *col = [[NSTableColumn alloc] initWithIdentifier:attr];
            [col setHeaderCell:[[NSTableHeaderCell alloc] initTextCell:attr]];
            [resultsTableView addTableColumn:col];
        }
    }
}

- (void)menuDidClose:(NSMenu *)menu {
    // UGH!
//    if (![[DEFAULTS objectforKey:@"ShowFileSize"] boolValue])
//        [resultsTableView removeTableColumn:[resultsTableView tableColumnWithIdentifier:@"Size"]];
//    if (![[DEFAULTS objectforKey:@"ShowKind"] boolValue])
//        [resultsTableView removeTableColumn:[resultsTableView tableColumnWithIdentifier:@"Kind"]];
//    if (![[DEFAULTS objectforKey:@"ShowUTI"] boolValue])
//        [resultsTableView removeTableColumn:[resultsTableView tableColumnWithIdentifier:@"UTI"]];
//    if (![[DEFAULTS objectforKey:@"ShowDateCreated"] boolValue])
//        [resultsTableView removeTableColumn:[resultsTableView tableColumnWithIdentifier:@"CreatedDate"]];
//    if (![[DEFAULTS objectforKey:@"ShowDateAccessed"] boolValue])
//        [resultsTableView removeTableColumn:[resultsTableView tableColumnWithIdentifier:@"AccessedDate"]];
//    if (![[DEFAULTS objectforKey:@"ShowDateModified"] boolValue])
//        [resultsTableView removeTableColumn:[resultsTableView tableColumnWithIdentifier:@"ModifiedDate"]];
//    if (![[DEFAULTS objectforKey:@"ShowFilePermissions"] boolValue])
//        [resultsTableView removeTableColumn:[resultsTableView tableColumnWithIdentifier:@"Permissions"]];
//    if (![[DEFAULTS objectforKey:@"ShowUserGroup"] boolValue])
//        [resultsTableView removeTableColumn:[resultsTableView tableColumnWithIdentifier:@"User:Group"]];
//    [self updateColumns];
}

- (IBAction)columnChanged:(id)sender {
    NSString *attr = [sender title];
    
    if (![sender state]) {
        [self addColumnForAttr:attr];
    } else {
        [self removeColumnForAttr:attr];
    }
}

- (void)addColumnForAttr:(NSString *)attr {
    if ([resultsTableView tableColumnWithIdentifier:attr] != nil) {
        return;
    }
    NSLog(@"Adding column %@", attr);
    NSTableColumn *col = [[NSTableColumn alloc] initWithIdentifier:attr];
    [col setHeaderCell:[[NSTableHeaderCell alloc] initTextCell:attr]];
    [resultsTableView addTableColumn:col];
}

- (void)removeColumnForAttr:(NSString *)attr {
    NSLog(@"Removing column %@", attr);
    [resultsTableView removeTableColumn:[resultsTableView tableColumnWithIdentifier:attr]];
}

- (IBAction)interfaceSizeSelected:(id)sender {
    
}
    
- (IBAction)filterFind:(id)sender {
    [DEFAULTS setBool:YES forKey:@"ShowStatusBar"];
    [self.window makeFirstResponder:filterTextField];
}

#pragma mark - Results 

- (void)addPaths:(NSArray *)paths {
    for (NSString *p in paths) {
        SnapItem *item = [SnapItem itemWithPath:p];
        [results addObject:item];
    }
    [self updateNumFiles];
    [resultsTableView noteNumberOfRowsChanged];
}

- (void)addPath:(NSString *)path {
    SnapItem *item = [SnapItem itemWithPath:path];

//    // file size
//    [dict setObject:[NSNumber numberWithUnsignedLongLong:statInfo.st_size] forKey:@"Size"];
//
//    // access date
//    [dict setObject:[NSNumber numberWithUnsignedLongLong:statInfo.st_atime] forKey:@"AccessDate"];
//    
//    // create date
//    [dict setObject:[NSNumber numberWithUnsignedLongLong:statInfo.st_birthtime] forKey:@"CreatedDate"];
//    
//    // modified date
//    [dict setObject:[NSNumber numberWithUnsignedLongLong:statInfo.st_mtime] forKey:@"ModifiedDate"];
    
    [results addObject:item];
    
    [self updateNumFiles];
    [resultsTableView noteNumberOfRowsChanged];
}

- (void)updateNumFiles {
    NSString *label = [NSString stringWithFormat:@"%lu items", (unsigned long)[results count]];
    [numResultsTextField setStringValue:label];
}

- (void)clear {
    [results removeAllObjects];
    [resultsTableView reloadData];
}

- (void)menuWillOpen:(NSMenu *)menu {
	// we do this lazily
//    NSIndexSet *indexSet = [self selectedItems];
//    NSString *path = [[results objectAtIndex:[indexSet firstIndex]] path];
    NSArray *items = [results objectsAtIndexes:[self selectedItems]];
    
    
    NSMenu *submenu = menu;
    [submenu removeAllItems];
    
    if ([items count] == 0) {
        [submenu addItemWithTitle:@"None" action:nil keyEquivalent:@""];
        [submenu addItem:[NSMenuItem separatorItem]];
        [submenu addItemWithTitle:@"Select…" action:nil keyEquivalent:@""];
        return;
    }
    
    //get default app for first file, and then separator
    NSArray *firstFileApps = [items[0] attr:@"HandlerApps"];
    if (!firstFileApps || ![firstFileApps count]) {
        [submenu addItemWithTitle:@"None" action:nil keyEquivalent:@""];
        [submenu addItem:[NSMenuItem separatorItem]];
        [submenu addItemWithTitle:@"Select…" action:@selector(selectAppOpenWith:) keyEquivalent:@""];
        return;
    }

    NSString *defaultAppPath = ([items count] > 1) ? nil : firstFileApps[0];
    if (defaultAppPath) {
        [submenu addItem:[self menuItemForApp:defaultAppPath default:YES]];
        [submenu addItem:[NSMenuItem separatorItem]];
    }
    
    // build up array of items
    NSMutableArray *apps = [NSMutableArray array];
    for (int i = 0; i < [items count]; i++) {
        //get all apps that open this file and append to apps
        NSArray *appsForFile = [items[i] attr:@"HandlerApps"];
        for (NSString *app in appsForFile) {
            if (![apps containsObject:app] && !(defaultAppPath && [app isEqualToString:defaultAppPath])) {
                [apps addObject:app];
            }
        }
    }
    
    if ([apps count] == 0) {
        return;
    }
    
    NSArray *sortedApps = [apps sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        return [[obj1 lastPathComponent] caseInsensitiveCompare:[obj2 lastPathComponent]];
    }];
    for (NSString *appPath in sortedApps) {
        [submenu addItem:[self menuItemForApp:appPath default:NO]];
    }
    
    [submenu addItem:[NSMenuItem separatorItem]];
    [submenu addItemWithTitle:@"Select…" action:@selector(selectAppOpenWith:) keyEquivalent:@""];
}

- (NSMenuItem *)menuItemForApp:(NSString *)appPath default:(BOOL)isDefault {
    NSString *name = [[NSFileManager defaultManager] displayNameAtPath:appPath];
    NSString *title = isDefault ? [NSString stringWithFormat:@"%@ (default)", name] : name;
    NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:name
                                                  action:@selector(openWithSender:)
                                           keyEquivalent:@""];
    NSImage *icon = [[NSWorkspace sharedWorkspace] iconForFile:appPath];
    [icon setSize:NSMakeSize(16,16)];
    [item setImage:icon];
    [item setTarget:self];
    [item setToolTip:appPath];
    
    return item;
}

#pragma mark - File functions

- (NSIndexSet *)selectedItems {
    NSIndexSet *sel = [resultsTableView selectedRowIndexes];
    if ([sel containsIndex:[resultsTableView clickedRow]]) {
        return sel;
    } else {
        return [NSIndexSet indexSetWithIndex:[resultsTableView clickedRow]];
    }
}

- (void)performSelector:(SEL)selector onIndexes:(NSIndexSet *)indexSet {
    [[resultsTableView selectedRowIndexes] enumerateIndexesUsingBlock:^(NSUInteger row, BOOL *stop){
         [results[row] performSelector:selector];
    }];
}

- (void)performSelector:(SEL)selector onIndexes:(NSIndexSet *)indexSet withObject:(id)obj {
    [[resultsTableView selectedRowIndexes] enumerateIndexesUsingBlock:^(NSUInteger row, BOOL *stop){
         [results[row] performSelector:selector withObject:obj];
    }];
}

- (void)open:(id)sender {
    BOOL commandKeyDown = (([[NSApp currentEvent] modifierFlags] & NSCommandKeyMask) == NSCommandKeyMask);
    if (commandKeyDown) {
        [self performSelector:@selector(showInFinder) onIndexes:[self selectedItems]];
    } else {
        [self performSelector:@selector(openInFinder) onIndexes:[self selectedItems]];
    }
}

-(IBAction)selectAppOpenWith:(id)sender {
    
}

- (IBAction)openWithSender:(id)sender {
    [self performSelector:@selector(openWithApplication:) onIndexes:[self selectedItems] withObject:[sender toolTip]];
}

- (IBAction)showInFinder:(id)sender {
    [self performSelector:@selector(showInFinder) onIndexes:[self selectedItems]];
}

- (IBAction)getInfo:(id)sender {
    [self performSelector:@selector(getInfo) onIndexes:[self selectedItems]];
}

- (IBAction)copyFile:(id)sender {
    NSIndexSet      *rowIndexes = [self selectedItems];
    NSMutableArray  *filenames = [NSMutableArray arrayWithCapacity:[rowIndexes count]];
    NSString        *str = @"";
    
	NSInteger index = [rowIndexes firstIndex];
	while (NSNotFound != index) {
        NSString *path = [results[index] path];
		[filenames addObject:path];
        str = [str stringByAppendingFormat:@"\'%@\' ", path, nil];
		index = [rowIndexes indexGreaterThanIndex:index];
	}
    
    [[NSPasteboard generalPasteboard] declareTypes:@[NSFilenamesPboardType, NSStringPboardType] owner:self];
    [[NSPasteboard generalPasteboard] setPropertyList:filenames forType:NSFilenamesPboardType];
    [[NSPasteboard generalPasteboard] setString:str forType:NSStringPboardType];
}

- (IBAction)quickLook:(id)sender {
    [self performSelector:@selector(quickLook) onIndexes:[self selectedItems]];
}

- (IBAction)setLabel:(id)sender {
    
}

- (IBAction)deleteFile:(id)sender {
    NSIndexSet *indexSet = [self selectedItems];
    for (NSUInteger i = [results count] -1; i > 0; i--) {
        if ([indexSet containsIndex:i]) {
            [results removeObjectAtIndex:i];
        }
    }
    [resultsTableView reloadData];
}

- (IBAction)moveToTrash:(id)sender {
    [self performSelector:@selector(moveToTrash) onIndexes:[self selectedItems]];
}

- (IBAction)openDirectoryInTerminal:(id)sender{
    
}

- (IBAction)runInTerminal:(id)sender{
    
}

#pragma mark - Key/value observation

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    
    if ([keyPath hasSuffix:@"ShowStatusBar"]) {
        [self setStatusBarHidden:![[NSUserDefaults standardUserDefaults] boolForKey:@"ShowStatusBar"]];
    }
}

- (void)setStatusBarHidden:(BOOL)hidden {
    if (hidden) {
        [statusBarView setHidden:YES];
        NSRect windowRect = [[self.window contentView] bounds];
        [scrollView setFrame:windowRect];
    } else {
        NSRect windowRect = [[self.window contentView] bounds];
        windowRect.origin.y = statusBarView.bounds.size.height;
        windowRect.size.height = windowRect.size.height - statusBarView.bounds.size.height;
        [scrollView setFrame:windowRect];
        [statusBarView setHidden:NO];

    }
}


- (void)setObserveDefaults:(BOOL)observeDefaults {
    NSArray *defaults = @[@"ShowStatusBar"];
    
    for (NSString *key in defaults) {
        if (observeDefaults) {
            [[NSUserDefaultsController sharedUserDefaultsController] addObserver:self
                                                                      forKeyPath:VALUES_KEYPATH(key)
                                                                         options:NSKeyValueObservingOptionNew
                                                                         context:NULL];
        } else {
            [[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self forKeyPath:VALUES_KEYPATH(key)];
        }
    }
}

#pragma mark - Table View

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification {
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView {
	return [results count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
    return [results[rowIndex] attr:[aTableColumn identifier]];
}

- (BOOL)tableView:(NSTableView *)tv writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard *)pboard {
	NSMutableArray *filenames = [NSMutableArray arrayWithCapacity:[rowIndexes count]];
	NSInteger index = [rowIndexes firstIndex];
	
	while (NSNotFound != index) {
		[filenames addObject:[results[index] attr:@"Path"]];
		index = [rowIndexes indexGreaterThanIndex:index];
	}
    
    [pboard declareTypes:@[NSFilenamesPboardType] owner:self];
    [pboard setPropertyList:filenames forType:NSFilenamesPboardType];
	
	return YES;
}

- (CGFloat)tableView:(NSTableView *)theTableView heightOfRow:(NSInteger)row {
    return 20;
}

@end
