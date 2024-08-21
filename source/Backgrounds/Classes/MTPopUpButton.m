/*
     MTPopUpButton.m
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

#import "MTPopUpButton.h"

@interface MTPopUpButton ()
@property (assign) NSInteger previousSelectionIndex;
@end

@implementation MTPopUpButton

- (instancetype)initWithFrame:(NSRect)buttonFrame pullsDown:(BOOL)flag
{
    self = [super initWithFrame:buttonFrame pullsDown:flag];
    [[self menu] setDelegate:self];
    
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    [[self menu] setDelegate:self];
    
    return self;
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
}

- (void)selectItemAtIndex:(NSInteger)index
{
    _previousSelectionIndex = self.indexOfSelectedItem;
    [super selectItemAtIndex:index];
}

- (void)menuWillOpen:(NSMenu *)menu
{
    _previousSelectionIndex = self.indexOfSelectedItem;
}

@end
