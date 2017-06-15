import CoreML

class Inceptionv3Input : MLFeatureProvider {
    var image: CVPixelBuffer
    
    var featureNames: Set<String> {
        get {
            return ["image"]
        }
    }
    
    func featureValue(for featureName: String) -> MLFeatureValue? {
        if (featureName == "image") {
            return MLFeatureValue(pixelBuffer: image)
        }
        return nil
    }
    
    init(image: CVPixelBuffer) {
        self.image = image
    }
}

class Inceptionv3Output : MLFeatureProvider {
    let classLabelProbs: [String : Double]
    let classLabel: String
    
    var featureNames: Set<String> {
        get {
            return ["classLabelProbs", "classLabel"]
        }
    }
    
    func featureValue(for featureName: String) -> MLFeatureValue? {
        if (featureName == "classLabelProbs") {
            return try! MLFeatureValue(dictionary: classLabelProbs as [NSObject : NSNumber])
        }
        if (featureName == "classLabel") {
            return MLFeatureValue(string: classLabel)
        }
        return nil
    }
    
    init(classLabelProbs: [String : Double], classLabel: String) {
        self.classLabelProbs = classLabelProbs
        self.classLabel = classLabel
    }
}

@objc class Inceptionv3:NSObject {
    var model: MLModel
    init(contentsOf url: URL) throws {
        self.model = try MLModel(contentsOf: url)
    }
    convenience override init() {
        let bundle = Bundle(for: Inceptionv3.self)
        let assetPath = bundle.url(forResource: "Inceptionv3", withExtension:"mlmodelc")
        try! self.init(contentsOf: assetPath!)
    }
    func prediction(input: Inceptionv3Input) throws -> Inceptionv3Output {
        let outFeatures = try model.prediction(from: input)
        let result = Inceptionv3Output(classLabelProbs: outFeatures.featureValue(for: "classLabelProbs")!.dictionaryValue as! [String : Double], classLabel: outFeatures.featureValue(for: "classLabel")!.stringValue)
        return result
    }
    func prediction(image: CVPixelBuffer) throws -> Inceptionv3Output {
        let input_ = Inceptionv3Input(image: image)
        return try self.prediction(input: input_)
    }
}
