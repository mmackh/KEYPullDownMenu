//
//  BVReorderTableView.m
//
//  Copyright (c) 2013 Ben Vogelzang.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

#import "BVReorderTableView.h"
#import <QuartzCore/QuartzCore.h>

@interface BVReorderTableView ()

@property (nonatomic, strong) UILongPressGestureRecognizer *longPress;
@property (nonatomic, strong) NSTimer *scrollingTimer;
@property (nonatomic, assign) CGFloat scrollRate;
@property (nonatomic, strong) NSIndexPath *currentLocationIndexPath;
@property (nonatomic, strong) NSIndexPath *initialIndexPath;
@property (nonatomic, strong) UIImageView *draggingView;
@property (nonatomic, retain) id savedObject;

- (void)initialize;
- (void)longPress:(UILongPressGestureRecognizer *)gesture;
- (void)updateCurrentLocation:(UILongPressGestureRecognizer *)gesture;
- (void)scrollTableWithCell:(NSTimer *)timer;
- (void)cancelGesture;

@end



@implementation BVReorderTableView

@dynamic delegate, canReorder;
@synthesize longPress;
@synthesize scrollingTimer;
@synthesize scrollRate;
@synthesize currentLocationIndexPath;
@synthesize draggingView;
@synthesize savedObject;
@synthesize draggingRowHeight;
@synthesize initialIndexPath;

- (id)init {
    return [self initWithFrame:CGRectZero];
}

- (id)initWithFrame:(CGRect)frame {
    return [self initWithFrame:frame style:UITableViewStylePlain];
}

- (id)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        [self initialize];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame style:(UITableViewStyle)style {
    self = [super initWithFrame:frame style:style];
    if (self) {
        [self initialize];
    }
    return self;
}


- (void)initialize {
    longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPress:)];
    [self addGestureRecognizer:longPress];
    
    self.canReorder = YES;
}

- (void)setCanReorder:(BOOL)canReorder {
    canReorder = canReorder;
    longPress.enabled = canReorder;
}


- (void)longPress:(UILongPressGestureRecognizer *)gesture {
    
    CGPoint location = [gesture locationInView:self];
    NSIndexPath *indexPath = [self indexPathForRowAtPoint:location];
    
    NSInteger sections = [self numberOfSections];
    int rows = 0;
    for(int i = 0; i < sections; i++) {
        rows += [self numberOfRowsInSection:i];
    }
    
    // get out of here if the long press was not on a valid row or our table is empty
    // or the dataSource tableView:canMoveRowAtIndexPath: doesn't allow moving the row
    if (rows == 0 || (gesture.state == UIGestureRecognizerStateBegan && indexPath == nil) ||
        (gesture.state == UIGestureRecognizerStateEnded && self.currentLocationIndexPath == nil) ||
        (gesture.state == UIGestureRecognizerStateBegan &&
         [self.dataSource respondsToSelector:@selector(tableView:canMoveRowAtIndexPath:)] &&
         indexPath && ![self.dataSource tableView:self canMoveRowAtIndexPath:indexPath])) {
        [self cancelGesture];
        return;
    }
    
    // started
    if (gesture.state == UIGestureRecognizerStateBegan) {
        
        UITableViewCell *cell = [self cellForRowAtIndexPath:indexPath];
        self.draggingRowHeight = cell.frame.size.height;
        [cell setHighlighted:NO animated:NO];
        [cell setSelected:NO animated:NO];
        
        
        // make an image from the pressed tableview cell
        UIGraphicsBeginImageContextWithOptions(cell.bounds.size, YES, 0);
        [cell.layer renderInContext:UIGraphicsGetCurrentContext()];
        UIImage *cellImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        // create and image view that we will drag around the screen
        if (!draggingView) {
            draggingView = [[UIImageView alloc] initWithImage:cellImage];
            [self addSubview:draggingView];
            CGRect rect = [self rectForRowAtIndexPath:indexPath];
            draggingView.frame = CGRectOffset(draggingView.bounds, rect.origin.x, rect.origin.y);
            [UIView animateWithDuration:0.3 animations:^{
                
                draggingView.transform = CGAffineTransformMakeScale(1.03, 1.03);
                draggingView.center = CGPointMake(self.center.x, location.y);
            }];
        }
        
        [self beginUpdates];
        [self deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationNone];
        [self insertRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationNone];
        
        self.savedObject = [self.delegate saveObjectAndInsertBlankRowAtIndexPath:indexPath];
        self.currentLocationIndexPath = indexPath;
        self.initialIndexPath = indexPath;
        [self endUpdates];
        
        // enable scrolling for cell
        NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithObject:gesture forKey:@"gesture"];
        self.scrollingTimer = [NSTimer timerWithTimeInterval:1/8 target:self selector:@selector(scrollTableWithCell:) userInfo:userInfo repeats:YES];
        [[NSRunLoop mainRunLoop] addTimer:self.scrollingTimer forMode:NSDefaultRunLoopMode];
        
    }
    // dragging
    else if (gesture.state == UIGestureRecognizerStateChanged) {
        // update position of the drag view
        // don't let it go past the top or the bottom too far
        if (location.y >= 0 && location.y <= self.contentSize.height + 50) {
            draggingView.center = CGPointMake(self.center.x, location.y);
        }
        
        CGRect rect = self.bounds;
        // adjust rect for content inset as we will use it below for calculating scroll zones
        rect.size.height -= self.contentInset.top;
        CGPoint location = [gesture locationInView:self];
        
        [self updateCurrentLocation:gesture];
        
        // tell us if we should scroll and which direction
        CGFloat scrollZoneHeight = rect.size.height / 6;
        CGFloat bottomScrollBeginning = self.contentOffset.y + self.contentInset.top + rect.size.height - scrollZoneHeight;
        CGFloat topScrollBeginning = self.contentOffset.y + self.contentInset.top  + scrollZoneHeight;
        // we're in the bottom zone
        if (location.y >= bottomScrollBeginning) {
            self.scrollRate = (location.y - bottomScrollBeginning) / scrollZoneHeight;
        }
        // we're in the top zone
        else if (location.y <= topScrollBeginning) {
            self.scrollRate = (location.y - topScrollBeginning) / scrollZoneHeight;
        }
        else {
            self.scrollRate = 0;
        }
    }
    // dropped
    else if (gesture.state == UIGestureRecognizerStateEnded) {
        
        NSIndexPath *indexPath = self.currentLocationIndexPath;
        
        // remove scrolling timer
        [self.scrollingTimer invalidate];
        self.scrollingTimer = nil;
        self.scrollRate = 0;
        
        // animate the drag view to the newly hovered cell
        [UIView animateWithDuration:0.1
                         animations:^{
                             CGRect rect = [self rectForRowAtIndexPath:indexPath];
                             draggingView.transform = CGAffineTransformIdentity;
                             draggingView.frame = CGRectOffset(draggingView.bounds, rect.origin.x, rect.origin.y);
                         } completion:^(BOOL finished) {
                             [draggingView removeFromSuperview];
                             
                             [self beginUpdates];
                             [self deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationNone];
                             [self insertRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationNone];
                             [self.delegate finishReorderingWithObject:self.savedObject atIndexPath:indexPath];
                             [self endUpdates];
                             self.currentLocationIndexPath = nil;
                             self.draggingView = nil;
                         }];
    }
}


- (void)updateCurrentLocation:(UILongPressGestureRecognizer *)gesture {
    
    NSIndexPath *indexPath  = nil;
    CGPoint location = CGPointZero;
    
    // refresh index path
    location  = [gesture locationInView:self];
    indexPath = [self indexPathForRowAtPoint:location];
    
    
    indexPath = [self.delegate tableView:self targetIndexPathForMoveFromRowAtIndexPath:self.initialIndexPath toProposedIndexPath:indexPath];
    
    NSInteger oldHeight = [self rectForRowAtIndexPath:self.currentLocationIndexPath].size.height;
    NSInteger newHeight = [self rectForRowAtIndexPath:indexPath].size.height;
    
    if (indexPath && ![indexPath isEqual:self.currentLocationIndexPath] && [gesture locationInView:[self cellForRowAtIndexPath:indexPath]].y > newHeight - oldHeight) {
        [self beginUpdates];
        [self deleteRowsAtIndexPaths:[NSArray arrayWithObject:self.currentLocationIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        [self insertRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        
        
        [self.delegate moveRowAtIndexPath:self.currentLocationIndexPath toIndexPath:indexPath];
        
        self.currentLocationIndexPath = indexPath;
        [self endUpdates];
    }
}

- (void)scrollTableWithCell:(NSTimer *)timer {
    
    UILongPressGestureRecognizer *gesture = [timer.userInfo objectForKey:@"gesture"];
    CGPoint location  = [gesture locationInView:self];
    
    CGPoint currentOffset = self.contentOffset;
    CGPoint newOffset = CGPointMake(currentOffset.x, currentOffset.y + self.scrollRate);
    
    if (newOffset.y < -self.contentInset.top) {
        newOffset.y = -self.contentInset.top;
    } else if (self.contentSize.height < self.frame.size.height) {
        newOffset = currentOffset;
    } else if (newOffset.y > self.contentSize.height - self.frame.size.height) {
        newOffset.y = self.contentSize.height - self.frame.size.height;
    } else {
    }
    [self setContentOffset:newOffset];
    
    if (location.y >= 0 && location.y <= self.contentSize.height + 50) {
        draggingView.center = CGPointMake(self.center.x, location.y);
    }
    
    [self updateCurrentLocation:gesture];
}

- (void)cancelGesture {
    longPress.enabled = NO;
    longPress.enabled = YES;
}

@end