//
//  DatabaseController.m
//  ColourMemory
//
//  Created by OsamaMac on 9/1/14.
//  Copyright (c) 2014 Osama Rabie. All rights reserved.
//

#import "DatabaseController.h"
#import <sqlite3.h>

static  NSString* DATABASENAME = @"ArabChatDB";
static  NSString* MESSAGESTABLE = @"ChatTable";

@implementation DatabaseController
{
    NSString *databasePath; // to hold the path the local db will be stored in.
    sqlite3 *localScoresDB; // the real object to hold reference to the local database.
}

/**
 This method to be called by the controller when he wants to make sure that the database with along the columns are stored locally.
 **/

-(void)createDatabaseIfNotExists
{
    databasePath = [self configureDatabasePath];
    
    // check if it is not already there, then create the database with all its tables then store it
    NSFileManager *filemgr = [NSFileManager defaultManager];
    
    if ([filemgr fileExistsAtPath: databasePath ] == NO) // DB is not there, need to create one.
    {
        const char *dbpath = [databasePath UTF8String];
        
        if (sqlite3_open(dbpath, &localScoresDB) == SQLITE_OK)
        {
            char *errMsg;
            // creating the all jobs table
            const char *sql_stmt =
            "CREATE TABLE IF NOT EXISTS ChatTable (ID INTEGER PRIMARY KEY , FRDID TEXT, FRDNAME TEXT, FRDIMG TEXT, MSG TEXT, SENT INTEGER, STATUS TEXT, WHENN DOUBLE, ONLINE INTEGER)";
            
            if (sqlite3_exec(localScoresDB, sql_stmt, NULL, NULL, &errMsg) == SQLITE_OK)
            {
                NSLog(@"%@",@"Successfully to create ChatTable table");
            }else
            {
                NSLog(@"%@",@"Failed to create ChatTable table");
            }
        }
    }
}

/**
 This method is to be used to initialize the path the database will be stored into.
 **/
-(NSString*)configureDatabasePath
{
    NSString *docsDir;
    NSArray *dirPaths;
    // Get the documents directory
    dirPaths = NSSearchPathForDirectoriesInDomains(
                                                   NSDocumentDirectory, NSUserDomainMask, YES);
    
    docsDir = dirPaths[0];
    
    // Build the path to the database file
    return  [[NSString alloc] initWithString: [docsDir stringByAppendingPathComponent: DATABASENAME]];
}



/**
 This method to be called by the controller when he wants to insert new score record locally.
 **/
-(void)insertNewChatRecord:(NSString*)FRDID FRDNAME:(NSString*)FRDNAME FRDIMG:(NSString*)FRDIMG MSG:(NSString*)MSG SENT:(int)SENT STATUS:(NSString*)STATUS WHENN:(double)WHENN ONLINE:(int)ONLINE
{
    databasePath = [self configureDatabasePath];
    sqlite3_stmt    *statement;
    const char *dbpath = [databasePath UTF8String];
    
    if (sqlite3_open(dbpath, &localScoresDB) == SQLITE_OK)
    {
        NSString *insertSQL = [NSString stringWithFormat:
                               @"INSERT INTO ChatTable (FRDID, FRDNAME, FRDIMG, MSG, SENT, STATUS, WHENN, ONLINE) VALUES (\"%@\", \"%@\", \"%@\", \"%@\", \"%i\", \"%@\", \"%f\", \"%i\")",
                               FRDID,
                               FRDNAME,
                               FRDIMG,
                               MSG,
                               SENT,
                               STATUS,
                               WHENN,
                               ONLINE];
        
        const char *insert_stmt = [insertSQL UTF8String];
        const char *errMsg;
        sqlite3_prepare_v2(localScoresDB, insert_stmt,
                           -1, &statement, &errMsg);
        if (sqlite3_step(statement) == SQLITE_DONE)
        {
            NSLog(@"%@",@"SCORE ADDED");
        } else {
            NSLog(@"%@.",@"Failed to add SCORE");
        }
        sqlite3_finalize(statement);
        sqlite3_close(localScoresDB);
    }
}


/**
 This method to be called by the controller when he wants to get the top 10 scores the user achieved till now.
 **/
-(NSMutableArray*)loadTopLevelThreads
{
    databasePath = [self configureDatabasePath];
    
    const char *dbpath = [databasePath UTF8String];
    sqlite3_stmt    *statement;
    
    NSMutableArray* topTenScores = [[NSMutableArray alloc]init];
    
    if (sqlite3_open(dbpath, &localScoresDB) == SQLITE_OK)
    {
        NSString *querySQL =  @"SELECT * FROM ChatTable WHERE ChatTable.WHENN IN (SELECT MAX(WHENN) FROM ChatTable GROUP BY FRDID) ORDER BY ChatTable.WHENN DESC";
        
        const char *query_stmt = [querySQL UTF8String];
        
        if (sqlite3_prepare_v2(localScoresDB,
                               query_stmt, -1, &statement, NULL) == SQLITE_OK)
        {
            while (sqlite3_step(statement) == SQLITE_ROW)
            {
                
                NSString *FRDID = [[NSString alloc]
                                   initWithUTF8String:
                                   (const char *) sqlite3_column_text(
                                                                      statement, 0)];
                
                NSString *FRDNAME = [[NSString alloc]
                                     initWithUTF8String:
                                     (const char *) sqlite3_column_text(
                                                                        statement, 1)];
                
                NSString *FRDIMG = [[NSString alloc]
                                    initWithUTF8String:
                                    (const char *) sqlite3_column_text(
                                                                       statement, 2)];
                
                NSString *MSG = [[NSString alloc]
                                 initWithUTF8String:
                                 (const char *) sqlite3_column_text(
                                                                    statement, 3)];
                
                NSNumber* SENT = [NSNumber numberWithInt:sqlite3_column_int(statement, 4)];
                
                NSString *STAUS = [[NSString alloc]
                                   initWithUTF8String:
                                   (const char *) sqlite3_column_text(
                                                                      statement, 5)];
                
                NSNumber* WHENN = [NSNumber numberWithInt:sqlite3_column_double(statement, 6)];
                
                NSNumber* ONLINE = [NSNumber numberWithInt:sqlite3_column_double(statement, 7)];
                
                
                NSDictionary* scoreEntry = [[NSDictionary alloc]initWithObjects:@[FRDID,FRDNAME,FRDIMG,MSG,SENT,STAUS,WHENN,ONLINE] forKeys:@[@"FRDID",@"FRDNAME",@"FRDIMG",@"MSG",@"SENT",@"STATUS",@"WHENN",@"ONLINE"]];
                
                [topTenScores addObject:scoreEntry];
                
            }
            sqlite3_finalize(statement);
        }
        sqlite3_close(localScoresDB);
    }
    return topTenScores;
}

-(void)updatePhoto:(NSString*)FRDI FRDIMG:(NSString*)FRDIMG FRDONLINE:(int)FRDONLINE
{
    databasePath = [self configureDatabasePath];
    
    const char *dbpath = [databasePath UTF8String];
    sqlite3_stmt    *statement;
    
    if (sqlite3_open(dbpath, &localScoresDB) == SQLITE_OK)
    {
        NSString *updateSQL = [NSString stringWithFormat:
                               @"UPDATE ChatTable SET FRDIMG=%@, FRDONLINE = %i WHERE FRDID=%@",
                               FRDIMG,FRDONLINE,FRDI];
        
        const char *update_stmt = [updateSQL UTF8String];
        const char *errMsg;
        sqlite3_prepare_v2(localScoresDB, update_stmt,
                           -1, &statement, &errMsg);
        if (sqlite3_step(statement) == SQLITE_DONE)
        {
            NSLog(@"%@ : %i",@"Updated",[FRDI intValue]);
        } else {
            NSLog(@"%@ : %i",@"Failed To Update",[FRDI intValue]);
        }
        sqlite3_finalize(statement);

        sqlite3_close(localScoresDB);
    }
}

-(NSString*)loadUniqueFriendIDs
{
    databasePath = [self configureDatabasePath];
    
    const char *dbpath = [databasePath UTF8String];
    sqlite3_stmt    *statement;
    
    NSMutableArray* topTenScores = [[NSMutableArray alloc]init];
    
    if (sqlite3_open(dbpath, &localScoresDB) == SQLITE_OK)
    {
        NSString *querySQL =  @"SELECT UNIQUE(FRDID) FROM ChatTable";
        
        const char *query_stmt = [querySQL UTF8String];
        
        if (sqlite3_prepare_v2(localScoresDB,
                               query_stmt, -1, &statement, NULL) == SQLITE_OK)
        {
            while (sqlite3_step(statement) == SQLITE_ROW)
            {
                
                NSString *FRDID = [[NSString alloc]
                                   initWithUTF8String:
                                   (const char *) sqlite3_column_text(
                                                                      statement, 0)];
                
                [topTenScores addObject:FRDID];
            }
            sqlite3_finalize(statement);
        }
        sqlite3_close(localScoresDB);
    }
    
    return [topTenScores componentsJoinedByString:@","];
}
@end
