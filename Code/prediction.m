arduinoObj = serialport("COM11", 9600); 
configureTerminator(arduinoObj, "CR/LF");
numSamples = 1000;
ecgData = zeros(1, numSamples); 
disp('Collecting ECG data...'); 
for i = 1:num
Samples data = readline(arduinoObj); 
numericData = str2double(data); 
if isnan(numericData) || isinf(numericData) 
numericData = 0; 
end 
ecgData(i) = numericData; 
end
samplingRate = 250; 
ecgDataScaled = (ecgData - min(ecgData)) / (max(ecgData) - min(ecgData)); 
windowSize = 10; 
ecgDataSmoothed = movmean(ecgDataScaled, windowSize);
[b, a] = butter(2, 0.5/(numSamples/2), 'high'); 
if all(isfinite(ecgDataSmoothed)) 
ecgDataFiltered = filtfilt(b, a, ecgDataSmoothed); 
else 
error('Signal contains non-finite values.'); 
end
minPeakHeight = 0.15; 
minPeakDistance = 50; 
[peaks, locs] = findpeaks(ecgDataFiltered, 'MinPeakHeight', minPeakHeight, 'MinPeakDistance', minPeakDistance);
scalingFactor = 1; 
rAmplitudes = peaks * scalingFactor; 
averageRAmplitude = mean(rAmplitudes);
if length(locs) > 1 
rrIntervals = diff(locs); 
rrIntervalsSec = rrIntervals / samplingRate; 
averageRRIntervalSec = mean(rrIntervalsSec); rrIntervalSpeedMs = (averageRAmplitude / averageRRIntervalSec); 
pulseRate = 60 / averageRRIntervalSec; 
else rrIntervalSpeedMs = NaN; 
pulseRate = NaN; 
end
age = 20; 
gender = categorical({'M'}); 
features = table( averageRAmplitude,averageRRIntervalSec,rrIntervalSpeedMs, age, gender,  'VariableNames', {'Amplitude', 'RR', 'Speed', 'Age', 'Gender'}); load('ClassificationLearnerSession.mat'); 
[predictions, scores] = trainedModel.predictFcn(features); disp('Predictions:'); 
disp(predictions); 
disp('Scores:'); 
disp(scores); 
predictionText = char(predictions); 
writeline(arduinoObj, predictionText); 
pulseRateStr = num2str(pulseRate); 
writeline(arduinoObj, pulseRateStr);
figure;
subplot(3,1,1);
plot(ecgDataScaled);
title('Raw ECG Waveform');
xlabel('Time (samples)');
ylabel('ECG Signal');
grid on;
subplot(3,1,2);
plot(ecgDataSmoothed);
title('Smoothed ECG Waveform');
xlabel('Time (samples)');
ylabel('ECG Signal');
grid on;
subplot(3,1,3);
plot(ecgDataFiltered);
hold on;
plot(locs, peaks, 'r*', 'MarkerSize', 8);  
title('Filtered ECG Waveform with Detected R-peaks');
xlabel('Time (samples)');
ylabel('ECG Signal');
grid on;
for i = 1:length(locs)
    line([locs(i) locs(i)], ylim, 'Color', 'r', 'LineStyle', '--', 'LineWidth', 0.5);
end
figure; 
bar(scores); 
title('Prediction Scores'); 
xlabel('Classes'); 
ylabel('Scores'); 
xticklabels({'Bradycardia', 'Normal', 'Tachycardia', 'Ventricular Tachycardia'}); 
xtickangle(45); 

