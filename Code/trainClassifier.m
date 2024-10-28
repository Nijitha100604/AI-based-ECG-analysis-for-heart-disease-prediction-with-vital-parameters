function [trainedClassifier, validationAccuracy] = trainClassifier(trainingData)
inputTable = trainingData;
predictorNames = {'Amplitude', 'RR', 'Speed', 'Age', 'Gender'};
predictors = inputTable(:, predictorNames);
response = inputTable.Arrhythmia;
isCategoricalPredictor = [false, false, false, false, true];
classNames = categorical({'Bradycardia'; 'Normal'; 'Trachycardia'; 'ventricular Trachycardia'});
classificationTree = fitctree(...
    predictors, ...
    response, ...
    'SplitCriterion', 'gdi', ...
    'MaxNumSplits', 4, ...
    'Surrogate', 'off', ...
    'ClassNames', classNames);
predictorExtractionFcn = @(t) t(:, predictorNames);
treePredictFcn = @(x) predict(classificationTree, x);
trainedClassifier.predictFcn = @(x) treePredictFcn(predictorExtractionFcn(x));
trainedClassifier.RequiredVariables = {'Amplitude', 'RR', 'Speed', 'Age', 'Gender'};
trainedClassifier.ClassificationTree = classificationTree;
trainedClassifier.About = 'This struct is a trained model exported from Classification Learner R2024b.';
trainedClassifier.HowToPredict = sprintf('To make predictions on a new table, T, use: \n  [yfit,scores] = c.predictFcn(T) \nreplace ''c'' with the name of the variable that is this struct, e.g. ''trainedModel''. \n \nThe table, T, must contain the variables returned by: \n  c.RequiredVariables \nVariable formats (e.g. matrix/vector, datatype) must match the original training data. \nAdditional variables are ignored. \n \nFor more information, see <a href="matlab:helpview(fullfile(docroot, ''stats'', ''stats.map''), ''appclassification_exportmodeltoworkspace'')">How to predict using an exported model</a>.');
inputTable = trainingData;
predictorNames = {'Amplitude', 'RR', 'Speed', 'Age', 'Gender'};
predictors = inputTable(:, predictorNames);
response = inputTable.Arrhythmia;
isCategoricalPredictor = [false, false, false, false, true];
classNames = categorical({'Bradycardia'; 'Normal'; 'Trachycardia'; 'ventricular Trachycardia'});
partitionedModel = crossval(trainedClassifier.ClassificationTree, 'KFold', 5);
[validationPredictions, validationScores] = kfoldPredict(partitionedModel);
validationAccuracy = 1 - kfoldLoss(partitionedModel, 'LossFun', 'ClassifError');
