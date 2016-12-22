//
//  APLViewController.swift
//  PhotoPicker
//
//  Created by 開発 on 2016/1/3.
//
//
/*
     File: APLViewController.h
     File: APLViewController.m
 Abstract: Main view controller for the application.
  Version: 2.0

 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
 Inc. ("Apple") in consideration of your agreement to the following
 terms, and your use, installation, modification or redistribution of
 this Apple software constitutes acceptance of these terms.  If you do
 not agree with these terms, please do not use, install, modify or
 redistribute this Apple software.

 In consideration of your agreement to abide by the following terms, and
 subject to these terms, Apple grants you a personal, non-exclusive
 license, under Apple's copyrights in this original Apple software (the
 "Apple Software"), to use, reproduce, modify and redistribute the Apple
 Software, with or without modifications, in source and/or binary forms;
 provided that if you redistribute the Apple Software in its entirety and
 without modifications, you must retain this notice and the following
 text and disclaimers in all such redistributions of the Apple Software.
 Neither the name, trademarks, service marks or logos of Apple Inc. may
 be used to endorse or promote products derived from the Apple Software
 without specific prior written permission from Apple.  Except as
 expressly stated in this notice, no other rights or licenses, express or
 implied, are granted by Apple herein, including but not limited to any
 patent rights that may be infringed by your derivative works or by other
 works in which the Apple Software may be incorporated.

 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
 MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
 THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
 FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
 OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.

 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
 OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
 MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
 AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
 STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.

 Copyright (C) 2013 Apple Inc. All Rights Reserved.

 */

import UIKit

@objc(APLViewController)
class APLViewController : UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    
    
    @IBOutlet weak var imageView: UIImageView!
    
    @IBOutlet weak var toolBar: UIToolbar!
    
    @IBOutlet weak var overlayView: UIView!
    @IBOutlet weak var takePictureButton: UIBarButtonItem!
    @IBOutlet weak var startStopButton: UIBarButtonItem!
    @IBOutlet weak var delayedPhotoButton: UIBarButtonItem!
    @IBOutlet weak var doneButton: UIBarButtonItem!
    
    var imagePickerController: UIImagePickerController?
    
    /*###weak*/ var cameraTimer: Timer?
    var capturedImages: [UIImage] = []
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.capturedImages = []
        
        if !UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.camera) {
            // There is not a camera on this device, so don't show the camera button.
            var toolbarItems = self.toolBar.items
            toolbarItems?.remove(at: 2)
            self.toolBar.setItems(toolbarItems, animated: false)
        }
    }
    
    
    @IBAction func showImagePickerForCamera(_: AnyObject) {
        self.showImagePickerForSourceType(UIImagePickerControllerSourceType.camera)
    }
    
    
    @IBAction func showImagePickerForPhotoPicker(_: AnyObject) {
        self.showImagePickerForSourceType(UIImagePickerControllerSourceType.photoLibrary)
    }
    
    
    fileprivate func showImagePickerForSourceType(_ sourceType: UIImagePickerControllerSourceType) {
        if self.imageView.isAnimating {
            self.imageView.stopAnimating()
        }
        
        if self.capturedImages.count > 0 {
            self.capturedImages.removeAll()
        }
        
        let imagePickerController = UIImagePickerController()
        imagePickerController.modalPresentationStyle = .currentContext
        imagePickerController.sourceType = sourceType
        imagePickerController.delegate = self
        
        if sourceType == .camera {
            /*
            The user wants to use the camera interface. Set up our custom overlay view for the camera.
            */
            imagePickerController.showsCameraControls = false
            
            /*
            Load the overlay view from the OverlayView nib file. Self is the File's Owner for the nib file, so the overlayView outlet is set to the main view in the nib. Pass that view to the image picker controller to use as its overlay view, and set self's reference to the view to nil.
            */
            Bundle.main.loadNibNamed("OverlayView", owner: self, options: nil)
            self.overlayView.frame = imagePickerController.cameraOverlayView!.frame
            imagePickerController.cameraOverlayView = self.overlayView;
            self.overlayView = nil;
        }
        
        self.imagePickerController = imagePickerController
        self.present(imagePickerController, animated: true, completion: nil)
    }
    
    
    //MARK: - Toolbar actions
    
    @IBAction func done(_: AnyObject) {
        // Dismiss the camera.
        if self.cameraTimer?.isValid ?? false {
            self.cameraTimer!.invalidate()
        }
        self.finishAndUpdate()
    }
    
    
    @IBAction func takePhoto(_: AnyObject) {
        self.imagePickerController?.takePicture()
    }
    
    
    @IBAction func delayedTakePhoto(_: AnyObject) {
        // These controls can't be used until the photo has been taken
        self.doneButton.isEnabled = false
        self.takePictureButton.isEnabled = false
        self.delayedPhotoButton.isEnabled = false
        self.startStopButton.isEnabled = false
        
        let fireDate = Date(timeIntervalSinceNow: 5.0)
        let cameraTimer = Timer(fireAt:fireDate, interval: 1.0, target: self, selector: #selector(APLViewController.timedPhotoFire(_:)), userInfo: nil, repeats: false)
        
        RunLoop.main.add(cameraTimer, forMode: RunLoopMode.defaultRunLoopMode)
        self.cameraTimer = cameraTimer;
    }
    
    
    @IBAction func startTakingPicturesAtIntervals(_: AnyObject) {
        /*
        Start the timer to take a photo every 1.5 seconds.
        
        CAUTION: for the purpose of this sample, we will continue to take pictures indefinitely.
        Be aware we will run out of memory quickly.  You must decide the proper threshold number of photos allowed to take from the camera.
        One solution to avoid memory constraints is to save each taken photo to disk rather than keeping all of them in memory.
        In low memory situations sometimes our "didReceiveMemoryWarning" method will be called in which case we can recover some memory and keep the app running.
        */
        self.startStopButton.title = NSLocalizedString("Stop", comment: "Title for overlay view controller start/stop button")
        self.startStopButton.action = #selector(APLViewController.stopTakingPicturesAtIntervals(_:))
        
        self.doneButton.isEnabled = false
        self.delayedPhotoButton.isEnabled = false
        self.takePictureButton.isEnabled = false
        
        self.cameraTimer = Timer.scheduledTimer(timeInterval: 1.5, target: self, selector: #selector(APLViewController.timedPhotoFire(_:)), userInfo: nil, repeats: true)
        self.cameraTimer!.fire() // Start taking pictures right away.
    }
    
    
    @IBAction func stopTakingPicturesAtIntervals(_: AnyObject) {
        // Stop and reset the timer.
        self.cameraTimer?.invalidate()
        self.cameraTimer = nil;
        
        self.finishAndUpdate()
    }
    
    
    fileprivate func finishAndUpdate() {
        self.dismiss(animated: true, completion: nil)
            
        if self.capturedImages.count > 0 {
            if self.capturedImages.count == 1 {
                // Camera took a single picture.
                self.imageView.image = self.capturedImages[0]
            } else {
                // Camera took multiple pictures; use the list of images for animation.
                self.imageView.animationImages = self.capturedImages
                self.imageView.animationDuration = 5.0    // Show each captured photo for 5 seconds.
                self.imageView.animationRepeatCount = 0   // Animate forever (show all photos).
                self.imageView.startAnimating()
            }
            
            // To be ready to start again, clear the captured images array.
            self.capturedImages.removeAll()
        }
        
        self.imagePickerController = nil;
    }
    
    
    //MARK: - Timer
    
    // Called by the timer to take a picture.
    @objc func timedPhotoFire(_ timer: Timer) {
        self.imagePickerController?.takePicture()
    }
    
    
    //MARK: - UIImagePickerControllerDelegate
    
    // This method is called when an image has been chosen from the library or taken from the camera.
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        let image = info[UIImagePickerControllerOriginalImage]! as! UIImage
        
        self.capturedImages.append(image)
        
        if self.cameraTimer?.isValid ?? false {
            return
        }
        
        self.finishAndUpdate()
    }
    
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        self.dismiss(animated: false/*true*/, completion: nil)
    }
    
    
}
