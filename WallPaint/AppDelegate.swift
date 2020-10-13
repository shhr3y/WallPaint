//
//  AppDelegate.swift
//  WallPaint
//
//  Created by Shrey Gupta on 31/08/20.
//  Copyright © 2020 Shrey Gupta. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        window?.makeKeyAndVisible()
        let nav = UINavigationController(rootViewController: MainController())
        window?.rootViewController = nav
        
        return true
    }



}

