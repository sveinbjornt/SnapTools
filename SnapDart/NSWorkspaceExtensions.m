/*
 Copyright (c) 2010-2017, Sveinbjorn Thordarson <sveinbjornt@gmail.com>
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

#import "NSWorkspaceExtensions.h"

@implementation NSWorkspace (SDExtensions)

#pragma mark - Application that handle files

- (NSArray *)applicationsForFile:(NSString *)filePath {
	NSURL *url = [NSURL fileURLWithPath:filePath];
	NSMutableArray *appPaths = [[NSMutableArray alloc] initWithCapacity:256];
	
	NSArray *applications = (NSArray *)CFBridgingRelease(LSCopyApplicationURLsForURL((__bridge CFURLRef)url, kLSRolesAll));
    if (applications == nil) {
		return @[];
    }
    
	for (int i = 0; i < [applications count]; i++) {
		[appPaths addObject:[applications[i] path]];
	}
	return appPaths;
}

- (NSString *)defaultApplicationForFile:(NSString *)filePath {
	FSRef fileRef;
	CFURLRef appURL;
	
	if (![filePath getFSRef:&fileRef createFileIfNecessary:NO]) {
		return nil;
	}

	// use Launch Services function to get default app
	OSStatus ret = LSGetApplicationForItem(&fileRef, kLSRolesAll, NULL, &appURL);
	
	if (ret != noErr || appURL == NULL) {
		return nil;
	}
	return [(__bridge NSURL *)appURL path];
}

#pragma mark - Labels

- (BOOL)setLabel:(NSUInteger)label forFile:(NSString *)filePath {
    if (label > 7) {
		NSLog(@"Error setting label %lu. Finder label must be in range 0-7", (unsigned long)label);
		return NO;
	}

    NSURL *fileURL = [NSURL fileURLWithPath:filePath];
    NSError *error = nil;
    if (![fileURL setResourceValue:@(label) forKey:NSURLLabelNumberKey error:&error]) {
        NSLog(@"Error setting label: %@", [error localizedDescription]);
        return NO;
    }
    return YES;
}

- (int)labelNumberForFile:(NSString *)path {
    NSURL *fileURL = [NSURL fileURLWithPath:path];
    id labelValue = nil;
    NSError *error;
    
    if (![fileURL getResourceValue:&labelValue forKey:NSURLLabelNumberKey error:&error]) {
        NSLog(@"An error occurred: %@", [error localizedDescription]);
        return -1;
    }
    
    return [labelValue intValue];
}

- (NSString *)labelNameForFile:(NSString *)path {
	int labelNum = [self labelNumberForFile:path];
    if (labelNum == 0) {
		return nil;
    }
	return [self fileLabels][labelNum];
}

- (NSColor *)labelColorForFile:(NSString *)path {
	int labelNum = [self labelNumberForFile:path];
    if (labelNum == -1) {
		return nil;
    }
	return [self fileLabelColors][labelNum];
}

@end
