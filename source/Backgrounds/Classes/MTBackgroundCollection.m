/*
     MTBackgroundCollection.m
     Copyright 2022-2024 SAP SE
     
     Licensed under the Apache License, Version 2.0 (the "License");
     you may not use this file except in compliance with the License.
     You may obtain a copy of the License at
     
     http://www.apache.org/licenses/LICENSE-2.0
     
     Unless required by applicable law or agreed to in writing, software
     distributed under the License is distributed on an "AS IS" BASIS,
     WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
     See the License for the specific language governing permissions and
     limitations under the License.
*/

#import "MTBackgroundCollection.h"
#import "Constants.h"

@interface MTBackgroundCollection ()
@property (nonatomic, strong, readwrite) NSMutableArray *backgroundsArray;
@property (nonatomic, strong, readwrite) NSUserDefaults *userDefaults;
@end

@implementation MTBackgroundCollection

- (id)init
{
    self = [super init];
    
    if (self) {
        _userDefaults = [NSUserDefaults standardUserDefaults];
        
        _backgroundsArray = [[NSMutableArray alloc] init];
        [_backgroundsArray addObject:[self getPredefinedBackgrounds]];
        [_backgroundsArray addObject:[self getUserDefinedBackgrounds]];
    }
    
    return self;
}

- (NSInteger)numberOfSections
{
    return [_backgroundsArray count];
}

- (NSInteger)numberOfBackgroundsInSection:(NSInteger)section
{
    NSInteger numberOfItems = 0;
    
    if (section < [self numberOfSections]) {
        numberOfItems = [_backgroundsArray[section] count];
    }
    
    return numberOfItems;
}

- (NSArray <NSDictionary*> *)predefinedBackgrounds
{
    return [_backgroundsArray objectAtIndex:0];
}

- (NSArray <NSDictionary*> *)userDefinedBackgrounds
{
    return [_backgroundsArray objectAtIndex:1];
}

- (NSDictionary*)predefinedBackgroundWithName:(NSString*)name
{
    NSDictionary *backgroundDict = nil;
    
    if (name) {
        
        NSArray *filteredBackgrounds = [[self predefinedBackgrounds] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"%K == %@", kMTDefaultsBackgroundName, name]];
        
        if ([filteredBackgrounds count] > 0) {
            backgroundDict = [NSDictionary dictionaryWithDictionary:[filteredBackgrounds firstObject]];
        }
    }
    
    return backgroundDict;
}
- (NSDictionary*)backgroundAtIndexPath:(NSIndexPath*)indexPath
{
    NSDictionary *backgroundDict = nil;
    
    NSInteger itemIndex = [indexPath item];
    NSInteger itemSection = [indexPath section];
    
    if (itemSection < [self numberOfSections] && itemIndex < [self numberOfBackgroundsInSection:itemSection]) {
        
        backgroundDict = [NSDictionary dictionaryWithDictionary:[_backgroundsArray[itemSection] objectAtIndex:itemIndex]];
        
    } else {
        
        backgroundDict = [NSDictionary dictionary];
    }
    
    return backgroundDict;
}

- (void)insertBackgrounds:(NSArray <NSDictionary*> *)backgrounds atIndexPath:(NSIndexPath*)indexPath
{
    if (backgrounds) {
        
        NSInteger itemIndex = [indexPath item];
        NSInteger itemSection = [indexPath section];

        if (itemSection < [self numberOfSections] && itemIndex <= [self numberOfBackgroundsInSection:itemSection]) {
            
            NSIndexSet *indexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(itemIndex, [backgrounds count])];
            [_backgroundsArray[itemSection] insertObjects:backgrounds atIndexes:indexes];
        }
    }
}

- (void)addUserDefinedBackground:(NSDictionary*)background
{
    if (background) {
        [self addUserDefinedBackgroundsFromArray:[NSArray arrayWithObject:background]];
    }
}

- (void)addUserDefinedBackgroundsFromArray:(NSArray <NSDictionary*> *)backgrounds
{
    if (backgrounds) {
        [_backgroundsArray[kMTSectionUserDefined] addObjectsFromArray:backgrounds];
    }
}

- (void)removeUserDefinedBackgroundsAtIndexes:(NSIndexSet*)indexes
{
    [_backgroundsArray[kMTSectionUserDefined] removeObjectsAtIndexes:indexes];
}

- (NSMutableArray*)getPredefinedBackgrounds
{
    NSMutableArray *backgroundArray = [[NSMutableArray alloc] init];
    NSArray *predefinedBackgrounds = [_userDefaults arrayForKey:kMTDefaultsPredefinedBackgrounds];
    
    if (!predefinedBackgrounds) {
        NSString *plistPath = [[NSBundle mainBundle] pathForResource:@"Predefined" ofType:@"plist"];
        if (plistPath) { predefinedBackgrounds = [[NSArray alloc] initWithContentsOfFile:plistPath]; }
    }
    
    for (NSDictionary *backgroundDict in predefinedBackgrounds) { [backgroundArray addObject:backgroundDict]; }
    
    return backgroundArray;
}

- (NSMutableArray*)getUserDefinedBackgrounds
{
    NSMutableArray *backgroundArray = [[NSMutableArray alloc] init];
    NSArray *userDefinedBackgrounds = [_userDefaults arrayForKey:kMTDefaultsUserDefinedBackgrounds];
    for (NSDictionary *backgroundDict in userDefinedBackgrounds) { [backgroundArray addObject:backgroundDict]; }
    
    return backgroundArray;
}

- (void)moveBackgroundFromIndex:(NSInteger)fromIndex toIndex:(NSInteger)toIndex inSection:(NSInteger)section
{
    if (section < [self numberOfSections] && toIndex < [self numberOfBackgroundsInSection:section] && fromIndex != toIndex) {
        NSDictionary *backgroundDict = [self backgroundAtIndexPath:[NSIndexPath indexPathForItem:fromIndex inSection:section]];
        [_backgroundsArray[section] removeObjectAtIndex:fromIndex];
        [_backgroundsArray[section] insertObject:backgroundDict atIndex:toIndex];
    }
}

- (void)synchronize
{
    [_userDefaults setValue:_backgroundsArray[kMTSectionUserDefined] forKey:kMTDefaultsUserDefinedBackgrounds];
}

- (void)importBackgroundsWithURL:(NSURL*)url
{
    [self importBackgroundsWithURL:url atIndexPath:nil];
}

- (void)importBackgroundsWithURL:(NSURL*)url atIndexPath:(NSIndexPath*)indexPath
{
    NSArray *backgroundsArray = [NSArray arrayWithContentsOfURL:url];
    
    if ([backgroundsArray isKindOfClass:[NSArray class]] && [backgroundsArray count]) {

        if (indexPath) {
            [self insertBackgrounds:backgroundsArray atIndexPath:indexPath];
        } else {
            [self addUserDefinedBackgroundsFromArray:backgroundsArray];
        }
        
        [self synchronize];
    }
}

- (BOOL)exportBackgroundsAtIndexPaths:(NSSet <NSIndexPath*> *)indexPaths toURL:(NSURL*)url
{
    BOOL success = NO;
    
    if ([indexPaths count] > 0) {
        
        NSMutableIndexSet *allIndexes = [[NSMutableIndexSet alloc] init];
        
        for (NSIndexPath *indexPath in indexPaths) {
            [allIndexes addIndex:[indexPath item]];
        }
    
        NSArray *backgroundsForExport = [[self userDefinedBackgrounds] objectsAtIndexes:allIndexes];
        success = [backgroundsForExport writeToURL:url atomically:YES];
        
        if (success) {
            [[NSFileManager defaultManager] setAttributes:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:NSFileExtensionHidden]
                                             ofItemAtPath:[url path] error:nil];
        }
    }
    
    return success;
}

@end
