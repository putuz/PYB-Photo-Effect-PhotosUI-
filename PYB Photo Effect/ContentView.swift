//
//  ContentView.swift
//  PYB Photo Effect
//
//  Created by Your Future on 12/11/24.
//

import SwiftUI
import PhotosUI
import Photos

struct PhotoEffect: Identifiable {
    let id = UUID()
    let name: String
    var brightness: Double
    var contrast: Double
    var saturation: Double
    var warmth: Double
    var isNormal: Bool
}

struct ContentView: View {
    @State private var selectedImage: UIImage?
    @State private var imageSelection: PhotosPickerItem?
    @State private var currentEffectIndex = 0
    
    let effects: [PhotoEffect] = [
        PhotoEffect(name: "Normal", brightness: 0, contrast: 1, saturation: 1, warmth: 0, isNormal: true),
        PhotoEffect(name: "Sunset Glow", brightness: 0.1, contrast: 1.2, saturation: 1.3, warmth: 0.4, isNormal: false),
        PhotoEffect(name: "Ocean Blue", brightness: 0, contrast: 1.3, saturation: 1.1, warmth: -0.3, isNormal: false),
        PhotoEffect(name: "Pop Art", brightness: 0.15, contrast: 1.4, saturation: 1.6, warmth: 0.2, isNormal: false),
        PhotoEffect(name: "Candy Pink", brightness: 0.1, contrast: 1.1, saturation: 1.5, warmth: 0.5, isNormal: false),
        PhotoEffect(name: "Electric", brightness: 0, contrast: 1.5, saturation: 1.8, warmth: 0, isNormal: false),
        PhotoEffect(name: "Tropical", brightness: 0.2, contrast: 1.3, saturation: 1.4, warmth: 0.3, isNormal: false),
        PhotoEffect(name: "Aqua Dream", brightness: 0.05, contrast: 1.2, saturation: 1.2, warmth: -0.2, isNormal: false),
        PhotoEffect(name: "Golden Hour", brightness: 0.2, contrast: 1.2, saturation: 1.3, warmth: 0.5, isNormal: false)
    ]
    
    var body: some View {
        NavigationStack {
            VStack {
                // Image Display Area
                if let selectedImage {
                    TabView(selection: $currentEffectIndex) {
                        ForEach(effects.indices, id: \.self) { index in
                            Group {
                                if effects[index].isNormal {
                                    Image(uiImage: selectedImage)
                                        .resizable()
                                        .scaledToFit()
                                } else {
                                    Image(uiImage: selectedImage)
                                        .resizable()
                                        .scaledToFit()
                                        .brightness(effects[index].brightness)
                                        .contrast(effects[index].contrast)
                                        .saturation(effects[index].saturation)
                                        .colorMultiply(effects[index].warmth > 0 ?
                                            .orange.opacity(effects[index].warmth) :
                                            .blue.opacity(-effects[index].warmth))
                                }
                            }
                            .tag(index)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .frame(height: 400)
                } else {
                    ContentUnavailableView(
                        "No Image Selected",
                        systemImage: "photo.badge.plus",
                        description: Text("Tap the button below to select a photo")
                    )
                }
                
                // Effect Names ScrollView with Circular Previews
                ScrollView(.horizontal, showsIndicators: false) {
                    ScrollViewReader { proxy in
                        HStack(spacing: 15) {
                            ForEach(effects.indices, id: \.self) { index in
                                VStack(spacing: 8) {
                                    if let selectedImage {
                                        Group {
                                            if effects[index].isNormal {
                                                Image(uiImage: selectedImage)
                                                    .resizable()
                                                    .scaledToFill()
                                            } else {
                                                Image(uiImage: selectedImage)
                                                    .resizable()
                                                    .scaledToFill()
                                                    .brightness(effects[index].brightness)
                                                    .contrast(effects[index].contrast)
                                                    .saturation(effects[index].saturation)
                                                    .colorMultiply(effects[index].warmth > 0 ?
                                                        .orange.opacity(effects[index].warmth) :
                                                        .blue.opacity(-effects[index].warmth))
                                            }
                                        }
                                        .frame(width: 65, height: 65)
                                        .clipShape(Circle())
                                        .overlay(
                                            Circle()
                                                .stroke(currentEffectIndex == index ? .blue : .gray.opacity(0.3), lineWidth: 2)
                                        )
                                    } else {
                                        Circle()
                                            .fill(Color.gray.opacity(0.2))
                                            .frame(width: 65, height: 65)
                                            .overlay(
                                                Circle()
                                                    .stroke(Color.gray.opacity(0.3), lineWidth: 2)
                                            )
                                    }
                                    
                                    Text(effects[index].name)
                                        .font(.caption)
                                        .foregroundColor(currentEffectIndex == index ? .blue : .primary)
                                }
                                .id(index) // Set the id to allow scroll tracking
                                .onTapGesture {
                                    withAnimation {
                                        currentEffectIndex = index
                                    }
                                }
                            }
                        }
                        .padding()
                        .onChange(of: currentEffectIndex) { old, index in
                            // Automatically scroll to selected effect in the ScrollView
                            withAnimation {
                                proxy.scrollTo(index, anchor: .center)
                            }
                        }
                    }
                }
                
                PhotosPicker(selection: $imageSelection,
                             matching: .images,
                             photoLibrary: .shared()) {
                    Label("Select Photo", systemImage: "photo.fill")
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding(.horizontal)
                }
                
                Button(action: {
                    if let image = selectedImage {
                        saveToLibrary(image: image)
                    }
                }) {
                    Text("Save to Library")
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding(.horizontal)
                }
            }
            .padding()
            .navigationTitle("Photo Effects")
            .onChange(of: imageSelection) {
                Task {
                    if let data = try? await imageSelection?.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {
                        selectedImage = uiImage
                        currentEffectIndex = 0
                    }
                }
            }
        }
    }
    
    private func saveToLibrary(image: UIImage) {
        // Request permission to access the photo library
        PHPhotoLibrary.requestAuthorization { status in
            if status == .authorized {
                // Create a graphics renderer with the same size as the image
                let renderer = UIGraphicsImageRenderer(size: image.size)
                
                // Render the image with applied effects
                let renderedImage = renderer.image { context in
                    // Draw the image with the current effect
                    image.draw(at: .zero, blendMode: .normal, alpha: 1.0)
                    
                    // Apply the current effect to the context
                    if !effects[currentEffectIndex].isNormal {
                        context.cgContext.setAlpha(1.0)
                        context.cgContext.setBlendMode(.normal)
                        context.cgContext.setFillColor(UIColor.orange.withAlphaComponent(CGFloat(effects[currentEffectIndex].warmth)).cgColor)
                        context.cgContext.fill(CGRect(origin: .zero, size: image.size))
                        
                        context.cgContext.setAlpha(1.0)
                        context.cgContext.setBlendMode(.multiply)
                        context.cgContext.setFillColor(UIColor.white.cgColor)
                        context.cgContext.fill(CGRect(origin: .zero, size: image.size))
                    }
                }

                // Save the rendered image to the photo library
                PHPhotoLibrary.shared().performChanges {
                    PHAssetCreationRequest.forAsset().addResource(with: .photo, data: renderedImage.jpegData(compressionQuality: 1.0)!, options: nil)
                } completionHandler: { success, error in
                    if success {
                        print("Image saved to library successfully!")
                    } else if let error = error {
                        print("Error saving image: \(error.localizedDescription)")
                    }
                }
            } else {
                print("Permission denied to access photo library.")
            }
        }
    }
}

struct ParameterView: View {
    let name: String
    let value: Double
    
    var body: some View {
        HStack {
            Text(name)
                .frame(width: 100, alignment: .leading)
            Text(String(format: "%.2f", value))
                .foregroundColor(.secondary)
        }
        .font(.caption)
    }
}

#Preview {
    ContentView()
}
