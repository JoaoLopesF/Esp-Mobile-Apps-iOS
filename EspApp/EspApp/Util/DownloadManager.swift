
/* ***********
 * Project   : Esp-App-Mobile-iOS - App to connect a Esp32 device by BLE
 * Programmer: Joao Lopes
 * Module    : Util - iOS UI utilities
 * Comments  : Download manager
 * Versions  :
 * -------   --------     -------------------------
 * 0.1.0     08/08/18     First version
 **/
 
import Foundation

// DownloadManager
// Based on  https://www.ralfebert.de/snippets/ios/urlsession-background-downloads/

class DownloadManager : NSObject, URLSessionDelegate, URLSessionDownloadDelegate {

    static var shared = DownloadManager()

    typealias ProgressHandler = (Float) -> ()
    typealias OnFinishDownLoad = (URL) -> ()
    typealias OnCompleteWithError = (Error?) -> ()
    
    var onProgress : ProgressHandler?
    var onFinishDownLoad : OnFinishDownLoad?
    var onCompleteWithError : OnCompleteWithError?
    
    override private init() {
        super.init()
    }

    func activate() -> URLSession {
        let config = URLSessionConfiguration.default
        // Warning: If an URLSession still exists from a previous download, it doesn't create a new URLSession object but returns the existing one with the old delegate object attached!
        return URLSession(configuration: config, delegate: self, delegateQueue: OperationQueue())
    }

    private func calculateProgress(session : URLSession, completionHandler : @escaping (Float) -> ()) {
        session.getTasksWithCompletionHandler { (tasks, uploads, downloads) in
            let progress = downloads.map({ (task) -> Float in
                if task.countOfBytesExpectedToReceive > 0 {
                    return Float(task.countOfBytesReceived) / Float(task.countOfBytesExpectedToReceive)
                } else {
                    return 0.0
                }
            })
            completionHandler(progress.reduce(0.0, +))
        }
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {

        if totalBytesExpectedToWrite > 0 {
            if let onProgress = onProgress {
                calculateProgress(session: session, completionHandler: onProgress)
            }
            //let progress = Float(totalBytesWritten) / Float(totalBytesExpectedToWrite)
            //debugV("Progress \(downloadTask) \(progress)")

        }
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
//        debugV("Download finished: \(location)")
//        debugV(Arquivo.existe(url: location))
        if (onFinishDownLoad != nil) {
            onFinishDownLoad! (location)
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if error == nil {
//            debugV("Data downloaded - task complete")
        } else {
            debugE("Task completed: \(task), error: \(String(describing: error))")
            if (onCompleteWithError != nil) {
                onCompleteWithError! (error)
            }            
        }
    }
    
}

////// End