//
//  KEYPullDownMenu.m
//  Keydown
//
//  Created by mmackh on 10/11/13.
//  Copyright (c) 2013 Maximilian Mackh. All rights reserved.
//

#import "KEYPullDownMenu.h"
#import "SKBounceAnimation.h"
#import "BVReorderTableView.h"

#define kKEYPullDownAnimationDuration 0.3
#define kKEYPullDownAnimationBounceHeight 20
#define kKEYPullDownViewTag 198312

@interface KEYPullDownMenuCell : UITableViewCell

@end

@interface KEYPullDownMenu () <UITableViewDataSource,UITableViewDelegate,ReorderTableViewDelegate>

@property (nonatomic,strong) BVReorderTableView *tableView;
@property (nonatomic,weak) UIViewController *parentViewController;
@property (nonatomic,strong) NSMutableArray *items;
@property (nonatomic,readonly) CGRect initialFrame;
@property (nonatomic,readonly) CGRect finalFrame;

@property (copy) dismissBlock dismissBlock;
@property (copy) reorderBlock reorderBlock;
@property (copy) deleteBlock deleteBlock;

@end

@interface KEYPullDownMenuItem ()

@property (nonatomic) BOOL dummy;

@end

@implementation KEYPullDownMenu

- (id)init
{
    self = [super init];
    if (self)
    {
        self.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.7];
        [self setAutoresizingMask:UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth];
        
        self.tableView = [[BVReorderTableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        [self.tableView registerClass:[KEYPullDownMenuCell class] forCellReuseIdentifier:@"Cell"];
        [self.tableView setRowHeight:60];
        [self.tableView setAutoresizingMask:(UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth)];
        [self.tableView setBackgroundColor:[UIColor clearColor]];
        [self.tableView setSeparatorColor:[UIColor clearColor]];
        [self.tableView setDelegate:self];
        [self.tableView setDataSource:self];
        [self addSubview:self.tableView];
    }
    return self;
}

#pragma mark -
#pragma mark TableView

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    [cell setBackgroundColor:[UIColor clearColor]];
    [cell setAccessoryType:([self.items[indexPath.row] isActive])?UITableViewCellAccessoryCheckmark:UITableViewCellAccessoryNone];

}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.items.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    KEYPullDownMenuCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    cell.textLabel.text = [self.items[indexPath.row] name];
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(self.items.count == 2) return NO;
    return [self.items[indexPath.row] deletable];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete)
    {
        KEYPullDownMenuItem *item = self.items[indexPath.row];
        self.deleteBlock(item);
        [self.tableView beginUpdates];
        [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        [self.items removeObject:item];
        [self.tableView endUpdates];
    }
}

- (BOOL)tableView:(UITableView *)tableview canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [self.items[indexPath.row] deletable];
}

- (NSIndexPath *)tableView:(UITableView *)tableView targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)sourceIndexPath toProposedIndexPath:(NSIndexPath *)proposedDestinationIndexPath
{
    if (![self.items[sourceIndexPath.row] deletable] || ![self.items[proposedDestinationIndexPath.row] deletable]) return sourceIndexPath;
    return proposedDestinationIndexPath;
}

- (id)saveObjectAndInsertBlankRowAtIndexPath:(NSIndexPath *)indexPath
{
    id object = [self.items objectAtIndex:indexPath.row];
    KEYPullDownMenuItem *dummyItem = [KEYPullDownMenuItem menuItemNamed:@"" deletable:YES];
    dummyItem.dummy = YES;
    [self.items replaceObjectAtIndex:indexPath.row withObject:dummyItem];
    return object;
}

- (void)moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
    id object = [self.items objectAtIndex:fromIndexPath.row];
    [self.items removeObjectAtIndex:fromIndexPath.row];
    [self.items insertObject:object atIndex:toIndexPath.row];
}

- (void)finishReorderingWithObject:(id)object atIndexPath:(NSIndexPath *)indexPath
{
    [self.items replaceObjectAtIndex:indexPath.row withObject:object];
    self.reorderBlock(object,indexPath.row);
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
    self.dismissBlock(self.items[indexPath.row],indexPath.row);
}

#pragma mark -
#pragma mark Frames

- (void)layoutSubviews
{
    [super layoutSubviews];
    if (self.frame.origin.y == self.initialFrame.origin.y)
    {
        self.frame = self.initialFrame;
        return;
    }
    self.frame = self.finalFrame;
}

- (CGRect)initialFrame
{
    return CGRectMake(0, -self.parentViewController.view.frame.size.height, self.parentViewController.view.frame.size.width, self.parentViewController.view.frame.size.height);
}

- (CGRect)finalFrame
{
    return CGRectMake(0, self.parentViewController.topLayoutGuide.length, self.parentViewController.view.frame.size.width, self.parentViewController.view.frame.size.height - self.parentViewController.topLayoutGuide.length);
}

#pragma mark -
#pragma mark Public Methods

+ (instancetype)openMenuInViewController:(UIViewController *)viewController items:(NSArray *)menuItems dismissBlock:dismissBlock reorderBlock:reorderBlock deleteBlock:deleteBlock
{
    [self blockUserInteraction:YES];
    KEYPullDownMenu *pullDownView = [[KEYPullDownMenu alloc] init];
    pullDownView.dismissBlock = dismissBlock;
    pullDownView.reorderBlock = reorderBlock;
    pullDownView.deleteBlock = deleteBlock;
    [pullDownView setParentViewController:viewController];
    [pullDownView setFrame:pullDownView.initialFrame];
    [pullDownView setItems:menuItems.mutableCopy];
    [pullDownView setTag:kKEYPullDownViewTag];
    [viewController.view addSubview:pullDownView];
    [UIView animateWithDuration:kKEYPullDownAnimationDuration delay:0 options:UIViewAnimationOptionCurveEaseOut animations:
    ^{
        [pullDownView setFrame:pullDownView.finalFrame];
    }
    completion:^(BOOL finished)
    {
         NSString *keyPath = @"position.y";
         CABasicAnimation *positionAnimation = [CABasicAnimation animationWithKeyPath:keyPath];;
         positionAnimation.fromValue = @(CGRectGetMidY(pullDownView.frame));
         positionAnimation.toValue = @(CGRectGetMidY(pullDownView.frame)-kKEYPullDownAnimationBounceHeight);
         positionAnimation.duration = 0.1;
         positionAnimation.beginTime = 0.0;
         
         id finalValue = @(CGRectGetMidY(pullDownView.finalFrame));
         [pullDownView.layer setValue:finalValue forKeyPath:keyPath];
         SKBounceAnimation *bounceAnimation = [SKBounceAnimation animationWithKeyPath:keyPath];
         bounceAnimation.fromValue = [NSNumber numberWithFloat:CGRectGetMidY(pullDownView.finalFrame) -kKEYPullDownAnimationBounceHeight];
         bounceAnimation.toValue = finalValue;
         bounceAnimation.numberOfBounces = 2;
         bounceAnimation.shouldOvershoot = NO;
         bounceAnimation.beginTime = 0.1;
         bounceAnimation.duration = 0.5;
         
         CAAnimationGroup *group = [CAAnimationGroup animation];
         [group setDuration:.57];
         [group setAnimations:[NSArray arrayWithObjects:positionAnimation, bounceAnimation, nil]];
         
         [pullDownView.layer addAnimation:group forKey:@"bounceAnimation"];
         [self blockUserInteraction:NO];
     }];
    
    return pullDownView;
}

+ (instancetype)dismissInViewController:(UIViewController *)viewController
{
    [self blockUserInteraction:YES];
    KEYPullDownMenu *pullDownView = (KEYPullDownMenu *)[viewController.view viewWithTag:kKEYPullDownViewTag];
    [pullDownView.layer removeAllAnimations];
    [UIView animateWithDuration:kKEYPullDownAnimationDuration animations:^{
        [pullDownView setFrame:pullDownView.initialFrame];
    } completion:^(BOOL finished) {
        [pullDownView removeFromSuperview];
        [self blockUserInteraction:NO];
    }];
    
    return pullDownView;
}

+ (void)blockUserInteraction:(BOOL)block
{
    [[[UIApplication sharedApplication] keyWindow] setUserInteractionEnabled:!block];
}

@end

@implementation KEYPullDownMenuItem
{
    NSString *_name;
    BOOL _deletable;
}

- (id)initWithName:(NSString *)name deletable:(BOOL)deletable
{
    self = [super init];
    if (!self) return nil;
    
    _name = name;
    _deletable = deletable;
    self.dictionary = [NSMutableDictionary new];
    
    return self;
}

+ (instancetype)menuItemNamed:(NSString *)name deletable:(BOOL)deletable
{
    return [[KEYPullDownMenuItem alloc] initWithName:name deletable:deletable];
}

- (NSString *)name
{
    return _name;
}

- (BOOL)deletable
{
    return _deletable;
}

@end

@implementation KEYPullDownMenuCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
    if (!self) return nil;
    
    self.textLabel.font = [UIFont boldSystemFontOfSize:23];
    self.textLabel.textColor = [UIColor whiteColor];
    self.textLabel.highlightedTextColor = [UIColor blackColor];
    self.tintColor = [UIColor whiteColor];
    
    return self;
}

@end
