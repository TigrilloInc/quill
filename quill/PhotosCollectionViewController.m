//
//  PhotosCollectionViewController.m
//  quill
//
//  Created by Alex Costantini on 3/18/15.
//  Copyright (c) 2015 chalk. All rights reserved.
//

#import "PhotosCollectionViewController.h"
#import "PhotosCollectionViewCell.h"
#import "AvatarButton.h"
#import "FirebaseHelper.h"
#import "PersonalSettingsViewController.h"
#import "MobileCoreServices/UTCoreTypes.h"

@implementation NSIndexSet (Convenience)
- (NSArray *)indexPathsFromIndexesWithSection:(NSUInteger)section {
    NSMutableArray *indexPaths = [NSMutableArray arrayWithCapacity:self.count];
    [self enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        [indexPaths addObject:[NSIndexPath indexPathForItem:idx inSection:section]];
    }];
    return indexPaths;
}
@end

@implementation UICollectionView (Convenience)
- (NSArray *)indexPathsForElementsInRect:(CGRect)rect {
    NSArray *allLayoutAttributes = [self.collectionViewLayout layoutAttributesForElementsInRect:rect];
    if (allLayoutAttributes.count == 0) { return nil; }
    NSMutableArray *indexPaths = [NSMutableArray arrayWithCapacity:allLayoutAttributes.count];
    for (UICollectionViewLayoutAttributes *layoutAttributes in allLayoutAttributes) {
        NSIndexPath *indexPath = layoutAttributes.indexPath;
        [indexPaths addObject:indexPath];
    }
    return indexPaths;
}
@end

@implementation PhotosCollectionViewController

static CGSize AssetGridThumbnailSize;

- (void)awakeFromNib {
    
    self.navigationItem.title = @"Select Avatar";
    
    UIBarButtonItem *photoItem = [[UIBarButtonItem alloc]
                                   initWithTitle: @"Take Photo"
                                   style: UIBarButtonItemStyleBordered
                                   target:self action:@selector(takePhoto)];
    [self.navigationItem setRightBarButtonItem:photoItem];
    
    self.collectionView.backgroundColor = [UIColor whiteColor];
    self.imageManager = [[PHCachingImageManager alloc] init];
    [self resetCachedAssets];
    [[PHPhotoLibrary sharedPhotoLibrary] registerChangeObserver:self];
}

-(void)viewWillAppear:(BOOL)animated {
    
    [super viewWillAppear:animated];
    
    logoImage = (UIImageView *)[self.navigationController.navigationBar viewWithTag:800];
    
    CGFloat scale = [UIScreen mainScreen].scale;
    CGSize cellSize = ((UICollectionViewFlowLayout *)self.collectionViewLayout).itemSize;
    AssetGridThumbnailSize = CGSizeMake(cellSize.width * scale, cellSize.height * scale);
}

-(void)viewDidAppear:(BOOL)animated {
    
    [super viewDidAppear:animated];
    [self updateCachedAssets];
    
    tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap)];
    
    [tapRecognizer setDelegate:self];
    [tapRecognizer setNumberOfTapsRequired:1];
    tapRecognizer.cancelsTouchesInView = NO;
    [self.view.window addGestureRecognizer:tapRecognizer];
}

-(void)viewWillDisappear:(BOOL)animated {
    
    [[PHPhotoLibrary sharedPhotoLibrary] unregisterChangeObserver:self];
    
    if ([self.navigationController.viewControllers indexOfObject:self]==NSNotFound) {
        
        logoImage.hidden = true;
        logoImage.frame = CGRectMake(155, 8, 32, 32);
        
        [self performSelector:@selector(showLogo) withObject:nil afterDelay:.3];
    }
    
    tapRecognizer.delegate = nil;
    [self.view.window removeGestureRecognizer:tapRecognizer];
}

-(void)showLogo {
    
    logoImage.alpha = 0;
    logoImage.hidden = false;
    
    [UIView animateWithDuration:.3 animations:^{
        logoImage.alpha = 1;
    }];
}

-(void) handleTap {
    
    if (tapRecognizer.state == UIGestureRecognizerStateEnded) {
        
        CGPoint location = [tapRecognizer locationInView:nil];
        CGPoint converted = [self.view convertPoint:CGPointMake(1024-location.y,location.x) fromView:self.view.window];
        
        if (!CGRectContainsPoint(self.view.frame, converted)){
            
            [tapRecognizer setDelegate:nil];
            [self.view.window removeGestureRecognizer:tapRecognizer];
            [self dismissViewControllerAnimated:YES completion:nil];
        }
        else {
            
            CGPoint loc = [tapRecognizer locationInView:self.collectionView];
                
            NSIndexPath *indexPath = [self.collectionView indexPathForItemAtPoint:loc];

            if (indexPath != nil) {
                
                PersonalSettingsViewController *settingsVC = self.navigationController.viewControllers[0];
                
                if (indexPath.item > 0) {
                    
                    PHAsset *asset = self.assetsFetchResults[indexPath.item-1];
                    [self.imageManager requestImageForAsset:asset
                                                 targetSize:AssetGridThumbnailSize
                                                contentMode:PHImageContentModeAspectFill
                                                    options:nil
                                              resultHandler:^(UIImage *result, NSDictionary *info) {
                                                  
                                                  if (result.size.height == 64) {
                                                      settingsVC.avatarImage = result;
                                                      settingsVC.imageChanged = true;
                                                      [self.navigationController popToRootViewControllerAnimated:YES];
                                                  }
                                              }];
                }
                else {
                    
                    settingsVC.avatarImage = nil;
                    [self.navigationController popToRootViewControllerAnimated:YES];
                }
            }
        }
    }
}

-(void) takePhoto {
    
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    picker.mediaTypes = @[(NSString *) kUTTypeImage];
    picker.sourceType = UIImagePickerControllerSourceTypeCamera;
    
    [self presentViewController:picker animated:YES completion:NULL];
}

#pragma mark - PHPhotoLibraryChangeObserver

- (void)photoLibraryDidChange:(PHChange *)changeInstance {
    
    // Call might come on any background queue. Re-dispatch to the main queue to handle it.
    dispatch_async(dispatch_get_main_queue(), ^{
        
        // check if there are changes to the assets (insertions, deletions, updates)
        PHFetchResultChangeDetails *collectionChanges = [changeInstance changeDetailsForFetchResult:self.assetsFetchResults];
        if (collectionChanges) {
            
            // get the new fetch result
            self.assetsFetchResults = [collectionChanges fetchResultAfterChanges];
            
            UICollectionView *collectionView = self.collectionView;
            
            if (![collectionChanges hasIncrementalChanges] || [collectionChanges hasMoves]) {
                // we need to reload all if the incremental diffs are not available
                [collectionView reloadData];
                
            } else {
                // if we have incremental diffs, tell the collection view to animate insertions and deletions
                [collectionView performBatchUpdates:^{
                    NSIndexSet *removedIndexes = [collectionChanges removedIndexes];
                    if ([removedIndexes count]) {
                        [collectionView deleteItemsAtIndexPaths:[removedIndexes indexPathsFromIndexesWithSection:0]];
                    }
                    NSIndexSet *insertedIndexes = [collectionChanges insertedIndexes];
                    if ([insertedIndexes count]) {
                        [collectionView insertItemsAtIndexPaths:[insertedIndexes indexPathsFromIndexesWithSection:0]];
                    }
                    NSIndexSet *changedIndexes = [collectionChanges changedIndexes];
                    if ([changedIndexes count]) {
                        [collectionView reloadItemsAtIndexPaths:[changedIndexes indexPathsFromIndexesWithSection:0]];
                    }
                } completion:NULL];
            }
            
            [self resetCachedAssets];
        }
    });
}

#pragma mark <UICollectionViewDataSource>

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {

    return self.assetsFetchResults.count+1;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    PhotosCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"PhotoCell" forIndexPath:indexPath];

    cell.userInteractionEnabled = true;
    
    [[cell.imageView viewWithTag:-1] removeFromSuperview];
    
    if (indexPath.item > 0) {
        
        // Increment the cell's tag
        NSInteger currentTag = cell.tag + 1;
        cell.tag = currentTag;
        
        PHAsset *asset = self.assetsFetchResults[indexPath.item-1];
        [self.imageManager requestImageForAsset:asset
                                     targetSize:AssetGridThumbnailSize
                                    contentMode:PHImageContentModeAspectFill
                                        options:nil
                                  resultHandler:^(UIImage *result, NSDictionary *info) {
                                      
                                      // Only update the thumbnail if the cell tag hasn't changed. Otherwise, the cell has been re-used.
                                      if (cell.tag == currentTag) {
                                          [cell.imageView setImage:result];
                                      }

                                  }];
    }
    else {
        
        AvatarButton *avatarButton = [AvatarButton buttonWithType:UIButtonTypeCustom];
        avatarButton.userID = [FirebaseHelper sharedHelper].uid;
        [avatarButton generateIdenticonWithShadow:true];
        avatarButton.identiconView.tag = -1;
        [cell.imageView setImage:avatarButton.imageView.image];
        [cell.imageView addSubview:avatarButton.identiconView];
        avatarButton.identiconView.transform = CGAffineTransformMakeScale(.51, .51);
        avatarButton.identiconView.center = CGPointMake(47.7,46);
    }
    
    return cell;
}

#pragma mark <UICollectionViewDelegate>

/*
// Uncomment this method to specify if the specified item should be highlighted during tracking
- (BOOL)collectionView:(UICollectionView *)collectionView shouldHighlightItemAtIndexPath:(NSIndexPath *)indexPath {
	return YES;
}
*/

/*
// Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
- (BOOL)collectionView:(UICollectionView *)collectionView shouldShowMenuForItemAtIndexPath:(NSIndexPath *)indexPath {
	return NO;
}

- (BOOL)collectionView:(UICollectionView *)collectionView canPerformAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
	return NO;
}

- (void)collectionView:(UICollectionView *)collectionView performAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
	
}
*/

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView{
    
    [self updateCachedAssets];
}

#pragma mark - Asset Caching

- (void)resetCachedAssets {
    
    [self.imageManager stopCachingImagesForAllAssets];
    self.previousPreheatRect = CGRectZero;
}

- (void)updateCachedAssets {
    
    BOOL isViewVisible = [self isViewLoaded] && [[self view] window] != nil;
    if (!isViewVisible) { return; }
    
    // The preheat window is twice the height of the visible rect
    CGRect preheatRect = self.collectionView.bounds;
    preheatRect = CGRectInset(preheatRect, 0.0f, -0.5f * CGRectGetHeight(preheatRect));
    
    // If scrolled by a "reasonable" amount...
    CGFloat delta = ABS(CGRectGetMidY(preheatRect) - CGRectGetMidY(self.previousPreheatRect));
    if (delta > CGRectGetHeight(self.collectionView.bounds) / 3.0f) {
        
        // Compute the assets to start caching and to stop caching.
        NSMutableArray *addedIndexPaths = [NSMutableArray array];
        NSMutableArray *removedIndexPaths = [NSMutableArray array];
        
        [self computeDifferenceBetweenRect:self.previousPreheatRect andRect:preheatRect removedHandler:^(CGRect removedRect) {
            NSArray *indexPaths = [self.collectionView indexPathsForElementsInRect:removedRect];
            [removedIndexPaths addObjectsFromArray:indexPaths];
            
        } addedHandler:^(CGRect addedRect) {
            
            NSArray *indexPaths = [self.collectionView indexPathsForElementsInRect:addedRect];
            [addedIndexPaths addObjectsFromArray:indexPaths];
        }];
        
        NSArray *assetsToStartCaching = [self assetsAtIndexPaths:addedIndexPaths];
        NSArray *assetsToStopCaching = [self assetsAtIndexPaths:removedIndexPaths];
        
        [self.imageManager startCachingImagesForAssets:assetsToStartCaching
                                            targetSize:AssetGridThumbnailSize
                                           contentMode:PHImageContentModeAspectFill
                                               options:nil];
        [self.imageManager stopCachingImagesForAssets:assetsToStopCaching
                                           targetSize:AssetGridThumbnailSize
                                          contentMode:PHImageContentModeAspectFill
                                              options:nil];
        
        self.previousPreheatRect = preheatRect;
    }
}

- (void)computeDifferenceBetweenRect:(CGRect)oldRect andRect:(CGRect)newRect removedHandler:(void (^)(CGRect removedRect))removedHandler addedHandler:(void (^)(CGRect addedRect))addedHandler {
    
    if (CGRectIntersectsRect(newRect, oldRect)) {
        
        CGFloat oldMaxY = CGRectGetMaxY(oldRect);
        CGFloat oldMinY = CGRectGetMinY(oldRect);
        CGFloat newMaxY = CGRectGetMaxY(newRect);
        CGFloat newMinY = CGRectGetMinY(newRect);
        if (newMaxY > oldMaxY) {
            CGRect rectToAdd = CGRectMake(newRect.origin.x, oldMaxY, newRect.size.width, (newMaxY - oldMaxY));
            addedHandler(rectToAdd);
        }
        if (oldMinY > newMinY) {
            CGRect rectToAdd = CGRectMake(newRect.origin.x, newMinY, newRect.size.width, (oldMinY - newMinY));
            addedHandler(rectToAdd);
        }
        if (newMaxY < oldMaxY) {
            CGRect rectToRemove = CGRectMake(newRect.origin.x, newMaxY, newRect.size.width, (oldMaxY - newMaxY));
            removedHandler(rectToRemove);
        }
        if (oldMinY < newMinY) {
            CGRect rectToRemove = CGRectMake(newRect.origin.x, oldMinY, newRect.size.width, (newMinY - oldMinY));
            removedHandler(rectToRemove);
        }
    } else {
        
        addedHandler(newRect);
        removedHandler(oldRect);
    }
}

- (NSArray *)assetsAtIndexPaths:(NSArray *)indexPaths {
    
    if (indexPaths.count == 0) { return nil; }
    
    NSMutableArray *assets = [NSMutableArray arrayWithCapacity:indexPaths.count];
    for (NSIndexPath *indexPath in indexPaths) {
        if (indexPath.item == 0) continue;
        PHAsset *asset = self.assetsFetchResults[indexPath.item-1];
        [assets addObject:asset];
    }
    return assets;
}

#pragma mark - UIImagePickerViewController Delegate

-(void) imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    
    UIImage *image = [info objectForKey:@"UIImagePickerControllerOriginalImage"];
    [FirebaseHelper sharedHelper].avatarImage = image;
    
    NSLog(@"size is %@", NSStringFromCGSize(image.size));
    
    [picker dismissViewControllerAnimated:YES completion:^{
        
        [self.navigationController popToRootViewControllerAnimated:YES];
    }];
}

#pragma mark - UIGestureRecognizer Delegate

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    return YES;
}

@end
