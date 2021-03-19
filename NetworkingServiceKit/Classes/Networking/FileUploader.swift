//
//  FileUploader.swift
//  NetworkingServiceKit
//
//  Created by Leandro Perez on 18/03/2021.
//

import Foundation
// Approach from https://www.swiftbysundell.com/articles/http-post-and-file-upload-requests-using-urlsession/

/// `FileUploader` uses `URLSessionUploadTask` and `URLSession` directly, it can be used with a `URLSessionConfiguration`, so yo can configure it with a background session
class FileUploader: NSObject {
    static var shared = FileUploader(configuration: .backgroundWithPrefixIdentifier())
    
    typealias Percentage = Double
    typealias ProgressHandler = (Percentage) -> Void
    typealias CompletionHandler = (Result<Void, Error>) -> Void
    
    private var progressHandlersByTaskID = [Int : (progress:ProgressHandler, completion: CompletionHandler)]()
    
    private let configuration : URLSessionConfiguration
    
    private init(configuration: URLSessionConfiguration = .default,
                  progressHandlersByTaskID: [Int : (progress:ProgressHandler, completion: CompletionHandler)] = [:]) {
        self.configuration = configuration
        self.progressHandlersByTaskID = progressHandlersByTaskID
    }
    
    
    private lazy var urlSession = URLSession(configuration: configuration,
                                             delegate: self,
                                             delegateQueue: .main)
    
    func upload(data: Data,
                to targetURL: URL,
                dispatchQueue : DispatchQueue = .main,
                progressHandler: @escaping ProgressHandler,
                completionHandler: @escaping CompletionHandler) {
        
        var request = URLRequest(url: targetURL,
                                 cachePolicy: .reloadIgnoringLocalCacheData)
        
        if let imageURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first?
            .appendingPathComponent(targetURL.lastPathComponent)
            .appendingPathComponent("\(Int.random(in: 1...100000000))") {
            do {
                try data.write(to: imageURL)
                let task = urlSession.uploadTask( with: request, fromFile: imageURL)
                progressHandlersByTaskID[task.taskIdentifier] = (progressHandler, completionHandler)
                task.resume()
            } catch let error {
                completionHandler(.failure(error))
            }
        } else {
            
            request.httpMethod = "POST"
            
            let task = urlSession.uploadTask(with: request, from: data)
            progressHandlersByTaskID[task.taskIdentifier] = (progressHandler, completionHandler)
            task.resume()
        }
        
        
        
    }
    
    private func handler(dispatchQueue : DispatchQueue = .main, completionHandler: @escaping CompletionHandler) -> (Data?, URLResponse?, Error?) -> Void {
        { data, resp, err in
            if let err = err {
                dispatchQueue.async {
                    completionHandler(.failure(err))
                }
                
                return
            }
            
            guard let h = resp as? HTTPURLResponse else {
                dispatchQueue.async {
                    completionHandler(.failure(UnknownError()))
                }
                return
            }
            
            guard expected200to300(h.statusCode) else {
                dispatchQueue.async {
                    completionHandler(.failure(WrongStatusCodeError(statusCode: h.statusCode, response: h, responseBody: data)))
                }
                return
            }
            
            dispatchQueue.async {
                completionHandler(.success(()))
            }
        }
    }
    
    func uploadFile( at fileURL: URL,
                     to targetURL: URL,
                     dispatchQueue : DispatchQueue = .main,
                     progressHandler: @escaping ProgressHandler,
                     completionHandler: @escaping CompletionHandler) {
        
        var request = URLRequest(url: targetURL, cachePolicy: .reloadIgnoringLocalCacheData)
        
        request.httpMethod = "POST"
        
        let task = urlSession.uploadTask(with: request, fromFile: fileURL)
        
        progressHandlersByTaskID[task.taskIdentifier] = (progressHandler, completionHandler)
        task.resume()
    }
}

extension FileUploader: URLSessionTaskDelegate {
    func urlSession( _ session: URLSession,
                     task: URLSessionTask,
                     didSendBodyData bytesSent: Int64,
                     totalBytesSent: Int64,
                     totalBytesExpectedToSend: Int64 ) {
        let progress = Double(totalBytesSent) / Double(totalBytesExpectedToSend)
        let handler = progressHandlersByTaskID[task.taskIdentifier]
        handler?.progress(progress)
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let handler = progressHandlersByTaskID[task.taskIdentifier] else {return}
        
        if let error = error {
            handler.completion(.failure(error))
            return
        }
        handler.completion(.success(()))
    }
}
