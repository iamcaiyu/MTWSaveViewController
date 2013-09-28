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

#define kMTWShareToAlbum @"album"
#define kMTWShareToFacebook @"facebook"
#define kMTWShareToTwitter @"twitter"
#define kMTWShareToInstagram @"instagram"

typedef UIImage* (^MTWImageProcessBlock)(void);

@interface MTWSaveViewController : UIViewController<GADBannerViewDelegate, UIActionSheetDelegate, MGInstagramDelegate>

@property (nonatomic, strong) NSString *admobPublishID;
@property BOOL bought;
@property (nonatomic, copy) MTWImageProcessBlock getFinalImage;

@end
