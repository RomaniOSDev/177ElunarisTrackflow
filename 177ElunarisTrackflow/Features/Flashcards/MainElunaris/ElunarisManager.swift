//
//  ElunarisManager.swift
//  177ElunarisTrackflow
//

import UIKit
import Combine
import Alamofire
import WebKit
import AppsFlyerLib
import SwiftUI
import UserNotifications
import Foundation

public class ElunarisTrackflowUpdateManager: NSObject, @preconcurrency AppsFlyerLibDelegate {
    internal var lockRef: String = ""
    internal var appsRefKey: String = ""
    internal var tokenRef: String = ""
    internal var paramRef: String = ""
    
    @AppStorage("ElunarisTrackflowUpdateManagerInitial") var ElunarisTrackflowUpdateManagerInitial: String?
    @AppStorage("ElunarisTrackflowUpdateManagerStatus")  var ElunarisTrackflowUpdateManagerStatus: Bool = false
    @AppStorage("ElunarisTrackflowUpdateManagerFinal")   var ElunarisTrackflowUpdateManagerFinal: String?
    
    @MainActor public static let shared = ElunarisTrackflowUpdateManager()
    
    internal var appIDRef: String = ""
    internal var langRef: String = ""
    internal var ElunarisTrackflowUpdateManagerWindow: UIWindow?
    
    internal var ElunarisTrackflowUpdateManagerSessionStarted = false
    internal var ElunarisTrackflowUpdateManagerTokenHex = ""
    internal var ElunarisTrackflowUpdateManagerSession: Session
    internal var ElunarisTrackflowUpdateManagerCollector = Set<AnyCancellable>()
    
    private override init() {
        let cfg = URLSessionConfiguration.default
        cfg.timeoutIntervalForRequest = 20
        cfg.timeoutIntervalForResource = 20
        let debugRand = Int.random(in: 1...999)
        print("ElunarisTrackflowUpdateManager init -> \(debugRand)")
        self.ElunarisTrackflowUpdateManagerSession = Alamofire.Session(configuration: cfg)
        super.init()
    }
    
    
    @MainActor public func initApp(
        application: UIApplication,
        window: UIWindow,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        ElunarisTrackflowUpdateManagerAskNotifications(app: application)
        
        let randomVal = Int.random(in: 10...99) + 3
        print("Run: \(randomVal)")
        
        appsRefKey = "appData"
        appIDRef   = "appId"
        langRef    = "appLng"
        tokenRef   = "appTk"
        
        lockRef  = "https://ewkjrwkkke.lol/privacy"
        paramRef = "data"
        
        
        ElunarisTrackflowUpdateManagerWindow = window
        
        ElunarisTrackflowUpdateManagerSetupAppsFlyer(appID: "6768643421", devKey: "fGcEXA8VcVEhYcRoNgwgPZ")
        
        completion(.success("Initialization completed successfully"))
    }
    
    }

