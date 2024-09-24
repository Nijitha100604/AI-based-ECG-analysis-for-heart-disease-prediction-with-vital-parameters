load('100m.mat');
original_signal = val;
disp(length(val));

Fs = 250;  
t = (0:length(val)-1) / Fs;  
figure;
plot(t, val);
title('Original ECG Signal');
xlabel('Time (s)');
ylabel('Amplitude');

[b, a] = butter(1, [0.5 40] / (Fs / 2), 'bandpass');  % Bandpass filter from 0.5 to 40 Hz
filtered_signal = filtfilt(b, a, val);  % Apply the filter


% Plot the filtered ECG signal for visual inspection
figure;
plot(t, filtered_signal);
title('Filtered ECG Signal');
xlabel('Time (s)');
ylabel('Amplitude');
xlim([0 10]);


% Calculate mean and standard deviation
mean_ecg = mean(filtered_signal);
std_ecg = std(filtered_signal);

% Set initial threshold based on mean and standard deviation
threshold_value = mean_ecg + 2 * std_ecg;  % You can adjust the multiplier

% Display the chosen threshold
disp(['Chosen threshold value: ', num2str(threshold_value)]);

% Detect R-peaks using the chosen threshold
min_peak_distance = round(Fs / 2);  % Minimum distance between peaks
[~, locs] = findpeaks(filtered_signal, 'MinPeakHeight', threshold_value, ...
                      'MinPeakDistance', min_peak_distance);

% Plot the detected R-peaks
figure;
plot(t, filtered_signal);
hold on;
plot(t(locs), filtered_signal(locs), 'ro');  % Highlight detected R-peaks
hold off;
title('R-peaks in Filtered ECG Signal');
xlabel('Time (s)');
ylabel('Amplitude');
xlim([0 10]);


rr_intervals = diff(locs);  % Differences in indices of R-peaks
rr_intervals_sec = rr_intervals / Fs;  % Convert to seconds

mean_amplitude = mean(filtered_signal(locs))/1000;  % Mean amplitude of R-peaks
mean_rr = mean(rr_intervals_sec);  % Mean RR interval in seconds
std_rr = std(rr_intervals_sec);  % Standard deviation of RR intervals

if mean_rr > 0  % Ensure mean RR is not zero to avoid division by zero
    speed = (60 / mean_rr)/100;  % Heart rate in beats per minute
else
    speed = NaN;  % Handle the case where mean RR is zero
end

age = 30;  
gender = categorical({'M'});

features = table(mean_amplitude, mean_rr, speed, age, gender, ...
                 'VariableNames', {'Amplitude', 'RR', 'Speed', 'Age', 'Gender'});

disp('Feature Table:');
disp(features);

load('ClassificationLearnerSession.mat');

[predictions, scores] = trainedModel.predictFcn(features);

disp(predictions);  % This will show the predicted conditions
disp(scores);       % This will show the score for each class

figure;
bar(scores);  % Display scores as a bar graph
title('Prediction');
xlabel('Classes');
ylabel('Scores');
xticklabels({'Bradycardia', 'Normal', 'Trachycardia', 'Ventricular Trachycardia'});
xtickangle(45);  % Rotate x-axis labels for better visibility


