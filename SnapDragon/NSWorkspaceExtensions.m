//
//  NSWorkspaceExtensions.m
//  MenuSmith
//
//  Created by Sveinbjorn Thordarson on 9/26/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "NSWorkspaceExtensions.h"


@implementation NSWorkspace (MSExtensions)

#pragma mark Application(s) for files

- (NSArray *)applicationsForFile:(NSString *)filePath 
{
	NSURL *url = [NSURL fileURLWithPath: filePath];
	NSMutableArray *appPaths = [[NSMutableArray alloc] initWithCapacity: 256];
	
	NSArray *applications = (NSArray *)LSCopyApplicationURLsForURL((CFURLRef)url, kLSRolesAll);
	if (applications == NULL)
		return [NSArray array];
	
	[applications autorelease];
	
	int i;
	for (i = 0; i < [applications count]; i++)
	{
		[appPaths addObject: [[applications objectAtIndex: i] path]];
	}
	return [appPaths autorelease];
}


- (NSString *)defaultApplicationForFile: (NSString *)filePath
{
	FSRef fileRef;
	NSURL *appURL;
	
	if (![filePath getFSRef:&fileRef createFileIfNecessary: NO])
		return nil;
	
	// use Launch Services function to get default app
	OSStatus ret = LSGetApplicationForItem(&fileRef, kLSRolesAll, NULL, (CFURLRef *)&appURL);
	
	if (ret != noErr || appURL == nil)
		return nil;
	
	return [appURL path];
}

#pragma mark Labels

- (void)setLabel:(NSUInteger)label forFile:(NSString *)filePath;
{
    if (label > 7)
	{
		NSLog(@"Error setting label %d. Finder label must be in range 0-7", label);
		return;
	}
	
	FSRef fileRef;
	if(![filePath getFSRef: &fileRef createFileIfNecessary: NO])
		return;
	
	FSCatalogInfo catalogInfo;    
	OSStatus err = FSGetCatalogInfo(&fileRef, kFSCatInfoNodeFlags | kFSCatInfoFinderInfo, &catalogInfo, NULL, NULL, NULL);
	
	if (err != noErr) 
		return;
	
	label = (label << 1L);
		
	// coerce to FolderInfo or FileInfo as needed and set the color bit
	if ((catalogInfo.nodeFlags & kFSNodeIsDirectoryMask) != 0) 
	{
		FolderInfo *fInfo = (FolderInfo *)&catalogInfo.finderInfo;
		fInfo->finderFlags &= ~kColor;
		fInfo->finderFlags |= (label & kColor);
	}
	else 
	{
		FileInfo *fInfo = (FileInfo *)&catalogInfo.finderInfo;
		fInfo->finderFlags &= ~kColor;
		fInfo->finderFlags |= (label & kColor);
	}
	
	FSSetCatalogInfo(&fileRef, kFSCatInfoFinderInfo, &catalogInfo);
}


- (int)labelNumberForFile: (NSString *)path
{
	NSUInteger label;
	FSRef fileRef;
	FSCatalogInfo catalogInfo;
	[path getFSRef: &fileRef createFileIfNecessary: NO];
	
	/* retrieve filespec from file ref */
	OSStatus err = FSGetCatalogInfo(&fileRef, kFSCatInfoNodeFlags | kFSCatInfoFinderInfo, &catalogInfo, NULL, NULL, NULL);
	if (err != noErr) 
	{
		fprintf(stderr, "FSGetCatalogInfo(): Error %d getting file catalog info", err);
		return 0;
	}
	
	// coerce to FolderInfo or FileInfo as needed and get the color bit
	if ((catalogInfo.nodeFlags & kFSNodeIsDirectoryMask) != 0) 
	{
		FolderInfo *fInfo = (FolderInfo *)&catalogInfo.finderInfo;
		label = fInfo->finderFlags & kColor;
	}
	else 
	{
		FileInfo *fInfo = (FileInfo *)&catalogInfo.finderInfo;
		label = fInfo->finderFlags & kColor;
	}
	
	return (label >> 1L);
}

- (NSString *)labelNameForFile: (NSString *)path
{
	int labelNum = [self labelNumberForFile: path];
	if (labelNum == 0)
		return nil;
	return [[self fileLabels] objectAtIndex: labelNum];
}

- (NSColor *)labelColorForFile: (NSString *)path
{
	int labelNum = [self labelNumberForFile: path];
	if (labelNum == 0)
		return nil;
	return [[self fileLabelColors] objectAtIndex: labelNum];
}

@end
