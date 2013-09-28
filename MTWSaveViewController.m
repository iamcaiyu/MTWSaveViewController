//
//  MTWSaveViewController.m
//  Bokeh Camera
//
//  Created by CaiYu on 13-8-30.
//  Copyright (c) 2013年 Meituwan. All rights reserved.
//

#import "MTWSaveViewController.h"
#import <GADBannerView.h>
#import <Twitter/Twitter.h>
#import "ALAssetsLibrary+CustomPhotoAlbum.h"
#import "MGInstagram.h"
#import <Social/Social.h>
#import "Header.h"

@interface MTWSaveViewController () {
    IBOutlet __weak UIActivityIndicatorView *indicatorView;
    IBOutlet __weak UILabel *stateLabel;
    
    UIImage *processedImage;
    GADBannerView *bannerView;
    BOOL displayAdview;
    BOOL requestClose;
    BOOL requestOpenActionSheet;
    BOOL requestInstagram;
    BOOL hasDisplay;
}

@end

@implementation MTWSaveViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        requestClose=NO;
        displayAdview=NO;
        requestOpenActionSheet=NO;
        requestInstagram=NO;
        hasDisplay=NO;
        _saveDelayTime=3.0f;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    if (!self.bought) {
        bannerView=[[GADBannerView alloc]initWithAdSize:kGADAdSizeMediumRectangle];
        bannerView.center=CGPointMake(kScreenWidth/2.0f, kScreenHeight/2.0f);
        bannerView.adUnitID=self.admobPublishID;
        bannerView.rootViewController=self;
        bannerView.delegate=self;
        [self.view addSubview:bannerView];
        GADRequest *request=[GADRequest request];
        //request.testDevices = [NSArray arrayWithObjects:@"09f93dda5b568219e2fb957f52f21791", nil];
        [bannerView loadRequest:request];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[UIApplication sharedApplication]setStatusBarHidden:YES];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if (!hasDisplay) {
        hasDisplay=YES;
        UIActionSheet *actionSheet=[[UIActionSheet alloc]initWithTitle:@"Share" delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", @"ActionSheet Cancel") destructiveButtonTitle:nil otherButtonTitles:NSLocalizedString(@"Save to Photo Album", @"Save to Photo Album"), @"Instagram", @"Twitter", @"Facebook", nil];
        [actionSheet showInView:self.view];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)closeViewController
{
    requestClose=YES;
    if (!displayAdview) {
        [self dismissViewControllerAnimated:YES completion:nil];
        requestClose=NO;
    }
}

- (void)processImage
{
    processedImage=self.getFinalImage();
    sleep(self.saveDelayTime);
}

#pragma mark UIActionSheet Delegate
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    switch (buttonIndex) {
        case 0:
            [self shareToPhotoAlbum];
            break;
        case 1:
            [self shareToInstagram];
            break;
        case 2:
            [self shareToTwitter];
            break;
        case 3:
            [self shareToFacebook];
            break;
        case 4:
            [self closeViewController];
            break;
        default:
            break;
    }
}

#pragma mark ShareTo
- (void)shareToPhotoAlbum
{
    stateLabel.hidden=NO;
    indicatorView.hidden=NO;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self processImage];
        dispatch_async(dispatch_get_main_queue(), ^{
            stateLabel.text=@"Saving";
            ALAssetsLibrary *assetsLibrary=[[ALAssetsLibrary alloc]init];
            [assetsLibrary saveImage:processedImage withOrientation:processedImage.imageOrientation toAlbum:self.albumName withCompletionBlock:^(NSError *error){
                if (error) {
                    stateLabel.text=@"Save Failed";
                } else {
                    stateLabel.text=@"Save Success";
                }
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    sleep(2.0f);
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self closeViewController];
                    });
                });
            }];
        });
    });
}

- (void)shareToInstagram
{
    stateLabel.hidden=NO;
    indicatorView.hidden=NO;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self processImage];
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([MGInstagram isAppInstalled]&&[MGInstagram isImageCorrectSize:processedImage]) {
                [MGInstagram postImage:processedImage inView:self.view delegate:self];
            } else {
                stateLabel.text=@"Send Failed";
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    sleep(2.0f);
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self closeViewController];
                    });
                });
            }
        });
    });
}

- (void)shareToTwitter
{
    stateLabel.hidden=NO;
    indicatorView.hidden=NO;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self processImage];
        dispatch_async(dispatch_get_main_queue(), ^{
            SLComposeViewController *twitter=[SLComposeViewController composeViewControllerForServiceType:SLServiceTypeTwitter];
            [twitter addImage:processedImage];
            twitter.completionHandler=^(TWTweetComposeViewControllerResult result){
                [self dismissViewControllerAnimated:YES completion:^{
                    [self dismissViewControllerAnimated:YES completion:nil];
                }];
            };
            [self presentViewController:twitter animated:YES completion:nil];
        });
    });
}

- (void)shareToFacebook
{
    stateLabel.hidden=NO;
    indicatorView.hidden=NO;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self processImage];
        dispatch_async(dispatch_get_main_queue(), ^{
            SLComposeViewController *twitter=[SLComposeViewController composeViewControllerForServiceType:SLServiceTypeFacebook];
            [twitter addImage:processedImage];
            twitter.completionHandler=^(TWTweetComposeViewControllerResult result){
                [self dismissViewControllerAnimated:YES completion:^{
                    [self dismissViewControllerAnimated:YES completion:nil];
                }];
            };
            [self presentViewController:twitter animated:YES completion:nil];
        });
    });
}

- (void)adView:(GADBannerView *)view didFailToReceiveAdWithError:(GADRequestError *)error
{
    NSLog(@"%@",error);
}

- (void)adViewDidReceiveAd:(GADBannerView *)view
{
    NSLog(@"%@",NSStringFromSelector(_cmd));
}

- (void)adViewWillPresentScreen:(GADBannerView *)adView
{
    displayAdview=YES;
}

- (void)adViewDidDismissScreen:(GADBannerView *)adView
{
    if (requestClose) {
        self.view.userInteractionEnabled=NO;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            sleep(2);
            dispatch_async(dispatch_get_main_queue(), ^{
                [self dismissViewControllerAnimated:YES completion:nil];
            });
        });
    }
    if (requestOpenActionSheet) {
        UIActionSheet *actionSheet=[[UIActionSheet alloc]initWithTitle:@"Share" delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", @"ActionSheet Cancel") destructiveButtonTitle:nil otherButtonTitles:NSLocalizedString(@"Save to Photo Album", @"Save to Photo Album"), @"Twitter", @"Facebook", nil];
        [actionSheet showInView:self.view];
    }
    
    if (requestInstagram) {
        [MGInstagram postImage:processedImage inView:self.view delegate:self];
    }
    
    displayAdview=NO;
    requestClose=NO;
    requestOpenActionSheet=NO;
    requestInstagram=NO;
}

#pragma mark MGInstagram Delegate
- (void)mgMenuWillDismiss
{
    [self closeViewController];
}

- (void)mgMenuWillPresent
{
    NSLog(@"%@",NSStringFromSelector(_cmd));
    if (displayAdview) {
        requestInstagram=YES;
    }
}

@end
