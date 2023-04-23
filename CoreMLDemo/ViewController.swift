/* ViewController.swift --> CoreMLDemo. Created by Miguel Torres on 23/04/23. */

import UIKit
import CoreML // Es la base de todas las herramientas de Machine Learning
import Vision // Nos ayuda a procesar imágenes más fácilmente

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    // Conexión del objeto ImageView de la interfaz a su clase ViewController.
    @IBOutlet weak var imageFromCamera: UIImageView!
    @IBOutlet weak var predictionLabel: UILabel!
    
    // Creamos un objeto de la clase UIImagePickerController, que tiene un Delegate, que debemos asignar a esta clase, dentro del viewDidLoad
    let imagePicker = UIImagePickerController()
    // Creamos un objeto igual pero para acceder a los archivos de imagen del dispositivo
    let imageGalery = UIImagePickerController()
    
    /// GPT
    // Crear una instancia de ImagePredictor
    let imagePredictor = ImagePredictor()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        /// Configuración del objeto "imagePicker"
        // Asignamos el Delegate de la clase UIImagePickerController a través de su objeto imagePicker, a esta clase ViewController.
        imagePicker.delegate = self
        // La manera más sencilla de implementar la cámara en cualquier app es definiendo el sourceType del imagePicker como .camera
        imagePicker.sourceType = .camera
        // Finalmente, la configuración de "allowsEditing" nos permite activar o desactivar el recortar las imágenes de la cámara para que sea más fácil reconocer la imagen por el modelo de ML.
        imagePicker.allowsEditing = false // Lo dejamos en falso para nuestros primeros proyectos, debido a que se requiere más código para activarlo.
        /// Configuración del objeto "imageGalery"
        // Asignamos el delegate del objeto imageGalery como self
        imageGalery.delegate = self
        // Si queremos que el objeto de UIImagePickerController acceda a las fotos en vez de usar la cámara, debemos indicarlo en su tipo de fuente de datos.
        imageGalery.sourceType = .photoLibrary // Podemos agregar fotos a la librería del simulador simplemente arrastrándo las fotos desde la mac.
        imageGalery.allowsEditing = false
    }
    
    // Para poder mandar la imagen que obtenemos de la cámara a nuestro modelo de ML necesitamos utilizar un método delegado, que le avisa al controlador cuando el usuario ya eligió una imagen estática (cuando ya hizo una foto)
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        // Primero tenemos que asegurarnos de que el usuario haya elegido una imagen, y si esto es así, podemos acceder a la imagen que el usuario ha elegido, con la constante "userImage", para eso hacemos un downcast con la palabra as? para pasar de tipo "any" a un tipo más específico, que es "ImageView", y además lo metemos en un Optional Binding para que no haya errores.
        if let userImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage { // El valor que obtenemos del diccionario "info" a través de la llave, es de tipo "any" en la función.
            // Asignamos la imagen que se muestra en el objeto ImageView de la interfaz, a la imagen que el usuario eligió desde la cámara mediante el imagePicker que vamos a pasar por parámetro a esta función.
            imageFromCamera.image = userImage // Pero necesitamos que el valor que obtenemos del diccionario sea de tipo UIImage para poder asignarlo a imageFromCamera.
            // Convertimos la imagen "userImage" de UIImage a CIImage, para poderla procesar con CoreML y Vision, usando un guard para atrapar errores.
            guard let ciimage = CIImage(image: userImage) else {
                fatalError("Couldn't convert to CIImage :c")
            }
            /// GPT
            // Obtener la orientación de la imagen
            let orientation = CGImagePropertyOrientation(rawValue: UInt32(userImage.imageOrientation.rawValue))!
            // Realizar predicciones usando ImagePredictor
            imagePredictor.makePredictions(for: ciimage, orientation: orientation) { (predictions) in
                // Manejar las predicciones aquí, por ejemplo, mostrarlas en la interfaz de usuario
                if let predictions = predictions {
                    // Ordenar las predicciones por confianza y obtener la predicción con mayor confianza
                    let topPrediction = predictions.sorted { $0.confidencePercentage > $1.confidencePercentage }.first
                    // Actualizar el texto del UILabel con la predicción de mayor confianza
                    if let topPrediction = topPrediction {
                        let resultText = "Classification: \(topPrediction.classification), Confidence: \(topPrediction.confidencePercentage)"
                        DispatchQueue.main.async {
                            self.predictionLabel.text = resultText
                        }
                    }
                }
            }
        }
        imagePicker.dismiss(animated: true)
        imageGalery.dismiss(animated: true)
    }
    
    // Conexión del botón BarButton que definimos como tipo "Camera" en la interfaz, a su clase ViewController.
    @IBAction func cameraTapped(_ sender: UIBarButtonItem) {
        // Queremos que la cámara se active cada vez que se presiona sobre el BarButton que agregamos a la interfaz, y para eso usamos "present" ya que imagePicker es un ViewController.
        present(imagePicker, animated: true)
    }
    
    // Conexión del botón BarButton que definimos como tipo "Search" en la interfaz, a su clase ViewController.
    @IBAction func searchTapped(_ sender: UIBarButtonItem) {
        // Activamos el objeto del UIImagePickerController que tiene como "sourceType" la librería de fotos para mostrarlo cada vez que se presione ese botón.
        present(imageGalery, animated: true)
    }
}
