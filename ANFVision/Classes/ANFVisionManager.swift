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
    
    public static func scan(image: UIImage, onComplete: @escaping TextScanCompletionHandler) {
        
        guard let cgImage = image.cgImage else {
            onComplete(.failure(
                NSError(domain: "Could not create the CGImage", code: 100, userInfo: nil)
            ))
            return
        }
        
        let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        let request = VNRecognizeTextRequest { req, error in
            
            guard error == nil else {
                onComplete(.failure(error!))
                return
            }
            
            guard let observationArr = req.results as? [VNRecognizedTextObservation], error == nil else {
                onComplete(.failure(
                    NSError(domain: "Could not create the CGImage", code: 101, userInfo: nil)
                ))
                return
            }
            
            var extractedText: [String] = [String]()
            
            for single in observationArr {
                
                let arr = single.topCandidates(10)
                
                for i in 0..<arr.count {
                    
                    if arr[i].confidence >= 0.5 {
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
                NSError(domain: "Invalid image", code: 102, userInfo: nil)
            ))
            return
        }

        let base64Str = imageData.base64EncodedString(options: .endLineWithCarriageReturn)
        if base64Str.count == 0 {
            onComplete(.failure(
                NSError(domain: "Invalid image", code: 102, userInfo: nil)
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
                                    onComplete(.success(.moreThanOneFaceDetected))
                                }
                                else {
                                    onComplete(.success(.ok(image)))
                                }
                            }
                            else {
                                onComplete(.success(.noFaceDetected))
                            }
                        }
                        else {
                            onComplete(.success(.noFaceDetected))
                        }
                    }
                    
                case .failure(let error):
                    onComplete(.failure(error))
            }
            
        }
       
    }
}
