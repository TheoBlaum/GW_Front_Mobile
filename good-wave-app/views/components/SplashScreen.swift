//
//  SplashScreen.swift
//  good-wave
//

import SwiftUI

struct SplashScreen: View {
    var body: some View {
        ZStack {
            Color.white.edgesIgnoringSafeArea(.all)
            
            Image("splash_screen")
                .resizable()
                .scaledToFill()
                .edgesIgnoringSafeArea(.all)
        }
    }
}

#Preview {
    SplashScreen()
}
