//
//  ANFNetworkManger.swift
//  ANFVision
//
//  Created by Anthony Niroshan Fernandez on 17/11/2021.
//

import Foundation

public enum NetworkOperationError: Error {
    case cancelled
    case notConnectedToInternet
    case invalidUrl
    case invalidResponse
    case serverError
    case other(Error?)
}

public typealias NetworkOperationCompletionHandler = (Result<[String: Any], NetworkOperationError>) -> Void

public class ANFNetworkManger {
    
    private var session = URLSession.shared
    private var task: URLSessionDataTask?
    
    func fetch(urlString: String, body: Data?, completionHandler: @escaping NetworkOperationCompletionHandler) {
        
        guard let url = URL(string: urlString) else {
            completionHandler(.failure(.invalidUrl))
            return
        }
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let requestBody = body {
            urlRequest.httpBody = requestBody
        }
        
        task = session.dataTask(with: urlRequest, completionHandler: { data, response, error in
            
            //Handdle error
            if let error = error {
                
                DispatchQueue.main.async {
                    
                    if let urlError = error as? URLError, urlError.code == .notConnectedToInternet {
                        completionHandler(.failure(.notConnectedToInternet))
                    } else {
                        completionHandler(.failure(.other(error)))
                    }
                }
                return
            }
            
            //Handdle response issues
            if let urlResponse = response as? HTTPURLResponse, urlResponse.statusCode != 200 {
        
                DispatchQueue.main.async {
                    completionHandler(.failure(.serverError))
                }
                return
            }
            
            //All ok so process the data
            if let data = data {
                
                do {
                    let responseJSON = try JSONSerialization.jsonObject(with: data, options: [.allowFragments])
                    if let decodedObject = responseJSON as? [String: Any] {
                        
                        DispatchQueue.main.async {
                            completionHandler(.success(decodedObject))
                        }
                    }
                    else {
                        DispatchQueue.main.async {
                            completionHandler(.failure(.invalidResponse))
                        }
                    }
                    
                    return
                    
                } catch let error {

                    DispatchQueue.main.async {
                        completionHandler(.failure(.other(error)))
                    }
                    return
                }
            }
            
            // for handling annonymous errors
            DispatchQueue.main.async {
                completionHandler(.failure(.other(nil)))
            }
        })
        
        task?.resume()
    }
}
