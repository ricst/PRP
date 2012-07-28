//
//  SQLiteMgr.h
//  PRP
//
//  Created by Steinberger Richard on 7/17/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

// Based on source code from here: https://github.com/misato/SQLiteManager4iOS

#import <Foundation/Foundation.h>
#import "sqlite3.h"

enum errorCodes {
	kDBNotExists,
	kDBFailAtOpen, 
	kDBFailAtCreate,
	kDBErrorQuery,
	kDBFailAtClose
};

@interface SQLiteMgr : NSObject {
    
	//sqlite3 *db; // The SQLite db reference
}

@property (nonatomic) sqlite3 *db;
@property (nonatomic, strong) NSURL *dbURL;
@property (nonatomic, copy) NSString *dbTablename;

- (id)initDatabaseWithURL:(NSURL *)url andTablename:(NSString *)tablename; 

// SQLite Operations
- (NSError *) openDatabase;
- (NSError *) doQuery:(NSString *)sql;
- (NSArray *) getRowsForQuery:(NSString *)sql;
- (NSString *) getDatabaseDump;
- (NSError *) closeDatabase;

@end
