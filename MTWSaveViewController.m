//
//  MTWSaveViewController.m
//  Bokeh Camera
//
//  Created by CaiYu on 13-8-30.
//  Copyright (c) 2013年 Meituwan. All rights reserved.
//

#import "MTWSaveViewController.h"
#import <GADBannerView.h>
#import "Header.h"
#import <Twitter/Twitter.h>
#import <FacebookSDK/FacebookSDK.h>
#import "ALAssetsLibrary+CustomPhotoAlbum.h"
#import "CAICreateThumbImage.h"
#import "MGInstagram.h"

@interface MTWSaveViewController () {
    IBOutlet __weak UIActivityIndicatorView *indicatorView;
    IBOutlet __weak UILabel *stateLabel;
    
    UIImage *processedImage;
    GADBannerView *bannerView;
    BOOL displayAdview;
    BOOL requestClose;
    BOOL requestOpenActionSheet;
    BOOL requestInstagram;
    
    BOOL firstDisplay;
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
        firstDisplay=YES;
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
        bannerView.adUnitID=kAdmobPublishID;
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
    if (firstDisplay) {
        firstDisplay=NO;
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
    processedImage=[CAICreateThumbImage createThumbImage:self.sourceImage size:CGSizeMake(900.0f, 900.0f)];
    if (!self.bought) {
        sleep(3);
    }
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
            [assetsLibrary saveImage:processedImage withOrientation:processedImage.imageOrientation toAlbum:@"Bokeh Camera" withCompletionBlock:^(NSError *error){
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
            TWTweetComposeViewController *twitter=[[TWTweetComposeViewController alloc]init];
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
    if (!FBSession.activeSession.isOpen) {
        [FBSession openActiveSessionWithPublishPermissions:[NSArray arrayWithObject:@"publish_actions"] defaultAudience:FBSessionDefaultAudienceFriends allowLoginUI:YES completionHandler:^(FBSession *session, FBSessionState status, NSError *error) {
            if (!FBSession.activeSession.isOpen) {
                stateLabel.text=@"Login Failed";
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    sleep(2.0f);
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self closeViewController];
                    });
                });
            } else {
                [self sendImageToFacebook];
            }
        }];
    } else {
        [self sendImageToFacebook];
    }
}

- (void)sendImageToFacebook
{
    stateLabel.hidden=NO;
    indicatorView.hidden=NO;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self processImage];
        dispatch_async(dispatch_get_main_queue(), ^{
            stateLabel.text=@"Sending";
            [self performPublishAction:^{
                [FBRequestConnection startForUploadPhoto:processedImage completionHandler:^(FBRequestConnection *connection, id result, NSError *error){
                    if (error) {
                        stateLabel.text=@"Send Failed";
                    } else {
                        stateLabel.text=@"Send Success";
                    }
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                        sleep(2.0f);
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [self closeViewController];
                        });
                    });
                }];
            }];
        });
    });
}

- (void)performPublishAction:(void (^)(void)) action
{
    if ([FBSession.activeSession.permissions indexOfObject:@"publish_actions"]==NSNotFound) {
        [FBSession.activeSession requestNewPublishPermissions:[NSArray arrayWithObject:@"publish_actions"] defaultAudience:FBSessionDefaultAudienceFriends completionHandler:^(FBSession *session, NSError *error){
            if (!error) {
                action();
            }
        }];
    } else {
        action();
    }
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
