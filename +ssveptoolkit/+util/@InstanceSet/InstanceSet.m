classdef InstanceSet
    % A class for describing a set of instances and labels
    
    properties (Access = public)
        instances; % the instances
        labels; % the labels
        K; % the kernel of the instances
    end
    
    methods
        function IS = InstanceSet(instances, labels)
            % obj = InstanceSet(instances, labels)
            % -instances : a m x n matrix where m = instances and n =
            % features
            % -labels: a m x 1 matrix containing the labels for each
            % instance
            if nargin == 1
                [~, cols] = size(instances);
                IS.instances = instances(:,1:cols-1);
                IS.labels = instances(:,cols);
            elseif nargin==2
                IS.instances = instances;
                IS.labels = floor(labels);
            end
            %             for i=1:size(IS.instances,1)
            %                 IS.instances(i,:) = IS.instances(i,:)./norm(IS.instances(i,:));
            %             end
        end
        
        function instances = getInstances(IS)
            % get the instances
            instances = IS.instances;
        end
        
        function K = computeKernel(IS,kernel, gamma)
            switch kernel
                case 'linear'
                    K = IS.instances*IS.instances';
                case 'rbf'
                    dist = pdist2(IS.instances,IS.instances).^2;
                    %                     N = size(IS.instances,1);
                    %                     dist = repmat(sum(IS.instances.^2, 2)', [N 1])' + ...
                    %                         repmat(sum(IS.instances.^2,2)', [N 1]) - ...
                    %                         2.*IS.instances*IS.instances';
                    K = exp(-gamma.*dist);
                case 'chi'
                    error('chi kernel not implemented yet');
                case 'xcorr'
                    maxlag = 150;
                    scaleopt = 'coeff';
                    K = zeros(size(IS.instances,1));
                    if size(IS.instances,2) < 500 % if memory allows it go for the vectorized version
                        a = xcorr(IS.instances',maxlag,scaleopt);
                        c = reshape(a, 2*maxlag+1, size(IS.instances,1), size(IS.instances,1));
                        if size(c,1) == 1 % no max is required
                            K = squeeze(c);
                        else
                            K = squeeze(max(c));
                        end
                    else
                        for i=1:size(IS.instances,1)
                            for j=i:size(IS.instances,1)
                                K(i,j)=max(xcorr(IS.instances(i,:),IS.instances(j,:),maxlag,scaleopt));
                                K(j,i)=K(i,j);
                            end
                        end
                    end
                case {'spearman','correlation','cosine'}
                    dist = pdist2(IS.instances,IS.instances,kernel);
                    K = 1-dist;
                case {'eucledian','seucledian','mahalanobis'}
                    dist = pdist2(IS.instances,IS.instances,kernel).^2;
                    K = exp(-gamma.*dist);
                otherwise % if not one of the above, it can either be any value of distance in pdist2 or a function handle
                    dist = pdist2(IS.instances,IS.instances,kernel).^2;
                    K = exp(-gamma.*dist);
            end
        end
        
        function Ktrain = getTrainKernel(IS, trainidx)
            Ktrain = IS.K(trainidx,trainidx);
        end
        
        function Ktest = getTestKernel(IS, trainidx, testidx)
            Ktest = IS.K(testidx,trainidx);
        end
        
        function instance = getInstancesWithIndices(IS, idx)
            instance = IS.instances(idx,:);
        end
        function labels = getLabels(IS)
            % get the labels
            labels = IS.labels;
        end
        
        function numLabels = getNumLabels(IS)
            % get the number of labels
            numLabels = length(unique(IS.getLabels()));
        end
        
        function numInstances = getNumInstances(IS)
            [numInstances,~] = size(IS.instances);
        end
        
        function numFeatures = getNumFeatures(IS)
            [~, numFeatures] = size(IS.instances);
        end
        
        
        function instances = getInstancesForLabel(IS, label)
            indices = IS.getInstanceIndicesForLabel(label);
            instances = IS.getInstances();
            instances = instances(indices,:);
        end
        
        function indices = getInstanceIndicesForLabel(IS,label)
            [indices, ~] = find(IS.getDataset()==label);
        end
        
        function dataset = getDataset(IS)
            % same with getInstances but includes the labels as the last
            % row
            dataset = horzcat(IS.instances,IS.labels);
        end
        
        function dataset = getDatasetWithIndices(IS,idx)
            instance = IS.instances(idx,:);
            label = IS.labels(idx,:);
            dataset = horzcat(instance,label);
        end
        function IS = removeInstancesWithIndices(IS, idx)
            IS.instances(idx,:) = [];
            IS.labels(idx,:) = [];
        end
        function writeCSV(IS, csvname)
            % write the dataset to a csv file
            % Example:
            %   obj.writeCSV('data.csv');
            csvwrite(csvname, IS.getDataset());
        end
        function writeArff(IS, fname)
            % write the dataset to a weka-readable file (arff)
            % Caution: filename without extension
            % Example:
            %   obj.writeArff('data')
            data = IS.getDataset();
            %             data = horzcat(IS.instances,floor(IS.labels));
            sss=size(data,2)-1;
            filename1=strcat(fname,'.arff');
            out1 = fopen (filename1, 'w+');
            aa1=strcat('@relation',{' '},fname,'-weka.filters.unsupervised.attribute.NumericToNominal-Rlast');
            fprintf (out1, '%s\n', char(aa1));
            for jj=1:sss
                fprintf (out1, '@attribute %s numeric\n',num2str(jj));
            end
            n_classes=max(unique(data(:,end)));
            txt1=strcat('@attribute',{' '},num2str(sss+1),{' {'});
            
            for ii=1:n_classes
                txt1=strcat(txt1,num2str(ii),{','});
            end
            txt1=strcat(txt1,{'}'});
            
            fprintf (out1, '%s\n\n',char(txt1));
            fprintf (out1,'@data\n');
            
            fclose(out1);
            
            dlmwrite (filename1, data, '-append' );
        end
    end
    
end

