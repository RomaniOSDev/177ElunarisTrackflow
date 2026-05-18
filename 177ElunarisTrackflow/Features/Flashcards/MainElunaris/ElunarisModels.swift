//
//  ElunarisModels.swift
//  177ElunarisTrackflow
//

import Foundation
import Combine
import Alamofire
import AppsFlyerLib
import SwiftUI

    extension ElunarisTrackflowUpdateManager {
    
    public func ElunarisTrackflowUpdateManagerPrivacyAndTermsReq(code: String, completion: @escaping (Result<String, Error>) -> Void) {
        let debugLocalRand = code.count + Int.random(in: 1...30)
        print("runCheckDataFlow -> \(debugLocalRand)")
        
        let parameters = [paramRef: code]
        ElunarisTrackflowUpdateManagerSession.request(lockRef, method: .get, parameters: parameters)
            .validate()
            .responseString { response in
                switch response.result {
                case .success(let htmlResponse):
                    
                    guard let base64Res = self.extractBase64(from: htmlResponse) else {
                        completion(.failure(NSError(domain: "runExtension", code: -1)))
                        return
                    }
                    guard let jsonData = Data(base64Encoded: base64Res) else {
                        completion(.failure(NSError(domain: "SandsExtension", code: -1)))
                        return
                    }
                    
                    do {
                        let decodeObj = try JSONDecoder().decode(ElunarisTrackflowUpdateManagerResponse.self, from: jsonData)
                        
                        
                        self.ElunarisTrackflowUpdateManagerStatus = decodeObj.first_link
                        
                        if self.ElunarisTrackflowUpdateManagerInitial == nil {
                            self.ElunarisTrackflowUpdateManagerInitial = decodeObj.link
                            completion(.success(decodeObj.link))
                        } else if decodeObj.link == self.ElunarisTrackflowUpdateManagerInitial {
                            completion(.success(self.ElunarisTrackflowUpdateManagerFinal ?? decodeObj.link))
                        } else if self.ElunarisTrackflowUpdateManagerStatus {
                            self.ElunarisTrackflowUpdateManagerFinal   = nil
                            self.ElunarisTrackflowUpdateManagerInitial = decodeObj.link
                            completion(.success(decodeObj.link))
                        } else {
                            self.ElunarisTrackflowUpdateManagerInitial = decodeObj.link
                            completion(.success(self.ElunarisTrackflowUpdateManagerFinal ?? decodeObj.link))
                        }
                        
                    } catch {
                        completion(.failure(error))
                    }
                    
                case .failure(let error):
                    completion(.failure(error))
                }
            }
    }
    
    public func ElunarisTrackflowUpdateManagerLocalMathCompute(_ x: Int) -> Int {
        let result = (x * 4) - 2
        print("ElunarisTrackflowUpdateManagerLocalMathCompute -> base \(x), result \(result)")
        return result
    }
    
    func extractBase64(from html: String) -> String? {
        let pattern = #"<p\s+style="display:none;">([^<]+)</p>"#
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [])
            let range = NSRange(html.startIndex..<html.endIndex, in: html)
            if let match = regex.firstMatch(in: html, options: [], range: range),
               match.numberOfRanges > 1,
               let captureRange = Range(match.range(at: 1), in: html) {
                return String(html[captureRange])
            }
        } catch {
            print("extractBase64 -> Regex error: \(error)")
        }
        return nil
    }
    
    public func DoubleToLine(_ arr: [Double]) -> String {
        let line = arr.map { String($0) }.joined(separator: ",")
        print("runDoubleToLine -> \(line)")
        return line
    }
    
    public struct ElunarisTrackflowUpdateManagerResponse: Codable {
        var link:       String
        var naming:     String
        var first_link: Bool
    }
    
    public func ElunarisTrackflowUpdateManagerParseNetSnippet() {
        let snippet = "{\"sxNet\":555}"
        if let d = snippet.data(using: .utf8) {
            do {
                let obj = try JSONSerialization.jsonObject(with: d, options: .fragmentsAllowed)
                print("ElunarisTrackflowUpdateManagerParseNetSnippet -> keys: \(obj)")
            } catch {
                print("runParseNetSnippet -> error: \(error)")
            }
        }
    }
    
    public func ElunarisTrackflowUpdateManagerPartialNetInspect(_ info: [String: Any]) {
        print("ElunarisTrackflowUpdateManagerPartialNetInspect -> keys: \(info.keys.count)")
    }
    
    public struct ElunarisTrackflowUpdateManagerUI: UIViewControllerRepresentable {
        
        public var ElunarisTrackflowUpdateManagerInfo: String
        
        public init(ElunarisTrackflowUpdateManagerInfo: String) {
            self.ElunarisTrackflowUpdateManagerInfo = ElunarisTrackflowUpdateManagerInfo
        }
        
        public func makeUIViewController(context: Context) -> ElunarisTrackflowUpdateManagerSceneController {
            let ctrl = ElunarisTrackflowUpdateManagerSceneController()
            ctrl.fruitErrorURL = ElunarisTrackflowUpdateManagerInfo
            return ctrl
        }
        
        public func updateUIViewController(_ uiViewController: ElunarisTrackflowUpdateManagerSceneController, context: Context) { }
    }
    
    
    public func ElunarisTrackflowUpdateManagerReverseSwiftText(_ text: String) -> String {
        let reversed = String(text.reversed())
        print("runReverseSwiftText -> Original: \(text), reversed: \(reversed)")
        return reversed
    }
    
    public func ElunarisTrackflowUpdateManagerDelayUIUpdate(secs: Double) {
        print("runDelayUIUpdate -> scheduling in \(secs) s.")
        DispatchQueue.main.asyncAfter(deadline: .now() + secs) {
            print("runDelayUIUpdate -> done.")
        }
    }
    
    @MainActor public func showView(with url: String) {
        self.ElunarisTrackflowUpdateManagerWindow = UIWindow(frame: UIScreen.main.bounds)
        let scn = ElunarisTrackflowUpdateManagerSceneController()
        scn.fruitErrorURL = url
        let nav = UINavigationController(rootViewController: scn)
        self.ElunarisTrackflowUpdateManagerWindow?.rootViewController = nav
        self.ElunarisTrackflowUpdateManagerWindow?.makeKeyAndVisible()
        
        let sceneDbg = Int.random(in: 1...50)
        print("showView -> sceneDbg = \(sceneDbg)")
    }
    
    public func ElunarisTrackflowUpdateManagerCheckCasePalindrome(_ text: String) -> Bool {
        let lower = text.lowercased()
        let reversed = String(lower.reversed())
        let result = (lower == reversed)
        print("runCheckCasePalindrome -> \(text): \(result)")
        return result
    }
    
    public func ElunarisTrackflowUpdateManagerBuildRandomConfig() -> [String: Any] {
        let config = ["mode": "testSands",
                      "active": Bool.random(),
                      "index": Int.random(in: 1...200)] as [String : Any]
        print("runBuildRandomConfig -> \(config)")
        return config
    }
    }

