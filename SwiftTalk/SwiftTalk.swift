//
//  SwiftTalk.swift
//  SwiftTalk
//
//  Created by 程東 on 12/11/25.
//

import SwiftUI
import TinyNetworking
import Model
import ViewHelpers

private let baseUrl = "https://talk.objc.io"
private let collections = Endpoint<[CollectionView]>(
    json: .get,
    url: URL(string: "\(baseUrl)/collections.json")!
)

struct ImageError: Error {}

extension CollectionView {
    var artworkEndpoint: Endpoint<UIImage> {
        .init(.get, url: artwork.png, expectedStatusCode: expected200to300) { data, _ in
            if let data, let image = UIImage(data: data) {
                return .success(image)
            }
            return .failure(ImageError())
        }
    }
}

struct CollectionDetail: View {
    let collection: CollectionView
    
    private var resource: Resource<UIImage>
    
    init(collection: CollectionView) {
        self.collection = collection
        self.resource = .init(endpoint: collection.artworkEndpoint)
    }
    
    var body: some View {
        ZStack {
            VStack {
                resource.value.map({
                    Image(uiImage: $0)
                        .resizable()
                        .scaledToFit()
                        .ignoresSafeArea()
                })
                Spacer()
            }
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text(collection.title)
                        .bold()
                        .font(.largeTitle)
                        .lineLimit(2)
                        .shadow(radius: 0, x: 2, y: 2)
                        .padding()
                        .background(Color(uiColor: .init(white: 1, alpha: 0.9)))
                        .border(.secondary)
                    Text(collection.description)
                        .lineLimit(nil)
                }
                .padding(.horizontal)
            }
        }
    }
}

struct SwiftTalk {
    
    private let resource = Resource(endpoint: collections)
    
    var data: [CollectionView] {
        resource.value ?? []
    }
}

extension CollectionView {
    var caption: String {
        "\(episodes_count) episodes · \(TimeInterval(total_duration).hoursAndMinutes)"
    }
}

extension SwiftTalk: View {
    var body: some View {
        NavigationStack {
            List {
                ForEach(data) { datum in
                    NavigationLink(destination: {
                        CollectionDetail(collection: datum)
                    }) {
                        VStack(alignment: .leading) {
                            Text(datum.title)
                            Text(datum.caption)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }.navigationTitle("Collections")
        }
    }
}

extension CollectionView: @retroactive Identifiable {}

#Preview {
    SwiftTalk()
}
