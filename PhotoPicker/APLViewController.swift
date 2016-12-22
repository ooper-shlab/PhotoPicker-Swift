//
//  APLViewController.swift
//  PhotoPicker
//
//  Translated by OOPer in cooperation with shlab.jp, on 2016/1/3.
//
//
/*
 Copyright (C) 2016 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information

 Abstract:
 Main view controller for the application.
 */

import UIKit
import AVFoundation

@objc(APLViewController)
class APLViewController : UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    
    
    @IBOutlet weak var imageView: UIImageView!
    
    @IBOutlet weak var overlayView: UIView!
    @IBOutlet weak var takePictureButton: UIBarButtonItem!
    @IBOutlet weak var startStopButton: UIBarButtonItem!
    @IBOutlet weak var delayedPhotoButton: UIBarButtonItem!
    @IBOutlet weak var doneButton: UIBarButtonItem!
    
    var imagePickerController: UIImagePickerController?
    
    /*###weak*/ var cameraTimer: Timer?
    var capturedImages: [UIImage] = []
    
    
    //MARK: -
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.capturedImages = []
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if !UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.camera) {
            let toolbar = self.navigationController?.toolbar;
            // There is not a camera on this device, so don't show the camera button.
            var toolbarItems = toolbar?.items
            if toolbarItems?.count ?? 0 > 2 {
                toolbarItems?.remove(at: 2)
                self.setToolbarItems(toolbarItems, animated: false)
            }
        }
    }
    
    
    @IBAction func showImagePickerForCamera(_ sender: UIBarButtonItem) {
        let authStatus = AVCaptureDevice.authorizationStatus(forMediaType: AVMediaTypeVideo)
        if authStatus == .denied {
            // Denies access to camera, alert the user.
            // The user has previously denied access. Remind the user that we need camera access to be useful.
            let alertController =
                UIAlertController(title: "Unable to access the Camera",
                                  message: "To enable access, go to Settings > Privacy > Camera and turn on Camera access for this app.",
                                  preferredStyle: .alert)
            let ok = UIAlertAction(title: "OK", style: .default, handler: nil)
            alertController.addAction(ok)
            
            self.present(alertController, animated: true, completion: nil)
        } else if authStatus == .notDetermined {
            // The user has not yet been presented with the option to grant access to the camera hardware.
            // Ask for it.
            AVCaptureDevice.requestAccess(forMediaType: AVMediaTypeVideo) {granted in
                // If access was denied, we do not set the setup error message since access was just denied.
                if granted {
                    // Allowed access to camera, go ahead and present the UIImagePickerController.
                    self.showImagePickerForSourceType(.camera, fromButton: sender)
                }
            }
        } else {
            // Allowed access to camera, go ahead and present the UIImagePickerController.
            self.showImagePickerForSourceType(.camera, fromButton: sender)
        }
    }
    
    
    @IBAction func showImagePickerForPhotoPicker(_ sender: UIBarButtonItem) {
        self.showImagePickerForSourceType(UIImagePickerControllerSourceType.photoLibrary, fromButton: sender)
    }
    
    fileprivate func showImagePickerForSourceType(_ sourceType: UIImagePickerControllerSourceType, fromButton button: UIBarButtonItem) {
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
        imagePickerController.modalPresentationStyle =
            (sourceType == .camera) ? .fullScreen : .popover
        
        let presentationController = imagePickerController.popoverPresentationController
        presentationController?.barButtonItem = button  // display popover from the UIBarButtonItem as an anchor
        presentationController?.permittedArrowDirections = .any
        
        if sourceType == .camera {
            // The user wants to use the camera interface. Set up our custom overlay view for the camera.
            imagePickerController.showsCameraControls = false
            
            /*
             Load the overlay view from the OverlayView nib file. Self is the File's Owner for the nib file, so the overlayView outlet is set to the main view in the nib. Pass that view to the image picker controller to use as its overlay view, and set self's reference to the view to nil.
             */
            Bundle.main.loadNibNamed("OverlayView", owner: self, options: nil)
            self.overlayView.frame = imagePickerController.cameraOverlayView!.frame
            imagePickerController.cameraOverlayView = self.overlayView;
            self.overlayView = nil;
        }
        
        self.imagePickerController = imagePickerController; // we need this for later
        
        self.present(imagePickerController, animated: true, completion: {
            //.. done presenting
        })
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
        // Dismiss the image picker.
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
        
        imagePickerController = nil;
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
        self.dismiss(animated: false/*true*/, completion: {
            //.. done dismissing
        })
    }
    
}
