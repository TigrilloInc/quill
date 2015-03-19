//
//  PhotosCollectionViewController.h
//  quill
//
//  Created by Alex Costantini on 3/18/15.
//  Copyright (c) 2015 chalk. All rights reserved.
//

#import <UIKit/UIKit.h>

@import Photos;

@interface PhotosCollectionViewController : UICollectionViewController <PHPhotoLibraryChangeObserver, UIGestureRecognizerDelegate> {
    
    UIImageView *logoImage;
    UITapGestureRecognizer *outsideTapRecognizer;
}

@property (strong) PHFetchResult *assetsFetchResults;
@property (strong) PHAssetCollection *assetCollection;
@property (strong) PHCachingImageManager *imageManager;
@property CGRect previousPreheatRect;

@end
