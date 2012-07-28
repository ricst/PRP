//
//  SQLiteMgr.m
//  PRP
//
//  Created by Steinberger Richard on 7/17/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SQLiteMgr.h"

// Private methods
@interface SQLiteMgr (Private)

- (NSError *)createDBErrorWithDescription:(NSString*)description andCode:(int)code;

@end

@implementation SQLiteMgr

@synthesize db = _db;
@synthesize dbURL = _dbURL;
@synthesize dbTablename = _dbTablename;

#pragma mark Init & Dealloc

/**
 * Init method. 
 * Use this method to initialise the object.  Call before calling openDatabase.
 *
 * set the property values, dbURL and dbTablename.
 * Note: User has to decide where the db is stored, or will be created. 
 *
 * return the SQLiteManager object initialised.
 */

- (id)initDatabaseWithURL:(NSURL *)url andTablename:(NSString *)tablename 
{
	self = [super init];
	if (self != nil) {
		self.dbURL = url;
		self.dbTablename = tablename;
	}
	return self;	
}

/**
 * Dealloc method.
 */

- (void)dealloc {
	if (self.db != nil) {
		[self closeDatabase];
	}
}

#pragma mark SQLite Operations

/**
 * Open or create a SQLite3 database.
 *
 * If the db exists, then is opened and ready to use. If not exists then is created and opened.
 *
 * @return nil if everything was ok, an NSError in other case.
 *
 */

- (NSError *)openDatabase {
	
	NSError *error = nil;
    
	const char *dbpath = [[self.dbURL path] UTF8String];
	int result = sqlite3_open(dbpath, &self->_db);
	if (result != SQLITE_OK) {
        const char *errorMsg = sqlite3_errmsg(self.db);
        NSString *errorStr = [NSString stringWithFormat:@"The database could not be opened: %@",[NSString stringWithCString:errorMsg encoding:NSUTF8StringEncoding]];
        error = [self createDBErrorWithDescription:errorStr	andCode:kDBFailAtOpen];
	}
	
	return error;
}

/**
 * Does an SQL query. 
 *
 * You should use this method for everything but SELECT statements.
 *
 * @param sql the sql statement.
 *
 * @return nil if everything was ok, NSError in other case.
 */

- (NSError *)doQuery:(NSString *)sql {
	
	NSError *openError = nil;
	NSError *errorQuery = nil;
	
	//Check if database is open and ready.
	if (self.db == nil) {
		openError = [self openDatabase];
	}
	
	if (openError == nil) {		
		sqlite3_stmt *statement;	
		const char *query = [sql UTF8String];
		sqlite3_prepare_v2(self.db, query, -1, &statement, NULL);
		
		if (sqlite3_step(statement) == SQLITE_ERROR) {
			const char *errorMsg = sqlite3_errmsg(self.db);
			errorQuery = [self createDBErrorWithDescription:[NSString stringWithCString:errorMsg encoding:NSUTF8StringEncoding]
													andCode:kDBErrorQuery];
		}
		sqlite3_finalize(statement);
		errorQuery = [self closeDatabase];
	}
	else {
		errorQuery = openError;
	}
    
	return errorQuery;
}

/**
 * Does a SELECT query and gets the info from the db.
 *
 * The return array contains an NSDictionary for row, made as: key=columName value= columnValue.
 *
 * For example, if we have a table named "users" containing:
 * name | pass
 * -------------
 * admin| 1234
 * pepe | 5678
 * 
 * it will return an array with 2 objects:
 * resultingArray[0] = name=admin, pass=1234;
 * resultingArray[1] = name=pepe, pass=5678;
 * 
 * So to get the admin password:
 * [[resultingArray objectAtIndex:0] objectForKey:@"pass"];
 *
 * @param sql the sql query (remember to use only a SELECT statement!).
 * 
 * @return an array containing the rows fetched.
 */

- (NSArray *)getRowsForQuery:(NSString *)sql {
	
	NSMutableArray *resultsArray = [[NSMutableArray alloc] initWithCapacity:1];
	
	if (self.db == nil) {
		[self openDatabase];
	}
	
	sqlite3_stmt *statement;	
	const char *query = [sql UTF8String];
	int returnCode = sqlite3_prepare_v2(self.db, query, -1, &statement, NULL);
	
	if (returnCode == SQLITE_ERROR) {
		const char *errorMsg = sqlite3_errmsg(self.db);
		NSError *errorQuery = [self createDBErrorWithDescription:[NSString stringWithCString:errorMsg encoding:NSUTF8StringEncoding]
                                                         andCode:kDBErrorQuery];
		NSLog(@"%@", errorQuery);
	}
	
	while (sqlite3_step(statement) == SQLITE_ROW) {
		int columns = sqlite3_column_count(statement);
		NSMutableDictionary *result = [[NSMutableDictionary alloc] initWithCapacity:columns];
        
		for (int i = 0; i<columns; i++) {
			const char *name = sqlite3_column_name(statement, i);	
            
			NSString *columnName = [NSString stringWithCString:name encoding:NSUTF8StringEncoding];
			
			int type = sqlite3_column_type(statement, i);
			
			switch (type) {
				case SQLITE_INTEGER:
				{
					int value = sqlite3_column_int(statement, i);
					[result setObject:[NSNumber numberWithInt:value] forKey:columnName];
					break;
				}
				case SQLITE_FLOAT:
				{
					float value = sqlite3_column_int(statement, i);
					[result setObject:[NSNumber numberWithFloat:value] forKey:columnName];
					break;
				}
				case SQLITE_TEXT:
				{
					const char *value = (const char*)sqlite3_column_text(statement, i);
					[result setObject:[NSString stringWithCString:value encoding:NSUTF8StringEncoding] forKey:columnName];
					break;
				}
                    
				case SQLITE_BLOB:
					break;
				case SQLITE_NULL:
					[result setObject:[NSNull null] forKey:columnName];
					break;
                    
				default:
				{
					const char *value = (const char *)sqlite3_column_text(statement, i);
					[result setObject:[NSString stringWithCString:value encoding:NSUTF8StringEncoding] forKey:columnName];
					break;
				}
                    
			} //end switch
			
			
		} //end for
		
		[resultsArray addObject:result];
		
	} //end while
	sqlite3_finalize(statement);
	
	[self closeDatabase];
	
	return resultsArray;
}


/**
 * Closes the database.
 *
 * @return nil if everything was ok, NSError in other case.
 */

- (NSError *)closeDatabase {
	
	NSError *error = nil;
	
	
	if (self.db != nil) {
		if (sqlite3_close(self.db) != SQLITE_OK){
			const char *errorMsg = sqlite3_errmsg(self.db);
			NSString *errorStr = [NSString stringWithFormat:@"The database could not be closed: %@",[NSString stringWithCString:errorMsg encoding:NSUTF8StringEncoding]];
			error = [self createDBErrorWithDescription:errorStr andCode:kDBFailAtClose];
		}
		
		self.db = nil;
	}
	
	return error;
}


/**
 * Creates an SQL dump of the database.
 *
 * This method could get a csv format dump with a few changes. 
 * But i prefer working with sql dumps ;)
 *
 * @return an NSString containing the dump.
 */

- (NSString *)getDatabaseDump {
	
	NSMutableString *dump = [[NSMutableString alloc] initWithCapacity:256];
	
	// info string ;) please do not remove it
	[dump appendString:@";\n; Dump generated with SQLiteMgr \n;\n;"];
	[dump appendString:[NSString stringWithFormat:@"; database %@;\n", [self.dbTablename lastPathComponent]]];
	
	// first get all table information
	
	NSArray *rows = [self getRowsForQuery:@"SELECT * FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%';"];
	// last sql query returns something like:
	// {
	// name = users;
	// rootpage = 2; 
	// sql = "CREATE TABLE users (id integer primary key autoincrement, user text, password text)";
	// "tbl_name" = users;
	// type = table;
	// }
	
	//loop through all tables
	for (int i = 0; i<[rows count]; i++) {
		
		NSDictionary *obj = [rows objectAtIndex:i];
		//get sql "create table" sentence
		NSString *sql = [obj objectForKey:@"sql"];
		[dump appendString:[NSString stringWithFormat:@"%@;\n",sql]];
        
		//get table name
		NSString *tableName = [obj objectForKey:@"name"];
        
		//get all table content
		NSArray *tableContent = [self getRowsForQuery:[NSString stringWithFormat:@"SELECT * FROM %@",tableName]];
		
		for (int j = 0; j<[tableContent count]; j++) {
			NSDictionary *item = [tableContent objectAtIndex:j];
			
			//keys are column names
			NSArray *keys = [item allKeys];
			
			//values are column values
			NSArray *values = [item allValues];
			
			//start constructing insert statement for this item
			[dump appendString:[NSString stringWithFormat:@"insert into %@ (",tableName]];
			
			//loop through all keys (aka column names)
			NSEnumerator *enumerator = [keys objectEnumerator];
			id obj;
			while (obj = [enumerator nextObject]) {
				[dump appendString:[NSString stringWithFormat:@"%@,",obj]];
			}
			
			//delete last comma
			NSRange range;
			range.length = 1;
			range.location = [dump length]-1;
			[dump deleteCharactersInRange:range];
			[dump appendString:@") values ("];
			
			// loop through all values
			// value types could be:
			// NSNumber for integer and floats, NSNull for null or NSString for text.
			
			enumerator = [values objectEnumerator];
			while (obj = [enumerator nextObject]) {
				//if it's a number (integer or float)
				if ([obj isKindOfClass:[NSNumber class]]){
					[dump appendString:[NSString stringWithFormat:@"%@,",[obj stringValue]]];
				}
				//if it's a null
				else if ([obj isKindOfClass:[NSNull class]]){
					[dump appendString:@"null,"];
				}
				//else is a string ;)
				else{
					[dump appendString:[NSString stringWithFormat:@"'%@',",obj]];
				}
				
			}
			
			//delete last comma again
			range.length = 1;
			range.location = [dump length]-1;
			[dump deleteCharactersInRange:range];
			
			//finish our insert statement
			[dump appendString:@");\n"];
			
		}
		
	}
	return dump;
}

@end


#pragma mark -
@implementation SQLiteMgr (Private)

/**
 * Creates an NSError.
 *
 * @param description the description wich can be queried with [error localizedDescription];
 * @param code the error code (code erors are defined as enum in the header file).
 *
 * @return the NSError just created.
 *
 */

- (NSError *)createDBErrorWithDescription:(NSString*)description andCode:(int)code {
	
	NSDictionary *userInfo = [[NSDictionary alloc] initWithObjectsAndKeys:description, NSLocalizedDescriptionKey, nil];
	NSError *error = [NSError errorWithDomain:@"SQLite Error" code:code userInfo:userInfo];
	
	return error;
}


@end
