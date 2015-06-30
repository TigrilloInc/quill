//
//  PhotosCollectionViewController.h
//  quill
//
//  Created by Alex Costantini on 3/18/15.
//  Copyright (c) 2015 Tigrillo. All rights reserved.
//

#import <UIKit/UIKit.h>

@import Photos;

@interface PhotosCollectionViewController : UICollectionViewController <PHPhotoLibraryChangeObserver, UIGestureRecognizerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate> {
    
    UIImageView *logoImage;
    UITapGestureRecognizer *tapRecognizer;
}

@property (strong) PHFetchResult *assetsFetchResults;
@property (strong) PHAssetCollection *assetCollection;
@property (strong) PHCachingImageManager *imageManager;
@property CGRect previousPreheatRect;

@end
