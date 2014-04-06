#Introduction

A pull down menu, similar to notification center on iOS that supports an unlimited number of items. Items can either be selected, deleted or reordered. The control is aimed at providing context for switching data within the same view controller.

by [@mmackh](https://twitter.com/mmackh)

#Live Demo

![](https://raw.githubusercontent.com/mmackh/KEYPullDownMenu/master/demo.gif)

#Example Usage

```
- (IBAction)togglePullDownMenu:(id)sender
{
    [self.pullDownMenuButton setSelected:!self.pullDownMenuButton.selected];
    BOOL menuVisible = self.pullDownMenuButton.selected;
    
    if (menuVisible)
    {
        self.searchBar.text = @"";
        [self.searchBar resignFirstResponder];
        
        __weak typeof(self) weakSelf = self;
        KEYPullDownMenuItem *activeMenu = [KEYPullDownMenuItem menuItemNamed:@"HP Restaurant" deletable:NO];
        [activeMenu setActive:YES];
        
        NSMutableArray *pullDownItems = [NSMutableArray new];
        for (PCSmartOrderTableStation *tableStation in self.controller.currentVenue.tableStations)
        {
            KEYPullDownMenuItem *item = [KEYPullDownMenuItem menuItemNamed:tableStation.name deletable:NO];
            [item setActive:(_currentTableStation == tableStation)];
            [pullDownItems addObject:item];
        }
        
        KEYPullDownMenu *pullDownMenu = [KEYPullDownMenu openMenuInViewController:self items:pullDownItems
         dismissBlock:^(KEYPullDownMenuItem *selectedItem, NSInteger selectedRow)
         {
             PCSmartOrderTableStation *temporaryTableStation = weakSelf.controller.currentVenue.tableStations[selectedRow];
             if (temporaryTableStation != _currentTableStation)
             {
                 _currentTableStation = temporaryTableStation;
                 weakSelf.controller.currentVenue.currentTableStation = _currentTableStation;
                 
                 [weakSelf.collectionView setContentOffset:CGPointZero];
                 [weakSelf updateView];
             };
             [weakSelf togglePullDownMenu:nil];
         }
         reorderBlock:nil deleteBlock:nil];
        pullDownMenu.backgroundColor = [UIColor colorWithWhite:0.3 alpha:0.95];
    }
    else
    {
        [KEYPullDownMenu dismissInViewController:self];
    }
}
```

#Attribution

##SKBounceAnimation

Copyright (c) 2012 Soroush Khanlou (http://khanlou.com/)

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

##BVReorderTableView
 Created by Benjamin Vogelzang on 3/5/13.
  Copyright (c) 2013 Ben Vogelzang.

  Permission is hereby granted, free of charge, to any person obtaining a copy
  of this software and associated documentation files (the "Software"), to deal
  in the Software without restriction, including without limitation the rights
  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
  copies of the Software, and to permit persons to whom the Software is
  furnished to do so, subject to the following conditions:

  The above copyright notice and this permission notice shall be included in
  all copies or substantial portions of the Software.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
  THE SOFTWARE.
