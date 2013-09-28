//
//  MGInstagram.m
//  MGInstagramDemo
//
//  Created by Mark Glagola on 10/20/12.
//  Copyright (c) 2012 Mark Glagola. All rights reserved.
//

#import "MGInstagram.h"

@interface MGInstagram ()
{
    UIDocumentInteractionController *documentInteractionController;
    void (^completion)(void);
    id<MGInstagramDelegate> mgDelegate;
}

+ (MGInstagram *)sharedInstance;

@end

@implementation MGInstagram

NSString* const kInstagramAppURLString = @"instagram://app";
NSString* const kInstagramPhotoFileName = @"tempinstgramphoto.igo";

+ (MGInstagram *)sharedInstance
{
    static MGInstagram* sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[MGInstagram alloc] init];
    });
    return sharedInstance;
}

+ (BOOL) isAppInstalled
{
    NSURL *appURL = [NSURL URLWithString:@"instagram://app"];
    return [[UIApplication sharedApplication] canOpenURL:appURL];
}

+ (BOOL) isImageCorrectSize:(UIImage*)image
{
    return (image.size.width >= 612 && image.size.height >= 612);
}

- (NSString*) photoFilePath
{
    return [NSString stringWithFormat:@"%@/%@",[NSHomeDirectory() stringByAppendingPathComponent:@"Documents"],kInstagramPhotoFileName];
}

+ (void) postImage:(UIImage*)image inView:(UIView*)view
{
    [[MGInstagram sharedInstance] postImage:image withCaption:nil inView:view];
}
+ (void) postImage:(UIImage*)image withCaption:(NSString*)caption inView:(UIView*)view
{
    [[MGInstagram sharedInstance] postImage:image withCaption:caption inView:view];
}
+ (void) postImage:(UIImage *)image inView:(UIView *)view completionBlock:(void (^)(void))completionBlock
{
    [[MGInstagram sharedInstance] postImage:image inView:view completionBlock:completionBlock];
}
+ (void) postImage:(UIImage *)image inView:(UIView *)view delegate:(id<MGInstagramDelegate>)delegate
{
    [[MGInstagram sharedInstance] postImage:image inView:view delegate:delegate];
}

- (id)init
{
    self=[super init];
    if (self) {
        completion=NULL;
        mgDelegate=nil;
    }
    return self;
}

- (void) postImage:(UIImage*)image withCaption:(NSString*)caption inView:(UIView*)view
{
    if (!image)
        [NSException raise:NSInternalInconsistencyException format:@"Image cannot be nil!"];
    if (![MGInstagram isImageCorrectSize:image])
        [NSException raise:NSInternalInconsistencyException format:@"INSTAGRAM IMAGE IS TOO SMALL! Instagram only takes images with dimensions 612x612 and larger. Use isImageCorrectSize: to make sure image is the correct size"];
    
    [UIImageJPEGRepresentation(image, 1.0) writeToFile:[self photoFilePath] atomically:YES];
    
    NSURL *fileURL = [NSURL fileURLWithPath:[self photoFilePath]];
    documentInteractionController = [UIDocumentInteractionController interactionControllerWithURL:fileURL];
    documentInteractionController.UTI = @"com.instagram.exclusivegram";
    documentInteractionController.delegate = self;
    if (caption)
        documentInteractionController.annotation = [NSDictionary dictionaryWithObject:caption forKey:@"InstagramCaption"];
    [documentInteractionController presentOpenInMenuFromRect:CGRectZero inView:view animated:YES];
}

- (void) postImage:(UIImage *)image inView:(UIView *)view completionBlock:(void (^)(void))completionBlock
{
    [self postImage:image withCaption:nil inView:view];
    completion=completionBlock;
}

- (void) postImage:(UIImage *)image inView:(UIView *)view delegate:(id<MGInstagramDelegate>)delegate
{
    mgDelegate=delegate;
    [self postImage:image withCaption:nil inView:view];
}

- (void)documentInteractionControllerDidDismissOpenInMenu:(UIDocumentInteractionController *)controller
{
    if (completion!=NULL) {
        completion();
    }
    if ([mgDelegate respondsToSelector:@selector(mgMenuWillDismiss)]) {
        [mgDelegate mgMenuWillDismiss];
    }
}

- (void)documentInteractionControllerWillPresentOpenInMenu:(UIDocumentInteractionController *)controller
{
    if ([mgDelegate respondsToSelector:@selector(mgMenuWillPresent)]) {
        [mgDelegate mgMenuWillPresent];
    }
}

@end
