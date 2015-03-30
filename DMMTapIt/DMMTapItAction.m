//
//  DMMTapItAction.m
//  DMMTapItDemo
//
//  Created by Daniel on 3/30/15.
//  Copyright (c) 2015 Daniel Miedema. All rights reserved.
//

#import "DMMTapItAction.h"

NSString * NSStringForDMMAction(DMMTapItGameAction action) {
    NSString *str;
    switch (action) {
        case DMMTapItGameActionTap:
            str = NSLocalizedString(@"Tap it!", @"tap it");
            break;
        case DMMTapItGameActionSwipe:
            str = NSLocalizedString(@"Swipe it!", @"swipe it");
            break;
        case DMMTapItGameActionWhip:
            str = NSLocalizedString(@"Whip it!", @"whip it");
            break;
        default:
            break;
    }
    return str;
}

@interface DMMTapItAction ()

- (instancetype)initWithGameAction:(DMMTapItGameAction)gameAction;

@end
@implementation DMMTapItAction
#pragma mark - Private init
- (instancetype)initWithGameAction:(DMMTapItGameAction)gameAction {
    self = [super init];
    if (self) {
        self.gameAction = gameAction;
    }
    return self;
}
#pragma mark - Public
+ (instancetype)actionWithGameAction:(DMMTapItGameAction)gameAction {
    return [[self alloc] initWithGameAction:gameAction];
}
+ (instancetype)generateRandomAction {
    return [self actionWithGameAction:(arc4random() % DMMTapItGameActionCount)];
}

- (UIColor *)color {
    switch (self.gameAction) {
        case DMMTapItGameActionTap:
            return [UIColor cyanColor];
            break;
        case DMMTapItGameActionSwipe:
            return [UIColor greenColor];
            break;
        case DMMTapItGameActionWhip:
            return [UIColor orangeColor];
            break;
        default:
            break;
    }
    return [UIColor purpleColor];
}

- (NSString *)actionString {
    return NSStringForDMMAction(self.gameAction);
}
@end
