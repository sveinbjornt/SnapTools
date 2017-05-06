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

#import <AppKit/AppKit.h>
#import <Carbon/Carbon.h>
#import <sys/stat.h>

#import "ResultsController.h"

#import "Common.h"
#import "ResultItem.h"
#import "NSFileManager+FileOrFolderSize.h"
#import "NSWorkspaceExtensions.h"

#define COLUMNS @[@"Icon", @"Path", @"File Size", @"Kind", @"Date Modified", @"Date Created", @"Date Accessed", @"User:Group", @"Permission", @"UTI"]

@interface ResultsController ()
{
    NSMutableArray  *results;
    
    IBOutlet id     resultsTableView;
    IBOutlet id     window;
    IBOutlet id     contextualMenu;
    IBOutlet id     openWithMenuItem;
    IBOutlet id     labelMenuItem;
    IBOutlet id     progressIndicator;
    IBOutlet id     locateButton;
    IBOutlet id     queryTextField;
    IBOutlet id     filterTextField;
    IBOutlet id     numResultsTextField;
    IBOutlet id     tableColumnContextualMenu;
    
    NSTask          *task;
    NSTimer         *checkStatusTimer;
    NSPipe          *outputPipe;
    NSFileHandle    *readHandle;
    BOOL            isTaskRunning;
    BOOL            outputEmpty;
    NSString        *remnants;
    UInt64          totalSize;
}

@property (nonatomic, readonly, copy) NSIndexSet *selectedItems;

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
- (void)appendOutput:(NSData *)data;
- (void)getOutputData:(NSNotification *)aNotification;

@end

@implementation ResultsController

- (instancetype)init {
    if ((self = [super init])) {
        results = [NSMutableArray array];
    }
    return self;
}

- (void)awakeFromNib {
    [resultsTableView setTarget:self];
	[resultsTableView setDoubleAction:@selector(open:)];
    [resultsTableView setDraggingSourceOperationMask:NSDragOperationCopy|NSDragOperationMove forLocal:NO];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(taskFinished:)
                                                 name:NSTaskDidTerminateNotification
                                               object:nil];
    [self updateColumns];
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

#pragma mark - Results 

- (void)addPath:(NSString *)path {
    ResultItem *item = [ResultItem itemWithPath:path];
    if ([[DEFAULTS objectForKey:@"ExcludeFolders"] boolValue] && item.isDirectory) {
        return;
    }
    
    // get attributes
    
    
    // file size
//    [dict setObject:[NSNumber numberWithUnsignedLongLong:statInfo.st_size] forKey:@"Size"];
//    totalSize += statInfo.st_size;
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
    NSInteger lim = [[DEFAULTS objectForKey:@"ResultLimit"] intValue];
    NSString *maxed = ([results count] >= lim) ? @"(hit limit)" : @"";
    NSString *label = [NSString stringWithFormat:@"%lu items %@", (unsigned long)[results count], maxed, nil];

    // append total size
    if (totalSize) {
        NSString *humanSizeStr = [FILEMGR sizeAsHumanReadable:totalSize];
        label = [label stringByAppendingFormat:@" %@", humanSizeStr, nil];
    }
    
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
    NSArray *selectedItems = [results objectsAtIndexes:[self selectedItems]];
    
    [openWithMenuItem setSubmenu:[self openWithMenuForItems:selectedItems]];
}

- (NSMenuItem *)menuItemForApp:(NSString *)path {
    NSString *title = [[NSFileManager defaultManager] displayNameAtPath:path];
    NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:title action:@selector(openWithSender:) keyEquivalent:@""];
    NSImage *icon = [[NSWorkspace sharedWorkspace] iconForFile:path];
    [icon setSize:NSMakeSize(16,16)];
    [item setImage:icon];
    [item setTarget:self];
    return item;
}

- (NSMenu *)openWithMenuForItems:(NSArray *)items {
	NSMenu *submenu = [[NSMenu alloc] initWithTitle:@"Open With"];
    if (![items count]) {
        [submenu addItemWithTitle:@"None" action:nil keyEquivalent:@""];
        [submenu addItem:[NSMenuItem separatorItem]];
        [submenu addItemWithTitle:@"Select..." action:nil keyEquivalent:@""];
        return submenu;
    }
    
    //get default app for first file, and then separator
    NSArray *firstFileApps = [items[0] attr:@"HandlerApps"];
    if (!firstFileApps || ![firstFileApps count]) {
        [submenu addItemWithTitle:@"None" action:nil keyEquivalent:@""];
        [submenu addItem:[NSMenuItem separatorItem]];
        [submenu addItemWithTitle:@"Select..." action:nil keyEquivalent:@""];
        return submenu;
    }
    
    NSString *defaultAppPath = ([items count] > 1) ? nil : firstFileApps[0];
    if (defaultAppPath) {
        [submenu addItem:[self menuItemForApp:defaultAppPath]];
        [submenu addItem:[NSMenuItem separatorItem]];
    }
    
    // build up array of items
    NSMutableArray *apps = [NSMutableArray arrayWithCapacity:255];
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
        [submenu addItemWithTitle:@"None" action:nil keyEquivalent:@""];
    } else {
        for (NSString *appPath in [apps sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)])
            [submenu addItem:[self menuItemForApp:appPath]];
    }
    
    [submenu addItem:[NSMenuItem separatorItem]];
    [submenu addItemWithTitle:@"Select..." action:nil keyEquivalent:@""];
    return submenu;
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

-(IBAction)openWithSender:(id)sender {
    [self performSelector:@selector(openWithApplication:) onIndexes:[self selectedItems] withObject:[sender title]];
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

#pragma mark - Table View

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification {
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView {
	return [results count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
    return [results[rowIndex] attr:[aTableColumn identifier] ];
}

- (BOOL)tableView:(NSTableView *)tv writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard*)pboard {
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

#pragma mark - Task

- (void)runLocate {
    // construct arguments list
    NSMutableArray *args = [[NSMutableArray alloc] initWithCapacity:10];
    
    // limit
    int lim = [[DEFAULTS objectForKey:@"ResultLimit"] intValue];
    if (lim) {
        [args addObject:@"-l"];
        [args addObject:[NSString stringWithFormat:@"%d", lim]];
    }
    
    //initalize task
    task = [[NSTask alloc] init];
    
    //apply settings for task
    [task setLaunchPath:[DEFAULTS objectForKey:@"ToolPath"]];
    [args addObject:[queryTextField stringValue]];
    [task setArguments:args];
    
    // set output to file handle and start monitoring it if script provides feedback
    outputPipe = [NSPipe pipe];
    [task setStandardOutput:outputPipe];
    readHandle = [outputPipe fileHandleForReading];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(getOutputData:) name:NSFileHandleReadCompletionNotification object:readHandle];
    [readHandle readInBackgroundAndNotify];
    
    //set it off
    totalSize = 0;
    isTaskRunning = YES;
    NSLog(@"Executing %@", [task description]);
    [task launch];
    
    [locateButton setTitle:@"Stop"];
    [progressIndicator setUsesThreadedAnimation:YES];
    [progressIndicator startAnimation:self];
    
    // we wait until task exits if this is for the menu
    //[task waitUntilExit];
}


//  read from the file handle and append it to the text window
- (void)getOutputData:(NSNotification *)aNotification {
    //get the data from notification
    NSData *data = [aNotification userInfo][NSFileHandleNotificationDataItem];
    
    //make sure there's actual data
    if ([data length]) {
        outputEmpty = NO;
        
        //append the output to the text field        
        [self appendOutput:data];
        
        // we schedule the file handle to go and read more data in the background again.
        [[aNotification object] readInBackgroundAndNotify];
    } else {
        outputEmpty = YES;
        [self updateNumFiles];
    }
}

- (void)appendOutput:(NSData *)data {
    // we decode the script output according to specified character encoding
    NSMutableString *outputString = [[NSMutableString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    if (!outputString) {
        return;
    }
    if (remnants != NULL && [remnants length] > 0) {
        [outputString insertString:remnants atIndex:0];
    }
    
    // parse the data just dumped out
    NSMutableArray *lines = [NSMutableArray arrayWithArray:[outputString componentsSeparatedByString:@"\n"]];
    
    // if the line did not end with a newline, it wasn't a complete line of output
    // Thus, we store the last line and then delete it from the outputstring
    // It'll be appended next time we get output
    if ([(NSString *)[lines lastObject] length] > 0) {
        if (remnants != NULL) {  remnants = NULL; }
        remnants = [[NSString alloc] initWithString:[lines lastObject]];
        [outputString deleteCharactersInRange:NSMakeRange([outputString length]-[remnants length], [remnants length])];
    } else {
        remnants = NULL;
    }
    [lines removeLastObject];
    
    for (int i = 0; i < [lines count]; i++) {
        NSString *theLine = lines[i];
        
        // if the line is empty, we ignore it
        if ([theLine length] == 0) {
            continue;
        }
        
        if ([theLine hasPrefix:@"/"]) {
            if ([FILEMGR fileExistsAtPath:theLine]) {
                [self addPath:theLine];
            }
        }
    }
    
}

// OK, called when we receive notification that task is finished
// Some cleaning up to do, controls need to be adjusted, etc.
- (void)taskFinished:(NSNotification *)aNotification {
    if (aNotification != nil && [aNotification object] != task) {
        return;
    }
    
    // if task already quit, we return    
    isTaskRunning = NO;

    // did we receive all the data?
    if (outputEmpty) {
        // We make sure to clear the filehandle of any remaining data
        if (readHandle != nil) {
            NSData *data;
            while ((data = [readHandle availableData]) && [data length]) {
                [self appendOutput:data];
            }
        }
    }
    
    // stop and dispose of task
    if (task != nil) {
        [task terminate];
        task = nil;
    }
    
    // update interface
    [progressIndicator stopAnimation:self];
    [locateButton setTitle:@"Locate"];
    [resultsTableView noteNumberOfRowsChanged];
    [self updateNumFiles];
}

@end
