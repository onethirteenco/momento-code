//
//  AppInfoView.swift
//  Momento
//
//  Created by Nicholas Dapolito on 8/20/24.
//

import SwiftUI

struct AppInfoView: View {
    var body: some View {
        NavigationStack {
            VStack {
                HStack {
                    Image("defaultPreview")
                        .resizable()
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .frame(width: 100, height: 100)
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Momento Camera")
                            .font(.title)
                            .fontDesign(.monospaced)
                            .fontWeight(.black)
                            .foregroundStyle(Color.subtitleText)
                        Text("The simple camera app.")
                            .font(.system(size: 18))
                            .fontDesign(.monospaced).bold()
                        Text("👨🏻‍💻 Sparrow Apps | 📆 September 19, 2024")
                            .font(.system(size: 10))
                            .fontDesign(.monospaced).bold()
                    }
                }
                .padding()
            }
            .navigationTitle("App Information")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    AppInfoView()
}
