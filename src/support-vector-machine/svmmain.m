% Author: Diogo Silva
% Email Address: dbtds@ua.pt
addpath('support-vector-machine/libsvm-3.21/matlab/')
addpath('support-vector-machine')
%data = csvread('data/bank-fixed-full.csv'); 
data = csvread('data/bank-fixed.csv'); 

colorstring = 'rbgry';
%scatter(data(:, 1), data(:, 2), colorClass(data(:,7) + 1))

X = data(:,1:end-1);
Y = not(data(:, end)); % inverting -> yes is 1 and no is 0

% 
%% TRYING PCA ANALYSIS
Xfiltered = X;
 
[coeff,score,latent,tsquared] = pca(Xfiltered, 'NumComponents', 2);
Xcentered = score*coeff';

cmap = [1 0 0; 0 1 0; 0 0 1];
colormap(cmap);
figure(1)
s1 = scatter(score(Y == 1,1), score(Y == 1,2), 'red');
hold on
s2 = scatter(score(Y == 0,1), score(Y == 0,2), 'blue');
s1.MarkerEdgeColor = s1.CData;
s2.MarkerEdgeColor = s2.CData;

hold off
title('PCA applied to 2 components')
legend({'yes','no'})
xlabel('Feature X1')
ylabel('Feature X2')
 

%% Normalization every feature value from 0 to 1
minX = min(X);
rangeX = max(X)-minX;
lX = length(X);
Xnorm = (X - repmat(minX, lX, 1)) ./ repmat(rangeX, lX, 1);

%% Algorithm to train, predict and check the performane
% Run for different scales (it depends from the kernel used):
% linear -> no kernel scaling (it will make no difference)
% polynomial -> gamma
% rbf -> gamma 
algorithms = {{'linear','red'}, {'polynomial','blue'}, {'rbf','magenta'}};
for selectAlgorithm = 1:1:length(algorithms)
    stats_mean = [];
    algo = algorithms{1,selectAlgorithm}(1,1);
    color = algorithms{1,selectAlgorithm}(1,2);
    for kernelScale = 0.2:0.2:20
        %% APPLYING CROSS VALIDATION
        crossvalid = 7;
        stats = zeros(crossvalid, 6);
        for index = 1:crossvalid
            %% COMPUTING SVM
            [ TrainX, TestX ] = splitset(Xnorm, index, crossvalid);
            [ TrainY, TestY ] = splitset(Y, index, crossvalid);
            fprintf('Training.. ');
            %fitcsvm(TrainX, TrainY, 'Standardize', true, 'KernelFunction', 'mrbf')
            prior0 = mean(TrainY);
            prior1 = 1 - prior0;

            % Measuring the performance time
            tic
            svmModel = fitcsvm(TrainX, TrainY, ...
                'CategoricalPredictors', [2,3,4,5,6,7,8,9,10,15], ... % additional set
                'Standardize', true, ...
                'KernelFunction', algo{:}, ...
                'KernelScale', kernelScale, ...
                'Prior', [prior0 prior1], ...       % empirical, uniform, ...
                ... %'PolynomialOrder', 3, ...       % default is 3
                'KernelOffset', 0 ...          % 0 for SMO, 0.1 ISDA
            );
            trainTiming = toc;
            % poly, SMO
            fprintf('Trained! Predicting.. ');
            tic
            out = predict(svmModel, TestX);
            predictTiming = toc;
            fprintf('Predicted! ');
            %% COMPUTING FMEASURE
            [acc, fscore, recall, precision] = fmeasure(TestY, out);
            stats(index, :) = [fscore, acc, recall, precision, trainTiming, predictTiming];
            fprintf('F-Measure: %.4f, Accuracy: %.4f, Recall: %.4f, Precision: %.4f\n', fscore, acc, recall, precision)
        end
        stats_mean(end+1,:) = [kernelScale mean(stats)]
    end
    figure(2)
    plot(stats_mean(:,1), stats_mean(:,4), color{:}, ...
        stats_mean(:,1), stats_mean(:,5), strcat('--', color{:}))
    hold on
    
    figure(3)
    plot(stats_mean(:,1), stats_mean(:,3), color{:})
    hold on
    
    figure(4)
    plot(stats_mean(:,1), stats_mean(:,6), color{:}, ...
        stats_mean(:,1), stats_mean(:,7), strcat('--', color{:}))
    hold on
end
figure(2)
hold off
title('Recall and Precision')
legend({'Linear Recall', 'Linear Precision', 'Polynomial Recall','Polynomial Precision', 'RBF Recall', 'RBF Precision'})
xlabel('Kernel Scaling (\gamma and/or \sigma)')
ylabel('Measure (from 0 to 1)')

figure(3)
hold off
title('Accuracy')
legend({'Linear', 'Polynomial', 'RBF'})
xlabel('Kernel Scaling (\gamma and/or \sigma)')
ylabel('Measure (from 0 to 1)')

figure(4)
hold off
title('Train and Predict Duration')
legend({'Linear Train', 'Linear Predict', 'Polynomial Train','Polynomial Predict', 'RBF Train', 'RBF Predict'})
xlabel('Kernel Scaling (\gamma and/or \sigma)')
ylabel('Duration (seconds)')
