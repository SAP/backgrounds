/*
     MTCollectionView.h
     Copyright 2022 SAP SE
     
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

@class MTCollectionView;

/*!
 @protocol      MTCollectionViewMenuDelegate
 @abstract      Defines an interface for delegates of MTCollectionView to be notified if the user right-clicked on the collection view.
*/
@protocol MTCollectionViewMenuDelegate <NSObject>

/*!
 @method        collectionView:willOpenMenuAtIndexPath
 @abstract      Called whenever the user does right-click on the collection view.
 @param         indexPath The index path of the collection view item the user clicked on.
 @discussion    Delegates receive this message whenever the user does right-click on the collection view.
 */
- (NSMenu*)collectionView:(MTCollectionView*)view willOpenMenuAtIndexPath:(NSIndexPath*)indexPath;

@end

/*!
 @protocol      MTCollectionViewDelegate
 @abstract      Extends the NSCollectionViewDelegate protocol by a method that notifies the delegate whenever the collection view will delete items.
*/
@protocol MTCollectionViewDelegate <NSCollectionViewDelegate>

/*!
 @method        backgroundAtIndexPath:
 @abstract      Called before the collection view deletes items.
 @param         indexPaths The index paths of the collection view items to be deleted.
 @discussion    Delegates receive this message whenever the collection view will delete items..
 */
- (void)collectionView:(MTCollectionView*)view willDeleteItemsAtIndexPaths:(NSSet<NSIndexPath *> *)indexPaths;

@end

@interface MTCollectionView : NSCollectionView

/*!
 @property      menuDelegate
 @abstract      The receiver's menu delegate.
 @discussion    The value of this property is an object conforming to the MTCollectionViewMenuDelegate protocol.
*/
@property (weak) id <MTCollectionViewMenuDelegate> menuDelegate;

/*!
 @property      menuDelegate
 @abstract      The receiver's delegate.
 @discussion    The value of this property is an object conforming to the MTCollectionViewDelegate protocol.
*/
@property (weak) id <MTCollectionViewDelegate> delegate;

/*!
 @property      lastSelectedIndexPath
 @abstract      A property to store the last selected index path.
 @discussion    The value of this property is a NSIndexPath.
*/
@property (nonatomic, strong, readwrite) NSIndexPath *lastSelectedIndexPath;

/*!
 @property      lastSelection
 @abstract      Returns the last selection of the collection view.
 @discussion    The value of this property is a set of index paths. To update this property, use the method takeSelectionSnaphot.
*/
@property (nonatomic, strong, readonly) NSSet <NSIndexPath *> *lastSelection;

/*!
 @method        selectionIndexesInSection:
 @abstract      Returns the indexes of the selected items in a given section.
 @param         section The section where to get the selected items for.
 @discussion    Returns a set of index paths.
 */
- (NSSet <NSIndexPath*> *)selectionIndexesInSection:(NSInteger)section;

/*!
 @method        takeSelectionSnaphot
 @abstract      Updates the property lastSelection with the index paths of the currently selected items.
 */
- (void)takeSelectionSnaphot;

@end

