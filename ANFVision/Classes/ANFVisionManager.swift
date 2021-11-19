//
//  ANFVisionManager.swift
//  ANFVision
//
//  Created by Anthony Niroshan Fernandez on 16/11/2021.
//

import Foundation
import UIKit
import Vision

public enum finalResponse {
    case noFaceDetected
    case moreThanOneFaceDetected
    case ok(UIImage)
}

public typealias TextScanCompletionHandler = (Result<[String], Error>) -> Void
public typealias FaceScanCompletionHandler = (Result<finalResponse, Error>) -> Void

public class ANFVisionManager {
    
    private static let GOOGLE_VISION_API = "https://vision.googleapis.com/v1/images:annotate"
    
    public static func scanText(image: UIImage, confidence: Float, onComplete: @escaping TextScanCompletionHandler) {
        
        guard let cgImage = image.cgImage else {
            onComplete(.failure(
                NSError(domain: "", code: 100, userInfo: [NSLocalizedDescriptionKey: "Could not create the CGImage"])
            ))
            return
        }
        
        let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        let request = VNRecognizeTextRequest { res, error in
            
            guard error == nil else {
                
                DispatchQueue.main.async {
                    onComplete(.failure(error!))
                }
                return
            }
            
            guard let observationArr = res.results as? [VNRecognizedTextObservation], error == nil else {
                
                DispatchQueue.main.async {
                    
                    onComplete(.failure(
                        NSError(domain: "", code: 101, userInfo: [NSLocalizedDescriptionKey: "Invalid response received from server"])
                    ))
                }
                return
            }
            
            var extractedText: [String] = [String]()
            
            for single in observationArr {
                
                let arr = single.topCandidates(10)
                
                for i in 0..<arr.count {
                    
                    if arr[i].confidence >= confidence {
                        extractedText.append(arr[i].string)
                        break
                    }
                }
            }

            DispatchQueue.main.async {
                onComplete(.success(extractedText))
            }
        }
        
        //Processss request
        do {
            try requestHandler.perform([request])
        } catch(let e) {
            onComplete(.failure(e))
        }
    }
    
    public static func detectFace(image: UIImage, apiKey: String, onComplete: @escaping FaceScanCompletionHandler) {
        
        guard let imageData = image.jpegData(compressionQuality: 1) else {
            onComplete(.failure(
                NSError(domain: "", code: 102, userInfo: [NSLocalizedDescriptionKey: "Invalid image"])
            ))
            return
        }

        let base64Str = imageData.base64EncodedString(options: .endLineWithCarriageReturn)
        if base64Str.count == 0 {
            onComplete(.failure(
                NSError(domain: "", code: 102, userInfo: [NSLocalizedDescriptionKey: "Invalid image"])
            ))
            return
        }

        let jsonBody = "{ 'requests': [ { 'image': { 'content': '\(base64Str)' }, 'features': [ { 'maxResults': 10, 'type': 'FACE_DETECTION' } ] } ] }"
        let jsonBodyData = jsonBody.data(using: .utf8)
        
        let url = GOOGLE_VISION_API + "?key=" + apiKey
        
        let networkManager: ANFNetworkManger = ANFNetworkManger()
        networkManager.fetch(urlString: url, body: jsonBodyData) { result in

            switch result {
                case .success(let data):
                    
                    if let response = data["responses"] as? [Any] {

                        if let data = response.first as? [String: Any], !data.isEmpty {
                            
                            if let faces = data["faceAnnotations"] as? [[String: Any]] {
                                
                                if faces.count > 1 {
                                    
                                    DispatchQueue.main.async {
                                        onComplete(.success(.moreThanOneFaceDetected))
                                    }
                                }
                                else {
                                    
                                    DispatchQueue.main.async {
                                        onComplete(.success(.ok(image)))
                                    }
                                }
                            }
                            else {
                                
                                DispatchQueue.main.async {
                                    onComplete(.success(.noFaceDetected))
                                }
                            }
                        }
                        else {
                            
                            DispatchQueue.main.async {
                                onComplete(.success(.noFaceDetected))
                            }
                        }
                    }
                    
            case .failure(let netError):
                
                let finalError = getErrorForNetworkError(networkError: netError)

                DispatchQueue.main.async {
                    onComplete(.failure(finalError))
                }
            }
            
        }
    }
    
    private static func getErrorForNetworkError(networkError: NetworkError) -> Error {
        
        switch networkError {
            case .notConnectedToInternet:
                return NSError(domain: "", code: 103, userInfo: [NSLocalizedDescriptionKey: "Not connected to internet"])
            case .invalidUrl:
                return NSError(domain: "", code: 104, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
            case .invalidResponse:
                return NSError(domain: "", code: 105, userInfo: [NSLocalizedDescriptionKey: "Invalid Response"])
            case .serverError:
                return NSError(domain: "", code: 106, userInfo: [NSLocalizedDescriptionKey: "Server Error"])
            case .unknownError:
                return NSError(domain: "", code: 107, userInfo: [NSLocalizedDescriptionKey: "Unknown error"])
            case .other(let e):
                return NSError(domain: "", code: 108, userInfo: [NSLocalizedDescriptionKey: e.localizedDescription])
        }
    }
}
