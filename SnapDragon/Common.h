//
//  Common.h
//  SnapDragon
//
//  Created by Sveinbjorn Thordarson on 1/29/12.
//  Copyright 2012 Sveinbjorn Thordarson. All rights reserved.
//

// paths
#define SNAP_TMP_DIR                        @"/tmp/"
#define TMP_FILE_BASENAME                   @"snap_tmp_file"
#define TMP_SCRIPT_TEMPLATE					[NSString stringWithFormat: @"%@.XXXXXX", TMP_FILE_BASENAME, nil]


// code abbrev.
#define DEFAULTS    [NSUserDefaults standardUserDefaults]
#define FILEMGR     [NSFileManager defaultManager]
