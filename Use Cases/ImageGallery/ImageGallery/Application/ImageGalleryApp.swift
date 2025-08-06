//
//  ImageGalleryApp.swift
//  ImageGallery
//
//  Created by Leonardo Maldonado on 4/26/25.
//

import SwiftUI

@main
struct ImageGalleryApp: App {
    @StateObject private var coordinator = ImageGalleryCoordinator()
    
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                ImageGalleryView(coordinator: coordinator)
                    .ignoresSafeArea(.all)
                    .navigationDestination(item: $coordinator.currentRoute) { route in
                        ImageGalleryRouter.destination(for: route)
                    }
            }
        }
    }
}
