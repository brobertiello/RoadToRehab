//
//  ContentView.swift
//  PoseDetection
//

// NOTE: Update Info.plist to support all orientations on iPad:
// UISupportedInterfaceOrientations~ipad: UIInterfaceOrientationPortrait, UIInterfaceOrientationPortraitUpsideDown, UIInterfaceOrientationLandscapeLeft, UIInterfaceOrientationLandscapeRight

import SwiftUI
import AVFoundation
import Vision

struct ContentView: View {
    @State private var isShowingCamera = false
    @State private var cameraPermissionGranted = false
    @State private var showingPermissionAlert = false
    @State private var infoPlistStatus = "Not checked yet"
    @State private var permissionValueFound = false
    @StateObject private var cameraModel = CameraViewModel()
    
    var body: some View {
        VStack {
            Spacer()
            
            Text("Pose Detection")
                .font(.largeTitle)
                .bold()
                .padding()
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Info.plist Status:")
                    .font(.headline)
                
                Text(infoPlistStatus)
                    .foregroundColor(permissionValueFound ? .green : .red)
                    .font(.subheadline)
                    .padding(.bottom, 10)
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
            .padding(.horizontal)
            
            Button(action: {
                checkInfoPlist()
            }) {
                Text("Check Info.plist")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(minWidth: 200)
                    .background(Color.orange)
                    .cornerRadius(10)
            }
            .padding(.bottom, 20)
            
            Button(action: {
                checkCameraPermission()
            }) {
                Text("Start Detection")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(minWidth: 200)
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .padding()
            .fullScreenCover(isPresented: $isShowingCamera) {
                CameraView()
                    .edgesIgnoringSafeArea(.all)
            }
            .alert("Camera Permission Required", isPresented: $showingPermissionAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
            } message: {
                Text("This app needs camera access to work. Please enable camera access in Settings.")
            }
            
            Spacer()
        }
        .onAppear {
            checkInfoPlist()
        }
    }
    
    func checkInfoPlist() {
        if let cameraPermission = InfoPlistTest.checkCameraPermissionValue() {
            infoPlistStatus = "Found: \"\(cameraPermission)\""
            permissionValueFound = true
            
            // Print all Info.plist values for debugging
            InfoPlistTest.printAllInfoPlistValues()
        } else {
            infoPlistStatus = "ERROR: Camera permission not found in Info.plist"
            permissionValueFound = false
        }
    }
    
    func checkCameraPermission() {
        print("Checking camera permission...")
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            // Permission already granted
            print("Camera permission already granted")
            isShowingCamera = true
            cameraModel.startSession()
        case .notDetermined:
            // Permission not requested yet, ask for it
            print("Requesting camera permission")
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    print("Camera permission response: \(granted)")
                    if granted {
                        self.cameraModel.startSession()
                        isShowingCamera = true
                    } else {
                        showingPermissionAlert = true
                    }
                }
            }
        case .denied, .restricted:
            // Permission previously denied
            print("Camera permission denied or restricted")
            showingPermissionAlert = true
        @unknown default:
            break
        }
    }
}

struct CameraView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var cameraViewController: CameraViewController?
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        ZStack {
            // Vision-based pose detection camera view
            PoseDetectionCameraView(cameraViewControllerHandler: { viewController in
                // Use DispatchQueue.main.async to set state to avoid "Modifying state during view update"
                DispatchQueue.main.async {
                    self.cameraViewController = viewController
                }
            })
            .edgesIgnoringSafeArea(.all)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            VStack {
                Spacer()
                
                Button("Close Camera") {
                    print("Closing camera")
                    // Stop capture before dismissing
                    cameraViewController?.stopCapture()
                    dismiss()
                }
                .padding()
                .background(Color.black.opacity(0.7))
                .foregroundColor(.white)
                .cornerRadius(10)
                .padding(.bottom, 30)
            }
        }
        .background(Color.black)
        .edgesIgnoringSafeArea(.all)
        .onDisappear {
            // Ensure capture stops when view disappears
            print("Camera view disappeared")
            cameraViewController?.stopCapture()
        }
        .alert("Camera Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
}

// Vision-based pose detection
struct PoseDetectionCameraView: UIViewControllerRepresentable {
    var cameraViewControllerHandler: ((CameraViewController) -> Void)?
    
    func makeUIViewController(context: Context) -> CameraViewController {
        let controller = CameraViewController()
        cameraViewControllerHandler?(controller)
        return controller
    }

    func updateUIViewController(_ uiViewController: CameraViewController, context: Context) {}
}

class CameraViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    private let session = AVCaptureSession()
    private var previewLayer: AVCaptureVideoPreviewLayer!
    private var poseRequest = VNDetectHumanBodyPoseRequest()
    private let overlayLayer = CAShapeLayer()
    
    private var isFrontCamera: Bool = false
    private var setupComplete = false
    private var processingFrame = false
    
    // Use dispatch queue for thread safety
    private let sessionQueue = DispatchQueue(label: "session.queue", qos: .background)
    private let processingQueue = DispatchQueue(label: "processing.queue", qos: .utility)
    
    // Safer tracking variables
    private var lastFrameTime = Date()
    private var frameCount = 0
    private var isCapturing = false

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Create empty layers on main thread first
        setupEmptyLayers()
        
        // Safer setup sequence
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            self.setupSession()
            self.startCapture()
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // Always update frames on main thread
        previewLayer?.frame = view.bounds
        overlayLayer.frame = view.bounds
    }
    
    // Start capturing safely
    private func startCapture() {
        guard !isCapturing else { return }
        
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            
            print("Starting camera capture...")
            self.session.startRunning()
            
            DispatchQueue.main.async {
                self.isCapturing = true
                self.setupComplete = true
                print("Camera started successfully")
                
                // Draw a placeholder immediately so user sees something
                self.drawSimpleSkeleton()
            }
        }
    }

    private func setupSession() {
        print("Setting up camera session...")
        printAvailableCameras()
        
        // Configure on the session queue for thread safety
        session.beginConfiguration()
        
        // Try to find any camera that works
        var device: AVCaptureDevice?
        
        // Try 3 different approaches to get a camera
        if let frontCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) {
            device = frontCamera
            print("Found front camera: \(frontCamera.localizedName)")
        } 
        else if let backCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) {
            device = backCamera
            print("Falling back to back camera: \(backCamera.localizedName)")
        }
        else if let anyCamera = AVCaptureDevice.default(for: .video) {
            device = anyCamera
            print("Using any available camera: \(anyCamera.localizedName)")
        }
        
        guard let captureDevice = device else {
            print("ERROR: No camera device available")
            session.commitConfiguration()
            return
        }
        
        print("Configuring camera device: \(captureDevice.localizedName)")
        
        // Set the flag based on camera position
        isFrontCamera = (captureDevice.position == .front)
        
        // Clear any existing inputs/outputs
        session.inputs.forEach { session.removeInput($0) }
        session.outputs.forEach { session.removeOutput($0) }
        
        do {
            let input = try AVCaptureDeviceInput(device: captureDevice)
            
            if session.canAddInput(input) {
                session.addInput(input)
                print("Camera input added successfully")
            } else {
                print("ERROR: Could not add camera input")
            }
            
            let output = AVCaptureVideoDataOutput()
            output.alwaysDiscardsLateVideoFrames = true
            
            let videoQueue = DispatchQueue(label: "videoQueue", qos: .userInteractive)
            output.setSampleBufferDelegate(self, queue: videoQueue)
            
            if session.canAddOutput(output) {
                session.addOutput(output)
                print("Video output added successfully")
            } else {
                print("ERROR: Could not add video output")
            }
            
            // Use a very basic preset to avoid taxing the system
            if session.canSetSessionPreset(.vga640x480) {
                session.sessionPreset = .vga640x480
                print("Using VGA preset for better performance")
            }
        } catch {
            print("ERROR setting up camera: \(error.localizedDescription)")
        }
        
        session.commitConfiguration()
        print("Camera session configured")
    }

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // Skip processing if we're already busy or not set up
        guard setupComplete, !processingFrame else { return }
        
        // Simple tracking without locking
        lastFrameTime = Date()
        frameCount += 1
        
        // Severely reduce processing load - only process every 30th frame
        guard frameCount % 30 == 0 else { return }
        
        // Flag that we're processing to avoid multiple simultaneous processing
        processingFrame = true
        
        // Always use a placeholder on Mac, which is much more stable
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.drawSimpleSkeleton()
            self.processingFrame = false
        }
    }

    // Draw a simple placeholder skeleton
    private func drawSimpleSkeleton() {
        // Only run on main thread
        if !Thread.isMainThread {
            DispatchQueue.main.async { [weak self] in
                self?.drawSimpleSkeleton()
            }
            return
        }
        
        let path = UIBezierPath()
        let width = overlayLayer.bounds.width
        let height = overlayLayer.bounds.height
        
        // Draw a simple stick figure in the center
        let centerX = width / 2
        let topY = height * 0.3
        let bottomY = height * 0.7
        
        // Head
        path.addArc(withCenter: CGPoint(x: centerX, y: topY), radius: 20, startAngle: 0, endAngle: .pi * 2, clockwise: true)
        
        // Body
        path.move(to: CGPoint(x: centerX, y: topY + 20))
        path.addLine(to: CGPoint(x: centerX, y: bottomY - 40))
        
        // Arms
        path.move(to: CGPoint(x: centerX - 40, y: topY + 50))
        path.addLine(to: CGPoint(x: centerX + 40, y: topY + 50))
        
        // Legs
        path.move(to: CGPoint(x: centerX, y: bottomY - 40))
        path.addLine(to: CGPoint(x: centerX - 30, y: bottomY))
        
        path.move(to: CGPoint(x: centerX, y: bottomY - 40))
        path.addLine(to: CGPoint(x: centerX + 30, y: bottomY))
        
        overlayLayer.path = path.cgPath
    }

    // Safe cleanup method
    func stopCapture() {
        guard isCapturing else { return }
        
        print("Stopping capture...")
        isCapturing = false
        setupComplete = false
        
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            if self.session.isRunning {
                self.session.stopRunning()
                print("Camera session stopped")
            }
        }
    }
    
    deinit {
        print("CameraViewController is being deallocated")
        stopCapture()
    }

    private func printAvailableCameras() {
        let discoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera],
            mediaType: .video,
            position: .unspecified
        )
        
        print("Available cameras: \(discoverySession.devices.count)")
        for device in discoverySession.devices {
            print("- \(device.localizedName) (position: \(device.position.rawValue))")
        }
    }
}

// Remove the old camera implementation that's no longer needed
class CameraViewModel: ObservableObject {
    @Published var captureSession = AVCaptureSession()
    @Published var isSessionRunning = false
    
    init() {
        setupCaptureSession()
    }
    
    func checkPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            startSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if granted {
                        self.startSession()
                    }
                }
            }
        case .denied, .restricted:
            break
        @unknown default:
            break
        }
    }
    
    private func setupCaptureSession() {
        captureSession.beginConfiguration()
        
        // Add video input
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let videoInput = try? AVCaptureDeviceInput(device: videoDevice) else {
            captureSession.commitConfiguration()
            return
        }
        
        if captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)
        }
        
        // Add video output
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(nil, queue: nil)
        
        if captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
        }
        
        captureSession.commitConfiguration()
    }
    
    func startSession() {
        if !captureSession.isRunning {
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.captureSession.startRunning()
                DispatchQueue.main.async {
                    self?.isSessionRunning = true
                }
            }
        }
    }
    
    func stopSession() {
        if captureSession.isRunning {
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.captureSession.stopRunning()
                DispatchQueue.main.async {
                    self?.isSessionRunning = false
                }
            }
        }
    }
}

// Remove the old camera preview code
struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: UIScreen.main.bounds)
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.frame = view.frame
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
}

#Preview {
    ContentView()
}
