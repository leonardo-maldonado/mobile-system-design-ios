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
            TabView {
                NavigationStack {
                    ImageGalleryView(coordinator: coordinator)
                        .ignoresSafeArea(.all)
                        .navigationDestination(item: $coordinator.currentRoute) { route in
                            ImageGalleryRouter.destination(for: route)
                        }
                }.tabItem {
                    Image(systemName: "photo")
                    Text("Photos")
                }
                
                NavigationStack {
                    Text("Memories")
                }.tabItem {
                    Image(systemName: "square.stack")
                    Text("Memory")
                }
                
                NavigationStack {
                    Text("Library")
                }.tabItem {
                    Image(systemName: "list.bullet")
                    Text("Library")
                }
                
                NavigationStack {
                    Text("Search")
                }.tabItem {
                    Image(systemName: "magnifyingglass")
                    Text("Search")
                }
            }
        }
    }
}
