%% M3C2 clouds
% Target Input Format is a TXT file such that:
% //X,Y,Z,Npoints_cloud1,Npoints_cloud2,STD_cloud1,STD_cloud2,significant change,distance uncertainty,M3C2 distance,Nx,Ny,Nz
% 919984
% 1042.822265625000,1194.622070312500,1010.627746582031,1158.000000,957.000000,0.004416,0.005624,1.000000,0.004358,-0.009361,-0.050169,-0.896264,0.440674
% Where the first line is the header, the second line is the number of rows, and the third line is a repeating data series matching the header.

% It should be noted that the line count is not arbitrary and is used later on in the program. 

% Clear MatLAB instance from variables.
clc
clear all;

% Start Clock for timing duration of operation.
tic;

% Assigning the location of the folders that contain the poit clouds to be processed. 
% As these are hardcoded, make sure to 
% TODO: CHANGE THESE PATHS
% such that they point to the directories containing the appropriate clouds. 
pointCloudInputDir = 'C:\Users\Hive Lab\Desktop\InputClouds';					% Folder containing the clouds as TXT files.
pointCloudOutputDir = 'C:\Users\Hive Lab\Desktop\OutputMassLossFile';			% Folder to dump output files. 
summaryCSV = 'C:\Users\Hive Lab\Desktop\OutputMassLossFile\MaterialLoss.csv';	% File to be created for the summary file. 

% Throw an exception if the input path is not a directory.
if ~isdir(pointCloudInputDir)
    errorMessege = 'The input folder path specified is either incorrect or labled wrong.';
    uiwait(warndlg(errorMessege));
    return;
end

% Throw another exception for the output path not being valid (or a directory).
if ~isdir(pointCloudOutputDir)
    ErrorMessege = 'The output folder path specified is either incorrent or it does not exist.';
    uiwait(warndlg(ErrorMessege));
    return;
end 

% Create file folder handle.
dirHandle = fullfile(pointCloudInputDir, '*.txt');
% Create a list of files in the folder.
dirList = dir(dirHandle);

% Create structure that stores output in a table.
output.names = extractfield(dirList, 'name'); % Holds names and years. 
output.loss = []; % Holds signed distance loss values. 


% Loop for each Point Cloud file.
for k = 1 : length(dirList)
    % Get Target Cloud Name
    cloudName = dirList(k).name;
	% Get Target Cloud File
    inputFile = fullfile(pointCloudInputDir,cloudName); 
    
    % Read in the second row in the header which contains the number of rows.
    entryCount = csvread(inputFile,1,0,[1,0,1,0]);
	
	% Read the distance values from the 10th column in the CSV file.
    distances = csvread(inputFile,2,9,[2,9,entryCount-2,9]);
	
	% Read the Uncertainty Values from the 9th column value.
    uncertaintyList = csvread(inputFile,2,8,[2,8,entryCount-2,8]);
	% Read the Distance and Uncertainty value from the 8th and 9th columns together. 
    distanceUncertaintyList = csvread(inputFile,1,8,[1,8,entryCount-2,9]);
    
    %  Remove all NaN values from lists.
    filteredDistances = distances(isfinite(distances(:,1)),:);
	
	% Lists of all columns in the memory.
    filteredDistanceUncertainty = uncertaintyList(isfinite(uncertaintyList(:,1)),:);
    filteredDistancesAndUncertainty = distanceUncertaintyList(isfinite(distanceUncertaintyList(:,1)),:);
    testDistancesAndUncertainty = distanceUncertaintyList(isfinite(distanceUncertaintyList(:,1)),:);
    
    % This value must be calibrated such that the average material loss calculation output is coherent. It must be tweaked to capture the material loss properly and will vary
	% on the sparsity of heterogenity of the cloud itself. You can use this value for now and adjust in increments of +- 0.01 to attain proper center.
    threshold = 0.021;
   
    % Eject any distances that are above the threshold.
    CertainDistances =  filteredDistancesAndUncertainty(:,1) > threshold;
	
	% Create a new array using the ejected distances.
    filteredDistancesAndUncertainty(CertainDistances,:) = []; 
    
	% Create the Filtered Distances using the second column. 
    outputFilteredDistances = filteredDistancesAndUncertainty(:,[2]);

	% Compute absolute mean of the distances for metrics in output.
    meanIntensity = abs(mean(outputFilteredDistances));
	
	% Create Signed Distance Loss column.
    output.loss = [output.loss meanIntensity];
   
end

% Assign all data columns to a STRUCT for easy write.
% The rows are rotated into columns here...
output.names = rot90(output.names);
%... and here.
output.loss = rot90(output.loss);
% The STRUCT is converted to a TABLE.
table = struct2table(output);
% Print the TABLE to the user.
disp(table)

% Write TABLE to CSV.
writetable(table,summaryCSV);

% Terminate clock.
toc;
% OMITTED: You can print out the duration of the operation here for debugging purposes.
