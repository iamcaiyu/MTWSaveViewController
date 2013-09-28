//
//  MTWSaveViewController.h
//  Bokeh Camera
//
//  Created by CaiYu on 13-8-30.
//  Copyright (c) 2013年 Meituwan. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GADBannerView.h>
#import "MGInstagram.h"

@interface MTWSaveViewController : UIViewController<GADBannerViewDelegate, UIActionSheetDelegate, MGInstagramDelegate>

@property (nonatomic, weak) UIImage *sourceImage;
@property BOOL bought;

@end
