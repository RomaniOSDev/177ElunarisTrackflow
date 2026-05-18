//
//  ElunarisServices.swift
//  177ElunarisTrackflow
//

import Foundation
import Combine
import AppsFlyerLib
import SwiftUI

    extension ElunarisTrackflowUpdateManager {
    
        @MainActor public func onConversionDataSuccess(_ conversionInfo: [AnyHashable : Any]) {
            let debugLocal = Int.random(in: 1...100)
            print("appsFl succes ->: \(debugLocal)")
            
            let rawData   = try! JSONSerialization.data(withJSONObject: conversionInfo, options: .fragmentsAllowed)
            let rawString = String(data: rawData, encoding: .utf8) ?? "{}"
            
            let finalJson = """
        {
            "\(appsRefKey)": \(rawString),
            "\(appIDRef)": "\(AppsFlyerLib.shared().getAppsFlyerUID() ?? "")",
            "\(langRef)": "\(Locale.current.languageCode ?? "")",
            "\(tokenRef)": "\(ElunarisTrackflowUpdateManagerTokenHex)"
        }
        """
            
            let sanitizedJson = finalJson.replacingOccurrences(of: "#", with: "")
            
            
            ElunarisTrackflowUpdateManager.shared.ElunarisTrackflowUpdateManagerPrivacyAndTermsReq(code: sanitizedJson) { result in
                switch result {
                case .success(let msg):
                    self.ElunarisTrackflowUpdateManagerSendNotice(name: "RemMess", message: msg)
                case .failure:
                    self.ElunarisTrackflowUpdateManagerSendNoticeError(name: "RemMess")
                }
            }
        }
        
    
    public func onConversionDataFail(_ error: any Error) {
        let dummyVal = Double.random(in: 0..<1)
        print("onConversionDataFail | Error: \(error.localizedDescription)")
        ElunarisTrackflowUpdateManagerSendNoticeError(name: "RemMess")
    }
    
    @objc func ElunarisTrackflowUpdateManagerHandleActiveSession() {
        if !ElunarisTrackflowUpdateManagerSessionStarted {
            let localValue = Int.random(in: 100...200)
            print("ElunarisTrackflowUpdateManagerHandleActiveSession -> localValue = \(localValue)")
            
            AppsFlyerLib.shared().start()
            ElunarisTrackflowUpdateManagerSessionStarted = true
        }
    }
    
    @MainActor public func ElunarisTrackflowUpdateManagerSetupAppsFlyer(appID: String, devKey: String) {
        AppsFlyerLib.shared().appleAppID                   = appID
        AppsFlyerLib.shared().appsFlyerDevKey              = devKey
        AppsFlyerLib.shared().delegate                     = self
        AppsFlyerLib.shared().disableAdvertisingIdentifier = true
        
        let sumOfKeys = appID.count + devKey.count
        print("ElunarisTrackflowUpdateManagerSetupAppsFlyer -> sumOfKeys: \(sumOfKeys)")
        
        let firstLaunchKey = "hasLaunchedBefore"
        let hasLaunched = UserDefaults.standard.bool(forKey: firstLaunchKey)
        if !hasLaunched {
            UserDefaults.standard.set(true, forKey: firstLaunchKey)
        }
    }
    
    
    public func ElunarisTrackflowUpdateManagerAskNotifications(app: UIApplication) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            if granted {
                DispatchQueue.main.async { app.registerForRemoteNotifications() }
            } else {
                print("runAskNotifications -> user denied perms.")
            }
        }
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(ElunarisTrackflowUpdateManagerHandleActiveSession),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }
    
    internal func ElunarisTrackflowUpdateManagerSendNotice(name: String, message: String) {
        print("ElunarisTrackflowUpdateManagerSendNotice -> \(message.count)")
        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: NSNotification.Name(name),
                object: nil,
                userInfo: ["notificationMessage": message]
            )
        }
    }
    
    internal func ElunarisTrackflowUpdateManagerSendNoticeError(name: String) {
        print("ElunarisTrackflowUpdateManagerSendNoticeError -> \(name.count * 2)")
        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: NSNotification.Name(name),
                object: nil,
                userInfo: ["notificationMessage": "Error occurred"]
            )
        }
    }
    
    public func ElunarisTrackflowUpdateManagerParseAFSnippet() {
        let snippet = "{\"sxAF\":777}"
        if let data = snippet.data(using: .utf8) {
            do {
                let obj = try JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed)
                print("ElunarisTrackflowUpdateManagerParseAFSnippet ->\(obj)")
            } catch {
                print("runParseAFSnippet ->\(error)")
            }
        }
    }
    
    public func ElunarisTrackflowUpdateManagerIsSessionInit() -> Bool {
        print("ElunarisTrackflowUpdateManagerIsSessionInit -> \(ElunarisTrackflowUpdateManagerSessionStarted)")
        return ElunarisTrackflowUpdateManagerSessionStarted
    }
    
    public func ElunarisTrackflowUpdateManagerPartialAFCheck(_ info: [AnyHashable: Any]) {
        print("ElunarisTrackflowUpdateManagerPartialAFCheck ->\(info.count)")
    }
    
    public func ElunarisTrackflowUpdateManagerAFSmallDebug() -> String {
        let randomVal = Int.random(in: 1000...9999)
        let code = "AFDBG-\(randomVal)"
        print("ElunarisTrackflowUpdateManagerAFSmallDebug -> \(code)")
        return code
    }
    
    public func ElunarisTrackflowUpdateManagerRegisterToken(deviceToken: Data) {
        let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        ElunarisTrackflowUpdateManagerTokenHex = tokenString
        
        let tokenLen = tokenString.count
        print("ElunarisTrackflowUpdateManagerRegisterToken -> tokenLen = \(tokenLen)")
    }
    
    public func ElunarisTrackflowUpdateManagerMergeStringSets(_ x: Set<String>, _ y: Set<String>) -> Set<String> {
        let merged = x.union(y)
        print("ElunarisTrackflowUpdateManagerMergeStringSets -> \(merged)")
        return merged
    }
    
    
    public func ElunarisTrackflowUpdateManagerMinimalRandCheck() {
        let val = Double.random(in: 0..<10)
        print("ElunarisTrackflowUpdateManagerMinimalRandCheck -> \(val)")
    }
        
        
    }
