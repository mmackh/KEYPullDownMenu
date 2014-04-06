 //
//  KEYPullDownMenu.h
//  Keydown
//
//  Created by mmackh on 10/11/13.
//  Copyright (c) 2013 Maximilian Mackh. All rights reserved.
//

#import <UIKit/UIKit.h>

@class KEYPullDownMenuItem;

typedef void(^dismissBlock)(KEYPullDownMenuItem *item, NSInteger selectedRow);
typedef void(^reorderBlock)(KEYPullDownMenuItem *item, NSInteger targetIndex);
typedef void(^deleteBlock)(KEYPullDownMenuItem *item);

@interface KEYPullDownMenu : UIView

+ (instancetype)openMenuInViewController:(UIViewController *)viewController items:(NSArray *)menuItems  dismissBlock:dismissBlock reorderBlock:reorderBlock deleteBlock:deleteBlock;
+ (instancetype)dismissInViewController:(UIViewController *)viewController;

@end

@interface KEYPullDownMenuItem : NSObject

+ (instancetype)menuItemNamed:(NSString *)name deletable:(BOOL)deletable;

@property (nonatomic,readwrite, getter = isActive) BOOL active;
@property (nonatomic,readonly) NSString *name;
@property (nonatomic,readonly) BOOL deletable;
@property (nonatomic) NSMutableDictionary *dictionary;

@end
