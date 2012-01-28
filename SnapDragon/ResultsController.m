//
//  ResultsTableView.m
//
//  Created by Sveinbjorn Thordarson on 1/26/12.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#import "ResultsController.h"

@implementation ResultsController

- (id)init
{
    if ((self = [super init])) 
    {

    }
    
    return self;
}

- (void)dealloc
{
    [results release];
}

- (void)awakeFromNib
{
    results = [[NSMutableArray alloc] initWithCapacity: 100000];
    [resultsTableView setTarget: self];
	[resultsTableView setDoubleAction: @selector(open:)];
    [resultsTableView setDraggingSourceOperationMask: NSDragOperationCopy | NSDragOperationMove forLocal: NO];
}

#pragma mark - Results 

- (void)addPath: (NSString *)path
{
    NSImage *icon = [[NSWorkspace sharedWorkspace] iconForFile: path];
    [icon setSize: NSMakeSize(16,16)];
    
    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys: path, @"Path", icon, @"Icon", nil];
    [results addObject: dict];
    [resultsTableView reloadData];
    [resultsTableView reloadDataForRowIndexes: [NSIndexSet indexSetWithIndex:[results count] ] columnIndexes: [NSIndexSet indexSetWithIndexesInRange: NSMakeRange(0, 10)]];
    
    [self updateNumFiles];
}
     
     
- (void)updateNumFiles
{
    NSInteger lim = [[[NSUserDefaults standardUserDefaults] objectForKey: @"ResultLimit"] intValue];
    NSString *maxed = ([results count] >= lim) ? @"(!limit)" : @"";
    NSString *label = [NSString stringWithFormat: @"%d files %@", [results count], maxed];
    [numResultsTextField setStringValue: label];
}

- (void)clear
{
    [results removeAllObjects];
    [resultsTableView reloadData];
}

#pragma mark - File functions

- (void)open: (id)sender
{
	if ([resultsTableView clickedRow] == -1)
		return;
	
	if(GetCurrentKeyModifiers() & cmdKey)
		[self showInFinder: [resultsTableView clickedRow]];
	else
		[self openInFinder: [resultsTableView clickedRow]];
}

- (void)showInFinder: (NSInteger)index
{
	BOOL		isDir;
	NSString	*path = [[results objectAtIndex: index] objectForKey: @"Path"];
	
	if ([[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir]) 
	{
        if (isDir)
            [[NSWorkspace sharedWorkspace] selectFile:nil inFileViewerRootedAtPath:path];
        else
            [[NSWorkspace sharedWorkspace] selectFile:path inFileViewerRootedAtPath:nil];
	}
}

- (void)openInFinder: (NSInteger)index
{	
	[[NSWorkspace sharedWorkspace] openFile: [[results objectAtIndex: index] objectForKey: @"Path"]];
}

#pragma mark - Table View

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
}

- (NSUInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
	return [results count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{	
	if ([[aTableColumn identifier] caseInsensitiveCompare: @"2"] == NSOrderedSame)//path
	{
		// check if bundled file still exists at path
        return([[results objectAtIndex: rowIndex] objectForKey: @"Path"]);
	}
	else if ([[aTableColumn identifier] caseInsensitiveCompare: @"1"] == NSOrderedSame)//icon
	{
        return [[results objectAtIndex: rowIndex] objectForKey: @"Icon"];
	}
	
	return(@"");
}

- (BOOL)tableView:(NSTableView *)tv writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard*)pboard 
{
    pboard = [NSPasteboard pasteboardWithName:NSDragPboard];
	NSMutableArray *filenames = [NSMutableArray arrayWithCapacity: [rowIndexes count]];
	NSInteger index = [rowIndexes firstIndex];
	
	while (NSNotFound != index) 
	{
		[filenames addObject: [[results objectAtIndex: index] objectForKey: @"Path"]];
		index = [rowIndexes indexGreaterThanIndex: index];
	}
    
    [pboard declareTypes: [NSArray arrayWithObjects: NSFilenamesPboardType, nil] owner: self];
    [pboard setPropertyList: filenames forType: NSFilenamesPboardType];
	
	return YES;
}

#pragma mark - Task

-(IBAction)locate: (id)sender
{
    [self clear];
    [self runLocate];
}

- (void)runLocate
{
    NSMutableArray *args = [[NSMutableArray alloc] initWithCapacity: 10];
    
    // limit
    int lim = [[[NSUserDefaults standardUserDefaults] objectForKey: @"ResultLimit"] intValue];
    if (lim)
    {
        [args addObject: @"-l"];
        [args addObject: [NSString stringWithFormat: @"%d", lim]];
    } 
    
    //initalize task
    task = [[NSTask alloc] init];
    
    //apply settings for task
    [task setLaunchPath: [[NSUserDefaults standardUserDefaults] objectForKey: @"ToolPath"]];
    [args addObject: [queryTextField stringValue]];
    [task setArguments: args];
    
    // set output to file handle and start monitoring it if script provides feedback
    outputPipe = [NSPipe pipe];
    [task setStandardOutput: outputPipe];
    readHandle = [outputPipe fileHandleForReading];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(getOutputData:) name: NSFileHandleReadCompletionNotification object:readHandle];
    [readHandle readInBackgroundAndNotify];
    
    //set it off
    [task launch];
    
    // we wait until task exits if this is for the menu
    //[task waitUntilExit];
}


//  read from the file handle and append it to the text window
-(void) getOutputData: (NSNotification *)aNotification
{
    //get the data from notification
    NSData *data = [[aNotification userInfo] objectForKey: NSFileHandleNotificationDataItem];
    
    //make sure there's actual data
    if ([data length]) 
    {
        outputEmpty = NO;
        
        //append the output to the text field        
        [self appendOutput: data];
        
        // we schedule the file handle to go and read more data in the background again.
        [[aNotification object] readInBackgroundAndNotify];
    }
    else
    {
        outputEmpty = YES;
    }
}

//
-(void)appendOutput: (NSData *)data
{    
    // we decode the script output according to specified character encoding
    NSMutableString *outputString = [[NSMutableString alloc] initWithData: data encoding: NSUTF8StringEncoding];
    
    if (!outputString)
        return;
    
    if (remnants != NULL && [remnants length] > 0)
        [outputString insertString: remnants atIndex: 0];
    
    // parse the data just dumped out
    NSMutableArray *lines = [NSMutableArray arrayWithArray: [outputString componentsSeparatedByString: @"\n"]];
    
    // if the line did not end with a newline, it wasn't a complete line of output
    // Thus, we store the last line and then delete it from the outputstring
    // It'll be appended next time we get output
    if ([(NSString *)[lines lastObject] length] > 0)
    {
        if (remnants != NULL) { [remnants release]; remnants = NULL; }
        remnants = [[NSString alloc] initWithString: [lines lastObject]];
        [outputString deleteCharactersInRange: NSMakeRange([outputString length]-[remnants length], [remnants length])];
    }
    else
        remnants = NULL;
    
    [lines removeLastObject];
    
    int i;
    for (i = 0; i < [lines count]; i++)
    {
        NSString *theLine = [lines objectAtIndex: i];
        
        // if the line is empty, we ignore it
        if ([theLine length] == 0)
            continue;
        
        // lines starting with PROGRESS:\d+ are interpreted as percentage to set progress bar at
        if ([theLine hasPrefix: @"/"])
        {
            if ([[NSFileManager defaultManager] fileExistsAtPath: theLine])
            {
                [self addPath: theLine];
                //[resultsTableView reloadData];
            }
        }
    }
    
    [outputString release];
}



@end
