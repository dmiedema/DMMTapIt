//
//  DMMTapItAction.h
//  DMMTapItDemo
//
//  Created by Daniel on 3/30/15.
//  Copyright (c) 2015 Daniel Miedema. All rights reserved.
//

#import <Foundation/Foundation.h>
@import UIKit.UIColor;

typedef NS_ENUM(NSInteger, DMMTapItGameAction){
    DMMTapItGameActionTap,
    DMMTapItGameActionSwipe,
    DMMTapItGameActionWhip,
    DMMTapItGameActionCount
};
NSString * NSStringForDMMAction(DMMTapItGameAction action);

@interface DMMTapItAction : NSObject
@property (nonatomic                  ) DMMTapItGameAction gameAction;
@property (readonly, strong, nonatomic) UIColor *color;
@property (readonly, strong, nonatomic) NSString *actionString;

+ (instancetype)actionWithGameAction:(DMMTapItGameAction)gameAction;

+ (instancetype)generateRandomAction;
@end
