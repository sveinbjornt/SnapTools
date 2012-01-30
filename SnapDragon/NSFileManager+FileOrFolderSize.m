//
//  NSTask+Description.m
//  SnapDragon
//
//  Created by Sveinbjorn Thordarson on 1/28/12.
//  Copyright 2012 Sveinbjorn Thordarson. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSFileManager (FileOrFolderSize)
- (UInt64) fileOrFolderSize: (NSString *)path;
- (NSString *) fileOrFolderSizeAsHumanReadable: (NSString *)path;
- (NSString *) sizeAsHumanReadable: (UInt64)size;
- (BOOL) isFolder: (NSString *)path;
@end

@implementation NSFileManager (Description)

- (UInt64) fileOrFolderSize: (NSString *)path
{
	UInt64			size = 0;
	BOOL			isDir;
	
	if (path == nil || ![self fileExistsAtPath: path isDirectory: &isDir])
		return size;
	
	if (isDir)
	{
		NSDirectoryEnumerator *dirEnumerator = [self enumeratorAtPath: path];
		while ([dirEnumerator nextObject])
			if ([NSFileTypeRegular isEqualToString:[[dirEnumerator fileAttributes] fileType]])
				size += [[dirEnumerator fileAttributes] fileSize];
	}
	else
		size = [[self fileAttributesAtPath: path traverseLink:YES] fileSize];
    
	return size;
}

- (NSString *) fileOrFolderSizeAsHumanReadable: (NSString *)path
{
	return [self sizeAsHumanReadable: [self fileOrFolderSize: path]];
}

- (NSString *) sizeAsHumanReadable: (UInt64)size
{
	NSString	*str;
	
	if (size < 1024ULL) 
		str = [NSString stringWithFormat:@"%u bytes", (unsigned int)size];
	else if (size < 1048576ULL) 
		str = [NSString stringWithFormat:@"%d KB", (long)size/1024];
	else if (size < 1073741824ULL) 
		str = [NSString stringWithFormat:@"%.1f MB", size / 1048576.0];
	else 
		str = [NSString stringWithFormat:@"%.1f GB", size / 1073741824.0];
    
	return str;
}


- (BOOL) isFolder: (NSString *)path
{
    BOOL isDir = NO;
    [self fileExistsAtPath: path isDirectory: &isDir];
    return isDir;
}

@end