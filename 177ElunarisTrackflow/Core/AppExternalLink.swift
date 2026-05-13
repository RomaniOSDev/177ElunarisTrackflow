//
//  AppExternalLink.swift
//  177ElunarisTrackflow
//

import Foundation

enum AppExternalLink {
    case privacyPolicy
    case termsOfUse

    var urlString: String {
        switch self {
        case .privacyPolicy:
            return "https://elunaristrackflow177.site/privacy/182"
        case .termsOfUse:
            return "https://elunaristrackflow177.site/terms/182"
        }
    }

    var url: URL? {
        URL(string: urlString)
    }
}
