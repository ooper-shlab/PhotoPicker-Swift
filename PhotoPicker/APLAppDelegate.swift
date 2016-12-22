//
//  APLAppDelegate.swift
//  PhotoPicker
//
//  Translated by OOPer in cooperation with shlab.jp, on 2016/1/3.
//
//
/*
 Copyright (C) 2016 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information

 Abstract:
 Standard application delegate.
 */

import UIKit

@UIApplicationMain
@objc(APLAppDelegate)
class APLAppDelegate: UIResponder, UIApplicationDelegate {
    
    // The app delegate must implement the window @property
    // from UIApplicationDelegate @protocol to use a main storyboard file.
    //
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        return true
    }
    
}
