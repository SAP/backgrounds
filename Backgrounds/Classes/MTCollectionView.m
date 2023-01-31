/*
     MTCollectionView.m
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

#import "MTCollectionView.h"

@interface MTCollectionView ()
@property (nonatomic, strong, readwrite) NSSet <NSIndexPath *> *lastSelection;
@end

@implementation MTCollectionView

@dynamic delegate;

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
}

- (NSMenu*)menuForEvent:(NSEvent *)event
{
    NSPoint mouseLocation = [self convertPoint:[event locationInWindow] fromView:nil];
    NSIndexPath *indexPath = [self indexPathForItemAtPoint:mouseLocation];
    NSMenu *theMenu = nil;
    
    if (_menuDelegate && [_menuDelegate respondsToSelector:@selector(collectionView:willOpenMenuAtIndexPath:)]) {
        theMenu = [_menuDelegate collectionView:self willOpenMenuAtIndexPath:indexPath];
    }

    return theMenu;
}

- (void)keyDown:(NSEvent *)event
{
    if ([[event charactersIgnoringModifiers] characterAtIndex:0] == NSDeleteCharacter) {

        if ([[self delegate] respondsToSelector:@selector(collectionView:willDeleteItemsAtIndexPaths:)]) {
            [[self delegate] collectionView:self willDeleteItemsAtIndexPaths:[self selectionIndexPaths]];
        }
        
    } else {
        
        [super keyDown:event];
    }
}

- (NSSet <NSIndexPath*> *)selectionIndexesInSection:(NSInteger)section
{
    NSSet *selectedInSection = [[self selectionIndexPaths] filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"section == %ld", section]];
    return selectedInSection;
}

- (void)takeSelectionSnaphot
{
    _lastSelection = self.selectionIndexPaths;
}

@end
