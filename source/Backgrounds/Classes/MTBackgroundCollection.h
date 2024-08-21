/*
     MTBackgroundCollection.h
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

#import <Cocoa/Cocoa.h>

/*!
 @abstract This class holds the predefined and user-defined backgrounds and provides methods for adding, removing and reordering backgrounds.
 */

@interface MTBackgroundCollection : NSObject

/*!
 @method        predefinedBackgrounds
 @abstract      Returns all predefined backgrounds.
 @discussion    Returns an array containing all predefined backgrounds or an empty array, if there are no backgrounds predefined.
 */
- (NSArray <NSDictionary*> *)predefinedBackgrounds;

/*!
 @method        userDefinedBackgrounds
 @abstract      Returns all user-defined backgrounds.
 @discussion    Returns an array containing all user-defined backgrounds or an empty array, if there are no user-defined backgrounds.
 */
- (NSArray <NSDictionary*> *)userDefinedBackgrounds;

/*!
 @method        predefinedBackgroundWithName:
 @abstract      Returns the predefined background matching the given name.
 @param         name The name of the predefined background.
 @discussion    Returns a dictionary for the background or an empty dictionary, if no background matches the given name.
 */
- (NSDictionary*)predefinedBackgroundWithName:(NSString*)name;

/*!
 @method        backgroundAtIndexPath:
 @abstract      Returns the background at the given index path.
 @param         indexPath The index path of the background.
 @discussion    Returns a dictionary for the background or an empty dictionary, if no background exists at the given index path.
 */
- (NSDictionary*)backgroundAtIndexPath:(NSIndexPath*)indexPath;

/*!
 @method        insertBackgrounds:atIndexPath:
 @abstract      Inserts the given backgrounds at the given index path.
 @param         backgrounds An array of backgrounds (dictionaries).
 @param         indexPath The index path at which the backgrounds should be inserted..
 */
- (void)insertBackgrounds:(NSArray <NSDictionary*> *)backgrounds atIndexPath:(NSIndexPath*)indexPath;

/*!
 @method        addUserDefinedBackground:
 @abstract      Adds a new background to the user-defined backgrounds array.
 @param         background A dictionary containing the information for the background.
 */
- (void)addUserDefinedBackground:(NSDictionary*)background;

/*!
 @method        addUserDefinedBackgroundsFromArray:
 @abstract      Adds an array of backgrounds to the user-defined backgrounds array.
 @param         backgrounds An array of dictionaries containing the information for backgrounds.
 */
- (void)addUserDefinedBackgroundsFromArray:(NSArray <NSDictionary*> *)backgrounds;

/*!
 @method        removeUserDefinedBackgroundsAtIndexes:
 @abstract      Removes user-defined backgrounds at the given indexes.
 @param         indexes An index set containing the indexes of the backgrounds that shoud be removed from user-defined backgrounds.
 */
- (void)removeUserDefinedBackgroundsAtIndexes:(NSIndexSet*)indexes;

/*!
 @method        moveBackgroundFromIndex:toIndex:inSection:
 @abstract      Moves a background from the given index to another index within the given section.
 @param         fromIndex The original index of the background that should be moved from.
 @param         toIndex The index the background should be moved to.
 @param         section The section where the background is located at.
 */
- (void)moveBackgroundFromIndex:(NSInteger)fromIndex toIndex:(NSInteger)toIndex inSection:(NSInteger)section;

/*!
 @method        synchronize
 @abstract      Writes the user-defined backgrounds array to disk.
 @discussion    To increase performance, changes to the user-defined backgrounds are not written to disk
 automatically. If the changes should be written, use this method. The user-defined backgrounds are then written
 to the app's user defaults using the key kMTDefaultsUserDefinedBackgrounds.
 */
- (void)synchronize;

/*!
 @method        importBackgroundsWithURL:
 @abstract      Import backgrounds from an export file (.bgexport) with the given url.
 @param         url The url of the export file.
 @discussion    Adds all valid backgrounds from the export file to the end of the user-defined backgrounds array.
 */
- (void)importBackgroundsWithURL:(NSURL*)url;

/*!
 @method        importBackgroundsWithURL:atIndexPath:
 @abstract      Import backgrounds from an export file (.bgexport) with the given url at the given index path.
 @param         url The url of the export file.
 @param         indexPath The index path (section, item) where the backgrounds should be imported at.
 @discussion    Adds all valid backgrounds from the export file to the backgrounds array at the specified index path.
 */
- (void)importBackgroundsWithURL:(NSURL*)url atIndexPath:(NSIndexPath*)indexPath;

/*!
 @method        exportBackgroundsAtIndexPaths:toURL:
 @abstract      Export the specified backgrounds to an export file (.bgexport) with the given url.
 @param         indexPaths A set of index paths (section, item) of the backgrounds that should be exported.
 @param         url The url where the export file should be written at.
 @discussion    Returns YES if the backgrounds haven been successfully exported, otherwise returns NO.
 */
- (BOOL)exportBackgroundsAtIndexPaths:(NSSet <NSIndexPath*> *)indexPaths toURL:(NSURL*)url;

/*!
 @method        numberOfSections
 @abstract      Returns the number of sections contained in the MTBackgroundCollection object.
 */
- (NSInteger)numberOfSections;

/*!
 @method        numberOfBackgroundsInSection:
 @abstract      Returns the number of backgrounds contained in the given section.
 @param         section An integer specifying the section.
 */
- (NSInteger)numberOfBackgroundsInSection:(NSInteger)section;

@end
