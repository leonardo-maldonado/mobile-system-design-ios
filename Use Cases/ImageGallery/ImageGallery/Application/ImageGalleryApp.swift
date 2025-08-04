//
//  ImageGalleryApp.swift
//  ImageGallery
//
//  Created by Leonardo Maldonado on 4/26/25.
//

import SwiftUI

@main
struct ImageGalleryApp: App {
    var body: some Scene {
        WindowGroup {
            ImageGalleryView()
                .ignoresSafeArea(.all) 
        }
    }
}
