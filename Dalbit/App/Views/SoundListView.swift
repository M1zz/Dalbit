//
//  SoundListView.swift
//  RelaxOn
//
//  Created by Doyeon on 2023/03/07.
//

import SwiftUI

struct FileInfo: Hashable {
    let name: String
}

struct SoundListView: View {
    var body: some View {
        NavigationStack {
            NavigationLink("Water Drop", value: FileInfo(name: "Water Drop"))
                .navigationDestination(for: FileInfo.self) { fileInfo in
                    SoundSelectView(fileInfo: fileInfo)
                }
        }
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        SoundListView()
    }
}
