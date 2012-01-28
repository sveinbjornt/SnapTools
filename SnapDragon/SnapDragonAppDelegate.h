//
//  SnapDragonAppDelegate.h
//  SnapDragon
//
//  Created by Sveinbjorn Thordarson on 1/28/12.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface SnapDragonAppDelegate : NSObject <NSApplicationDelegate> {
    NSWindow *window;
}

@property (assign) IBOutlet NSWindow *window;

@end
