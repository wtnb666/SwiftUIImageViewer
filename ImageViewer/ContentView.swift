import SwiftUI

struct ContentView: View {
    @Namespace private var namespace
    @State var selectedIndex: Int?
    @State var isPreviewing: Bool = false
    @State var images: [UIImage] = [
        UIImage(named: "image1")!,
        UIImage(named: "image2")!,
        UIImage(named: "image3")!,
        UIImage(named: "image4")!,
        UIImage(named: "image5")!
    ]
    
    var body: some View {
        
        ScrollViewReader { reader in
            ZStack {
                ScrollView {
                    VStack {
                        ForEach(Array(images.enumerated()), id: \.offset) { index, image in
                            Image(uiImage: image)
                                .resizable()
                                .cornerRadius(10)
                                .aspectRatio(contentMode: .fill)
                                .matchedGeometryEffect(id: index, in: namespace)
                                .onTapGesture {
                                    self.selectedIndex = index
                                    withAnimation(.easeOut(duration: 0.3)) {
                                        self.isPreviewing = true
                                    }
                                }
                                .zIndex(selectedIndex == index ? 1 : 0)
                        }
                    }
                    .padding()
                }
                if let index = selectedIndex, isPreviewing {
                    GeometryReader(content: { proxy in
                        ImageViewer(index: index, pageSize: proxy.size, images: images, namespace: namespace, onChangeIndex: { changed in
                            self.selectedIndex = changed
                            reader.scrollTo(changed)
                        }) {
                            withAnimation(.easeOut(duration: 0.3)) {
                                self.isPreviewing = false
                            }
                        }
                    })
                }
            }
            .frame(maxHeight: .infinity)
        }
    }
}

struct ImageViewer: View {
    @State var index: Int
    @State var offsetSize: CGSize
    @State var imageOffsetSize: CGSize = .zero
    let pageSize: CGSize
    let images: [UIImage]
    let namespace: Namespace.ID
    let onChangeIndex: ((_ index: Int) -> Void)?
    let onClose: (() -> Void)?
    let hStackSpacing: CGFloat = 16
    @State private var dragStartAxis: DragAxis? = nil
    
    enum DragAxis {
        case horizontal
        case verticalUp
        case verticalDown
    }
    
    var isDissmissDragging: Bool {
        abs(imageOffsetSize.width) > 0 || abs(imageOffsetSize.height) > 0
    }
    
    init(index: Int, pageSize: CGSize, images: [UIImage], namespace: Namespace.ID, onChangeIndex: ((_ index: Int) -> Void)?, onClose: ( () -> Void)?) {
        self.index = index
        self.offsetSize = CGSize(width: -(pageSize.width + hStackSpacing) * CGFloat(index), height: 0)
        self.pageSize = pageSize
        self.images = images
        self.namespace = namespace
        self.onChangeIndex = onChangeIndex
        self.onClose = onClose
    }
    
    
    var dragGesture: some Gesture {
        DragGesture(coordinateSpace: .global)
            .onChanged { value in
                switch dragStartAxis {
                case .horizontal:
                    if value.translation.width > 0 && index == 0 {
                        self.offsetSize.width = -(pageSize.width + hStackSpacing) * CGFloat(index) + value.translation.width * 0.3
                    } else if value.translation.width < 0 && index == images.count - 1 {
                        self.offsetSize.width = -(pageSize.width + hStackSpacing) * CGFloat(index) + value.translation.width * 0.3
                    } else {
                        self.offsetSize.width = -(pageSize.width + hStackSpacing) * CGFloat(index) + value.translation.width * 0.6
                    }
                case .verticalUp:
                    break
                case .verticalDown:
                    self.imageOffsetSize = value.translation
                case nil:
                    if abs(value.predictedEndTranslation.width) > abs(value.predictedEndTranslation.height) {
                        dragStartAxis = .horizontal
                    } else {
                        dragStartAxis = value.translation.height > 0 ? .verticalDown : .verticalUp
                    }
                }
            }
            .onEnded { value in
                switch dragStartAxis {
                case .horizontal:
                    var targetIndex = index
                    if value.predictedEndTranslation.width < -pageSize.width / 3 && index + 1 < images.count {
                        targetIndex += 1
                    } else if value.predictedEndTranslation.width > pageSize.width / 3 && index > 0 {
                        targetIndex -= 1
                    }
                    index = targetIndex
                    onChangeIndex?(targetIndex)
                    withAnimation(.easeOut(duration: 0.2)) {
                        self.offsetSize = CGSize(width: -(pageSize.width + hStackSpacing) * CGFloat(targetIndex), height: 0)
                    }
                case .verticalUp:
                    break
                case .verticalDown:
                    if value.translation.height > 0 {
                        onClose?()
                    } else {
                        withAnimation(.easeOut(duration: 0.2)) {
                            self.imageOffsetSize = .zero
                        }
                    }
                case nil:
                    break
                }
                dragStartAxis = nil
            }
    }
    
    var body: some View {
        ZStack {
            Color.white
                .opacity(1.0 - (imageOffsetSize.height / pageSize.height))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea()
            
            HStack(spacing: hStackSpacing) {
                ForEach(Array(images.enumerated()), id: \.offset) { offset, image in
                    if image == images[index] {
                        ImagePreviewView(image: image)
                            .matchedGeometryEffect(id: offset, in: namespace)
                            .frame(width: pageSize.width, height: pageSize.height)
                            .offset(imageOffsetSize)
                    } else {
                        ImagePreviewView(image: image)
                            .frame(width: pageSize.width, height: pageSize.height)
                    }
                }
            }
            .frame(width: (pageSize.width + hStackSpacing) * CGFloat(images.count) - hStackSpacing, height: pageSize.height)
            .offset(offsetSize)
            .gesture(dragGesture)
            
            Button(action: {
                onClose?()
            }, label: {
                Text("Close")
            })
            .disabled(isDissmissDragging)
            .opacity(isDissmissDragging ? 0 : 1)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding()
        }
        
        
        
    }
}

struct ImagePreviewView: View {
    let image: UIImage
    
    var body: some View {
        Image(uiImage: image)
            .resizable()
            .aspectRatio(contentMode: .fit)
    }
}
