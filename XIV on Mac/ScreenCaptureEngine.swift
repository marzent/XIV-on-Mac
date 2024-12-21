import Foundation
import AVFoundation
import ScreenCaptureKit
import Combine

@available(macOS 13.0, *)
class ScreenCaptureEngine: NSObject, @unchecked Sendable {
    public var  avWriter : AVWriter?
    private var stream: SCStream?
    private let videoSampleBufferQueue = DispatchQueue(label: "com.marzent.XIVOnMac.VideoCapture")
    private let audioSampleBufferQueue = DispatchQueue(label: "com.marzent.XIVOnMac.AudioCapture")
	private var streamOutput: CaptureEngineStreamOutput? = nil

    /// - Tag: StartCapture
    func startCapture(configuration: SCStreamConfiguration, filter: SCContentFilter) {
        do {
			let streamOutput = CaptureEngineStreamOutput()
			// Need to keep a reference to this so that it's not discarded when we start recording
			self.streamOutput = streamOutput
            if let avWriter = self.avWriter
            {
                streamOutput.avWriter = avWriter
                avWriter.startRecording(height: Int(configuration.height), width: Int(configuration.width))
            }
            stream = SCStream(filter: filter, configuration: configuration, delegate: streamOutput)
            
            // Add a stream output to capture screen content.
            try stream?.addStreamOutput(streamOutput, type: .screen, sampleHandlerQueue: videoSampleBufferQueue)
            try stream?.addStreamOutput(streamOutput, type: .audio, sampleHandlerQueue: audioSampleBufferQueue)
            stream?.startCapture()
            Log.information("XIV Screen Recording: ")
        } catch {
            Log.error("XIV Screen Recording: Failed to start screen recording \(error)")
        }
    }
    
    @discardableResult
    func stopCapture() async -> URL? {
        var result : URL? = nil
        do {
            try await stream?.stopCapture()
        } catch {
            Log.error("XIV Screen Recording: Error stopping screen recording \(error)")
        }
        if let avWriter = self.avWriter {
            result = await avWriter.stopRecording()
        }
        return result
    }
    
    func update(configuration: SCStreamConfiguration, filter: SCContentFilter) async {
        do {
            try await stream?.updateConfiguration(configuration)
            try await stream?.updateContentFilter(filter)
        } catch {
            Log.error("Failed to update the stream session: \(String(describing: error))")
        }
    }
}

@available(macOS 13.0, *)
private class CaptureEngineStreamOutput: NSObject, SCStreamOutput, SCStreamDelegate {
    
    public var avWriter : AVWriter?
    
    private func isValidFrame(for sampleBuffer: CMSampleBuffer) -> Bool {

            guard let attachmentsArray = CMSampleBufferGetSampleAttachmentsArray(sampleBuffer,
                                                                                 createIfNecessary: false) as? [[SCStreamFrameInfo: Any]],
                  let attachments = attachmentsArray.first
            else {
                return false
            }

            guard let statusRawValue = attachments[SCStreamFrameInfo.status] as? Int,
                  let status = SCFrameStatus(rawValue: statusRawValue),
                  status == .complete
            else {
                return false
            }

            guard let pixelBuffer = sampleBuffer.imageBuffer else {
                return false
            }

            // We don't need to use any of these, we're just sanity checking that they're there.
            guard let _ = CVPixelBufferGetIOSurface(pixelBuffer)?.takeUnretainedValue(), // SurfaceRef/Backing IOSurface
                  let contentRectDict = attachments[.contentRect],
                  let _ = CGRect(dictionaryRepresentation: contentRectDict as! CFDictionary), // contentRect
                  let _ = attachments[.contentScale] as? CGFloat, // contentScale
                  let _ = attachments[.scaleFactor] as? CGFloat // scaleFactor
            else {
                return false
            }

            return true
        }
    
    func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of outputType: SCStreamOutputType) {
        
        // Return early if the sample buffer is invalid.
        guard sampleBuffer.isValid else { return }
        
        // Determine which type of data the sample buffer contains.
        switch outputType {
        case .screen:
            guard isValidFrame(for: sampleBuffer) else {
                            return
                        }
            avWriter?.recordVideo(sampleBuffer: sampleBuffer)
        case .audio:
            avWriter?.recordAudio(sampleBuffer: sampleBuffer)
        case .microphone:
            avWriter?.recordAudio(sampleBuffer: sampleBuffer)
        @unknown default:
            fatalError("Encountered unknown stream output type: \(outputType)")
        }
    }
    
    func stream(_ stream: SCStream, didStopWithError error: Error) {
        Log.error("XIV Screen Recording: An error occurred while capturing: \(error)")
    }
}

@available(macOS 13.0, *)
class AVWriter {

    private(set) var assetWriter: AVAssetWriter?
    private var assetWriterVideoInput: AVAssetWriterInput?
    private var assetWriterAudioInput: AVAssetWriterInput?

    private(set) var isRecording = false
    public var currentRecordingURL : URL? = nil

    init() {}

    private func getRecordingPath() -> URL {
        
        let recordingLocation : URL
        if let savedStringLocation = UserDefaults.standard.string(forKey: ScreenCaptureHelper.captureFolderPref) {
            recordingLocation = URL(filePath: savedStringLocation)
        }
        else
        {
            recordingLocation = FileManager.default.urls(for: .moviesDirectory, in: .userDomainMask)[0]
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HHmmss"
        formatter.timeZone = NSTimeZone.local
        let now = Date()
        let formatted = formatter.string(from: now)
        let filename = "XIV On Mac Recording \(formatted).mov"
        
        // I *suppose* the most correct thing to do is check for duplicates but hardly seems worth the effort with the timestamp.
        let finalPath : URL = recordingLocation.appending(component: filename)
        Log.information("Screen Recording: Creating new recording at \(finalPath)")
        return finalPath
    }

    func startRecording(height: Int, width: Int) {
        let filePath = getRecordingPath()
        currentRecordingURL = filePath
        guard let assetWriter = try? AVAssetWriter(url: filePath, fileType: .mov) else {
            return
        }

        // Add an audio input
        let audioSettings = [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 2,
        ] as [String: Any]

        let assetWriterAudioInput = AVAssetWriterInput(mediaType: .audio, outputSettings: audioSettings)
        assetWriterAudioInput.expectsMediaDataInRealTime = true
        assetWriter.add(assetWriterAudioInput)

        var chosenCodec : AVVideoCodecType
        switch ScreenCaptureCodec(rawValue: UserDefaults.standard.integer(forKey: ScreenCaptureHelper.videoCodecPref))
        {
            case .hevc:
                chosenCodec = AVVideoCodecType.hevc
            default:
                chosenCodec = AVVideoCodecType.h264
        }
        let videoSettings = [
            AVVideoCodecKey: chosenCodec,
            AVVideoWidthKey: width,
            AVVideoHeightKey: height
        ] as [String: Any]

        // Add a video input
        let assetWriterVideoInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
        assetWriterVideoInput.expectsMediaDataInRealTime = true
        assetWriter.add(assetWriterVideoInput)

        self.assetWriter = assetWriter
        self.assetWriterAudioInput = assetWriterAudioInput
        self.assetWriterVideoInput = assetWriterVideoInput
        isRecording = true
    }

    func stopRecording() async -> URL? {
        guard let assetWriter = assetWriter else {
            return nil
        }

        self.isRecording = false
        self.assetWriter = nil
		if assetWriter.status == .writing
		{
			await assetWriter.finishWriting()
			return assetWriter.outputURL
		}
		
		return nil
        
    }

    func recordVideo(sampleBuffer: CMSampleBuffer) {
        guard isRecording,
              let assetWriter = assetWriter
        else {
            return
        }

        if assetWriter.status == .unknown {
            assetWriter.startWriting()
            assetWriter.startSession(atSourceTime: CMSampleBufferGetPresentationTimeStamp(sampleBuffer))
        } else if assetWriter.status == .writing {
            if let input = assetWriterVideoInput,
               input.isReadyForMoreMediaData {
                input.append(sampleBuffer)
            }
        } else {
            Log.error("Error writing video - \(assetWriter.error?.localizedDescription ?? "Unknown error")")
        }
    }
    
    func recordAudio(sampleBuffer: CMSampleBuffer) {
        guard isRecording,
              let assetWriter = assetWriter,
              assetWriter.status == .writing,
              let input = assetWriterAudioInput,
              input.isReadyForMoreMediaData
        else {
            return
        }

        input.append(sampleBuffer)
    }
}
