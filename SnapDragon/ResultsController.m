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
    
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(taskFinished:)
                                                 name: NSTaskDidTerminateNotification
                                               object: NULL];
    [queryTextField setColorInvalidPath: NO];
}

#pragma mark - Results 

- (void)addPath: (NSString *)path
{
    NSMutableDictionary *item = [ResultItem itemWithPath: path];
    
    
    
    // get attributes
    
    
    // file size
//    [dict setObject: [NSNumber numberWithUnsignedLongLong: statInfo.st_size] forKey: @"Size"];
//    totalSize += statInfo.st_size;
//    
//    // access date
//    [dict setObject: [NSNumber numberWithUnsignedLongLong: statInfo.st_atime] forKey: @"AccessDate"];
//    
//    // create date
//    [dict setObject: [NSNumber numberWithUnsignedLongLong: statInfo.st_birthtime] forKey: @"CreatedDate"];
//    
//    // modified date
//    [dict setObject: [NSNumber numberWithUnsignedLongLong: statInfo.st_mtime] forKey: @"ModifiedDate"];
    
    [results addObject: item];
    
    if ([results count] % 10 == 0)
    {
        //NSLog([item description]);
        
        [resultsTableView noteNumberOfRowsChanged];
        [self updateNumFiles];
    }
}
     
     
- (void)updateNumFiles
{
    NSInteger lim = [[[NSUserDefaults standardUserDefaults] objectForKey: @"ResultLimit"] intValue];
    NSString *maxed = ([results count] >= lim) ? @"(hit limit)" : @"";
    NSString *label = [NSString stringWithFormat: @"%d files %@", [results count], maxed, nil];

    // append total size
    if (totalSize)
    {
        NSString *humanSizeStr = [[NSFileManager defaultManager] sizeAsHumanReadable: totalSize];
        label = [label stringByAppendingFormat: @" %@", humanSizeStr, nil];
    }
    
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
	NSString	*path = [[results objectAtIndex: index] path];
	
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
	[[NSWorkspace sharedWorkspace] openFile: [[results objectAtIndex: index] path]];
}

#pragma mark - Table View

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
	return [results count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{	
    return [[results objectAtIndex: rowIndex] attr: [aTableColumn identifier] ];
}

- (BOOL)tableView:(NSTableView *)tv writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard*)pboard 
{
	NSMutableArray *filenames = [NSMutableArray arrayWithCapacity: [rowIndexes count]];
	NSInteger index = [rowIndexes firstIndex];
	
	while (NSNotFound != index) 
	{
		[filenames addObject: [[results objectAtIndex: index] attr: @"Path"]];
		index = [rowIndexes indexGreaterThanIndex: index];
	}
    
    [pboard declareTypes: [NSArray arrayWithObjects: NSFilenamesPboardType, nil] owner: self];
    [pboard setPropertyList: filenames forType: NSFilenamesPboardType];
	
	return YES;
}

#pragma mark - Task

-(IBAction)locate: (id)sender
{
    if (isTaskRunning)
    {
        [self taskFinished: nil];
        return;
    }
    
    if ([[[NSUserDefaults standardUserDefaults] objectForKey: @"IgnoreEmptyQuery"] boolValue] &&
        [[queryTextField stringValue] isEqualToString: @""])
         return;
         
    [self clear];
    [self runLocate];
}

- (void)runLocate
{
    // construct arguments list
    NSMutableArray *args = [[[NSMutableArray alloc] initWithCapacity: 10] autorelease];
    
    // limit
    int lim = [[[NSUserDefaults standardUserDefaults] objectForKey: @"ResultLimit"] intValue];
    if (lim)
    {
        [args addObject: @"-l"];
        [args addObject: [NSString stringWithFormat: @"%d", lim]];
    }
    
    // ignore case
    if ([[[NSUserDefaults standardUserDefaults] objectForKey: @"IgnoreCase"] boolValue])
        [args addObject: @"-i"];
    
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
    totalSize = 0;
    isTaskRunning = YES;
    NSLog(@"Executing %@", [task fullDescription]);
    [task launch];
    
    [locateButton setTitle: @"Stop"];
    [progressIndicator setUsesThreadedAnimation: YES];
    [progressIndicator startAnimation: self];
    
    // we wait until task exits if this is for the menu
    //[task waitUntilExit];
}


//  read from the file handle and append it to the text window
- (void)getOutputData: (NSNotification *)aNotification
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
        [self updateNumFiles];
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
        
        if ([theLine hasPrefix: @"/"])
        {
            if ([[NSFileManager defaultManager] fileExistsAtPath: theLine])
            {
                [self addPath: theLine];
            }
        }
    }
    
    [outputString release];
}

// OK, called when we receive notification that task is finished
// Some cleaning up to do, controls need to be adjusted, etc.
-(void)taskFinished: (NSNotification *)aNotification
{        
    // if task already quit, we return    
    isTaskRunning = NO;

    // did we receive all the data?
    if (outputEmpty) // if no data left we do the clean up 
    {
        // We make sure to clear the filehandle of any remaining data
        if (readHandle != NULL)
        {
            NSData *data;
            while ((data = [readHandle availableData]) && [data length])
                [self appendOutput: data];
        }
    }
    
    // stop and dispose of task
    if (task != nil)
    {
        [task terminate];
        [task release];
        task = nil;
    }
    
    // update interface
    [progressIndicator stopAnimation: self];
    [locateButton setTitle: @"Locate"];
    [resultsTableView noteNumberOfRowsChanged];
    [self updateNumFiles];
}



@end
