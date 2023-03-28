//
//  FFAuthorityTool.swift
//  Picroll
//
//  Created by cofey on 2022/8/17.
//  权限请求类

import Foundation
import Photos
import FFUITool

public class FFAuthorizationTool {
    public static func requestPhotoAuthorization(result: @escaping (_ success: Bool)->()) {
        var status = PHPhotoLibrary.authorizationStatus()
        if #available(iOS 14, *) {
            status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
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
            asyncRequestPhotoAuthorization(result: result)
            break
        case .limited:
            ffPrint("选择了单个相册权限")
            result(true)
            break
        default: break
            
        }
    }
    
    public static func requestPhotoAddOnlyAuthorization(result: @escaping (_ success: Bool)->()) {
        var status = PHPhotoLibrary.authorizationStatus()
        if #available(iOS 14, *) {
            status = PHPhotoLibrary.authorizationStatus(for: .addOnly)
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
            asyncRequestPhotoAddOnlyAuthorization(result: result)
            break
        case .limited:
            ffPrint("选择了单个相册权限")
            result(true)
            break
        default: break
            
        }
    }
    
    private static func asyncRequestPhotoAuthorization(result: @escaping (_ success: Bool)->Void) {
        
        if #available(iOS 14, *) {
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
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
    
    private static func asyncRequestPhotoAddOnlyAuthorization(result: @escaping (_ success: Bool)->Void) {
        
        if #available(iOS 14, *) {
            PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
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
