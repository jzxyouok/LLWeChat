//
//  UITableView+LLExt.m
//  LLWeChat
//
//  Created by GYJZH on 8/9/16.
//  Copyright © 2016 GYJZH. All rights reserved.
//

#import "UITableView+LLExt.h"

@implementation UITableView (LLExt)

- (void)insertRowAtIndexPath:(NSIndexPath *)indexPath withRowAnimation:(UITableViewRowAnimation)animation {
    [self insertRowsAtIndexPaths:@[indexPath] withRowAnimation:animation];
}

- (void)insertRow:(NSUInteger)row inSection:(NSUInteger)section withRowAnimation:(UITableViewRowAnimation)animation {
    NSIndexPath *toInsert = [NSIndexPath indexPathForRow:row inSection:section];
    [self insertRowAtIndexPath:toInsert withRowAnimation:animation];
}



@end
