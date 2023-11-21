//
//  FFAuthorityTool.swift
//  Picroll
//
//  Created by cofey on 2022/8/17.
//  权限请求类

import Foundation
import Photos
import FFUITool

public enum FFAccessLevel : Int, @unchecked Sendable {
    case addOnly = 1
    case readWrite = 2
    
    @available(iOS 14, *)
    var phAccessLevel: PHAccessLevel {
        switch self {
        case .addOnly:
            return PHAccessLevel.addOnly
        default:
            return PHAccessLevel.readWrite
        }
    }
}


public class FFAuthorizationTool {
    public static func requestPhotoAuthorization(for accessLevel: FFAccessLevel, result: @escaping (_ success: Bool)->()) {
        var status = PHPhotoLibrary.authorizationStatus()
        if #available(iOS 14, *) {
            status = PHPhotoLibrary.authorizationStatus(for: accessLevel.phAccessLevel)
        }
        switch status {
        case .authorized:
            result(true)
            break
        case .denied, .restricted:
            ffPrint("未获得相册权限")
            result(false)
            break
        case .notDetermined:
            asyncRequestPhotoAuthorization(for: accessLevel,result: result)
            break
        case .limited:
            ffPrint("选择了单个相册权限")
            result(true)
            break
        default: break
            
        }
    }
    
    private static func asyncRequestPhotoAuthorization(for accessLevel: FFAccessLevel,result: @escaping (_ success: Bool)->Void) {
        
        if #available(iOS 14, *) {
            PHPhotoLibrary.requestAuthorization(for: accessLevel.phAccessLevel) { status in
                DispatchQueue.main.async {
                    if status != .authorized && status != .limited {
                        result(false)
                        ffPrint("未开启相册权限，请到设置中开启")
                    }
                    result(true)
                }
            }
        } else {
            PHPhotoLibrary.requestAuthorization { status in
                DispatchQueue.main.async {
                    if status != .authorized {
                        result(false)
                        ffPrint("未开启相册权限，请到设置中开启")
                    }
                    result(true)
                }
            }
        }
    }
    
    private static func requestCameraAuthorization(result: @escaping (_ success: Bool)->Void) {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .authorized:
            result(true)
            break
        case .denied, .restricted:
            ffPrint("未获得摄像头权限")
            result(false)
            break
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { finish in
                DispatchQueue.main.async {
                    result(finish == true ? true : false)
                }
            }
            break
        default: break
        }
    }
}

@available(iOS 13.0, *)
extension FFAuthorizationTool {
    public static func requestPhotoAutuorization(for accessLevel: FFAccessLevel) async -> Bool {
        var status = PHPhotoLibrary.authorizationStatus()
        if #available(iOS 14, *) {
            status = PHPhotoLibrary.authorizationStatus(for: accessLevel.phAccessLevel)
        }
        
        if status == .notDetermined {
            let result = await asyncRequestPhotoAuthorization(for: accessLevel)
            return await withUnsafeContinuation {(continuation:UnsafeContinuation<Bool, Never>) in
                return continuation.resume(returning: result)
            }
        } else {
            return await withUnsafeContinuation {(continuation:UnsafeContinuation<Bool, Never>) in
                switch status {
                case .authorized:
                    return continuation.resume(returning: true)
                case .denied, .restricted:
                    ffPrint("未获得相册权限")
                    return continuation.resume(returning: false)
                case .limited:
                    ffPrint("选择了单个相册权限")
                    return continuation.resume(returning: true)
                default: break
                }
            }
        }
    }
    
    private static func asyncRequestPhotoAuthorization(for accessLevel: FFAccessLevel) async -> Bool {
        return await withUnsafeContinuation {(continuation:UnsafeContinuation<Bool, Never>) in
            if #available(iOS 14, *) {
                PHPhotoLibrary.requestAuthorization(for: accessLevel.phAccessLevel) { status in
                    DispatchQueue.main.async {
                        if status != .authorized && status != .limited {
                            continuation.resume(returning: false)
                            ffPrint("未开启相册权限，请到设置中开启")
                        }
                        continuation.resume(returning: true)
                    }
                }
            } else {
                PHPhotoLibrary.requestAuthorization { status in
                    DispatchQueue.main.async {
                        if status != .authorized {
                            continuation.resume(returning: false)
                            ffPrint("未开启相册权限，请到设置中开启")
                        }
                        continuation.resume(returning: true)
                    }
                }
            }
        }
    }
    
    
    private static func requestCameraAuthorization() async -> Bool {
        return await withUnsafeContinuation {(continuation:UnsafeContinuation<Bool, Never>) in
            let status = AVCaptureDevice.authorizationStatus(for: .video)
            switch status {
            case .authorized:
                return continuation.resume(returning: true)
            case .denied, .restricted:
                ffPrint("未获得摄像头权限")
                return continuation.resume(returning: false)
            case .notDetermined:
                AVCaptureDevice.requestAccess(for: .video) { finish in
                    DispatchQueue.main.async {
                        return continuation.resume(returning: finish)
                    }
                }
            default: break
            }
        }
    }
}
