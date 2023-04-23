/* ImagePredictor.swift --> CoreMLDemo. Created by Miguel Torres on 23/04/23. */

import Foundation
import UIKit
import CoreML
import Vision

class ImagePredictor {
    // Singleton para el clasificador de imágenes
    static let imageClassifier = createImageClassifier()

    // Tipo personalizado para almacenar las predicciones
    struct Prediction {
        let classification: String
        let confidencePercentage: String
    }

    // Crear una instancia de VNCoreMLModel para el modelo MobileNet
    static func createImageClassifier() -> VNCoreMLModel {
        let defaultConfig = MLModelConfiguration()
        guard let imageClassifierWrapper = try? MobileNetV2(configuration: defaultConfig) else {
            fatalError("App failed to create an image classifier model instance.")
        }
        let imageClassifierModel = imageClassifierWrapper.model
        guard let imageClassifierVisionModel = try? VNCoreMLModel(for: imageClassifierModel) else {
            fatalError("App failed to create a `VNCoreMLModel` instance.")
        }
        return imageClassifierVisionModel
    }
    
    // Agregamos una función para convertir CIImage a CGImage en la clase ImagePredictor.
    func convertCIImageToCGImage(inputImage: CIImage) -> CGImage? {
        let context = CIContext(options: nil)
        if let cgImage = context.createCGImage(inputImage, from: inputImage.extent) {
            return cgImage
        }
        return nil
    }

    // Función para realizar predicciones usando el modelo MobileNet y una imagen
    func makePredictions(for photo: CIImage, orientation: CGImagePropertyOrientation, completionHandler: @escaping ([Prediction]?) -> Void) {
        // Convertir CIImage a CGImage
        guard let cgImage = convertCIImageToCGImage(inputImage: photo) else {
            print("Error al convertir CIImage a CGImage")
            completionHandler(nil)
            return
        }

        let visionRequestHandler = { (request: VNRequest, error: Error?) in
            // Verificar si hay errores
            if let error = error {
                print("Error al realizar la clasificación: \(error)")
                completionHandler(nil)
                return
            }
            // Convertir los resultados en un array de VNClassificationObservation
            guard let observations = request.results as? [VNClassificationObservation] else {
                print("VNRequest produced the wrong result type: \(type(of: request.results)).")
                completionHandler(nil)
                return
            }
            // Convertir las observaciones en instancias de Prediction
            let predictions = observations.map { observation in
                Prediction(classification: observation.identifier, confidencePercentage: observation.confidencePercentageString)
            }
            // Llamar al completionHandler con las predicciones
            completionHandler(predictions)
        }

        // Crear una solicitud de clasificación de imágenes con el modelo de clasificador de imágenes
        let imageClassificationRequest = VNCoreMLRequest(model: ImagePredictor.imageClassifier, completionHandler: visionRequestHandler)
        imageClassificationRequest.imageCropAndScaleOption = .centerCrop
        // Crear un manejador de solicitudes de imágenes
        let handler = VNImageRequestHandler(cgImage: cgImage, orientation: orientation)

        // Iniciar la solicitud de clasificación de imágenes
        do {
            try handler.perform([imageClassificationRequest])
        } catch {
            print("Error al realizar la solicitud de clasificación: \(error)")
            completionHandler(nil)
        }
    }
}

// Extensión para formatear la confianza como un porcentaje
extension VNClassificationObservation {
    var confidencePercentageString: String {
        return String(format: "%.2f%%", confidence * 100)
    }
}
