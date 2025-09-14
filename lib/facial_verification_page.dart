import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'widgets/custom_button.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/firestore_service.dart';
import 'package:geolocator/geolocator.dart';

class FacialVerificationPage extends StatefulWidget {
  final String subjectName;
  final String facultyName;
  final String sessionId;

  const FacialVerificationPage({
    super.key,
    required this.subjectName,
    required this.facultyName,
    required this.sessionId,
  });

  @override
  State<FacialVerificationPage> createState() => _FacialVerificationPageState();
}

class _FacialVerificationPageState extends State<FacialVerificationPage>
    with TickerProviderStateMixin {
  bool _isVerifying = false;
  bool _isVerificationComplete = false;
  bool _isVerificationSuccessful = false;

  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _cameraPermissionGranted = false;
  List<CameraDescription> _cameras = [];

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  final _firestoreService = FirestoreService();
  final _auth = FirebaseAuth.instance;

  Position? _position;
  String? _locationError;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  Future<void> _initializeCamera() async {
    try {
      // Request camera permission
      final status = await Permission.camera.request();

      if (status.isGranted) {
        setState(() {
          _cameraPermissionGranted = true;
        });

        // Get available cameras
        _cameras = await availableCameras();

        if (_cameras.isEmpty) {
          print('No cameras available on device');
          return;
        }

        // Initialize front camera if available, otherwise use first available
        final frontCamera = _cameras.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.front,
          orElse: () => _cameras.first,
        );

        _cameraController = CameraController(
          frontCamera,
          ResolutionPreset.medium,
          enableAudio: false,
        );

        await _cameraController!.initialize();

        if (mounted) {
          setState(() {
            _isCameraInitialized = true;
          });
        }
      } else if (status.isDenied) {
        setState(() {
          _cameraPermissionGranted = false;
        });
        print('Camera permission denied');
      } else if (status.isPermanentlyDenied) {
        setState(() {
          _cameraPermissionGranted = false;
        });
        print('Camera permission permanently denied');
        // Show dialog to go to settings
        if (mounted) {
          _showPermissionDialog();
        }
      }
    } catch (e) {
      print('Error initializing camera: $e');
      if (mounted) {
        setState(() {
          _cameraPermissionGranted = false;
          _isCameraInitialized = false;
        });
      }
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Camera Permission Required'),
          content: const Text(
            'This app needs camera access to verify your identity for attendance marking. Please go to Settings and enable camera permission for this app.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings();
              },
              child: const Text('Settings'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _startVerification() async {
    setState(() {
      _isVerifying = true;
    });

    _pulseController.repeat(reverse: true);

    // Simulate verification process
    await Future.delayed(const Duration(seconds: 3));

    _pulseController.stop();

    bool success = true; // Replace with real face verification result

    if (success) {
      // Mark present in Firestore
      final uid = _auth.currentUser?.uid;
      if (uid != null) {
        try {
          await _firestoreService.markPresent(
            sessionId: widget.sessionId,
            studentId: uid,
          );
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to mark attendance: $e')),
            );
          }
        }
      }

      // Get current location (permissions handled here)
      try {
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          _locationError = 'Location services are disabled';
        } else {
          LocationPermission permission = await Geolocator.checkPermission();
          if (permission == LocationPermission.denied) {
            permission = await Geolocator.requestPermission();
          }
          if (permission == LocationPermission.deniedForever ||
              permission == LocationPermission.denied) {
            _locationError = 'Location permission denied';
          } else {
            _position = await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.high,
            );
          }
        }
      } catch (e) {
        _locationError = 'Error getting location: $e';
      }

      if (mounted) {
        final msg = _position != null
            ? 'Attendance marked. Lat: ${_position!.latitude.toStringAsFixed(6)}, Lng: ${_position!.longitude.toStringAsFixed(6)}'
            : (_locationError ?? 'Attendance marked present.');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
      }
    }

    if (mounted) {
      setState(() {
        _isVerifying = false;
        _isVerificationComplete = true;
        _isVerificationSuccessful = success;
      });
    }
  }

  void _retryVerification() {
    setState(() {
      _isVerificationComplete = false;
      _isVerificationSuccessful = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Facial Verification',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // Subject info
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: Column(
                  children: [
                    Text(
                      widget.subjectName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.facultyName,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 14,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // Camera preview area
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _isVerifying
                          ? Colors.blue
                          : _isVerificationComplete
                          ? (_isVerificationSuccessful
                                ? Colors.green
                                : Colors.red)
                          : Colors.white.withOpacity(0.3),
                      width: 3,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(17),
                    child: Stack(
                      children: [
                        // Camera preview
                        if (_cameraPermissionGranted &&
                            _isCameraInitialized &&
                            _cameraController != null)
                          Positioned.fill(
                            child: CameraPreview(_cameraController!),
                          )
                        else if (!_cameraPermissionGranted)
                          // Permission denied UI
                          Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.camera_alt_outlined,
                                  size: 80,
                                  color: Colors.white,
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  'Camera Permission Required',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'We need access to your camera to verify\nyour identity for attendance marking.',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 14,
                                    fontFamily: 'Poppins',
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 20),
                                ElevatedButton.icon(
                                  onPressed: _initializeCamera,
                                  icon: const Icon(Icons.camera_alt),
                                  label: const Text('Grant Camera Access'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextButton(
                                  onPressed: () {
                                    openAppSettings();
                                  },
                                  child: Text(
                                    'Open App Settings',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.8),
                                      fontSize: 12,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          // Loading camera UI
                          Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  'Initializing camera...',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.8),
                                    fontSize: 16,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Face detection overlay (when camera is active and not verifying)
                        if (_cameraPermissionGranted &&
                            _isCameraInitialized &&
                            !_isVerifying &&
                            !_isVerificationComplete)
                          Positioned.fill(
                            child: CustomPaint(painter: FaceDetectionOverlay()),
                          ),

                        // Initial guidance overlay (when camera is ready but not verifying)
                        if (_cameraPermissionGranted &&
                            _isCameraInitialized &&
                            !_isVerifying &&
                            !_isVerificationComplete)
                          Positioned(
                            bottom: 50,
                            left: 20,
                            right: 20,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Position your face within the circle',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 14,
                                  fontFamily: 'Poppins',
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),

                        // Verification progress overlay
                        if (_isVerifying)
                          Positioned.fill(
                            child: Container(
                              color: Colors.black.withOpacity(0.5),
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    AnimatedBuilder(
                                      animation: _pulseAnimation,
                                      builder: (context, child) {
                                        return Transform.scale(
                                          scale: _pulseAnimation.value,
                                          child: Container(
                                            width: 120,
                                            height: 120,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: Colors.blue,
                                                width: 3,
                                              ),
                                            ),
                                            child: const Icon(
                                              Icons.face,
                                              size: 60,
                                              color: Colors.blue,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                    const SizedBox(height: 20),
                                    const CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.blue,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'Verifying your identity...',
                                      style: TextStyle(
                                        color: Colors.blue,
                                        fontSize: 16,
                                        fontFamily: 'Poppins',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                        // Verification result overlay
                        if (_isVerificationComplete)
                          Positioned.fill(
                            child: Container(
                              color: Colors.black.withOpacity(0.7),
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 120,
                                      height: 120,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: _isVerificationSuccessful
                                            ? Colors.green.withOpacity(0.2)
                                            : Colors.red.withOpacity(0.2),
                                        border: Border.all(
                                          color: _isVerificationSuccessful
                                              ? Colors.green
                                              : Colors.red,
                                          width: 3,
                                        ),
                                      ),
                                      child: Icon(
                                        _isVerificationSuccessful
                                            ? Icons.check
                                            : Icons.close,
                                        size: 60,
                                        color: _isVerificationSuccessful
                                            ? Colors.green
                                            : Colors.red,
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    Text(
                                      _isVerificationSuccessful
                                          ? 'Verification Successful!'
                                          : 'Verification Failed',
                                      style: TextStyle(
                                        color: _isVerificationSuccessful
                                            ? Colors.green
                                            : Colors.red,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Poppins',
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    if (_isVerificationSuccessful &&
                                        _position != null)
                                      Text(
                                        'Lat: ${_position!.latitude.toStringAsFixed(6)}, Lng: ${_position!.longitude.toStringAsFixed(6)}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontFamily: 'Poppins',
                                        ),
                                      ),
                                    if (_isVerificationSuccessful &&
                                        _position == null &&
                                        _locationError != null)
                                      Text(
                                        _locationError!,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontFamily: 'Poppins',
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // Action buttons
              if (!_isVerifying && !_isVerificationComplete)
                Column(
                  children: [
                    CustomButton(
                      text: 'Start Verification',
                      onPressed: _startVerification,
                      backgroundColor: Colors.blue,
                      height: 56,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Make sure you are in a well-lit area\nand look directly at the camera',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12,
                        fontFamily: 'Poppins',
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),

              if (_isVerificationComplete)
                Column(
                  children: [
                    if (_isVerificationSuccessful)
                      CustomButton(
                        text: 'Done',
                        onPressed: () => Navigator.pop(context, true),
                        backgroundColor: Colors.green,
                        height: 56,
                      )
                    else
                      CustomButton(
                        text: 'Try Again',
                        onPressed: _retryVerification,
                        backgroundColor: Colors.red,
                        height: 56,
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class FaceDetectionOverlay extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = 100.0;

    // Draw corner brackets
    final cornerLength = 30.0;
    final cornerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    // Top-left corner
    canvas.drawLine(
      Offset(center.dx - radius, center.dy - radius),
      Offset(center.dx - radius + cornerLength, center.dy - radius),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(center.dx - radius, center.dy - radius),
      Offset(center.dx - radius, center.dy - radius + cornerLength),
      cornerPaint,
    );

    // Top-right corner
    canvas.drawLine(
      Offset(center.dx + radius, center.dy - radius),
      Offset(center.dx + radius - cornerLength, center.dy - radius),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(center.dx + radius, center.dy - radius),
      Offset(center.dx + radius, center.dy - radius + cornerLength),
      cornerPaint,
    );

    // Bottom-left corner
    canvas.drawLine(
      Offset(center.dx - radius, center.dy + radius),
      Offset(center.dx - radius + cornerLength, center.dy + radius),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(center.dx - radius, center.dy + radius),
      Offset(center.dx - radius, center.dy + radius - cornerLength),
      cornerPaint,
    );

    // Bottom-right corner
    canvas.drawLine(
      Offset(center.dx + radius, center.dy + radius),
      Offset(center.dx + radius - cornerLength, center.dy + radius),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(center.dx + radius, center.dy + radius),
      Offset(center.dx + radius, center.dy + radius - cornerLength),
      cornerPaint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
