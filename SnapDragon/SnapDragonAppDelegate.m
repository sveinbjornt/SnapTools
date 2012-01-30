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

@end
