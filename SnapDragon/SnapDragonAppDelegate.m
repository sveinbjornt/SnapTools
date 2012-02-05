//
//  MacLocateAppDelegate.m
//  MacLocate
//
//  Created by Sveinbjorn Thordarson on 1/25/12.
//  Copyright 2012 Sveinbjorn Thordarson. All rights reserved.
//

#import "SnapDragonAppDelegate.h"

@implementation SnapDragonAppDelegate

+ (void)initialize 
{ 
	NSDictionary *registrationDefaults = [NSDictionary dictionaryWithContentsOfFile: 
										  [[NSBundle mainBundle] pathForResource: @"Defaults" ofType: @"plist"]];
    [DEFAULTS registerDefaults: registrationDefaults];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{

}

-(void)application: (NSApplication *)theApplication openFiles: (NSArray *)filenames
{
    NSLog(@"HAndler");
    NSString *firstPath = [filenames objectAtIndex: 0];
    [resultsController clear];
    
    if ([[firstPath lastPathComponent] hasPrefix: TMP_FILE_BASENAME])
    {
        NSLog(@"Opening snap file");
        NSString *fileStr = [NSString stringWithContentsOfFile: firstPath encoding: NSUTF8StringEncoding error: nil];
        if (!fileStr)
            NSLog(@"Error reading snap file");
        
        for (NSString *path in [fileStr componentsSeparatedByString: @"\n"])
        {
            if ([[NSFileManager defaultManager] fileExistsAtPath: path])
                [resultsController addPath: path];
        }
        return;
    }
    else
    {
        NSLog(@"Opening paths");
        for (NSString *path in filenames)
        {
            NSLog(path);
            [resultsController addPath: path];
        }
    }
}


@end
